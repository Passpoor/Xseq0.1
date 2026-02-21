# =====================================================
# Xseq 一键安装脚本
# =====================================================
# 用户使用方式：
# source("https://raw.githubusercontent.com/Passpoor/Xseq0.1/main/install.R")
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
# 下载项目
# =====================================================

cat("\n📥 下载 Xseq...\n")

# 获取项目目录
if (!interactive()) {
  # 非交互模式，使用当前目录
  install_dir <- getwd()
} else {
  # 交互模式，询问用户
  install_dir <- getwd()
}

xseq_dir <- file.path(install_dir, "Xseq")

# 检查是否已存在
if (dir.exists(xseq_dir)) {
  cat(sprintf("📁 发现已有安装: %s\n", xseq_dir))
  cat("   正在更新...\n")

  # 尝试 git pull
  tryCatch({
    setwd(xseq_dir)
    system("git pull")
    setwd(install_dir)
  }, error = function(e) {
    cat("   无法更新，将重新下载\n")
    unlink(xseq_dir, recursive = TRUE)
  })
}

if (!dir.exists(xseq_dir)) {
  # 克隆仓库
  repo_url <- "https://github.com/Passpoor/Xseq0.1.git"

  tryCatch({
    system(sprintf("git clone %s %s", repo_url, xseq_dir))
    cat(sprintf("✅ 下载完成: %s\n", xseq_dir))
  }, error = function(e) {
    # 如果没有 git，尝试下载 zip
    cat("   Git 不可用，尝试下载 ZIP...\n")

    zip_url <- "https://github.com/Passpoor/Xseq0.1/archive/refs/heads/main.zip"
    zip_file <- file.path(install_dir, "Xseq.zip")

    tryCatch({
      download.file(zip_url, zip_file)
      unzip(zip_file, exdir = install_dir)
      file.rename(file.path(install_dir, "Xseq-main"), xseq_dir)
      unlink(zip_file)
      cat(sprintf("✅ 下载完成: %s\n", xseq_dir))
    }, error = function(e2) {
      stop("下载失败，请手动从 GitHub 下载: https://github.com/Passpoor/Xseq0.1")
    })
  })
}

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
