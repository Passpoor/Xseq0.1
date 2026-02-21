# =====================================================
# 测试 biofree.qyKEGGtools 包的可用性
# =====================================================

cat("======================================\n")
cat("biofree.qyKEGGtools 包测试\n")
cat("======================================\n\n")

# 1. 检查包是否已安装
cat("1️⃣ 检查包安装状态...\n")
if (require("biofree.qyKEGGtools", quietly = TRUE)) {
  cat("✅ biofree.qyKEGGtools 已安装\n\n")

  # 显示包版本
  pkg_version <- packageVersion("biofree.qyKEGGtools")
  cat(sprintf("📦 包版本: %s\n\n", pkg_version))

} else {
  cat("❌ biofree.qyKEGGtools 未安装\n")
  cat("请运行以下命令安装:\n")
  cat("  install.packages('biofree.qyKEGGtools')\n")
  cat("  # 或从GitHub安装\n")
  cat("  devtools::install_git('https://github.com/biofree/biofree.qyKEGGtools.git')\n")
  stop("包未安装，测试终止")
}

# 2. 检查 enrich_local_KEGG 函数
cat("2️⃣ 检查 enrich_local_KEGG 函数...\n")
if (exists("enrich_local_KEGG", mode = "function")) {
  cat("✅ enrich_local_KEGG 函数存在\n\n")

  # 查看函数参数
  cat("📋 函数参数:\n")
  func_args <- formals(biofree.qyKEGGtools::enrich_local_KEGG)
  print(names(func_args))
  cat("\n")

} else {
  cat("❌ enrich_local_KEGG 函数不存在\n")
}

# 3. 检查函数文档
cat("3️⃣ 查看函数文档...\n")
tryCatch({
  help_doc <- help("enrich_local_KEGG", package = "biofree.qyKEGGtools")
  cat("✅ 函数文档可用\n")
  cat("请使用 ?enrich_local_KEGG 查看完整文档\n\n")
}, error = function(e) {
  cat("⚠️ 无法查看文档:", e$message, "\n\n")
})

# 4. 测试函数调用（使用示例数据）
cat("4️⃣ 测试函数调用（使用示例基因）...\n")

# 示例基因列表（人类）
test_genes <- c("672", "7157", "7422", "5295", "7158")  # TP53, TGFBR1, BRAF, PIK3R1, TGFBR2

cat(sprintf("📊 测试基因数量: %d\n", length(test_genes)))
cat(sprintf("📊 测试基因示例: %s\n", paste(head(test_genes, 3), collapse = ", ")))

tryCatch({
  # 调用函数
  result <- biofree.qyKEGGtools::enrich_local_KEGG(
    gene = test_genes,
    species = "hsa",
    pCutoff = 0.05
  )

  cat("✅ 函数调用成功\n\n")

  # 显示结果
  if (!is.null(result)) {
    cat(sprintf("📊 结果类型: %s\n", class(result)[1]))

    if (inherits(result, "enrichResult")) {
      result_df <- result@result
      cat(sprintf("📊 富集通路数量: %d\n", nrow(result_df)))

      if (nrow(result_df) > 0) {
        cat("\nTop 5 富集通路:\n")
        print(head(result_df[, c("ID", "Description", "p.adjust", "geneID")], 5))
      }
    } else if (is.data.frame(result)) {
      cat(sprintf("📊 结果数据框行数: %d\n", nrow(result)))
      if (nrow(result) > 0) {
        cat("\nTop 5 行:\n")
        print(head(result, 5))
      }
    }
  } else {
    cat("⚠️ 返回结果为 NULL\n")
  }

}, error = function(e) {
  cat("❌ 函数调用失败\n")
  cat(sprintf("错误信息: %s\n", e$message))
  cat("\n可能的原因:\n")
  cat("  1. 基因ID格式不正确（需要ENTREZ ID）\n")
  cat("  2. 本地KEGG数据库未安装或不完整\n")
  cat("  3. 物种代码不支持\n")
})

cat("\n======================================\n")
cat("测试完成\n")
cat("======================================\n")
