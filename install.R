# =====================================================
# Xseq 一键安装脚本
# =====================================================
# 用户使用方式：
# source("https://raw.githubusercontent.com/Passpoor/Xseq0.1/master/install.R")
# =====================================================

cat("
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║     ██╗  ██╗██╗   ██╗██████╗ ███████╗                     ║
║     ╚██╗██╔╝██║   ██║██╔══██╗██╔════╝                     ║
║      ╚███╔╝ ██║   ██║██║  ██║█████╗                       ║
║      ██╔██╗ ██║   ██║██║  ██║██╔══╝                       ║
║     ██╔╝ ██╗╚██████╔╝██████╔╝███████╗                     ║
║     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝                     ║
║                                                            ║
║     Bioinformatics Analysis Platform                       ║
║     Version 13.0                                           ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
")

cat("\n🔍 检查 R 版本...\n")
if (as.numeric(R.Version()$major) < 4) {
  warning("建议使用 R 4.0 或更高版本")
}

# =====================================================
# 安装必要依赖
# =====================================================

cat("\n📦 安装依赖包...\n")

required_packages <- c(
  "shiny",
  "shinydashboard",
  "DT",
  "ggplot2",
  "plotly",
  "dplyr",
  "tidyr",
  "readr",
  "jsonlite",
  "httr",
  "digest",
  "limma",
  "edgeR",
  "clusterProfiler",
  "org.Hs.eg.db",
  "org.Mm.eg.db",
  "enrichplot"
)

# 使用 Bioconductor 安装生物信息学包
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

installed_count <- 0
skipped_count <- 0

for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  ✅ %s (已安装)\n", pkg))
    skipped_count <- skipped_count + 1
  } else {
    cat(sprintf("  📥 安装 %s...\n", pkg))

    # 判断是否为 Bioconductor 包
    bioc_packages <- c("limma", "edgeR", "clusterProfiler",
                       "org.Hs.eg.db", "org.Mm.eg.db", "enrichplot")

    tryCatch({
      if (pkg %in% bioc_packages) {
        BiocManager::install(pkg, ask = FALSE, update = FALSE)
      } else {
        install.packages(pkg, repos = "https://cloud.r-project.org")
      }
      cat(sprintf("  ✅ %s 安装成功\n", pkg))
      installed_count <- installed_count + 1
    }, error = function(e) {
      cat(sprintf("  ❌ %s 安装失败: %s\n", pkg, e$message))
    })
  }
}

cat(sprintf("\n📊 安装完成: 新安装 %d 个, 跳过 %d 个\n", installed_count, skipped_count))

# =====================================================
# 下载项目（优先使用 ZIP，更可靠）
# =====================================================

cat("\n📥 下载 Xseq...\n")

# 获取项目目录
install_dir <- getwd()
xseq_dir <- file.path(install_dir, "Xseq0.1")

# 删除旧的下载（如果存在且不完整）
if (dir.exists(xseq_dir)) {
  # 检查是否有 app.R 文件
  if (!file.exists(file.path(xseq_dir, "app.R"))) {
    cat("   删除不完整的下载...\n")
    unlink(xseq_dir, recursive = TRUE)
  }
}

# 下载函数（使用 ZIP）
download_xseq <- function() {
  zip_url <- "https://codeload.github.com/Passpoor/Xseq0.1/zip/refs/heads/master"
  zip_file <- file.path(install_dir, "Xseq0.1.zip")

  cat("   正在下载 ZIP 文件...\n")

  tryCatch({
    # 下载 ZIP
    download.file(zip_url, zip_file, mode = "wb", quiet = FALSE)

    # 检查文件大小
    file_size <- file.info(zip_file)$size
    if (is.na(file_size) || file_size < 10000) {
      cat("   ⚠️ 下载的文件太小，可能不完整\n")
      return(FALSE)
    }

    cat(sprintf("   下载完成 (%.1f MB)\n", file_size / 1024 / 1024))

    # 解压
    cat("   正在解压...\n")
    unzip(zip_file, exdir = install_dir, overwrite = TRUE)

    # 重命名解压后的目录
    extracted_dir <- file.path(install_dir, "Xseq0.1-master")
    if (dir.exists(extracted_dir)) {
      # 如果目标目录已存在，先删除
      if (dir.exists(xseq_dir)) {
        unlink(xseq_dir, recursive = TRUE)
      }
      file.rename(extracted_dir, xseq_dir)
    }

    # 删除 ZIP 文件
    unlink(zip_file)

    # 验证
    if (file.exists(file.path(xseq_dir, "app.R"))) {
      return(TRUE)
    }

    cat("   ⚠️ 解压后找不到 app.R 文件\n")
    return(FALSE)

  }, error = function(e) {
    cat(sprintf("   ❌ 下载失败: %s\n", e$message))
    return(FALSE)
  })
}

# 执行下载
if (!dir.exists(xseq_dir) || !file.exists(file.path(xseq_dir, "app.R"))) {
  success <- download_xseq()

  if (!success || !file.exists(file.path(xseq_dir, "app.R"))) {
    cat("\n❌ 自动下载失败！\n")
    cat("\n========================================\n")
    cat("请手动下载：\n\n")
    cat("  1. 访问: https://github.com/Passpoor/Xseq0.1\n")
    cat("  2. 点击绿色按钮 'Code' -> 'Download ZIP'\n")
    cat("  3. 解压 ZIP 文件\n")
    cat("  4. 将文件夹 'Xseq0.1-master' 重命名为 'Xseq0.1'\n")
    cat("  5. 在 RStudio 中打开该文件夹\n")
    cat("  6. 运行: source('launch_app.R')\n")
    cat("========================================\n")
    stop("下载失败，请手动下载")
  }
}

cat(sprintf("✅ 下载完成: %s\n", xseq_dir))

# =====================================================
# 启动应用
# =====================================================

cat("\n🚀 准备启动 Xseq...\n")
cat("\n════════════════════════════════════════════════════════\n")
cat("  安装完成！\n")
cat("\n")
cat("  项目位置: ")
cat(xseq_dir)
cat("\n\n")
cat("  启动方式:\n")
cat("  1. 在 RStudio 中打开项目文件夹\n")
cat("  2. 运行: source('launch_app.R')\n")
cat("     或者: shiny::runApp('app.R')\n")
cat("\n")
cat("  📧 激活联系: xseq_fastfreee@163.com\n")
cat("════════════════════════════════════════════════════════\n")

# 询问是否立即启动
if (interactive()) {
  cat("\n是否立即启动 Xseq? (y/n): ")
  answer <- readline()

  if (tolower(answer) == "y" || tolower(answer) == "yes") {
    setwd(xseq_dir)
    source("launch_app.R")
  }
}
