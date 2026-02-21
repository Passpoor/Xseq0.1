# 测试基因符号清理函数的修复效果
cat("=== 测试基因符号清理函数 ===\n")

# 定义清理函数（与KEGG/GO模块中相同）
clean_gene_symbols <- function(gene_symbols, species_code) {
  # 清理基因符号：去除空格、特殊字符，标准化大小写
  cleaned <- trimws(gene_symbols)  # 去除首尾空格
  cleaned <- gsub("[\t\n\r]", "", cleaned)  # 去除空白字符

  # 根据物种标准化大小写
  if (species_code == "mmu") {
    # 小鼠基因：首字母大写，其余小写
    cleaned <- sapply(cleaned, function(x) {
      if (grepl("^[A-Za-z]", x)) {
        paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x))))
      } else {
        x
      }
    }, USE.NAMES = FALSE)
  } else {
    # 人类基因：全部大写
    cleaned <- toupper(cleaned)
  }

  # 去除连字符、点等特殊字符（保留字母和数字）
  cleaned <- gsub("[^[:alnum:]]", "", cleaned)

  return(cleaned)
}

# 测试数据
test_cases <- list(
  human = list(
    input = c("TP53", "tp53", "BRCA1", "brca1", "EGFR ", "EGFR\t", "BRCA-1", "myc", "ACTB", "gapdh"),
    expected = c("TP53", "TP53", "BRCA1", "BRCA1", "EGFR", "EGFR", "BRCA1", "MYC", "ACTB", "GAPDH")
  ),
  mouse = list(
    input = c("Trp53", "trp53", "Brca1", "brca1", "Egfr ", "Egfr\t", "Brca-1", "Myc", "Actb", "gapdh"),
    expected = c("Trp53", "Trp53", "Brca1", "Brca1", "Egfr", "Egfr", "Brca1", "Myc", "Actb", "Gapdh")
  )
)

# 运行测试
for (species in names(test_cases)) {
  cat("\n--- 测试", species, "基因符号清理 ---\n")

  input <- test_cases[[species]]$input
  expected <- test_cases[[species]]$expected

  species_code <- ifelse(species == "human", "hsa", "mmu")
  result <- clean_gene_symbols(input, species_code)

  cat("输入基因符号:\n")
  print(input)

  cat("\n清理后结果:\n")
  print(result)

  cat("\n期望结果:\n")
  print(expected)

  # 检查结果
  if (all(result == expected)) {
    cat("✓ 测试通过！\n")
  } else {
    cat("✗ 测试失败！\n")
    mismatches <- which(result != expected)
    for (i in mismatches) {
      cat(sprintf("  位置 %d: 输入='%s', 结果='%s', 期望='%s'\n",
                  i, input[i], result[i], expected[i]))
    }
  }
}

# 测试mapIds函数配合清理后的基因符号
cat("\n=== 测试清理后基因符号的mapIds转换 ===\n")

library(AnnotationDbi)

test_mapIds <- function(gene_symbols, species_code) {
  db_pkg <- if(species_code == "mmu") "org.Mm.eg.db" else "org.Hs.eg.db"

  if (!require(db_pkg, character.only = TRUE, quietly = TRUE)) {
    cat("数据库包", db_pkg, "未安装\n")
    return(NULL)
  }

  db_obj <- get(db_pkg)

  # 清理基因符号
  cleaned_symbols <- clean_gene_symbols(gene_symbols, species_code)

  cat("原始基因符号:", paste(gene_symbols, collapse=", "), "\n")
  cat("清理后基因符号:", paste(cleaned_symbols, collapse=", "), "\n")

  tryCatch({
    entrez_ids <- AnnotationDbi::mapIds(db_obj,
                                       keys = cleaned_symbols,
                                       column = "ENTREZID",
                                       keytype = "SYMBOL",
                                       multiVals = "first")

    cat("转换结果:\n")
    print(entrez_ids)

    # 统计成功率
    success_rate <- sum(!is.na(entrez_ids)) / length(entrez_ids) * 100
    cat(sprintf("转换成功率: %.1f%%\n", success_rate))

    return(entrez_ids)
  }, error = function(e) {
    cat("错误:", e$message, "\n")
    return(NULL)
  })
}

# 测试人类基因
cat("\n--- 测试人类基因转换 ---\n")
human_genes <- c("TP53", "tp53", "BRCA1", "BRCA-1", "EGFR ", "myc")
human_result <- test_mapIds(human_genes, "hsa")

# 测试小鼠基因
cat("\n--- 测试小鼠基因转换 ---\n")
mouse_genes <- c("Trp53", "trp53", "Brca1", "Brca-1", "Egfr ", "myc")
mouse_result <- test_mapIds(mouse_genes, "mmu")

cat("\n=== 修复总结 ===\n")
cat("1. 清理函数解决的问题:\n")
cat("   - 大小写标准化（人类：大写，小鼠：首字母大写）\n")
cat("   - 去除空格和空白字符\n")
cat("   - 去除特殊字符（连字符、点等）\n")
cat("2. 预期效果:\n")
cat("   - 提高基因符号转换成功率\n")
cat("   - 减少 'None of the keys entered are valid keys for SYMBOL' 错误\n")
cat("3. 使用建议:\n")
cat("   - 在调用mapIds或select前先清理基因符号\n")
cat("   - 确保选择正确的物种数据库\n")
cat("   - 检查数据中的基因符号格式\n")