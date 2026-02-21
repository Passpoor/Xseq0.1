# ============================================================================
# 多文件Universe富集分析工具
# ============================================================================
# 用途：对多个数据集的交集基因进行KEGG/GO富集分析
# 核心特性：自动从多个文件中提取Universe（交集）
# ============================================================================

# 所需包
required_packages <- c("clusterProfiler", "org.Mm.eg.db", "scales")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("请安装包: install.packages('", pkg, "')")
  }
}

library(clusterProfiler)
library(scales)

# ============================================================================
# 函数1: 多文件交集KEGG富集分析
# ============================================================================

#' 多数据集交集的KEGG富集分析
#'
#' @param datasets 数据集列表，每个元素包含：
#'   - df: 数据框
#'   - gene_col: 基因列名
#'   - fc_col: log2FC列名（可选）
#'   - pval_col: p值列名（可选）
#' @param fc_thresholds 每个数据集的log2FC阈值（向量）
#' @param pval_thresholds 每个数据集的p值阈值（向量）
#' @param organism 物种（"mmu"或"hsa"）
#' @param min_gssize 最小基因集大小
#' @param max_gssize 最大基因集大小
#' @return 富集分析结果
#' @export
enrich_multi_file_kegg <- function(
    datasets,
    fc_thresholds = NULL,
    pval_thresholds = NULL,
    organism = "mmu",
    min_gssize = 5,
    max_gssize = 500
) {

  message("\n")
  message(rep("=", 70), collapse = "")
  message("  多数据集交集KEGG富集分析")
  message(rep("=", 70), collapse = "")
  message("\n")

  # ----------------------------------------------------
  # Step 1: 提取每个数据集的Target基因
  # ----------------------------------------------------
  message("【步骤1/5】提取每个数据集的Target基因...\n")

  target_gene_lists <- list()

  for (i in seq_along(datasets)) {
    d <- datasets[[i]]
    df <- d$df
    gene_col <- d$gene_col

    message(sprintf("  数据集 %d:", i))
    message(sprintf("    文件/名称: %s", d$name %or% "未命名"))

    # 如果提供了阈值，筛选基因
    if (!is.null(fc_thresholds) && !is.null(d$fc_col)) {
      fc_thresh <- fc_thresholds[i]
      fc_col <- d$fc_col
      pval_thresh <- if (!is.null(pval_thresholds)) pval_thresholds[i] else NULL
      pval_col <- if (!is.null(d$pval_col)) d$pval_col else NULL

      # 构建筛选条件
      filter_mask <- df[[fc_col]] > fc_thresh

      if (!is.null(pval_col) && !is.null(pval_thresh)) {
        filter_mask <- filter_mask & (df[[pval_col]] < pval_thresh)
      }

      target_genes <- df[[gene_col]][filter_mask]

      message(sprintf("    筛选条件: log2FC > %.2f", fc_thresh))
      if (!is.null(pval_thresh)) {
        message(sprintf("              padj < %.3f", pval_thresh))
      }
      message(sprintf("    Target基因数: %d", length(target_genes)))

    } else {
      # 如果没有提供阈值，使用所有基因
      target_genes <- df[[gene_col]]
      message(sprintf("    所有基因数: %d（未应用阈值）", length(target_genes)))
    }

    # 移除NA
    target_genes <- target_genes[!is.na(target_genes)]
    target_gene_lists[[i]] <- target_genes

    message(sprintf("    去除NA后: %d\n", length(target_genes)))
  }

  # ----------------------------------------------------
  # Step 2: 计算Target交集
  # ----------------------------------------------------
  message("\n【步骤2/5】计算Target交集...\n")

  target_intersect <- Reduce(intersect, target_gene_lists)

  message(sprintf("  各数据集Target基因数:"))
  for (i in seq_along(target_gene_lists)) {
    message(sprintf("    数据集 %d: %,d", i, length(target_gene_lists[[i]])))
  }

  message(sprintf("\n  Target交集基因数: %,d", length(target_intersect)))

  if (length(target_intersect) < 3) {
    stop("❌ Target交集基因太少（< 3），无法进行富集分析")
  }

  # ----------------------------------------------------
  # Step 3: 计算Universe（所有数据集的基因交集）
  # ----------------------------------------------------
  message("\n【步骤3/5】计算Universe（所有数据集基因的交集）...\n")

  # 从每个数据集提取所有基因（不管显著不显著）
  all_genes_lists <- list()

  for (i in seq_along(datasets)) {
    d <- datasets[[i]]
    df <- d$df
    gene_col <- d$gene_col

    all_genes <- unique(df[[gene_col]])
    all_genes <- all_genes[!is.na(all_genes)]

    all_genes_lists[[i]] <- all_genes

    message(sprintf("  数据集 %d: %,d 个基因", i, length(all_genes)))
  }

  # 计算Universe = 所有数据集基因的交集
  universe <- Reduce(intersect, all_genes_lists)

  message(sprintf("\n  Universe (所有数据集基因交集): %,d", length(universe)))

  # 计算Target占比
  target_ratio <- length(target_intersect) / length(universe)
  message(sprintf("  Target占Universe比例: %s\n", percent(target_ratio)))

  # ----------------------------------------------------
  # Step 4: 验证Target ⊆ Universe
  # ----------------------------------------------------
  message("\n【步骤4/5】验证逻辑一致性...\n")

  genes_not_in_universe <- target_intersect[!target_intersect %in% universe]

  if (length(genes_not_in_universe) > 0) {
    warning("⚠️  有 ", length(genes_not_in_universe),
           " 个Target基因不在Universe中")
    message("  这些基因将被移除")
    target_intersect <- intersect(target_intersect, universe)
  } else {
    message("  ✅ 所有Target基因都在Universe中")
  }

  # 质量控制检查
  issues <- quality_check_universe(target_intersect, universe, organism)

  if (length(issues) > 0) {
    message("\n  发现以下问题:")
    for (issue in issues) {
      message("    ", issue)
    }
  }

  # ----------------------------------------------------
  # Step 5: 执行KEGG富集分析
  # ----------------------------------------------------
  message("\n【步骤5/5】执行KEGG富集分析...\n")

  kegg_result <- tryCatch({
    enrichKEGG(
      gene = target_intersect,
      universe = universe,
      organism = organism,
      pvalueCutoff = 0.05,
      qvalueCutoff = 0.2,
      minGSSize = min_gssize,
      maxGSSize = max_gssize,
      pAdjustMethod = "BH"
    )
  }, error = function(e) {
    message("  ❌ KEGG富集分析失败: ", e$message)
    message("  💡 可能原因:")
    message("    1. 基因ID类型错误（需要Entrez ID）")
    message("    2. 网络连接问题")
    message("    3. Target基因太少")
    stop(e)
  })

  # ----------------------------------------------------
  # Step 6: 返回结果
  # ----------------------------------------------------
  message("\n✅ 分析完成!")

  n_significant <- sum(kegg_result$p.adjust < 0.05, na.rm = TRUE)
  message(sprintf("  显著富集通路数（p.adjust < 0.05）: %d", n_significant))

  if (n_significant > 0) {
    message("\n  Top 5 富集通路:")
    top_paths <- head(kegg_result[kegg_result$p.adjust < 0.05, ], 5)
    for (i in 1:nrow(top_paths)) {
      message(sprintf("    %d. %s", i, top_paths$Description[i]))
    }
  }

  message("\n", rep("=", 70), collapse = "")

  # 返回完整结果
  result <- list(
    kegg = kegg_result,
    target_genes = target_intersect,
    universe = universe,
    target_from_each_dataset = target_gene_lists,
    all_genes_from_each_dataset = all_genes_lists,
    metadata = list(
      n_datasets = length(datasets),
      target_size = length(target_intersect),
      universe_size = length(universe),
      universe_strategy = "multi_file_intersection",
      organism = organism,
      n_significant_pathways = n_significant
    )
  )

  class(result) <- c("multi_file_enrichment_result", class(result))

  return(result)
}


