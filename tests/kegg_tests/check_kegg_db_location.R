# 检查 biofree.qyKEGGtools KEGG 数据库位置

cat("\n========================================\n")
cat("检查 KEGG 数据库位置\n")
cat("========================================\n\n")

# 加载包
library(biofree.qyKEGGtools)

# 1. 检查包路径
pkg_path <- system.file(package = "biofree.qyKEGGtools")
cat("📁 包路径:\n")
cat("   ", pkg_path, "\n\n")

# 2. 检查 extdata 目录
extdata_path <- system.file("extdata", package = "biofree.qyKEGGtools")
cat("📁 extdata 路径:\n")
cat("   ", extdata_path, "\n\n")

# 3. 列出 extdata 下的所有文件
if (extdata_path != "" && dir.exists(extdata_path)) {
  cat("📋 extdata 目录内容:\n")
  all_files <- list.files(extdata_path, recursive = TRUE, full.names = FALSE)
  if (length(all_files) > 0) {
    for (f in head(all_files, 20)) {
      cat("   ", f, "\n")
    }
    if (length(all_files) > 20) {
      cat("   ... (还有", length(all_files) - 20, "个文件)\n")
    }
  } else {
    cat("   (空目录)\n")
  }
} else {
  cat("⚠️ extdata 目录不存在\n\n")
}

cat("\n")

# 4. 搜索整个包目录中的 .rds 文件
cat("🔍 搜索 .rds 文件:\n")
rds_files <- list.files(pkg_path, pattern = "\\.rds$", recursive = TRUE, full.names = TRUE)

if (length(rds_files) > 0) {
  for (f in rds_files) {
    file_size <- file.info(f)$size
    cat(sprintf("   %s (%.1f MB)\n", f, file_size / 1024 / 1024))
  }
} else {
  cat("   (未找到 .rds 文件)\n")
}

cat("\n")

# 5. 检查是否有 hsa, mmu, rno 目录
species_dirs <- c("hsa", "mmu", "rno")
cat("📂 检查物种目录:\n")
for (sp in species_dirs) {
  sp_dir <- file.path(extdata_path, sp)
  if (dir.exists(sp_dir)) {
    cat(sprintf("   ✅ %s 存在\n", sp))
    # 列出该目录下的文件
    sp_files <- list.files(sp_dir)
    for (f in sp_files) {
      cat("      -", f, "\n")
    }
  } else {
    cat(sprintf("   ❌ %s 不存在\n", sp))
  }
}

cat("\n")

# 6. 尝试调用 update_local_kegg 并观察行为
cat("🔄 测试 update_local_kegg():\n")
cat("（不实际下载，只检查其行为）\n\n")

# 查看函数源码（简要）
func_body <- body(biofree.qyKEGGtools::update_local_kegg)
cat("update_local_kegg 函数存在: ", !is.null(func_body), "\n\n")

# 7. 检查是否有其他可能的数据库位置
cat("🔍 检查其他可能的位置:\n\n")

# 用户主目录
home_dir <- path.expand("~")
cat("用户主目录:\n")
cat("   ", home_dir, "\n\n")

# 检查是否有 .biofree 或类似目录
hidden_dirs <- list.files(home_dir, pattern = "^\\.", full.names = TRUE)
biofree_dirs <- grep("biofree|kegg", hidden_dirs, value = TRUE, ignore.case = TRUE)

if (length(biofree_dirs) > 0) {
  cat("找到可能的数据库目录:\n")
  for (d in biofree_dirs) {
    cat("   ", d, "\n")
  }
} else {
  cat("未找到 .biofree 或类似目录\n")
}

cat("\n")

# 8. 检查 Temp 目录
temp_dir <- tempdir()
cat("临时目录:\n")
cat("   ", temp_dir, "\n\n")

cat("========================================\n")
cat("检查完成\n")
cat("========================================\n")
