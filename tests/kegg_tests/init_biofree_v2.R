# =====================================================
# biofree.qyKEGGtools 正确的初始化流程
# 基于实际的 SQLite 数据库实现
# =====================================================

cat("\n========================================\n")
cat("biofree.qyKEGGtools v2.0 正确初始化\n")
cat("========================================\n\n")

# =====================================================
# 步骤1：检查包
# =====================================================

cat("1️⃣ 检查包状态...\n")

if (!require("biofree.qyKEGGtools", quietly = TRUE)) {
  cat("❌ 包未安装，请先安装:\n")
  cat("   remotes::install_github('Passpoor/biofree.qykeggtools')\n")
  stop("包未安装")
}

pkg_version <- packageVersion("biofree.qyKEGGtools")
cat(sprintf("✅ biofree.qyKEGGtools v%s\n", pkg_version))
cat("\n")

# =====================================================
# 步骤2：下载/更新 SQLite 数据库
# =====================================================

cat("2️⃣ 更新 KEGG 数据库...\n")
cat("（数据库格式: SQLite）\n")
cat("（默认路径: ~/biofree_KEGG_mirror）\n\n")

# 使用默认的 db_dir
default_db_dir <- "~/biofree_KEGG_mirror"
cat(sprintf("数据库目录: %s\n", path.expand(default_db_dir)))

tryCatch({
  biofree.qyKEGGtools::update_local_kegg(
    species = "hsa",
    db_dir = default_db_dir
  )
  cat("\n✅ 数据库更新完成\n\n")
}, error = function(e) {
  cat(sprintf("\n❌ 更新失败: %s\n", conditionMessage(e)))

  # 检查是否缺少依赖
  if (!requireNamespace("createKEGGdb", quietly = TRUE)) {
    cat("\n💡 需要安装 createKEGGdb:\n")
    cat("   remotes::install_github('PasBio/free_createKEGGdb')\n")
  }

  stop("数据库更新失败")
})

# =====================================================
# 步骤3：验证数据库
# =====================================================

cat("3️⃣ 验证数据库...\n\n")

db_dir <- path.expand(default_db_dir)

if (!dir.exists(db_dir)) {
  cat(sprintf("❌ 数据库目录不存在: %s\n", db_dir))
  stop("数据库目录不存在")
}

# 查找 SQLite 文件
sqlite_files <- list.files(db_dir, pattern = "\\.sqlite$", full.names = TRUE)

if (length(sqlite_files) == 0) {
  cat("❌ 未找到 SQLite 数据库文件\n")
  stop("数据库文件不存在")
}

cat(sprintf("✅ 找到 %d 个数据库文件:\n", length(sqlite_files)))
for (f in sqlite_files) {
  fsize <- file.info(f)$size
  cat(sprintf("   - %s (%.2f MB)\n", basename(f), fsize/1024/1024))
}
cat("\n")

# =====================================================
# 步骤4：测试数据库加载
# =====================================================

cat("4️⃣ 测试数据库加载...\n\n")

tryCatch({
  kegg_data <- biofree.qyKEGGtools::load_local_kegg(
    species = "hsa",
    db_dir = db_dir
  )

  cat("✅ 数据库加载成功\n")
  cat(sprintf("   数据类型: %s\n", class(kegg_data)[1]))
  cat(sprintf("   包含字段: %s\n", paste(names(kegg_data), collapse = ", ")))
  cat("\n")

  # 检查必要字段
  required_fields <- c("pathway2gene", "pathway_info", "all_genes")
  missing_fields <- required_fields[!required_fields %in% names(kegg_data)]

  if (length(missing_fields) > 0) {
    cat(sprintf("⚠️ 缺少字段: %s\n", paste(missing_fields, collapse = ", ")))
  } else {
    cat("✅ 所有必要字段都存在\n")
  }

}, error = function(e) {
  cat(sprintf("❌ 数据库加载失败: %s\n", conditionMessage(e)))
  stop("数据库加载失败")
})

cat("\n")

# =====================================================
# 步骤5：测试原始 enrich_local_KEGG
# =====================================================

cat("5️⃣ 测试原始 enrich_local_KEGG...\n\n")

test_genes <- c("672", "7157", "7422", "5295", "7158")

tryCatch({
  result <- biofree.qyKEGGtools::enrich_local_KEGG(
    gene = test_genes,
    species = "hsa",
    db_dir = db_dir,
    pCutoff = 0.05
  )

  cat(sprintf("✅ 富集分析成功！找到 %d 个通路\n\n", nrow(result@result)))

  if (nrow(result@result) > 0) {
    cat("Top 3 通路:\n")
    print(head(result@result[, c("ID", "Description", "p.adjust", "Count")], 3))
  }

}, error = function(e) {
  cat(sprintf("❌ 富集分析失败: %s\n", conditionMessage(e)))
})

cat("\n")

# =====================================================
# 步骤6：应用 universe 补丁（使用正确的数据库路径）
# =====================================================

cat("6️⃣ 应用 universe 补丁...\n\n")

if (file.exists("patch_biofree_qykeggtools.R")) {
  # 加载补丁
  source("patch_biofree_qykeggtools.R")

  cat("✅ 补丁已加载\n")
  cat(sprintf("💡 提示: 使用 enrich_local_KEGG 时，需要指定 db_dir:\n"))
  cat(sprintf("   db_dir = '%s'\n\n", db_dir))

} else {
  cat("⚠️ 未找到补丁文件\n\n")
}

# =====================================================
# 完成
# =====================================================

cat("========================================\n")
cat("初始化完成！\n")
cat("========================================\n\n")

cat("✅ biofree.qyKEGGtools 已正确配置\n")
cat("✅ KEGG SQLite 数据库已下载\n")
cat(sprintf("✅ 数据库路径: %s\n\n", db_dir))

cat("📝 使用方法:\n")
cat("--------------------------------\n")
cat("方法1: 使用原始函数（需要指定 db_dir）\n\n")
cat("  result <- biofree.qyKEGGtools::enrich_local_kegg(\n")
cat("    gene = your_genes,\n")
cat("    species = 'hsa',\n")
cat("    db_dir = '~/biofree_KEGG_mirror',\n")
cat("    pCutoff = 0.05\n")
cat("  )\n\n")

cat("方法2: 使用补丁函数（需要指定 db_dir）\n\n")
cat("  result <- enrich_local_kegg(\n")
cat("    gene = your_genes,\n")
cat("    species = 'hsa',\n")
cat("    db_dir = '~/biofree_KEGG_mirror',\n")
cat("    pCutoff = 0.05,\n")
cat("    universe = your_background  # ✨ 新功能\n")
cat("  )\n\n")

cat("方法3: 设置默认 db_dir（推荐）\n\n")
cat("  options(biofree_kegg_db_dir = '~/biofree_KEGG_mirror')\n")
cat("  # 之后就可以省略 db_dir 参数\n\n")

cat("⚠️ 重要提示:\n")
cat("--------------------------------\n")
cat("1. 数据库格式是 SQLite（不是 .rds）\n")
cat("2. 数据库路径默认: ~/biofree_KEGG_mirror\n")
cat("3. 使用 enrich_local_KEGG 时需要指定 db_dir\n")
cat("4. Universe 补丁需要原始数据库支持\n\n")

cat("========================================\n")
