# Biofree项目诊断脚本
# 用途：快速诊断常见问题
# 使用：source("scripts/diagnose.R"); diagnose_biofree()

diagnose_biofree <- function() {
  message("\n")
  message(rep("=", 60), collapse = "")
  message("  Biofree项目诊断工具")
  message(rep("=", 60), collapse = "")
  message("\n")

  # 1. 检查项目结构
  message("【1/6】检查项目结构...")
  required_dirs <- c("modules", "data", "config", "www", "scripts")
  dir_status <- list()

  for (dir in required_dirs) {
    exists <- dir.exists(dir)
    dir_status[[dir]] <- exists

    if (exists) {
      # 检查是否为空
      files <- list.files(dir)
      if (length(files) == 0) {
        message("  ⚠️  ", dir, " (存在但为空)")
        dir_status[[dir]] <- "empty"
      } else {
        message("  ✅ ", dir, " (包含 ", length(files), " 个文件)")
      }
    } else {
      message("  ❌ ", dir, " (缺失)")
    }
  }

  # 2. 检查数据库
  message("\n【2/6】检查数据库...")
  db_files <- c(
    "data/biofree_annotation.db",
    "data/biofree_annotation.db-shm",
    "data/biofree_annotation.db-wal",
    "data/biofree_users.sqlite"
  )

  db_status <- list()
  for (f in db_files) {
    if (file.exists(f)) {
      size <- file.info(f)$size
      size_mb <- size / (1024 * 1024)
      db_status[[f]] <- size

      if (grepl("-shm|-wal", f)) {
        message("  ⚠️  ", f, " (", format(size, big.mark = ","), " bytes) - 锁文件")
      } else {
        message("  ✅ ", f, " (", round(size_mb, 2), " MB)")
      }
    } else {
      message("  - ", f, " (不存在)")
      db_status[[f]] <- NULL
    }
  }

  # 检查是否需要清理锁文件
  has_lock <- any(sapply(db_files, function(f) {
    file.exists(f) && grepl("-shm|-wal", f)
  }))

  if (has_lock) {
    message("\n  💡 提示: 发现数据库锁文件，运行清理脚本:")
    message("     source(\"scripts/cleanup_r_locks.R\")")
  }

  # 3. 检查R包
  message("\n【3/6】检查R包依赖...")
  required_pkgs <- list(
    shiny = "1.7.0",
    DBI = "1.1.0",
    RSQLite = "2.2.0",
    dplyr = "1.0.0",
    ggplot2 = "3.3.0",
    biomaRt = "2.50.0",
    KEGGREST = "1.34.0",
    AnnotationDbi = "1.56.0"
  )

  pkg_status <- list()
  missing_pkgs <- c()
  outdated_pkgs <- c()

  for (pkg in names(required_pkgs)) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      current_ver <- packageVersion(pkg)
      min_ver <- required_pkgs[[pkg]]
      pkg_status[[pkg]] <- as.character(current_ver)

      if (current_ver < package_version(min_ver)) {
        message("  ⚠️  ", pkg, " ", current_ver, " (建议: ", min_ver, " 或更高)")
        outdated_pkgs <- c(outdated_pkgs, pkg)
      } else {
        message("  ✅ ", pkg, " ", current_ver)
      }
    } else {
      message("  ❌ ", pkg, " (未安装)")
      pkg_status[[pkg]] <- NULL
      missing_pkgs <- c(missing_pkgs, pkg)
    }
  }

  if (length(missing_pkgs) > 0) {
    message("\n  💡 安装缺失的包:")
    message("     install.packages(c(\"",
            paste(missing_pkgs, collapse = "\", \""), "\"))")
  }

  # 4. 检查网络连接
  message("\n【4/6】检查外部API连接...")
  network_status <- list()

  # 检查KEGG
  message("  检查 KEGG API...")
  kegg_result <- tryCatch({
    test <- KEGGREST::keggList("organism", limit = 1)
    network_status[["kegg"]] <- TRUE
    message("    ✅ KEGG API 连接正常")
    TRUE
  }, error = function(e) {
    network_status[["kegg"]] <- FALSE
    message("    ❌ KEGG API 连接失败: ", e$message)
    FALSE
  })

  # 检查Ensembl BioMart
  message("  检查 Ensembl BioMart...")
  biomart_result <- tryCatch({
    mart <- biomaRt::useMart("ensembl", dataset = "mmusculus_gene_ensembl")
    network_status[["biomart"]] <- TRUE
    message("    ✅ Ensembl BioMart 连接正常")
    TRUE
  }, error = function(e) {
    network_status[["biomart"]] <- FALSE
    message("    ❌ Ensembl BioMart 连接失败: ", e$message)
    message("    💡 可能原因: 网络问题或Ensembl维护中")
    message("    💡 解决方案: 查看 BUG_FIX_MANUAL.md 'Ensembl ID注释失败' 章节")
    FALSE
  })

  # 5. 检查临时文件
  message("\n【5/6】检查临时文件...")
  temp_patterns <- c("\\.rds$", "\\.Rhistory$", "\\.RData$")
  temp_files <- list.files(pattern = paste(temp_patterns, collapse = "|"))

  if (length(temp_files) > 0) {
    message("  ⚠️  发现 ", length(temp_files), " 个临时文件:")
    for (f in head(temp_files, 5)) {
      size <- file.info(f)$size
      message("    - ", f, " (", format(size, big.mark = ","), " bytes)")
    }
    if (length(temp_files) > 5) {
      message("    ... 还有 ", length(temp_files) - 5, " 个文件")
    }
    message("\n  💡 清理临时文件:")
    message("     source(\"scripts/cleanup_temp_files.R\")")
  } else {
    message("  ✅ 无多余临时文件")
  }

  # 6. 检查Git状态
  message("\n【6/6】检查Git状态...")
  git_status <- tryCatch({
    # 检查是否是Git仓库
    system2("git", c("status", "--short"), stdout = TRUE, stderr = TRUE)
    message("  ✅ Git 仓库可用")
    TRUE
  }, error = function(e) {
    message("  ⚠️  Git 仓库检查失败")
    FALSE
  }, warning = function(w) {
    message("  - Git 未初始化或不可用")
    FALSE
  })

  # 生成诊断摘要
  message("\n")
  message(rep("=", 60), collapse = "")
  message("  诊断摘要")
  message(rep("=", 60), collapse = "")

  # 统计问题
  issues <- list()
  if (any(!unlist(dir_status))) {
    issues <- c(issues, "项目结构不完整")
  }
  if (has_lock) {
    issues <- c(issues, "数据库锁文件存在")
  }
  if (length(missing_pkgs) > 0) {
    issues <- c(issues, paste("缺失", length(missing_pkgs), "个R包"))
  }
  if (!kegg_result || !biomart_result) {
    issues <- c(issues, "外部API连接问题")
  }

  if (length(issues) == 0) {
    message("\n✅ 所有检查通过！项目状态良好。\n")
  } else {
    message("\n⚠️  发现 ", length(issues), " 个潜在问题:")
    for (i in seq_along(issues)) {
      message("  ", i, ". ", issues[[i]])
    }
    message("\n💡 建议操作:")
    if (has_lock) {
      message("  1. 运行: source(\"scripts/cleanup_r_locks.R\")")
    }
    if (length(missing_pkgs) > 0) {
      message("  2. 安装缺失的R包")
    }
    if (!kegg_result || !biomart_result) {
      message("  3. 查看 BUG_FIX_MANUAL.md 网络问题章节")
    }
    message("\n📚 完整解决方案: 查看 BUG_FIX_MANUAL.md\n")
  }

  # 返回诊断结果（可用于脚本自动化）
  invisible(list(
    project_structure = dir_status,
    database = db_status,
    packages = pkg_status,
    network = network_status,
    timestamp = Sys.time()
  ))
}

