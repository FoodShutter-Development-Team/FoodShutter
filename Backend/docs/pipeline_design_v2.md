# VLM 营养分析 Pipeline 设计方案（v2）

## 一、整体架构

```
输入：餐桌图片
   │
   ▼
[Step 1] 菜品检测（分割模型 输出 bbox）
   │
   ▼
[Step 2] Bbox 后处理（NMS + 面积过滤）
   │
   ▼
[Step 3] VLM 计数校验 ──不一致──┐
   │ 一致                      │
   │                           ▼
   │                  [Fallback] VLM grounding 直接出 bbox
   │                           │
   ▼◄──────────────────────────┘
[Step 4] VLM 主分析（全图高清 + bbox 列表，逐框输出结构化结果）
   │
   ▼
[Step 5] 向量库检索营养信息（每个原料 top-k 候选）
   │
   ▼
[Step 6] LLM 决策层（选营养条目 + 原料合理性校验 + 未命中补全）
   │
   ▼
[Step 7] 结果组装与输出（带置信度分级）
```

## 二、各模块详细设计

### Step 1：菜品检测

- **模型**：SAM2 / FoodSeg 预训练模型，或直接用支持 grounding 的 VLM
- **输入**：原始餐桌图片
- **输出**：每道菜的 bounding box 列表 `[(x1,y1,x2,y2), ...]`
- **设计取舍**：用 bbox 而非 mask，下游 VLM 不需要像素级精度，bbox 更鲁棒、错误恢复更容易

### Step 2：Bbox 后处理

零成本但有效的清洗步骤：

- **NMS 合并**：IoU > 0.5 的框合并，避免一道菜被切成多个
- **面积过滤**：丢弃面积小于全图 2% 的框（多半是酱料碟、餐具误检）
- **边缘过滤**：完全贴在图像边缘的框标记为低置信（可能是不完整菜品）

### Step 3：VLM 计数校验（防错关键）

- **调用**：让 VLM 看全图回答"这桌上有几道独立的菜品？"
- **比对**：VLM 数量 vs Step 2 的 bbox 数量
  - 一致 → 进入 Step 4 主流程
  - 不一致 → 触发 Fallback

**Fallback 路径**：直接让 VLM 在全图上做 grounding，输出 bbox 列表，跳过原本的分割模型。即使分割失败，pipeline 也能退化到一个"VLM-only 但仍优于 baseline"的状态，避免错误传播。

### Step 4：VLM 主分析

**输入**：全图（高清）+ bbox 坐标列表

**Prompt 设计要点**：

- 请 VLM 在全图语境下"聚焦看第 i 个框"逐个分析，保留全局上下文
- 同时识别容器类型（饭碗 ≈ 250ml、菜盘 ≈ 25cm、汤碗 ≈ 15cm）+ 装盛比例作为隐性尺度参照
- 份量按 小份/中份/大份 三档输出对应预设克数（如 150 / 250 / 350g），比让模型直接报具体数字更稳定

**输出 JSON 结构**：

```json
{
  "dishes": [
    {
      "bbox_id": 1,
      "dish_name": "宫保鸡丁",
      "container": "中号菜盘",
      "portion_size": "中份",
      "estimated_total_grams": 250,
      "ingredients": [
        {"name": "鸡胸肉", "grams": 120, "cooking": "炒"},
        {"name": "花生", "grams": 30, "cooking": "炸"},
        {"name": "葱姜蒜", "grams": 15, "cooking": "炒"}
      ],
      "confidence": "high"
    }
  ]
}
```

### Step 5：向量库检索

- 对每个 `ingredient.name` 检索营养数据库
- 返回 top-k（建议 k=3–5）候选条目，附带 metadata（生熟状态、烹饪方式、部位等）
- 不在这一步做选择，把选择权交给 Step 6 的 LLM

### Step 6：LLM 决策层（三职责）

一次 LLM 调用完成三件事：

**职责 A：营养条目选择（DB 命中时）**

- 输入：原料名 + 烹饪方式 + top-k 候选条目
- 输出：选定的条目 ID 及对应营养数据
- 标记 `source: "database"`，置信度 high

**职责 B：营养信息补全（DB 未命中时）**

- 让 LLM 用其参数化知识估算蛋白质/脂肪/碳水百分比
- 标记 `source: "llm_estimated"`，置信度 low
- Prompt 中要求 LLM 参考相似原料给出数值，避免数字过于离谱
- 如果 LLM 自己也判断不出，再降级为类目均值

**职责 C：原料合理性校验（软先验）**

- 让 LLM 用其参数化知识判断："这道菜叫 X，VLM 识别出的原料是 [...]，是否合理？"
- 不合理项标记为低置信，但不强制删除
- 这一步替代了菜谱数据库，零额外架构

### Step 7：结果组装

每个原料的输出带 `source` 和 `confidence` 字段，前端/报告中分级展示：

- **高置信**（DB 命中 + LLM 校验通过）→ 正常展示
- **中置信**（DB 命中但 LLM 校验存疑 / 份量为模糊估计）→ 标注"估算"
- **低置信**（DB 未命中，LLM 补全）→ 标注"AI 估算，仅供参考"

**最终输出示例**：

```json
{
  "dish_name": "宫保鸡丁",
  "total_grams": 250,
  "portion_confidence": "medium",
  "ingredients": [
    {
      "name": "鸡胸肉",
      "grams": 120,
      "nutrition": {"protein": 23, "fat": 2, "carb": 0},
      "source": "database",
      "confidence": "high"
    },
    {
      "name": "宫保酱汁",
      "grams": 25,
      "nutrition": {"protein": 3, "fat": 8, "carb": 15},
      "source": "llm_estimated",
      "confidence": "low"
    }
  ]
}
```

## 三、防错与降级策略汇总

| 风险点 | 防御手段 | 成本 |
|--------|----------|------|
| 分割错误（多切/漏切） | NMS + 面积过滤 + VLM 计数校验 | 极低 |
| 分割模型完全失败 | Fallback 到 VLM grounding | 低 |
| 克数估计离谱 | 容器识别 + 三档份量预设 | 零 |
| 原料误识别 | LLM 软先验交叉校验 | 一次 LLM 调用（已有） |
| 数据库未命中 | LLM 补全 + 显式 source/confidence 标记 | 零（已有调用） |

## 四、评估方案（建议写入报告）

**测试集**：自拍餐桌图 10–20 张，人工标注 ground truth（菜名、原料、克数、营养值）

**对比组**：

- Baseline：整图直接进 VLM，要求一次性输出所有信息
- 本方案完整版
- 消融 a：去掉分割（验证分割模块的贡献）
- 消融 b：去掉 RAG（验证向量库的贡献）
- 消融 c：去掉 LLM 校验层（验证软先验的贡献）

**评估指标**：

- 菜名识别准确率
- 原料召回率 / 准确率
- 克数相对误差（MAPE）
- 营养值（蛋白质/脂肪/碳水）相对误差
- DB 命中率 vs LLM 补全率（体现 RAG 模块的实际工作量）

**加分项**：在报告中讨论 fallback 触发率、不同 VLM 模型的对比、深度估计为何未采用等设计决策的权衡。
