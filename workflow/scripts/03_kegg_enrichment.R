#!/usr/bin/env Rscript
# =====================================================
# BioFastFree Snakemake - KEGG 富集分析
# 优先 clusterProfiler::enrichKEGG，备选 biofree.qyKEGGtools
# =====================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(AnnotationDbi)
  try(library(org.Mm.eg.db), silent = TRUE)
  try(library(org.Hs.eg.db), silent = TRUE)
})

args <- commandArgs(trailingOnly = TRUE)
parse_arg <- function(name, default = NULL) {
  idx <- grep(paste0("^--", name, "="), args)
  if (length(idx) == 0) {
    idx <- match(paste0("--", name), args)
    if (!is.na(idx) && idx < length(args)) return(args[idx + 1])
    return(default)
  }
  sub(paste0("^--", name, "="), "", args[idx][1])
}

deg_file <- parse_arg("deg")
output_csv <- parse_arg("output_csv")
output_pdf <- parse_arg("output_pdf")
species <- parse_arg("species", "mmu")
direction <- parse_arg("direction", "Up")
pval_cutoff <- as.numeric(parse_arg("pval_cutoff", "0.05"))

if (is.null(deg_file) || is.null(output_csv) || is.null(output_pdf)) {
  stop("Usage: Rscript 03_kegg_enrichment.R --deg=DEG.csv --output_csv=OUT.csv --output_pdf=OUT.pdf [--species=mmu] [--direction=Up] [--pval_cutoff=0.05]")
}

deg <- read.csv(deg_file, stringsAsFactors = FALSE)
target_status <- switch(direction, "Up" = "Up", "Down" = "Down", "All" = c("Up", "Down"))

ids <- deg %>% filter(Status %in% target_status & !is.na(ENTREZID)) %>% pull(ENTREZID)
ids <- as.character(unique(ids))

if (length(ids) == 0) {
  stop("无有效 ENTREZID，请检查 DEG 文件中的基因注释")
}

# 背景基因（检测到的所有基因）
bg_entrez <- deg %>% filter(!is.na(ENTREZID)) %>% pull(ENTREZID) %>% unique() %>% as.character()

kegg_obj <- NULL

# 优先使用 clusterProfiler::enrichKEGG
if (requireNamespace("clusterProfiler", quietly = TRUE)) {
  tryCatch({
    kegg_obj <- clusterProfiler::enrichKEGG(
      gene = ids,
      organism = species,
      pvalueCutoff = pval_cutoff,
      qvalueCutoff = 0.2,
      universe = if (length(bg_entrez) > 0) bg_entrez else NULL
    )
  }, error = function(e) message("clusterProfiler::enrichKEGG 失败: ", e$message))
}

# 备选 biofree.qyKEGGtools
if ((is.null(kegg_obj) || nrow(kegg_obj@result) == 0) && requireNamespace("biofree.qyKEGGtools", quietly = TRUE)) {
  tryCatch({
    kegg_obj <- biofree.qyKEGGtools::enrich_local_KEGG(
      gene = ids,
      species = species,
      pCutoff = pval_cutoff
    )
  }, error = function(e) message("biofree.qyKEGGtools 失败: ", e$message))
}

if (is.null(kegg_obj) || (inherits(kegg_obj, "enrichResult") && nrow(kegg_obj@result) == 0)) {
  message("KEGG 富集无显著结果，生成空输出")
  df_out <- data.frame(ID = character(), Description = character(), GeneRatio = character(),
    BgRatio = character(), pvalue = numeric(), p.adjust = numeric(), qvalue = numeric(),
    geneID = character(), Count = integer(), stringsAsFactors = FALSE)
} else {
  df_out <- kegg_obj@result
  df_out$Description <- gsub(" - Mus musculus.*| - Homo sapiens.*", "", df_out$Description)

  # ENTREZID 转 SYMBOL
  db_pkg <- if (species == "mmu") "org.Mm.eg.db" else "org.Hs.eg.db"
  if (require(db_pkg, character.only = TRUE, quietly = TRUE)) {
    db <- get(db_pkg)
    all_entrez <- unique(unlist(strsplit(df_out$geneID, "/")))
    mapped <- suppressMessages(AnnotationDbi::mapIds(db, keys = all_entrez, column = "SYMBOL",
      keytype = "ENTREZID", multiVals = "first"))
    df_out$geneID <- sapply(df_out$geneID, function(x) {
      ids <- unlist(strsplit(x, "/"))
      syms <- mapped[ids]
      syms[is.na(syms)] <- ids[is.na(syms)]
      paste(syms, collapse = "/")
    })
  }
}

# 输出 CSV
dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
write.csv(df_out, output_csv, row.names = FALSE)
message("KEGG 结果已保存: ", output_csv)

# 点图
if (nrow(df_out) > 0) {
  df_plot <- head(df_out[order(df_out$p.adjust), ], 20)
  df_plot$Count <- as.integer(sapply(strsplit(df_plot$GeneRatio, "/"), `[`, 1))
  df_plot$Description <- factor(df_plot$Description, levels = rev(df_plot$Description))

  p <- ggplot(df_plot, aes(x = Count, y = Description, size = Count, color = p.adjust)) +
    geom_point() +
    scale_color_gradient(low = "#e74c3c", high = "#3498db") +
    labs(x = "Gene Count", y = "", color = "Adj.P", size = "Count") +
    theme_bw(base_size = 10) +
    theme(axis.text.y = element_text(size = 9))
  ggsave(output_pdf, p, width = 8, height = max(5, nrow(df_plot) * 0.25))
  message("KEGG 点图已保存: ", output_pdf)
} else {
  pdf(output_pdf, width = 6, height = 4)
  plot.new()
  text(0.5, 0.5, "No significant KEGG enrichment", cex = 1.2)
  dev.off()
}
