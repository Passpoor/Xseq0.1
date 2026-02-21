# 查找实际的 SQLite 数据库

cat("\n========================================\n")
cat("查找 KEGG SQLite 数据库\n")
cat("========================================\n\n")

# 检查 ~/biofree_KEGG_mirror
db_dir <- path.expand("~/biofree_KEGG_mirror")
cat("默认数据库目录:\n")
cat("  ", db_dir, "\n\n")

if (dir.exists(db_dir)) {
  cat("✅ 目录存在\n\n")

  # 列出文件
  files <- list.files(db_dir, full.names = FALSE)
  cat("文件列表:\n")
  for (f in files) {
    fpath <- file.path(db_dir, f)
    if (dir.exists(fpath)) {
      cat(sprintf("  [DIR] %s\n", f))
    } else {
      fsize <- file.info(fpath)$size
      cat(sprintf("  [FILE] %s (%.2f MB)\n", f, fsize/1024/1024))
    }
  }
} else {
  cat("❌ 目录不存在\n\n")

  cat("尝试查找其他可能的位置...\n\n")

  # 在用户主目录中搜索
  home_dir <- path.expand("~")
  sqlite_files <- list.files(home_dir, pattern = "\\.sqlite$", recursive = TRUE, full.names = TRUE)

  if (length(sqlite_files) > 0) {
    cat("✅ 找到 SQLite 文件:\n")
    for (f in sqlite_files) {
      if (grepl("KEGG|kegg", f)) {
        fsize <- file.info(f)$size
        cat(sprintf("  - %s (%.2f MB)\n", f, fsize/1024/1024))
      }
    }
  } else {
    cat("❌ 未找到任何 SQLite 数据库\n")
  }
}

cat("\n")

# 检查 enrich_local_KEGG 函数如何加载数据
cat("========================================\n")
cat("检查 enrich_local_KEGG 实现\n")
cat("========================================\n\n")

cat("查看 load_local_kegg 函数...\n")
print(body(biofree.qyKEGGtools::load_local_kegg))

cat("\n")
