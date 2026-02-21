# SOFT文件列内容检查工具
# 用法：先上传SOFT文件到芯片分析模块，然后运行此脚本

cat("====================================\n")
cat("SOFT文件列内容检查工具\n")
cat("====================================\n\n")

# 读取SOFT文件（假设已上传）
# 请修改为你的SOFT文件路径
soft_file <- "data/GPLxxxx.nnn.txt"  # 修改为你的文件路径

if (!file.exists(soft_file)) {
  cat("❌ 文件不存在，请修改脚本中的文件路径\n")
  cat("当前路径:", soft_file, "\n")
} else {
  # 读取SOFT文件
  cat("📁 正在读取SOFT文件...\n")
  soft_data <- tryCatch({
    read.table(soft_file, header = TRUE, sep = "\t",
               stringsAsFactors = FALSE, comment.char = "",
               quote = "", check.names = FALSE)
  }, error = function(e) {
    cat("❌ 读取失败:", conditionMessage(e), "\n")
    return(NULL)
  })

  if (!is.null(soft_data)) {
    cat(sprintf("✅ 成功读取: %d 行 × %d 列\n",
                nrow(soft_data), ncol(soft_data)))
    cat("\n")

    # 显示所有列名
    cat("📋 所有列名:\n")
    colnames_vec <- colnames(soft_data)
    for (i in seq_along(colnames_vec)) {
      cat(sprintf("  %2d. %s\n", i, colnames_vec[i]))
    }
    cat("\n")

    # 检查每一列的内容
    cat("🔍 列内容分析:\n")
    cat(sprintf("%-20s %-15s %-10s %s\n",
                "列名", "数据类型", "示例1", "示例2"))
    cat(sprintf("%s\n", paste(rep("-", 70), collapse = "")))

    for (col_name in colnames_vec) {
      col_data <- soft_data[[col_name]]

      # 检查数据类型
      is_numeric <- all(grepl("^[0-9.]+$", col_data[!is.na(col_data)][1:10]))
      is_text <- any(grepl("[A-Za-z]", col_data[!is.na(col_data)][1:10]))

      # 获取前两个非NA示例
      examples <- head(col_data[!is.na(col_data) & col_data != ""], 2)
      ex1 <- if (length(examples) > 0) as.character(examples[1]) else "NA"
      ex2 <- if (length(examples) > 1) as.character(examples[2]) else "NA"

      # 截断过长的示例
      if (nchar(ex1) > 15) ex1 <- paste0(substr(ex1, 1, 12), "...")
      if (nchar(ex2) > 15) ex2 <- paste0(substr(ex2, 1, 12), "...")

      # 确定数据类型
      data_type <- if (is_numeric) {
        "数字ID"
      } else if (is_text) {
        "基因符号"
      } else {
        "其他"
      }

      cat(sprintf("%-20s %-15s %-10s %s\n",
                  col_name, data_type, ex1, ex2))
    }
    cat("\n")

    # 推荐
    cat("💡 推荐选择:\n")
    cat("  ID列: ID 或 SPOT_ID\n")
    cat("  基因列: GENE, GENE_NAME, NAME, 或 DESCRIPTION\n")
    cat("\n")

    # 检查ID列候选
    id_candidates <- c("ID", "SPOT_ID", "PROBE_ID")
    for (id_col in id_candidates) {
      if (id_col %in% colnames_vec) {
        cat(sprintf("  ✅ 找到ID列候选: %s\n", id_col))
        examples <- head(soft_data[[id_col]], 3)
        cat(sprintf("     示例: %s\n", paste(examples, collapse = ", ")))
      }
    }

    cat("\n")

    # 检查基因列候选
    gene_candidates <- c("GENE", "GENE_SYMBOL", "GENE_NAME", "NAME", "SYMBOL",
                        "DESCRIPTION", "GENE_TITLE")
    for (gene_col in gene_candidates) {
      if (gene_col %in% colnames_vec) {
        col_data <- soft_data[[gene_col]]
        examples <- head(col_data[!is.na(col_data) & col_data != ""], 3)

        # 检查是数字ID还是基因符号
        is_numeric <- all(grepl("^[0-9]+$", examples))

        if (is_numeric) {
          cat(sprintf("  ⚠️  %s: 包含数字ID (不推荐)\n", gene_col))
          cat(sprintf("     示例: %s\n", paste(examples, collapse = ", ")))
        } else {
          cat(sprintf("  ✅ %s: 包含基因符号 (推荐)\n", gene_col))
          cat(sprintf("     示例: %s\n", paste(examples, collapse = ", ")))
        }
      }
    }
  }
}

cat("\n====================================\n")
cat("检查完成\n")
cat("====================================\n")
