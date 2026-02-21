# 富集分析背景基因集（Universe/Background）完整指南

> **创建日期**: 2025-01-03
> **重要性**: ⭐⭐⭐⭐⭐
> **适用场景**: KEGG、GO、GSEA等所有功能富集分析

---

## 📚 目录

1. [核心问题定义](#核心问题定义)
2. [Universe/Background的定义原则](#universebackground的定义原则)
3. [常见错误场景](#常见错误场景)
4. [最佳实践](#最佳实践)
5. [代码实现](#代码实现)
6. [实例分析](#实例分析)

---

## 核心问题定义

### 1️⃣ 研究场景

**场景：双数据集差异基因交集富集分析**

有两个独立的数据集：
- **Dataset A**（如：处理组 vs 对照组）
- **Dataset B**（如：疾病组 vs 健康组）

每个数据集都进行了差异表达分析（DE analysis）

**研究目标**：
```
Target gene set = A上调基因 ∩ B下调基因
对Target进行功能富集分析（KEGG/GO）
```

### 2️⃣ 富集分析的统计本质

富集分析是在回答：

> **在"有资格被选中"的所有基因中，当前目标基因集合是否在某些通路/功能中显著集中？**

关键统计概念：
- **Target gene set（目标基因集）**: 你想研究的一组基因
- **Universe / Background gene set（背景基因集）**: 所有"有资格"被选中的基因

**类比理解**：
- 🎯 就像从抽奖池中抽奖
- Target = 中奖的号码
- Universe = 所有参与抽奖的号码（不是全世界所有可能的号码！）

---

## Universe/Background的定义原则

### ✅ 正确的Universe定义

**核心原则**：
> **Universe = 所有"理论上有机会进入 Target"的基因**

### 具体来说：

对于 **A上调 ∩ B下调** 的交集分析：

```r
Universe = 在 Dataset A 和 Dataset B 中都被检测到、并参与差异分析的所有基因
```

**Universe包含的基因**：
- ✅ Dataset A中的显著差异基因（上调+下调）
- ✅ Dataset A中的不显著基因
- ✅ Dataset B中的显著差异基因（上调+下调）
- ✅ Dataset B中的不显著基因
- ✅ 上调、下调、无变化的基因

**关键条件**：
- 基因必须在 **A 和 B 中都出现过**
- 基因必须 **参与了DE分析**（在表达矩阵中、在DE结果表中）

### ❌ 错误的Universe定义

以下是常见的错误做法：

| 错误定义 | 为什么错误 |
|---------|-----------|
| ❌ Universe = 全基因组（所有20,000+基因） | 包含了从未被检测到的基因，稀释统计显著性 |
| ❌ Universe = 仅显著差异基因 | 忽略了不显著基因，造成富集假阳性 |
| ❌ Universe = 仅A上调基因 | 人为限制了背景范围，统计错误 |
| ❌ Universe = Target基因集 | 完全错误，无法做富集分析 |
| ❌ Universe = A的检测基因 ∪ B的检测基因 | 包含了只在一个集中出现的基因，它们不可能进入交集 |

---

## "被检测到"的技术定义

### 📊 层级1：最优定义（推荐）

**在表达矩阵中有表达 + 被纳入DE分析**

```r
# Dataset A的Universe
universe_A <- all_genes_in_DE_table_A
# 即DESeq2/limma/edgeR输出表中的所有基因行

# Dataset B的Universe
universe_B <- all_genes_in_DE_table_B

# 交集分析的Universe
universe_intersection <- universe_A ∩ universe_B
```

**优点**：
- ✅ 最准确反映实验设计
- ✅ 包含所有参与分析的基因
- ✅ 统计效力最强

### 📋 层级2：常用定义

**DE结果表中所有基因行**

```r
# 例如从DESeq2结果中
universe_A <- rownames(DE_results_A)
universe_B <- rownames(DE_results_B)

universe_intersect <- intersect(universe_A, universe_B)
```

**优点**：
- ✅ 易于获取
- ✅ 包含所有测试过的基因
- ✅ 可靠性高

### 🔍 层级3：最低可接受

**A与B的基因ID交集**

```r
# 从表达矩阵中
genes_A <- rownames(count_matrix_A)
genes_B <- rownames(count_matrix_B)

universe <- intersect(genes_A, genes_B)
```

**缺点**：
- ⚠️ 可能包含低表达基因
- ⚠️ 可能被过滤步骤影响

**仅在前两个定义不可用时使用**

---

## 常见错误场景

### 🚫 错误场景1：使用全基因组作为Universe

```r
# ❌ 错误做法
library(org.Mm.eg.db)
all_genes <- keys(org.Mm.eg.db)  # 获取全基因组

enrichKEGG(
  gene = target_genes,
  universe = all_genes,  # ❌ 包含了未检测基因！
  organism = "mmu"
)
```

**问题**：
- 包含了在你的实验中从未被检测到的基因
- 这些基因不可能出现在你的Target中
- 会导致统计显著性被稀释（假阴性）
- **P值不准确**

**影响**：
- 真实的富集信号可能被掩盖
- 漏检真实的生物学通路

### 🚫 错误场景2：仅用显著基因作为Universe

```r
# ❌ 错误做法
sig_genes_A <- DE_results_A[DE_results_A$padj < 0.05, ]
sig_genes_B <- DE_results_B[DE_results_B$padj < 0.05, ]

universe <- union(sig_genes_A, sig_genes_B)  # ❌ 只有显著基因！

enrichKEGG(
  gene = target_genes,
  universe = universe,  # ❌ 缺少不显著基因
  organism = "mmu"
)
```

**问题**：
- 人为增加了富集比例
- **产生假阳性结果**
- 例如：如果Target中有5个基因属于某通路，而Universe中只有100个基因（实际应该有10000个），该通路会显得高度"富集"

**影响**：
- 高度不显著的结果变得"显著"
- **产生假生物学发现**

### 🚫 错误场景3：Universe不包含交集条件

```r
# ❌ 错误做法
# Target = A上调 ∩ B下调
target_up_A <- DE_results_A[DE_results_A$log2FC > 1 & DE_results_A$padj < 0.05, ]
target_down_B <- DE_results_B[DE_results_B$log2FC < -1 & DE_results_B$padj < 0.05, ]
target_genes <- intersect(target_up_A, target_down_B)

# 但Universe用的是A的所有基因
universe <- rownames(DE_results_A)  # ❌ 只包含A！

enrichKEGG(
  gene = target_genes,
  universe = universe,  # ❌ 应该是A∩B
  organism = "mmu"
)
```

**问题**：
- Universe包含了只在A中出现、不在B中出现的基因
- 这些基因不可能进入 A∩B 的Target
- **统计空间定义错误**

### ✅ 正确做法

```r
# ✅ 正确做法
# Target = A上调 ∩ B下调
target_up_A <- DE_results_A[DE_results_A$log2FC > 1 & DE_results_A$padj < 0.05, ]
target_down_B <- DE_results_B[DE_results_B$log2FC < -1 & DE_results_B$padj < 0.05, ]
target_genes <- intersect(target_up_A, target_down_B)

# Universe = A中所有基因 ∩ B中所有基因
universe_A <- rownames(DE_results_A)
universe_B <- rownames(DE_results_B)
universe <- intersect(universe_A, universe_B)  # ✅ 正确！

enrichKEGG(
  gene = target_genes,
  universe = universe,
  organism = "mmu"
)
```

---

## 最佳实践

### 📋 推荐流程

#### Step 1: 明确研究问题

```r
# 清晰定义Target
target_genes <- intersect(
  genes_upregulated_in_A,
  genes_downregulated_in_B
)

length(target_genes)  # 例如: 150个基因
```

#### Step 2: 确定正确的Universe

```r
# Universe的定义必须与Target的定义逻辑一致
universe_A <- rownames(DE_results_A)  # A中所有测试过的基因
universe_B <- rownames(DE_results_B)  # B中所有测试过的基因

universe <- intersect(universe_A, universe_B)

length(universe)  # 例如: 15,000个基因
```

#### Step 3: 验证逻辑一致性

```r
# 验证：Target必须是Universe的子集
all(target_genes %in% universe)  # 必须返回TRUE

# 验证：Universe不应该太大
length(universe) < length(org.Mm.eg.db)  # 应该小于全基因组

# 验证：Universe不应该太小
length(universe) > 1000  # 应该包含足够多的基因
```

#### Step 4: 记录决策

```r
# 在分析脚本中注释清楚
# Target definition:
# - Upregulated in Dataset A (log2FC > 1, padj < 0.05)
# - Downregulated in Dataset B (log2FC < -1, padj < 0.05)
# - Intersection of both conditions

# Universe definition:
# - All genes tested in both Dataset A and Dataset B
# - Intersection of DE result tables from both datasets
# - Includes both significant and non-significant genes

universe <- intersect(
  rownames(DE_results_A),
  rownames(DE_results_B)
)
```

---

## 代码实现

### R语言完整实现

#### 基础版本

```r
library(clusterProfiler)
library(org.Mm.eg.db)

# 定义函数：交集基因的KEGG富集分析
enrich_intersect_kegg <- function(
    DE_results_A,
    DE_results_B,
    fc_threshold_A = 1,
    fc_threshold_B = -1,
    padj_threshold = 0.05,
    organism = "mmu"
) {

  message("=== 交集基因KEGG富集分析 ===\n")

  # 1. 定义Target基因集
  message("【1/4】定义Target基因集...")

  up_A <- DE_results_A$gene[DE_results_A$log2FoldChange > fc_threshold_A &
                            DE_results_A$padj < padj_threshold]

  down_B <- DE_results_B$gene[DE_results_B$log2FoldChange < fc_threshold_B &
                              DE_results_B$padj < padj_threshold]

  target_genes <- intersect(up_A, down_B)

  message("  A上调基因数: ", length(up_A))
  message("  B下调基因数: ", length(down_B))
  message("  交集基因数 (Target): ", length(target_genes))

  if (length(target_genes) == 0) {
    stop("❌ 没有找到交集基因，请检查阈值设置")
  }

  # 2. 定义Universe/Background基因集
  message("\n【2/4】定义Universe基因集...")

  universe_A <- DE_results_A$gene  # A中所有测试过的基因
  universe_B <- DE_results_B$gene  # B中所有测试过的基因

  universe <- intersect(universe_A, universe_B)

  message("  A中基因数: ", length(universe_A))
  message("  B中基因数: ", length(universe_B))
  message("  交集基因数 (Universe): ", length(universe))

  # 3. 验证逻辑一致性
  message("\n【3/4】验证逻辑一致性...")

  # Target必须是Universe的子集
  if (!all(target_genes %in% universe)) {
    warning("⚠️  Target基因不是Universe的子集，请检查数据")
  } else {
    message("  ✅ Target ⊆ Universe (逻辑正确)")
  }

  # Universe大小合理性检查
  genome_size <- length(keys(org.Mm.eg.db))
  if (length(universe) > genome_size) {
    warning("⚠️  Universe大小超过全基因组，可能有问题")
  } else {
    message("  ✅ Universe大小合理 (全基因组: ", genome_size, ")")
  }

  # 计算Target占比
  target_ratio <- length(target_genes) / length(universe)
  message("  ✅ Target占Universe比例: ", scales::percent(target_ratio))

  # 4. 执行KEGG富集分析
  message("\n【4/4】执行KEGG富集分析...")

  kegg_result <- enrichKEGG(
    gene = target_genes,
    universe = universe,  # ✅ 使用正确的Universe
    organism = organism,
    pvalueCutoff = 0.05,
    qvalueCutoff = 0.2,
    minGSSize = 5,
    maxGSSize = 500,
    pAdjustMethod = "BH"
  )

  # 5. 返回结果和元数据
  message("\n✅ 分析完成!")
  message("  显著富集通路数: ", sum(kegg_result$p.adjust < 0.05, na.rm = TRUE))

  return(list(
    result = kegg_result,
    target_genes = target_genes,
    universe = universe,
    target_size = length(target_genes),
    universe_size = length(universe),
    metadata = list(
      fc_threshold_A = fc_threshold_A,
      fc_threshold_B = fc_threshold_B,
      padj_threshold = padj_threshold,
      organism = organism
    )
  ))
}
```

#### 使用示例

```r
# 示例数据
DE_results_A <- read.csv("DE_results_dataset_A.csv")
DE_results_B <- read.csv("DE_results_dataset_B.csv")

# 运行分析
result <- enrich_intersect_kegg(
  DE_results_A = DE_results_A,
  DE_results_B = DE_results_B,
  fc_threshold_A = 1,      # A上调阈值
  fc_threshold_B = -1,     # B下调阈值
  padj_threshold = 0.05,
  organism = "mmu"
)

# 查看结果
head(result$result)

# 可视化
library(enrichplot)
dotplot(result$result, showCategory = 20) +
  ggtitle("A上调 ∩ B下调 基因的KEGG富集分析")
```

### 高级版本：自动选择最佳Universe

```r
smart_enrich_kegg <- function(
    target_genes,
    count_matrix_A = NULL,
    count_matrix_B = NULL,
    DE_results_A = NULL,
    DE_results_B = NULL,
    organism = "mmu"
) {

  message("=== 智能Universe选择 ===\n")

  # 策略1: 最优 - DE结果表
  if (!is.null(DE_results_A) && !is.null(DE_results_B)) {
    message("✅ 使用DE结果表定义Universe (最优)")

    universe_A <- rownames(DE_results_A)
    universe_B <- rownames(DE_results_B)
    universe <- intersect(universe_A, universe_B)

    strategy <- "DE_results_tables"

  # 策略2: 次优 - 表达矩阵
  } else if (!is.null(count_matrix_A) && !is.null(count_matrix_B)) {
    message("⚠️  使用表达矩阵定义Universe (次优)")

    universe_A <- rownames(count_matrix_A)
    universe_B <- rownames(count_matrix_B)
    universe <- intersect(universe_A, universe_B)

    strategy <- "count_matrices"

  # 策略3: 兜底 - 全基因组（警告！）
  } else {
    warning("❌ 无法从输入数据推断Universe，使用全基因组（不推荐）")

    library(org.Mm.eg.db)
    universe <- keys(org.Mm.eg.db)

    strategy <- "full_genome"
  }

  # 验证
  if (!all(target_genes %in% universe)) {
    missing <- target_genes[!target_genes %in% universe]
    warning("⚠️  有 ", length(missing), " 个Target基因不在Universe中")
  }

  message("\nUniverse统计:")
  message("  策略: ", strategy)
  message("  大小: ", length(universe))
  message("  Target占比: ", scales::percent(length(target_genes) / length(universe)))

  # 执行富集分析
  kegg_result <- enrichKEGG(
    gene = target_genes,
    universe = universe,
    organism = organism
  )

  return(list(
    result = kegg_result,
    universe = universe,
    universe_strategy = strategy,
    universe_size = length(universe)
  ))
}
```

---

## 实例分析

### 案例：双数据集交集分析

**研究场景**：
- Dataset A: 药物处理 vs 对照（小鼠）
- Dataset B: 疾病模型 vs 正常（小鼠）
- Target: A中上调的基因 ∩ B中下调的基因

**数据**：
```r
# Dataset A DE结果
DE_A <- read.csv("drug_vs_control.csv")
# 包含: gene, log2FoldChange, padj (20,000行)

# Dataset B DE结果
DE_B <- read.csv("disease_vs_normal.csv")
# 包含: gene, log2FoldChange, padj (18,000行)
```

#### ❌ 错误分析1：不指定Universe

```r
# 假设不指定universe参数
target <- intersect(
  DE_A$gene[DE_A$log2FoldChange > 1 & DE_A$padj < 0.05],
  DE_B$gene[DE_B$log2FoldChange < -1 & DE_B$padj < 0.05]
)

# clusterProfiler会自动使用所有测试过的基因
# 但这个"自动"行为可能不正确！
result_wrong <- enrichKEGG(gene = target, organism = "mmu")
```

**问题**：
- `clusterProfiler` 默认使用 `org.Mm.eg.db` 的所有基因
- 或者使用注释包中所有能被注释的基因
- **可能包含实际未检测的基因**

#### ❌ 错误分析2：Universe太大

```r
library(org.Mm.eg.db)
all_mouse_genes <- keys(org.Mm.eg.db)  # ~50,000+ 基因

result_wrong2 <- enrichKEGG(
  gene = target,
  universe = all_mouse_genes,  # ❌ 太大！
  organism = "mmu"
)
```

**问题**：
- 包含了实验中从未检测到的基因
- 比如某些组织特异性基因、低表达基因
- **稀释统计显著性**

#### ✅ 正确分析

```r
# 1. 定义Target
up_A <- DE_A$gene[DE_A$log2FoldChange > 1 & DE_A$padj < 0.05]
down_B <- DE_B$gene[DE_B$log2FoldChange < -1 & DE_B$padj < 0.05]
target <- intersect(up_A, down_B)

# 2. 定义正确的Universe
universe_A <- DE_A$gene  # A中所有测试过的基因
universe_B <- DE_B$gene  # B中所有测试过的基因
universe <- intersect(universe_A, universe_B)  # ✅ 交集

# 3. 验证
cat("Target size:", length(target), "\n")
cat("Universe size:", length(universe), "\n")
cat("Target ratio:", length(target) / length(universe), "\n")
cat("All Target in Universe?", all(target %in% universe), "\n")

# 输出:
# Target size: 150
# Universe size: 15,234
# Target ratio: 0.0098
# All Target in Universe? TRUE

# 4. 执行富集分析
result_correct <- enrichKEGG(
  gene = target,
  universe = universe,  # ✅ 正确的Universe
  organism = "mmu",
  pvalueCutoff = 0.05,
  qvalueCutoff = 0.2
)

# 5. 查看结果
head(result_correct)
```

**预期结果差异**：

| 指标 | 错误分析（全基因组Universe） | 正确分析 |
|------|---------------------------|---------|
| Universe大小 | 50,000+ | 15,234 |
| 富集通路数（p<0.05） | 3 | 12 |
| Top通路p值 | 0.042 | 0.003 |
| 统计效力 | 弱（稀释） | 强（准确） |

---

## 特殊场景处理

### 场景1：单列基因列表富集

**问题**：用户只提供一列基因ID（如从韦恩图得到），没有原始DE数据

**解决方案**：

```r
# 用户输入
gene_list_from_venn <- c("Gene1", "Gene2", "Gene3", ...)

# 询问用户：这些基因来自什么实验？
# 然后根据实验范围定义Universe

# 选项A: 如果来自特定的RNA-seq实验
universe <- read.csv("original_DE_results.csv")$gene

# 选项B: 如果不知道来源，使用组织相关的全基因组
# (仍然比直接用全基因组好)
# 例如：肝脏表达基因
universe <- get_liver_expressed_genes()

# 选项C: 如果完全不知道，至少要警告用户
if (missing_universe_warning) {
  warning("⚠️  未提供明确的Universe，将使用全基因组。
          结果可能不够准确，请谨慎解读。")
}
```

### 场景2：不同物种的比较

```r
# Dataset A: 小鼠
# Dataset B: 大鼠

# 需要先转换到同源基因
library(biomaRt)

mouse_genes <- DE_A$gene
rat_genes <- DE_B$gene

# 转换大鼠基因到小鼠同源基因
rat_to_mouse <- getLDS(
  attributes = "ensembl_gene_id",
  filters = "ensembl_gene_id",
  values = rat_genes,
  mart = rat_mart,
  attributesL = "ensembl_gene_id",
  martL = mouse_mart
)

# 然后做交集
target <- intersect(mouse_genes, rat_to_mouse$Gene.stable.ID)
```

### 场景3：时间序列数据

```r
# 多个时间点的DE分析
DE_t0 <- read.csv("DE_t0_vs_baseline.csv")
DE_t1 <- read.csv("DE_t1_vs_baseline.csv")
DE_t2 <- read.csv("DE_t2_vs_baseline.csv")

# Universe = 所有时间点都检测到的基因
universe <- Reduce(
  intersect,
  list(
    DE_t0$gene,
    DE_t1$gene,
    DE_t2$gene
  )
)
```

---

## 质量控制检查清单

### ✅ 分析前检查

- [ ] Target基因集定义清晰？
- [ ] Universe基因集与Target逻辑一致？
- [ ] Target ⊆ Universe？
- [ ] Universe大小合理（100 < Universe < 全基因组）？
- [ ] 记录了Universe的选择依据？

### ✅ 分析中检查

```r
# 自动检查脚本
quality_check <- function(target, universe, organism = "mmu") {
  issues <- list()

  # 检查1: Target在Universe中
  if (!all(target %in% universe)) {
    issues <- c(issues, "❌ 部分Target基因不在Universe中")
  }

  # 检查2: Universe大小
  if (length(universe) < 100) {
    issues <- c(issues, "❌ Universe太小（<100基因）")
  }

  library(org.Mm.eg.db)
  genome_size <- length(keys(org.Mm.eg.db))
  if (length(universe) > genome_size) {
    issues <- c(issues, "❌ Universe超过全基因组大小")
  }

  # 检查3: Target占比
  ratio <- length(target) / length(universe)
  if (ratio > 0.5) {
    issues <- c(issues, "⚠️  Target占比过高（>50%）")
  }

  if (ratio < 0.001) {
    issues <- c(issues, "⚠️  Target占比过低（<0.1%）")
  }

  return(issues)
}
```

### ✅ 分析后检查

- [ ] 富集结果合理（生物学上可解释）？
- [ ] 没有过多"低质量"通路？
- [ ] 记录了分析参数？

---

## 总结与建议

### 🎯 核心原则

1. **Universe必须与Target的定义逻辑一致**
   - 如果Target是交集，Universe也应该是交集
   - 如果Target是某条件下的基因，Universe应该是该条件下所有基因

2. **Universe应该包含所有"有机会"进入Target的基因**
   - 包含显著和不显著基因
   - 包含上调、下调和无变化基因
   - 包含实际检测到的基因

3. **避免两种极端**
   - ❌ 太大：全基因组（稀释信号）
   - ❌ 太小：仅显著基因（假阳性）

### 📋 实践建议

| 数据情况 | 推荐Universe定义 | 可靠性 |
|---------|----------------|--------|
| 有DE结果表 | DE结果表中所有基因的交集 | ⭐⭐⭐⭐⭐ |
| 有表达矩阵 | 表达矩阵中所有基因的交集 | ⭐⭐⭐⭐ |
| 有基因ID列表 | 该列表的交集 | ⭐⭐⭐ |
| 什么都没有 | ⚠️ 使用全基因组+警告 | ⭐ |

### 🔍 故障排查

**如果富集分析结果为空**：
1. 检查Target基因数是否太少（<5）
2. 检查基因ID类型是否正确（ENSEMBL vs Entrez vs Symbol）
3. 检查物种参数是否正确

**如果富集分析结果过多（50+通路）**：
1. 检查Universe是否太小
2. 检查Target占比是否过高
3. 考虑提高显著性阈值

**如果富集分析结果很少但预期应该很多**：
1. 检查Universe是否太大（是否用了全基因组）
2. 检查基因ID注释是否正确
3. 考虑降低p值阈值

---

## 参考资料

- clusterProfiler文档: https://guangchuangyu.github.io/software/clusterProfiler/
- GO分析最佳实践: https://yulab-smu.top/biomedical-knowledge-mining-book/
- KEGG富集分析原理: https://www.genome.jp/kegg/tool/

---

**文档维护**: 如有疑问或更新，请及时更新本文档。
