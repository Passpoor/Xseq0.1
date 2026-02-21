# 修复火山图log2FoldChange列问题

cat("开始修复火山图log2FoldChange列问题...\n")
cat("=" * 60, "\n\n")

# 读取当前的差异分析模块
differential_file <- "modules/differential_analysis.R"
original_code <- readLines(differential_file, warn = FALSE)

# 创建增强的列检查和重命名函数
enhanced_column_mapping <- function(df) {
  cat("检查上传的差异基因文件列结构...\n")
  cat("原始列名:", paste(colnames(df), collapse = ", "), "\n")
  
  # 可能的列名映射
  column_mappings <- list(
    log2FoldChange = c("log2FoldChange", "log2FC", "avg_log2FC", "logFC", "log2_fold_change", "log2fc", "log2fc_adj"),
    pvalue = c("pvalue", "p_val", "p.value", "P.Value", "pvalue_adj"),
    padj = c("padj", "p_val_adj", "p_adj", "adj.P.Val", "pvalue_adj", "FDR"),
    GeneID = c("GeneID", "gene", "Gene", "SYMBOL", "symbol", "gene_symbol", "ensembl", "ENSEMBL")
  )
  
  # 检查并重命名列
  for (target_col in names(column_mappings)) {
    possible_names <- column_mappings[[target_col]]
    found <- FALSE
    
    for (col_name in possible_names) {
      if (col_name %in% colnames(df)) {
        if (col_name != target_col) {
          cat("  重命名列:", col_name, "->", target_col, "\n")
          colnames(df)[colnames(df) == col_name] <- target_col
        } else {
          cat("  找到列:", target_col, "\n")
        }
        found <- TRUE
        break
      }
    }
    
    if (!found) {
      cat("  ⚠️  缺失列:", target_col, "\n")
    }
  }
  
  # 确保log2FoldChange是数值类型
  if ("log2FoldChange" %in% colnames(df)) {
    if (!is.numeric(df$log2FoldChange)) {
      cat("  转换log2FoldChange为数值类型\n")
      df$log2FoldChange <- as.numeric(as.character(df$log2FoldChange))
    }
  }
  
  # 确保pvalue和padj是数值类型
  for (col in c("pvalue", "padj")) {
    if (col %in% colnames(df)) {
      if (!is.numeric(df[[col]])) {
        cat("  转换", col, "为数值类型\n")
        df[[col]] <- as.numeric(as.character(df[[col]]))
      }
    }
  }
  
  return(df)
}