# ============================================================================
# 函数2: 质量控制检查
# ============================================================================

#' 多文件Universe质量控制检查
#'
#' @param target_genes 目标基因集
#' @param universe 背景基因集
#' @param organism 物种
#' @return 问题列表
#' @export
quality_check_universe <- function(target_genes, universe, organism = "mmu") {

  issues <- character(0)

  # 检查1: Target在Universe中
  genes_not_in_universe <- target_genes[!target_genes %in% universe]

  if (length(genes_not_in_universe) > 0) {
    issues <- c(issues,
                sprintf("❌ 有 %d 个Target基因不在Universe中",
                       length(genes_not_in_universe)))
  }

  # 检查2: Universe大小
  if (length(universe) < 100) {
    issues <- c(issues,
                sprintf("❌ Universe太小（%d < 100）", length(universe)))
  }

  # 检查3: Target占比
  ratio <- length(target_genes) / length(universe)

  if (ratio > 0.5) {
    issues <- c(issues,
                sprintf("⚠️  Target占比过高（%.1f%% > 50%%）", ratio * 100))
  }

  if (ratio < 0.001) {
    issues <- c(issues,
                sprintf("⚠️  Target占比过低（%.3f%% < 0.1%%）", ratio * 100))
  }

  return(issues)
}


# ============================================================================
# 使用示例
# ============================================================================

