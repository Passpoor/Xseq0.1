# 语法测试文件
test_observe <- function(input) {
  n <- 2
  files <- list()
  gene_cols <- list()
  counter <- 1

  for (i in 1:n) {
    file_input <- input[[sprintf("background_file_%d", i)]]

    if (!is.null(file_input)) {
      files[[counter]] <- list(
        index = counter,
        name = file_input$name,
        path = file_input$datapath,
        size = file_input$size
      )

      tryCatch({
        cols <- names(read.csv(file_input$datapath, nrows = 0))
        gene_col <- grep("^gene$|^Gene$|^SYMBOL$|^symbol", cols,
                        ignore.case = TRUE, value = TRUE)[1]
        gene_cols[[counter]] <- if (!is.na(gene_col)) gene_col else cols[1]
      }, error = function(e) {
        gene_cols[[counter]] <- NULL
      })

      counter <- counter + 1
    }
  }

  return(list(files = files, gene_cols = gene_cols))
}

print("语法测试通过！")
