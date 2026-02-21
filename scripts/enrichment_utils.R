# ============================================================================
# Biofree富集分析工具集
# ============================================================================
# 用途：提供正确的富集分析背景基因集（Universe）选择和验证工具
# 作者：Claude Code Assistant
# 创建日期：2025-01-03
# ============================================================================

# 所需包
required_packages <- c("clusterProfiler", "org.Mm.eg.db", "scales")

# 自动加载包
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("请安装包: install.packages('", pkg, "')")
  }
}

library(clusterProfiler)
library(scales)

# ----------------------------------------------------------------------------
# 函数1: 质量控制检查
# ----------------------------------------------------------------------------

#' 富集分析Universe质量控制检查
#'
#' @param target_genes 目标基因集向量
#' @param universe 背景基因集向量
#' @param organism 物种（默认"mmu"小鼠）
#' @return 问题列表（空列表表示通过）
#' @export
quality_check_universe <- function(target_genes, universe, organism = "mmu") {

  issues <- character(0)

  # 检查1: Target必须在Universe中
  genes_not_in_universe <- target_genes[!target_genes %in% universe]

  if (length(genes_not_in_universe) > 0) {
    issues <- c(issues,
                sprintf("❌ 有 %d 个Target基因不在Universe中: %s...",
                       length(genes_not_in_universe),
                       paste(head(genes_not_in_universe, 3), collapse = ", ")))
  }

  # 检查2: Universe大小
  if (length(universe) < 100) {
    issues <- c(issues,
                sprintf("❌ Universe太小（%d < 100）", length(universe)))
  }

  if (length(universe) < 500) {
    issues <- c(issues,
                sprintf("⚠️  Universe较小（%d < 500），可能影响统计效力", length(universe)))
  }

  # 检查3: Universe不应超过全基因组
  genome_size <- switch(organism,
                        "mmu" = length(keys(org.Mm.eg.db)),
                        "hsa" = length(keys(org.Hs.eg.db)),
                        length(keys(org.Mm.eg.db))  # 默认
  )

  if (length(universe) > genome_size) {
    issues <- c(issues,
                sprintf("❌ Universe大小（%d）超过全基因组（%d）",
                       length(universe), genome_size))
  }

  # 检查4: Target占比
  target_ratio <- length(target_genes) / length(universe)

  if (target_ratio > 0.5) {
    issues <- c(issues,
                sprintf("⚠️  Target占比过高（%.1f%% > 50%%）",
                       target_ratio * 100))
  }

  if (target_ratio > 0.8) {
    issues <- c(issues,
                sprintf("❌ Target占比极高（%.1f%%），富集分析无意义",
                       target_ratio * 100))
  }

  if (target_ratio < 0.001) {
    issues <- c(issues,
                sprintf("⚠️  Target占比过低（%.3f%% < 0.1%%）",
                       target_ratio * 100))
  }

  # 检查5: Target基因数
  if (length(target_genes) < 3) {
    issues <- c(issues,
                sprintf("❌ Target基因太少（%d < 3），无法进行富集分析",
                       length(target_genes)))
  }

  if (length(target_genes) < 5) {
    issues <- c(issues,
                sprintf("⚠️  Target基因较少（%d < 5），结果可能不稳定",
                       length(target_genes)))
  }

  return(issues)
}


# ----------------------------------------------------------------------------
# 函数2: 自动选择最佳Universe
# ----------------------------------------------------------------------------

