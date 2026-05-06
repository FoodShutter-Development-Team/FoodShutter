# 进度记录

## 已完成：阶段 1 — 图片 → BBox（Steps 1–3）

### 实现

| 模块 | 文件 | 说明 |
|---|---|---|
| Step 1 检测 | `pipeline/step1_detection.py` | Gemini 3 Flash，输出 `bbox_2d [y1,x1,y2,x2]` 0–1000坐标，转换为 `[x1,y1,x2,y2]` 归一化 |
| Step 2 后处理 | `pipeline/step2_postprocess.py` | IoU NMS → 包含关系抑制（>72%） → 面积过滤（2%–65%）→ 边缘标记 |
| Step 3 一致性 | `pipeline/step3_vlm_verify.py` | 过滤保留率 <10% 时回退（极端安全网，实际从未触发） |
| 流水线 | `pipeline/bbox_pipeline.py` | 串联 Step 1–3 |
| 可视化 | `pipeline/visualization.py` | Pillow 绘制彩色 bbox + 标签 |
| 评估 | `run_eval.py` | 跑全量数据集，输出 JSON + 可视化 + summary |

### 方案选型结果

| 方案 | MAE | 耗时 | 结论 |
|---|---|---|---|
| Grounding DINO + 后处理 | 1.85 | 1.4s | 快但标签差、近景漏检 |
| qwen3.5:9b (Ollama) | 5.9 | 95s | 慢且密集场景爆框，放弃 |
| **Gemini 3 Flash** | **1.88** | 24s | 标签精准、复杂场景稳定，**采用** |

### 评估结果（17/20，后3张触发免费配额）

- count MAE：1.88，fallback 率：0%
- 输出：`results/bbox/meal_XX.json` + `results/bbox/visualizations/`

### 关键参数

```python
MODEL = "gemini-3-flash-preview"
box_threshold (NMS IoU) = 0.50
containment_threshold   = 0.72
min_area_ratio          = 0.02   # 过滤 < 2% 的框
max_area_ratio          = 0.65   # 过滤 > 65% 的背景框
drop_tolerance          = 0.90   # Step 3 回退阈值
```

### 运行方式

```bash
GOOGLE_API_KEY=<key> uv run python run_eval.py            # 全量
GOOGLE_API_KEY=<key> uv run python run_eval.py meal_01.jpg  # 单张
```

---

## 待做：阶段 2 — BBox → 营养分析（Steps 4–7）

按 `docs/pipeline_design_v2.md` 设计：

- Step 4：VLM 主分析（全图 + bbox 列表 → 菜名/原料/份量 JSON）
- Step 5：向量库检索营养信息
- Step 6：LLM 决策层（选条目 + 补全 + 合理性校验）
- Step 7：结果组装与置信度分级输出
