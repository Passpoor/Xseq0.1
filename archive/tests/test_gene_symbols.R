# 测试基因符号转换问题
library(AnnotationDbi)

# 测试人类基因符号
test_human_symbols <- function() {
  cat("=== 测试人类基因符号转换 ===\n")

  if (!require("org.Hs.eg.db", quietly = TRUE)) {
    cat("请先安装 org.Hs.eg.db 包\n")
    return(FALSE)
  }

  # 测试一些常见的人类基因符号
  test_symbols <- c("TP53", "BRCA1", "EGFR", "MYC", "ACTB", "GAPDH", "NOT_A_GENE")

  cat("测试基因符号:", paste(test_symbols, collapse=", "), "\n")

  tryCatch({
    # 使用select函数
    result <- select(org.Hs.eg.db,
                     keys = test_symbols,
                     columns = c("ENTREZID", "SYMBOL"),
                     keytype = "SYMBOL")

    cat("成功转换的基因:\n")
    print(result)

    # 使用mapIds函数
    cat("\n使用mapIds函数:\n")
    entrez_ids <- mapIds(org.Hs.eg.db,
                        keys = test_symbols,
                        column = "ENTREZID",
                        keytype = "SYMBOL",
                        multiVals = "first")
    print(entrez_ids)

    return(TRUE)
  }, error = function(e) {
    cat("错误:", e$message, "\n")
    return(FALSE)
  })
}

# 测试小鼠基因符号
test_mouse_symbols <- function() {
  cat("\n=== 测试小鼠基因符号转换 ===\n")

  if (!require("org.Mm.eg.db", quietly = TRUE)) {
    cat("请先安装 org.Mm.eg.db 包\n")
    return(FALSE)
  }

  # 测试一些常见的小鼠基因符号
  test_symbols <- c("Trp53", "Brca1", "Egfr", "Myc", "Actb", "Gapdh", "NOT_A_GENE")

  cat("测试基因符号:", paste(test_symbols, collapse=", "), "\n")

  tryCatch({
    # 使用select函数
    result <- select(org.Mm.eg.db,
                     keys = test_symbols,
                     columns = c("ENTREZID", "SYMBOL"),
                     keytype = "SYMBOL")

    cat("成功转换的基因:\n")
    print(result)

    # 使用mapIds函数
    cat("\n使用mapIds函数:\n")
    entrez_ids <- mapIds(org.Mm.eg.db,
                        keys = test_symbols,
                        column = "ENTREZID",
                        keytype = "SYMBOL",
                        multiVals = "first")
    print(entrez_ids)

    return(TRUE)
  }, error = function(e) {
    cat("错误:", e$message, "\n")
    return(FALSE)
  })
}

# 检查可用的keytypes
check_keytypes <- function() {
  cat("\n=== 检查可用的keytypes ===\n")

  if (require("org.Hs.eg.db", quietly = TRUE)) {
    cat("人类数据库可用的keytypes:\n")
    print(keytypes(org.Hs.eg.db))
  }

  if (require("org.Mm.eg.db", quietly = TRUE)) {
    cat("\n小鼠数据库可用的keytypes:\n")
    print(keytypes(org.Mm.eg.db))
  }
}

# 运行测试
cat("开始基因符号转换测试...\n")
human_ok <- test_human_symbols()
mouse_ok <- test_mouse_symbols()
check_keytypes()

cat("\n=== 测试总结 ===\n")
cat("人类基因符号测试:", ifelse(human_ok, "通过", "失败"), "\n")
cat("小鼠基因符号测试:", ifelse(mouse_ok, "通过", "失败"), "\n")

# 检查实际数据中的问题
cat("\n=== 检查实际数据问题 ===\n")
cat("请检查你的数据中是否包含以下问题：\n")
cat("1. 基因符号大小写问题（人类：大写，小鼠：首字母大写）\n")
cat("2. 基因符号包含特殊字符或空格\n")
cat("3. 基因符号是ENSEMBL ID而不是基因符号\n")
cat("4. 数据库包未正确安装\n")