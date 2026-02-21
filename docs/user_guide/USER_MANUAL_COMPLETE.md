# BioFastFree 完整用户手册

> **版本**: v11.2
> **更新日期**: 2025-01-04
> **适用人群**: 生物信息学研究人员、学生、数据分析师

---

## 📚 目录

1. [项目简介](#项目简介)
2. [快速开始](#快速开始)
3. [核心功能详解](#核心功能详解)
4. [高级功能](#高级功能)
5. [富集分析最佳实践](#富集分析最佳实践)
6. [常见问题解答](#常见问题解答)
7. [故障排除](#故障排除)
8. [附录](#附录)

---

## 项目简介

### 什么是 BioFastFree？

BioFastFree 是一个基于 R Shiny 的生物信息学分析平台，专注于转录组数据的差异表达分析和功能富集分析。

### 核心特性

#### 🧬 基础分析功能
- **差异表达分析**: 支持 limma-voom 和 edgeR 两种方法
- **富集分析**: KEGG 通路富集、GO 富集、GSEA 分析
- **韦恩图**: 多组差异基因交集分析（2-5个集合）
- **转录因子活性**: 基于 decoupleR 的 TF 活性预测
- **增强火山图**: 支持多种格式的差异基因结果可视化

#### 🎨 用户界面
- **科幻主题**: 现代化的玻璃拟态设计
- **日夜模式**: 动态主题切换
- **响应式布局**: 适配不同屏幕尺寸
- **交互式图表**: 基于 plotly 的可交互可视化

#### 🔐 用户管理
- 多用户认证系统
- 每日使用额度控制
- 数据安全存储（本地 SQLite）

### 版本历史

| 版本 | 日期 | 主要更新 |
|------|------|----------|
| v11.2 | 2025-01-03 | 多文件背景基因集、自动交集计算 |
| v11.1 | 2024-12-10 | 修复基因注释错误、增强基因匹配 |
| v11.0 | 2024-12-01 | 增强火山图、多种格式支持 |

---

## 快速开始

### 系统要求

#### 硬件要求
- **CPU**: 4核心以上推荐
- **内存**: 8GB 最低，16GB 推荐
- **硬盘**: 至少 5GB 可用空间

#### 软件要求
- **R 版本**: >= 4.0.0
- **操作系统**: Windows 10+, macOS 10.14+, Linux (Ubuntu 18.04+)

### 安装步骤

#### 1. 下载项目

```bash
# 克隆项目
git clone https://github.com/your-repo/Biofree_project.git
cd Biofree_project

# 或下载并解压 ZIP 文件
```

#### 2. 安装 R 依赖包

在 R 控制台中运行：

```r
# 安装 CRAN 包
install.packages(c(
  "shiny", "shinyjs", "bslib", "RSQLite", "DBI",
  "ggplot2", "dplyr", "DT", "pheatmap", "plotly",
  "colourpicker", "shinyWidgets", "rlang",
  "edgeR", "limma", "AnnotationDbi", "clusterProfiler",
  "decoupleR", "tibble", "tidyr", "ggrepel", "RColorBr
ewer",
  "VennDiagram", "grid", "gridExtra"
))

# 安装 Bioconductor 包
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c(
  "org.Mm.eg.db",  # 小鼠注释
  "org.Hs.eg.db",  # 人类注释
  "biofree.qyKEGGtools",
  "GseaVis",
  "enrichplot"
))
```

#### 3. 运行应用

**方法 1: 使用启动脚本（推荐）**

```bash
# Windows
launch_app.bat

# Linux/Mac
bash run_app.sh
```

**方法 2: 在 R 中运行**

```r
setwd("path/to/Biofree_project")
shiny::runApp("app.R")
```

#### 4. 访问应用

应用将在浏览器中自动打开：
- **默认地址**: http://127.0.0.1:8080
- **默认账号**: admin
- **默认密码**: 1234

---

## 核心功能详解

### 1. 数据输入模块

#### 1.1 上传 Counts 矩阵

**文件格式要求**:
- CSV 格式
- 第一列：基因 ID（Symbol 或 ENSEMBL）
- 第一行：样本名称
- 其余：表达量（整数）

**示例**:

| Gene | Control1 | Control2 | Treat1 | Treat2 |
|------|----------|----------|--------|--------|
| Actb | 1000 | 950 | 1050 | 980 |
| Gapdh | 800 | 850 | 820 | 840 |
| Tp53 | 50 | 45 | 200 | 190 |

#### 1.2 直接上传差异基因结果

如果已经有差异分析结果，可以直接上传进行富集分析。

**支持的格式**:
- DESeq2 结果
- edgeR 结果
- limma-voom 结果
- Seurat 结果

**必需列**:
- 基因 ID 列: `Gene`, `gene`, `SYMBOL`, 或 `ENSEMBL`
- 统计列: `log2FoldChange`, `logFC`, 或 `log2FC`
- P 值列: `pvalue`, `p_val`, `PValue`, 或 `padj`

### 2. 差异表达分析

#### 2.1 1V1 分析模式

**适用场景**: 单个对照组 vs 单个处理组

**步骤**:
1. 上传 Counts 矩阵
2. 选择对照组样本（1个）
3. 选择处理组样本（1个）
4. 设置参数：
   - log2FC 阈值（默认: 1）
   - P 值阈值（默认: 0.05）
   - 分析方法（limma-voom 或 edgeR）
5. 点击"运行分析"

#### 2.2 nVn 分析模式

**适用场景**: 多个对照组 vs 多个处理组

**步骤**:
1. 上传 Counts 矩阵
2. 选择多个对照组样本
3. 选择多个处理组样本
4. 设置参数
5. 点击"运行分析"

#### 2.3 结果说明

**输出表格包含**:
- 基因 ID
- log2FoldChange（对数倍数变化）
- pvalue（原始 P 值）
- padj（校正后 P 值）
- 变化方向（Up/Down/NS）

**可视化**:
- 火山图
- MA 图
- P 值分布图

### 3. KEGG 富集分析

#### 3.1 基于差异基因的 KEGG 分析

**输入**: 差异分析结果

**步骤**:
1. 完成差异分析后，切换到"KEGG 富集"标签
2. 选择基因集（上调/下调/全部）
3. 选择物种
4. 设置 P 值阈值
5. **重要**: 选择背景基因集（Universe）
6. 点击"运行富集分析"

#### 3.2 基于单列基因的 KEGG 分析

**输入**: 一列基因 ID（如从韦恩图获得）

**步骤**:
1. 上传基因列表（CSV/TXT，每行一个基因）
2. 或者在文本框中粘贴基因（用逗号或换行分隔）
3. 选择物种
4. 设置 P 值阈值
5. **重要**: 选择背景基因集
6. 点击"运行"

#### 3.3 背景基因集（Universe）设置

**⭐ 关键概念**: 背景基因集的选择直接影响富集结果的准确性！

**什么是背景基因集？**
- 所有"有机会"进入你目标基因集的基因
- 必须包含显著和不显著的基因
- 必须与你目标基因集的定义逻辑一致

**选择原则**:

| 场景 | 背景基因集选择 | 示例 |
|------|--------------|------|
| 单次差异分析 | 差异分析结果表中的所有基因 | DE_results 中的所有 20,000 行 |
| A上调 ∩ B下调 | A的所有基因 ∩ B的所有基因 | Dataset_A 和 Dataset_B 的交集 |
| 多个时间点 | 所有时间点都检测到的基因 | Time1 ∩ Time2 ∩ Time3 |
| 不知道 | 实验检测到的所有基因 | 表达矩阵中的所有基因 |

**❌ 常见错误**:
- ❌ 使用全基因组（包含未检测基因）→ 假阴性
- ❌ 只用显著基因 → 假阳性
- ❌ Target 与 Universe 逻辑不一致 → 统计错误

**详细指南**: 参见 [富集分析最佳实践](#富集分析最佳实践)

### 4. GSEA 分析

#### 4.1 基本概念

**GSEA (Gene Set Enrichment Analysis)**:
- 不需要预设阈值
- 使用所有基因的排序信息
- 检测协同表达变化
- 适用于检测微弱但一致的变化

#### 4.2 使用步骤

1. **准备基因排序列表**:
   - 按照统计量排序（如 log2FC）
   - 格式: CSV 或 TXT

2. **上传文件**:
   ```
   Gene,log2FC
   Gene1,2.5
   Gene2,1.8
   Gene3,0.3
   ...
   ```

3. **设置参数**:
   - 选择物种
   - 选择基因集数据库（KEGG/GO）
   - 设置排列次数（默认: 1000）

4. **运行分析**

#### 4.3 结果解读

**输出**:
- NES (Normalized Enrichment Score): 标准化富集分数
- FDR: 错误发现率
- Leading Edge: 核心富集基因

**可视化**:
- 富集分数图
- 山峰图
- 热图

### 5. 韦恩图分析

#### 5.1 支持的集合数量

- 2 个集合
- 3 个集合
- 4 个集合
- 5 个集合

#### 5.2 使用场景

**示例 1: 多组差异基因交集**
- 集合 1: A处理上调基因
- 集合 2: B处理下调基因
- 交集: A上调 ∩ B下调

**示例 2: 时间序列分析**
- 集合 1: 早期响应基因
- 集合 2: 中期响应基因
- 集合 3: 晚期响应基因

#### 5.3 交互功能

- **点击区域**: 查看交集基因
- **复制基因**: 一键复制到剪贴板
- **导出结果**: CSV 或 TXT 格式
- **下载图片**: 高分辨率 PNG/PDF

### 6. 转录因子活性分析

#### 6.1 基本原理

**方法**: 使用 decoupleR 的 VIPER 算法
- 从表达数据推断转录因子活性
- 基于调控网络（CollecTRI）
- 评估靶基因的富集程度

#### 6.2 使用步骤

1. **上传表达矩阵**:
   - 行：基因
   - 列：样本
   - 需要标准化（log2 CPM 或 TPM）

2. **选择调控网络**:
   - CollecTRI（推荐）
   - DoRothEA
   - 自定义网络

3. **设置参数**:
   - 方法：VIPER, ULM, 或 SCORE
   - 最小靶基因数：默认 5

4. **运行分析**

#### 6.3 结果解读

**输出**:
- TF 活性评分（正/负）
- P 值和校正 P 值
- 靶基因列表

**可视化**:
- TF 活性热图
- 活性条形图
- 网络图（TF - 靶基因）

---

## 高级功能

### 1. 多文件背景基因集 (v11.2 新功能)

#### 1.1 功能介绍

**用途**: 为交集基因富集分析提供准确的背景基因集

**适用场景**:
- A上调基因 ∩ B下调基因的富集分析
- 多数据集联合研究
- 需要准确 Universe 的富集分析

#### 1.2 使用步骤

1. **准备文件**:
   - 2-5 个 CSV 文件
   - 每个文件包含基因 ID 列

2. **上传文件**:
   - 点击"添加文件"按钮
   - 选择所有文件

3. **选择基因列**:
   - 系统自动检测（gene, Gene, SYMBOL 等）
   - 可以手动选择

4. **查看交集**:
   - 实时显示交集大小
   - 显示统计信息

5. **使用为背景基因集**:
   - 自动填充到 KEGG/GSEA 分析的 Universe 参数

#### 1.3 示例

**场景**: 分析药物处理上调但疾病下调的基因

```
文件 1: drug_up.csv（药物处理上调的 1000 个基因）
文件 2: disease_down.csv（疾病下调的 1200 个基因）

系统自动计算:
  Universe = drug_up.csv 的所有原始基因 ∩ disease_down.csv 的所有原始基因
  例如: 15,000 个基因

Target = drug_up ∩ disease_down
  例如: 150 个基因

富集分析:
  enrichKEGG(gene = 150个基因, universe = 15,000个基因)
```

### 2. 基因助手功能

#### 2.1 功能介绍

集成智谱 AI 的智能分析助手，可以：
- 解释基因功能
- 建议分析方案
- 解读富集结果
- 回答生物学问题

#### 2.2 配置

1. **获取 API Key**:
   - 访问智谱 AI 开放平台
   - 注册并获取 API Key

2. **配置应用**:
   - 在设置中输入 API Key
   - 保存配置

#### 2.3 使用方法

**方式 1: 快速提问**
- 在"基因助手"标签页
- 输入问题或基因列表
- 点击"提问"

**方式 2: 结果分析**
- 完成富集分析后
- 点击"AI 解读"按钮
- 自动生成结果解读

### 3. 芯片数据分析

#### 3.1 支持的平台

- Affymetrix
- Illumina
- Agilent
- 自定义平台

#### 3.2 分析流程

1. **上传 CEL 文件或预处理数据**
2. **探针注释**:
   - 自动进行探针到基因的注释
   - 支持最新注释包
3. **质量控制**:
   - PCA 图
   - 样本聚类
   - 表达密度图
4. **差异分析**
5. **富集分析**

---

## 富集分析最佳实践

### 背景基因集（Universe）选择指南

#### 核心原则

> **最重要的原则**: Universe 必须与 Target 的定义逻辑一致！

#### 三大铁律

**1️⃣ Universe 一定是「交集」，不是「并集」**

```
❌ 错误: Universe = A的所有基因 ∪ B的所有基因
✅ 正确: Universe = A的所有基因 ∩ B的所有基因

原因: 只有交集基因才"有资格"同时进入 A 和 B 的交集结果
```

**图解**:
```
数据集A（20,000基因）  数据集B（18,000基因）
       └────┬────┘              │
            └──────┬───────────┘
                   ↓
          ┌──────────────┐
          │ 交集 Universe  │
          │   (15,000基因) │
          └──────────────┘
```

**2️⃣ Universe 必须包含「不显著的基因」**

```
❌ 错误: Universe = 显著差异基因
✅ 正确: Universe = 所有检测到的基因（显著 + 不显著）

Universe ≠ 差异基因
Universe = 统计背景（Statistical Background）
```

**类比理解**:
- Target = 中奖号码（7个）
- Universe = 所有参与抽奖的号码（1000个）
- 不是全世界所有可能的号码！

**3️⃣ Universe 来自 DE 结果表**

```
层级1 (最优⭐⭐⭐⭐⭐):
  在表达矩阵中有表达 + 被纳入 DE 分析

层级2 (常用⭐⭐⭐⭐):
  DE 结果表中的所有基因行

层级3 (最低可用⭐⭐⭐):
  两个文件中共有的基因 ID
```

#### 完整示例

**研究设计**:
- Dataset A: 药物处理 vs 对照（小鼠）
- Dataset B: 疾病 vs 正常（小鼠）
- Target = A上调 ∩ B下调

**数据**:
```
Dataset A DE结果: 20,000 行
  - 显著上调: 1,000 个
  - 显著下调: 800 个
  - 不显著: 18,200 个

Dataset B DE结果: 18,000 行
  - 显著上调: 900 个
  - 显著下调: 1,200 个
  - 不显著: 15,900 个
```

**✅ 正确的 Universe**:
```r
# 提取所有基因（显著 + 不显著）
all_genes_A <- Dataset_A$Gene  # 20,000 个
all_genes_B <- Dataset_B$Gene  # 18,000 个

# 计算交集
Universe <- all_genes_A ∩ all_genes_B  # 15,000 个

# 验证
target_genes <- intersect(up_A, down_B)  # 150 个
all(target_genes %in% Universe)  # TRUE
```

**富集分析**:
```r
enrichKEGG(
  gene = target_genes,     # 150 个
  universe = Universe,      # 15,000 个
  organism = "mmu"
)
```

#### 常见错误

| 错误做法 | 后果 |
|---------|------|
| 使用全基因组（50,000+基因） | 稀释信号，假阴性 |
| 只用显著基因 | 夸大富集，假阳性 |
| Universe 与 Target 逻辑不一致 | 统计空间错误 |

#### 快速检查清单

在进行富集分析前，检查：

- [ ] Universe 是交集（∩），不是并集（∪）
- [ ] Universe 包含不显著基因
- [ ] Universe 来自 DE 结果表
- [ ] Target ⊆ Universe
- [ ] Universe 大小合理（100 < Universe < 全基因组）
- [ ] 记录了 Universe 的选择依据

### 代码模板

```r
# 完整的交集基因富集分析
library(clusterProfiler)
library(org.Mm.eg.db)

# 1. 定义 Target
up_A <- Dataset_A[Dataset_A$log2FC > 1 & Dataset_A$padj < 0.05, ]
down_B <- Dataset_B[Dataset_B$log2FC < -1 & Dataset_B$padj < 0.05, ]
target_genes <- intersect(up_A, down_B)

# 2. 定义 Universe（关键！）
universe_A <- Dataset_A$Gene  # A 中所有基因
universe_B <- Dataset_B$Gene  # B 中所有基因
universe <- intersect(universe_A, universe_B)  # 交集

# 3. 验证
stopifnot(all(target_genes %in% universe))

# 4. 富集分析
result <- enrichKEGG(
  gene = target_genes,
  universe = universe,
  organism = "mmu",
  pvalueCutoff = 0.05
)

# 5. 可视化
library(enrichplot)
dotplot(result, showCategory = 20)
```

---

## 常见问题解答

### Q1: 如何选择差异分析方法？

**limma-voom vs edgeR**:

| 特性 | limma-voom | edgeR |
|------|-----------|-------|
| 适用样本量 | 大样本（n>10） | 小样本（n<10） |
| 速度 | 快 | 较慢 |
| 稳定性 | 高 | 中等 |
| 推荐 | ✅ 首选 | 小样本时使用 |

**建议**:
- 默认使用 limma-voom
- 重复数 < 3 时考虑 edgeR
- 两种方法都可以尝试，比较结果

### Q2: 富集分析没有显著结果怎么办？

**可能原因**:
1. 基因列表太小（< 20 个）
2. P 值阈值太严格
3. 背景基因集选择错误
4. 基因 ID 类型不匹配

**解决方法**:
```r
# 1. 检查基因数量
length(target_genes)  # 应该 > 20

# 2. 降低 P 值阈值
pvalueCutoff = 0.1  # 或更高

# 3. 检查 Universe
length(universe)  # 应该合理
all(target_genes %in% universe)  # 应该为 TRUE

# 4. 检查基因 ID
head(target_genes)  # 查看 ID 类型
# 应该统一：全部 Symbol 或全部 ENSEMBL
```

### Q3: 如何处理 Ensembl ID 和 Symbol？

**转换方法**:

```r
library(org.Mm.eg.db)
library(clusterProfiler)

# Ensembl -> Symbol
ensembl_to_symbol <- function(ensembl_ids) {
  genes <- bitr(
    ensembl_ids,
    fromType = "ENSEMBL",
    toType = "SYMBOL",
    OrgDb = org.Mm.eg.db
  )
  return(genes$SYMBOL)
}

# Symbol -> Entrez
symbol_to_entrez <- function(symbols) {
  genes <- bitr(
    symbols,
    fromType = "SYMBOL",
    toType = "ENTREZID",
    OrgDb = org.Mm.eg.db
  )
  return(genes$ENTREZID)
}
```

### Q4: 应用运行缓慢怎么办？

**优化建议**:

1. **关闭不必要的分析**:
   - 不要同时运行多个分析
   - 完成一个再开始下一个

2. **减少数据量**:
   - 过滤低表达基因
   - 使用合理阈值

3. **关闭浏览器扩展**:
   - 某些扩展可能影响性能

4. **增加 R 内存**:
   ```r
   # 在启动前设置
   options(java.parameters = "-Xmx8g")
   ```

### Q5: 如何导出高质量图片？

**方法**:

1. **应用内导出**:
   - 点击"下载图片"按钮
   - 选择格式（PNG/PDF）
   - 设置分辨率（DPI: 300-600）

2. **R 代码导出**:
   ```r
   # 在 R 控制台
   library(ggplot2)
   ggsave("figure.pdf", width = 10, height = 8, dpi = 300)
   ```

3. **浏览器截图**:
   - 使用 Chrome 开发者工具的截图功能
   - 或者使用系统截图工具

### Q6: 数据库更新失败怎么办？

**问题**: "不能锁定目录"错误

**解决方法**:

1. **关闭其他 R 进程**:
   - 关闭 RStudio
   - 打开任务管理器，结束所有 R.exe 进程

2. **手动更新**:
   ```r
   BiocManager::install('org.Mm.eg.db', update = TRUE)
   BiocManager::install('org.Hs.eg.db', update = TRUE)
   ```

3. **删除锁文件**:
   ```r
   file.remove("C:/Users/.../00LOCK")
   ```

4. **临时禁用自动更新**:
   ```r
   Sys.setenv(AUTO_UPDATE_DB = "FALSE")
   ```

详见 [故障排除](#故障排除)

### Q7: 如何批量处理多个数据集？

**方法 1: 逐个处理**
- 使用应用的导入/导出功能
- 保存中间结果

**方法 2: R 脚本自动化**
```r
# 创建处理脚本
datasets <- list(
  "data1.csv",
  "data2.csv",
  "data3.csv"
)

results <- lapply(datasets, function(file) {
  # 读取数据
  data <- read.csv(file)

  # 差异分析
  # ... 分析代码 ...

  # 返回结果
  return(result)
})

# 合并结果
final_result <- do.call(rbind, results)
```

### Q8: 单个基因可以进行富集分析吗？

**问题**: 输入一个基因时富集分析失败

**原因**: 富集分析需要一定数量的基因（通常 > 5）

**解决方案**:

1. **添加参考基因**:
   ```r
   # 将目标基因与看家基因组合
   genes <- c(target_gene, "Actb", "Gapdh", "Tbp")
   ```

2. **使用单个基因查询**:
   - 应用支持单基因 KEGG 查询
   - 会使用特殊的查询模式

3. **解释**: 单个基因无法进行统计检验
   - 富集分析基于超几何分布
   - 需要足够的样本量

---

## 故障排除

### 问题 1: 应用无法启动

**症状**: 点击运行后浏览器打不开

**诊断**:
```r
# 检查端口占用
# Windows
netstat -ano | findstr :8080

# 检查 R 版本
R.version.string
```

**解决方法**:

1. **更换端口**:
   ```r
   # 在 launch_app.R 中修改
   shiny::runApp("app.R", port = 8081)
   ```

2. **检查防火墙**:
   - 允许 R 访问网络
   - 关闭 VPN

3. **重新安装 Shiny**:
   ```r
   install.packages("shiny")
   ```

### 问题 2: 数据库锁定错误

**错误信息**:
```
Error in sqliteExecStatement: database is locked
```

**原因**: 多个 R 会话同时访问数据库

**解决方法**:

1. **快速修复**:
   ```r
   source("scripts/cleanup/cleanup_r_locks.R")
   ```

2. **重启 R**:
   - 完全关闭 R
   - 重新启动应用

3. **优化连接**:
   - 确保数据库连接正确关闭
   - 使用 `on.exit(dbDisconnect(con))`

详见 [BUG_FIX_MANUAL.md](docs/bug_fixes/DB_LOCK_ERROR_FIX.md)

### 问题 3: KEGG 查询失败

**错误信息**:
```
Error: 无法连接 KEGG API
```

**诊断**:
```r
# 测试网络连接
tryCatch({
  KEGGREST::keggList("organism")
  print("网络连接正常")
}, error = function(e) {
  print("网络连接失败:", e$message)
})
```

**解决方法**:

1. **检查网络**:
   - 确保网络连接正常
   - 检查防火墙设置

2. **使用本地数据库**:
   - 应用使用本地 KEGG 数据库
   - 自动离线模式

3. **调整超时**:
   ```r
   options(timeout = 60)
   ```

### 问题 4: 基因注释失败

**错误信息**:
```
Error: Cannot retrieve Ensembl annotation
```

**原因**:
- Ensembl 服务不可用
- 网络问题
- ID 版本不匹配

**解决方法**:

1. **使用本地注释**:
   ```r
   library(org.Mm.eg.db)
   # 本地数据库，不需要网络
   ```

2. **重试机制**:
   ```r
   # 添加重试逻辑
   for (i in 1:3) {
     result <- tryCatch({
       annotate_genes(genes)
     }, error = function(e) {
       if (i < 3) {
         Sys.sleep(2)
       } else {
         stop(e)
       }
     })
   }
   ```

3. **更新注释包**:
   ```r
   BiocManager::install("org.Mm.eg.db")
   ```

### 问题 5: 内存不足

**错误信息**:
```
Error: cannot allocate vector of size...
```

**解决方法**:

1. **增加 R 内存限制**:
   ```r
   # Windows
   memory.limit(size = 16000)  # 16GB

   # 查看当前限制
   memory.limit()
   ```

2. **处理大数据**:
   ```r
   # 分批处理
   batches <- split(genes, ceiling(seq_along(genes) / 1000))

   results <- lapply(batches, function(batch) {
     # 分析代码
   })
   ```

3. **过滤数据**:
   - 移除低表达基因
   - 使用合理的阈值

### 问题 6: 图表显示异常

**症状**: 图表不显示或显示错误

**诊断**:
```r
# 检查数据
str(plot_data)
summary(plot_data)

# 测试绘图
library(ggplot2)
ggplot(data, aes(x, y)) + geom_point()
```

**解决方法**:

1. **清除缓存**:
   - 浏览器 Ctrl+Shift+Delete
   - 清除缓存和 Cookie

2. **更新浏览器**:
   - 使用最新版 Chrome/Firefox
   - 或尝试 Edge

3. **检查数据格式**:
   - 确保数据框格式正确
   - 没有缺失值或异常值

4. **启用调试**:
   ```r
   Sys.setenv(SHINY_DEBUG = "TRUE")
   ```

---

## 附录

### A. 支持的基因 ID 类型

| ID 类型 | 示例 | 转换工具 |
|---------|------|----------|
| Entrez ID | 12345, 67890 | org.Mm.eg.db |
| Ensembl Gene ID | ENSMUSG00000012345 | biomaRt |
| Gene Symbol | Actb, Gapdh | AnnotationDbi |
| RefSeq ID | NM_00123456 | org.Mm.eg.db |

### B. 支持的物种

| 物种 | 代码 | 注释包 |
|------|------|--------|
| 小鼠 | mmu | org.Mm.eg.db |
| 人类 | hsa | org.Hs.eg.db |
| 大鼠 | rno | org.Rn.eg.db |

### C. 常用统计阈值

| 分析类型 | log2FC | P 值 |
|---------|--------|------|
| 差异分析（严格） | 2 | 0.001 |
| 差异分析（标准） | 1 | 0.05 |
| 差异分析（宽松） | 0.5 | 0.1 |
| 富集分析 | - | 0.05 |

### D. 数据格式示例

#### DESeq2 结果格式
```csv
Gene,baseMean,log2FoldChange,lfcSE,stat,pvalue,padj
Gene1,100.5,2.3,0.5,4.6,0.00001,0.001
Gene2,80.2,-1.8,0.4,-4.5,0.00002,0.002
```

#### edgeR 结果格式
```csv
Gene,logFC,logCPM,PValue,FDR
Gene1,2.5,5.2,0.00001,0.001
Gene2,-2.0,4.8,0.00002,0.002
```

#### 基因列表格式
```csv
Gene
Actb
Gapdh
Tp53
```

或

```
Actb
Gapdh
Tp53
```

### E. 参考资源

#### 官方文档
- [clusterProfiler](https://guangchuangyu.github.io/software/clusterProfiler/)
- [edgeR](https://bioconductor.org/packages/edgeR/)
- [limma](https://bioconductor.org/packages/limma/)
- [Shiny](https://shiny.rstudio.com/)

#### 学习资源
- [生物信息学最佳实践](https://www.bioconductor.org/help/course-materials/)
- [KEGG 通路数据库](https://www.genome.jp/kegg/)
- [GO 基因本体论](http://geneontology.org/)

#### 社区支持
- [Bioconductor 支持论坛](https://support.bioconductor.org/)
- [Stack Overflow - R 标签](https://stackoverflow.com/questions/tagged/r)
- [GitHub Issues](https://github.com/your-repo/issues)

### F. 快捷键

| 操作 | Windows/Linux | Mac |
|------|--------------|-----|
| 中断分析 | Esc | Esc |
| 刷新页面 | Ctrl+F5 | Cmd+Shift+R |
| 开发者工具 | Ctrl+Shift+I | Cmd+Option+I |
| 全屏 | F11 | Ctrl+Cmd+F |

### G. 文件路径规范

**Windows**:
```
C:\Users\Username\Documents\data.csv
或
C:/Users/Username/Documents/data.csv  # 推荐
```

**避免**:
```
❌ C:\Program Files\data.csv  # 需要管理员权限
❌ 包含中文或特殊字符的路径
❌ 过长的路径（> 260 字符）
```

---

## 更新日志

### v11.2 (2025-01-03)
- ✅ 多文件背景基因集上传
- ✅ 自动交集计算
- ✅ 增强的错误提示
- ✅ 性能优化

### v11.1 (2024-12-10)
- ✅ 修复基因注释错误
- ✅ 增强基因匹配算法
- ✅ 动态列名检测

### v11.0 (2024-12-01)
- ✅ 增强火山图
- ✅ 多格式支持
- ✅ 数据验证增强

---

## 联系与支持

### 获取帮助

1. **查阅文档**:
   - 用户手册（本文档）
   - Bug 修复手册 (BUG_FIX_MANUAL.md)
   - KEGG 调试指南 (KEGG_DEBUG_GUIDE.md)

2. **运行诊断**:
   ```r
   source("scripts/tests/diagnose_syntax.R")
   diagnose_biofree()
   ```

3. **提交问题**:
   - GitHub Issues
   - 邮件支持

### 贡献指南

欢迎贡献代码、报告 Bug 或提出建议！

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

---

**文档维护**: 本文档会持续更新，请以最新版本为准。

**最后更新**: 2025-01-04
