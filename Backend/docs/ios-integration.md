# iOS 接入指南

## 概览

上传一张餐食照片后，后端异步分析，分两阶段写入 Supabase：

```
上传图片
  └─ POST /analyze → job_id (meal_id)
       ├─ Phase 1 (~5s)  检测菜品 → status: dishes_ready
       └─ Phase 2 (~25s) 营养分析 → status: complete
                                        └─ 生成建议 → meal_advices 表
```

状态流转：`processing` → `dishes_ready` → `complete` / `failed`

---

## 1. 认证

使用 Supabase Auth 登录后，拿到 `access_token`，每个请求都带上：

```
Authorization: Bearer <access_token>
```

Token 过期后用 `supabase.auth.refreshSession()` 刷新。

---

## 2. 上传图片

```
POST /analyze
Content-Type: multipart/form-data
Authorization: Bearer <token>
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `image` | File | JPEG / PNG / HEIC / HEIF / WebP，最大 20 MB |
| `meal_type` | String | `breakfast` / `lunch` / `dinner` / `snack` / `other` |

**响应 202：**
```json
{ "job_id": "550e8400-e29b-41d4-a716-446655440000" }
```

`job_id` 即 `meal_id`，用于后续轮询。

**Swift 示例：**
```swift
func uploadMeal(imageData: Data, mealType: String) async throws -> String {
    var request = URLRequest(url: URL(string: "https://your-api/analyze")!)
    request.method = .post
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    body.appendFormField(name: "meal_type", value: mealType, boundary: boundary)
    body.appendFileField(name: "image", filename: "meal.jpg",
                         mimeType: "image/jpeg", data: imageData, boundary: boundary)
    body.appendString("--\(boundary)--\r\n")
    request.httpBody = body

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(["job_id": String].self, from: data)["job_id"]!
}
```

---

## 3. 轮询状态

### 方式 A：Supabase Realtime（推荐）

订阅 `meals` 表指定行的变化，状态更新时自动触发，无需轮询：

```swift
supabase.realtimeV2.channel("meal-\(jobId)")
    .on(.postgresChanges,
        filter: PostgresChangesFilter(
            event: .update,
            schema: "public",
            table: "meals",
            filter: "id=eq.\(jobId)"
        )
    ) { payload in
        let status = payload.record["status"] as? String
        switch status {
        case "dishes_ready": fetchDishes(jobId)
        case "complete":     fetchNutrition(jobId)
        case "failed":       showError(payload.record["pipeline_error"])
        default: break
        }
    }
    .subscribe()
```

### 方式 B：REST 轮询（备选）

每 3 秒查一次 `meals` 表，建议设最长等待 60 秒后超时：

```swift
func pollStatus(jobId: String) async throws -> MealStatus {
    let deadline = Date().addingTimeInterval(60)
    while Date() < deadline {
        let result = try await supabase
            .from("meals")
            .select("status, pipeline_error")
            .eq("id", jobId)
            .single()
            .execute()

        switch result.data["status"] {
        case "dishes_ready", "complete": return result.data
        case "failed": throw AppError.pipeline(result.data["pipeline_error"])
        default: try await Task.sleep(nanoseconds: 3_000_000_000)
        }
    }
    throw AppError.timeout
}
```

---

## 4. Phase 1：菜品列表（dishes_ready）

`status == "dishes_ready"` 时可展示初步检测到的菜品（名称 + 位置），让用户看到"已识别到 N 道菜"的中间反馈。

```swift
let dishes = try await supabase
    .from("dishes")
    .select("id, name, bbox, sort_order, empty")
    .eq("meal_id", jobId)
    .order("sort_order")
    .execute()
```

**单条 dish 数据：**
```json
{
  "id": "uuid",
  "name": "红油抄手",
  "bbox": [0.27, 0.19, 0.81, 0.49],
  "sort_order": 1,
  "empty": false
}
```

`bbox` 为归一化坐标 `[x_min, y_min, x_max, y_max]`（0–1），可直接乘以图片宽高画框。

---

## 5. Phase 2：完整营养数据（complete）

`status == "complete"` 时拉取菜品宏量素和食材明细：

```swift
let dishes = try await supabase
    .from("dishes")
    .select("""
        id, name, container, portion_size,
        estimated_total_grams, confidence,
        total_calories, total_protein_g, total_fat_g, total_carb_g,
        ingredients (
            name, weight_grams, calories,
            protein_g, fat_g, carb_g, confidence, source
        )
    """)
    .eq("meal_id", jobId)
    .eq("empty", false)
    .order("sort_order")
    .execute()
```

**单条 dish 完整数据：**
```json
{
  "id": "uuid",
  "name": "红油抄手",
  "container": "bowl",
  "portion_size": "large",
  "estimated_total_grams": 450,
  "total_calories": 887,
  "total_protein_g": 24.9,
  "total_fat_g": 28.4,
  "total_carb_g": 132.8,
  "confidence": "high",
  "ingredients": [
    { "name": "猪肉馅", "weight_grams": 150, "calories": 213.0,
      "protein_g": 17.1, "fat_g": 9.8, "carb_g": 0.0,
      "confidence": "high", "source": "database" }
  ]
}
```

**全餐合计**（从 `meals` 表单独查，或客户端自行累加 dishes）：

```swift
let meal = try await supabase
    .from("meals")
    .select("timestamp, meal_type, photo_url, status")
    .eq("id", jobId)
    .single()
    .execute()
```

---

## 6. 饮食建议（meal_advices）

完成后在 `meal_advices` 表查个性化建议：

```swift
let advice = try await supabase
    .from("meal_advices")
    .select("summary, nutrition_status, pros, cons, suggestions, next_meal_recommendation")
    .eq("meal_id", jobId)
    .single()
    .execute()
```

**数据结构：**
```json
{
  "summary": "本餐热量偏高，碳水比例超标。",
  "nutrition_status": "over_carbs",
  "pros": ["蛋白质摄入充足", "含蔬菜"],
  "cons": ["碳水化合物超出今日建议量"],
  "suggestions": ["下一餐减少主食", "增加绿叶蔬菜"],
  "next_meal_recommendation": "建议选择轻食沙拉或蒸蔬菜"
}
```

---

## 7. 错误处理

| 情况 | 处理 |
|------|------|
| `status == "failed"` | 读 `meals.pipeline_error` 字段展示原因 |
| HTTP 401 | token 过期，刷新后重试 |
| HTTP 413 | 图片超过 20 MB，压缩后重试 |
| HTTP 415 | 格式不支持（接受 JPEG/PNG/HEIC/HEIF/WebP） |
| 60s 超时无响应 | 提示用户稍后刷新，任务可能仍在后台运行 |

---

## 8. 完整流程时序

```
iPhone                    API Server              Supabase
  │                           │                      │
  │── POST /analyze ─────────>│                      │
  │<─ 202 { job_id } ─────────│                      │
  │                           │── insert meals ─────>│ status: processing
  │                           │                      │
  │── subscribe Realtime ─────────────────────────── │
  │                           │── Phase 1 完成 ──────>│ status: dishes_ready
  │<─ Realtime 推送 ───────────────────────────────── │
  │── fetchDishes() ──────────────────────────────── │
  │                           │── Phase 2 完成 ──────>│ status: complete
  │<─ Realtime 推送 ───────────────────────────────── │
  │── fetchNutrition() ───────────────────────────── │
  │── fetchAdvice() ──────────────────────────────── │
```
