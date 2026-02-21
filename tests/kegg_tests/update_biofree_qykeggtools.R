# =====================================================
# biofree.qyKEGGtools 包更新模块
# 添加 universe 参数支持
# =====================================================
# 作者：文献计量与基础医学
# 目的：为 biofree.qyKEGGtools 包添加 universe 参数支持
# 用法：运行此脚本来更新已安装的包
# =====================================================

cat("\n========================================\n")
cat("biofree.qyKEGGtools 包更新工具\n")
cat("========================================\n\n")

# =====================================================
# 步骤1：检查当前包状态
# =====================================================

cat("1️⃣ 检查当前包状态...\n")

if (!require("biofree.qyKEGGtools", quietly = TRUE)) {
  cat("❌ biofree.qyKEGGtools 未安装\n")
  cat("\n请先安装包：\n")
  cat("  remotes::install_github('Passpoor/biofree.qyKEGGtools')\n")
  stop("包未安装")
}

pkg_version <- packageVersion("biofree.qyKEGGtools")
cat(sprintf("✅ 当前版本: %s\n", pkg_version))

# 获取包的安装路径
pkg_path <- system.file(package = "biofree.qyKEGGtools")
cat(sprintf("📁 包路径: %s\n", pkg_path))

# 检查原始函数
func_args <- tryCatch({
  formals(biofree.qyKEGGtools::enrich_local_KEGG)
}, error = function(e) NULL)

if (is.null(func_args)) {
  cat("❌ 无法读取 enrich_local_KEGG 函数\n")
  stop("函数不存在")
}

cat(sprintf("📋 当前参数: %s\n\n", paste(names(func_args), collapse = ", ")))

# 检查是否支持universe
supports_universe <- "universe" %in% names(func_args)

if (supports_universe) {
  cat("✅ 当前版本已支持 universe 参数\n")
  cat("无需更新！\n")
  return(invisible(TRUE))
} else {
  cat("⚠️ 当前版本不支持 universe 参数\n")
  cat("📝 将添加以下功能：\n")
  cat("   - universe 参数（自定义背景基因集）\n")
  cat("   - pAdjustMethod 参数（多种校正方法）\n")
  cat("   - minGSSize / maxGSSize 参数（通路大小过滤）\n\n")
}

# =====================================================
# 步骤2：创建更新后的函数文件
# =====================================================

cat("2️⃣ 创建更新后的函数...\n")

# 读取原始的 enrich_local_KEGG 函数
original_func <- biofree.qyKEGGtools::enrich_local_KEGG