# 示例1: 两个数据集的交集分析（A上调 ∩ B下调）
# ------------------------------------------------
# dataset1 <- read.csv("dataset_A_drug_vs_control.csv")
# dataset2 <- read.csv("dataset_B_disease_vs_normal.csv")
#
# # 准备数据集列表
# datasets <- list(
#   list(
#     name = "药物处理 vs 对照",
#     df = dataset1,
#     gene_col = "gene",          # 自动检测或用户选择
#     fc_col = "log2FoldChange",
#     pval_col = "padj"
#   ),
#   list(
#     name = "疾病 vs 正常",
#     df = dataset2,
#     gene_col = "Gene",           # 不同的列名
#     fc_col = "LogFC",
#     pval_col = "FDR"
#   )
# )
#
# # 设置阈值
# fc_thresholds <- c(1, -1)      # 数据集1: log2FC > 1（上调）
#                             # 数据集2: log2FC < -1（下调）
# pval_thresholds <- c(0.05, 0.05)
#
# # 运行分析
# result <- enrich_multi_file_kegg(
#   datasets = datasets,
#   fc_thresholds = fc_thresholds,
#   pval_thresholds = pval_thresholds,
#   organism = "mmu"
# )
#
# # 查看结果
# head(result$kegg)
# print(result$metadata)

# 示例2: 三个数据集的交集（不设阈值）
# ------------------------------------------------
# datasets <- list(
#   list(df = dataset1, gene_col = "gene"),
#   list(df = dataset2, gene_col = "Gene"),
#   list(df = dataset3, gene_col = "gene_symbol")
# )
#
# result <- enrich_multi_file_kegg(
#   datasets = datasets,
#   organism = "mmu"
# )

# 示例3: 在Shiny应用中使用
# ------------------------------------------------
# observeEvent(input$run_kegg, {
#   # 假设已经通过multi_file_universe_server获得了数据集信息
#   multi_file_result <- multi_file_universe_data()
#
#   datasets <- multi_file_result$datasets
#   universe <- multi_file_result$universe
#
#   # 从UI获取每个数据集的阈值
#   fc_thresholds <- sapply(datasets, function(d) {
#     input[[sprintf("fc_threshold_%d", d$index)]]
#   })
#
#   pval_thresholds <- sapply(datasets, function(d) {
#     input[[sprintf("pval_threshold_%d", d$index)]]
#   })
#
#   # 执行富集分析
#   result <- enrich_multi_file_kegg(
#     datasets = datasets,
#     fc_thresholds = fc_thresholds,
#     pval_thresholds = pval_thresholds,
#     organism = "mmu"
#   )
#
#   # 显示结果...
# })


print("✅ 多文件Universe富集分析工具加载完成！")
print("📖 查看文档末尾的使用示例")
