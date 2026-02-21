# =====================================================
# 清理 R 包残留锁文件
# =====================================================
# 用途：删除 R 包目录中的 00LOCK 残留文件
# 使用：在启动 Biofree 前运行此脚本
# =====================================================

cleanup_locks <- function(verbose = TRUE) {
  # 检测操作系统
  if (.Platform$OS.type == "windows") {
    # Windows 系统的库路径
    lib_paths <- c(
      path.expand("~/AppData/Local/R/win-library/4.5"),
      path.expand("~/AppData/Local/R/win-library/4.4"),
      path.expand("~/AppData/Local/R/win-library/4.3")
    )
  } else {
    # Unix-like 系统的库路径
    lib_paths <- c(
      path.expand("~/R/library"),
      "/usr/local/lib/R/site-library"
    )
  }

  total_cleaned <- 0

  for (lib_path in lib_paths) {
    if (dir.exists(lib_path)) {
      if (verbose) {
        cat(sprintf("\n🔍 检查路径: %s\n", lib_path))
      }

      # 查找所有 00LOCK 目录
      lock_dirs <- list.files(lib_path, pattern = "^00LOCK", full.names = TRUE)

      if (length(lock_dirs) > 0) {
        if (verbose) {
          cat(sprintf("   发现 %d 个残留的锁文件\n", length(lock_dirs)))
        }

        for (lock_dir in lock_dirs) {
          pkg_name <- gsub("^00LOCK", "", basename(lock_dir))

          if (verbose) {
            cat(sprintf("   🗑️  删除: %s\n", pkg_name))
          }

          tryCatch({
            unlink(lock_dir, recursive = TRUE)
            total_cleaned <- total_cleaned + 1
          }, error = function(e) {
            if (verbose) {
              cat(sprintf("   ❌ 删除失败: %s\n", e$message))
            }
          })
        }

        if (verbose) {
          cat("   ✅ 清理完成\n")
        }
      } else {
        if (verbose) {
          cat("   ✅ 没有发现残留的锁文件\n")
        }
      }
    }
  }

  if (verbose) {
    cat("\n")
    cat("=" , rep("=", 50), "\n", sep = "")
    if (total_cleaned > 0) {
      cat(sprintf("✅ 总共清理了 %d 个残留锁文件\n", total_cleaned))
      cat("💡 现在可以安全启动 Biofree 了\n")
    } else {
      cat("✅ 没有发现任何残留锁文件\n")
      cat("💡 如果仍然遇到锁定错误，请检查是否有其他 R 进程正在运行\n")
    }
    cat("=" , rep("=", 50), "\n", sep = "")
  }

  return(total_cleaned)
}

# 检查是否有 R 进程正在运行
check_r_processes <- function() {
  if (.Platform$OS.type == "windows") {
    tryCatch({
      result <- shell("tasklist | findstr /I \"R.exe Rterm.exe\"", intern = TRUE, ignore.stderr = TRUE)

      if (length(result) > 0) {
        # 过滤掉 findstr 自己和当前进程
        r_processes <- result[!grepl("findstr", result, ignore.case = TRUE)]

        if (length(r_processes) > 0) {
          cat("\n⚠️  警告: 检测到以下 R 进程正在运行:\n")
          cat(paste(r_processes, collapse = "\n"))
          cat("\n")
          cat("💡 建议:\n")
          cat("   1. 关闭 RStudio 和其他 R 编辑器\n")
          cat("   2. 在任务管理器中结束 R.exe 和 Rterm.exe 进程\n")
          cat("   3. 然后重新运行此清理脚本\n")
          return(FALSE)
        }
      }
    }, error = function(e) {
      # 忽略错误，继续
    })
  }

  return(TRUE)
}

# =====================================================
# 主程序
# =====================================================

cat("\n")
cat("=" , rep("=", 50), "\n", sep = "")
cat("🧹 R 包锁文件清理工具\n")
cat("=" , rep("=", 50), "\n", sep = "")

# 1. 检查 R 进程
cat("\n🔍 步骤 1/2: 检查 R 进程\n")
cat("-" , rep("-", 50), "\n", sep = "")

process_ok <- check_r_processes()

if (!process_ok) {
  cat("\n❌ 检测到冲突的 R 进程，清理已取消\n")
  cat("💡 请先关闭所有 R 进程后再运行此脚本\n")
  quit(status = 1)
}

# 2. 清理锁文件
cat("\n🔍 步骤 2/2: 清理锁文件\n")
cat("-" , rep("-", 50), "\n", sep = "")

cleaned_count <- cleanup_locks(verbose = TRUE)

# 3. 给出建议
cat("\n💡 下一步:\n")
if (cleaned_count > 0) {
  cat("   运行以下命令启动 Biofree:\n")
  cat("   source(\"launch_app.R\")\n")
} else {
  cat("   如果仍然遇到问题，可以尝试:\n")
  cat("   1. 重启电脑（清除所有锁定）\n")
  cat("   2. 在 RStudio 中手动更新:\n")
  cat("      BiocManager::install('org.Hs.eg.db', update=TRUE)\n")
  cat("      BiocManager::install('org.Mm.eg.db', update=TRUE)\n")
  cat("   3. 临时禁用自动更新:\n")
  cat("      Sys.setenv(AUTO_UPDATE_DB = \"FALSE\")\n")
  cat("      source(\"launch_app.R\")\n")
}

cat("\n")