# 创建更新后的函数（带universe支持）
updated_func <- function(
  gene,
  species,
  pCutoff = 0.05,
  qCutoff = NULL,
  universe = NULL,        # ✨ 新增
  pAdjustMethod = "BH",   # ✨ 新增
  minGSSize = 10,         # ✨ 新增
  maxGSSize = 500,        # ✨ 新增
  db_dir = NULL
) {

  # =====================================================
  # 参数验证
  # =====================================================

  # 验证gene
  if (!is.character(gene)) {
    gene <- as.character(gene)
  }

  gene <- unique(gene)
  gene <- gene[!is.na(gene) & gene != ""]

  if (length(gene) < 2) {
    stop("At least 2 genes are required for enrichment analysis")
  }

  K <- length(gene)

  # 验证species
  if (!is.character(species) || length(species) != 1) {
    stop("'species' must be a single character value (e.g., 'hsa', 'mmu')")
  }

  # 验证pCutoff
  if (!is.numeric(pCutoff) || length(pCutoff) != 1 || pCutoff <= 0 || pCutoff > 1) {
    stop("'pCutoff' must be a numeric value between 0 and 1")
  }

  # 验证pAdjustMethod
  valid_methods <- c("holm", "hochberg", "hommel", "bonferroni",
                     "BH", "BY", "fdr", "none")
  if (!is.character(pAdjustMethod) || length(pAdjustMethod) != 1 ||
      !pAdjustMethod %in% valid_methods) {
    stop(sprintf(
      "'pAdjustMethod' must be one of: %s",
      paste(valid_methods, collapse = ", ")
    ))
  }

  # 验证minGSSize和maxGSSize
  if (!is.numeric(minGSSize) || minGSSize < 5) {
    stop("'minGSSize' must be >= 5")
  }

  if (!is.numeric(maxGSSize) || maxGSSize < minGSSize) {
    stop("'maxGSSize' must be >= 'minGSSize'")
  }

  # =====================================================
  # 加载KEGG数据库
  # =====================================================

  if (is.null(db_dir)) {
    db_dir <- system.file("extdata", package = "biofree.qyKEGGtools")
  }

  species_db_file <- file.path(db_dir, species, "kegg_annot.rds")

  if (!file.exists(species_db_file)) {
    stop(sprintf(
      "KEGG database not found for species: %s\n%s",
      species,
      "Supported species: hsa, mmu, rno, etc."
    ))
  }

  kegg_db <- readRDS(species_db_file)

  # =====================================================
  # ✨ 处理 universe 参数（核心）
  # =====================================================

  if (is.null(universe)) {
    # 未提供universe：使用全基因组
    background_genes <- kegg_db$all_genes
    message(sprintf("Using full KEGG genome as background: %d genes",
                    length(background_genes)))
  } else {
    # ✨ 使用自定义universe

    # 验证格式
    if (!is.character(universe)) {
      universe <- as.character(universe)
    }

    universe <- unique(universe)
    universe <- universe[!is.na(universe) & universe != ""]

    if (length(universe) == 0) {
      stop("'universe' cannot be empty")
    }

    # ⭐ 关键：验证universe包含所有gene（对齐clusterProfiler）
    genes_not_in_universe <- gene[!gene %in% universe]

    if (length(genes_not_in_universe) > 0) {
      warning(sprintf(
        "Removing %d genes not in universe: %s",
        length(genes_not_in_universe),
        paste(head(genes_not_in_universe, 5), collapse = ", ")
      ))

      gene <- gene[gene %in% universe]
      K <- length(gene)

      if (K < 2) {
        stop("Less than 2 genes remaining after filtering")
      }
    }

    # ✨ 与KEGG数据库取交集
    background_genes <- intersect(universe, kegg_db$all_genes)

    if (length(background_genes) == 0) {
      stop("None of the universe genes found in KEGG database.\n",
           "Please check if ENTREZ IDs are correct.")
    }

    # 警告：如果过滤太多
    if (length(background_genes) < length(universe) * 0.5) {
      warning(sprintf(
        "Only %d out of %d universe genes found in KEGG database (%.1f%%).",
        length(background_genes),
        length(universe),
        100 * length(background_genes) / length(universe)
      ))
    }

    message(sprintf("Using custom universe: %d genes", length(background_genes)))
  }

  M <- length(background_genes)  # ✨ 背景基因总数

  # =====================================================
  # 获取通路数据
  # =====================================================

  pathways <- kegg_db$pathway2gene

  if (length(pathways) == 0) {
    stop("No pathways found in KEGG database")
  }

  # =====================================================
  # 对每个通路进行超几何检验
  # =====================================================

  results_list <- list()

  for (pathway_id in names(pathways)) {
    pathway_genes <- pathways[[pathway_id]]
    n <- length(pathway_genes)

    # ✨ 过滤通路大小
    if (n < minGSSize || n > maxGSSize) {
      next
    }

    # 计算重叠
    overlap <- intersect(gene, pathway_genes)
    k <- length(overlap)

    if (k == 0) {
      next
    }

    # 超几何检验
    pvalue <- phyper(k - 1, n, M - n, K, lower.tail = FALSE)

    # 保存结果
    results_list[[pathway_id]] <- list(
      ID = pathway_id,
      Description = kegg_db$pathway_info[pathway_id, "name"],
      pvalue = pvalue,
      GeneRatio = paste(k, K, sep = "/"),
      BgRatio = paste(n, M, sep = "/"),
      geneID = paste(overlap, collapse = "/"),
      Count = k
    )
  }

  # =====================================================
  # 多重检验校正
  # =====================================================

  if (length(results_list) > 0) {
    pvalues <- sapply(results_list, function(x) x$pvalue)

    # ✨ 支持多种校正方法
    padj <- p.adjust(pvalues, method = pAdjustMethod)

    for (i in seq_along(results_list)) {
      results_list[[i]]$p.adjust <- padj[i]
      results_list[[i]]$qvalue <- padj[i]
    }
  }

  # =====================================================
  # 过滤显著通路
  # =====================================================

  significant_results <- Filter(function(x) {
    x$pvalue <= pCutoff && (is.null(qCutoff) || x$p.adjust <= qCutoff)
  }, results_list)

  if (length(significant_results) == 0) {
    warning("No significant pathways found")
    return(new("enrichResult",
               result = data.frame(),
               pAdjustMethod = pAdjustMethod,
               organism = species,
               ontology = "KEGG"))
  }

  # =====================================================
  # 组装结果数据框
  # =====================================================

  result_df <- do.call(rbind, lapply(significant_results, function(x) {
    data.frame(
      ID = x$ID,
      Description = x$Description,
      GeneRatio = x$GeneRatio,
      BgRatio = x$BgRatio,
      pvalue = x$pvalue,
      p.adjust = x$p.adjust,
      qvalue = x$qvalue,
      geneID = x$geneID,
      Count = x$Count,
      stringsAsFactors = FALSE
    )
  }))

  rownames(result_df) <- NULL
  result_df <- result_df[order(result_df$p.adjust), ]

  # =====================================================
  # 创建并返回enrichResult对象
  # =====================================================

  enrich_obj <- new("enrichResult",
                    result = result_df,
                    pAdjustMethod = pAdjustMethod,
                    pvalueCutoff = pCutoff,
                    qvalueCutoff = qCutoff,
                    organism = species,
                    ontology = "KEGG",
                    gene = as.character(gene),
                    universe = background_genes)  # ✨ 保存universe

  return(enrich_obj)
}

cat("✅ 更新后的函数已创建\n\n")

# =====================================================
# 步骤3：更新包中的函数
# =====================================================

cat("3️⃣ 更新包中的函数...\n")

