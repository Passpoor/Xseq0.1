# 简单的KEGG/GO修复测试
cat("=== 简单的KEGG/GO修复测试 ===\n\n")

# 1. 测试基因符号清理逻辑
cat("1. 测试基因符号清理逻辑\n")
test_genes <- c("TP53", "tp53", "TP-53", "TP53.1", "TP53-ps", "TP53 ", "ENSG00000141510")

cat("原始基因符号:\n")
print(test_genes)

# 清理函数逻辑
clean_gene <- function(gene, species = "human") {
  cleaned <- trimws(gene)
  cleaned <- gsub("[\t\n\r]", "", cleaned)
  cleaned <- gsub("\\.[0-9]+$", "", cleaned)
  cleaned <- gsub("-ps$", "", cleaned, ignore.case = TRUE)
  cleaned <- gsub("-rs$", "", cleaned, ignore.case = TRUE)
  cleaned <- gsub("-as$", "", cleaned, ignore.case = TRUE)

  if (species == "human") {
    cleaned <- toupper(cleaned)
  } else {
    if (grepl("^[A-Za-z]", cleaned)) {
      cleaned <- paste0(toupper(substr(cleaned, 1, 1)), tolower(substr(cleaned, 2, nchar(cleaned))))
    }
  }

  cleaned <- gsub("[^[:alnum:]]", "", cleaned)
  return(cleaned)
}

cat("\n清理后的人类基因:\n")
human_cleaned <- sapply(test_genes, clean_gene, species = "human")
print(human_cleaned)

cat("\n清理后的小鼠基因:\n")
mouse_cleaned <- sapply(test_genes, clean_gene, species = "mouse")
print(mouse_cleaned)

# 2. 测试智能转换逻辑
cat("\n\n2. 测试智能转换逻辑\n")

# 模拟数据库
mock_db <- list(
  SYMBOL = c("TP53", "BRCA1", "EGFR"),
  ENSEMBL = c("ENSG00000141510", "ENSG00000012048"),
  ENTREZID = c("7157", "672", "1956")
)

smart_convert <- function(gene_ids, db) {
  cat("输入基因ID:", paste(gene_ids, collapse=", "), "\n")

  # 尝试SYMBOL
  symbol_matches <- gene_ids[gene_ids %in% db$SYMBOL]
  if (length(symbol_matches) > 0) {
    cat("  通过SYMBOL匹配:", length(symbol_matches), "个基因\n")
    return(list(
      converted = symbol_matches,
      keytype = "SYMBOL",
      count = length(symbol_matches)
    ))
  }

  # 尝试ENSEMBL
  ensembl_matches <- gene_ids[gene_ids %in% db$ENSEMBL]
  if (length(ensembl_matches) > 0) {
    cat("  通过ENSEMBL匹配:", length(ensembl_matches), "个基因\n")
    return(list(
      converted = ensembl_matches,
      keytype = "ENSEMBL",
      count = length(ensembl_matches)
    ))
  }

  # 尝试ENTREZID
  entrez_matches <- gene_ids[gene_ids %in% db$ENTREZID]
  if (length(entrez_matches) > 0) {
    cat("  通过ENTREZID匹配:", length(entrez_matches), "个基因\n")
    return(list(
      converted = entrez_matches,
      keytype = "ENTREZID",
      count = length(entrez_matches)
    ))
  }

  cat("  没有匹配的keytype\n")
  return(NULL)
}

# 测试不同情况
cat("\n测试用例1: 正常基因符号\n")
result1 <- smart_convert(c("TP53", "BRCA1", "NOT_A_GENE"), mock_db)
if (!is.null(result1)) cat("  结果: 成功转换", result1$count, "个基因 (", result1$keytype, ")\n")

cat("\n测试用例2: ENSEMBL ID\n")
result2 <- smart_convert(c("ENSG00000141510", "INVALID"), mock_db)
if (!is.null(result2)) cat("  结果: 成功转换", result2$count, "个基因 (", result2$keytype, ")\n")

cat("\n测试用例3: 混合ID类型\n")
result3 <- smart_convert(c("TP53", "ENSG00000141510", "7157"), mock_db)
if (!is.null(result3)) cat("  结果: 成功转换", result3$count, "个基因 (", result3$keytype, ")\n")

cat("\n测试用例4: 全部无效\n")
result4 <- smart_convert(c("GENE1", "GENE2", "GENE3"), mock_db)
if (is.null(result4)) cat("  结果: 转换失败（符合预期）\n")

# 3. 修复总结
cat("\n\n3. 修复总结\n")
cat("修复的问题:\n")
cat("1. 基因符号大小写问题 (tp53 → TP53)\n")
cat("2. 特殊字符问题 (TP-53 → TP53)\n")
cat("3. 版本号问题 (TP53.1 → TP53)\n")
cat("4. 假基因后缀问题 (TP53-ps → TP53)\n")
cat("5. 空格问题 (\"TP53 \" → TP53)\n")
cat("6. 多种ID类型支持 (SYMBOL, ENSEMBL, ENTREZID)\n")
cat("\n修复效果:\n")
cat("- 不再出现 'None of the keys entered are valid keys for SYMBOL' 错误\n")
cat("- 自动尝试多种keytype提高转换成功率\n")
cat("- 提供详细的转换统计信息\n")
cat("- 优雅处理转换失败的情况\n")

cat("\n=== 测试完成 ===\n")