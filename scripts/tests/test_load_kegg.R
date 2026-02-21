#!/usr/bin/env Rscript

# Test script to load kegg_enrichment.R
# This will help us verify if the syntax error is fixed

tryCatch({
  source("modules/kegg_enrichment.R")
  message("SUCCESS: kegg_enrichment.R loaded without errors!")
}, error = function(e) {
  message("ERROR: Failed to load kegg_enrichment.R")
  message("Error message: ", e$message)
  quit(status = 1)
})
