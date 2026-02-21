# =====================================================
# RNAseq分析工具 - 包依赖安装脚本
# =====================================================

# 检查并安装CRAN包
install_cran_packages <- function() {
  cran_packages <- c(
    "shiny", "shinyjs", "bslib", "RSQLite", "DBI",
    "ggplot2", "dplyr", "DT", "pheatmap", "plotly",
    "colourpicker", "shinyWidgets", "rlang",
    "tibble", "tidyr", "ggrepel", "RColorBrewer",
    "VennDiagram", "grid", "gridExtra", "svglite", "Cairo",
    "httr", "jsonlite"
  )

  for (pkg in cran_packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      install.packages(pkg, dependencies = TRUE)
      cat("已安装包:", pkg, "\n")
    } else {
      cat("包已存在:", pkg, "\n")
    }
  }
}

# 检查并安装Bioconductor包
install_bioc_packages <- function() {
  bioc_packages <- c(
    "edgeR", "limma", "AnnotationDbi", "clusterProfiler",
    "org.Mm.eg.db", "org.Hs.eg.db", "GseaVis", "enrichplot"
  )

  # 检查是否已安装BiocManager
  if (!require("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
  }

  for (pkg in bioc_packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      BiocManager::install(pkg)
      cat("已安装Bioconductor包:", pkg, "\n")
    } else {
      cat("Bioconductor包已存在:", pkg, "\n")
    }
  }
}

# 安装decoupleR包
install_decoupleR <- function() {
  if (!require("decoupleR", quietly = TRUE)) {
    # 尝试从CRAN安装
    if (!require("decoupleR", quietly = TRUE)) {
      # 如果CRAN没有，从GitHub安装
      if (!require("remotes", quietly = TRUE)) {
        install.packages("remotes")
      }
      remotes::install_github("saezlab/decoupleR")
      cat("已从GitHub安装decoupleR包\n")
    }
  } else {
    cat("decoupleR包已存在\n")
  }
}

# 安装biofree.qyKEGGtools包
install_biofree_kegg <- function() {
  if (!require("biofree.qyKEGGtools", quietly = TRUE)) {
    if (!require("remotes", quietly = TRUE)) {
      install.packages("remotes")
    }
    # 这里需要实际的GitHub仓库地址
    # remotes::install_github("username/biofree.qyKEGGtools")
    cat("注意: biofree.qyKEGGtools 需要从特定仓库安装\n")
    cat("请手动安装: remotes::install_github('username/biofree.qyKEGGtools')\n")
  } else {
    cat("biofree.qyKEGGtools包已存在\n")
  }
}

# 主安装函数
main_install <- function() {
  cat("开始安装RNAseq分析工具依赖包...\n\n")

  cat("1. 安装CRAN包...\n")
  install_cran_packages()

  cat("\n2. 安装Bioconductor包...\n")
  install_bioc_packages()

  cat("\n3. 安装decoupleR包...\n")
  install_decoupleR()

  cat("\n4. 安装biofree.qyKEGGtools包...\n")
  install_biofree_kegg()

  cat("\n安装完成!\n")
  cat("现在可以运行应用: shiny::runApp('app.R')\n")
}

# 执行安装
if (interactive()) {
  main_install()
}