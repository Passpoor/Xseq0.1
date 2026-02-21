# Biofree Project Bug修复手册

> **创建日期**: 2025-01-03
> **最后更新**: 2025-01-03
> **维护者**: Claude Code Assistant
> **版本**: 1.0

---

## 📋 文档说明

本文档记录Biofree项目开发过程中遇到的所有Bug、问题及其最佳解决方案。每次遇到新问题时，都应该先查阅此手册。

### 使用说明
1. 每次遇到Bug时，首先在文档中搜索相关问题
2. 如果找到匹配的条目，按照记录的解决方案操作
3. 如果是新问题，解决后更新此文档
4. 每个条目包含：问题描述、诊断步骤、解决方案、预防措施

---

## 🐛 Bug记录索引

### 数据库相关
- [数据库锁定问题](#数据库锁定问题) (2025-01-03)
- [数据库版本缓存不一致](#数据库版本缓存不一致) (2025-01-03)

### 基因注释相关
- [Ensembl ID注释失败](#ensembl-id注释失败) (2025-01-03)
- [Symbol注释修复](#symbol注释修复) (2025-01-03)
- [假基因过滤问题](#假基因过滤问题) (2025-01-03)

### KEGG通路分析
- [单个基因KEGG查询失败](#单个基因kegg查询失败) (2025-01-03)
- [KEGG通路批量查询优化](#kegg通路批量查询优化) (2025-01-03)
- [富集分析背景基因集选择错误](#富集分析背景基因集选择错误) (2025-01-03) ⭐
- [NA值处理](#na值处理) (2025-01-03)

### 项目结构
- [项目清理](#项目清理) (2025-01-03)
- [兼容性问题](#兼容性问题) (2025-01-03)

### R语言特定
- [R会话锁定](#r会话锁定) (2025-01-03)
- [临时文件清理](#临时文件清理) (2025-01-03)

---

## 详细Bug记录

### 数据库锁定问题

**日期**: 2025-01-03
**优先级**: 🔴 高

#### 问题描述
```
Error in sqliteExecStatement(con, statement, ...) :
  SCHEMA: database schema has changed
```

或者
```
Error in rsqlite_connect: database is locked
```

#### 根本原因
1. 多个R会话同时访问同一个SQLite数据库文件
2. 数据库连接未正确关闭
3. 文件系统锁机制冲突（Windows常见）
4. 临时锁文件残留

#### 诊断步骤
```r
# 检查锁文件
file.exists("biofree_annotation.db-shm")
file.exists("biofree_annotation.db-wal")

# 检查是否有R进程占用
# Windows: 任务管理器查看R进程
# Linux/Mac: ps aux | grep R
```

#### 最佳解决方案

**方案1: 清理锁文件（快速修复）**
```r
# 创建 cleanup_r_locks.R
cleanup_r_locks <- function(db_path = "data/biofree_annotation.db") {
  # 确保数据库文件存在
  if (!file.exists(db_path)) {
    message("数据库文件不存在: ", db_path)
    return(invisible(NULL))
  }

  # 检查并清理锁文件
  lock_files <- c(
    paste0(db_path, "-shm"),
    paste0(db_path, "-wal")
  )

  for (lock_file in lock_files) {
    if (file.exists(lock_file)) {
      tryCatch({
        file.remove(lock_file)
        message("✓ 已删除锁文件: ", lock_file)
      }, error = function(e) {
        warning("无法删除锁文件: ", lock_file, " - ", e$message)
      })
    }
  }

  message("✓ 锁文件清理完成")
}

# 执行清理
cleanup_r_locks()
```

**方案2: 数据库连接优化**
```r
# 修改数据库连接设置
db_connect <- function(db_path) {
  DBI::dbConnect(
    RSQLite::SQLite(),
    db_path,
    # 关键参数
    loadable.extensions = TRUE,
    cache_size = 2000,  # 增大缓存
    synchronous = "OFF",  # 提升性能
    journal_mode = "WAL"  # 写前日志
  )
}

# 确保连接关闭
on.exit(DBI::dbDisconnect(con), add = TRUE)
```

**方案3: 重启R会话**
```r
# 完全重启R
.rs.restartR()

# 或者命令行
# 关闭所有R进程，重新启动
```

#### 预防措施
1. 使用完数据库立即关闭连接
2. 避免在多个R会话中同时打开同一数据库
3. 定期运行 `cleanup_r_locks.R`
4. 在应用关闭时清理所有连接

#### 相关文档
- `DB_LOCK_ERROR_FIX.md` - 详细技术说明
- `cleanup_r_locks.R` - 自动清理脚本

---

### 数据库版本缓存不一致

**日期**: 2025-01-03
**优先级**: 🟡 中

#### 问题描述
更新了数据库文件，但应用仍在使用旧的缓存数据。

#### 解决方案
```r
# 强制清除数据库缓存
clear_db_cache <- function() {
  cache_files <- list.files(
    "data",
    pattern = "\\.rds$",
    full.names = TRUE
  )

  file.remove(cache_files)
  message("✓ 已清除 ", length(cache_files), " 个缓存文件")
}

clear_db_cache()
```

#### 预防措施
每次更新数据库后自动清除缓存

#### 相关文档
- `DB_VERSION_CACHE.md`

---

### Ensembl ID注释失败

**日期**: 2025-01-03
**优先级**: 🔴 高

#### 问题描述
```
Error: Cannot retrieve Ensembl annotation for gene: ENSMUSG00000012345
```

#### 根本原因
1. 网络问题导致biomaRt无法连接
2. Ensembl ID版本不匹配
3. 基因ID已过时或被删除

#### 最佳解决方案

**步骤1: 检查网络连接**
```r
# 测试Ensembl连接
library(biomaRt)
mart <- useMart("ensembl", dataset = "mmusculus_gene_ensembl")
test <- getBM(attributes = c('ensembl_gene_id'),
              filters = 'ensembl_gene_id',
              values = 'ENSMUSG00000012345',
              mart = mart)
```

**步骤2: 更新Ensembl版本**
```r
# 使用最新版本的Ensembl
mart <- useMart(
  "ensembl",
  dataset = "mmusculus_gene_ensembl",
  host = "https://dec2024.archive.ensembl.org"  # 使用特定版本
)
```

**步骤3: 本地数据库方案（推荐）**
```r
# 使用预构建的本地数据库
library(org.Mm.eg.db)

# Ensembl -> Entrez -> Symbol
ensembl_to_symbol <- function(ensembl_ids) {
  entrez <- mapIds(
    org.Mm.eg.db,
    keys = ensembl_ids,
    column = "SYMBOL",
    keytype = "ENSEMBL",
    multiVals = "first"
  )
  return(entrez)
}
```

**步骤4: 批量重试机制**
```r
annotate_ensembl_batch <- function(ensembl_ids, max_retries = 3) {
  results <- vector("list", length(ensembl_ids))

  for (i in seq_along(ensembl_ids)) {
    for (attempt in 1:max_retries) {
      tryCatch({
        results[[i]] <- query_ensembl(ensembl_ids[i])
        break  # 成功则跳出
      }, error = function(e) {
        if (attempt == max_retries) {
          results[[i]] <- NA
        } else {
          Sys.sleep(2)  # 等待2秒后重试
        }
      })
    }
  }

  return(unlist(results))
}
```

#### 预防措施
1. 定期更新本地注释数据库
2. 实现离线注释功能
3. 添加重试和超时机制

#### 相关文档
- `ENSEMBL_ID_ANNOTATION_FIX.md`
- `UNANNOTATED_GENES_SOLUTION.md`

---

### Symbol注释修复

**日期**: 2025-01-03
**优先级**: 🟡 中

#### 问题描述
基因Symbol大小写不一致导致注释失败。

#### 解决方案
```r
# 标准化Gene Symbol
normalize_symbol <- function(symbols) {
  # 去除空格
  symbols <- trimws(symbols)

  # 转换为首字母大写
  symbols <- gsub("\\b([a-z])([a-z]*)\\b", "\\U\\1\\L\\2", symbols, perl = TRUE)

  # 移除版本号（如 Brca1-001）
  symbols <- gsub("-\\d+$", "", symbols)

  return(symbols)
}

# 使用示例
symbols <- c("brca1", "TP53", "egfr", "Brca1-001")
normalized <- normalize_symbol(symbols)
# 结果: c("Brca1", "Tp53", "Egfr", "Brca1")
```

#### 相关文档
- `SYMBOL_ANNOTATION_FIX.md`

---

### 假基因过滤问题

**日期**: 2025-01-03
**优先级**: 🟡 中

#### 问题描述
注释结果包含大量假基因（Pseudogene），影响分析质量。

#### 解决方案
```r
# 过滤假基因
filter_pseudogenes <- function(annotation_df) {
  # 移除包含pseudogene的条目
  filtered <- annotation_df[
    !grepl("pseudogene", annotation_df$gene_biotype, ignore.case = TRUE),
  ]

  # 也可以根据基因类型过滤
  allowed_types <- c(
    "protein_coding",
    "lncRNA",
    "miRNA",
    "rRNA",
    "snRNA",
    "snoRNA"
  )

  filtered <- filtered[filtered$gene_biotype %in% allowed_types, ]

  message("过滤前: ", nrow(annotation_df), " 条")
  message("过滤后: ", nrow(filtered), " 条")
  message("移除: ", nrow(annotation_df) - nrow(filtered), " 个假基因")

  return(filtered)
}
```

#### 相关文档
- `PSEUDO_GENE_FILTER_FIX.md`

---

### 单个基因KEGG查询失败

**日期**: 2025-01-03
**优先级**: 🔴 高

#### 问题描述
当用户只输入一个基因时，KEGG通路分析返回错误或空结果。

#### 根本原因
KEGG API对单个基因的查询处理方式不同，或者需要使用不同的参数格式。

#### 最佳解决方案

**方案1: 单基因特殊处理**
```r
query_kegg_pathway <- function(gene_list) {
  # 单基因特殊处理
  if (length(gene_list) == 1) {
    message("检测到单个基因，使用单基因查询模式")

    # 方式1: 添加模式基因
    extended_genes <- c(gene_list, "Actb")  # 添加看家基因

    # 方式2: 使用不同的查询方式
    result <- tryCatch({
      # 直接查询基因相关通路
      pathways <- KEGGREST::keggList("pathway", gene_list)

      # 或者使用更宽松的查询
      # pathways <- KEGGREST::keggFind("pathway", gene_list)
    }, error = function(e) {
      warning("KEGG查询失败: ", e$message)
      return(NULL)
    })
  } else {
    # 批量查询（原有逻辑）
    result <- query_kegg_batch(gene_list)
  }

  return(result)
}
```

**方案2: 降级处理**
```r
safe_kegg_query <- function(genes) {
  result <- tryCatch({
    query_kegg_pathway(genes)
  }, error = function(e) {
    message("批量查询失败，尝试单个查询")

    # 降级为逐个查询
    results <- lapply(genes, function(gene) {
      tryCatch({
        KEGGREST::keggFind("genes", gene)
      }, error = function(e) NULL)
    })

    # 合并结果
    results <- results[!sapply(results, is.null)]
    if (length(results) > 0) {
      do.call(rbind, results)
    } else {
      data.frame()
    }
  })

  return(result)
}
```

**方案3: 添加调试信息**
```r
debug_kegg_query <- function(genes) {
  message("=== KEGG查询调试信息 ===")
  message("基因数量: ", length(genes))
  message("基因列表: ", paste(genes, collapse = ", "))

  # 检查网络连接
  tryCatch({
    test <- KEGGREST::keggList("organism")
    message("✓ KEGG API连接正常")
  }, error = function(e) {
    message("✗ KEGG API连接失败: ", e$message)
    return(NULL)
  })

  # 尝试查询
  result <- KEGGREST::keggFind("pathway", paste(genes, collapse = "+"))

  message("返回结果数: ", nrow(result))

  return(result)
}
```

#### 使用示例
```r
# 在modules/kegg.R中修改
# 添加单基因检查
if (length(input_genes) == 1) {
  showNotification("单个基因查询，启用特殊模式", type = "message")
  result <- safe_kegg_query(input_genes)
}
```

#### 预防措施
1. 在UI层面提示用户输入多个基因
2. 提供测试基因按钮
3. 实现降级查询策略

#### 相关文档
- `SINGLE_GENE_KEGG_FIX.md` - 详细修复记录
- `KEGG_BUGFIX_REPORT.md` - Bug修复报告
- `KEGG_DEBUG_GUIDE.md` - 调试指南

---

### KEGG通路批量查询优化

**日期**: 2025-01-03
**优先级**: 🟢 低

#### 问题描述
批量查询KEGG通路时速度慢，容易超时。

#### 解决方案
```r
# 批量查询优化
optimized_kegg_batch <- function(genes, batch_size = 50) {
  # 分批处理
  batches <- split(genes, ceiling(seq_along(genes) / batch_size))

  all_results <- list()

  for (i in seq_along(batches)) {
    message("处理批次 ", i, "/", length(batches))

    batch_result <- tryCatch({
      KEGGREST::keggFind("pathway", paste(batches[[i]], collapse = "+"))
    }, error = function(e) {
      warning("批次 ", i, " 失败: ", e$message)
      return(NULL)
    })

    if (!is.null(batch_result)) {
      all_results[[i]] <- batch_result
    }

    # 避免API限流
    Sys.sleep(1)
  }

  # 合并结果
  do.call(rbind, all_results)
}
```

---

### NA值处理

**日期**: 2025-01-03
**优先级**: 🟡 中

#### 问题描述
数据中存在NA值，导致分析和可视化失败。

#### 最佳解决方案

**策略1: 移除NA值**
```r
# 移除包含NA的行
remove_na_rows <- function(df, columns = NULL) {
  if (is.null(columns)) {
    # 检查所有列
    return(df[complete.cases(df), ])
  } else {
    # 检查指定列
    return(df[complete.cases(df[, columns]), ])
  }
}
```

**策略2: 填充NA值**
```r
# 根据数据类型填充
fill_na <- function(df) {
  for (col in names(df)) {
    if (is.numeric(df[[col]])) {
      # 数值型: 使用中位数
      df[[col]][is.na(df[[col]])] <- median(df[[col]], na.rm = TRUE)
    } else if (is.character(df[[col]])) {
      # 字符型: 使用"Unknown"
      df[[col]][is.na(df[[col]])] <- "Unknown"
    }
  }
  return(df)
}
```

**策略3: 保留NA但标记**
```r
# 在可视化时标记NA
library(ggplot2)

ggplot(df, aes(x, y)) +
  geom_point(data = df[!is.na(df$group), ], aes(color = group)) +
  geom_point(data = df[is.na(df$group), ], color = "gray", shape = 1) +
  labs(title = "灰色点表示NA值")
```

#### 相关文档
- `NA_VALUE_FIX.md`

---

### 富集分析背景基因集选择错误

**日期**: 2025-01-03
**优先级**: 🔴 高
**重要性**: ⭐⭐⭐⭐⭐

#### 问题描述

富集分析（KEGG/GO/GSEA）结果不准确：
- 预期应该富集的通路没有出现（假阴性）
- 或者出现了很多不相关的"显著"通路（假阳性）
- P值和富集倍数看起来不对

#### 根本原因

**核心问题：Universe/Background基因集定义错误**

富集分析的统计本质是在问：
> 在"有资格被选中"的所有基因中，当前目标基因集合是否在某些通路中显著集中？

如果Universe定义错误，统计空间就错了，结果必然错误。

#### 常见错误场景

**❌ 错误1: 使用全基因组作为Universe**
```r
library(org.Mm.eg.db)
all_genes <- keys(org.Mm.eg.db)  # 全基因组

enrichKEGG(
  gene = target_genes,
  universe = all_genes,  # ❌ 包含了未检测基因！
  organism = "mmu"
)
```

**问题**：
- 包含了在实验中从未被检测到的基因
- 这些基因不可能出现在Target中
- 统计显著性被稀释（假阴性）

**❌ 错误2: 仅用显著基因作为Universe**
```r
sig_genes <- DE_results[DE_results$padj < 0.05, ]

enrichKEGG(
  gene = target_genes,
  universe = sig_genes,  # ❌ 只有显著基因！
  organism = "mmu"
)
```

**问题**：
- 人为增加富集比例
- 产生假阳性结果
- 例如：Target中有5个基因属于某通路，Universe只有100个基因（实际应该10000个），该通路会显得高度"富集"

**❌ 错误3: Universe与Target逻辑不一致**
```r
# Target = A上调 ∩ B下调
target <- intersect(up_A, down_B)

# 但Universe只用了A的所有基因
universe <- rownames(DE_results_A)  # ❌ 应该是A∩B

enrichKEGG(gene = target, universe = universe, organism = "mmu")
```

**问题**：
- Universe包含了只在A中出现、不在B中的基因
- 这些基因不可能进入 A∩B 的Target
- 统计空间定义错误

#### 最佳解决方案

**✅ 核心原则**

> **Universe = 所有"理论上有机会进入 Target"的基因**

对于交集分析（A上调 ∩ B下调）：
```r
Universe = 在A和B中都检测到、并参与DE分析的所有基因
```

**✅ 包含的基因**：
- A和B中的显著差异基因（上调+下调）
- A和B中的不显著基因
- 上调、下调、无变化的基因
- **关键条件**：基因必须在 A和B中都出现过

**✅ 推荐实现**

```r
library(clusterProfiler)
library(org.Mm.eg.db)

# Step 1: 定义Target基因集
up_A <- DE_results_A$gene[DE_results_A$log2FoldChange > 1 &
                          DE_results_A$padj < 0.05]
down_B <- DE_results_B$gene[DE_results_B$log2FoldChange < -1 &
                            DE_results_B$padj < 0.05]
target_genes <- intersect(up_A, down_B)

# Step 2: 定义正确的Universe
universe_A <- DE_results_A$gene  # A中所有测试过的基因
universe_B <- DE_results_B$gene  # B中所有测试过的基因
universe <- intersect(universe_A, universe_B)  # ✅ 交集

# Step 3: 验证逻辑一致性
stopifnot(all(target_genes %in% universe))  # Target ⊆ Universe

# Step 4: 执行富集分析
result <- enrichKEGG(
  gene = target_genes,
  universe = universe,  # ✅ 使用正确的Universe
  organism = "mmu",
  pvalueCutoff = 0.05,
  qvalueCutoff = 0.2
)
```

**✅ 不同场景的Universe选择**

| 数据情况 | 推荐Universe定义 | 可靠性 |
|---------|----------------|--------|
| 有DE结果表 | DE结果表中所有基因的交集 | ⭐⭐⭐⭐⭐ |
| 有表达矩阵 | 表达矩阵中所有基因的交集 | ⭐⭐⭐⭐ |
| 只有基因列表 | 该列表的交集 | ⭐⭐⭐ |
| 什么都没有 | ⚠️ 使用全基因组+警告 | ⭐ |

#### 质量控制检查

```r
# 自动检查脚本
quality_check_universe <- function(target, universe, organism = "mmu") {
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

# 使用
issues <- quality_check_universe(target_genes, universe)
if (length(issues) > 0) {
  for (issue in issues) cat(issue, "\n")
}
```

#### 完整工具函数

```r
# 富集分析包装函数：自动处理Universe
enrich_with_correct_universe <- function(
    DE_results_A,
    DE_results_B,
    fc_threshold_A = 1,
    fc_threshold_B = -1,
    padj_threshold = 0.05,
    organism = "mmu"
) {

  message("=== 交集基因富集分析（自动Universe选择）===\n")

  # 1. 定义Target
  up_A <- DE_results_A$gene[DE_results_A$log2FoldChange > fc_threshold_A &
                            DE_results_A$padj < padj_threshold]
  down_B <- DE_results_B$gene[DE_results_B$log2FoldChange < fc_threshold_B &
                              DE_results_B$padj < padj_threshold]
  target_genes <- intersect(up_A, down_B)

  message("Target基因数: ", length(target_genes))

  if (length(target_genes) < 5) {
    stop("❌ Target基因太少（<5），无法进行富集分析")
  }

  # 2. 自动选择最佳Universe
  universe_A <- DE_results_A$gene
  universe_B <- DE_results_B$gene
  universe <- intersect(universe_A, universe_B)

  message("Universe基因数: ", length(universe))
  message("Target占比: ", scales::percent(length(target_genes) / length(universe)))

  # 3. 质量控制
  issues <- quality_check_universe(target_genes, universe, organism)
  if (length(issues) > 0) {
    warning("\n发现以下问题:\n")
    for (issue in issues) cat("  ", issue, "\n")
  }

  # 4. 执行富集分析
  message("\n执行KEGG富集分析...")
  result <- enrichKEGG(
    gene = target_genes,
    universe = universe,
    organism = organism,
    pvalueCutoff = 0.05,
    qvalueCutoff = 0.2
  )

  message("✅ 完成! 显著通路数: ",
          sum(result$p.adjust < 0.05, na.rm = TRUE))

  return(list(
    result = result,
    target_genes = target_genes,
    universe = universe,
    metadata = list(
      target_size = length(target_genes),
      universe_size = length(universe),
      universe_strategy = "DE_results_intersection"
    )
  ))
}
```

#### 诊断步骤

**问题：富集分析结果为空**

```r
# 检查
length(target_genes)  # 应该 > 5
table(target_genes %in% universe)  # 应该全为TRUE

# 常见原因
# 1. Target基因数太少
# 2. 基因ID类型错误（ENSEMBL vs Entrez vs Symbol）
# 3. 物种参数错误
```

**问题：富集结果过多（50+通路）**

```r
# 检查
length(universe)  # 是否太小？
length(target_genes) / length(universe)  # 是否>50%?

# 解决方案
# 1. 检查Universe是否太小
# 2. 检查是否只用显著基因作为Universe
# 3. 提高p值阈值
```

**问题：结果很少但预期应该很多**

```r
# 检查
length(universe)  # 是否接近全基因组？
length(universe) / length(keys(org.Mm.eg.db))  # 是否>90%?

# 解决方案
# 1. 检查是否用了全基因组作为Universe
# 2. 检查基因ID注释
# 3. 降低p值阈值
```

#### 预防措施

1. **记录Universe的选择依据**
   ```r
   # 在分析脚本中注释
   # Universe = DE_results_A和DE_results_B的所有基因交集
   # 包含显著和不显著基因
   # 目标: 分析A上调∩B下调基因的富集情况
   ```

2. **使用自动化工具**
   - 使用上面的包装函数
   - 避免手动选择Universe

3. **验证逻辑一致性**
   - Target ⊆ Universe
   - Universe大小合理
   - Target占比合理（0.1%-50%）

4. **文档化分析决策**
   - 记录为什么选择这个Universe
   - 记录数据来源和预处理步骤

#### 相关文档

**完整指南**: `docs/ENRICHMENT_UNIVERSE_GUIDE.md` - 包含：
- 详细的理论解释
- 多个实例分析
- 不同场景的处理方法
- 代码实现和最佳实践

**核心知识点**：
- Universe定义的核心原则
- Target和Universe的逻辑一致性
- 常见错误和正确做法对比
- 质量控制检查清单

---

### 项目清理

**日期**: 2025-01-03
**优先级**: 🟢 低

#### 问题描述
项目目录中存在大量临时文件和测试文件，影响项目可维护性。

#### 解决方案

**自动清理脚本**
```r
# cleanup_project.R
cleanup_project <- function() {
  message("=== Biofree项目清理 ===")

  # 1. 清理R锁文件
  lock_patterns <- c("\\.rds$", "\\.Rhistory$", "\\.RData$", "\\.lock$")

  all_files <- list.files(recursive = TRUE)
  lock_files <- all_files[sapply(all_files, function(f) {
    any(sapply(lock_patterns, function(p) grepl(p, f)))
  })]

  if (length(lock_files) > 0) {
    file.remove(lock_files)
    message("✓ 已删除 ", length(lock_files), " 个临时文件")
  }

  # 2. 清理临时目录
  temp_dirs <- c("temp", "tmp", "__pycache__")

  for (dir in temp_dirs) {
    if (dir.exists(dir)) {
      unlink(dir, recursive = TRUE)
      message("✓ 已删除临时目录: ", dir)
    }
  }

  message("✓ 清理完成")
}

cleanup_project()
```

#### 项目结构建议
```
Biofree_project/
├── app.R                    # 主应用入口
├── modules/                 # 核心模块
│   ├── database.R
│   ├── kegg.R
│   ├── annotation.R
│   └── utils.R
├── data/                    # 数据文件
│   └── biofree_annotation.db
├── config/                  # 配置文件
├── docs/                    # 文档
├── tests/                   # 测试脚本
├── www/                     # Web资源
├── R/                       # R包和依赖
├── scripts/                 # 工具脚本
│   ├── cleanup_r_locks.R
│   ├── cleanup_temp_files.R
│   └── check_project_structure.R
└── BUG_FIX_MANUAL.md       # 本文档
```

#### 相关文档
- `PROJECT_STRUCTURE_CLEANUP.md`
- `CLEANUP_MANUAL_GUIDE.md`

---

### 兼容性问题

**日期**: 2025-01-03
**优先级**: 🟡 中

#### 问题描述
不同R版本和包版本导致的行为不一致。

#### 解决方案

**检查兼容性**
```r
# check_compatibility.R
check_compatibility <- function() {
  message("=== Biofree兼容性检查 ===")

  # 检查R版本
  r_version <- getRversion()
  message("R版本: ", r_version)

  if (r_version < "4.0.0") {
    warning("建议升级R到4.0.0或更高版本")
  }

  # 检查关键包
  required_packages <- c(
    "shiny" = "1.7.0",
    "dplyr" = "1.0.0",
    "DBI" = "1.1.0",
    "RSQLite" = "2.2.0",
    "biomaRt" = "2.50.0",
    "KEGGREST" = "1.34.0"
  )

  for (pkg in names(required_packages)) {
    version <- tryCatch({
      packageVersion(pkg)
    }, error = function(e) {
      return(NULL)
    })

    if (is.null(version)) {
      warning("❌ ", pkg, " 未安装")
    } else if (version < package_version(required_packages[pkg])) {
      warning("⚠️  ", pkg, " 版本过低: ", version,
              " (建议: ", required_packages[pkg], ")")
    } else {
      message("✅ ", pkg, ": ", version)
    }
  }
}

check_compatibility()
```

#### 相关文档
- `PROJECT_COMPATIBILITY_REPORT.md`

---

### R会话锁定

**日期**: 2025-01-03
**优先级**: 🟡 中

#### 问题描述
RStudio或R会话无响应，无法关闭数据库连接。

#### 解决方案

**强制关闭R会话**
```r
# 1. 尝试优雅退出
tryCatch({
  gc()  # 垃圾回收，清理连接
}, error = function(e) {
  message("垃圾回收失败: ", e$message)
})

# 2. 查看打开的连接
# Windows: 在任务管理器中结束R进程
# Linux/Mac:
# killall R

# 3. 清理锁文件
source("scripts/cleanup_r_locks.R")
```

#### 预防措施
```r
# 在每个函数中使用on.exit
safe_database_operation <- function() {
  con <- dbConnect(...)  # 连接数据库

  # 确保函数退出时断开连接
  on.exit(dbDisconnect(con), add = TRUE)

  # 执行操作...
}
```

---

### 临时文件清理

**日期**: 2025-01-03
**优先级**: 🟢 低

#### 问题描述
R会话留下的临时文件占用磁盘空间。

#### 解决方案
```r
# cleanup_temp_files.R
cleanup_temp_files <- function() {
  temp_dir <- tempdir()

  # 获取所有临时文件
  temp_files <- list.files(temp_dir, full.names = TRUE)

  # 删除超过7天的文件
  old_files <- temp_files[file.mtime(temp_files) <
                           Sys.time() - 7 * 24 * 60 * 60]

  if (length(old_files) > 0) {
    file.remove(old_files)
    message("✓ 已删除 ", length(old_files), " 个旧临时文件")
  }
}

cleanup_temp_files()
```

---

## 🔧 诊断工具集

### 快速诊断脚本

将以下函数保存为 `diagnose.R`，用于快速诊断常见问题：

```r
diagnose_biofree <- function() {
  message("\n=== Biofree项目诊断 ===\n")

  # 1. 检查项目结构
  message("1. 检查项目结构...")
  required_dirs <- c("modules", "data", "config", "www")
  for (dir in required_dirs) {
    if (dir.exists(dir)) {
      message("  ✓ ", dir)
    } else {
      message("  ✗ ", dir, " (缺失)")
    }
  }

  # 2. 检查数据库
  message("\n2. 检查数据库...")
  db_files <- c(
    "data/biofree_annotation.db",
    "data/biofree_annotation.db-shm",
    "data/biofree_annotation.db-wal"
  )

  for (f in db_files) {
    if (file.exists(f)) {
      size <- file.info(f)$size
      message("  ✓ ", f, " (", format(size, big.mark = ","), " bytes)")
    } else {
      message("  - ", f, " (不存在)")
    }
  }

  # 3. 检查R包
  message("\n3. 检查R包...")
  required_pkgs <- c("shiny", "DBI", "RSQLite", "dplyr", "biomaRt", "KEGGREST")
  for (pkg in required_pkgs) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      message("  ✓ ", pkg, " (", packageVersion(pkg), ")")
    } else {
      message("  ✗ ", pkg, " (未安装)")
    }
  }

  # 4. 检查网络连接
  message("\n4. 检查网络连接...")
  tryCatch({
    KEGGREST::keggList("organism", limit = 1)
    message("  ✓ KEGG API连接正常")
  }, error = function(e) {
    message("  ✗ KEGG API连接失败: ", e$message)
  })

  tryCatch({
    mart <- biomaRt::useMart("ensembl", dataset = "mmusculus_gene_ensembl")
    message("  ✓ Ensembl/BioMart连接正常")
  }, error = function(e) {
    message("  ✗ Ensembl/BioMart连接失败: ", e$message)
  })

  # 5. 检查临时文件
  message("\n5. 检查临时文件...")
  r_files <- list.files(pattern = "\\.rds$")
  if (length(r_files) > 0) {
    message("  发现 ", length(r_files), " 个.rds文件")
  } else {
    message("  ✓ 无多余临时文件")
  }

  message("\n=== 诊断完成 ===\n")
}

# 运行诊断
diagnose_biofree()
```

---

## 📝 更新日志

### 2025-01-03
- ✅ 创建Bug修复手册
- ✅ 记录所有已知的Bug和解决方案
- ✅ 添加诊断工具集
- ✅ 整理相关文档链接

---

## 🔍 快速查找

### 按症状查找

| 症状 | 可能原因 | 参考章节 |
|------|---------|---------|
| 应用启动失败 | 数据库锁定、包缺失 | [数据库锁定](#数据库锁定问题), [兼容性](#兼容性问题) |
| 注释失败 | 网络问题、ID错误 | [Ensembl注释](#ensembl-id注释失败), [Symbol注释](#symbol注释修复) |
| KEGG无结果 | 单基因、API限流 | [单基因KEGG](#单个基因kegg查询失败) |
| R无响应 | 会话锁定 | [R会话锁定](#r会话锁定) |
| 磁盘空间不足 | 临时文件 | [临时文件清理](#临时文件清理) |

---

## 📚 相关文档

项目中的其他重要文档：

- `README.md` - 项目概述
- `PROJECT_STATUS_REPORT.md` - 项目状态报告
- `UPDATE_SUMMARY_2025_01_03.md` - 更新总结
- `AUTO_UPDATE_ENABLED.md` - 自动更新说明
- `AUTO_DATABASE_CHECK.md` - 数据库检查说明

---

## 🎯 最佳实践

### 开发流程
1. **遇到Bug时**
   - 第一步：运行 `diagnose.R` 检查系统状态
   - 第二步：在本手册中搜索类似问题
   - 第三步：按照文档中的解决方案操作

2. **解决Bug后**
   - 更新本手册，记录新问题和解决方案
   - 运行测试确保修复有效
   - 更新相关文档

3. **预防措施**
   - 定期运行清理脚本
   - 检查日志文件
   - 保持R包更新

### 代码规范
- 使用 `tryCatch` 处理错误
- 使用 `on.exit` 清理资源
- 添加详细的日志信息
- 编写可重用的工具函数

---

## 🆘 获取帮助

如果手册中没有解决方案：

1. **收集诊断信息**
   ```r
   source("scripts/diagnose.R")
   diagnose_biofree()
   ```

2. **查看详细日志**
   - 检查 `logs/` 目录
   - 查看控制台输出
   - 启用详细模式

3. **参考外部资源**
   - R官方文档
   - Stack Overflow
   - GitHub Issues

---

**文档维护**: 每次修复Bug后更新此文档，确保信息的准确性和时效性。
