# =====================================================
# enrich_local_KEGG with universe parameter - 实现代码模板
# =====================================================
# 功能：为 biofree.qyKEGGtools::enrich_local_KEGG 添加 universe 参数支持
# 目标：完全对齐 clusterProfiler::enrichKEGG 的实现
#
# 作者：Biofree Project Team
# 日期：2026-01-02
# 版本：1.0
# =====================================================

# =====================================================
# 函数 1: 主函数 - enrich_local_KEGG_v2
# =====================================================

enrich_local_KEGG_v2 <- function(
  gene,
  species,
  pCutoff = 0.05,
  qCutoff = NULL,
  universe = NULL,           # ✨ 新增：背景基因集
  pAdjustMethod = "BH",      # ✨ 新增：多重检验校正方法
  minGSSize = 10,            # ✨ 新增：最小通路大小
  maxGSSize = 500,           # ✨ 新增：最大通路大小
  db_dir = NULL
) {

  # =====================================================
  # 第1步：输入验证
  # =====================================================

  # 验证 gene 参数
  if (!is.character(gene)) {
    gene <- as.character(gene)
  }

  gene <- unique(gene)
  gene <- gene[!is.na(gene) & gene != ""]

  if (length(gene) < 2) {
    stop("At least 2 genes are required for enrichment analysis")
  }

  K <- length(gene)

  # =====================================================
  # 第2步：加载 KEGG 数据库
  # =====================================================

  if (is.null(db_dir)) {
    db_dir <- system.file("extdata", package = "biofree.qyKEGGtools")
  }

  species_db_file <- file.path(db_dir, species, "kegg_annot.rds")

  if (!file.exists(species_db_file)) {
    stop(sprintf("KEGG database not found for species: %s\n%s",
                 species,
                 "Please ensure the species is supported."))
  }

  kegg_db <- readRDS(species_db_file)

  # =====================================================
  # 第3步：✨ 处理 universe 参数（核心）
  # =====================================================

  if (is.null(universe)) {
    # 未提供 universe，使用全基因组
    background_genes <- kegg_db$all_genes
    message(sprintf("Using full genome as background (%d genes)",
                    length(background_genes)))
  } else {
    # ✨ 使用自定义 universe

    # 验证 universe 格式
    if (!is.character(universe)) {
      universe <- as.character(universe)
    }

    universe <- unique(universe)
    universe <- universe[!is.na(universe) & universe != ""]

    if (length(universe) == 0) {
      stop("universe cannot be empty")
    }

    # ✨ 验证 universe 包含所有 gene
    genes_not_in_universe <- gene[!gene %in% universe]

    if (length(genes_not_in_universe) > 0) {
      warning(sprintf(
        "Removing %d genes not in universe: %s",
        length(genes_not_in_universe),
        paste(head(genes_not_in_universe, 5), collapse = ", ")
      ))

      gene <- gene[gene %in% universe]
      K <<- length(gene)  # 更新 K
    }

    # ✨ 与 KEGG 数据库取交集
    background_genes <- intersect(universe, kegg_db$all_genes)

    if (length(background_genes) == 0) {
      stop("None of the universe genes found in KEGG database.\n",
           "Please check if ENTREZ IDs are correct.")
    }

    # 警告：如果过滤掉的基因太多
    if (length(background_genes) < length(universe) * 0.5) {
      warning(sprintf(
        "Only %d out of %d universe genes found in KEGG database (%.1f%%). ",
        "This may affect results. ",
        length(background_genes),
        length(universe),
        100 * length(background_genes) / length(universe)
      ))
    }

    message(sprintf("Using custom universe: %d genes (from %d input, %d in KEGG)",
                    length(background_genes),
                    length(universe),
                    length(kegg_db$all_genes)))
  }

  M <- length(background_genes)  # ✨ 背景基因总数

  # =====================================================
  # 第4步：获取通路数据
  # =====================================================

  pathways <- kegg_db$pathway2gene

  if (length(pathways) == 0) {
    stop("No pathways found in KEGG database")
  }

  # =====================================================
  # 第5步：对每个通路进行超几何检验
  # =====================================================

  results_list <- list()

  for (pathway_id in names(pathways)) {
    pathway_genes <- pathways[[pathway_id]]
    n <- length(pathway_genes)  # 通路中基因数

    # ✨ 过滤通路大小
    if (n < minGSSize || n > maxGSSize) {
      next
    }

    # 计算重叠
    overlap <- intersect(gene, pathway_genes)
    k <- length(overlap)  # 重叠基因数

    if (k == 0) {
      next
    }

    # =====================================================
    # 超几何检验
    # =====================================================

    # P(X >= k) = 1 - phyper(k-1, n, M-n, K)
    pvalue <- phyper(k - 1, n, M - n, K, lower.tail = FALSE)

    # 保存结果
    results_list[[pathway_id]] <- list(
      ID = pathway_id,
      Description = kegg_db$pathway_info[pathway_id, "name"],
      pvalue = pvalue,
      GeneRatio = paste(k, K, sep = "/"),
      BgRatio = paste(n, M, sep = "/"),  # ✨ 使用自定义 universe
      geneID = paste(overlap, collapse = "/"),
      Count = k
    )
  }

  # =====================================================
  # 第6步：多重检验校正 ✨ 支持自定义方法
  # =====================================================

  if (length(results_list) > 0) {
    pvalues <- sapply(results_list, function(x) x$pvalue)

    # ✨ 支持多种校正方法
    padj <- p.adjust(pvalues, method = pAdjustMethod)

    # 添加到结果中
    for (i in seq_along(results_list)) {
      results_list[[i]]$p.adjust <- padj[i]
      results_list[[i]]$qvalue <- padj[i]
    }
  }

  # =====================================================
  # 第7步：过滤显著通路
  # =====================================================

  significant_results <- Filter(function(x) {
    x$pvalue <= pCutoff && (is.null(qCutoff) || x$p.adjust <= qCutoff)
  }, results_list)

  if (length(significant_results) == 0) {
    warning("No significant pathways found")
    return(new("enrichResult", result = data.frame(),
               pAdjustMethod = pAdjustMethod,
               organism = species, ontology = "KEGG"))
  }

  # =====================================================
  # 第8步：组装结果数据框
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

  # 按 p.adjust 排序
  result_df <- result_df[order(result_df$p.adjust), ]

  # =====================================================
  # 第9步：创建 enrichResult 对象
  # =====================================================

  enrich_obj <- new("enrichResult",
                    result = result_df,
                    pAdjustMethod = pAdjustMethod,
                    pvalueCutoff = pCutoff,
                    qvalueCutoff = qCutoff,
                    organism = species,
                    ontology = "KEGG",
                    gene = as.character(gene),
                    universe = background_genes)  # ✨ 保存 universe

  return(enrich_obj)
}