# 修改差异分析模块中的文件加载逻辑
modify_deg_results_from_file <- function() {
  # 读取原始文件
  lines <- readLines(differential_file, warn = FALSE)
  
  # 找到deg_results_from_file函数的开始和结束
  start_idx <- grep("deg_results_from_file <- eventReactive", lines)
  end_idx <- grep("return\\(res\\)", lines)[which(grep("return\\(res\\)", lines) > start_idx)[1]]
  
  if (length(start_idx) == 0 || length(end_idx) == 0) {
    cat("❌ 无法找到deg_results_from_file函数\n")
    return(FALSE)
  }
  
  cat("找到deg_results_from_file函数，从第", start_idx, "行到第", end_idx, "行\n")
  
  # 创建新的函数代码
  new_function_code <- paste0(
    '  # --- 加载差异基因结果 ---\n',
    '  deg_results_from_file <- eventReactive(input$load_deg, {\n',
    '    req(data_input$deg_file_data(), user_session$logged_in)\n',
    '\n',
    '    if (!check_usage_limit(user_session$info$username)) {\n',
    '      showNotification("今日额度已用完", type = "error")\n',
    '      return(NULL)\n',
    '    }\n',
    '\n',
    '    showNotification("正在加载差异基因结果...", type = "message")\n',
    '\n',
    '    df <- data_input$deg_file_data()\n',
    '    cat("上传的文件列名:", paste(colnames(df), collapse = ", "), "\\n")\n',
    '\n',
    '    # 应用增强的列映射\n',
    '    df <- enhanced_column_mapping(df)\n',
    '\n',
    '    # 检查必要的列是否存在\n',
    '    required_cols <- c("pvalue", "log2FoldChange")\n',
    '    missing_cols <- setdiff(required_cols, colnames(df))\n',
    '\n',
    '    if (length(missing_cols) > 0) {\n',
    '      showNotification(paste("缺少必要的列:", paste(missing_cols, collapse = ", ")), type = "error")\n',
    '      return(NULL)\n',
    '    }\n',
    '\n',
    '    # 确保有padj列，如果没有则使用pvalue\n',
    '    if (!"padj" %in% colnames(df)) {\n',
    '      df$padj <- df$pvalue\n',
    '    }\n',
    '\n',
    '    res <- df\n',
    '\n',
    '    # 确保所有必要列都存在\n',
    '    if (!"GeneID" %in% colnames(res)) {\n',
    '      res$GeneID <- if("SYMBOL" %in% colnames(res)) res$SYMBOL else rownames(res)\n',
    '    }\n',
    '\n',
    '    if (!"baseMean" %in% colnames(res)) res$baseMean <- 1\n',
    '    if (!"logCPM" %in% colnames(res)) res$logCPM <- 0\n',
    '    if (!"SYMBOL" %in% colnames(res)) res$SYMBOL <- res$GeneID\n',
    '\n',
    '    # 差异状态判断\n',
    '    pval_col <- if(input$deg_pval_type == "p_val_adj") "padj" else "pvalue"\n',
    '    res$Status <- ifelse(res[[pval_col]] < input$deg_pval_cutoff & abs(res$log2FoldChange) > input$deg_log2fc_cutoff,\n',
    '                         ifelse(res$log2FoldChange > 0, "Up", "Down"), "Not DE")\n',
    '\n',
    '    res <- res %>%\n',
    '      dplyr::mutate(t_stat = -log10(pvalue) * log2FoldChange)\n',
    '\n',
    '    anno <- data_input$annotate_genes(res$GeneID, input$deg_species)\n',
    '\n',
    '    if (!is.null(anno)) {\n',
    '      if("ENSEMBL" %in% colnames(anno) && any(grepl("ENS", res$GeneID))) {\n',
    '        res <- merge(res, anno, by.x="GeneID", by.y="ENSEMBL", all.x=TRUE)\n',
    '      } else if ("SYMBOL" %in% colnames(anno)) {\n',
    '        res <- merge(res, anno, by.x="GeneID", by.y="SYMBOL", all.x=TRUE)\n',
    '      }\n',
    '    }\n',
    '\n',
    '    if (!"SYMBOL" %in% colnames(res)) res$SYMBOL <- res$GeneID\n',
    '    if (!"ENTREZID" %in% colnames(res)) res$ENTREZID <- NA\n',
    '\n',
    '    res <- data_input$filter_pseudo_genes(res)\n',
    '    res <- res[!duplicated(res$SYMBOL), ]\n',
    '\n',
    '    cat("最终数据列:", paste(colnames(res), collapse = ", "), "\\n")\n',
    '    return(res)\n',
    '  })\n'
  )
  
  # 创建增强列映射函数代码
  enhanced_column_mapping_function <- paste0(
    '  enhanced_column_mapping <- function(df) {\n',
    '    cat("检查上传的差异基因文件列结构...\\n")\n',
    '    column_mappings <- list(\n',
    '      log2FoldChange = c("log2FoldChange", "log2FC", "avg_log2FC", "logFC", "log2_fold_change", "log2fc", "log2fc_adj"),\n',
    '      pvalue = c("pvalue", "p_val", "p.value", "P.Value", "pvalue_adj"),\n',
    '      padj = c("padj", "p_val_adj", "p_adj", "adj.P.Val", "pvalue_adj", "FDR"),\n',
    '      GeneID = c("GeneID", "gene", "Gene", "SYMBOL", "symbol", "gene_symbol", "ensembl", "ENSEMBL")\n',
    '    )\n',
    '    \n',
    '    for (target_col in names(column_mappings)) {\n',
    '      possible_names <- column_mappings[[target_col]]\n',
    '      for (col_name in possible_names) {\n',
    '        if (col_name %in% colnames(df)) {\n',
    '          if (col_name != target_col) {\n',
    '            colnames(df)[colnames(df) == col_name] <- target_col\n',
    '          }\n',
    '          break\n',
    '        }\n',
    '      }\n',
    '    }\n',
    '    \n',
    '    if ("log2FoldChange" %in% colnames(df) && !is.numeric(df$log2FoldChange)) {\n',
    '      df$log2FoldChange <- as.numeric(as.character(df$log2FoldChange))\n',
    '    }\n',
    '    \n',
    '    for (col in c("pvalue", "padj")) {\n',
    '      if (col %in% colnames(df) && !is.numeric(df[[col]])) {\n',
    '        df[[col]] <- as.numeric(as.character(df[[col]]))\n',
    '      }\n',
    '    }\n',
    '    return(df)\n',
    '  }\n',
    '\n'
  )
  
  # 正确的行合并（修复括号错误）
  server_start <- grep("differential_analysis_server <- function", lines)
  if (length(server_start) > 0) {
    lines <- c(
      lines[1:(server_start[1] + 3)],
      enhanced_column_mapping_function,
      lines[(server_start[1] + 4):(start_idx[1] - 1)],  # ✅ 这里修复了括号
      strsplit(new_function_code, "\n")[[1]],
      lines[(end_idx[1] + 1):length(lines)]
    )
  }
  
  # 写回文件
  writeLines(lines, differential_file, useBytes = TRUE)
  cat("✅ 差异分析模块已更新\n")
  
  return(TRUE)
}

# 执行修复
cat("\n3. 执行修复\n")
success <- modify_deg_results_from_file()

if (success) {
  cat("\n", strrep("=", 60), "\n")
  cat("✅ 修复完成！\n\n")
  cat("修复内容:\n")
  cat("1. ✅ 修复了括号语法错误\n")
  cat("2. ✅ 添加了enhanced_column_mapping函数\n")
  cat("3. ✅ 支持多种列名格式自动识别\n")
  cat("4. ✅ 自动转换非数值列为数值类型\n\n")
} else {
  cat("\n❌ 修复失败，请检查文件路径和权限\n")
}