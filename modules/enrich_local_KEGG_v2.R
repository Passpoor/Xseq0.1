# =====================================================
# enrich_local_KEGG v2 - 完全对齐 clusterProfiler
# 添加 universe 参数支持
# =====================================================
# 作者：文献计量与基础医学
# 基于：clusterProfiler::enrichKEGG 的实现标准
# 创建：2026-01-02
# =====================================================

#' @title KEGG富集分析（支持universe参数）
#' @description 使用本地KEGG数据库进行富集分析，完全对齐clusterProfiler::enrichKEGG的universe参数实现
#' @param gene 差异基因的ENTREZID向量
#' @param species 物种代码（"hsa", "mmu", "rno"等）
#' @param pCutoff p值阈值（默认0.05）
#' @param pAdjustMethod 多重检验校正方法（"BH", "BY", "bonferroni", "holm", "hochberg", "hommel", "fdr", "none"）
#' @param universe 背景基因集的ENTREZID向量（必须包含所有gene）
#' @param minGSSize 最小通路大小（默认10）
#' @param maxGSSize 最大通路大小（默认500）
#' @param qCutoff q值（FDR）阈值（可选）
#' @param db_dir KEGG数据库目录（可选）
#' @return enrichResult对象
#' @export
#' @examples
#' # 不使用universe（使用全基因组）
#' result1 <- enrich_local_KEGG_v2(
#'   gene = c("672", "7157", "7422"),
#'   species = "hsa",
#'   pCutoff = 0.05
#' )
#'
#' # 使用universe（推荐）
#' result2 <- enrich_local_KEGG_v2(
#'   gene = c("672", "7157", "7422"),
#'   species = "hsa",
#'   pCutoff = 0.05,
#'   universe = bg_entrez  # 检测到的所有基因
#' )