# =====================================================
# 函数 2: 包装函数 - enrich_local_KEGG_enhanced
# =====================================================
# 用途：如果原始 enrich_local_KEGG 不支持 universe，
#       使用此函数作为临时解决方案

enrich_local_KEGG_enhanced <- function(
  gene,
  species,
  pCutoff = 0.05,
  qCutoff = NULL,
  universe = NULL,
  pAdjustMethod = "BH",
  minGSSize = 10,
  maxGSSize = 500
) {

  # 检查是否需要自定义处理
  need_custom <- !is.null(universe) ||
                 pAdjustMethod != "BH" ||
                 minGSSize != 10 ||
                 maxGSSize != 500

  if (!need_custom) {
    # 使用原始函数
    return(biofree.qyKEGGtools::enrich_local_KEGG(
      gene = gene,
      species = species,
      pCutoff = pCutoff,
      qCutoff = qCutoff
    ))
  }

  # 如果有 universe 或其他自定义参数，
  # 使用 clusterProfiler 作为备用方案
  if (!require("clusterProfiler", quietly = TRUE)) {
    stop("clusterProfiler package required for custom parameters.\n",
         "Please install: BiocManager::install('clusterProfiler')")
  }

  # 映射物种代码
  org_mapping <- c(
    "hsa" = "hsa",
    "mmu" = "mmu",
    "rno" = "rno"
  )

  if (!(species %in% names(org_mapping))) {
    stop(sprintf("Species '%s' not supported", species))
  }

  message("Using clusterProfiler::enrichKEGG for custom parameters")

  result <- tryCatch({
    clusterProfiler::enrichKEGG(
      gene = gene,
      organism = org_mapping[species],
      pvalueCutoff = pCutoff,
      qvalueCutoff = qCutoff,
      pAdjustMethod = pAdjustMethod,
      minGSSize = minGSSize,
      maxGSSize = maxGSSize,
      universe = universe  # ✅ 使用 universe
    )
  }, error = function(e) {
    stop("clusterProfiler::enrichKEGG failed: ", e$message)
  })

  return(result)
}


# =====================================================
# 函数 3: 智能选择函数 - kegg_enrichment_auto
# =====================================================
# 用途：自动选择最佳的 KEGG 富集分析方法

kegg_enrichment_auto <- function(
  gene,
  species = "hsa",
  pCutoff = 0.05,
  universe = NULL,
  prefer_offline = FALSE,
  verbose = TRUE
) {

  result <- NULL
  method_used <- NULL

  # =====================================================
  # 策略1: 如果需要离线，优先使用 biofree.qyKEGGtools
  # =====================================================

  if (prefer_offline && require("biofree.qyKEGGtools", quietly = TRUE)) {
    if (verbose) message("尝试使用 biofree.qyKEGGtools（离线模式）...")

    result <- tryCatch({
      biofree.qyKEGGtools::enrich_local_KEGG(
        gene = gene,
        species = species,
        pCutoff = pCutoff
      )
    }, error = function(e) {
      if (verbose) message("biofree.qyKEGGtools 失败: ", e$message)
      NULL
    })

    if (!is.null(result)) {
      method_used <- "biofree.qyKEGGtools"

      if (!is.null(universe) && verbose) {
        warning("biofree.qyKEGGtools 不支持 universe 参数，使用全基因组背景")
      }
    }
  }

  # =====================================================
  # 策略2: 如果有 universe 参数或上一步失败，使用 clusterProfiler
  # =====================================================

  if (is.null(result) && require("clusterProfiler", quietly = TRUE)) {
    if (verbose) message("使用 clusterProfiler...")

    result <- tryCatch({
      if (!is.null(universe) && verbose) {
        message("  使用自定义背景基因集 (", length(universe), " genes)")
      } else {
        message("  使用全基因组背景")
      }

      clusterProfiler::enrichKEGG(
        gene = gene,
        organism = species,
        pvalueCutoff = pCutoff,
        universe = universe
      )
    }, error = function(e) {
      if (verbose) message("clusterProfiler 失败: ", e$message)
      NULL
    })

    if (!is.null(result)) {
      method_used <- "clusterProfiler"
    }
  }

  # =====================================================
  # 返回结果
  # =====================================================

  if (is.null(result)) {
    stop("KEGG 富集分析失败：所有方法都失败了")
  }

  if (verbose) message("✅ KEGG 分析完成，使用方法: ", method_used)

  attr(result, "method") <- method_used

  return(result)
}


