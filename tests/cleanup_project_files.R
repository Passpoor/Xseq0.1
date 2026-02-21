# =====================================================
# 项目文件整理脚本
# 将测试和调试文件移动到 tests/ 目录
# =====================================================

cat("\n========================================\n")
cat("项目文件整理\n")
cat("========================================\n\n")

# 创建必要的目录
dirs_to_create <- c(
  "tests",
  "tests/legacy",
  "tests/kegg_tests",
  "tests/gsea_tests",
  "tests/volcano_tests",
  "tests/chip_tests",
  "tests/debug"
)

cat("1️⃣ 创建目录结构...\n")
for (d in dirs_to_create) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    cat(sprintf("   ✅ 创建: %s\n", d))
  }
}
cat("\n")

# =====================================================
# 文件分类
# =====================================================

cat("2️⃣ 整理文件...\n\n")

# ===== KEGG 相关测试文件 =====
kegg_test_files <- c(
  "test_biofree_qykeggtools.R",
  "check_biofree_package.R",
  "deep_study_qykeggtools.R",
  "test_universe_parameter.R",
  "enrich_local_KEGG_with_universe.R",
  "test_enrich_local_kegg_universe.R",
  "test_enrich_local_kegg_v2.R",
  "quick_test.R",
  "update_biofree_qykeggtools.R",
  "init_biofree_qykeggtools.R",
  "check_kegg_db_location.R",
  "diagnose_kegg_db.R",
  "test_enrich_with_db_dir.R",
  "find_sqlite_db.R",
  "study_qykeggtools_impl.R",
  "init_biofree_v2.R",
  "patch_biofree_qykeggtools.R",
  "test_universe_functionality.R",
  "diagnose_kegg_go.R"
)

# ===== GSEA 相关测试文件 =====
gsea_test_files <- c(
  "debug_gsea_table.R",
  "test_gsea_complete.R",
  "verify_gsea_complete.R",
  "test_gsea_fixes.R",
  "test_gsea_module.R"
)

# ===== Volcano 相关测试文件 =====
volcano_test_files <- c(
  "test_volcano_fix.R",
  "test_volcano_fix_final.R",
  "test_volcano_data_fix.R",
  "fix_volcano_log2foldchange.R"
)

# ===== ChIP 相关测试文件 =====
chip_test_files <- c(
  "test_chip_ui.R",
  "test_chip_syntax.R"
)

# ===== 通用测试文件 =====
general_test_files <- c(
  "test_background_fix.R",
  "test_gene_symbols.R",
  "test_fix_cleanup.R",
  "debug_full_pipeline.R",
  "test_fix_validation.R",
  "test_simple_fix.R",
  "test_fix_safe.R",
  "test_full_pipeline.R",
  "verify_fix_complete.R",
  "test_background_conversion_fix.R",
  "test_ensembl_fix.R",
  "test_complete_fix.R",
  "test_method_selection.R",
  "test_notification_types.R",
  "test_group_factor.R",
  "test_design_matrix.R",
  "test_syntax.R",
  "test_zhipu_integration.R",
  "test_pathway_module.R",
  "verify_pathway_fix.R"
)

# ===== 调试和工具文件 =====
debug_files <- c(
  "check_db.R",
  "check_db_structure.R",
  "debug_gsea_table.R",
  "check_soft_file_columns.R",
  "check_parens.R",
  "gene_symbol_validator.R"
)

# ===== 组织和清理文件 =====
organize_files <- c(
  "organize_files.R",
  "organize_files_safe.R",
  "execute_org.R",
  "organize_project_files.R"
)

# ===== 数据库和配置文件 =====
config_files <- c(
  "migrate_database.R",
  "email_config_template.R"
)

# ===== 其他工具文件 =====
tool_files <- c(
  "install_packages.R",
  "add_haibo_user.R",
  "test_registration.R",
  "fix_ui_theme.R"
)

# ===== 保留在根目录的文件 =====
keep_in_root <- c(
  "app.R",
  "launch_app.R",
  "patch_biofree_simple.R",  # ✨ 主要补丁，保留
  "README.md",
  ".gitignore"
)

# =====================================================
# 移动文件
# =====================================================

move_files <- function(files, target_dir) {
  moved_count <- 0
  for (f in files) {
    if (file.exists(f)) {
      target <- file.path(target_dir, f)
      file.rename(f, target)
      cat(sprintf("   ✅ %s -> %s/\n", f, target_dir))
      moved_count <- moved_count + 1
    }
  }
  return(moved_count)
}

cat("移动 KEGG 测试文件...\n")
n1 <- move_files(kegg_test_files, "tests/kegg_tests")
cat(sprintf("   移动了 %d 个文件\n\n", n1))

cat("移动 GSEA 测试文件...\n")
n2 <- move_files(gsea_test_files, "tests/gsea_tests")
cat(sprintf("   移动了 %d 个文件\n\n", n2))

