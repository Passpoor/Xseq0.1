# =====================================================
# 测试 KEGG 富集分析（带数据库路径诊断）
# =====================================================

cat("\n========================================\n")
cat("测试 KEGG 富集分析\n")
cat("========================================\n\n")

# 加载补丁
setwd("D:/cherry_code/Biofree_project11.2/Biofree_project")
source("patch_biofree_qykeggtools.R")

cat("\n")

# =====================================================
# 查找 KEGG 数据库
# =====================================================

cat("🔍 搜索 KEGG 数据库文件...\n\n")

pkg_root <- system.file(package = "biofree.qyKEGGtools")
cat("包路径:", pkg_root, "\n\n")

# 搜索所有 kegg_annot.rds 文件
kegg_files <- list.files(pkg_root, pattern = "kegg_annot\\.rds$", recursive = TRUE, full.names = TRUE)

if (length(kegg_files) > 0) {
  cat("✅ 找到", length(kegg_files), "个数据库文件:\n")
  for (f in kegg_files) {
    # 提取物种信息
    species <- dirname(dirname(sub(pkg_root, "", f)))
    cat(sprintf("   - %s: %s\n", species, f))
  }
  cat("\n")

  # 使用找到的第一个数据库
  db_path <- dirname(dirname(kegg_files[1]))
  cat("使用数据库路径:", db_path, "\n\n")

} else {
  cat("❌ 未找到 kegg_annot.rds 文件\n")
  cat("尝试其他路径...\n\n")

  # 检查常见的可能位置
  possible_paths <- c(
    file.path(pkg_root, "extdata"),
    pkg_root,
    file.path(dirname(pkg_root), "biofree.qyKEGGtools", "extdata")
  )

  for (path in possible_paths) {
    if (dir.exists(path)) {
      cat("检查路径:", path, "\n")
      subdirs <- list.dirs(path, recursive = FALSE, full.names = FALSE)
      cat("  子目录:", paste(subdirs, collapse = ", "), "\n")
      cat("\n")
    }
  }

  stop("无法找到 KEGG 数据库，请先运行 biofree.qyKEGGtools::update_local_kegg()")
}

# =====================================================
# 运行测试
# =====================================================

cat("2️⃣ 运行 KEGG 富集分析测试...\n\n")

# 测试基因
test_genes <- c("672", "7157", "7422", "5295", "7158")
test_universe <- c("672", "7157", "7422", "5295", "7158",
                   "1956", "673", "7423", "898", "9133")

tryCatch({
  result <- enrich_local_KEGG(
    gene = test_genes,
    species = "hsa",
    pCutoff = 0.05,
    universe = test_universe,
    db_dir = db_path  # ✨ 使用找到的数据库路径
  )

  cat(sprintf("\n✅ 成功！找到 %d 个富集通路\n\n", nrow(result@result)))

  if (nrow(result@result) > 0) {
    cat("Top 5 通路:\n")
    print(head(result@result[, c("ID", "Description", "p.adjust", "Count")], 5))
  }

}, error = function(e) {
  cat(sprintf("\n❌ 失败: %s\n", conditionMessage(e)))

  cat("\n💡 可能的解决方案:\n")
  cat("   1. 运行 biofree.qyKEGGtools::update_local_kegg() 下载最新数据库\n")
  cat("   2. 检查数据库是否在预期位置\n")
  cat("   3. 尝试手动指定 db_dir 参数\n")
})

cat("\n========================================\n")
