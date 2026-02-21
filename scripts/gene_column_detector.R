# ============================================================================
# 基因列自动检测工具
# ============================================================================
# 用途：自动识别DE结果表中基因ID、log2FC、p值等关键列
# ============================================================================

#' 自动检测基因列
#'
#' @param df 数据框（DE结果表）
#' @param verbose 是否打印详细信息
#' @return 列名（如果找到）或NULL（如果未找到）
#' @export
detect_gene_column <- function(df, verbose = TRUE) {

  if (verbose) {
    message("检测基因列...")
  }

  # 常见的基因列名模式
  gene_patterns <- c(
    # 英文
    "^gene$", "^gene_id$", "^geneid$", "^gene.symbol$", "^gene_name$",
    "^ensembl$", "^ensembl.id$", "^ensembl_gene$", "^ensembl_gene_id$",
    "^entrez$", "^entrez.id$", "^entrez_gene$", "^entrez_gene_id$",
    "^symbol$", "^gene.symbol$", "^hgnc.symbol$",
    "^row.names$", "^rowname$", "^row_names$",

    # 变体
    ".*gene.*", ".*ensembl.*", ".*entrez.*", ".*symbol.*"
  )

  # 获取所有列名
  all_cols <- colnames(df)

  # 优先精确匹配
  for (pattern in gene_patterns[1:10]) {  # 前10个是精确匹配
    match_cols <- grep(pattern, all_cols, ignore.case = TRUE)
    if (length(match_cols) == 1) {
      gene_col <- all_cols[match_cols]
      if (verbose) {
        message("  ✅ 找到基因列: '", gene_col, "' (精确匹配)")
      }
      return(gene_col)
    }
  }

  # 如果精确匹配失败，尝试模糊匹配
  for (pattern in gene_patterns[11:length(gene_patterns)]) {
    match_cols <- grep(pattern, all_cols, ignore.case = TRUE)
    if (length(match_cols) == 1) {
      gene_col <- all_cols[match_cols]
      if (verbose) {
        message("  ⚠️  找到可能的基因列: '", gene_col, "' (模糊匹配)")
      }
      return(gene_col)
    }
  }

  # 如果还是没有，检查第一列（传统上是基因列）
  first_col <- all_cols[1]
  if (verbose) {
    message("  ⚠️  无法自动识别，尝试使用第一列: '", first_col, "'")
  }
  return(first_col)
}


#' 自动检测log2FC列
#'
#' @param df 数据框
#' @param verbose 是否打印详细信息
#' @return 列名
#' @export
detect_logfc_column <- function(df, verbose = TRUE) {

  if (verbose) {
    message("检测log2FoldChange列...")
  }

  # 常见的log2FC列名
  fc_patterns <- c(
    "^log2fc$", "^log2.fold.change$", "^log2foldchange$",
    "^log2.fc$", "^log_2_fc$", "^log2fc$",
    "^lfc$", "^logfc$", "^log.fold.change$",
    "^fold.change$", "^fc$",
    "^log2$", "^log2ratio$"
  )

  all_cols <- colnames(df)

  # 精确匹配
  for (pattern in fc_patterns) {
    match_cols <- grep(pattern, all_cols, ignore.case = TRUE)
    if (length(match_cols) == 1) {
      fc_col <- all_cols[match_cols]
      if (verbose) {
        message("  ✅ 找到log2FC列: '", fc_col, "'")
      }
      return(fc_col)
    }
  }

  # 模糊匹配
  match_cols <- grep("log2|fold|change|fc|lfc", all_cols, ignore.case = TRUE)
  if (length(match_cols) == 1) {
    fc_col <- all_cols[match_cols]
    if (verbose) {
      message("  ⚠️  可能的log2FC列: '", fc_col, "'")
    }
    return(fc_col)
  }

  if (verbose) {
    message("  ❌ 未找到log2FC列")
  }
  return(NULL)
}


