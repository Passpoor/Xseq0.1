# =====================================================
# 安全文件整理脚本
# 只复制文件，不删除任何内容
# =====================================================

cat("
╔════════════════════════════════════════════════════════╗
║              安全文件整理 - Phase 1-3                 ║
║  ✅ 只创建文件夹和复制文件                               ║
║  ✅ 不删除任何文件                                       ║
║  ✅ 可以随时回滚                                         ║
╚════════════════════════════════════════════════════════╝

")

# =====================================================
# Phase 1: 创建文件夹
# =====================================================

cat("\n📁 Phase 1: 创建文件夹结构\n")
cat("─────────────────────────────────────────\n")

# 创建必要的文件夹
dirs_to_create <- c(
  "tests/legacy",
  "docs/gsea_history",
  "docs/functional_docs"
)

for (d in dirs_to_create) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    cat(sprintf("  ✅ 创建文件夹: %s\n", d))
  } else {
    cat(sprintf("  📁 文件夹已存在: %s\n", d))
  }
}

# =====================================================
# Phase 2: 复制测试脚本
# =====================================================

cat("\n🧪 Phase 2: 复制测试脚本\n")
cat("─────────────────────────────────────────\n")

# 获取测试脚本文件
test_patterns <- c("^test_.*\\.R$", "^debug_.*\\.R$", "^verify_.*\\.R$", "^check_.*\\.R$")
all_test_files <- character()

for (pattern in test_patterns) {
  files <- list.files(pattern = pattern, full.names = FALSE)
  all_test_files <- c(all_test_files, files)
}

if (length(all_test_files) > 0) {
  # 复制到tests/legacy/
  for (f in all_test_files) {
    if (file.exists(f)) {
      dest <- file.path("tests/legacy", f)
      file.copy(f, dest, overwrite = TRUE)
      cat(sprintf("  ✅ %s -> tests/legacy/\n", f))
    }
  }
  cat(sprintf("\n✅ 总共复制了 %d 个测试脚本\n", length(all_test_files)))
} else {
  cat("  ⚠️  未找到测试脚本\n")
}

# 复制其他临时脚本
temp_scripts <- c(
  "diagnose_kegg_go.R",
  "fix_ui_theme.R",
  "add_haibo_user.R",
  "check_parens.R",
  "fix_volcano_log2foldchange.R"
)

copied_temp <- 0
for (f in temp_scripts) {
  if (file.exists(f)) {
    dest <- file.path("tests/legacy", f)
    file.copy(f, dest, overwrite = TRUE)
    cat(sprintf("  ✅ %s -> tests/legacy/\n", f))
    copied_temp <- copied_temp + 1
  }
}
if (copied_temp > 0) {
  cat(sprintf("\n✅ 复制了 %d 个临时脚本\n", copied_temp))
}

# =====================================================
# Phase 3: 复制文档
# =====================================================

cat("\n📚 Phase 3: 复制文档文件\n")
cat("─────────────────────────────────────────\n")

# 3.1 GSEA历史文档
gsea_docs <- list.files(pattern = "^GSEA_.*\\.md$", full.names = FALSE)
gsea_docs <- gsea_docs[gsea_docs != "GSEA_FINAL_STATUS.md"]  # 保留最新的在根目录

if (length(gsea_docs) > 0) {
  for (f in gsea_docs) {
    dest <- file.path("docs/gsea_history", f)
    file.copy(f, dest, overwrite = TRUE)
    cat(sprintf("  ✅ %s -> docs/gsea_history/\n", f))
  }
  cat(sprintf("\n✅ 复制了 %d 个GSEA历史文档\n", length(gsea_docs)))
}

# 3.2 功能说明文档
func_docs <- c(
  "API配置使用指南.md",
  "基因助手功能说明.md",
  "火山图功能增强说明.md",
  "logo_optimization_guide.md",
  "test_volcano_enhancements.md",
  "API请求格式修复说明.md"
)

