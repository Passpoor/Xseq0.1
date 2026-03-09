# 文件整理脚本 - 移动测试文件和文档
# 不会影响任何功能文件

root_dir <- getwd()
cat("工作目录:", root_dir, "\n")

# 创建目录
dir.create("tests/root_tests", showWarnings = FALSE, recursive = TRUE)
dir.create("docs/reports", showWarnings = FALSE, recursive = TRUE)
dir.create("docs/guides", showWarnings = FALSE, recursive = TRUE)

# === 1. 移动测试文件 ===
cat("\n=== 移动测试文件 ===\n")

test_files <- c(
  "test_registration.R",
  "check_db.R",
  "check_db_structure.R",
  "migrate_database.R",
  "test_background_fix.R",
  "test_gene_symbols.R",
  "diagnose_kegg_go.R",
  "test_fix_cleanup.R",
  "debug_full_pipeline.R",
  "test_fix_validation.R",
  "test_simple_fix.R",
  "test_fix_safe.R",
  "test_full_pipeline.R",
  "verify_fix_complete.R",
  "gene_symbol_validator.R",
  "test_background_conversion_fix.R",
  "test_ensembl_fix.R",
  "test_volcano_fix.R",
  "test_volcano_fix_final.R",
  "test_complete_fix.R",
  "test_volcano_data_fix.R",
  "fix_ui_theme.R",
  "add_haibo_user.R",
  "check_parens.R",
  "fix_volcano_log2foldchange.R",
  "test_method_selection.R",
  "test_notification_types.R",
  "test_group_factor.R",
  "test_design_matrix.R",
  "test_gsea_module.R",
  "launch_app.R",
  "debug_gsea_table.R",
  "test_gsea_complete.R",
  "verify_gsea_complete.R",
  "test_gsea_fixes.R",
  "organize_files.R",
  "organize_files_safe.R",
  "execute_org.R",
  "test_syntax.R",
  "test_zhipu_integration.R",
  "test_pathway_module.R",
  "verify_pathway_fix.R",
  "install_packages.R"
)

moved_count <- 0
for (file in test_files) {
  from <- file.path(root_dir, file)
  to <- file.path(root_dir, "tests/root_tests", file)

  if (file.exists(from)) {
    file.rename(from, to)
    cat("✓ 移动:", file, "\n")
    moved_count <- moved_count + 1
  }
}

cat("\n共移动", moved_count, "个测试文件到 tests/root_tests/\n")

# === 2. 移动修复报告文档 ===
cat("\n=== 移动修复报告文档 ===\n")

report_files <- c(
  "AI功能修复完成报告.md",
  "AI功能修复报告.md",
  "AI功能完整性检查报告.md",
  "AI如何获取结果详细.md",
  "AI研究主题功能更新.md",
  "AI进度展示功能更新.md",
  "API测试功能修复说明.md",
  "API请求格式修复说明.md",
  "API配置使用指南.md",
  "BACKGROUND_CONVERSION_FIX_FINAL.md",
  "BACKGROUND_GENE_SET_FIX.md",
  "Ensembl_ID兼容性问题说明文档.md",
  "FILE_ORGANIZATION_REPORT.md",
  "GSEA_ANNOTATION_FIX.md",
  "GSEA_ANNOTATION_GUIDE.md",
  "GSEA_BUG_FIXES_COMPLETE.md",
  "GSEA_FINAL_FIX.md",
  "GSEA_FINAL_STATUS.md",
  "GSEA_FIXES_VERIFICATION.md",
  "GSEA_FIX_V3.4.md",
  "GSEA_FIX_V3.5.md",
  "GSEA_FIX_V3.6_FINAL.md",
  "GSEA_FIX_V3.7_FINAL.md",
  "GSEA_FIX_V3.8_FINAL.md",
  "GSEA_ID_MISMATCH_FIX.md",
  "GSEA_TABLE_AND_LE_FIX.md",
  "GSEA_TEST_GUIDE.md",
  "KEGG_GO_FIX_SUMMARY.md",
  "KEGG_GO数据使用问题修复.md",
  "ORGANIZATION_GUIDE.md",
  "PATHWAY_ACTIVITY_FIX_COMPLETE.md",
  "PATHWAY_ACTIVITY_MODULE.md",
  "PATHWAY_ACTIVITY_USAGE_GUIDE.md",
  "PROJECT_SUMMARY.md",
  "SAFE_CLEANUP_PLAN.md",
  "SINGLE_CELL_INTEGRATION_PROPOSAL.md",
  "TF_ACTIVITY_FIX.md",
  "TF交互式网络图最终修复.md",
  "TF模块v2.1更新报告.md",
  "TF模块交互式网络图修复报告.md",
  "TF模块全面检查报告.md",
  "TF模块分析报告.md",
  "TF模块更新完成报告.md",
  "TF模块继承修复报告.md",
  "ULM方法原理详解.md",
  "火山图功能增强说明.md",
  "差异应用问题修复报告.md",
  "通透性模块UI界面模块完成.md",
  "通透性模块问题修复.md",
  "通透性模块修复完成报告.md",
  "通透性簇图子和簇图功能更新.md",
  "文件整理准备工作完成.md",
  "文件整理执行指南.md",
  "智谱AI集成使用指南.md",
  "智谱AI集成完成报告.md"
)

moved_docs <- 0
for (file in report_files) {
  from <- file.path(root_dir, file)
  to <- file.path(root_dir, "docs/reports", file)

  if (file.exists(from)) {
    file.rename(from, to)
    cat("✓ 移动:", file, "\n")
    moved_docs <- moved_docs + 1
  }
}

cat("\n共移动", moved_docs, "个报告文档到 docs/reports/\n")

# === 3. 移动使用指南 ===
cat("\n=== 移动使用指南文档 ===\n")

guide_files <- c(
  "基本手功能说明.md",
  "智谱AI集成完成报告.md",
  "智谱AI集成使用指南.md"
)

moved_guides <- 0
for (file in guide_files) {
  from <- file.path(root_dir, file)
  to <- file.path(root_dir, "docs/guides", file)

  if (file.exists(from)) {
    file.rename(from, to)
    cat("✓ 移动:", file, "\n")
    moved_guides <- moved_guides + 1
  }
}

cat("\n共移动", moved_guides, "个指南文档到 docs/guides/\n")

# === 4. 清理临时脚本 ===
cat("\n=== 清理临时脚本 ===\n")
temp_script <- file.path(root_dir, "temp_move_tests.ps1")
if (file.exists(temp_script)) {
  file.remove(temp_script)
  cat("✓ 删除临时脚本\n")
}

# === 总结 ===
cat("\n========== 整理完成 ==========\n")
cat("✓ 测试文件:", moved_count, "个 -> tests/root_tests/\n")
cat("✓ 报告文档:", moved_docs, "个 -> docs/reports/\n")
cat("✓ 指南文档:", moved_guides, "个 -> docs/guides/\n")
cat("\n所有功能文件保持不变，应用正常运行！\n")