cat("移动 Volcano 测试文件...\n")
n3 <- move_files(volcano_test_files, "tests/volcano_tests")
cat(sprintf("   移动了 %d 个文件\n\n", n3))

cat("移动 ChIP 测试文件...\n")
n4 <- move_files(chip_test_files, "tests/chip_tests")
cat(sprintf("   移动了 %d 个文件\n\n", n4))

cat("移动通用测试文件...\n")
n5 <- move_files(general_test_files, "tests/legacy")
cat(sprintf("   移动了 %d 个文件\n\n", n5))

cat("移动调试文件...\n")
n6 <- move_files(debug_files, "tests/debug")
cat(sprintf("   移动了 %d 个文件\n\n", n6))

cat("移动组织脚本...\n")
n7 <- move_files(organize_files, "tests")
cat(sprintf("   移动了 %d 个文件\n\n", n7))

cat("移动配置文件...\n")
n8 <- move_files(config_files, "config")
cat(sprintf("   移动了 %d 个文件\n\n", n8))

cat("移动工具文件...\n")
n9 <- move_files(tool_files, "tests")
cat(sprintf("   移动了 %d 个文件\n\n", n9))

# =====================================================
# 创建 .gitignore 更新
# =====================================================

cat("3️⃣ 更新 .gitignore...\n")

gitignore_entries <- c(
  "# 测试文件目录",
  "tests/",
  "",
  "# 临时文件",
  "*.tmp",
  "*.temp",
  "*.rds",
  "*.Rhistory",
  "*.Rproj.user",
  ".RData",
  ".Ruserdata",
  "",
  "# 数据库文件",
  "*.sqlite",
  "*.db"
)

if (file.exists(".gitignore")) {
  current_ignore <- readLines(".gitignore")
  new_entries <- setdiff(gitignore_entries, current_ignore)
  if (length(new_entries) > 0) {
    cat(gitignore_entries, sep = "\n", append = TRUE)
    cat("   ✅ .gitignore 已更新\n\n")
  } else {
    cat("   ℹ️ .gitignore 已是最新\n\n")
  }
} else {
  cat(gitignore_entries, sep = "\n", file = ".gitignore")
  cat("   ✅ .gitignore 已创建\n\n")
}

# =====================================================
# 创建文件清单
# =====================================================

cat("4️⃣ 创建文件清单...\n")

root_files <- list.files(pattern = "\\.(R|md|txt)$", full.names = FALSE)
file_tree <- list.files(recursive = TRUE, pattern = "\\.R$")

cat(sprintf("\n根目录文件 (%d):\n", length(root_files)))
for (f in root_files) {
  marker <- ifelse(f %in% keep_in_root, " ✅", " ⚠️")
  cat(sprintf("  %s %s\n", marker, f))
}

cat(sprintf("\n所有 R 文件 (%d):\n", length(file_tree)))
for (d in c("tests", "modules", "config")) {
  if (dir.exists(d)) {
    files_in_dir <- list.files(d, pattern = "\\.R$", recursive = TRUE)
    cat(sprintf("\n%s/ (%d 文件):\n", d, length(files_in_dir)))
    for (f in head(files_in_dir, 10)) {
      cat(sprintf("  - %s\n", f))
    }
    if (length(files_in_dir) > 10) {
      cat(sprintf("  ... 还有 %d 个文件\n", length(files_in_dir) - 10))
    }
  }
}

# =====================================================
# 总结
# =====================================================

cat("\n========================================\n")
cat("整理完成！\n")
cat("========================================\n\n")

total_moved <- n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 + n9
cat(sprintf("✅ 总共移动了 %d 个文件\n", total_moved))
cat(sprintf("✅ 创建了 %d 个目录\n", length(dirs_to_create)))
cat("\n")

cat("📁 新的目录结构:\n")
cat("   ├── app.R                    (主应用)\n")
cat("   ├── launch_app.R            (启动脚本)\n")
cat("   ├── patch_biofree_simple.R   (KEGG补丁)\n")
cat("   ├── modules/                 (功能模块)\n")
cat("   ├── tests/                   (测试文件)\n")
cat("   │   ├── kegg_tests/          (KEGG测试)\n")
cat("   │   ├── gsea_tests/          (GSEA测试)\n")
cat("   │   ├── volcano_tests/       (Volcano测试)\n")
cat("   │   ├── chip_tests/          (ChIP测试)\n")
cat("   │   ├── legacy/              (旧测试)\n")
cat("   │   └── debug/               (调试工具)\n")
cat("   └── config/                  (配置文件)\n\n")

cat("💡 提示:\n")
cat("   - 保留在根目录的文件标记为 ✅\n")
cat("   - 其他文件建议移动到相应目录\n")
cat("   - tests/ 目录已添加到 .gitignore\n\n")

cat("========================================\n")
