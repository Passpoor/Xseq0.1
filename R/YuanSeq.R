# =====================================================
# YuanSeq: RNA-seq & Microarray Analysis Platform
# =====================================================

#' @title YuanSeq
#' @description A comprehensive R/Shiny platform for RNA-seq, microarray and
#'   single-cell downstream analysis.
#' @name YuanSeq
#' @docType package
#' @author Yu Qiao (乔宇)
#' @references \url{https://github.com/Passpoor/Yuanseq}
NULL

#' @title Launch YuanSeq Shiny App
#' @description Start the YuanSeq analysis platform in your default browser.
#' @param ... Additional arguments passed to \code{shiny::runApp()}
#' @return A running Shiny application
#' @export
#' @examples
#' \dontrun{
#' YuanSeq::run_app()
#' }
run_app <- function(...) {
  app_dir <- system.file("shiny", package = "YuanSeq")
  if (app_dir == "") {
    # 开发模式 | Development mode
    app_dir <- file.path(dirname(getwd()), "Biofree_project")
    if (!file.exists(file.path(app_dir, "app.R"))) {
      app_dir <- getwd()
    }
  }
  shiny::runApp(app_dir, launch.browser = TRUE, ...)
}

#' @title Install YuanSeq Dependencies
#' @description Install all required packages for YuanSeq.
#' @param bioc_only Install only Bioconductor packages
#' @param github_only Install only GitHub packages
#' @export
install_deps <- function(bioc_only = FALSE, github_only = FALSE) {
  if (!bioc_only && !github_only) {
    # CRAN packages
    message("Installing CRAN packages...")
    cran_pkgs <- c(
      "shiny", "shinyjs", "bslib", "ggplot2", "dplyr", "DT",
      "pheatmap", "plotly", "colourpicker", "shinyWidgets", "rlang",
      "tibble", "tidyr", "ggrepel", "RColorBrewer", "VennDiagram",
      "grid", "gridExtra", "httr", "jsonlite", "base64enc", "remotes"
    )
    missing <- cran_pkgs[!sapply(cran_pkgs, requireNamespace, quietly = TRUE)]
    if (length(missing) > 0) install.packages(missing)
  }

  if (!github_only) {
    # Bioconductor packages
    message("Installing Bioconductor packages...")
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
      install.packages("BiocManager")
    }
    bioc_pkgs <- c(
      "edgeR", "limma", "AnnotationDbi", "clusterProfiler",
      "org.Mm.eg.db", "org.Hs.eg.db", "GseaVis", "enrichplot",
      "decoupleR", "sva"
    )
    missing <- bioc_pkgs[!sapply(bioc_pkgs, requireNamespace, quietly = TRUE)]
    if (length(missing) > 0) BiocManager::install(missing, ask = FALSE)
  }

  # GitHub packages (optional)
  message("Installing GitHub packages (optional)...")
  tryCatch({
    remotes::install_github("Passpoor/biofree.qyKEGGtools", upgrade = "never")
  }, error = function(e) {
    message("biofree.qyKEGGtools installation skipped: ", e$message)
  })

  message("\nDone! Run YuanSeq::run_app() to launch.")
}