copied_func <- 0
for (f in func_docs) {
  if (file.exists(f)) {
    dest <- file.path("docs/functional_docs", f)
    file.copy(f, dest, overwrite = TRUE)
    cat(sprintf("  ✅ %s -> docs/functional_docs/\n", f))
    copied_func <- copied_func + 1
  }
}
if (copied_func > 0) {
  cat(sprintf("\n✅ 复制了 %d 个功能文档\n", copied_func))
}

# 3.3 提议文档
proposal_docs <- list.files(pattern = "_PROPOSAL\\.md$")
if (length(proposal_docs) > 0) {
  for (f in proposal_docs) {
    dest <- file.path("docs", f)
    file.copy(f, dest, overwrite = TRUE)
    cat(sprintf("  ✅ %s -> docs/\n", f))
  }
  cat(sprintf("\n✅ 复制了 %d 个提议文档\n", length(proposal_docs)))
}

# 3.4 修复记录文档
fix_docs <- list.files(pattern = "_FIX\\.md$")
fix_docs <- fix_docs[!grepl("GSEA", fix_docs)]  # GSEA的已处理

if (length(fix_docs) > 0) {
  for (f in fix_docs) {
    dest <- file.path("docs", f)
    file.copy(f, dest, overwrite = TRUE)
    cat(sprintf("  ✅ %s -> docs/\n", f))
  }
  cat(sprintf("\n✅ 复制了 %d 个修复记录\n", length(fix_docs)))
}

# =====================================================
# Phase 4: 验证
# =====================================================

cat("\n✅ Phase 4: 验证文件完整性\n")
cat("─────────────────────────────────────────\n")

# 验证核心文件
core_files <- c(
  "app.R",
  "modules/database.R",
  "modules/ui_theme.R",
  "modules/data_input.R",
  "modules/differential_analysis.R",
  "modules/kegg_enrichment.R",
  "modules/go_analysis.R",
  "modules/gsea_analysis.R",
  "modules/tf_activity.R",
  "modules/venn_diagram.R",
  "README.md",
  "CHANGELOG.md"
)

missing_files <- character()
for (f in core_files) {
  if (!file.exists(f)) {
    missing_files <- c(missing_files, f)
    cat(sprintf("  ❌ 缺少核心文件: %s\n", f))
  }
}

if (length(missing_files) == 0) {
  cat("  ✅ 所有核心文件完整\n")
} else {
  cat(sprintf("  ⚠️  警告: %d 个核心文件缺失\n", length(missing_files)))
}

# 统计整理结果
cat("\n📊 整理统计\n")
cat("─────────────────────────────────────────\n")

original_file_count <- length(list.files())
new_test_count <- length(list.files("tests/legacy", full.names = FALSE))
new_doc_count <- length(list.files("docs", full.names = TRUE, recursive = TRUE))

cat(sprintf("  📁 原根目录文件: %d 个\n", original_file_count))
cat(sprintf("  📁 tests/legacy/: %d 个文件\n", new_test_count))
cat(sprintf("  📁 docs/: %d 个文件\n", new_doc_count))
cat(sprintf("\n  ⚠️  原文件仍保留（未删除）\n"))

# =====================================================
# 完成总结
# =====================================================

cat("\n═════════════════════════════════════════════════════════\n")
cat("                Phase 1-3 完成！\n")
cat("═════════════════════════════════════════════════════════\n")

cat("\n✅ 已完成:\n")
cat("  1. 创建文件夹结构\n")
cat("  2. 复制所有测试脚本到 tests/legacy/\n")
cat("  3. 复制所有文档到 docs/\n")
cat("  4. 验证核心文件完整\n")

cat("\n📋 下一步 (需要您确认):\n")
cat("  1. 测试应用是否正常运行\n")
cat("     source('app.R')\n")
cat("  2. 确认无问题后执行Phase 5-6\n")
cat("  3. 删除根目录的测试文件原副本\n")
cat("  4. 删除备份文件\n")

cat("\n💡 提示:\n")
cat("  - 所有原文件仍保留在根目录\n")
cat("  - 可以随时回滚\n")
cat("  - 建议先测试应用\n")

cat("\n")
