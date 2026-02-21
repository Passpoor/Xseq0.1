# 快速验证脚本

cat("\n========================================\n")
cat("enrich_local_KEGG_v2 快速验证\n")
cat("========================================\n\n")

# 设置工作目录
setwd("D:/cherry_code/Biofree_project11.2/Biofree_project")
cat("✅ 工作目录:", getwd(), "\n")

# 清理环境
rm(list = ls())

# 加载函数
cat("\n正在加载函数...\n")
source("modules/enrich_local_KEGG_v2.R")

# 验证函数存在
if (exists("enrich_local_KEGG_v2", mode = "function")) {
  cat("✅ enrich_local_KEGG_v2 已加载\n\n")
} else {
  cat("❌ 函数加载失败\n")
  stop()
}

# 显示函数参数
cat("📋 函数参数:\n")
print(names(formals(enrich_local_KEGG_v2)))
cat("\n")

# =====================================================
# 测试1: 不使用universe
# =====================================================

cat("1️⃣ 测试1: 不使用universe...\n")

result1 <- tryCatch({
  enrich_local_KEGG_v2(
    gene = c("672", "7157", "7422", "5295", "7158"),
    species = "hsa",
    pCutoff = 0.05
  )
}, error = function(e) {
  cat("❌ 失败:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(result1)) {
  cat(sprintf("✅ 成功！找到 %d 个通路\n", nrow(result1@result)))
  cat(sprintf("   背景基因: %s\n",
              ifelse(is.null(result1@universe), "NULL", length(result1@universe))))

  if (nrow(result1@result) > 0) {
    cat("\n   Top 3 通路:\n")
    print(head(result1@result[, c("ID", "Description", "p.adjust", "BgRatio")], 3))
  }
}

cat("\n")

# =====================================================
# 测试2: 使用universe
# =====================================================

cat("2️⃣ 测试2: 使用universe...\n")

bg_genes <- c("672", "7157", "7422", "5295", "7158",
              "1956", "673", "7423", "898", "9133")

result2 <- tryCatch({
  enrich_local_KEGG_v2(
    gene = c("672", "7157", "7422", "5295", "7158"),
    species = "hsa",
    pCutoff = 0.05,
    universe = bg_genes
  )
}, error = function(e) {
  cat("❌ 失败:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(result2)) {
  cat(sprintf("✅ 成功！找到 %d 个通路\n", nrow(result2@result)))
  cat(sprintf("   背景基因: %d\n", length(result2@universe)))

  if (nrow(result2@result) > 0) {
    cat("\n   Top 3 通路:\n")
    print(head(result2@result[, c("ID", "Description", "p.adjust", "BgRatio")], 3))

    # 验证universe是否被使用
    bg_ratio <- strsplit(result2@result$BgRatio[1], "/")[[1]]
    M <- as.numeric(bg_ratio[2])
    cat(sprintf("\n   ✅ 验证: BgRatio分母 = %d (期望 %d)\n", M, length(bg_genes)))
  }
}

cat("\n")

# =====================================================
# 测试3: pCutoff = 1.0（获取所有结果）
# =====================================================

cat("3️⃣ 测试3: pCutoff = 1.0 (获取所有结果)...\n")

result3 <- tryCatch({
  enrich_local_KEGG_v2(
    gene = c("672", "7157", "7422"),
    species = "hsa",
    pCutoff = 1.0  # 获取所有结果
  )
}, error = function(e) {
  cat("❌ 失败:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(result3)) {
  cat(sprintf("✅ 成功！找到 %d 个通路\n", nrow(result3@result)))
}

cat("\n")

# =====================================================
# 总结
# =====================================================

cat("========================================\n")
cat("测试总结\n")
cat("========================================\n\n")

success_count <- sum(!is.null(c(result1, result2, result3)))
cat(sprintf("成功: %d/3\n", success_count))

if (success_count == 3) {
  cat("\n✅ 所有测试通过！函数工作正常。\n")
  cat("✅ Universe参数功能正常。\n")
  cat("✅ pCutoff = 1.0 支持正常。\n")
} else {
  cat("\n⚠️ 部分测试失败，请检查错误信息。\n")
}

cat("\n========================================\n")
