# =====================================================
# biofree.qyKEGGtools 补丁模块
# 添加 universe 参数支持（无需修改原包）
# =====================================================
# 作者：文献计量与基础医学
# 目的：通过包装函数的方式添加 universe 支持
# 优点：不修改原包，避免权限问题
# =====================================================

cat("\n========================================\n")
cat("biofree.qyKEGGtools Universe 补丁\n")
cat("========================================\n\n")

# =====================================================
# 步骤1：检查当前包状态
# =====================================================

cat("1️⃣ 检查当前包状态...\n")

if (!require("biofree.qyKEGGtools", quietly = TRUE)) {
  cat("❌ biofree.qyKEGGtools 未安装\n")
  cat("\n请先安装：\n")
  cat("  remotes::install_github('Passpoor/biofree.qyKEGGtools')\n")
  stop("包未安装")
}

pkg_version <- packageVersion("biofree.qyKEGGtools")
cat(sprintf("✅ 当前版本: %s\n", pkg_version))

# 检查原始函数
func_args <- tryCatch({
  formals(biofree.qyKEGGtools::enrich_local_KEGG)
}, error = function(e) NULL)

if (is.null(func_args)) {
  cat("❌ 无法读取 enrich_local_KEGG 函数\n")
  stop("函数不存在")
}

cat(sprintf("📋 原始参数: %s\n\n", paste(names(func_args), collapse = ", ")))

# 检查是否支持universe
supports_universe <- "universe" %in% names(func_args)

if (supports_universe) {
  cat("✅ 当前版本已支持 universe 参数\n")
  cat("无需补丁！\n")
  return(invisible(TRUE))
} else {
  cat("⚠️ 当前版本不支持 universe 参数\n")
  cat("📝 将创建包装函数来添加支持\n\n")
}

# =====================================================
# 步骤2：创建增强版包装函数
# =====================================================

cat("2️⃣ 创建增强版包装函数...\n")

