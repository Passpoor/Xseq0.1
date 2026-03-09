# =====================================================
# 安全文件整理脚本 v2 - 简化版
# 只复制文件，不删除任何内容
# =====================================================

cat("========================================\n")
cat("   安全文件整理 - 只复制，不删除\n")
cat("========================================\n\n")

# 设置工作目录
setwd("D:/cherry_code/Biofree_project11.2/Biofree_project")

# =====================================================
# Step 1: 创建文件夹
# =====================================================

cat("Step 1: 创建文件夹结构\n")
cat("----------------------------------------\n")

dirs <- c(
  "tests/legacy",
  "docs/gsea_history",
  "docs/functional_docs"
)

for (d in dirs) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    cat(sprintf("  创建: %s\n", d))
  } else {
    cat(sprintf("  已存在: %s\n", d))
  }
}

# =====================================================
# Step 2: 复制测试脚本
# =====================================================

cat("\nStep 2: 复制测试脚本\n")
cat("----------------------------------------\n")

# 获取所有测试相关文件
test_files <- list.files(pattern = "^test_.*\\.R$")
debug_files <- list.files(pattern = "^debug_.*\\.R$")
verify_files <- list.files(pattern = "^verify_.*\\.R$")
check_files <- list.files(pattern = "^check_.*\\.R$")

all_test_files <- c(test_files, debug_files, verify_files, check_files)

if (length(all_test_files) > 0) {
  for (f in all_test_files) {
    if (file.exists(f)) {
      file.copy(f, "tests/legacy/", overwrite = TRUE)
      cat(sprintf("  复制: %s -> tests/legacy/\n", f))
    }
  }
  cat(sprintf("\n✅ 总共复制了 %d 个测试文件\n", length(all_test_files)))
} else {
  cat("  没有找到测试文件\n")
}

# 复制其他临时脚本
temp_scripts <- c(
  "diagnose_kegg_go.R",
  "fix_ui_theme.R",
  "add_haibo_user.R",
  "check_parens.R",
  "fix_volcano_log2foldchange.R",
  "gene_symbol_validator.R"
)

copied_count <- 0
for (f in temp_scripts) {
  if (file.exists(f)) {
    file.copy(f, "tests/legacy/", overwrite = TRUE)
    cat(sprintf("  复制: %s -> tests/legacy/\n", f))
    copied_count <- copied_count + 1
  }
}

if (copied_count > 0) {
  cat(sprintf("\n✅ 复制了 %d 个临时脚本\n", copied_count))
}

# =====================================================
# Step 3: 复制文档
# =====================================================

cat("\nStep 3: 复制文档文件\n")
cat("----------------------------------------\n")

# 3.1 GSEA历史文档
gsea_docs <- list.files(pattern = "^GSEA_.*\\.md$")
gsea_docs <- gsea_docs[gsea_docs != "GSEA_FINAL_STATUS.md"]  # 保留最新的

if (length(gsea_docs) > 0) {
  for (f in gsea_docs) {
    file.copy(f, "docs/gsea_history/", overwrite = TRUE)
    cat(sprintf("  复制: %s -> docs/gsea_history/\n", f))
  }
  cat(sprintf("\n✅ 复制了 %d 个GSEA文档\n", length(gsea_docs)))
}

# 3.2 功能文档
func_docs <- c(
  "API配置使用指南.md",
  "API请求格式修复说明.md",
  "基因助手功能说明.md",
  "火山图功能增强说明.md",
  "test_volcano_enhancements.md",
  "logo_optimization_guide.md"
)

copied_docs <- 0
for (f in func_docs) {
  if (file.exists(f)) {
    file.copy(f, "docs/functional_docs/", overwrite = TRUE)
    cat(sprintf("  复制: %s -> docs/functional_docs/\n", f))
    copied_docs <- copied_docs + 1
  }
}

if (copied_docs > 0) {
  cat(sprintf("\n✅ 复制了 %d 个功能文档\n", copied_docs))
}

# 3.3 修复记录和提议文档
fix_docs <- list.files(pattern = "_FIX\\.md$")
proposal_docs <- list.files(pattern = "_PROPOSAL\\.md$")
other_docs <- c(fix_docs, proposal_docs)

if (length(other_docs) > 0) {
  for (f in other_docs) {
    file.copy(f, "docs/", overwrite = TRUE)
    cat(sprintf("  复制: %s -> docs/\n", f))
  }
  cat(sprintf("\n✅ 复制了 %d 个其他文档\n", length(other_docs)))
}

# =====================================================
# Step 4: 验证
# =====================================================

cat("\nStep 4: 验证文件完整性\n")
cat("----------------------------------------\n")

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

missing_count <- 0
for (f in core_files) {
  if (!file.exists(f)) {
    cat(sprintf("  ❌ 缺少: %s\n", f))
    missing_count <- missing_count + 1
  }
}

if (missing_count == 0) {
  cat("  ✅ 所有核心文件完整\n")
} else {
  cat(sprintf("  ⚠️  警告: %d 个核心文件缺失\n", missing_count))
}

# 统计
cat("\n========================================\n")
cat("           整理统计\n")
cat("========================================\n")
cat(sprintf("  原根目录文件数: %d\n", length(list.files())))
cat(sprintf("  tests/legacy/ 文件数: %d\n", length(list.files("tests/legacy"))))
cat(sprintf("  docs/ 文件数: %d\n", length(list.files("docs", recursive = TRUE))))

cat("\n========================================\n")
cat("           ✅ 完成！\n")
cat("========================================\n\n")

cat("📋 下一步操作:\n")
cat("  1. 测试应用是否正常运行\n")
cat("  2. 如果无问题，删除根目录的测试文件原副本\n")
cat("  3. 删除备份文件 (*.backup)\n\n")

cat("💡 提示: 所有原文件仍保留在根目录，可以随时回滚\n\n")