# =====================================================
# 使用示例
# =====================================================

# 示例1：基本使用（不使用 universe）
result1 <- enrich_local_KEGG_v2(
  gene = c("672", "7157", "7422", "5295"),
  species = "hsa",
  pCutoff = 0.05
)

# 示例2：使用 universe（推荐）
library(org.Hs.eg.db)

# 假设从 RNA-seq 获得差异基因和背景基因
deg_symbols <- c("TP53", "EGFR", "MYC", "BRCA1", "PTEN")
background_symbols <- c("TP53", "EGFR", "MYC", "BRCA1", "PTEN",
                        "KRAS", "CDKN1A", "ESR1", "ERBB2", "AKT1",
                        # ... 更多基因
                        "APOE", "INS", "GAPDH", "ACTB", "TGFB1")

# 转换为 ENTREZID
library(clusterProfiler)
deg_entrez <- bitr(deg_symbols, fromType = "SYMBOL",
                   toType = "ENTREZID", OrgDb = org.Hs.eg.db)$ENTREZID
bg_entrez <- bitr(background_symbols, fromType = "SYMBOL",
                  toType = "ENTREZID", OrgDb = org.Hs.eg.db)$ENTREZID

# 使用自定义 universe
result2 <- enrich_local_KEGG_v2(
  gene = deg_entrez,
  species = "hsa",
  pCutoff = 0.05,
  universe = bg_entrez  # ✨ 使用自定义背景
)

# 验证 universe 是否被使用
cat(sprintf("背景基因数: %d\n", length(result2@universe)))
cat(sprintf("输入基因数: %d\n", length(result2@gene)))
cat(sprintf("通路数: %d\n", nrow(result2@result)))

# 查看结果
head(result2@result)

# 可视化
dotplot(result2, showCategory = 20)

# 示例3：使用所有新参数
result3 <- enrich_local_KEGG_v2(
  gene = deg_entrez,
  species = "hsa",
  pCutoff = 0.05,
  universe = bg_entrez,
  pAdjustMethod = "BY",      # ✨ 使用不同的校正方法
  minGSSize = 15,            # ✨ 最小通路大小
  maxGSSize = 300            # ✨ 最大通路大小
)

# 示例4：使用智能选择函数
result4 <- kegg_enrichment_auto(
  gene = deg_entrez,
  species = "hsa",
  pCutoff = 0.05,
  universe = bg_entrez,
  prefer_offline = FALSE  # 优先使用在线方法（支持 universe）
)

# 查看使用的方法
attr(result4, "method")


# =====================================================
# 对比测试：enrich_local_KEGG_v2 vs clusterProfiler
# =====================================================

# 使用相同的基因和背景
result_v2 <- enrich_local_KEGG_v2(
  gene = deg_entrez,
  species = "hsa",
  universe = bg_entrez,
  pCutoff = 0.05
)

result_cp <- clusterProfiler::enrichKEGG(
  gene = deg_entrez,
  organism = "hsa",
  universe = bg_entrez,
  pvalueCutoff = 0.05
)

# 对比 BgRatio（应该相同或非常接近）
if (nrow(result_v2@result) > 0 && nrow(result_cp@result) > 0) {
  bg_v2 <- strsplit(result_v2@result$BgRatio[1], "/")[[1]]
  bg_cp <- strsplit(result_cp@result$BgRatio[1], "/")[[1]]

  cat(sprintf("enrich_local_KEGG_v2 BgRatio: %s\n", result_v2@result$BgRatio[1]))
  cat(sprintf("clusterProfiler BgRatio: %s\n", result_cp@result$BgRatio[1]))
  cat(sprintf("背景基因数: %d vs %d\n",
              as.numeric(bg_v2[2]),
              as.numeric(bg_cp[2])))
}


# =====================================================
# 导出函数
# =====================================================

# 如果需要，可以将这些函数导出到命名空间
# export(enrich_local_KEGG_v2)
# export(enrich_local_KEGG_enhanced)
# export(kegg_enrichment_auto)
