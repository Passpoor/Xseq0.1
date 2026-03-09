#!/usr/bin/env Rscript
# =====================================================
# BioFastFree Snakemake - 差异分析 (limma-voom / edgeR)
# =====================================================

suppressPackageStartupMessages({
  library(edgeR)
  library(limma)
  library(dplyr)
  library(AnnotationDbi)
  try(library(org.Mm.eg.db), silent = TRUE)
  try(library(org.Hs.eg.db), silent = TRUE)
})

# 解析命令行参数
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

counts_file <- parse_arg("counts")
design_file <- parse_arg("design")
output_file <- parse_arg("output")
species <- parse_arg("species", "Mm")
pval_cutoff <- as.numeric(parse_arg("pval_cutoff", "0.05"))
log2fc_cutoff <- as.numeric(parse_arg("log2fc_cutoff", "1"))
method <- parse_arg("method", "auto")

if (is.null(counts_file) || is.null(design_file) || is.null(output_file)) {
  stop("Usage: Rscript 01_differential_analysis.R --counts=COUNTS --design=DESIGN --output=OUTPUT [--species=Mm] [--pval_cutoff=0.05] [--log2fc_cutoff=1] [--method=auto]")
}

# 读取数据
counts_df <- read.csv(counts_file, row.names = 1, check.names = FALSE)
design_df <- read.csv(design_file, stringsAsFactors = FALSE)

# 确保 design 包含 sample, group
if (!all(c("sample", "group") %in% colnames(design_df))) {
  stop("design.csv 必须包含 'sample' 和 'group' 列。group 取值为 Control 或 Treatment")
}

# 样本与组别
samples <- design_df$sample
groups <- factor(design_df$group, levels = c("Control", "Treatment"))
ctrl_samples <- design_df$sample[design_df$group == "Control"]
trt_samples <- design_df$sample[design_df$group == "Treatment"]

# 检查样本是否在 counts 中
missing <- setdiff(samples, colnames(counts_df))
if (length(missing) > 0) stop("design 中的样本不在 counts 中: ", paste(missing, collapse = ", "))

counts_use <- as.matrix(counts_df[, samples, drop = FALSE])
group <- factor(c(rep("Control", length(ctrl_samples)), rep("Treatment", length(trt_samples))),
                levels = c("Control", "Treatment"))
min_replicates <- min(length(ctrl_samples), length(trt_samples))

# 基因注释
annotate_genes <- function(gene_ids, sp) {
  db_pkg <- if (sp == "Mm") "org.Mm.eg.db" else "org.Hs.eg.db"
  if (!require(db_pkg, character.only = TRUE, quietly = TRUE)) return(NULL)
  db <- get(db_pkg)
  clean <- trimws(gene_ids)
  clean <- gsub("[^[:alnum:]._-]", "", clean)
  is_ens <- grepl("^ENS", clean, ignore.case = TRUE)
  anno <- tryCatch({
    if (any(is_ens)) {
      suppressMessages(AnnotationDbi::select(db, keys = unique(clean[is_ens]),
        columns = c("SYMBOL", "ENTREZID"), keytype = "ENSEMBL"))
    } else {
      suppressMessages(AnnotationDbi::select(db, keys = unique(clean[!is_ens]),
        columns = c("SYMBOL", "ENTREZID"), keytype = "SYMBOL"))
    }
  }, error = function(e) NULL)
  if (is.null(anno) || nrow(anno) == 0) return(NULL)
  anno <- anno[!duplicated(anno[[1]]), ]
  anno
}

# 差异分析
perform_deg <- function(mat, grp, min_rep) {
  dge <- DGEList(counts = mat, group = grp)
  dge <- calcNormFactors(dge)
  keep <- filterByExpr(dge)
  dge <- dge[keep, , keep.lib.sizes = FALSE]

  if (min_rep >= 3 && (method == "auto" || method == "limma")) {
    design <- model.matrix(~ 0 + grp)
    colnames(design) <- levels(grp)
    v <- voom(dge, design, plot = FALSE)
    fit <- lmFit(v, design)
    cm <- makeContrasts(Treatment_vs_Control = Treatment - Control, levels = design)
    fit2 <- contrasts.fit(fit, cm)
    fit2 <- eBayes(fit2)
    res <- topTable(fit2, coef = "Treatment_vs_Control", number = Inf)
    res$GeneID <- rownames(res)
    res <- res %>% rename(log2FoldChange = logFC, pvalue = P.Value, padj = adj.P.Val, t_stat = t)
  } else {
    dge <- estimateDisp(dge)
    et <- exactTest(dge, pair = c("Control", "Treatment"))
    res <- topTags(et, n = Inf)$table
    res$GeneID <- rownames(res)
    res <- res %>% rename(log2FoldChange = logFC, pvalue = PValue, padj = FDR)
    res$t_stat <- qnorm(1 - res$pvalue / 2) * sign(res$log2FoldChange)
  }

  res$baseMean <- rowMeans(edgeR::cpm(dge, log = FALSE, prior.count = 1))
  res$logCPM <- rowMeans(edgeR::cpm(dge, log = TRUE, prior.count = 1))
  res
}

res <- perform_deg(counts_use, group, min_replicates)

# 添加 Status
res$Status <- ifelse(
  res$padj < pval_cutoff & abs(res$log2FoldChange) > log2fc_cutoff,
  ifelse(res$log2FoldChange > 0, "Up", "Down"),
  "Not DE"
)

# 基因注释
anno <- annotate_genes(res$GeneID, species)
if (!is.null(anno)) {
  key_col <- if (any(grepl("^ENS", res$GeneID, ignore.case = TRUE))) "ENSEMBL" else "SYMBOL"
  if (key_col %in% colnames(anno)) {
    idx <- match(res$GeneID, anno[[key_col]])
    res$SYMBOL <- anno$SYMBOL[idx]
    res$ENTREZID <- anno$ENTREZID[idx]
  }
}
if (!"SYMBOL" %in% colnames(res)) res$SYMBOL <- res$GeneID
if (!"ENTREZID" %in% colnames(res)) res$ENTREZID <- NA_character_

# 输出
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
write.csv(res, output_file, row.names = FALSE)
message("DEG 结果已保存: ", output_file)
message("显著差异基因数 (padj<", pval_cutoff, ", |log2FC|>", log2fc_cutoff, "): ",
        sum(res$Status != "Not DE", na.rm = TRUE))
