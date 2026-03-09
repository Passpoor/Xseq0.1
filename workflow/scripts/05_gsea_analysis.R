#!/usr/bin/env Rscript
# =====================================================
# BioFastFree Snakemake - GSEA 富集分析
# 需要提供 GMT 文件
# =====================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(clusterProfiler)
  library(ggplot2)
  library(enrichplot)
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
gmt_file <- parse_arg("gmt")
output_csv <- parse_arg("output_csv")
output_pdf <- parse_arg("output_pdf")
pval_cutoff <- as.numeric(parse_arg("pval_cutoff", "0.05"))
id_type <- parse_arg("id_type", "SYMBOL")

if (is.null(deg_file) || is.null(gmt_file) || is.null(output_csv) || is.null(output_pdf)) {
  stop("Usage: Rscript 05_gsea_analysis.R --deg=DEG.csv --gmt=pathways.gmt --output_csv=OUT.csv --output_pdf=OUT.pdf [--pval_cutoff=0.05] [--id_type=SYMBOL]")
}

deg <- read.csv(deg_file, stringsAsFactors = FALSE)
id_col <- if (id_type == "SYMBOL" && "SYMBOL" %in% colnames(deg)) "SYMBOL" else "ENTREZID"

res_clean <- deg %>%
  filter(!is.na(.data[[id_col]]), !is.na(log2FoldChange)) %>%
  group_by(.data[[id_col]]) %>%
  filter(abs(log2FoldChange) == max(abs(log2FoldChange))) %>%
  ungroup() %>%
  distinct(.data[[id_col]], .keep_all = TRUE)

gene_list <- setNames(res_clean$log2FoldChange, res_clean[[id_col]])
gene_list <- sort(gene_list, decreasing = TRUE)

gmt <- clusterProfiler::read.gmt(gmt_file)

# GMT 若为 ENTREZID 而选用 SYMBOL，需转换
if (id_type == "SYMBOL" && all(grepl("^[0-9]+$", head(gmt$gene, 100)))) {
  entrez_to_symbol <- setNames(res_clean$SYMBOL, res_clean$ENTREZID)
  gmt$gene_symbol <- entrez_to_symbol[as.character(gmt$gene)]
  gmt <- gmt %>% filter(!is.na(gene_symbol)) %>% select(term, gene = gene_symbol)
}

gsea_res <- clusterProfiler::GSEA(
  geneList = gene_list,
  TERM2GENE = gmt,
  pvalueCutoff = pval_cutoff,
  minGSSize = 10,
  maxGSSize = 500,
  verbose = FALSE
)

if (is.null(gsea_res) || nrow(gsea_res@result) == 0) {
  message("GSEA 无显著结果")
  df_out <- gsea_res@result
} else {
  df_out <- gsea_res@result
}

dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
write.csv(df_out, output_csv, row.names = FALSE)
message("GSEA 结果已保存: ", output_csv)

if (nrow(df_out) > 0 && requireNamespace("enrichplot", quietly = TRUE)) {
  tryCatch({
    p <- ridgeplot(gsea_res, showCategory = 15) + ggtitle("GSEA Ridge Plot")
    ggsave(output_pdf, p, width = 10, height = 8)
    message("GSEA 图已保存: ", output_pdf)
  }, error = function(e) {
    pdf(output_pdf, width = 8, height = 6)
    barplot(-log10(df_out$p.adjust[1:15]), names.arg = substr(df_out$Description[1:15], 1, 40),
      las = 2, horiz = TRUE, main = "GSEA - Top 15")
    dev.off()
  })
} else {
  pdf(output_pdf, width = 6, height = 4)
  plot.new()
  text(0.5, 0.5, "No significant GSEA results", cex = 1.2)
  dev.off()
}
