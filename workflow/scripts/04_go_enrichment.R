#!/usr/bin/env Rscript
# =====================================================
# BioFastFree Snakemake - GO 富集分析
# =====================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(clusterProfiler)
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
species <- parse_arg("species", "Mm")
ontology <- parse_arg("ontology", "ALL")
pval_cutoff <- as.numeric(parse_arg("pval_cutoff", "0.05"))

if (is.null(deg_file) || is.null(output_csv) || is.null(output_pdf)) {
  stop("Usage: Rscript 04_go_enrichment.R --deg=DEG.csv --output_csv=OUT.csv --output_pdf=OUT.pdf [--species=Mm] [--ontology=ALL] [--pval_cutoff=0.05]")
}

deg <- read.csv(deg_file, stringsAsFactors = FALSE)
ids <- deg %>% filter(Status %in% c("Up", "Down") & !is.na(ENTREZID)) %>% pull(ENTREZID)
ids <- as.character(unique(ids))
bg_entrez <- deg %>% filter(!is.na(ENTREZID)) %>% pull(ENTREZID) %>% unique() %>% as.character()

if (length(ids) == 0) stop("无有效 ENTREZID")

db_pkg <- if (species == "Mm") "org.Mm.eg.db" else "org.Hs.eg.db"
if (!require(db_pkg, character.only = TRUE, quietly = TRUE)) stop("请安装 ", db_pkg)
db_obj <- get(db_pkg)

go_obj <- enrichGO(
  gene = ids,
  OrgDb = db_obj,
  keyType = "ENTREZID",
  ont = ontology,
  pAdjustMethod = "BH",
  pvalueCutoff = pval_cutoff,
  qvalueCutoff = 0.2,
  readable = TRUE,
  universe = if (length(bg_entrez) > 0) bg_entrez else NULL
)

if (is.null(go_obj) || nrow(go_obj@result) == 0) {
  message("GO 富集无显著结果")
  df_out <- data.frame(ID = character(), Description = character(), GeneRatio = character(),
    BgRatio = character(), pvalue = numeric(), p.adjust = numeric(), qvalue = numeric(),
    geneID = character(), Count = integer(), stringsAsFactors = FALSE)
} else {
  df_out <- go_obj@result
  df_out$Description <- gsub("\\s*\\(.*\\)$", "", df_out$Description)
}

dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
write.csv(df_out, output_csv, row.names = FALSE)
message("GO 结果已保存: ", output_csv)

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
  ggsave(output_pdf, p, width = 9, height = max(5, nrow(df_plot) * 0.25))
  message("GO 点图已保存: ", output_pdf)
} else {
  pdf(output_pdf, width = 6, height = 4)
  plot.new()
  text(0.5, 0.5, "No significant GO enrichment", cex = 1.2)
  dev.off()
}