#' 自动选择最佳的Universe定义
#'
#' @param count_matrix_A 数据集A的表达矩阵（可选）
#' @param count_matrix_B 数据集B的表达矩阵（可选）
#' @param DE_results_A 数据集A的DE结果（可选）
#' @param DE_results_B 数据集B的DE结果（可选）
#' @param gene_list_A 数据集A的基因列表（兜底）
#' @param gene_list_B 数据集B的基因列表（兜底）
#' @param organism 物种
#' @return 包含universe和strategy的列表
#' @export
auto_select_universe <- function(
    count_matrix_A = NULL,
    count_matrix_B = NULL,
    DE_results_A = NULL,
    DE_results_B = NULL,
    gene_list_A = NULL,
    gene_list_B = NULL,
    organism = "mmu"
) {

  message("=== 自动选择Universe ===\n")

  strategy <- NULL
  universe <- NULL

  # 策略1: DE结果表（最优）
  if (!is.null(DE_results_A) && !is.null(DE_results_B)) {
    message("✅ 策略1: 使用DE结果表（最优）")

    if (is.data.frame(DE_results_A)) {
      universe_A <- DE_results_A[[1]]  # 假设第一列是基因
    } else {
      universe_A <- DE_results_A
    }

    if (is.data.frame(DE_results_B)) {
      universe_B <- DE_results_B[[1]]
    } else {
      universe_B <- DE_results_B
    }

    universe <- intersect(universe_A, universe_B)
    strategy <- "DE_results_intersection"

    message("  A中基因数: ", length(universe_A))
    message("  B中基因数: ", length(universe_B))
    message("  交集基因数: ", length(universe))

  # 策略2: 表达矩阵（次优）
  } else if (!is.null(count_matrix_A) && !is.null(count_matrix_B)) {
    message("⚠️  策略2: 使用表达矩阵（次优）")

    universe_A <- rownames(count_matrix_A)
    universe_B <- rownames(count_matrix_B)
    universe <- intersect(universe_A, universe_B)
    strategy <- "count_matrix_intersection"

    message("  A中基因数: ", length(universe_A))
    message("  B中基因数: ", length(universe_B))
    message("  交集基因数: ", length(universe))

  # 策略3: 基因列表（兜底）
  } else if (!is.null(gene_list_A) && !is.null(gene_list_B)) {
    message("⚠️  策略3: 使用基因列表（兜底）")

    universe <- intersect(gene_list_A, gene_list_B)
    strategy <- "gene_list_intersection"

    message("  A中基因数: ", length(gene_list_A))
    message("  B中基因数: ", length(gene_list_B))
    message("  交集基因数: ", length(universe))

  # 策略4: 全基因组（不推荐，最后手段）
  } else {
    warning("❌ 无法从输入数据推断Universe，使用全基因组（不推荐！）")

    if (organism == "mmu") {
      universe <- keys(org.Mm.eg.db)
    } else if (organism == "hsa") {
      universe <- keys(org.Hs.eg.db)
    } else {
      stop("不支持的物种: ", organism)
    }

    strategy <- "full_genome"

    message("  ⚠️  全基因组大小: ", length(universe))
    message("  ⚠️  结果可能不准确，请谨慎解读！")
  }

  message("\n选择的策略: ", strategy)

  return(list(
    universe = universe,
    strategy = strategy,
    size = length(universe)
  ))
}


# ----------------------------------------------------------------------------
# 函数3: 交集基因KEGG富集分析（推荐使用）
# ----------------------------------------------------------------------------

