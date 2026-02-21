# 基因符号验证工具
# 用于诊断和解决"None of the keys entered are valid keys for 'SYMBOL'"错误

library(AnnotationDbi)

# 主验证函数
validate_gene_symbols <- function(gene_symbols, species = "human") {
  cat("=== 基因符号验证工具 ===\n")
  cat("物种:", species, "\n")
  cat("输入基因数量:", length(gene_symbols), "\n")
  cat("输入基因示例:", paste(head(gene_symbols, 10), collapse=", "), "\n\n")

  # 选择数据库
  if (species == "human") {
    db_pkg <- "org.Hs.eg.db"
    species_code <- "hsa"
  } else if (species == "mouse") {
    db_pkg <- "org.Mm.eg.db"
    species_code <- "mmu"
  } else {
    cat("错误: 不支持的物种。请使用 'human' 或 'mouse'\n")
    return(NULL)
  }

  # 检查数据库是否安装
  if (!require(db_pkg, character.only = TRUE, quietly = TRUE)) {
    cat("错误: 数据库包", db_pkg, "未安装\n")
    cat("请使用以下命令安装: install.packages('BiocManager'); BiocManager::install('", db_pkg, "')\n", sep="")
    return(NULL)
  }

  db_obj <- get(db_pkg)

  # 1. 清理基因符号
  cat("1. 清理基因符号\n")
  cleaned_genes <- clean_gene_symbols(gene_symbols, species_code)
  cat("   清理后基因示例:", paste(head(cleaned_genes, 10), collapse=", "), "\n\n")

  # 2. 检查各种keytype的匹配情况
  cat("2. 检查不同keytype的匹配情况\n")
  keytypes_to_check <- c("SYMBOL", "ALIAS", "ENSEMBL", "ENTREZID")

  results <- list()
  for (keytype in keytypes_to_check) {
    cat("   ", keytype, ":\n")

    tryCatch({
      # 获取有效的keys
      valid_keys <- keys(db_obj, keytype = keytype)

      # 检查匹配
      matched <- cleaned_genes[cleaned_genes %in% valid_keys]
      match_count <- length(matched)

      cat("     有效key数量:", length(valid_keys), "\n")
      cat("     匹配数量:", match_count, "\n")

      if (match_count > 0) {
        cat("     匹配示例:", paste(head(matched, 5), collapse=", "), "\n")

        # 尝试转换
        if (match_count <= 100) {  # 避免转换太多基因
          tryCatch({
            converted <- AnnotationDbi::mapIds(
              db_obj,
              keys = matched,
              column = "ENTREZID",
              keytype = keytype,
              multiVals = "first"
            )
            success_count <- sum(!is.na(converted))
            cat("     成功转换为ENTREZID:", success_count, "个\n")
          }, error = function(e) {
            cat("     转换错误:", e$message, "\n")
          })
        }
      } else {
        cat("     无匹配\n")
      }

      results[[keytype]] <- list(
        valid_count = length(valid_keys),
        matched_count = match_count,
        matched_samples = if(match_count > 0) head(matched, 5) else NULL
      )

    }, error = function(e) {
      cat("     错误:", e$message, "\n")
      results[[keytype]] <- list(error = e$message)
    })

    cat("\n")
  }

  # 3. 识别问题基因
  cat("3. 识别问题基因\n")

  # 获取所有有效的SYMBOL
  tryCatch({
    valid_symbols <- keys(db_obj, keytype = "SYMBOL")
    invalid_genes <- cleaned_genes[!cleaned_genes %in% valid_symbols]

    if (length(invalid_genes) > 0) {
      cat("   无效的基因符号:", length(invalid_genes), "个\n")
      cat("   无效基因示例:", paste(head(invalid_genes, 10), collapse=", "), "\n")

      # 分析可能的问题
      cat("\n   可能的问题分析:\n")

      # 检查大小写问题（仅对人类基因）
      if (species == "human") {
        lower_genes <- invalid_genes[grepl("^[a-z]", invalid_genes)]
        if (length(lower_genes) > 0) {
          cat("   - 小写基因符号:", length(lower_genes), "个\n")
          cat("     示例:", paste(head(lower_genes, 5), collapse=", "), "\n")
          cat("     建议: 人类基因需要大写，尝试转换为大写\n")
        }
      }

      # 检查特殊字符
      special_char_genes <- invalid_genes[grepl("[^[:alnum:]]", invalid_genes)]
      if (length(special_char_genes) > 0) {
        cat("   - 包含特殊字符:", length(special_char_genes), "个\n")
        cat("     示例:", paste(head(special_char_genes, 5), collapse=", "), "\n")
        cat("     建议: 去除连字符、点号等特殊字符\n")
      }

      # 检查是否是ENSEMBL ID
      ensembl_genes <- invalid_genes[grepl("^ENS(MUS)?G", invalid_genes)]
      if (length(ensembl_genes) > 0) {
        cat("   - ENSEMBL ID:", length(ensembl_genes), "个\n")
        cat("     示例:", paste(head(ensembl_genes, 5), collapse=", "), "\n")
        cat("     建议: 这些是ENSEMBL ID，不是基因符号。尝试使用ENSEMBL keytype\n")
      }

      # 检查是否是ENTREZID
      entrez_genes <- invalid_genes[grepl("^[0-9]+$", invalid_genes)]
      if (length(entrez_genes) > 0) {
        cat("   - ENTREZID:", length(entrez_genes), "个\n")
        cat("     示例:", paste(head(entrez_genes, 5), collapse=", "), "\n")
        cat("     建议: 这些是ENTREZID，不是基因符号。尝试使用ENTREZID keytype\n")
      }

    } else {
      cat("   所有基因符号都是有效的SYMBOL\n")
    }

  }, error = function(e) {
    cat("   分析错误:", e$message, "\n")
  })

  # 4. 提供解决方案
  cat("\n4. 解决方案建议\n")

  best_keytype <- NULL
  best_match <- 0

  for (keytype in names(results)) {
    if (!is.null(results[[keytype]]$matched_count) && results[[keytype]]$matched_count > best_match) {
      best_match <- results[[keytype]]$matched_count
      best_keytype <- keytype
    }
  }

  if (!is.null(best_keytype) && best_match > 0) {
    cat("   推荐使用keytype:", best_keytype, "\n")
    cat("   预计可转换基因:", best_match, "个\n")
    cat("   转换成功率:", round(best_match/length(gene_symbols)*100, 1), "%\n")
  } else {
    cat("   未找到合适的keytype\n")
    cat("   可能的原因:\n")
    cat("   - 基因符号格式不正确\n")
    cat("   - 数据库不包含这些基因\n")
    cat("   - 物种选择错误\n")
  }

  # 返回结果
  return(list(
    cleaned_genes = cleaned_genes,
    results = results,
    best_keytype = best_keytype,
    best_match_count = best_match
  ))
}

