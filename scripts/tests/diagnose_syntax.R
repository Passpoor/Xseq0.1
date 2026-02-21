#!/usr/bin/env Rscript

# Diagnostic script to check syntax of kegg_enrichment.R

cat("Checking syntax of modules/kegg_enrichment.R...\n\n")

# Try to parse the file without sourcing it
tryCatch({
  parse("modules/kegg_enrichment.R")
  cat("✅ SUCCESS: File syntax is valid!\n")
  cat("The file can be parsed without errors.\n")
}, error = function(e) {
  cat("❌ ERROR: Syntax error found!\n")
  cat("Error message:", e$message, "\n\n")

  # Try to get more details
  if (!is.null(attr(e, "call"))) {
    cat("Error call:", deparse(attr(e, "call")), "\n\n")
  }

  quit(status = 1)
})
