#!/usr/bin/env Rscript
# =====================================================
# BioFastFree Snakemake - 火山图
# =====================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
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
output <- parse_arg("output")
pval_cutoff <- as.numeric(parse_arg("pval_cutoff", "0.05"))
log2fc_cutoff <- as.numeric(parse_arg("log2fc_cutoff", "1"))

if (is.null(deg_file) || is.null(output)) {
  stop("Usage: Rscript 02_volcano_plot.R --deg=DEG.csv --output=volcano.pdf [--pval_cutoff=0.05] [--log2fc_cutoff=1]")
}

deg <- read.csv(deg_file, stringsAsFactors = FALSE)
pval_col <- if ("padj" %in% colnames(deg)) "padj" else "pvalue"

deg <- deg %>%
  mutate(
    neglog10p = -log10(.data[[pval_col]]),
    sig = case_when(
      .data[[pval_col]] < pval_cutoff & log2FoldChange > log2fc_cutoff ~ "Up",
      .data[[pval_col]] < pval_cutoff & log2FoldChange < -log2fc_cutoff ~ "Down",
      TRUE ~ "NS"
    )
  )

label_col <- if ("SYMBOL" %in% colnames(deg) && !all(is.na(deg$SYMBOL))) "SYMBOL" else "GeneID"
top_n <- 20
deg_label <- deg %>%
  filter(sig != "NS") %>%
  arrange(desc(abs(log2FoldChange))) %>%
  head(top_n)

p <- ggplot(deg, aes(x = log2FoldChange, y = neglog10p, color = sig)) +
  geom_point(alpha = 0.6, size = 2) +
  scale_color_manual(values = c(Up = "#e74c3c", Down = "#3498db", NS = "gray70")) +
  geom_hline(yintercept = -log10(pval_cutoff), linetype = "dashed", color = "gray40") +
  geom_vline(xintercept = c(-log2fc_cutoff, log2fc_cutoff), linetype = "dashed", color = "gray40") +
  labs(x = "log2 Fold Change", y = paste0("-log10(", pval_col, ")"), color = "Status") +
  theme_bw(base_size = 12) +
  theme(legend.position = "top")

if (nrow(deg_label) > 0 && requireNamespace("ggrepel", quietly = TRUE)) {
  p <- p + ggrepel::geom_text_repel(
    data = deg_label,
    aes(label = .data[[label_col]]),
    size = 3,
    max.overlaps = 20,
    box.padding = 0.5
  )
}

dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
ggsave(output, p, width = 8, height = 6)
message("火山图已保存: ", output)
