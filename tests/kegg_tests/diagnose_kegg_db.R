# 深度诊断 KEGG 数据库问题

cat("\n========================================\n")
cat("深度诊断 KEGG 数据库\n")
cat("========================================\n\n")

# 加载包
library(biofree.qyKEGGtools)

# =====================================================
# 步骤1：查看 update_local_kegg 的实际行为
# =====================================================

cat("1️⃣ 分析 update_local_kegg() 函数...\n\n")

# 查看函数源码
func_source <- capture.output(print(biofree.qyKEGGtools::update_local_kegg))
cat("函数源码（前50行）:\n")
cat(paste(head(func_source, 50), collapse = "\n"), "\n\n")

# =====================================================
# 步骤2：检查函数实际使用的路径
# =====================================================

cat("2️⃣ 检查函数内部的路径配置...\n\n")

# 尝试查找配置信息
pkg_env <- environment(biofree.qyKEGGtools::update_local_kegg)

# 检查环境中的变量
env_vars <- ls(envir = pkg_env)
cat("函数环境中的变量:\n")
for (v in env_vars) {
  val <- get(v, envir = pkg_env)
  cat(sprintf("   %s: %s\n", v, class(val)[1]))
}

cat("\n")

# =====================================================
# 步骤3：检查可能的数据库存储位置
# =====================================================

cat("3️⃣ 检查所有可能的数据库位置...\n\n")

possible_locations <- list(
  "包extdata目录" = system.file("extdata", package = "biofree.qyKEGGtools"),
  "包根目录" = system.file(package = "biofree.qyKEGGtools"),
  "当前工作目录" = getwd(),
  "用户主目录" = path.expand("~"),
  "临时目录" = tempdir()
)

for (name in names(possible_locations)) {
  loc <- possible_locations[[name]]
  cat(sprintf("\n%s:\n", name))
  cat(sprintf("   路径: %s\n", loc))

  if (dir.exists(loc)) {
    # 查找 kegg 相关文件
    kegg_files <- list.files(loc, pattern = "kegg", recursive = TRUE, full.names = FALSE)
    if (length(kegg_files) > 0) {
      cat("   找到KEGG相关文件:\n")
      for (f in head(kegg_files, 10)) {
        cat(sprintf("     - %s\n", f))
      }
      if (length(kegg_files) > 10) {
        cat(sprintf("     ... 还有 %d 个文件\n", length(kegg_files) - 10))
      }
    }

    # 查找 .rds 文件
    rds_files <- list.files(loc, pattern = "\\.rds$", recursive = TRUE, full.names = FALSE)
    if (length(rds_files) > 0) {
      cat("   找到 .rds 文件:\n")
      for (f in head(rds_files, 10)) {
        fpath <- file.path(loc, f)
        if (file.exists(fpath)) {
          fsize <- file.info(fpath)$size
          cat(sprintf("     - %s (%.2f MB)\n", f, fsize/1024/1024))
        }
      }
      if (length(rds_files) > 10) {
        cat(sprintf("     ... 还有 %d 个文件\n", length(rds_files) - 10))
      }
    }
  } else {
    cat("   (目录不存在)\n")
  }
}

cat("\n")

# =====================================================
# 步骤4：检查 update_local_kegg 的选项
# =====================================================

cat("4️⃣ 检查包的选项配置...\n\n")

# 查看包相关的选项
pkg_options <- grep("biofree|kegg", names(options()), value = TRUE, ignore.case = TRUE)

if (length(pkg_options) > 0) {
  cat("找到包相关的选项:\n")
  for (opt in pkg_options) {
    cat(sprintf("   %s: %s\n", opt, as.character(options()[[opt]])))
  }
} else {
  cat("未找到包相关的选项\n")
}

cat("\n")

# =====================================================
# 步骤5：尝试实际调用函数并观察
# =====================================================

cat("5️⃣ 测试实际数据库访问...\n\n")

# 尝试手动构造数据库路径
test_species <- "hsa"

cat(sprintf("测试物种: %s\n\n", test_species))

# 方法1：默认路径
db_dir1 <- system.file("extdata", package = "biofree.qyKEGGtools")
db_file1 <- file.path(db_dir1, test_species, "kegg_annot.rds")
cat(sprintf("方法1 (默认路径):\n"))
cat(sprintf("   路径: %s\n", db_file1))
cat(sprintf("   存在: %s\n\n", ifelse(file.exists(db_file1), "✅", "❌")))

# 方法2：包根目录
db_dir2 <- system.file(package = "biofree.qyKEGGtools")
db_file2 <- file.path(db_dir2, test_species, "kegg_annot.rds")
cat(sprintf("方法2 (包根目录):\n"))
cat(sprintf("   路径: %s\n", db_file2))
cat(sprintf("   存在: %s\n\n", ifelse(file.exists(db_file2), "✅", "❌")))

# 方法3：直接查找
cat("方法3 (递归搜索):\n")
pkg_root <- system.file(package = "biofree.qyKEGGtools")
found_files <- list.files(pkg_root, pattern = "kegg_annot\\.rds$", recursive = TRUE)

if (length(found_files) > 0) {
  cat("   找到数据库文件:\n")
  for (f in found_files) {
    fpath <- file.path(pkg_root, f)
    cat(sprintf("     - %s\n", fpath))
  }
} else {
  cat("   未找到任何 kegg_annot.rds 文件\n")
}

cat("\n")

# =====================================================
# 步骤6：查看包的文件列表
# =====================================================

cat("6️⃣ 列出包的所有文件...\n\n")

pkg_root <- system.file(package = "biofree.qyKEGGtools")
all_files <- list.files(pkg_root, recursive = TRUE)

cat(sprintf("包目录: %s\n", pkg_root))
cat(sprintf("总文件数: %d\n\n", length(all_files)))

if (length(all_files) > 0) {
  cat("文件列表 (前50个):\n")
  for (f in head(all_files, 50)) {
    cat(sprintf("   %s\n", f))
  }

  if (length(all_files) > 50) {
    cat(sprintf("\n... 还有 %d 个文件\n", length(all_files) - 50))
  }
}

cat("\n")

# =====================================================
# 步骤7：检查是否需要手动指定 db_dir
# =====================================================

cat("7️⃣ 建议的解决方案...\n\n")

cat("基于以上诊断，如果数据库文件存在但不在默认位置，\n")
cat("你需要在使用函数时显式指定 db_dir 参数：\n\n")

cat("例如:\n")
cat("  result <- enrich_local_KEGG(\n")
cat("    gene = your_genes,\n")
cat("    species = 'hsa',\n")
cat("    db_dir = '/path/to/kegg/database'  # ✨ 指定实际路径\n")
cat("  )\n\n")

cat("========================================\n")
cat("诊断完成\n")
cat("========================================\n")