#' 自动检测p值列
#'
#' @param df 数据框
#' @param verbose 是否打印详细信息
#' @return 列名
#' @export
detect_pvalue_column <- function(df, verbose = TRUE) {

  if (verbose) {
    message("检测p值列...")
  }

  # 常见的p值列名（优先adj p值）
  pval_patterns <- c(
    # 调整p值（优先）
    "^padj$", "^p.adjust$", "^padj$", "^fdr$",
    "^pvalue.adjusted$", "^pval.adjusted$",
    "^qvalue$", "^q.val$", "^bh$",
    "^bonferroni$",

    # 原始p值（备选）
    "^pvalue$", "^p.val$", "^pvalue$",
    "^pval$", "^p.val$", "^p$",
    "^raw.p$", "^p_raw$"
  )

  all_cols <- colnames(df)

  # 优先找调整p值
  for (pattern in pval_patterns[1:8]) {
    match_cols <- grep(pattern, all_cols, ignore.case = TRUE)
    if (length(match_cols) == 1) {
      pval_col <- all_cols[match_cols]
      if (verbose) {
        message("  ✅ 找到p值列: '", pval_col, "' (调整p值)")
      }
      return(pval_col)
    }
  }

  # 如果没有调整p值，找原始p值
  for (pattern in pval_patterns[9:length(pval_patterns)]) {
    match_cols <- grep(pattern, all_cols, ignore.case = TRUE)
    if (length(match_cols) == 1) {
      pval_col <- all_cols[match_cols]
      if (verbose) {
        message("  ⚠️  找到p值列: '", pval_col, "' (原始p值，建议使用调整p值)")
      }
      return(pval_col)
    }
  }

  # 模糊匹配
  match_cols <- grep("^p|padj|fdr|qval", all_cols, ignore.case = TRUE)
  if (length(match_cols) == 1) {
    pval_col <- all_cols[match_cols]
    if (verbose) {
      message("  ⚠️  可能的p值列: '", pval_col, "'")
    }
    return(pval_col)
  }

  if (verbose) {
    message("  ❌ 未找到p值列")
  }
  return(NULL)
}


#' 智能检测所有关键列
#'
#' @param df 数据框
#' @param verbose 是否打印详细信息
#' @return 包含gene_col, fc_col, pval_col的列表
#' @export
detect_all_columns <- function(df, verbose = TRUE) {

  if (verbose) {
    message("\n=== 自动检测DE结果表列名 ===\n")
    message("数据框列数: ", ncol(df))
    message("数据框行数: ", nrow(df))
    message("\n所有列名: ")
    for (col in colnames(df)) {
      message("  • ", col)
    }
    message("\n")
  }

  gene_col <- detect_gene_column(df, verbose)
  fc_col <- detect_logfc_column(df, verbose)
  pval_col <- detect_pvalue_column(df, verbose)

  result <- list(
    gene_col = gene_col,
    fc_col = fc_col,
    pval_col = pval_col
  )

  # 验证
  if (verbose) {
    message("\n检测结果:")
    message("  基因列: ", ifelse(is.null(gene_col), "❌ 未找到", gene_col))
    message("  log2FC列: ", ifelse(is.null(fc_col), "❌ 未找到", fc_col))
    message("  p值列: ", ifelse(is.null(pval_col), "❌ 未找到", pval_col))

    if (is.null(gene_col) || is.null(fc_col) || is.null(pval_col)) {
      warning("\n⚠️  某些关键列未自动识别，请手动指定")
    } else {
      message("\n✅ 所有关键列已识别")
    }
    message("\n")
  }

  return(result)
}


#' 验证列的内容是否合理
#'
#' @param df 数据框
#' @param gene_col 基因列名
#' @param fc_col log2FC列名
#' @param pval_col p值列名
#' @return 验证结果（逻辑值）
#' @export
validate_columns <- function(df, gene_col, fc_col, pval_col) {

  message("\n=== 验证列内容 ===\n")

  issues <- character(0)

  # 检查基因列
  if (!gene_col %in% colnames(df)) {
    issues <- c(issues, "❌ 基因列 '", gene_col, "' 不存在")
  } else {
    genes <- df[[gene_col]]
    n_unique <- length(unique(genes))
    n_na <- sum(is.na(genes))

    message("基因列验证:")
    message("  • 列名: ", gene_col)
    message("  • 基因数: ", length(genes))
    message("  • 唯一基因数: ", n_unique)
    message("  • NA值数: ", n_na)

    if (n_na > 0) {
      issues <- c(issues, "⚠️  基因列包含 ", n_na, " 个NA值")
    }

    if (n_unique < length(genes) * 0.9) {
      issues <- c(issues, "⚠️  基因重复率高（", n_unique, "/", length(genes), "）")
    }
  }

  # 检查log2FC列
  if (!fc_col %in% colnames(df)) {
    issues <- c(issues, "❌ log2FC列 '", fc_col, "' 不存在")
  } else {
    fc <- df[[fc_col]]
    n_na <- sum(is.na(fc))

    message("\nlog2FC列验证:")
    message("  • 列名: ", fc_col)
    message("  • 数值范围: [", round(min(fc, na.rm = TRUE), 2),
            ", ", round(max(fc, na.rm = TRUE), 2), "]")
    message("  • NA值数: ", n_na)

    if (!is.numeric(fc)) {
      issues <- c(issues, "❌ log2FC列不是数值类型")
    }

    if (n_na > length(fc) * 0.5) {
      issues <- c(issues, "⚠️  log2FC列NA值过多（", n_na, "/", length(fc), "）")
    }
  }

  # 检查p值列
  if (!pval_col %in% colnames(df)) {
    issues <- c(issues, "❌ p值列 '", pval_col, "' 不存在")
  } else {
    pvals <- df[[pval_col]]
    n_na <- sum(is.na(pvals))

    message("\np值列验证:")
    message("  • 列名: ", pval_col)
    message("  • 数值范围: [", round(min(pvals, na.rm = TRUE), 4),
            ", ", round(max(pvals, na.rm = TRUE), 4), "]")
    message("  • NA值数: ", n_na)

    if (!is.numeric(pvals)) {
      issues <- c(issues, "❌ p值列不是数值类型")
    }

    if (any(pvals < 0, na.rm = TRUE) || any(pvals > 1, na.rm = TRUE)) {
      issues <- c(issues, "⚠️  p值超出[0,1]范围，可能不是p值")
    }

    if (n_na > length(pvals) * 0.5) {
      issues <- c(issues, "⚠️  p值列NA值过多（", n_na, "/", length(pvals), "）")
    }
  }

  # 总结
  if (length(issues) == 0) {
    message("\n✅ 所有列验证通过\n")
    return(TRUE)
  } else {
    message("\n发现以下问题:")
    for (issue in issues) {
      message("  ", issue)
    }
    message()
    return(FALSE)
  }
}


