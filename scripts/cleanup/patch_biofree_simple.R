# =====================================================
# biofree.qyKEGGtools 简化版补丁
# 基于 clusterProfiler::enricher 的 universe 支持
# =====================================================
# 作者：文献计量与基础医学
# 目的：简单的包装器，传递 universe 参数给 enricher
# =====================================================

cat("\n========================================\n")
cat("biofree.qyKEGGtools Universe 补丁 (简化版)\n")
cat("========================================\n\n")

# =====================================================
# 步骤1：检查当前包状态
# =====================================================

cat("1️⃣ 检查当前包状态...\n")

if (!require("biofree.qyKEGGtools", quietly = TRUE)) {
  cat("❌ biofree.qyKEGGtools 未安装\n")
  cat("\n请先安装：\n")
  cat("  remotes::install_github('Passpoor/biofree.qyKEGGtools')\n")
  stop("包未安装")
}

pkg_version <- packageVersion("biofree.qyKEGGtools")
cat(sprintf("✅ 当前版本: %s\n", pkg_version))

# 检查原始函数
func_args <- tryCatch({
  formals(biofree.qyKEGGtools::enrich_local_KEGG)
}, error = function(e) NULL)

if (is.null(func_args)) {
  cat("❌ 无法读取 enrich_local_KEGG 函数\n")
  stop("函数不存在")
}

cat(sprintf("📋 原始参数: %s\n\n", paste(names(func_args), collapse = ", ")))

# 检查是否支持universe
supports_universe <- "universe" %in% names(func_args)

if (supports_universe) {
  cat("✅ 当前版本已支持 universe 参数\n")
  cat("无需补丁！\n")
  return(invisible(TRUE))
} else {
  cat("⚠️ 当前版本不支持 universe 参数\n")
  cat("📝 将创建包装函数来添加支持\n\n")
}

# =====================================================
# 步骤2：创建简化版包装函数
# =====================================================

cat("2️⃣ 创建简化版包装函数...\n")

enrich_local_KEGG_universe <- function(
  gene,
  species = "hsa",
  db_dir = "~/biofree_KEGG_mirror",
  pCutoff = 0.05,
  qCutoff = NULL,
  universe = NULL  # ✨ 新增参数
) {

  # =====================================================
  # 参数验证
  # =====================================================

  if (missing(gene) || length(gene) == 0) {
    stop("❌ gene 列表不能为空。")
  }

  # 处理 qCutoff 默认值
  if (is.null(qCutoff)) {
    qCutoff <- 0.2  # 设置默认值
  }

  # 展开路径
  db_dir <- path.expand(db_dir)

  # =====================================================
  # 加载数据库
  # =====================================================

  db <- biofree.qyKEGGtools::load_local_kegg(
    species = species,
    db_dir = db_dir
  )

  path2gene <- DBI::dbGetQuery(db, "SELECT * FROM pathway2gene")
  path2name <- DBI::dbGetQuery(db, "SELECT * FROM pathway2name")

  # =====================================================
  # ✨ 使用 clusterProfiler::enricher（支持universe）
  # =====================================================

  # clusterProfiler::enricher 的参数
  enricher_args <- list(
    gene = gene,
    TERM2GENE = path2gene,
    TERM2NAME = path2name,
    pvalueCutoff = pCutoff,
    qvalueCutoff = qCutoff
  )

  # 添加 universe 参数（如果提供）
  if (!is.null(universe)) {
    enricher_args$universe <- universe
    message(sprintf("✅ 使用自定义 universe: %d 个背景基因", length(universe)))
  }

  # 调用 enricher
  res <- do.call(clusterProfiler::enricher, enricher_args)

  # 检查结果
  if (is.null(res)) {
    warning("未找到富集结果，可能是参数设置过严格或universe太小")
    # 返回空的 enrichResult
    res <- new("enrichResult",
               result = data.frame(),
               pAdjustMethod = "BH",
               pvalueCutoff = pCutoff,
               qvalueCutoff = qCutoff,
               organism = species,
               ontology = "KEGG")
  }

  # 断开数据库连接
  DBI::dbDisconnect(db)

  message("🎯 ", species, " 的 KEGG 富集分析完成，共检测到 ",
          nrow(res@result), " 个通路。")

  return(res)
}

cat("✅ 简化版包装函数已创建\n\n")

# =====================================================
# 步骤3：设置为包的默认方法
# =====================================================

cat("3️⃣ 设置默认方法...\n")

# 在全局环境中设置
assign("enrich_local_KEGG", enrich_local_KEGG_universe, envir = globalenv())

cat("✅ 全局函数 'enrich_local_KEGG' 已设置为增强版\n")
cat("   （优先于 biofree.qyKEGGtools::enrich_local_KEGG）\n\n")

# =====================================================
# 步骤4：创建快捷函数
# =====================================================

cat("4️⃣ 创建快捷函数...\n")

# 快捷函数：直接使用增强版
enrichKEGG_universe <- function(...) {
  enrich_local_KEGG_universe(...)
}

assign("enrichKEGG_universe", enrichKEGG_universe, envir = globalenv())

cat("✅ 快捷函数 'enrichKEGG_universe' 已创建\n")
cat("   （与 enrich_local_KEGG 功能相同）\n\n")

# =====================================================
# 步骤5：使用说明
# =====================================================

cat("========================================\n")
cat("补丁安装完成！\n")
cat("========================================\n\n")

cat("✅ 现在可以使用 universe 参数了！\n\n")

cat("📝 使用方法：\n")
cat("--------------------------------\n")
cat("方法1: 使用全局函数（推荐）\n\n")
cat("  library(biofree.qyKEGGtools)\n")
cat("  result <- enrich_local_KEGG(\n")
cat("    gene = c('672', '7157', '7422'),\n")
cat("    species = 'hsa',\n")
cat("    pCutoff = 0.05,\n")
cat("    universe = bg_entrez  # ✨ 新功能\n")
cat("  )\n\n")

cat("方法2: 使用快捷函数\n\n")
cat("  result <- enrichKEGG_universe(\n")
cat("    gene = c('672', '7157', '7422'),\n")
cat("    species = 'hsa',\n")
cat("    pCutoff = 0.05,\n")
cat("    universe = bg_entrez  # ✨ 新功能\n")
cat("  )\n\n")

cat("方法3: 使用显式调用\n\n")
cat("  result <- enrich_local_KEGG_universe(\n")
cat("    gene = c('672', '7157', '7422'),\n")
cat("    species = 'hsa',\n")
cat("    pCutoff = 0.05,\n")
cat("    universe = bg_entrez  # ✨ 新功能\n")
cat("  )\n\n")

cat("⚠️ 重要提示：\n")
cat("--------------------------------\n")
cat("1. 此补丁仅在当前R会话中有效\n")
cat("2. 关闭R后需要重新运行此脚本\n")
cat("3. 如需永久使用，请在 ~/.Rprofile 中添加：\n\n")

cat(sprintf("   source('%s')\n\n", normalizePath("patch_biofree_simple.R")))

cat("4. 与项目集成：\n")
cat("   项目会自动检测并使用增强版函数\n")
cat("   modules/kegg_enrichment.R 已集成\n\n")

cat("5. 数据库说明：\n")
cat("   - 数据库格式: SQLite\n")
cat("   - 默认路径: ~/biofree_KEGG_mirror\n")
cat("   - 使用 biofree.qyKEGGtools::update_local_kegg() 更新\n\n")

cat("========================================\n")

# 返回增强版函数（invisibly）
invisible(enrich_local_KEGG_universe)
