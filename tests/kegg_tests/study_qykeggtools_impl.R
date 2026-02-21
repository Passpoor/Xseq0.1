# 深入研究 biofree.qyKEGGtools 的实际实现

cat("\n========================================\n")
cat("研究 biofree.qyKEGGtools 实现\n")
cat("========================================\n\n")

library(biofree.qyKEGGtools)

# =====================================================
# 查看 load_local_kegg 函数
# =====================================================

cat("1️⃣ load_local_kegg 函数源码:\n")
cat("========================================\n\n")

load_local_source <- capture.output(print(biofree.qyKEGGtools::load_local_kegg))
cat(paste(load_local_source, collapse = "\n"))
cat("\n\n")

# =====================================================
# 查看 enrich_local_KEGG 函数
# =====================================================

cat("2️⃣ enrich_local_KEGG 函数源码:\n")
cat("========================================\n\n")

enrich_source <- capture.output(print(biofree.qyKEGGtools::enrich_local_KEGG))
cat(paste(enrich_source, collapse = "\n"))
cat("\n\n")

# =====================================================
# 测试 load_local_kegg
# =====================================================

cat("3️⃣ 测试 load_local_kegg:\n")
cat("========================================\n\n")

tryCatch({
  # 使用默认路径
  cat("尝试加载 hsa 数据库（默认路径）...\n")
  kegg_data <- biofree.qyKEGGtools::load_local_kegg(species = "hsa")
  cat("✅ 成功加载数据库\n\n")

  cat("数据库结构:\n")
  cat("  类:", class(kegg_data), "\n")
  cat("  字段:", names(kegg_data), "\n\n")

}, error = function(e) {
  cat(sprintf("❌ 失败: %s\n\n", conditionMessage(e)))

  cat("尝试指定 db_dir 参数...\n")
  db_dir <- path.expand("~/biofree_KEGG_mirror")
  cat(sprintf("使用 db_dir: %s\n", db_dir))

  if (dir.exists(db_dir)) {
    tryCatch({
      kegg_data <- biofree.qyKEGGtools::load_local_kegg(
        species = "hsa",
        db_dir = db_dir
      )
      cat("✅ 成功加载数据库\n\n")

      cat("数据库结构:\n")
      cat("  类:", class(kegg_data), "\n")
      cat("  字段:", names(kegg_data), "\n\n")

    }, error = function(e2) {
      cat(sprintf("❌ 仍然失败: %s\n", conditionMessage(e2)))
    })
  }
})

cat("\n")