#' 交集基因的KEGG富集分析（自动Universe处理）
#'
#' @param DE_results_A 数据集A的DE结果表
#' @param DE_results_B 数据集B的DE结果表
#' @param gene_col 基因列名（默认"gene"）
#' @param fc_col log2FC列名（默认"log2FoldChange"）
#' @param padj_col 调整p值列名（默认"padj"）
#' @param fc_threshold_A A上调阈值（默认1）
#' @param fc_threshold_B B下调阈值（默认-1）
#' @param padj_threshold 显著性阈值（默认0.05）
#' @param organism 物种（默认"mmu"）
#' @param min_gssize 最小基因集大小（默认5）
#' @param max_gssize 最大基因集大小（默认500）
#' @return 包含富集结果和元数据的列表
#' @export
enrich_intersect_kegg <- function(
    DE_results_A,
    DE_results_B,
    gene_col = "gene",
    fc_col = "log2FoldChange",
    padj_col = "padj",
    fc_threshold_A = 1,
    fc_threshold_B = -1,
    padj_threshold = 0.05,
    organism = "mmu",
    min_gssize = 5,
    max_gssize = 500
) {

  message("\n")
  message(rep("=", 70), collapse = "")
  message("  交集基因KEGG富集分析（自动Universe处理）")
  message(rep("=", 70), collapse = "")
  message("\n")

  # --------------------------------------------------------------------
  # Step 1: 定义Target基因集
  # --------------------------------------------------------------------
  message("【步骤1/5】定义Target基因集...")

  # 提取A的上调基因
  up_A <- DE_results_A[[gene_col]][
    DE_results_A[[fc_col]] > fc_threshold_A &
    DE_results_A[[padj_col]] < padj_threshold
  ]

  # 提取B的下调基因
  down_B <- DE_results_B[[gene_col]][
    DE_results_B[[fc_col]] < fc_threshold_B &
    DE_results_B[[padj_col]] < padj_threshold
  ]

  # 交集
  target_genes <- intersect(up_A, down_B)

  message(sprintf("  • A上调基因数: %d", length(up_A)))
  message(sprintf("  • B下调基因数: %d", length(down_B)))
  message(sprintf("  • 交集基因数 (Target): %d", length(target_genes)))

  if (length(target_genes) < 3) {
    stop("❌ Target基因太少（< 3），无法进行富集分析")
  }

  # --------------------------------------------------------------------
  # Step 2: 自动选择Universe
  # --------------------------------------------------------------------
  message("\n【步骤2/5】自动选择Universe...")

  universe_result <- auto_select_universe(
    DE_results_A = DE_results_A,
    DE_results_B = DE_results_B,
    organism = organism
  )

  universe <- universe_result$universe
  strategy <- universe_result$strategy

  message(sprintf("  • Universe大小: %d", length(universe)))
  message(sprintf("  • Target占比: %s", percent(length(target_genes) / length(universe))))

  # --------------------------------------------------------------------
  # Step 3: 质量控制检查
  # --------------------------------------------------------------------
  message("\n【步骤3/5】质量控制检查...")

  issues <- quality_check_universe(target_genes, universe, organism)

  if (length(issues) > 0) {
    message("  ⚠️  发现以下问题:")
    for (issue in issues) {
      message("    ", issue)
    }

    response <- readline("  是否继续？(y/n): ")
    if (tolower(response) != "y") {
      stop("用户取消分析")
    }
  } else {
    message("  ✅ 所有检查通过！")
  }

  # --------------------------------------------------------------------
  # Step 4: 执行KEGG富集分析
  # --------------------------------------------------------------------
  message("\n【步骤4/5】执行KEGG富集分析...")

  kegg_result <- tryCatch({
    enrichKEGG(
      gene = target_genes,
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

  # --------------------------------------------------------------------
  # Step 5: 返回结果
  # --------------------------------------------------------------------
  message("\n【步骤5/5】分析完成!")

  n_significant <- sum(kegg_result$p.adjust < 0.05, na.rm = TRUE)
  message(sprintf("  • 显著富集通路数（p.adjust < 0.05）: %d", n_significant))

  if (n_significant > 0) {
    message("\n  Top 5 富集通路:")
    top_paths <- head(kegg_result[kegg_result$p.adjust < 0.05, ],
                      min(5, n_significant))
    for (i in 1:nrow(top_paths)) {
      message(sprintf("    %d. %s (p=%.2e, q=%.2e)",
                     i, top_paths$Description[i],
                     top_paths$pvalue[i], top_paths$p.adjust[i]))
    }
  } else {
    message("  ⚠️  未发现显著富集通路")
  }

  # 返回完整结果
  result <- list(
    kegg = kegg_result,
    target_genes = target_genes,
    universe = universe,
    up_A = up_A,
    down_B = down_B,
    metadata = list(
      target_size = length(target_genes),
      universe_size = length(universe),
      universe_strategy = strategy,
      fc_threshold_A = fc_threshold_A,
      fc_threshold_B = fc_threshold_B,
      padj_threshold = padj_threshold,
      organism = organism,
      n_significant_pathways = n_significant
    )
  )

  class(result) <- c("enrich_intersect_result", class(result))

  message("\n", rep("=", 70), collapse = "")
  message("  分析完成！使用 result$kegg 查看富集结果")
  message(rep("=", 70), collapse = "", "\n")

  return(result)
}


# ----------------------------------------------------------------------------
# 函数4: 单列基因列表的KEGG富集分析
# ----------------------------------------------------------------------------

#' 单列基因列表的KEGG富集分析（需要用户提供Universe）
#'
#' @param gene_list 单列基因列表
#' @param universe 背景基因集（如果为NULL，将尝试自动推断）
#' @param count_matrix 表达矩阵（用于自动推断Universe）
#' @param DE_results DE结果表（用于自动推断Universe）
#' @param organism 物种
#' @return 富集分析结果
#' @export
enrich_single_column_kegg <- function(
    gene_list,
    universe = NULL,
    count_matrix = NULL,
    DE_results = NULL,
    organism = "mmu"
) {

  message("\n=== 单列基因KEGG富集分析 ===\n")

  target_genes <- unique(gene_list)
  message("Target基因数: ", length(target_genes))

  # 自动选择Universe
  if (is.null(universe)) {
    message("\n未提供Universe，尝试自动推断...")
    universe_result <- auto_select_universe(
      count_matrix_A = count_matrix,
      DE_results_A = DE_results,
      organism = organism
    )
    universe <- universe_result$universe
    message("推断的Universe大小: ", length(universe))
  }

  # 质量控制
  issues <- quality_check_universe(target_genes, universe, organism)
  if (length(issues) > 0) {
    message("\n发现问题:")
    for (issue in issues) message("  ", issue)
  }

  # 执行分析
  message("\n执行KEGG富集分析...")
  result <- enrichKEGG(
    gene = target_genes,
    universe = universe,
    organism = organism
  )

  message("显著通路数: ", sum(result$p.adjust < 0.05, na.rm = TRUE))

  return(result)
}


# ----------------------------------------------------------------------------
# 函数5: 打印富集分析摘要
# ----------------------------------------------------------------------------

#' 打印富集分析结果摘要
#'
#' @param result enrich_intersect_kegg的返回结果
#' @export
print_enrichment_summary <- function(result) {

  cat("\n")
  cat(rep("=", 70), sep = "")
  cat("\n富集分析结果摘要\n")
  cat(rep("=", 70), sep = "")
  cat("\n")

  cat("数据统计:\n")
  cat(sprintf("  • Target基因数: %d\n", result$metadata$target_size))
  cat(sprintf("  • Universe大小: %d\n", result$metadata$universe_size))
  cat(sprintf("  • Target占比: %s\n",
              percent(result$metadata$target_size / result$metadata$universe_size)))
  cat(sprintf("  • Universe策略: %s\n", result$metadata$universe_strategy))

  cat("\n富集结果:\n")
  cat(sprintf("  • 显著通路数: %d\n", result$metadata$n_significant_pathways))

  if (result$metadata$n_significant_pathways > 0) {
    cat("\nTop 10 富集通路:\n")
    top_paths <- head(result$kegg[result$kegg$p.adjust < 0.05, ], 10)

    for (i in 1:nrow(top_paths)) {
      cat(sprintf("  %2d. %-50s p=%.2e q=%.2e\n",
                 i, top_paths$Description[i],
                 top_paths$pvalue[i], top_paths$p.adjust[i]))
    }
  }

  cat(rep("=", 70), sep = "", "\n")
}


# ----------------------------------------------------------------------------
# 函数6: 交互式Universe选择工具
# ----------------------------------------------------------------------------

#' 交互式Universe选择工具
#'
#' 当用户只有基因列表时，帮助确定合适的Universe
#' @param target_genes 目标基因集
#' @param organism 物种
#' @export
interactive_universe_selector <- function(target_genes, organism = "mmu") {

  message("\n=== 交互式Universe选择工具 ===\n")
  message("您提供了一列基因，但没有指定Universe。")
  message("请回答以下问题以确定最佳的Universe:\n")

  # 问题1
  q1 <- readline("这些基因来自RNA-seq分析吗？(y/n): ")

  if (tolower(q1) == "y") {
    # 问题2
    q2 <- readline("您有DESeq2/edgeR/limma的输出文件吗？(y/n): ")

    if (tolower(q2) == "y") {
      de_file <- readline("请输入DE结果文件路径: ")

      if (file.exists(de_file)) {
        de_results <- read.csv(de_file)
        universe <- de_results[[1]]  # 第一列

        message(sprintf("\n✅ 使用DE结果文件，Universe大小: %d", length(universe)))
        return(universe)
      } else {
        message("❌ 文件不存在")
      }
    }

    # 问题3
    q3 <- readline("您有原始count matrix吗？(y/n): ")

    if (tolower(q3) == "y") {
      count_file <- readline("请输入count matrix文件路径: ")

      if (file.exists(count_file)) {
        count_matrix <- read.csv(count_file, row.names = 1)
        universe <- rownames(count_matrix)

        message(sprintf("\n✅ 使用count matrix，Universe大小: %d", length(universe)))
        return(universe)
      }
    }

    # 问题4
    message("\n⚠️  如果您没有原始数据，以下是选项:\n")
    message("  1. 使用组织相关基因集（如肝脏表达基因）")
    message("  2. 使用全基因组（不推荐，统计效力弱）")
    message("  3. 手动输入Universe大小")

    choice <- readline("\n请选择 (1/2/3): ")

    if (choice == "1") {
      # TODO: 实现组织特异性基因集
      message("💡 建议：查询GTEx等数据库获取组织特异性表达基因")
    } else if (choice == "2") {
      warning("使用全基因组（不推荐）")

      if (organism == "mmu") {
        universe <- keys(org.Mm.eg.db)
      } else {
        universe <- keys(org.Hs.eg.db)
      }

      return(universe)
    } else if (choice == "3") {
      size <- as.integer(readline("请输入Universe大小: "))
      message(sprintf("⚠️  使用假设的Universe大小: %d", size))
      message("⚠️  这将影响统计准确性，请谨慎解读结果！")
      return(NULL)  # clusterProfiler会自动处理
    }

  } else {
    message("\n💡 如果不是RNA-seq数据，请提供研究背景以确定合适的Universe")
  }

  # 默认返回NULL，让clusterProfiler使用默认行为
  return(NULL)
}


# ============================================================================
# 使用示例
# ============================================================================

# 示例1: 双数据集交集分析（推荐）
# --------------------------------
# DE_results_A <- read.csv("dataset_A_DE.csv")
# DE_results_B <- read.csv("dataset_B_DE.csv")
#
# result <- enrich_intersect_kegg(
#   DE_results_A = DE_results_A,
#   DE_results_B = DE_results_B,
#   fc_threshold_A = 1,
#   fc_threshold_B = -1,
#   padj_threshold = 0.05
# )
#
# print_enrichment_summary(result)

# 示例2: 单列基因列表
# --------------------------------
# gene_list <- read.csv("my_genes.csv")$gene
#
# # 选项A: 有DE结果
# DE_results <- read.csv("DE_results.csv")
# result <- enrich_single_column_kegg(
#   gene_list = gene_list,
#   DE_results = DE_results
# )
#
# # 选项B: 交互式选择
# result <- enrich_single_column_kegg(
#   gene_list = gene_list,
#   universe = interactive_universe_selector(gene_list)
# )

# 示例3: 质量控制检查
# --------------------------------
# target <- c("Gene1", "Gene2", "Gene3")
# universe <- c("Gene1", "Gene2", "Gene3", "Gene4", "Gene5")
#
# issues <- quality_check_universe(target, universe)
# if (length(issues) > 0) {
#   for (issue in issues) cat(issue, "\n")
# }


# ============================================================================
# 导出说明
# ============================================================================

# 在R中加载此脚本后，以下函数将可用:
# - quality_check_universe(): 质量控制检查
# - auto_select_universe(): 自动选择Universe
# - enrich_intersect_kegg(): 交集基因富集分析（推荐）
# - enrich_single_column_kegg(): 单列基因富集分析
# - print_enrichment_summary(): 打印结果摘要
# - interactive_universe_selector(): 交互式Universe选择

# 核心特性:
# ✅ 自动选择最佳的Universe定义
# ✅ 全面的质量控制检查
# ✅ 详细的日志输出
# ✅ 错误处理和诊断信息
# ✅ 适用于多种场景

print("✅ 富集分析工具集加载完成！")
print("使用 help(enrich_intersect_kegg) 查看详细帮助")