enrich_local_KEGG_enhanced <- function(
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
  # 设置默认 db_dir
  # =====================================================

  if (is.null(db_dir)) {
    # 使用 biofree.qyKEGGtools 的默认路径
    db_dir <- "~/biofree_KEGG_mirror"
  }

  # 展开路径（处理 ~）
  db_dir <- path.expand(db_dir)

  # =====================================================
  # ✨ 检查是否需要使用新参数
  # =====================================================

  needs_enhanced <- !is.null(universe) ||
                   pAdjustMethod != "BH" ||
                   minGSSize != 10 ||
                   maxGSSize != 500

  if (!needs_enhanced) {
    # 不需要新参数，直接使用原始函数
    message("使用原始 biofree.qyKEGGtools::enrich_local_KEGG")
    return(biofree.qyKEGGtools::enrich_local_KEGG(
      gene = gene,
      species = species,
      pCutoff = pCutoff,
      qCutoff = qCutoff,
      db_dir = db_dir
    ))
  }

  # =====================================================
  # ✨ 需要新参数，使用增强版实现
  # =====================================================

  message("使用增强版实现（支持自定义参数）")

  # 验证universe
  if (!is.null(universe)) {
    if (!is.character(universe)) {
      universe <- as.character(universe)
    }

    universe <- unique(universe)
    universe <- universe[!is.na(universe) & universe != ""]

    if (length(universe) == 0) {
      stop("'universe' cannot be empty")
    }

    # 验证包含关系
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

    message(sprintf("使用自定义 universe: %d genes", length(universe)))
  }

  # =====================================================
  # 加载KEGG数据库（使用 load_local_kegg）
  # =====================================================

  tryCatch({
    kegg_db <- biofree.qyKEGGtools::load_local_kegg(
      species = species,
      db_dir = db_dir
    )
  }, error = function(e) {
    stop(sprintf(
      "KEGG database not found for species: %s\n\n%s\n%s\n%s\n%s\n%s",
      species,
      "Database directory:", db_dir,
      "",
      "💡 解决方案：运行以下命令下载KEGG数据库",
      "   biofree.qyKEGGtools::update_local_kegg(species = 'hsa', db_dir = '~/biofree_KEGG_mirror')"
    ))
  })

  # =====================================================
  # ✨ 处理 universe
  # =====================================================

  if (is.null(universe)) {
    background_genes <- kegg_db$all_genes
    message(sprintf("Using full KEGG genome as background: %d genes",
                    length(background_genes)))
  } else {
    # 与KEGG数据库取交集
    background_genes <- intersect(universe, kegg_db$all_genes)

    if (length(background_genes) == 0) {
      stop("None of the universe genes found in KEGG database")
    }

    if (length(background_genes) < length(universe) * 0.5) {
      warning(sprintf(
        "Only %d out of %d universe genes found in KEGG database",
        length(background_genes),
        length(universe)
      ))
    }

    message(sprintf("Custom universe: %d genes (from %d input)",
                    length(background_genes),
                    length(universe)))
  }

  M <- length(background_genes)

  # =====================================================
  # 获取通路数据
  # =====================================================

  pathways <- kegg_db$pathway2gene

  if (length(pathways) == 0) {
    stop("No pathways found in KEGG database")
  }

  # =====================================================
  # 超几何检验
  # =====================================================

  results_list <- list()

  for (pathway_id in names(pathways)) {
    pathway_genes <- pathways[[pathway_id]]
    n <- length(pathway_genes)

    # 过滤通路大小
    if (n < minGSSize || n > maxGSSize) {
      next
    }

    overlap <- intersect(gene, pathway_genes)
    k <- length(overlap)

    if (k == 0) next

    pvalue <- phyper(k - 1, n, M - n, K, lower.tail = FALSE)

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

  if (length(results_list) == 0) {
    warning("No enrichment found")
    return(new("enrichResult",
               result = data.frame(),
               pAdjustMethod = pAdjustMethod,
               organism = species,
               ontology = "KEGG"))
  }

  # 多重检验校正
  pvalues <- sapply(results_list, function(x) x$pvalue)
  padj <- p.adjust(pvalues, method = pAdjustMethod)

  for (i in seq_along(results_list)) {
    results_list[[i]]$p.adjust <- padj[i]
    results_list[[i]]$qvalue <- padj[i]
  }

  # 过滤显著通路
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

  # 组装结果
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

  # 返回enrichResult
  enrich_obj <- new("enrichResult",
                    result = result_df,
                    pAdjustMethod = pAdjustMethod,
                    pvalueCutoff = pCutoff,
                    qvalueCutoff = qCutoff,
                    organism = species,
                    ontology = "KEGG",
                    gene = as.character(gene),
                    universe = background_genes)

  return(enrich_obj)
}

cat("✅ 增强版包装函数已创建\n\n")

# =====================================================
# 步骤3：设置为包的默认方法
# =====================================================

cat("3️⃣ 设置默认方法...\n")

# 在全局环境中设置
assign("enrich_local_KEGG", enrich_local_KEGG_enhanced, envir = globalenv())

cat("✅ 全局函数 'enrich_local_KEGG' 已设置为增强版\n")
cat("   （优先于 biofree.qyKEGGtools::enrich_local_KEGG）\n\n")

# =====================================================
# 步骤4：创建快捷函数
# =====================================================

cat("4️⃣ 创建快捷函数...\n")

# 快捷函数：直接使用增强版
enrichKEGG_universe <- function(...) {
  enrich_local_KEGG_enhanced(...)
}

assign("enrichKEGG_universe", enrichKEGG_universe, envir = globalenv())

cat("✅ 快捷函数 'enrichKEGG_universe' 已创建\n")
cat("   （与 enrich_local_KEGG 功能相同）\n\n")

# =====================================================
# 步骤5：使用说明
# =====================================================

cat("========================================\n")
cat("补丁安装完成！\n")
cat("========================================\n\n")

cat("✅ 现在可以使用 universe 参数了！\n\n")

cat("📝 使用方法：\n")
cat("--------------------------------\n")
cat("方法1: 使用全局函数（推荐）\n\n")
cat("  library(biofree.qyKEGGtools)\n")
cat("  result <- enrich_local_KEGG(\n")
cat("    gene = c('672', '7157', '7422'),\n")
cat("    species = 'hsa',\n")
cat("    pCutoff = 0.05,\n")
cat("    universe = bg_entrez  # ✨ 新功能\n")
cat("  )\n\n")

cat("方法2: 使用快捷函数\n\n")
cat("  result <- enrichKEGG_universe(\n")
cat("    gene = c('672', '7157', '7422'),\n")
cat("    species = 'hsa',\n")
cat("    pCutoff = 0.05,\n")
cat("    universe = bg_entrez  # ✨ 新功能\n")
cat("  )\n\n")

cat("方法3: 使用显式调用\n\n")
cat("  result <- enrich_local_KEGG_enhanced(\n")
cat("    gene = c('672', '7157', '7422'),\n")
cat("    species = 'hsa',\n")
cat("    pCutoff = 0.05,\n")
cat("    universe = bg_entrez  # ✨ 新功能\n")
cat("  )\n\n")

cat("⚠️ 重要提示：\n")
cat("--------------------------------\n")
cat("1. 此补丁仅在当前R会话中有效\n")
cat("2. 关闭R后需要重新运行此脚本\n")
cat("3. 如需永久使用，请在 ~/.Rprofile 中添加：\n\n")

cat(sprintf("   source('%s')\n\n", normalizePath("patch_biofree_qykeggtools.R")))

cat("4. 与项目集成：\n")
cat("   项目会自动检测并使用增强版函数\n")
cat("   modules/kegg_enrichment.R 已集成\n\n")

cat("========================================\n")

# 返回增强版函数（invisibly）
invisible(enrich_local_KEGG_enhanced)
