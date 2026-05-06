# Foodshutter — 营养向量数据库搭建 任务细化

> **负责人**：Zhou Yunhui  
> **技术栈**：Python + ChromaDB + 本地 Embedding 模型  
> **数据源**：USDA FoodData Central — Foundation Foods

---

## 一、数据获取与清洗

### 工作内容

- 从 USDA FoodData Central 下载 Foundation Foods 数据集（JSON 或 CSV 格式）
  - 下载地址：https://fdc.nal.usda.gov/download-datasets
  - 选择 **Foundation Foods** 类型，获取完整数据包
- 解析原始数据，提取以下核心字段：
  - `fdc_id`：食物唯一标识
  - `description`：食物名称（英文）
  - `foodNutrients` 中筛选三大宏量营养素：
    - **Protein**（蛋白质，nutrientId: 1003）
    - **Total lipid (fat)**（脂肪，nutrientId: 1004）
    - **Carbohydrate, by difference**（碳水化合物，nutrientId: 1005）
  - 营养素数值统一为 **每 100g 含量（g）**
- 数据清洗规则：
  - 去除 description 为空或营养素数据缺失的条目
  - 去重（同名食物取最新版本）
  - 统一文本格式：小写化、去除多余空格和特殊字符

### 交付标准

- 输出清洗后的结构化数据文件 `foundation_foods_cleaned.json`，单条格式：

```json
{
  "fdc_id": 321360,
  "name": "egg, whole, raw",
  "protein_g": 12.56,
  "fat_g": 9.51,
  "carbohydrate_g": 0.72
}
```

- 附带数据清洗报告：原始条目数、清洗后条目数、丢弃原因统计
- 数据完整性要求：三大营养素字段 **零缺失**

---

## 二、Embedding 模型选型与向量化

### 工作内容

- 选用本地 Embedding 模型，推荐方案（按优先级）：
  1. `stella_en_1.5B_v5`（轻量，384 维，适合快速部署）
  2. `BAAI/bge-small-en-v1.5`（效果更优，384 维）
- 对每条食物的 `name` 字段进行 embedding，生成向量
- 向量与结构化营养数据一同存入 ChromaDB

### 交付标准

- 模型文件下载至本地，**不依赖外部 API 调用**
- 提供模型选型说明文档，包含：模型名称、维度、大小、选择理由
- 向量化脚本支持一键重建（数据更新时可重新执行）

---

## 三、ChromaDB 数据库搭建

### 工作内容

- 使用 ChromaDB 创建持久化 collection，存储结构：
  - **documents**：食物名称（用于语义搜索）
  - **embeddings**：由本地模型生成的向量
  - **metadatas**：结构化营养数据（fdc_id、protein_g、fat_g、carbohydrate_g）
- 数据库持久化至本地目录（如 `./chroma_db/`）
- 编写初始化脚本 `build_db.py`，功能：
  - 读取清洗后的数据
  - 批量生成 embedding
  - 写入 ChromaDB
  - 输出构建统计（总条目数、耗时等）

### 交付标准

- 运行 `python build_db.py` 即可从零构建完整数据库
- 构建完成后打印摘要：总条目数、向量维度、数据库文件大小
- 数据库文件可随项目分发，无需每次重建

---

## 四、查询接口设计与实现

### 接口总览

提供 Python 模块 `nutrition_db.py`，暴露统一的查询类 `NutritionVectorDB`。

---

### 接口 1：语义搜索

```python
def search_by_name(
    self,
    query: str,
    top_k: int = 5
) -> list[dict]
```

- **功能**：根据输入的原料名称，利用 embedding 语义相似度进行模糊搜索
- **参数**：
  - `query`：原料名称关键词（如 `"chicken breast"`、`"rice"`）
  - `top_k`：返回结果数量，默认 5
- **返回**：按相似度从高到低排序，每项包含：

```python
{
    "name": "Chicken, breast, meat only, raw",
    "similarity": 0.92,
    "protein_g": 22.5,
    "fat_g": 2.62,
    "carbohydrate_g": 0.0,
    "fdc_id": 331960
}
```

---

### 接口 2：精确搜索

```python
def search_exact(
    self,
    query: str,
    top_k: int = 5
) -> list[dict]
```

- **功能**：基于字符串匹配进行精确/子串搜索，适用于已知明确名称的场景
- **返回**：按匹配准确度排序（完全匹配 > 前缀匹配 > 包含匹配），`similarity` 替换为 `match_score`

---

### 接口 3：统一搜索（推荐对外暴露）

```python
def search(
    self,
    query: str,
    top_k: int = 5,
    mode: str = "semantic"   # "semantic" | "exact" | "hybrid"
) -> list[dict]
```

- **功能**：统一入口，通过 `mode` 切换搜索策略
  - `semantic`：纯语义搜索
  - `exact`：纯精确搜索
  - `hybrid`：先精确匹配，不足 top_k 时用语义搜索补充，去重合并
- **返回格式统一**：

```python
{
    "name": str,
    "score": float,
    "protein_g": float,
    "fat_g": float,
    "carbohydrate_g": float,
    "fdc_id": int
}
```

---

### 接口交付标准

- 所有接口附带 **type hints** 和 **docstring**
- 提供 `test_nutrition_db.py` 测试脚本，覆盖：
  - 常见食物搜索（egg、rice、milk、chicken）
  - 模糊输入（拼写不完整、近义词）
  - top_k 边界测试（1、10、超过数据库总量）
  - 三种 mode 结果对比
- 单次查询响应时间 **< 200ms**（本地环境）

---

## 五、项目结构

```
nutrition_vector_db/
├── README.md                   # 使用说明
├── requirements.txt            # 依赖清单
├── data/
│   ├── raw/                    # USDA 原始数据
│   └── foundation_foods_cleaned.json
├── models/                     # 本地 embedding 模型缓存
├── chroma_db/                  # ChromaDB 持久化目录
├── clean_data.py               # 数据清洗脚本
├── build_db.py                 # 数据库构建脚本
├── nutrition_db.py             # 查询接口模块
└── test_nutrition_db.py        # 测试脚本
```

### README 要求

- 环境要求（Python 版本、系统依赖）
- 一键安装：`pip install -r requirements.txt`
- 构建流程：`python clean_data.py` → `python build_db.py`
- 调用示例：至少 3 个完整代码示例
- 已知限制与后续优化方向

---

## 六、交付物与验收一览

| 交付物 | 说明 | 验收标准 |
|--------|------|----------|
| `foundation_foods_cleaned.json` | 清洗后结构化数据 | 三大营养素零缺失，格式正确 |
| `build_db.py` | 数据库一键构建脚本 | 运行无报错，输出统计信息 |
| `nutrition_db.py` | 查询接口模块 | 三个接口功能正确，响应 < 200ms |
| `test_nutrition_db.py` | 测试脚本 | 全部用例通过 |
| `README.md` | 使用说明文档 | 新成员按文档可独立跑通全流程 |
| 数据清洗报告 | 清洗过程记录 | 含原始/清洗后条目数及丢弃统计 |
| 模型选型说明 | Embedding 模型选择理由 | 含模型名、维度、大小、benchmark |
