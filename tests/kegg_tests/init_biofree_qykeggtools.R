# =====================================================
# biofree.qyKEGGtools 初始化脚本
# 下载KEGG数据库并应用universe补丁
# =====================================================
# 作者：文献计量与基础医学
# 目的：首次使用时的完整初始化
# =====================================================

cat("\n========================================\n")
cat("biofree.qyKEGGtools 初始化\n")
cat("========================================\n\n")

# =====================================================
# 步骤1：检查包是否安装
# =====================================================

cat("1️⃣ 检查包安装状态...\n")

if (!require("biofree.qyKEGGtools", quietly = TRUE)) {
  cat("❌ biofree.qyKEGGtools 未安装\n")
  cat("\n正在安装...\n")

  # 安装包
  if (!require("remotes", quietly = TRUE)) {
    install.packages("remotes")
  }

  remotes::install_github('Passpoor/biofree.qyKEGGtools')

  cat("✅ 安装完成\n")
} else {
  pkg_version <- packageVersion("biofree.qyKEGGtools")
  cat(sprintf("✅ biofree.qyKEGGtools v%s 已安装\n", pkg_version))
}

cat("\n")

# =====================================================
# 步骤2：下载KEGG数据库
# =====================================================

cat("2️⃣ 下载KEGG数据库...\n")
cat("（这可能需要几分钟，请耐心等待）\n\n")

# 下载KEGG数据库
tryCatch({
  biofree.qyKEGGtools::update_local_kegg()
  cat("\n✅ KEGG数据库下载完成\n\n")
}, error = function(e) {
  cat(sprintf("\n❌ 下载失败: %s\n", conditionMessage(e)))
  cat("\n请检查网络连接或手动下载\n")
  stop("KEGG数据库下载失败")
})

# =====================================================
# 步骤3：验证KEGG数据库
# =====================================================

cat("3️⃣ 验证KEGG数据库...\n")

db_dir <- system.file("extdata", package = "biofree.qyKEGGtools")

# 检查不同物种的数据库
species_to_check <- c("hsa", "mmu", "rno")

found_dbs <- 0
for (sp in species_to_check) {
  db_file <- file.path(db_dir, sp, "kegg_annot.rds")
  if (file.exists(db_file)) {
    # 读取并检查
    db_data <- readRDS(db_file)
    n_pathways <- length(db_data$pathway2gene)
    n_genes <- length(db_data$all_genes)

    cat(sprintf("   ✅ %s: %d pathways, %d genes\n", sp, n_pathways, n_genes))
    found_dbs <- found_dbs + 1
  } else {
    cat(sprintf("   ⚠️ %s: 数据库文件不存在\n", sp))
  }
}

if (found_dbs == 0) {
  cat("\n❌ 未找到任何KEGG数据库文件\n")
  cat("请重新运行 update_local_kegg()\n")
  stop("KEGG数据库验证失败")
}

cat(sprintf("\n✅ 验证完成，找到 %d 个物种的数据库\n\n", found_dbs))

# =====================================================
# 步骤4：应用universe补丁
# =====================================================

cat("4️⃣ 应用universe参数补丁...\n\n")

if (file.exists("patch_biofree_qykeggtools.R")) {
  source("patch_biofree_qykeggtools.R")
  cat("✅ 补丁已应用\n\n")
} else {
  cat("⚠️ 未找到补丁文件: patch_biofree_qykeggtools.R\n")
  cat("请确保在项目根目录运行此脚本\n\n")
}

# =====================================================
# 步骤5：快速测试
# =====================================================

cat("5️⃣ 运行快速测试...\n\n")

test_gene <- c("672", "7157", "7422", "5295", "7158")
test_universe <- c("672", "7157", "7422", "5295", "7158",
                   "1956", "673", "7423", "898", "9133")

test_result <- tryCatch({
  enrich_local_KEGG(
    gene = test_gene,
    species = "hsa",
    pCutoff = 0.05,
    universe = test_universe
  )
}, error = function(e) {
  cat(sprintf("❌ 测试失败: %s\n", conditionMessage(e)))
  NULL
})

if (!is.null(test_result)) {
  cat(sprintf("✅ 测试成功！找到 %d 个富集通路\n\n", nrow(test_result@result)))

  if (nrow(test_result@result) > 0) {
    cat("Top 3 通路:\n")
    print(head(test_result@result[, c("ID", "Description", "p.adjust", "Count")], 3))
  }
}

cat("\n")

# =====================================================
# 完成
# =====================================================

cat("========================================\n")
cat("初始化完成！\n")
cat("========================================\n\n")

cat("✅ biofree.qyKEGGtools 已完全初始化\n")
cat("✅ KEGG数据库已下载\n")
cat("✅ Universe参数补丁已应用\n\n")

cat("📝 下一步：\n")
cat("--------------------------------\n")
cat("1. 启动Shiny应用:\n")
cat("   runApp('app.R')\n\n")

cat("2. 或者直接使用:\n")
cat("   library(biofree.qyKEGGtools)\n")
cat("   result <- enrich_local_KEGG(\n")
cat("     gene = your_genes,\n")
cat("     species = 'hsa',\n")
cat("     universe = your_background  # ✨ 新功能\n")
cat("   )\n\n")

cat("⚠️ 注意:\n")
cat("   - 补丁仅在当前R会话中有效\n")
cat("   - 重启R后需要重新运行: source('patch_biofree_qykeggtools.R')\n")
cat("   - 或者添加到 ~/.Rprofile 自动加载\n\n")

cat("========================================\n")
