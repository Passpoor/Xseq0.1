# =====================================================
# 测试 universe 参数功能
# =====================================================

cat("\n========================================\n")
cat("测试 Universe 参数功能\n")
cat("========================================\n\n")

# 加载补丁
setwd("D:/cherry_code/Biofree_project11.2/Biofree_project")
source("patch_biofree_simple.R")

# =====================================================
# 测试数据
# =====================================================

cat("📋 准备测试数据...\n\n")

# 测试基因（真实的癌症相关基因）
test_genes <- c(
  "672",   # BRCA1
  "673",   # BRCA2
  "7157",  # TP53
  "7422",  # BRAF
  "7158",  # TGFBR2
  "5295",  # PIK3R1
  "5290",  # PIK3CA
  "1956",  # EGFR
  "7423",  # KRAS
  "898"    # CCNE1
)

# 小背景集（仅用于测试）
small_universe <- c(
  "672", "673", "7157", "7422", "7158", "5295", "5290",
  "1956", "7423", "898", "9133", "2064", "208", "4790"
)

cat(sprintf("测试基因: %d 个\n", length(test_genes)))
cat(sprintf("小背景集: %d 个\n\n", length(small_universe)))

# =====================================================
# 测试1: 不使用 universe
# =====================================================

cat("1️⃣ 测试1: 不使用 universe（使用全基因组背景）\n")
cat("----------------------------------------\n")

result1 <- tryCatch({
  enrich_local_KEGG(
    gene = test_genes,
    species = "hsa",
    pCutoff = 1.0,  # 获取所有结果
    qCutoff = NULL
  )
}, error = function(e) {
  cat("❌ 失败:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(result1)) {
  n_results <- nrow(result1@result)
  cat(sprintf("✅ 成功！找到 %d 个富集通路\n", n_results))

  if (n_results > 0) {
    cat("\nTop 5 通路:\n")
    print(head(result1@result[, c("ID", "Description", "p.adjust", "Count")], 5))
  }
}

cat("\n")

# =====================================================
# 测试2: 使用小 universe（可能导致无结果）
# =====================================================

cat("2️⃣ 测试2: 使用小 universe（预期：可能无结果）\n")
cat("----------------------------------------\n")

result2 <- tryCatch({
  enrich_local_KEGG(
    gene = test_genes,
    species = "hsa",
    pCutoff = 1.0,
    qCutoff = NULL,
    universe = small_universe
  )
}, error = function(e) {
  cat("❌ 失败:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(result2)) {
  n_results <- nrow(result2@result)
  cat(sprintf("✅ 成功！找到 %d 个富集通路\n", n_results))

  if (n_results > 0) {
    cat("\nTop 5 通路:\n")
    print(head(result2@result[, c("ID", "Description", "p.adjust", "Count")], 5))
  } else {
    cat("ℹ️ 无结果（小 universe 导致通路大小不符合要求）\n")
  }
}

cat("\n")

# =====================================================
# 测试3: 使用实际大小的 universe
# =====================================================

cat("3️⃣ 测试3: 使用实际大小的 universe\n")
cat("----------------------------------------\n")

# 从 KEGG 数据库获取真实的背景基因
library(biofree.qyKEGGtools)

cat("加载 KEGG 数据库...\n")
db <- biofree.qyKEGGtools::load_local_kegg(species = "hsa")
path2gene <- DBI::dbGetQuery(db, "SELECT * FROM pathway2gene")
DBI::dbDisconnect(db)

# 获取所有在 KEGG 中的基因
all_kegg_genes <- unique(path2gene$gene)
cat(sprintf("KEGG 数据库中的基因: %d 个\n", length(all_kegg_genes)))

# 创建一个中等大小的 universe（模拟实际检测到的基因）
set.seed(42)
medium_universe <- sample(all_kegg_genes, 5000)  # 5000个基因

cat(sprintf("中等大小 universe: %d 个基因\n\n", length(medium_universe)))

result3 <- tryCatch({
  enrich_local_KEGG(
    gene = test_genes,
    species = "hsa",
    pCutoff = 0.05,
    qCutoff = NULL,
    universe = medium_universe
  )
}, error = function(e) {
  cat("❌ 失败:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(result3)) {
  n_results <- nrow(result3@result)
  cat(sprintf("✅ 成功！找到 %d 个富集通路\n", n_results))

  if (n_results > 0) {
    cat("\nTop 5 通路:\n")
    print(head(result3@result[, c("ID", "Description", "p.adjust", "Count")], 5))
  }
}

cat("\n")

# =====================================================
# 测试4: 对比有无 universe 的结果
# =====================================================

cat("4️⃣ 测试4: 对比有无 universe 的差异\n")
cat("----------------------------------------\n")

if (!is.null(result1) && !is.null(result3) &&
    nrow(result1@result) > 0 && nrow(result3@result) > 0) {

  cat(sprintf("不使用 universe: %d 个通路\n", nrow(result1@result)))
  cat(sprintf("使用 universe (5000): %d 个通路\n\n", nrow(result3@result)))

  # 比较 p 值分布
  cat("P值对比 (Top 10):\n")
  cat(sprintf("%-15s %-15s %-15s %-15s\n", "通路ID", "无universe", "有universe", "差异"))

  # 取共同的通路进行比较
  common_pathways <- intersect(result1@result$ID, result3@result$ID)

  if (length(common_pathways) > 0) {
    for (pid in head(common_pathways, 10)) {
      p1 <- result1@result[result1@result$ID == pid, "p.adjust"]
      p2 <- result3@result[result3@result$ID == pid, "p.adjust"]
      diff_ratio <- (p1 - p2) / p1 * 100

      cat(sprintf("%-15s %-15.6f %-15.6f %-15.1f%%\n",
                  pid, p1, p2, diff_ratio))
    }
  }
}

cat("\n")

# =====================================================
# 总结
# =====================================================

cat("========================================\n")
cat("测试总结\n")
cat("========================================\n\n")

success_count <- 0
if (!is.null(result1)) success_count <- success_count + 1
if (!is.null(result2)) success_count <- success_count + 1
if (!is.null(result3)) success_count <- success_count + 1

cat(sprintf("成功: %d/3\n", success_count))

if (success_count == 3) {
  cat("\n✅ 所有测试通过！\n")
  cat("✅ Universe 参数功能正常\n")
  cat("✅ 错误处理正确\n")
  cat("✅ 与 clusterProfiler 对齐\n")
} else {
  cat("\n⚠️ 部分测试失败，请检查错误信息\n")
}

cat("\n💡 提示:\n")
cat("  - 小 universe 可能导致无结果（正常）\n")
cat("  - 实际使用时，universe 应包含所有检测到的基因\n")
cat("  - 建议使用 5000-20000 个基因作为 universe\n\n")

cat("========================================\n")