# 方法：在全局环境中替换函数
assign("enrich_local_KEGG", updated_func, envir = asNamespace("biofree.qyKEGGtools"))

cat("✅ 函数已在包的命名空间中更新\n\n")

# =====================================================
# 步骤4：验证更新
# =====================================================

cat("4️⃣ 验证更新...\n")

# 检查更新后的参数
updated_args <- formals(biofree.qyKEGGtools::enrich_local_KEGG)
cat(sprintf("📋 更新后的参数: %s\n", paste(names(updated_args), collapse = ", ")))

# 验证新参数存在
if ("universe" %in% names(updated_args)) {
  cat("✅ universe 参数已添加\n")
} else {
  cat("❌ universe 参数添加失败\n")
}

if ("pAdjustMethod" %in% names(updated_args)) {
  cat("✅ pAdjustMethod 参数已添加\n")
} else {
  cat("❌ pAdjustMethod 参数添加失败\n")
}

if ("minGSSize" %in% names(updated_args)) {
  cat("✅ minGSSize 参数已添加\n")
} else {
  cat("❌ minGSSize 参数添加失败\n")
}

if ("maxGSSize" %in% names(updated_args)) {
  cat("✅ maxGSSize 参数已添加\n")
} else {
  cat("❌ maxGSSize 参数添加失败\n")
}

cat("\n")

# =====================================================
# 步骤5：创建备份文件（可选）
# =====================================================

cat("5️⃣ 创建备份文件...\n")

backup_dir <- file.path(pkg_path, "backup")
if (!dir.exists(backup_dir)) {
  dir.create(backup_dir)
}

backup_file <- file.path(backup_dir,
                         sprintf("enrich_local_KEGG_backup_%s.R",
                                 format(Sys.Date(), "%Y%m%d")))

# 保存更新后的函数到备份文件
writeLines(
  c(
    "# biofree.qyKEGGtools::enrich_local_KEGG 备份",
    sprintf("# 备份日期: %s", Sys.Date()),
    "# 这是更新后的函数版本，支持 universe 参数",
    "",
    deparse(body(updated_func))
  ),
  backup_file
)

cat(sprintf("✅ 备份已创建: %s\n", backup_file))

# =====================================================
# 步骤6：永久更新（可选）
# =====================================================

cat("\n6️⃣ 使更新永久生效...\n\n")

cat("当前更新仅在当前R会话中有效。\n")
cat("要使更新永久生效，请选择以下方式之一：\n\n")

cat("方式1: 更新源代码（推荐）\n")
cat("--------------------------------\n")
cat("1. 找到包的安装目录:\n")
cat(sprintf("   %s\n", pkg_path))
cat("\n2. 找到 R/enrich_local_KEGG.R 文件\n")
cat("\n3. 用更新后的函数替换原函数\n")
cat("\n4. 或者：将备份文件复制到 R/ 目录\n\n")

cat("方式2: 使用 .Rprofile 自动加载（临时）\n")
cat("--------------------------------\n")
cat("在 ~/.Rprofile 中添加:\n\n")
cat(sprintf("source('%s')\n", backup_file))
cat("\n这样每次启动R时会自动加载更新后的函数\n\n")

cat("方式3: 重新安装包（需要修改源代码）\n")
cat("--------------------------------\n")
cat("1. Fork GitHub仓库: https://github.com/Passpoor/biofree.qyKEGGtools\n")
cat("2. 修改 R/enrich_local_KEGG.R 文件\n")
cat("3. 重新安装:\n")
cat("   remotes::install_github('yourusername/biofree.qyKEGGtools')\n\n")

# =====================================================
# 完成
# =====================================================

cat("\n========================================\n")
cat("更新完成！\n")
cat("========================================\n\n")

cat("✅ biofree.qyKEGGtools 已在当前R会话中更新\n")
cat("✅ 现在支持以下新功能：\n")
cat("   - universe 参数（自定义背景基因集）\n")
cat("   - pAdjustMethod 参数（BH, BY, bonferroni, etc.）\n")
cat("   - minGSSize / maxGSSize 参数（通路大小过滤）\n\n")

cat("📝 使用示例：\n")
cat("library(biofree.qyKEGGtools)\n\n")
cat("# 不使用universe\n")
cat("result1 <- enrich_local_KEGG(\n")
cat("  gene = c('672', '7157', '7422'),\n")
cat("  species = 'hsa',\n")
cat("  pCutoff = 0.05\n")
cat(")\n\n")
cat("# 使用universe（推荐）\n")
cat("result2 <- enrich_local_KEGG(\n")
cat("  gene = c('672', '7157', '7422'),\n")
cat("  species = 'hsa',\n")
cat("  pCutoff = 0.05,\n")
cat("  universe = c('672', '7157', '7422', '5295', '7158', ...)\n")
cat(")\n\n")

cat("⚠️ 重要提示：\n")
cat("   - 此更新仅在当前R会话中有效\n")
cat("   - 重启R后需要重新运行此脚本\n")
cat("   - 建议使用方式1永久更新源代码\n\n")

cat("========================================\n")

# 返回更新后的函数（ invisibly）
invisible(updated_func)
