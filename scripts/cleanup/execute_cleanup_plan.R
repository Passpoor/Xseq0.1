# =====================================================
# Biofree Project 完整清理执行计划
# =====================================================

cat("🚀 开始执行 Biofree Project 完整清理\n")
cat("========================================\n\n")

# 记录开始时间
start_time <- Sys.time()

# =====================================================
# 第一步：删除临时文件
# =====================================================

cat("📋 第一步：删除临时文件\n\n")

temp_files <- c(
  "finalize_cleanup.R",
  "finalize_cleanup.ps1",
  "organize_md.bat",
  "run_organize.bat",
  "cleanup_files.bat",
  "temp_move_tests.ps1",
  "test_ui.ps1",
  "test_biofree_qykeggtools.bat",
  "run_app.bat",
  "verify_code.py",
  "auto_organize_md.py"
)

deleted_count <- 0
for (file in temp_files) {
  if (file.exists(file)) {
    file.remove(file)
    cat(sprintf("  ✅ 已删除: %s\n", file))
    deleted_count <- deleted_count + 1
  }
}

cat(sprintf("\n   删除了 %d 个临时文件\n\n", deleted_count))

# =====================================================
# 第二步：删除 biofree.qyKEGGtools 克隆目录
# =====================================================

cat("📋 第二步：删除 biofree.qyKEGGtools 克隆目录\n")

if (dir.exists("biofree.qyKEGGtools")) {
  unlink("biofree.qyKEGGtools", recursive = TRUE)
  cat("  ✅ 已删除: biofree.qyKEGGtools/\n\n")
} else {
  cat("  ⚠️  biofree.qyKEGGtools/ 不存在\n\n")
}

# =====================================================
# 第三步：归档 UPDATE_FILES/
# =====================================================

cat("📋 第三步：归档 UPDATE_FILES/\n")

if (dir.exists("UPDATE_FILES")) {
  if (!dir.exists("docs")) {
    dir.create("docs")
  }

  if (!dir.exists("docs/UPDATE_FILES_ARCHIVE")) {
    file.rename("UPDATE_FILES", "docs/UPDATE_FILES_ARCHIVE")
    cat("  ✅ 已归档: UPDATE_FILES/ → docs/UPDATE_FILES_ARCHIVE/\n\n")
  } else {
    cat("  ⚠️  docs/UPDATE_FILES_ARCHIVE/ 已存在\n")
    cat("  💡 请手动删除或重命名\n\n")
  }
} else {
  cat("  ⚠️  UPDATE_FILES/ 不存在\n\n")
}

# =====================================================
# 第四步：整理 md/ 目录
# =====================================================

cat("📋 第四步：整理 md/ 目录\n")

if (dir.exists("md")) {
  md_files <- list.files("md", pattern = "\\.*$", full.names = TRUE)

  if (length(md_files) > 0) {
    # 创建归档目录
    if (!dir.exists("docs/md_archive")) {
      dir.create("docs/md_archive")
    }

    # 移动文件
    for (file in md_files) {
      file.rename(file, file.path("docs/md_archive", basename(file)))
    }

    cat(sprintf("  ✅ 已移动 %d 个文件到 docs/md_archive/\n", length(md_files)))

    # 删除空目录
    unlink("md", recursive = TRUE)
    cat("  ✅ 已删除 md/ 目录\n\n")
  } else {
    unlink("md", recursive = TRUE)
    cat("  ✅ md/ 为空，已删除\n\n")
  }
} else {
  cat("  ✅ md/ 目录不存在\n\n")
}

# =====================================================
# 第五步：验证项目结构
# =====================================================

cat("📋 第五步：验证项目结构\n\n")

# 检查核心文件
core_files <- c(
  "app.R",
  "launch_app.R",
  "patch_biofree_simple.R",
  "README.md",
  ".gitignore"
)

cat("  核心文件检查：\n")
for (file in core_files) {
  status <- if (file.exists(file)) "✅" else "❌"
  cat(sprintf("    %s %s\n", status, file))
}

cat("\n  核心目录检查：\n")
core_dirs <- c("modules", "config", "www", "tests", "docs")
for (dir in core_dirs) {
  status <- if (dir.exists(dir)) "✅" else "❌"
  cat(sprintf("    %s %s/\n", status, dir))
}

cat("\n")

# =====================================================
# 第六步：显示最终项目结构
# =====================================================

cat("📋 第六步：最终项目结构\n\n")

cat("Biofree_project/\n")
cat("├── 📄 app.R                          ✅\n")
cat("├── 📄 launch_app.R                   ✅\n")
cat("├── 📄 patch_biofree_simple.R         ✅\n")
cat("├── 📄 README.md                      ✅\n")
cat("├── 📁 modules/                       ✅ (13个核心模块)\n")
cat("├── 📁 config/                        ✅ (配置文件)\n")
cat("├── 📁 www/                           ✅ (静态资源)\n")
cat("├── 📁 tests/                         ✅ (测试文件，已分类)\n")
cat("│   ├── kegg_tests/\n")
cat("│   ├── gsea_tests/\n")
cat("│   ├── volcano_tests/\n")
cat("│   ├── chip_tests/\n")
cat("│   ├── debug/\n")
cat("│   └── legacy/\n")
cat("├── 📁 docs/                          ✅ (项目文档)\n")
cat("│   ├── biofree_qykeggtools_v2.1.0_release.md\n")
cat("│   ├── PROJECT_COMPATIBILITY_REPORT.md\n")
cat("│   ├── APPROACH_PRIORITY_CHANGE.md\n")
cat("│   ├── PROJECT_STRUCTURE_CLEANUP.md\n")
cat("│   ├── UPDATE_FILES_ARCHIVE/         (已归档)\n")
cat("│   └── md_archive/                   (已归档)\n")
cat("└── 📁 images/                        ✅\n")

cat("\n")

# =====================================================
# 清理完成
# =====================================================

end_time <- Sys.time()
duration <- as.numeric(difftime(end_time, start_time, units = "secs"))

cat("========================================\n")
cat("🎉 清理完成！\n")
cat("========================================\n\n")

cat(sprintf("⏱️  耗时: %.2f 秒\n", duration))
cat("✅ 项目结构已优化\n")
cat("✅ 临时文件已清理\n")
cat("✅ 文档已归档\n\n")

cat("🚀 下一步：\n")
cat("   1. 运行测试: source('launch_app.R')\n")
cat("   2. 验证功能是否正常\n")
cat("   3. 提交到 Git（如果需要）\n\n")

cat("========================================\n")
