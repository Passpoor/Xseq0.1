#!/usr/bin/env Rscript

# Test sparse list fix for background file upload
# This simulates the scenario where file reading fails

cat("Testing sparse list fix...\n\n")

# Simulate the problem
files <- list()
gene_cols <- list()
counter <- 1

# File 1: Success
file_1 <- list(index = 1, name = "file1.csv", path = "/tmp/file1.csv", size = 1000)
tryCatch({
  cols <- c("gene", "log2FC", "padj")
  gene_col <- "gene"
  files[[counter]] <- file_1
  gene_cols[[counter]] <- gene_col
  counter <- counter + 1
  cat("✓ File 1 processed successfully\n")
}, error = function(e) {
  cat("✗ File 1 failed\n")
})

# File 2: Reading failure (should NOT be added)
file_input_2 <- list(name = "file2.csv", datapath = "/tmp/file2.csv")
tryCatch({
  cols <- names(read.csv(file_input_2$datapath, nrows = 0))
}, error = function(e) {
  cat("✗ File 2 reading failed (as expected)\n")
  # Do NOT add to files or gene_cols
})

# File 3: Success
file_3 <- list(index = 2, name = "file3.csv", path = "/tmp/file3.csv", size = 2000)
tryCatch({
  cols <- c("Gene", "log2FC", "padj")
  gene_col <- "Gene"
  files[[counter]] <- file_3
  gene_cols[[counter]] <- gene_col
  counter <- counter + 1
  cat("✓ File 3 processed successfully\n")
}, error = function(e) {
  cat("✗ File 3 failed\n")
})

cat("\nResult:\n")
cat(sprintf("files length: %d\n", length(files)))
cat(sprintf("gene_cols length: %d\n", length(gene_cols)))
cat(sprintf("counter: %d\n\n", counter - 1))

# Test iteration safety
cat("Testing safe iteration...\n")
for (i in seq_along(files)) {
  f <- files[[i]]
  col <- gene_cols[[i]]

  if (is.null(f)) {
    cat(sprintf("  [%d] files[[%d]] is NULL ✗\n", i, i))
  } else if (is.null(col)) {
    cat(sprintf("  [%d] gene_cols[[%d]] is NULL ✗\n", i, i))
  } else {
    cat(sprintf("  [%d] File: %s, Column: %s ✓\n", i, f$name, col))
  }
}

cat("\n✅ Test completed: No '下标出界' error!\n")
