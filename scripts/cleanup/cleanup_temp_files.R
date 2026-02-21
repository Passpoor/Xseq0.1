# =====================================================
# Biofree Project 临时文件清理脚本
# =====================================================
# 用途：清理更新过程中生成的临时文件
# 使用方法：source("cleanup_temp_files.R")
# =====================================================

cat("🧹 Biofree Project 临时文件清理\n")
cat("================================\n\n")

# 统计信息
deleted_files <- 0
deleted_dirs <- 0
skipped_files <- 0

# =====================================================
# 第一步：删除明确的临时文件
# =====================================================

cat("📋 第一步：删除明确的临时文件\n\n")

temp_files_to_delete <- c(
  "finalize_cleanup.R",
  "finalize_cleanup.ps1"
)

for (file in temp_files_to_delete) {
  if (file.exists(file)) {
    file.remove(file)
    cat(sprintf("  ✅ 已删除: %s\n", file))
    deleted_files <- deleted_files + 1
  } else {
    cat(sprintf("  ⚠️  不存在: %s\n", file))
    skipped_files <- skipped_files + 1
  }
}

cat("\n")

# =====================================================
# 第二步：删除 biofree.qyKEGGtools 克隆目录
# =====================================================

cat("📋 第二步：删除 biofree.qyKEGGtools 克隆目录\n\n")

if (dir.exists("biofree.qyKEGGtools")) {
  unlink("biofree.qyKEGGtools", recursive = TRUE)
  cat("  ✅ 已删除目录: biofree.qyKEGGtools/\n")
  deleted_dirs <- deleted_dirs + 1
} else {
  cat("  ⚠️  目录不存在: biofree.qyKEGGtools/\n")
  skipped_files <- skipped_files + 1
}

cat("\n")

# =====================================================
# 第三步：检查批处理和脚本文件（询问是否删除）
# =====================================================

cat("📋 第三步：检查批处理和脚本文件\n\n")

script_files <- c(
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

# 保留的文件
keep_files <- c("launch_app.R", "run_app.sh", ".gitignore")

existing_scripts <- script_files[file.exists(script_files)]

if (length(existing_scripts) > 0) {
  cat("  发现以下脚本文件：\n")
  for (file in existing_scripts) {
    cat(sprintf("    - %s\n", file))
  }

  cat("\n  ⚠️  这些可能是更新过程中生成的临时脚本\n")
  cat("  💡 建议手动检查后删除\n")
  cat("  📝 或运行：手动删除模式\n\n")

  # 自动删除选项
  cat("  🗑️  自动删除这些文件...\n")
  for (file in existing_scripts) {
    file.remove(file)
    cat(sprintf("    ✅ 已删除: %s\n", file))
    deleted_files <- deleted_files + 1
  }
} else {
  cat("  ✅ 没有发现临时脚本文件\n")
  skipped_files <- skipped_files + 1
}

cat("\n")

# =====================================================
# 第四步：归档 UPDATE_FILES/
# =====================================================

cat("📋 第四步：归档 UPDATE_FILES/\n\n")

if (dir.exists("UPDATE_FILES")) {
  # 创建归档目录
  archive_dir <- "docs/UPDATE_FILES_ARCHIVE"

  if (!dir.exists("docs")) {
    dir.create("docs")
    cat("  ✅ 创建目录: docs/\n")
  }

  if (dir.exists(archive_dir)) {
    cat(sprintf("  ⚠️  归档目录已存在: %s\n", archive_dir))
    cat("  💡 请手动删除或重命名现有目录\n")
  } else {
    # 移动目录
    rename_result <- file.rename("UPDATE_FILES", archive_dir)

    if (rename_result) {
      cat(sprintf("  ✅ 已归档: UPDATE_FILES/ → %s/\n", archive_dir))
    } else {
      cat("  ❌ 归档失败，请手动操作\n")
      cat(sprintf("     mv UPDATE_FILES/ %s/\n", archive_dir))
    }
  }
} else {
  cat("  ⚠️  UPDATE_FILES/ 不存在\n")
  skipped_files <- skipped_files + 1
}

cat("\n")

# =====================================================
# 第五步：检查 md/ 目录
# =====================================================

cat("📋 第五步：检查 md/ 目录\n\n")

if (dir.exists("md")) {
  md_files <- list.files("md", pattern = "\\.md$", full.names = TRUE)

  if (length(md_files) > 0) {
    cat(sprintf("  📁 md/ 目录包含 %d 个 Markdown 文件\n", length(md_files)))

    # 显示前5个文件
    if (length(md_files) > 0) {
      cat("  示例文件：\n")
      for (file in head(md_files, 5)) {
        cat(sprintf("    - %s\n", basename(file)))
      }
    }

    cat("\n  💡 建议检查这些文档是否需要\n")
    cat("  📝 如果需要，可以移到 docs/ 目录\n")
    cat("  🗑️  如果不需要，可以删除 md/ 目录\n")

    # 自动整理到 docs/md_archive
    if (!dir.exists("docs/md_archive")) {
      dir.create("docs/md_archive")
      cat("  ✅ 创建目录: docs/md_archive/\n")
    }
    file.rename(md_files, file.path("docs/md_archive", basename(md_files)))
    unlink("md", recursive = FALSE)
    cat("  ✅ 已将 md/ 内容移到 docs/md_archive/ 并删除 md/ 目录\n")
  } else {
    cat("  📁 md/ 目录为空\n")
    unlink("md", recursive = TRUE)
    cat("  ✅ 已删除空目录: md/\n")
    deleted_dirs <- deleted_dirs + 1
  }
} else {
  cat("  ✅ md/ 目录不存在\n")
  skipped_files <- skipped_files + 1
}

cat("\n")

# =====================================================
# 清理完成统计
# =====================================================

cat("================================\n")
cat("📊 清理完成统计\n")
cat("================================\n\n")

cat(sprintf("✅ 已删除文件: %d 个\n", deleted_files))
cat(sprintf("✅ 已删除目录: %d 个\n", deleted_dirs))
cat(sprintf("⚠️  跳过项目: %d 个\n", skipped_files))

if (deleted_files + deleted_dirs > 0) {
  cat("\n🎉 清理完成！\n")
  cat("💡 建议运行测试：source('launch_app.R')\n")
} else {
  cat("\n✨ 项目已经很干净了！\n")
}

cat("\n")

# =====================================================
# 手动清理指南
# =====================================================

cat("================================\n")
cat("📝 手动清理指南\n")
cat("================================\n\n")

cat("如果需要手动清理，请执行以下操作：\n\n")

cat("1️⃣  删除临时脚本文件：\n")
cat("   rm organize_md.bat run_organize.bat cleanup_files.bat\n")
cat("   rm temp_move_tests.ps1 test_ui.ps1\n")
cat("   rm test_biofree_qykeggtools.bat run_app.bat\n")
cat("   rm verify_code.py auto_organize_md.py\n\n")

cat("2️⃣  归档 UPDATE_FILES/（如果还存在）：\n")
cat("   mv UPDATE_FILES/ docs/UPDATE_FILES_ARCHIVE/\n\n")

cat("3️⃣  检查 md/ 目录：\n")
cat("   ls md/\n")
cat("   # 如不需要，删除：\n")
cat("   rm -rf md/\n\n")

cat("4️⃣  验证项目结构：\n")
cat("   ls -la\n")
cat("   ls modules/\n")
cat("   ls tests/\n\n")

cat("================================\n")
cat("✅ 清理脚本执行完成\n")
cat("================================\n")