enrich_local_KEGG_v2 <- function(
  gene,
  species,
  pCutoff = 0.05,
  pAdjustMethod = "BH",
  universe = NULL,
  minGSSize = 10,
  maxGSSize = 500,
  qCutoff = NULL,
  db_dir = NULL
) {

  # =====================================================
  # Step 1: 参数验证 - 完全对齐clusterProfiler
  # =====================================================

  # 1.1 验证gene参数
  if (missing(gene) || is.null(gene)) {
    stop("'gene' parameter is required")
  }

  if (!is.character(gene) || length(gene) == 0) {
    stop("'gene' must be a non-empty character vector")
  }

  # 去重和去除NA
  gene <- unique(gene[!is.na(gene)])
  gene <- gene[gene != ""]

  if (length(gene) == 0) {
    stop("No valid genes in 'gene' parameter")
  }

  K <- length(gene)  # 输入基因数

  # 1.2 验证species参数
  if (missing(species) || is.null(species)) {
    stop("'species' parameter is required")
  }

  if (!is.character(species) || length(species) != 1) {
    stop("'species' must be a single character value")
  }

  # 1.3 验证universe参数（对齐clusterProfiler的验证逻辑）
  if (!is.null(universe)) {
    # 类型检查
    if (!is.character(universe)) {
      stop("'universe' must be a character vector of ENTREZ IDs")
    }

    # 去重和去除NA
    universe <- unique(universe[!is.na(universe)])
    universe <- universe[universe != ""]

    if (length(universe) == 0) {
      stop("'universe' cannot be empty")
    }

    # ⭐ 关键验证：universe必须包含所有gene
    # 这是对齐clusterProfiler的重要检查
    if (!all(gene %in% universe)) {
      missing_genes <- gene[!gene %in% universe]
      stop(sprintf(
        "All genes in 'gene' must be in 'universe'. Missing genes: %s\n%s",
        paste(head(missing_genes, 5), collapse = ", "),
        "Please ensure 'universe' contains all genes in 'gene' parameter."
      ))
    }

    message(sprintf("Using custom universe: %d genes", length(universe)))
  }

  # 1.4 验证pCutoff
  # 注意：pCutoff = 1.0 表示获取所有结果（不过滤），是有效的
  if (!is.numeric(pCutoff) || length(pCutoff) != 1 || pCutoff <= 0 || pCutoff > 1) {
    stop("'pCutoff' must be a numeric value between 0 and 1 (inclusive)")
  }

  # 1.5 验证pAdjustMethod
  valid_methods <- c("holm", "hochberg", "hommel", "bonferroni",
                     "BH", "BY", "fdr", "none")
  if (!is.character(pAdjustMethod) || length(pAdjustMethod) != 1 ||
      !pAdjustMethod %in% valid_methods) {
    stop(sprintf(
      "'pAdjustMethod' must be one of: %s",
      paste(valid_methods, collapse = ", ")
    ))
  }

  # 1.6 验证minGSSize和maxGSSize
  if (!is.numeric(minGSSize) || minGSSize < 5) {
    stop("'minGSSize' must be >= 5")
  }

  if (!is.numeric(maxGSSize) || maxGSSize < minGSSize) {
    stop("'maxGSSize' must be >= 'minGSSize'")
  }

  # =====================================================
  # Step 2: 加载本地KEGG数据库
  # =====================================================

  if (is.null(db_dir)) {
    db_dir <- system.file("extdata", package = "biofree.qyKEGGtools")
  }

  if (db_dir == "" || !dir.exists(db_dir)) {
    stop("KEGG database not found. Please specify 'db_dir' parameter")
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

  # 验证数据库结构
  required_keys <- c("pathway2gene", "pathway_info", "all_genes")
  if (!all(required_keys %in% names(kegg_db))) {
    stop("Invalid KEGG database format")
  }

  # =====================================================
  # Step 3: 处理背景基因集（universe）- 核心逻辑
  # =====================================================

  # 获取KEGG数据库中所有基因
  kegg_all_genes <- kegg_db$all_genes

  if (is.null(universe)) {
    # 不使用universe：使用KEGG数据库中的所有基因作为背景
    background_genes <- kegg_all_genes
    message(sprintf("Using full KEGG genome as background: %d genes",
                    length(background_genes)))
  } else {
    # ✨ 使用自定义universe - 对齐clusterProfiler的处理方式

    # ⭐ 关键步骤1: 与KEGG数据库取交集
    # 原因：超几何检验只能考虑在KEGG中有注释的基因
    background_genes <- intersect(universe, kegg_all_genes)

    if (length(background_genes) == 0) {
      stop(
        "None of the universe genes found in KEGG database.\n",
        "Please check if ENTREZ IDs are correct or if species is supported."
      )
    }

    # ⭐ 关键步骤2: 验证gene是否在background_genes中
    if (!all(gene %in% background_genes)) {
      missing_in_kegg <- gene[!gene %in% background_genes]
      warning(
        sprintf(
          "Some genes not in KEGG database and will be removed: %s",
          paste(head(missing_in_kegg, 5), collapse = ", ")
        ),
        call. = FALSE
      )
      gene <- gene[gene %in% background_genes]
      K <- length(gene)

      if (K == 0) {
        stop("No valid genes after KEGG database filtering")
      }
    }

    # ⭐ 关键步骤3: 检查过滤比例（警告用户）
    if (length(background_genes) < length(universe) * 0.5) {
      warning(
        sprintf(
          "Only %d out of %d universe genes found in KEGG database (%.1f%%).\n%s",
          length(background_genes),
          length(universe),
          100 * length(background_genes) / length(universe),
          "This may affect enrichment results."
        ),
        call. = FALSE
      )
    }

    message(sprintf(
      "Using custom universe: %d genes (from %d input, %d in KEGG)",
      length(background_genes),
      length(universe),
      length(background_genes)
    ))
  }

  M <- length(background_genes)  # ⭐ 背景基因总数（在超几何检验中使用）

  # =====================================================
  # Step 4: 获取KEGG通路
  # =====================================================

  pathways <- kegg_db$pathway2gene

  if (length(pathways) == 0) {
    stop("No pathways found in KEGG database")
  }

  # =====================================================
  # Step 5: 对每个通路进行超几何检验 - 核心统计算法
  # =====================================================

  results_list <- list()

  for (pathway_id in names(pathways)) {
    pathway_genes <- pathways[[pathway_id]]
    n <- length(pathway_genes)  # 通路中基因数

    # 过滤通路大小
    if (n < minGSSize || n > maxGSSize) {
      next
    }

    # 计算重叠
    overlap <- intersect(gene, pathway_genes)
    k <- length(overlap)  # 重叠基因数

    if (k == 0) {
      next
    }

    # ⭐ 超几何分布检验 - 对齐clusterProfiler的公式
    # P(X >= k) = phyper(k-1, n, M-n, K, lower.tail = FALSE)
    # 参数说明：
    #   k: 成功次数阈值（重叠基因数-1）
    #   n: 通路中成功数（通路基因数）
    #   M-n: 背景中失败数（背景基因数-通路基因数）
    #   K: 样本中成功数（输入基因数）
    pvalue <- phyper(k - 1, n, M - n, K, lower.tail = FALSE)

    # 保存结果
    results_list[[pathway_id]] <- list(
      ID = pathway_id,
      Description = as.character(kegg_db$pathway_info[pathway_id, "name"]),
      pvalue = pvalue,
      GeneRatio = sprintf("%d/%d", k, K),
      BgRatio = sprintf("%d/%d", n, M),  # ⭐ 反映了universe的使用
      geneID = paste(overlap, collapse = "/"),
      Count = k
    )
  }

  # =====================================================
  # Step 6: 多重假设检验校正
  # =====================================================

  if (length(results_list) == 0) {
    warning("No enrichment found in any pathway", call. = FALSE)
    return(new("enrichResult",
               result = data.frame(),
               pAdjustMethod = pAdjustMethod,
               organism = species,
               ontology = "KEGG"))
  }

  # 提取所有p值
  pvalues <- sapply(results_list, function(x) x$pvalue)

  # 多重检验校正（支持多种方法）
  padj <- p.adjust(pvalues, method = pAdjustMethod)

  # 添加校正后的p值
  for (i in seq_along(results_list)) {
    results_list[[i]]$p.adjust <- padj[i]
    results_list[[i]]$qvalue <- padj[i]
  }

  # =====================================================
  # Step 7: 过滤显著通路
  # =====================================================

  significant_results <- Filter(function(x) {
    x$pvalue <= pCutoff && (is.null(qCutoff) || x$p.adjust <= qCutoff)
  }, results_list)

  if (length(significant_results) == 0) {
    warning(
      sprintf("No significant pathways found (pCutoff=%.2f)", pCutoff),
      call. = FALSE
    )
    return(new("enrichResult",
               result = data.frame(),
               pAdjustMethod = pAdjustMethod,
               organism = species,
               ontology = "KEGG"))
  }

  # =====================================================
  # Step 8: 组装结果数据框
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

  # 按p.adjust排序
  result_df <- result_df[order(result_df$p.adjust), ]

  # =====================================================
  # Step 9: 创建并返回enrichResult对象
  # =====================================================

  enrich_obj <- new("enrichResult",
                    result = result_df,
                    pAdjustMethod = pAdjustMethod,
                    pvalueCutoff = pCutoff,
                    qvalueCutoff = qCutoff,
                    organism = species,
                    ontology = "KEGG",
                    gene = as.character(gene),
                    universe = background_genes)  # ⭐ 保存universe

  return(enrich_obj)
}


# =====================================================
# 辅助函数：打印enrichResult对象
# =====================================================

print_enrichResult <- function(x, showCategory = 10, ...) {
  result_df <- x@result

  if (nrow(result_df) == 0) {
    cat("No enrichment results.\n")
    return(invisible(x))
  }

  cat(sprintf("Enrichment Analysis (KEGG, %s)\n", x@organism))
  cat(sprintf("%d enriched terms found, showing top %d\n\n",
              nrow(result_df),
              min(showCategory, nrow(result_df))))

  print(head(result_df, showCategory), ...)

  return(invisible(x))
}

# =====================================================
# 示例代码
# =====================================================

if (FALSE) {
  # 示例1: 不使用universe（使用全基因组）
  result1 <- enrich_local_KEGG_v2(
    gene = c("672", "7157", "7422", "5295", "7158"),
    species = "hsa",
    pCutoff = 0.05
  )

  print(result1)

  # 示例2: 使用universe（推荐）✨
  library(org.Hs.eg.db)

  # 模拟差异分析结果
  deg_symbols <- c("TP53", "EGFR", "MYC", "BRCA1", "PTEN")
  all_detected <- c("TP53", "EGFR", "MYC", "BRCA1", "PTEN",
                    "AKT1", "MTOR", "RB1", "KRAS", "NRAS")

  # 转换为ENTREZID
  deg_entrez <- bitr(deg_symbols, fromType = "SYMBOL",
                     toType = "ENTREZID", OrgDb = org.Hs.eg.db)$ENTREZID
  bg_entrez <- bitr(all_detected, fromType = "SYMBOL",
                    toType = "ENTREZID", OrgDb = org.Hs.eg.db)$ENTREZID

  # KEGG分析（使用自定义背景）
  result2 <- enrich_local_KEGG_v2(
    gene = deg_entrez,
    species = "hsa",
    pCutoff = 0.05,
    universe = bg_entrez  # ✨ 使用检测到的基因作为背景
  )

  print(result2)

  # 验证universe是否被使用
  cat(sprintf("\n背景基因数: %d\n", length(result2@universe)))
  cat(sprintf("输入基因数: %d\n", length(result2@gene)))

  # 对比BgRatio
  cat("\nBgRatio对比:\n")
  cat("无universe:", result1@result$BgRatio[1], "\n")
  cat("有universe:", result2@result$BgRatio[1], "\n")
}