# 快速检查函数
quick_check <- function() {
  message("快速检查...\n")

  checks <- list(
    "项目文件" = file.exists("app.R"),
    "数据库" = file.exists("data/biofree_annotation.db"),
    "配置文件" = file.exists("config/config.R"),
    "模块目录" = dir.exists("modules")
  )

  all_ok <- TRUE

  for (name in names(checks)) {
    if (checks[[name]]) {
      message("✅ ", name)
    } else {
      message("❌ ", name)
      all_ok <<- FALSE
    }
  }

  if (all_ok) {
    message("\n✨ 基本检查通过！可以启动应用。")
  } else {
    message("\n⚠️  请修复上述问题后再启动应用。")
  }

  invisible(all_ok)
}

# 修复建议函数
get_fix_suggestions <- function(diagnosis_result) {
  suggestions <- list()

  # 根据诊断结果提供修复建议
  if (is.null(diagnosis_result$packages$shiny)) {
    suggestions <- c(suggestions, "安装Shiny: install.packages('shiny')")
  }

  if (!is.null(diagnosis_result$database[["data/biofree_annotation.db-shm"]])) {
    suggestions <- c(suggestions, "清理数据库锁: source('scripts/cleanup_r_locks.R')")
  }

  if (!diagnosis_result$network$biomart) {
    suggestions <- c(suggestions, "检查网络连接或查看BUG_FIX_MANUAL.md Ensembl章节")
  }

  return(suggestions)
}

# 执行提示
if (interactive()) {
  message("\n💡 使用方法:")
  message("  diagnose_biofree()    # 完整诊断")
  message("  quick_check()          # 快速检查\n")
}