#' 智能读取DE结果文件（支持多种格式）
#'
#' @param file_path 文件路径
#' @param auto_detect 是否自动检测列名
#' @param verbose 是否打印详细信息
#' @return 数据框
#' @export
smart_read_DE <- function(file_path, auto_detect = TRUE, verbose = TRUE) {

  if (verbose) {
    message("\n=== 读取DE结果文件 ===")
    message("文件: ", file_path, "\n")
  }

  # 检查文件是否存在
  if (!file.exists(file_path)) {
    stop("文件不存在: ", file_path)
  }

  # 根据扩展名选择读取方式
  ext <- tolower(tools::file_ext(file_path))

  df <- tryCatch({
    if (ext == "csv") {
      if (verbose) message("格式: CSV")
      read.csv(file_path, check.names = FALSE, stringsAsFactors = FALSE)
    } else if (ext == "tsv" || ext == "txt") {
      if (verbose) message("格式: TSV/TXT")
      read.delim(file_path, check.names = FALSE, stringsAsFactors = FALSE)
    } else if (ext == "xlsx" || ext == "xls") {
      if (verbose) message("格式: Excel")
      readxl::read_excel(file_path)
    } else {
      if (verbose) message("格式: 未知，尝试CSV")
      read.csv(file_path, check.names = FALSE, stringsAsFactors = FALSE)
    }
  }, error = function(e) {
    stop("读取文件失败: ", e$message)
  })

  if (verbose) {
    message("✅ 成功读取 ", nrow(df), " 行 × ", ncol(df), " 列\n")
  }

  # 自动检测列名
  if (auto_detect) {
    col_info <- detect_all_columns(df, verbose = verbose)

    # 将检测结果作为属性附加到数据框
    attr(df, "gene_col") <- col_info$gene_col
    attr(df, "fc_col") <- col_info$fc_col
    attr(df, "pval_col") <- col_info$pval_col
  }

  return(df)
}


# ============================================================================
# 使用示例
# ============================================================================

# 示例1: 自动检测所有列
# --------------------------------
# DE_results <- smart_read_DE("DE_results.csv", auto_detect = TRUE)
#
# # 访问检测到的列名
# gene_col <- attr(DE_results, "gene_col")
# fc_col <- attr(DE_results, "fc_col")
# pval_col <- attr(DE_results, "pval_col")
#
# # 使用这些列名
# up_genes <- DE_results[[gene_col]][DE_results[[fc_col]] > 1 &
#                                     DE_results[[pval_col]] < 0.05]

# 示例2: 手动指定列名（如果自动检测失败）
# --------------------------------
# DE_results <- read.csv("DE_results.csv")
#
# # 用户明确指定列名
# result <- enrich_intersect_kegg(
#   DE_results_A = DE_A,
#   DE_results_B = DE_B,
#   gene_col = "gene",  # 手动指定
#   fc_col = "log2FoldChange",
#   padj_col = "padj"
# )

# 示例3: 验证列内容
# --------------------------------
# DE_results <- read.csv("DE_results.csv")
#
# cols <- detect_all_columns(DE_results, verbose = TRUE)
#
# validate_columns(
#   df = DE_results,
#   gene_col = cols$gene_col,
#   fc_col = cols$fc_col,
#   pval_col = cols$pval_col
# )

print("✅ 基因列检测工具加载完成！")
print("使用 help(detect_all_columns) 查看详细帮助")
