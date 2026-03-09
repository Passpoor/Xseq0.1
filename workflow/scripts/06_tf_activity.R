#!/usr/bin/env Rscript
# =====================================================
# BioFastFree Snakemake - 转录因子活性分析 (decoupleR)
# =====================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(decoupleR)
  library(ggplot2)
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
method <- parse_arg("method", "ulm")

if (is.null(deg_file) || is.null(output_csv) || is.null(output_pdf)) {
  stop("Usage: Rscript 06_tf_activity.R --deg=DEG.csv --output_csv=OUT.csv --output_pdf=OUT.pdf [--species=Mm] [--method=ulm]")
}

deg <- read.csv(deg_file, stringsAsFactors = FALSE)

# 需要 SYMBOL 和 t_stat
if (!"t_stat" %in% colnames(deg)) {
  deg$t_stat <- qnorm(1 - deg$pvalue / 2) * sign(deg$log2FoldChange)
}

stats_df <- deg %>%
  filter(!is.na(SYMBOL), !is.na(t_stat), is.finite(t_stat), t_stat != 0) %>%
  group_by(SYMBOL) %>%
  filter(abs(log2FoldChange) == max(abs(log2FoldChange))) %>%
  ungroup() %>%
  distinct(SYMBOL, .keep_all = TRUE) %>%
  select(SYMBOL, t_stat)

if (nrow(stats_df) < 5) {
  stop("有效基因数不足 5 个，无法进行 TF 活性分析")
}

organism <- if (species == "Mm") "mouse" else "human"
collectri_dir <- parse_arg("collectri_dir", ".")
net_file <- file.path(collectri_dir, paste0("collectri_", organism, ".rds"))

if (file.exists(net_file)) {
  net <- readRDS(net_file)
} else {
  message("下载 CollecTRI 网络...")
  net <- decoupleR::get_collectri(organism = organism, split_complexes = FALSE)
  dir.create(collectri_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(net, net_file)
}

mat_input <- stats_df %>% column_to_rownames("SYMBOL") %>% as.matrix()

run_tf <- switch(method,
  ulm = decoupleR::run_ulm(mat_input, net, .source = "source", .target = "target", .mor = "mor"),
  mlm = decoupleR::run_mlm(mat_input, net, .source = "source", .target = "target", .mor = "mor"),
  wsum = decoupleR::run_wsum(mat_input, net, .source = "source", .target = "target", .mor = "mor"),
  viper = decoupleR::run_viper(mat_input, net, .source = "source", .target = "target", .mor = "mor"),
  decoupleR::run_ulm(mat_input, net, .source = "source", .target = "target", .mor = "mor")
)

# decoupleR 返回 source, target, statistic, score, p_value 等列
df_out <- run_tf %>%
  select(source, score, p_value) %>%
  distinct(source, .keep_all = TRUE) %>%
  arrange(p_value)

dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
write.csv(df_out, output_csv, row.names = FALSE)
message("TF 活性结果已保存: ", output_csv)

# 条形图
df_plot <- head(df_out[order(df_out$p_value), ], 20)
df_plot$source <- factor(df_plot$source, levels = rev(df_plot$source))

p <- ggplot(df_plot, aes(x = score, y = source, fill = -log10(p_value + 1e-10))) +
  geom_col() +
  scale_fill_gradient(low = "#3498db", high = "#e74c3c") +
  labs(x = "Activity Score", y = "Transcription Factor", fill = "-log10(P)") +
  theme_bw(base_size = 10) +
  theme(axis.text.y = element_text(size = 9))
ggsave(output_pdf, p, width = 8, height = max(5, nrow(df_plot) * 0.25))
message("TF 活性图已保存: ", output_pdf)
