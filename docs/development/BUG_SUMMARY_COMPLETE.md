# BioFastFree Bug 修复完整总结

> **版本**: v11.2
> **更新日期**: 2025-01-04
> **维护者**: Development Team
> **状态**: ✅ 已整合所有已知Bug和解决方案

---

## 📋 文档说明

本文档整合了 BioFastFree 项目开发过程中遇到的所有 Bug、问题及其解决方案。是开发和维护人员的重要参考手册。

### 使用方法
1. **遇到问题时**：首先在文档中搜索相关错误信息
2. **按类别查找**：根据问题类型快速定位
3. **参考解决方案**：按照记录的步骤操作
4. **更新文档**：解决新问题后及时更新

---

## 🐛 Bug 分类索引

### 🔴 高优先级问题
- [数据库锁定](#1-数据库锁定问题)
- [Ensembl ID 注释失败](#2-ensembl-id-注释失败)
- [单个基因 KEGG 查询失败](#3-单个基因-kegg-查询失败)
- [富集分析背景基因集选择错误](#4-富集分析背景基因集选择错误) ⭐

### 🟡 中优先级问题
- [Symbol 注释修复](#5-symbol-注释修复)
- [假基因过滤](#6-假基因过滤问题)
- [NA 值处理](#7-na-值处理)
- [数据库版本缓存](#8-数据库版本缓存不一致)

### 🟢 低优先级问题
- [KEGG 批量查询优化](#9-kegg-通路批量查询优化)
- [项目结构清理](#10-项目结构清理)
- [R 会话锁定](#11-r会话锁定)

---

## 详细 Bug 修复记录

### 1. 数据库锁定问题

**日期**: 2025-01-03
**优先级**: 🔴 高
**状态**: ✅ 已解决

#### 问题描述

**错误信息 1**:
```
Error in sqliteExecStatement(con, statement, ...) :
  SCHEMA: database schema has changed
```

**错误信息 2**:
```
Error in rsqlite_connect: database is locked
```

#### 根本原因

1. **多个 R 会话同时访问**同一个 SQLite 数据库
2. **数据库连接未正确关闭**
3. **文件系统锁机制冲突**（Windows 常见）
4. **临时锁文件残留**（.db-shm, .db-wal）

#### 诊断步骤

```r
# 检查锁文件
file.exists("biofree_annotation.db-shm")
file.exists("biofree_annotation.db-wal")

# 检查 R 进程
# Windows: 任务管理器查看 R.exe
# Linux/Mac: ps aux | grep R
```

#### 解决方案

**方案 1: 快速清理锁文件** ⭐

```r
# 创建 cleanup_r_locks.R
cleanup_r_locks <- function(db_path = "data/biofree_annotation.db") {
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
        warning("无法删除锁文件: ", lock_file)
      })
    }
  }

  message("✓ 锁文件清理完成")
}

# 执行清理
cleanup_r_locks()
```

**方案 2: 优化数据库连接**

```r
db_connect <- function(db_path) {
  DBI::dbConnect(
    RSQLite::SQLite(),
    db_path,
    loadable.extensions = TRUE,
    cache_size = 2000,
    synchronous = "OFF",
    journal_mode = "WAL"
  )
}

# 确保连接关闭
on.exit(DBI::dbDisconnect(con), add = TRUE)
```

**方案 3: 重启 R 会话**

```r
# 完全重启 R
.rs.restartR()

# 或者关闭所有 R 进程后重新启动
```

#### 预防措施

1. ✅ 使用完数据库立即关闭连接
2. ✅ 避免在多个 R 会话中同时打开同一数据库
3. ✅ 定期运行 `cleanup_r_locks.R`
4. ✅ 在应用关闭时清理所有连接

#### 相关文档
- `docs/bug_fixes/DB_LOCK_ERROR_FIX.md` - 详细技术说明
- `scripts/cleanup/cleanup_r_locks.R` - 自动清理脚本

---

### 2. Ensembl ID 注释失败

**日期**: 2025-01-03
**优先级**: 🔴 高
**状态**: ✅ 已解决

#### 问题描述

**错误信息**:
```
Error: Cannot retrieve Ensembl annotation for gene: ENSMUSG00000012345
```

#### 根本原因

1. **网络问题**导致 biomaRt 无法连接
2. **Ensembl ID 版本不匹配**
3. **基因 ID 已过时或被删除**
4. **API 请求过于频繁**被限制

#### 解决方案

**步骤 1: 检查网络连接**

```r
library(biomaRt)
mart <- useMart("ensembl", dataset = "mmusculus_gene_ensembl")
test <- getBM(
  attributes = 'ensembl_gene_id',
  filters = 'ensembl_gene_id',
  values = 'ENSMUSG00000012345',
  mart = mart
)
```

**步骤 2: 更新 Ensembl 版本**

```r
# 使用特定版本的 Ensembl
mart <- useMart(
  "ensembl",
  dataset = "mmusculus_gene_ensembl",
  host = "https://dec2024.archive.ensembl.org"
)
```

**步骤 3: 本地数据库方案** ⭐ 推荐

```r
library(org.Mm.eg.db)

# Ensembl -> Symbol
ensembl_to_symbol <- function(ensembl_ids) {
  symbols <- mapIds(
    org.Mm.eg.db,
    keys = ensembl_ids,
    column = "SYMBOL",
    keytype = "ENSEMBL",
    multiVals = "first"
  )
  return(symbols)
}

# 使用
genes <- c("ENSMUSG00000012345", "ENSMUSG00000067890")
symbols <- ensembl_to_symbol(genes)
```

**步骤 4: 批量重试机制**

```r
annotate_ensembl_batch <- function(ensembl_ids, max_retries = 3) {
  results <- vector("list", length(ensembl_ids))

  for (i in seq_along(ensembl_ids)) {
    for (attempt in 1:max_retries) {
      tryCatch({
        results[[i]] <- query_ensembl(ensembl_ids[i])
        break
      }, error = function(e) {
        if (attempt == max_retries) {
          results[[i]] <- NA
        } else {
          Sys.sleep(2)
        }
      })
    }
  }

  return(unlist(results))
}
```

#### 预防措施

1. ✅ 定期更新本地注释数据库
2. ✅ 实现离线注释功能
3. ✅ 添加重试和超时机制
4. ✅ 使用本地数据库优先

#### 相关文档
- `docs/bug_fixes/ENSEMBL_ID_ANNOTATION_FIX.md`
- `docs/UNANNOTATED_GENES_SOLUTION.md`

---

### 3. 单个基因 KEGG 查询失败

**日期**: 2025-01-03
**优先级**: 🔴 高
**状态**: ✅ 已解决

#### 问题描述

**症状**: 当用户只输入一个基因时，KEGG 通路分析返回错误或空结果。

#### 根本原因

1. KEGG API 对单个基因的查询处理方式不同
2. 需要使用不同的参数格式
3. 统计检验需要足够的样本量

#### 解决方案

**方案 1: 单基因特殊处理** ⭐

```r
query_kegg_pathway <- function(gene_list) {
  if (length(gene_list) == 1) {
    message("检测到单个基因，使用单基因查询模式")

    # 添加看家基因
    extended_genes <- c(gene_list, "Actb", "Gapdh")

    # 使用特殊查询方式
    result <- tryCatch({
      pathways <- KEGGREST::keggList("pathway", gene_list)
      return(pathways)
    }, error = function(e) {
      warning("KEGG查询失败: ", e$message)
      return(NULL)
    })
  } else {
    result <- query_kegg_batch(gene_list)
  }

  return(result)
}
```

**方案 2: 降级处理**

```r
safe_kegg_query <- function(genes) {
  result <- tryCatch({
    query_kegg_pathway(genes)
  }, error = function(e) {
    message("批量查询失败，尝试单个查询")

    results <- lapply(genes, function(gene) {
      tryCatch({
        KEGGREST::keggFind("genes", gene)
      }, error = function(e) NULL)
    })

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

**方案 3: 添加调试信息**

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

  result <- KEGGREST::keggFind("pathway", paste(genes, collapse = "+"))
  message("返回结果数: ", nrow(result))

  return(result)
}
```

#### 预防措施

1. ✅ 在 UI 层面提示用户输入多个基因
2. ✅ 提供测试基因按钮
3. ✅ 实现降级查询策略
4. ✅ 添加友好的错误提示

#### 相关文档
- `docs/bug_fixes/SINGLE_GENE_KEGG_FIX.md`
- `docs/KEGG_DEBUG_GUIDE.md`

---

### 4. 富集分析背景基因集选择错误 ⭐

**日期**: 2025-01-03
**优先级**: 🔴 高
**重要性**: ⭐⭐⭐⭐⭐
**状态**: ✅ 已解决

#### 问题描述

这是**最常见且最重要的问题**！错误的背景基因集选择会导致：

- ❌ **假阳性**: 富集结果看起来很显著，但是是错误的
- ❌ **假阴性**: 真实的富集信号被掩盖
- ❌ **不可重复**: 结果无法被其他研究重现

#### 根本原因

**不理解背景基因集（Universe）的正确含义**

#### 三大核心原则

**1️⃣ Universe 一定是「交集」，不是「并集」**

```
❌ 错误: Universe = A的所有基因 ∪ B的所有基因（并集）
✅ 正确: Universe = A的所有基因 ∩ B的所有基因（交集）

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
❌ 错误: Universe = 差异基因（显著基因）
✅ 正确: Universe = 所有检测到的基因（显著 + 不显著）

Universe ≠ 差异基因
Universe = 统计背景（Statistical Background）
```

**类比理解**:
- **Target** = 中奖号码（7个）
- **Universe** = 所有参与抽奖的号码（1000个）
- **不是**全世界所有可能的号码！

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

**❌ 错误做法**:

```r
# 错误 1: 只用 A 的基因
Universe = 20,000  # A的所有基因
# 问题: 包含了 2,000 个只在 A 中、不在 B 中的基因

# 错误 2: 用并集
Universe = 20,000 + 18,000 = 38,000  # 并集
# 问题: 包含了 5,000 个只在 A 或只在 B 中的基因

# 错误 3: 只用显著基因
sig_A <- 1000 + 800 = 1800
sig_B <- 900 + 1200 = 2100
Universe = sig_A ∪ sig_B  # 并集
# 问题: 人为夸大富集比例（假阳性）
```

**✅ 正确做法**:

```r
# Step 1: 提取所有基因（显著 + 不显著）
all_genes_A <- Dataset_A$Gene  # 20,000 个
all_genes_B <- Dataset_B$Gene  # 18,000 个

# Step 2: 计算交集
Universe <- all_genes_A ∩ all_genes_B
# 结果: 15,000 个基因

这 15,000 个基因包括：
  - 显著基因（上调 + 下调）
  - 不显著基因
  - 无变化基因

关键：
  ✅ 只有这 15,000 个基因同时存在于 A 和 B 中
  ✅ 只有这 15,000 个基因"有资格"进入 A∩B 的 Target
  ✅ 统计空间准确
```

#### 代码实现

```r
library(clusterProfiler)

enrich_intersect_kegg <- function(
    DE_results_A,
    DE_results_B,
    fc_threshold_A = 1,
    fc_threshold_B = -1,
    padj_threshold = 0.05,
    organism = "mmu"
) {

  # 1. 定义 Target
  up_A <- DE_results_A$gene[DE_results_A$log2FoldChange > fc_threshold_A &
                            DE_results_A$padj < padj_threshold]

  down_B <- DE_results_B$gene[DE_results_B$log2FoldChange < fc_threshold_B &
                              DE_results_B$padj < padj_threshold]

  target_genes <- intersect(up_A, down_B)

  # 2. 定义 Universe（关键！）
  universe_A <- DE_results_A$gene  # A 中所有基因
  universe_B <- DE_results_B$gene  # B 中所有基因
  universe <- intersect(universe_A, universe_B)  # 交集

  # 3. 验证
  stopifnot(all(target_genes %in% universe))

  # 4. 富集分析
  kegg_result <- enrichKEGG(
    gene = target_genes,
    universe = universe,  # ✅ 使用正确的 Universe
    organism = organism,
    pvalueCutoff = 0.05
  )

  return(kegg_result)
}
```

#### 常见错误案例

| 错误做法 | 后果 |
|---------|------|
| 使用全基因组（50,000+基因） | 稀释信号，假阴性 |
| 只用显著基因 | 夸大富集，假阳性 |
| Universe 与 Target 逻辑不一致 | 统计空间错误 |

#### 预防措施

1. ✅ 分析前检查清单
2. ✅ 使用应用的多文件背景基因集功能
3. ✅ 记录 Universe 的选择依据
4. ✅ 验证 Target ⊆ Universe

#### 相关文档
- `docs/UNIVERSE_CORE_PRINCIPLES.md` - 核心原则详解
- `docs/ENRICHMENT_UNIVERSE_GUIDE.md` - 完整指南
- `docs/MULTI_FILE_BACKGROUND_QUICK_GUIDE.md` - 快速指南

---

### 5. Symbol 注释修复

**日期**: 2025-01-03
**优先级**: 🟡 中
**状态**: ✅ 已解决

#### 问题描述

基因 Symbol 大小写不一致导致注释失败。

#### 解决方案

```r
# 标准化 Gene Symbol
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
- `docs/bug_fixes/SYMBOL_ANNOTATION_FIX.md`

---

### 6. 假基因过滤问题

**日期**: 2025-01-03
**优先级**: 🟡 中
**状态**: ✅ 已解决

#### 问题描述

注释结果包含大量假基因（Pseudogene），影响分析质量。

#### 解决方案

```r
# 过滤假基因
filter_pseudogenes <- function(annotation_df) {
  # 移除包含 pseudogene 的条目
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
- `docs/bug_fixes/PSEUDO_GENE_FILTER_FIX.md`

---

### 7. NA 值处理

**日期**: 2025-01-03
**优先级**: 🟡 中
**状态**: ✅ 已解决

#### 问题描述

数据中包含 NA 值导致分析失败。

#### 解决方案

```r
# 安全的数据清理
safe_clean_data <- function(df) {
  # 检查 NA
  na_count <- sum(is.na(df))
  if (na_count > 0) {
    message("发现 ", na_count, " 个 NA 值")

    # 策略 1: 删除包含 NA 的行
    df <- na.omit(df)

    # 或策略 2: 填充 NA
    # df[is.na(df)] <- 0
  }

  return(df)
}
```

#### 相关文档
- `docs/bug_fixes/NA_VALUE_FIX.md`

---

### 8. 数据库版本缓存不一致

**日期**: 2025-01-03
**优先级**: 🟡 中
**状态**: ✅ 已解决

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

#### 相关文档
- `docs/archive/DB_VERSION_CACHE.md`

---

### 9. KEGG 通路批量查询优化

**日期**: 2025-01-03
**优先级**: 🟢 低
**状态**: ✅ 已优化

#### 问题描述

批量查询 KEGG 通路时速度慢，容易超时。

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

    Sys.sleep(1)  # 避免请求过快
  }

  # 合并结果
  do.call(rbind, all_results)
}
```

---

### 10. 项目结构清理

**日期**: 2025-01-04
**优先级**: 🟢 低
**状态**: ✅ 已完成

#### 问题

项目根目录文件过多，不利于维护。

#### 解决方案

详见 `PROJECT_CLEANUP_REPORT.md`

**整理内容**:
- ✅ 文档分类归档（archive/bug_fixes）
- ✅ 脚本分类整理（cleanup/tests）
- ✅ 临时文件清理
- ✅ 目录结构优化
- ✅ .gitignore 更新

---

### 11. R 会话锁定

**日期**: 2025-01-03
**优先级**: 🟢 低
**状态**: ✅ 已解决

#### 问题描述

R 会话无响应或卡死。

#### 解决方案

```r
# 完全重启 R
.rs.restartR()

# 或手动清理
.closeAllConnections()
gc()
```

#### 预防措施

1. ✅ 定期保存工作
2. ✅ 避免创建过大的对象
3. ✅ 使用 `rm()` 删除不需要的对象
4. ✅ 定期运行 `gc()`

---

## 🔧 快速诊断工具

### 综合诊断脚本

```r
# diagnose_biofree.R
diagnose_biofree <- function() {
  cat("=== BioFastFree 诊断工具 ===\n\n")

  # 1. 检查 R 版本
  cat("【1】R 版本检查\n")
  cat("R 版本:", R.version.string, "\n")
  if (getRversion() < "4.0.0") {
    cat("⚠️  R 版本过低，建议升级\n")
  } else {
    cat("✅ R 版本正常\n")
  }

  # 2. 检查必需的包
  cat("\n【2】包依赖检查\n")
  required_packages <- c("shiny", "clusterProfiler", "org.Mm.eg.db")
  for (pkg in required_packages) {
    if (require(pkg, quietly = TRUE)) {
      cat("✅", pkg, "\n")
    } else {
      cat("❌", pkg, "- 需要安装\n")
    }
  }

  # 3. 检查数据库文件
  cat("\n【3】数据库文件检查\n")
  db_files <- c("biofree_users.sqlite", "biofree_annotation.db")
  for (db in db_files) {
    if (file.exists(db)) {
      cat("✅", db, "\n")
    } else {
      cat("❌", db, "- 不存在\n")
    }
  }

  # 4. 检查锁文件
  cat("\n【4】锁文件检查\n")
  lock_files <- list.files(pattern = "-(shm|wal)$")
  if (length(lock_files) > 0) {
    cat("⚠️  发现残留锁文件:\n")
    print(lock_files)
    cat("   运行 cleanup_r_locks() 清理\n")
  } else {
    cat("✅ 无残留锁文件\n")
  }

  # 5. 检查内存
  cat("\n【5】内存使用\n")
  mem_size <- gc()[2, 2]
  cat("已用内存:", round(mem_size / 1024^2, 2), "MB\n")

  cat("\n=== 诊断完成 ===\n")
}

# 运行诊断
diagnose_biofree()
```

---

## 📊 Bug 统计

### 按优先级分类

| 优先级 | 数量 | 状态 |
|--------|------|------|
| 🔴 高 | 4 | ✅ 已解决 |
| 🟡 中 | 4 | ✅ 已解决 |
| 🟢 低 | 3 | ✅ 已解决 |
| **总计** | **11** | **100% 解决率** |

### 按类别分类

| 类别 | 数量 |
|------|------|
| 数据库相关 | 2 |
| 基因注释相关 | 3 |
| KEGG 分析相关 | 3 |
| 数据处理相关 | 3 |

---

## 🎯 最佳实践总结

### 开发原则

1. **错误处理优先**
   - 所有外部 API 调用都要有 tryCatch
   - 提供友好的错误提示
   - 实现降级策略

2. **数据验证**
   - 输入数据必须验证
   - 检查 NA 值和异常值
   - 验证逻辑一致性

3. **性能优化**
   - 批量操作
   - 使用缓存
   - 避免重复计算

4. **文档记录**
   - 记录所有 Bug 和解决方案
   - 更新相关文档
   - 添加代码注释

### 用户支持

1. **诊断优先**
   - 提供诊断脚本
   - 收集详细错误信息
   - 引导用户自助解决

2. **预防为主**
   - 添加输入验证
   - 提供清晰提示
   - 实现自动修复

3. **持续改进**
   - 定期更新文档
   - 收集用户反馈
   - 优化用户体验

---

## 📚 相关文档索引

### 核心文档
- [用户手册](USER_MANUAL_COMPLETE.md) - 完整使用指南
- [项目整理报告](PROJECT_CLEANUP_REPORT.md) - 项目结构说明
- [README.md](README.md) - 项目简介

### Bug 修复文档
- `docs/bug_fixes/DB_LOCK_ERROR_FIX.md` - 数据库锁定
- `docs/bug_fixes/ENSEMBL_ID_ANNOTATION_FIX.md` - Ensembl 注释
- `docs/bug_fixes/SINGLE_GENE_KEGG_FIX.md` - 单基因 KEGG
- `docs/bug_fixes/SYMBOL_ANNOTATION_FIX.md` - Symbol 注释
- `docs/bug_fixes/PSEUDO_GENE_FILTER_FIX.md` - 假基因过滤
- `docs/bug_fixes/NA_VALUE_FIX.md` - NA 值处理

### 指南文档
- `docs/UNIVERSE_CORE_PRINCIPLES.md` - Universe 核心原则 ⭐
- `docs/ENRICHMENT_UNIVERSE_GUIDE.md` - 富集分析完整指南
- `docs/KEGG_DEBUG_GUIDE.md` - KEGG 调试指南
- `docs/COLUMN_SELECTOR_USAGE_GUIDE.md` - 列选择模块使用指南

### 历史文档（归档）
- `docs/archive/` - 历史更新和修复记录
- `docs/md_archive/` - 早期文档
- `docs/gsea_history/` - GSEA 更新历史

---

## 🔗 外部资源

### R 语言和 Bioconductor
- [R Project](https://www.r-project.org/)
- [Bioconductor](https://www.bioconductor.org/)
- [Shiny](https://shiny.rstudio.com/)

### 关键包文档
- [clusterProfiler](https://guangchuangyu.github.io/software/clusterProfiler/)
- [edgeR](https://bioconductor.org/packages/edgeR/)
- [limma](https://bioconductor.org/packages/limma/)
- [org.Mm.eg.db](https://bioconductor.org/packages/org.Mm.eg.db/)

### 数据库
- [KEGG](https://www.genome.jp/kegg/)
- [GO](http://geneontology.org/)
- [Ensembl](https://www.ensembl.org/)

---

## ✅ 检查清单

### 遇到问题时

- [ ] 1. 在本文档中搜索相关错误
- [ ] 2. 运行诊断脚本
- [ ] 3. 检查相关文档
- [ ] 4. 尝试推荐的解决方案
- [ ] 5. 如果仍无法解决，收集以下信息：
  - 完整错误信息
  - 数据类型和大小
  - R 版本和包版本
  - 操作系统

### 预防措施

- [ ] 定期清理临时文件
- [ ] 定期更新 R 和包
- [ ] 使用正确的 Universe 选择
- [ ] 验证输入数据
- [ ] 记录分析参数

---

## 📝 更新日志

### 2025-01-04
- ✅ 整合所有 Bug 修复文档
- ✅ 创建完整的 Bug 总结
- ✅ 添加快速诊断工具
- ✅ 优化文档结构

### 2025-01-03
- ✅ 解决数据库锁定问题
- ✅ 修复 Ensembl 注释
- ✅ 优化单基因 KEGG 查询
- ✅ 增强错误处理

---

**文档维护**: 本文档会持续更新，请以最新版本为准。

**最后更新**: 2025-01-04
**维护者**: Development Team