# 清理基因符号函数（与主代码一致）
clean_gene_symbols <- function(gene_symbols, species_code) {
  cleaned <- trimws(gene_symbols)
  cleaned <- gsub("[\t\n\r]", "", cleaned)
  cleaned <- gsub("\\.[0-9]+$", "", cleaned)
  cleaned <- gsub("-ps$", "", cleaned, ignore.case = TRUE)
  cleaned <- gsub("-rs$", "", cleaned, ignore.case = TRUE)
  cleaned <- gsub("-as$", "", cleaned, ignore.case = TRUE)

  if (species_code == "mmu") {
    cleaned <- sapply(cleaned, function(x) {
      if (grepl("^[A-Za-z]", x)) {
        paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x))))
      } else {
        x
      }
    }, USE.NAMES = FALSE)
  } else {
    cleaned <- toupper(cleaned)
  }

  cleaned <- gsub("[^[:alnum:]]", "", cleaned)
  return(cleaned)
}

# 示例使用
if (interactive()) {
  cat("\n=== 示例使用 ===\n")

  # 示例1: 常见问题基因
  example_genes <- c(
    "TP53", "tp53", "TP-53", "TP53.1", "TP53-ps",
    "BRCA1", "brca1", "BRCA-1", "BRCA1 ",
    "ENSG00000141510", "7157", "NOT_A_GENE"
  )

  cat("\n示例1: 验证人类基因符号\n")
  result1 <- validate_gene_symbols(example_genes, "human")

  # 示例2: 小鼠基因
  mouse_genes <- c(
    "Trp53", "trp53", "Trp-53", "Trp53.2",
    "Brca1", "brca1", "Brca-1",
    "ENSMUSG00000059552", "22059"
  )

  cat("\n\n示例2: 验证小鼠基因符号\n")
  result2 <- validate_gene_symbols(mouse_genes, "mouse")

  cat("\n=== 验证完成 ===\n")
  cat("使用建议:\n")
  cat("1. 运行 validate_gene_symbols(your_genes, 'human') 验证人类基因\n")
  cat("2. 运行 validate_gene_symbols(your_genes, 'mouse') 验证小鼠基因\n")
  cat("3. 根据输出结果调整基因符号格式\n")
  cat("4. 使用推荐的keytype进行转换\n")
}