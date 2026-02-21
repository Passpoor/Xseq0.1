# =====================================================
# KEGG富集分析模块
# =====================================================

kegg_enrichment_server <- function(input, output, session, user_session, deg_results) {

  # =====================================================
  # 🆕 多文件背景基因集管理
  # =====================================================
  background_files_data <- reactiveValues(
    files = list(),        # 文件信息列表
    gene_cols = list(),    # 每个文件的基因列名
    n_files = 2            # 默认2个文件
  )

  # 动态生成文件上传UI
  output$background_files_upload_ui <- renderUI({
    n <- background_files_data$n_files

    tagList(
      lapply(1:n, function(i) {
        div(
          style = "margin-bottom: 8px;",
          h6(sprintf("背景文件 %d", i)),
          fileInput(
            inputId = sprintf("background_file_%d", i),
            label = NULL,
            buttonLabel = "上传CSV",
            accept = c(".csv")
          )
        )
      })
    )
  })

  # 添加文件按钮
  observeEvent(input$add_background_file, {
    current <- background_files_data$n_files
    if (current < 5) {
      background_files_data$n_files <- current + 1
      showNotification(sprintf("已添加背景文件 %d", current + 1), type = "message")
    } else {
      showNotification("最多支持5个背景文件", type = "warning")
    }
  })

  # 移除文件按钮
  observeEvent(input$remove_background_file, {
    current <- background_files_data$n_files
    if (current > 2) {
      background_files_data$n_files <- current - 1
      showNotification(sprintf("已移除背景文件 %d", current), type = "message")
    } else {
      showNotification("至少需要2个背景文件", type = "warning")
    }
  })

  observe({
    n <- background_files_data$n_files
    files <- list()
    gene_cols <- list()
    counter <- 1

    for (i in 1:n) {
      file_input <- input[[sprintf("background_file_%d", i)]]

      if (!is.null(file_input)) {
        temp_success <- FALSE
        temp_col <- NULL

        tryCatch({
          cols <- names(read.csv(file_input$datapath, nrows = 0))
          gene_col <- grep("^gene$|^Gene$|^SYMBOL$|^symbol", cols,
                          ignore.case = TRUE, value = TRUE)[1]

          if (!is.na(gene_col)) {
            temp_col <- gene_col
          } else {
            temp_col <- cols[1]
          }
          temp_success <- TRUE
        }, error = function(e) {
          temp_success <<- FALSE
        })

        if (temp_success && !is.null(temp_col)) {
          files[[counter]] <- list(
            index = counter,
            name = file_input$name,
            path = file_input$datapath,
            size = file_input$size
          )
          gene_cols[[counter]] <- temp_col
          counter <- counter + 1
        }
      }
    }

    background_files_data$files <- files
    background_files_data$gene_cols <- gene_cols
  })

  # 显示文件状态
  output$background_files_status <- renderUI({
    files <- background_files_data$files

    if (length(files) == 0) {
      return(div(class = "alert alert-info", "请上传至少2个背景基因文件"))
    }

    n <- background_files_data$n_files

    if (length(files) < n) {
      return(div(class = "alert alert-warning",
                 sprintf("已上传 %d/%d 个文件", length(files), n)))
    }

    # 所有文件已上传
    file_table <- lapply(seq_along(files), function(i) {
      f <- files[[i]]
      tags$tr(
        tags$td(sprintf("文件 %d", f$index)),
        tags$td(strong(f$name)),
        tags$td(sprintf("%.2f MB", f$size / 1024 / 1024)),
        tags$td(tags$span(class = "badge bg-success", "✓"))
      )
    })

    div(
      class = "alert alert-success",
      h5("✓ 所有背景文件已上传"),
      tags$table(class = "table table-condensed",
                tags$thead(tags$tr(
                  tags$th("文件"), tags$th("名称"), tags$th("大小"), tags$th("状态")
                )),
                tags$tbody(do.call(tagList, file_table))
      )
    )
  })

  # 显示列名选择（每个文件独立设置）
  output$background_files_columns <- renderUI({
    files <- background_files_data$files
    gene_cols <- background_files_data$gene_cols

    if (length(files) == 0) return(NULL)

    column_selectors <- lapply(seq_along(files), function(i) {
      f <- files[[i]]

      if (is.null(f)) return(NULL)

      # 读取列名
      cols <- tryCatch({
        names(read.csv(f$path, nrows = 0))
      }, error = function(e) character(0))

      if (length(cols) == 0) return(NULL)

      # 当前选中的基因列（添加安全检查）
      selected_col <- NULL
      if (i <= length(gene_cols)) {
        selected_col <- gene_cols[[i]]
      }

      # 如果selected_col是NULL或不在cols中，使用第一个选项
      if (is.null(selected_col) || !selected_col %in% cols) {
        selected_col <- cols[1]
      }

      div(
        style = "margin-bottom: 10px; padding: 10px; background-color: #f9f9f9;",
        h6(sprintf("文件 %d: %s - 选择基因列", f$index, f$name)),
        selectInput(
          inputId = sprintf("background_gene_col_%d", f$index),
          label = NULL,
          choices = cols,
          selected = selected_col
        )
      )
    })

    # 过滤掉NULL元素
    column_selectors <- column_selectors[!sapply(column_selectors, is.null)]

    if (length(column_selectors) == 0) return(NULL)

    do.call(tagList, column_selectors)
  })

  # 监听列名选择
  observe({
    files <- background_files_data$files

    if (length(files) == 0) return()

    gene_cols <- list()

    for (i in seq_along(files)) {
      f <- files[[i]]
      col_name <- input[[sprintf("background_gene_col_%d", f$index)]]
      if (!is.null(col_name)) {
        gene_cols[[i]] <- col_name
      }
    }

    background_files_data$gene_cols <- gene_cols
  })

  # 显示Universe预览
  output$background_universe_preview <- renderUI({
    files <- background_files_data$files
    gene_cols <- background_files_data$gene_cols

    if (length(files) < 2) {
      return(div(class="alert alert-info", "请上传至少2个文件以查看Universe预览"))
    }

    # 检查是否所有文件都选择了列名
    all_selected <- sapply(seq_along(files), function(i) {
      if (i <= length(gene_cols)) {
        !is.null(gene_cols[[i]])
      } else {
        FALSE
      }
    })

    if (!all(all_selected)) {
      return(div(class="alert alert-warning", "请为每个文件选择基因列"))
    }

    # 读取并计算交集
    all_genes <- list()

    for (i in seq_along(files)) {
      f <- files[[i]]
      tryCatch({
        # 检查列名是否存在
        if (is.null(gene_cols[[i]])) {
          warning(sprintf("文件 %d 的基因列名为空，跳过", f$index))
          next
        }

        df <- read.csv(f$path)

        # 检查列是否在数据框中
        if (!gene_cols[[i]] %in% colnames(df)) {
          warning(sprintf("文件 %d 不存在列 '%s'，跳过", f$index, gene_cols[[i]]))
          next
        }

        genes <- unique(df[[gene_cols[[i]]]])
        genes <- genes[!is.na(genes)]
        all_genes[[i]] <- genes
      }, error = function(e) {
        warning(sprintf("读取文件 %d 失败: %s", f$index, e$message))
        NULL
      })
    }

    # 移除NULL元素
    all_genes <- all_genes[!sapply(all_genes, is.null)]

    if (length(all_genes) < 2) {
      return(div(class="alert alert-danger", "无法读取文件，请检查文件格式和列名设置"))
    }

    # 计算交集
    universe_intersect <- Reduce(intersect, all_genes)

    # 创建预览表
    preview_rows <- lapply(seq_along(files), function(i) {
      f <- files[[i]]
      gene_count <- if (!is.null(all_genes[[i]])) length(all_genes[[i]]) else 0
      tags$tr(
        tags$td(sprintf("文件 %d", f$index)),
        tags$td(sprintf("%d", gene_count)),
        tags$td(sprintf("%.1f%%", gene_count / length(universe_intersect) * 100))
      )
    })

    div(
      class = "alert alert-info",
      h5("🔍 Universe预览（所有文件基因的交集）"),
      tags$table(class = "table table-striped",
                tags$thead(tags$tr(
                  tags$th("文件"), tags$th("基因数"), tags$th("相对Universe")
                )),
                tags$tbody(do.call(tagList, preview_rows)),
                tags$tfoot(
                  tags$tr(
                    style = "background-color: #e3f2fd;",
                    tags$td(strong("Universe (交集)")),
                    tags$td(strong(sprintf("%d", length(universe_intersect)))),
                    tags$td(tags$span(class = "badge bg-primary", "100%"))
                  )
                )
      ),
      p("💡 系统将使用这个交集作为背景基因集", class="small text-muted")
    )
  })

  # =====================================================
  # 辅助函数：清理基因符号
  # =====================================================
  clean_gene_symbols <- function(gene_symbols, species_code) {
    # 清理基因符号：去除空格、特殊字符，标准化大小写
    cleaned <- trimws(gene_symbols)  # 去除首尾空格
    cleaned <- gsub("[\t\n\r]", "", cleaned)  # 去除空白字符

    # 去除版本号（如.1, .2等）
    cleaned <- gsub("\\.[0-9]+$", "", cleaned)

    # 去除常见的假基因后缀
    cleaned <- gsub("-ps$", "", cleaned, ignore.case = TRUE)
    cleaned <- gsub("-rs$", "", cleaned, ignore.case = TRUE)
    cleaned <- gsub("-as$", "", cleaned, ignore.case = TRUE)

    # 识别并处理ENSEMBL ID
    # ENSEMBL ID模式：ENS(MUS)?G[0-9]+（人类：ENSG，小鼠：ENSMUSG）
    is_ensembl_id <- grepl("^ENS(MUS)?G[0-9]+$", cleaned, ignore.case = TRUE)

    # 根据物种和ID类型标准化大小写
    if (species_code == "mmu") {
      # 小鼠基因处理
      cleaned <- sapply(seq_along(cleaned), function(i) {
        gene <- cleaned[i]

        if (is_ensembl_id[i]) {
          # ENSEMBL ID：全部大写
          return(toupper(gene))
        } else if (grepl("^[A-Za-z]", gene)) {
          # 基因符号：首字母大写，其余小写
          return(paste0(toupper(substr(gene, 1, 1)), tolower(substr(gene, 2, nchar(gene)))))
        } else {
          # 其他情况（如数字ID）
          return(gene)
        }
      }, USE.NAMES = FALSE)
    } else {
      # 人类基因：全部大写（包括ENSEMBL ID和基因符号）
      cleaned <- toupper(cleaned)
    }

    # 去除连字符、点等特殊字符（保留字母和数字）
    # 注意：对于ENSEMBL ID，这可能会去除有效的版本号，但我们已经处理了版本号
    cleaned <- gsub("[^[:alnum:]]", "", cleaned)

    return(cleaned)
  }

  # =====================================================
  # 辅助函数：识别基因ID类型
  # =====================================================
  identify_gene_id_types <- function(gene_ids, species_code) {
    # 初始化结果列表
    result <- list(
      ensembl_ids = character(0),
      gene_symbols = character(0),
      entrez_ids = character(0),
      other_ids = character(0)
    )

    for (gene in gene_ids) {
      # 检查是否是ENSEMBL ID
      if (grepl("^ENS(MUS)?G[0-9]+$", gene, ignore.case = TRUE)) {
        result$ensembl_ids <- c(result$ensembl_ids, gene)
      }
      # 检查是否是ENTREZID（纯数字）
      else if (grepl("^[0-9]+$", gene)) {
        result$entrez_ids <- c(result$entrez_ids, gene)
      }
      # 检查是否是基因符号（以字母开头）
      else if (grepl("^[A-Za-z]", gene)) {
        result$gene_symbols <- c(result$gene_symbols, gene)
      }
      # 其他类型
      else {
        result$other_ids <- c(result$other_ids, gene)
      }
    }

    return(result)
  }

  # =====================================================
  # 辅助函数：智能基因符号转换
  # =====================================================
  smart_gene_conversion <- function(gene_ids, db_obj, target_column = "ENTREZID") {
    # 尝试不同的keytype来转换基因ID
    keytypes_to_try <- c("SYMBOL", "ALIAS", "ENSEMBL", "ENTREZID")

    # 记录调试信息
    debug_info <- list()
    debug_info$input_count <- length(gene_ids)
    debug_info$input_samples <- head(gene_ids, 10)
    debug_info$attempts <- list()

    for (keytype in keytypes_to_try) {
      tryCatch({
        # 先检查哪些基因ID在当前keytype中有效
        valid_keys <- keys(db_obj, keytype = keytype)
        matched_ids <- gene_ids[gene_ids %in% valid_keys]

        # 记录尝试信息
        attempt_info <- list(
          keytype = keytype,
          valid_keys_count = length(valid_keys),
          matched_count = length(matched_ids),
          matched_samples = head(matched_ids, 5)
        )
        debug_info$attempts[[keytype]] <- attempt_info

        if (length(matched_ids) > 0) {
          # 尝试转换匹配的基因ID
          converted <- AnnotationDbi::mapIds(
            db_obj,
            keys = matched_ids,
            column = target_column,
            keytype = keytype,
            multiVals = "first"
          )

          # 返回成功转换的结果
          successful <- converted[!is.na(converted)]
          if (length(successful) > 0) {
            debug_info$final_keytype <- keytype
            debug_info$success_count <- length(successful)
            debug_info$failed_count <- length(matched_ids) - length(successful)

            # 打印调试信息（在开发环境中）
            if (Sys.getenv("SHINY_DEBUG") == "TRUE") {
              cat("\n=== 基因转换调试信息 ===\n")
              cat("输入基因数量:", debug_info$input_count, "\n")
              cat("输入基因示例:", paste(debug_info$input_samples, collapse=", "), "\n")
              cat("成功使用的keytype:", keytype, "\n")
              cat("匹配的基因数量:", length(matched_ids), "\n")
              cat("成功转换的基因数量:", length(successful), "\n")
              cat("失败的基因数量:", debug_info$failed_count, "\n")
            }

            return(list(
              converted = successful,
              keytype_used = keytype,
              matched_count = length(matched_ids),
              success_count = length(successful),
              debug_info = debug_info
            ))
          }
        }
      }, error = function(e) {
        # 记录错误信息
        debug_info$attempts[[keytype]]$error <- e$message
        # 继续尝试下一个keytype
        NULL
      })
    }

    # 如果所有keytype都失败，返回详细的调试信息
    debug_info$all_failed <- TRUE

    # 打印详细的调试信息
    if (Sys.getenv("SHINY_DEBUG") == "TRUE") {
      cat("\n=== 基因转换失败调试信息 ===\n")
      cat("输入基因数量:", debug_info$input_count, "\n")
      cat("输入基因示例:", paste(debug_info$input_samples, collapse=", "), "\n")
      cat("\n尝试的keytype结果:\n")
      for (keytype in keytypes_to_try) {
        if (!is.null(debug_info$attempts[[keytype]])) {
          attempt <- debug_info$attempts[[keytype]]
          cat("  ", keytype, ":\n")
          cat("    有效key数量:", attempt$valid_keys_count, "\n")
          cat("    匹配数量:", attempt$matched_count, "\n")
          if (!is.null(attempt$matched_samples)) {
            cat("    匹配示例:", paste(attempt$matched_samples, collapse=", "), "\n")
          }
          if (!is.null(attempt$error)) {
            cat("    错误:", attempt$error, "\n")
          }
        }
      }
    }

    return(list(
      converted = NULL,
      keytype_used = NULL,
      matched_count = 0,
      success_count = 0,
      debug_info = debug_info,
      error_message = "所有keytype尝试都失败了"
    ))
  }

  # =====================================================
  # KEGG 模块
  # =====================================================
  kegg_data_processed <- eventReactive(input$run_kegg, {
    req(deg_results(), user_session$logged_in)

    # 从deg_results中提取差异分析结果和背景基因
    deg_data <- deg_results()
    res_df <- deg_data$deg_df
    background_genes <- deg_data$background_genes

    target_status <- switch(input$kegg_direction, "Up" = "Up", "Down" = "Down", "All" = c("Up", "Down"))

    # 清理基因符号
    if (!is.null(background_genes) && length(background_genes) > 0) {
      background_genes <- clean_gene_symbols(background_genes, input$kegg_species)
    }

    # 获取ENTREZID
    ids <- res_df %>% dplyr::filter(Status %in% target_status & !is.na(ENTREZID)) %>% dplyr::pull(ENTREZID)

    if(length(ids) == 0) {
      showNotification("无有效ENTREZID，请检查基因注释结果", type="error")
      return(NULL)
    }

    tryCatch({
      # 准备背景基因集（如果可用）
      universe <- NULL
      if(!is.null(background_genes) && length(background_genes) > 0) {
        # 将背景基因符号转换为ENTREZID（使用智能转换）
        db_pkg <- if(input$kegg_species == "mmu") "org.Mm.eg.db" else "org.Hs.eg.db"
        if(require(db_pkg, character.only = TRUE)) {
          db_obj <- get(db_pkg)

          # 先清理基因符号
          cleaned_background <- clean_gene_symbols(background_genes, input$kegg_species)

          # 使用智能转换函数
          conversion_result <- smart_gene_conversion(cleaned_background, db_obj, "ENTREZID")

          # 检查转换结果
          if(!is.null(conversion_result$converted) && length(conversion_result$converted) > 0) {
            bg_entrez <- conversion_result$converted
            universe <- bg_entrez

            # 显示成功信息
            if(!is.null(conversion_result$keytype_used)) {
              showNotification(paste("使用", length(universe), "个检测到的基因作为KEGG分析背景基因集（通过",
                                    conversion_result$keytype_used, "转换）"), type = "message")
            } else {
              showNotification(paste("使用", length(universe), "个检测到的基因作为KEGG分析背景基因集"), type = "message")
            }

            # 如果有失败的情况，显示警告
            if(conversion_result$matched_count > conversion_result$success_count) {
              failed_count <- conversion_result$matched_count - conversion_result$success_count
              showNotification(paste("警告：", failed_count, "个背景基因无法转换为ENTREZID"), type = "warning")
            }
          } else {
            # 转换失败，显示详细的错误信息
            error_msg <- "背景基因转换失败"

            if(!is.null(conversion_result$error_message)) {
              error_msg <- paste(error_msg, ": ", conversion_result$error_message)
            }

            # 提供具体的建议
            if(length(cleaned_background) > 0) {
              sample_genes <- head(cleaned_background, 5)
              error_msg <- paste0(error_msg, "\n示例基因：", paste(sample_genes, collapse=", "))

              # 分析基因ID类型并提供具体建议
              id_types <- identify_gene_id_types(sample_genes, input$kegg_species)
              error_msg <- paste0(error_msg, "\n\n检测到的ID类型分析：")

              if(length(id_types$ensembl_ids) > 0) {
                error_msg <- paste0(error_msg, "\n• ENSEMBL ID: ", length(id_types$ensembl_ids), "个")
                error_msg <- paste0(error_msg, "\n  示例：", paste(head(id_types$ensembl_ids, 3), collapse=", "))
                error_msg <- paste0(error_msg, "\n  建议：这些是ENSEMBL ID，不是基因符号。")
                error_msg <- paste0(error_msg, "\n  请使用基因符号（如Trp53）或确保数据库包含这些ENSEMBL ID")
              }

              if(length(id_types$gene_symbols) > 0) {
                error_msg <- paste0(error_msg, "\n• 基因符号: ", length(id_types$gene_symbols), "个")
                error_msg <- paste0(error_msg, "\n  示例：", paste(head(id_types$gene_symbols, 3), collapse=", "))

                # 检查大小写问题
                if(input$kegg_species == "hsa") {
                  lower_case <- id_types$gene_symbols[grepl("^[a-z]", id_types$gene_symbols)]
                  if(length(lower_case) > 0) {
                    error_msg <- paste0(error_msg, "\n  大小写问题：", length(lower_case), "个基因是小写")
                    error_msg <- paste0(error_msg, "\n  建议：人类基因需要大写（如TP53，不是tp53）")
                  }
                } else if(input$kegg_species == "mmu") {
                  # 检查小鼠基因大小写
                  not_proper_case <- id_types$gene_symbols[!grepl("^[A-Z][a-z]+$", id_types$gene_symbols) & grepl("^[A-Za-z]", id_types$gene_symbols)]
                  if(length(not_proper_case) > 0) {
                    error_msg <- paste0(error_msg, "\n  大小写问题：", length(not_proper_case), "个基因大小写不正确")
                    error_msg <- paste0(error_msg, "\n  建议：小鼠基因需要首字母大写，其余小写（如Trp53，不是trp53或TRP53）")
                  }
                }
              }

              if(length(id_types$other_ids) > 0) {
                error_msg <- paste0(error_msg, "\n• 其他ID类型: ", length(id_types$other_ids), "个")
                error_msg <- paste0(error_msg, "\n  示例：", paste(head(id_types$other_ids, 3), collapse=", "))
                error_msg <- paste0(error_msg, "\n  建议：请检查这些ID的格式是否正确")
              }
            }

            showNotification(error_msg, type = "error", duration = 15)

            # 在调试模式下显示更多信息
            if(Sys.getenv("SHINY_DEBUG") == "TRUE" && !is.null(conversion_result$debug_info)) {
              cat("\n=== 背景基因转换详细调试信息 ===\n")
              print(conversion_result$debug_info)
            }
          }
        } else {
          showNotification(paste("错误：数据库包", db_pkg, "未安装"), type = "error")
        }
      }

      # =====================================================
      # KEGG富集分析 - 支持universe参数（对齐clusterProfiler）
      # =====================================================
      kegg_obj <- NULL

      cat("🔧 开始KEGG富集分析...\n")
      cat(sprintf("📊 输入基因数量: %d\n", length(ids)))
      cat(sprintf("📊 背景基因数量: %s\n",
                  ifelse(is.null(universe), "NULL (使用全基因组)", length(universe))))

      # 转换为character向量
      ids_char <- as.character(ids)
      universe_char <- if(!is.null(universe)) as.character(universe) else NULL

      # =====================================================
      # 方法1: 尝试使用 enrich_local_KEGG_v2（支持universe）✨
      # =====================================================

      # 尝试加载新函数
      if (exists("enrich_local_KEGG_v2", mode = "function")) {
        cat("✅ 使用 enrich_local_KEGG_v2（支持universe参数）\n")

        kegg_obj <- tryCatch({
          args <- list(
            gene = ids_char,
            species = input$kegg_species,
            pCutoff = input$kegg_p,
            pAdjustMethod = "BH"
          )

          # 添加universe参数（如果有）
          if (!is.null(universe_char)) {
            args$universe <- universe_char
            cat(sprintf("📊 使用自定义背景基因集: %d 个基因\n", length(universe_char)))
          }

          result <- do.call(enrich_local_KEGG_v2, args)

          cat(sprintf("✅ enrich_local_KEGG_v2成功！找到 %d 个显著通路\n",
                      nrow(result@result)))

          result

        }, error = function(e) {
          warning(sprintf("enrich_local_KEGG_v2失败: %s", e$message))
          NULL
        })
      }

      # =====================================================
      # 方法2: 尝试使用 biofree.qyKEGGtools（原始版本）
      # =====================================================

      if (is.null(kegg_obj) && require("biofree.qyKEGGtools", quietly = TRUE)) {
        cat("⚠️ enrich_local_KEGG_v2不可用，尝试使用biofree.qyKEGGtools\n")

        # 检查原始函数是否支持universe
        func_args <- tryCatch({
          formals(biofree.qyKEGGtools::enrich_local_KEGG)
        }, error = function(e) NULL)

        supports_universe <- !is.null(func_args) && "universe" %in% names(func_args)

        if (supports_universe) {
          cat("✅ biofree.qyKEGGtools支持universe参数\n")

          kegg_obj <- tryCatch({
            args <- list(
              gene = ids_char,
              species = input$kegg_species,
              pCutoff = input$kegg_p
            )

            if (!is.null(universe_char)) {
              args$universe <- universe_char
            }

            result <- do.call(biofree.qyKEGGtools::enrich_local_KEGG, args)

            cat(sprintf("✅ biofree.qyKEGGtools成功！找到 %d 个显著通路\n",
                        nrow(result@result)))

            result

          }, error = function(e) {
            warning(sprintf("biofree.qyKEGGtools失败: %s", e$message))
            NULL
          })

        } else {
          cat("⚠️ biofree.qyKEGGtools不支持universe参数\n")

          if (!is.null(universe_char)) {
            showNotification(
              "注意：当前版本的biofree.qyKEGGtools不支持universe参数，将使用全基因组背景。建议更新到最新版本或使用clusterProfiler。",
              type = "warning",
              duration = 10
            )
          }

          kegg_obj <- tryCatch({
            result <- biofree.qyKEGGtools::enrich_local_KEGG(
              gene = ids_char,
              species = input$kegg_species,
              pCutoff = input$kegg_p
            )

            cat(sprintf("✅ biofree.qyKEGGtools成功！找到 %d 个显著通路\n",
                        nrow(result@result)))

            result

          }, error = function(e) {
            warning(sprintf("biofree.qyKEGGtools失败: %s", e$message))
            NULL
          })
        }
      }

      # =====================================================
      # 方法3: 使用 clusterProfiler::enrichKEGG（备用）
      # =====================================================

      if (is.null(kegg_obj) && require("clusterProfiler", quietly = TRUE)) {
        cat("⚠️ 尝试使用clusterProfiler::enrichKEGG作为备用\n")

        kegg_obj <- tryCatch({
          args <- list(
            gene = ids_char,
            organism = input$kegg_species,
            pvalueCutoff = input$kegg_p,
            pAdjustMethod = "BH"
          )

          if (!is.null(universe_char)) {
            args$universe <- universe_char
            cat(sprintf("📊 使用clusterProfiler，背景基因: %d 个\n", length(universe_char)))
          }

          result <- do.call(clusterProfiler::enrichKEGG, args)

          cat(sprintf("✅ clusterProfiler成功！找到 %d 个显著通路\n",
                      nrow(result@result)))

          result

        }, error = function(e) {
          error_msg <- sprintf("clusterProfiler调用失败: %s", e$message)
          cat(sprintf("❌ %s\n", error_msg))
          showNotification(error_msg, type = "error")
          NULL
        })
      }

      # =====================================================
      # 检查结果
      # =====================================================

      # 🔧 如果返回NULL，给出详细错误信息
      if(is.null(kegg_obj)) {
        showNotification("❌ KEGG富集分析失败：biofree.qyKEGGtools返回NULL\n可能原因：基因ID格式不正确或本地KEGG数据库缺少对应物种的注释", type = "error")
        return(NULL)
      }

      # 检查结果
      result_df <- if(inherits(kegg_obj, "enrichResult")) {
        kegg_obj@result
      } else if(is.data.frame(kegg_obj)) {
        kegg_obj
      } else {
        cat(sprintf("⚠️ 未知的结果类型: %s\n", class(kegg_obj)[1]))
        showNotification("❌ KEGG富集分析返回了未知格式的结果", type = "error")
        return(NULL)
      }

      if(nrow(result_df) == 0) {
        showNotification("⚠️ KEGG富集分析没有找到显著富集的通路", type = "warning")
        return(NULL)
      }

      df <- result_df

      df$Description <- gsub(" - Mus musculus.*| - Homo sapiens.*", "", df$Description)

      db_pkg <- if(input$kegg_species == "mmu") "org.Mm.eg.db" else "org.Hs.eg.db"
      if(require(db_pkg, character.only = TRUE)) {
        db_obj <- get(db_pkg)
        all_entrez <- unique(unlist(strsplit(df$geneID, "/")))
        mapped <- AnnotationDbi::mapIds(db_obj, keys = all_entrez, column = "SYMBOL", keytype = "ENTREZID", multiVals = "first")

        df$geneID <- sapply(df$geneID, function(x) {
          ids <- unlist(strsplit(x, "/"))
          syms <- mapped[ids]
          syms[is.na(syms)] <- ids[is.na(syms)]
          paste(syms, collapse = "/")
        })
      }

      return(df)
    }, error = function(e) { showNotification(paste("KEGG Error:", e$message), type="error"); return(NULL) })
  })

  output$download_kegg <- downloadHandler(
    filename = function() {
      paste0("KEGG_Enrichment_Results_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(kegg_data_processed())
      write.csv(kegg_data_processed(), file, row.names = FALSE)
    }
  )

  # KEGG图表生成reactive
  kegg_plot_obj <- reactive({
    req(kegg_data_processed())
    df <- kegg_data_processed()

    # 计算Fold Enrichment（如果数据框中没有）
    if (!"FoldEnrichment" %in% colnames(df)) {
      # 从GeneRatio和BgRatio计算Fold Enrichment
      # GeneRatio格式: "5/120", BgRatio格式: "50/5000"
      df$FoldEnrichment <- sapply(1:nrow(df), function(i) {
        gene_ratio <- as.numeric(strsplit(df$GeneRatio[i], "/")[[1]])
        bg_ratio <- as.numeric(strsplit(df$BgRatio[i], "/")[[1]])

        # 处理可能的NA或Inf值
        if (length(gene_ratio) < 2 || length(bg_ratio) < 2) {
          return(NA)
        }
        if (gene_ratio[2] == 0 || bg_ratio[2] == 0) {
          return(NA)
        }

        fe <- (gene_ratio[1] / gene_ratio[2]) / (bg_ratio[1] / bg_ratio[2])
        return(ifelse(is.finite(fe), fe, NA))
      })

      # 确保是数值类型
      df$FoldEnrichment <- as.numeric(df$FoldEnrichment)
    }

    df_plot <- head(df[order(df$p.adjust),], 20)

    txt_col <- if(input$theme_toggle) "white" else "black"
    grid_col <- if(input$theme_toggle) "#444444" else "#cccccc"

    font_face <- if(input$kegg_bold) "bold" else "plain"

    # 根据用户选择设置X轴变量
    if (input$kegg_x_axis == "FoldEnrichment") {
      x_var <- df_plot$FoldEnrichment
      x_label <- "Fold Enrichment"
    } else {
      x_var <- df_plot$Count
      x_label <- "Gene Count"
    }

    # 使用aes()而不是aes_string()
    p <- ggplot(df_plot, aes(x = x_var, y = reorder(Description, x_var), size = x_var, color = p.adjust)) +
      geom_point() +
      scale_color_gradient(low = input$kegg_high_col, high = input$kegg_low_col) +
      theme_minimal() +
      labs(x = x_label, y = "", title = paste("KEGG Enrichment (", input$kegg_direction, ")")) +
      theme(
        panel.background = element_rect(fill = "transparent", colour = NA),
        plot.background = element_rect(fill = "transparent", colour = NA),
        plot.title = element_text(color = txt_col, face = "bold", hjust = 0.5),
        text = element_text(color = txt_col, size = input$kegg_font_size, face = font_face),
        axis.text = element_text(color = txt_col, size = input$kegg_font_size),
        legend.text = element_text(color = txt_col),
        legend.title = element_text(color = txt_col),
        axis.line = element_line(color = txt_col),
        panel.grid.major = element_line(color = grid_col),
        panel.grid.minor = element_line(color = grid_col)
      )

    return(p)
  })

  # KEGG图表下载
  output$download_kegg_plot <- downloadHandler(
    filename = function() {
      paste0("KEGG_Dotplot_", Sys.Date(), ".", input$kegg_export_format)
    },
    content = function(file) {
      req(kegg_plot_obj())

      # 获取当前图表
      p <- kegg_plot_obj()

      # 根据格式保存
      if (input$kegg_export_format == "png") {
        png(file, width = 10, height = 8, units = "in", res = 300)
      } else if (input$kegg_export_format == "pdf") {
        pdf(file, width = 10, height = 8)
      } else if (input$kegg_export_format == "svg") {
        svg(file, width = 10, height = 8)
      }

      print(p)
      dev.off()
    }
  )

  output$kegg_dotplot <- renderPlot({
    kegg_plot_obj()
  })

  output$kegg_table <- DT::renderDataTable({
    req(kegg_data_processed())
    DT::datatable(kegg_data_processed(), options = list(scrollX=T), rownames=F)
  })

  # =====================================================
  # 新增：单列基因 KEGG 富集分析
  # =====================================================

  # --- 单列基因 KEGG 富集分析 ---
  single_gene_kegg_data <- eventReactive(input$run_single_gene_kegg, {
    req(input$single_gene_file, user_session$logged_in)

    showNotification("正在处理单列基因 KEGG 富集分析...", type = "message")

    # 读取单列基因文件
    gene_df <- read.csv(input$single_gene_file$datapath, header = TRUE)

    # 检查文件格式（支持大小写不敏感的列名）
    symbol_col <- NULL
    for (col in c("SYMBOL", "symbol", "Symbol", "Gene", "gene", "GeneSymbol")) {
      if (col %in% colnames(gene_df)) {
        symbol_col <- col
        break
      }
    }

    if (is.null(symbol_col)) {
      showNotification("错误：CSV 文件必须包含基因符号列（SYMBOL/symbol/Gene等）", type = "error")
      return(NULL)
    }

    # 获取基因列表（使用检测到的列名）
    gene_symbols <- gene_df[[symbol_col]]
    gene_symbols <- gene_symbols[!is.na(gene_symbols) & gene_symbols != ""]

    if (length(gene_symbols) == 0) {
      showNotification("错误：未找到有效的基因符号", type = "error")
      return(NULL)
    }

    # 🔧 新增：过滤掉未注释的基因（is_annotated = FALSE）和Ensembl ID格式
    if ("is_annotated" %in% colnames(gene_df)) {
      original_count <- length(gene_symbols)
      # 只保留成功注释的基因
      annotated_mask <- gene_df$is_annotated[match(gene_symbols, gene_df[[symbol_col]])]
      if (!is.null(annotated_mask)) {
        gene_symbols <- gene_symbols[annotated_mask & !is.na(annotated_mask)]
        n_filtered <- original_count - length(gene_symbols)
        if (n_filtered > 0) {
          cat(sprintf("🧹 自动过滤 %d 个未注释的基因\n", n_filtered))
          showNotification(
            sprintf("自动过滤了 %d 个未注释的基因（%d → %d）",
                    n_filtered, original_count, length(gene_symbols)),
            type = "message", duration = 5
          )
        }
      }
    }

    # 🔧 新增：过滤掉Ensembl ID格式的"基因"
    ensembl_mask <- !grepl("^ENS", gene_symbols, ignore.case = TRUE)
    if (sum(!ensembl_mask) > 0) {
      cat(sprintf("🧹 自动过滤 %d 个Ensembl ID格式的基因\n", sum(!ensembl_mask)))
      gene_symbols <- gene_symbols[ensembl_mask]
      showNotification(
        sprintf("检测到并过滤了Ensembl ID格式，请使用基因符号"),
        type = "warning", duration = 5
      )
    }

    # =====================================================
    # 🆕 自动过滤不符合物种格式的基因
    # =====================================================

    original_count <- length(gene_symbols)

    if (input$single_gene_species == "hsa") {
      # 人类：只保留全大写的基因符号（如 TP53, EGFR）
      # 过滤掉：包含小写的基因（可能是小鼠基因：Trp53, Egfr）
      mask <- grepl("^[A-Z]+$", gene_symbols) & nchar(gene_symbols) > 2

      if (sum(!mask) > 0) {
        filtered_out <- gene_symbols[!mask]
        cat(sprintf("🧹 自动过滤 %d 个不符合人类格式的基因\n", sum(!mask)))
        cat(sprintf("   示例: %s\n", paste(head(filtered_out, 5), collapse=", ")))
        cat("   人类基因应为全大写（如 TP53, EGFR）\n")

        gene_symbols <- gene_symbols[mask]
        showNotification(
          sprintf("自动过滤了 %d 个不符合格式的基因（%d → %d）",
                  sum(!mask), original_count, length(gene_symbols)),
          type = "message",
          duration = 5
        )
      }

    } else if (input$single_gene_species == "mmu") {
      # 小鼠：只保留首字母大写的基因符号（如 Trp53, Egfr, Tnfrsf11b）
      # 过滤掉：全大写的基因（可能是人类基因：TP53, EGFR）

      # 保留：首字母大写，其余任意（Trp53, Egfr, Tnfrsf11b 都可以）
      mask <- grepl("^[A-Z]", gene_symbols) & !grepl("^[A-Z]+$", gene_symbols)

      # 但要排除纯数字
      mask <- mask & !grepl("^[0-9]+$", gene_symbols)

      if (sum(!mask) > 0) {
        filtered_out <- gene_symbols[!mask]
        cat(sprintf("🧹 自动过滤 %d 个不符合小鼠格式的基因\n", sum(!mask)))
        cat(sprintf("   示例: %s\n", paste(head(filtered_out, 5), collapse=", ")))
        cat("   小鼠基因应首字母大写（如 Trp53, Egfr, Tnfrsf11b）\n")

        gene_symbols <- gene_symbols[mask]
        showNotification(
          sprintf("自动过滤了 %d 个不符合格式的基因（%d → %d）",
                  sum(!mask), original_count, length(gene_symbols)),
          type = "message",
          duration = 5
        )
      }
    }

    if (length(gene_symbols) == 0) {
      showNotification("错误：过滤后没有剩余的有效基因符号", type = "error")
      return(NULL)
    }

    cat(sprintf("✅ 最终使用 %d 个基因进行富集分析\n\n", length(gene_symbols)))
    showNotification(paste("使用", length(gene_symbols), "个基因进行富集分析"), type = "message")

    # 转换为 ENTREZID
    db_pkg <- if(input$single_gene_species == "mmu") "org.Mm.eg.db" else "org.Hs.eg.db"

    if (!require(db_pkg, character.only = TRUE, quietly = TRUE)) {
      showNotification(paste("错误：未安装", db_pkg), type = "error")
      return(NULL)
    }

    db_obj <- get(db_pkg)

    # ⚠️ 物种匹配警告
    # 检查基因符号格式是否与选择的物种匹配
    cat("🔍 检查基因符号与物种匹配...\n")

    # 提取样本基因进行检测
    sample_genes <- head(gene_symbols, min(20, length(gene_symbols)))

    # 检测大小写模式
    if (input$single_gene_species == "hsa") {
      # 人类基因应该是全大写（如 TP53, EGFR）
      not_uppercase <- sample_genes[grepl("[a-z]", sample_genes)]
      if (length(not_uppercase) > 0) {
        cat(sprintf("⚠️  警告: 检测到 %d 个基因包含小写字母（如: %s）\n",
                   length(not_uppercase), paste(head(not_uppercase, 3), collapse=", ")))
        cat("    人类基因符号应该全大写（如 TP53, EGFR）\n")
        cat("    小鼠基因符号首字母大写（如 Trp53, Egfr）\n")
        cat("    💡 如果这些是小鼠基因，请将物种改为 'mmu'\n")
        showNotification(
          paste("检测到基因符号格式可能是小鼠，但当前选择人类。请检查物种设置。",
                "\n示例：", paste(head(not_uppercase, 3), collapse=", ", "..."),
                "\n如果是小鼠实验，请选择物种: mmu"),
          type = "warning",
          duration = 10
        )
      }
    } else if (input$single_gene_species == "mmu") {
      # 小鼠基因检查
      # 正确的小鼠基因：首字母大写（如 Trp53, Egfr, Tnfrsf11b）
      # 错误的人类基因：全大写（如 TP53, EGFR, TNFRSF11B）

      # 检测全大写的基因（可能是人类基因）
      all_uppercase <- sample_genes[grepl("^[A-Z]+$", sample_genes) & nchar(sample_genes) > 2]
      if (length(all_uppercase) > 0) {
        cat(sprintf("⚠️  警告: 检测到 %d 个可能的人类基因符号（全大写）\n",
                   length(all_uppercase)))
        cat(sprintf("    示例: %s\n", paste(head(all_uppercase, 3), collapse=", ")))
        cat("    人类基因符号: 全大写（如 TP53, EGFR, TNFRSF11B）\n")
        cat("    小鼠基因符号: 首字母大写（如 Trp53, Egfr, Tnfrsf11b）\n")
        cat("    💡 如果这些是人类基因，请将物种改为 'hsa'\n")
        showNotification(
          paste("检测到可能的人类基因符号（全大写），但当前选择小鼠。",
                "\n示例：", paste(head(all_uppercase, 3), collapse=", "),
                "\n如果是人类数据，请选择物种: hsa"),
          type = "warning",
          duration = 10
        )
      } else {
        cat("✅ 基因符号格式检查通过，符合小鼠基因命名规范\n")
      }
    }

    tryCatch({
      # 清理基因符号
      cleaned_genes <- clean_gene_symbols(gene_symbols, input$single_gene_species)

      # 使用智能转换函数将基因符号转换为ENTREZID
      conversion_result <- smart_gene_conversion(cleaned_genes, db_obj, "ENTREZID")

      if(is.null(conversion_result)) {
        # 如果智能转换失败，尝试直接使用SYMBOL keytype
        tryCatch({
          mapped <- AnnotationDbi::mapIds(db_obj,
                                         keys = cleaned_genes,
                                         column = "ENTREZID",
                                         keytype = "SYMBOL",
                                         multiVals = "first")
          entrez_ids <- na.omit(mapped)
        }, error = function(e) {
          showNotification(paste("基因符号转换失败:", e$message), type = "error")
          return(NULL)
        })
      } else {
        entrez_ids <- conversion_result$converted
        showNotification(paste("成功转换", length(entrez_ids), "个基因ID（通过",
                              conversion_result$keytype_used, "转换）"), type = "message")
      }

      if (length(entrez_ids) == 0) {
        showNotification("错误：无法将基因符号转换为 ENTREZID", type = "error")
        return(NULL)
      }

      # =====================================================
      # 🆕 处理背景基因集（支持多文件上传或手动指定）
      # =====================================================
      universe <- NULL

      # 优先级1: 上传了多个背景基因文件（新功能）
      if (!is.null(background_files_data$files) && length(background_files_data$files) >= 2) {

        all_bg_genes <- list()
        all_entrez_genes <- list()

        message("\n=== 处理多文件背景基因集 ===\n")

        # 处理每个上传的文件
        for (i in seq_along(background_files_data$files)) {
          file_info <- background_files_data$files[[i]]
          gene_col <- background_files_data$gene_cols[[i]]

          if (!is.null(file_info) && !is.null(gene_col)) {
            tryCatch({
              df <- read.csv(file_info$path, header = TRUE)
              bg_genes <- df[[gene_col]]
              bg_genes <- unique(bg_genes[!is.na(bg_genes) & bg_genes != ""])

              message(sprintf("  背景文件 %d: %s", file_info$index, file_info$name))
              message(sprintf("    基因列: %s", gene_col))
              message(sprintf("    基因数: %d\n", length(bg_genes)))

              # 转换为ENTREZID
              cleaned_bg <- clean_gene_symbols(bg_genes, input$single_gene_species)
              bg_conversion <- smart_gene_conversion(cleaned_bg, db_obj, "ENTREZID")

              if (!is.null(bg_conversion$converted) && length(bg_conversion$converted) > 0) {
                all_entrez_genes[[i]] <- bg_conversion$converted
                all_bg_genes[[i]] <- bg_genes
              }

            }, error = function(e) {
              showNotification(sprintf("读取背景文件 %d 失败: %s", file_info$index, e$message),
                              type = "warning")
              message(sprintf("  错误: %s\n", e$message))
            })
          }
        }

        # 计算Universe（所有文件ENTREZID的交集）
        if (length(all_entrez_genes) >= 2) {
          universe <- Reduce(intersect, all_entrez_genes)

          message(sprintf("=== 多文件Universe计算完成 ==="))
          message(sprintf("文件数: %d", length(all_entrez_genes)))
          message(sprintf("Universe (交集): %d 个ENTREZID\n", length(universe)))

          showNotification(
            sprintf("✅ 使用多文件背景基因集交集: %d 个文件 → %d 个ENTREZID",
                    length(all_entrez_genes), length(universe)),
            type = "message"
          )
        } else {
          showNotification("多文件背景处理失败，将使用全基因组", type = "warning")
        }

      } else if (!is.null(input$background_gene_file_kegg)) {
        # 兼容旧版单文件上传（保留原有逻辑）
        tryCatch({
          bg_df <- read.csv(input$background_gene_file_kegg$datapath, header = TRUE)

          # 检测列名（支持大小写不敏感）
          bg_symbol_col <- NULL
          for (col in c("SYMBOL", "symbol", "Symbol", "Gene", "gene", "GeneSymbol")) {
            if (col %in% colnames(bg_df)) {
              bg_symbol_col <- col
              break
            }
          }

          if (is.null(bg_symbol_col)) {
            showNotification("背景基因文件缺少SYMBOL列，将忽略", type = "warning")
          } else {
            bg_symbols <- bg_df[[bg_symbol_col]]
            bg_symbols <- bg_symbols[!is.na(bg_symbols) & bg_symbols != ""]

            if (length(bg_symbols) > 0) {
              # 清理背景基因符号
              cleaned_bg <- clean_gene_symbols(bg_symbols, input$single_gene_species)

              # 转换为ENTREZID
              bg_conversion <- smart_gene_conversion(cleaned_bg, db_obj, "ENTREZID")

              if (!is.null(bg_conversion$converted) && length(bg_conversion$converted) > 0) {
                universe <- bg_conversion$converted
                showNotification(
                  sprintf("✅ 使用单文件背景基因集: %d 个基因（成功转换 %d 个）",
                          length(cleaned_bg), length(universe)),
                  type = "message"
                )
              } else {
                showNotification("背景基因文件转换失败，将使用全基因组", type = "warning")
              }
            }
          }
        }, error = function(e) {
          showNotification(paste("读取背景基因文件失败:", e$message), type = "warning")
        })
      }

      # 优先级2: 手动输入了背景基因数量
      if (is.null(universe) && !is.null(input$background_gene_count_kegg) &&
          !is.na(input$background_gene_count_kegg) && input$background_gene_count_kegg > 0) {
        all_genes <- keys(db_obj, keytype = "ENTREZID")
        target_count <- min(input$background_gene_count_kegg, length(all_genes))

        # 随机抽样（不太准确，但比没有好）
        set.seed(123)  # 保证可重复性
        universe <- sample(all_genes, target_count)

        showNotification(
          sprintf("⚠️ 从全基因组随机抽取 %d 个基因作为背景（建议上传完整背景文件）",
                  length(universe)),
          type = "warning"
        )
      }

      # 优先级3: 使用全基因组
      if (is.null(universe)) {
        all_genes <- keys(db_obj, keytype = "ENTREZID")
        universe <- all_genes
        showNotification(
          sprintf("ℹ️ 使用全基因组作为背景: %d 个基因（如需更准确结果，请上传背景基因文件）",
                  length(universe)),
          type = "message"
        )
      }

      # =====================================================
      # 运行 KEGG 富集分析 - 支持universe参数
      # =====================================================
      kegg_obj <- NULL

      # 检查基因数量
      if (is.null(entrez_ids) || length(entrez_ids) == 0) {
        showNotification("错误：没有有效的 ENTREZID 进行KEGG分析", type = "error")
        return(NULL)
      }

      cat("🔧 单列基因KEGG富集分析...\n")
      cat(sprintf("📊 输入基因数量: %d\n", length(entrez_ids)))
      cat(sprintf("📊 物种: %s\n", input$single_gene_species))
      cat(sprintf("📊 P值阈值: %s\n", input$single_gene_kegg_p))
      cat(sprintf("📊 背景基因数量: %s\n",
                  ifelse(is.null(universe), "NULL (使用全基因组)", length(universe))))

      # 详细调试信息
      if (Sys.getenv("SHINY_DEBUG") == "TRUE") {
        cat("🔍 调试信息：\n")
        cat(sprintf("  entrez_ids 类别: %s\n", class(entrez_ids)))
        cat(sprintf("  entrez_ids 长度: %d\n", length(entrez_ids)))
        cat(sprintf("  前5个基因: %s\n", paste(head(entrez_ids, 5), collapse=", ")))
        cat(sprintf("  input$single_gene_species: %s\n", input$single_gene_species))
        cat(sprintf("  input$single_gene_kegg_p: %s\n", input$single_gene_kegg_p))
      }

      # 验证必需的输入参数
      if (is.null(input$single_gene_species) || input$single_gene_species == "") {
        showNotification("错误：请选择物种", type = "error")
        return(NULL)
      }

      # 🔧 修复：验证并转换P值参数
      pvalue_cutoff <- tryCatch({
        as.numeric(input$single_gene_kegg_p)
      }, error = function(e) {
        NULL
      })

      if (is.null(pvalue_cutoff) || is.na(pvalue_cutoff)) {
        showNotification("错误：P值阈值格式不正确", type = "error")
        return(NULL)
      }

      # 🔧 新增：验证qCutoff（使用默认值0.2）
      qvalue_cutoff <- 0.2

      cat(sprintf("✅ 参数验证通过: pCutoff=%.4f, qCutoff=%.4f\n", pvalue_cutoff, qvalue_cutoff))

      # =====================================================
      # 方法1: 尝试使用 enrich_local_KEGG_v2（支持universe）✨
      # =====================================================

      if (exists("enrich_local_KEGG_v2", mode = "function")) {
        cat("✅ 使用 enrich_local_KEGG_v2（支持universe参数）\n")

        kegg_obj <- tryCatch({
          args <- list(
            gene = entrez_ids,
            species = input$single_gene_species,
            pCutoff = pvalue_cutoff,  # 🔧 使用验证后的参数
            qCutoff = qvalue_cutoff,  # 🔧 使用验证后的参数
            pAdjustMethod = "BH"
          )

          # 添加universe参数（如果有）
          if (!is.null(universe)) {
            args$universe <- universe
            cat(sprintf("📊 使用自定义背景基因集: %d 个基因\n", length(universe)))
          }

          cat("🔍 调用 enrich_local_KEGG_v2...\n")
          result <- do.call(enrich_local_KEGG_v2, args)

          cat(sprintf("✅ enrich_local_KEGG_v2成功！找到 %d 个显著通路\n",
                      nrow(result@result)))

          result

        }, error = function(e) {
          cat(sprintf("❌ enrich_local_KEGG_v2失败: %s\n", e$message))
          cat(sprintf("   错误类型: %s\n", class(e)[1]))
          cat(sprintf("   当前参数:\n"))
          cat(sprintf("     - 基因数量: %d\n", length(entrez_ids)))
          cat(sprintf("     - 物种: %s\n", input$single_gene_species))
          cat(sprintf("     - P值: %s\n", input$single_gene_kegg_p))
          showNotification(sprintf("KEGG分析失败: %s", e$message), type = "error", duration = 15)
          NULL
        })
      }

      # =====================================================
      # 方法2: 尝试使用 biofree.qyKEGGtools（原始版本）
      # =====================================================

      if (is.null(kegg_obj) && require("biofree.qyKEGGtools", quietly = TRUE)) {
        cat("⚠️ enrich_local_KEGG_v2不可用，尝试使用biofree.qyKEGGtools\n")

        # 检查原始函数是否支持universe
        func_args <- tryCatch({
          formals(biofree.qyKEGGtools::enrich_local_KEGG)
        }, error = function(e) NULL)

        supports_universe <- !is.null(func_args) && "universe" %in% names(func_args)

        if (supports_universe) {
          cat("✅ biofree.qyKEGGtools支持universe参数\n")

          kegg_obj <- tryCatch({
            args <- list(
              gene = entrez_ids,
              species = input$single_gene_species,
              pCutoff = pvalue_cutoff,  # 🔧 使用验证后的参数
              qCutoff = qvalue_cutoff   # 🔧 使用验证后的参数
            )

            if (!is.null(universe)) {
              args$universe <- universe
            }

            result <- do.call(biofree.qyKEGGtools::enrich_local_KEGG, args)

            cat(sprintf("✅ biofree.qyKEGGtools成功！找到 %d 个显著通路\n",
                        nrow(result@result)))

            result

          }, error = function(e) {
            warning(sprintf("biofree.qyKEGGtools失败: %s", e$message))
            NULL
          })

        } else {
          cat("⚠️ biofree.qyKEGGtools不支持universe参数\n")

          if (!is.null(universe)) {
            showNotification(
              "注意：当前版本的biofree.qyKEGGtools不支持universe参数，将使用全基因组背景。建议更新到最新版本或使用clusterProfiler。",
              type = "warning",
              duration = 10
            )
          }

          kegg_obj <- tryCatch({
            result <- biofree.qyKEGGtools::enrich_local_KEGG(
              gene = entrez_ids,
              species = input$single_gene_species,
              pCutoff = pvalue_cutoff,  # 🔧 使用验证后的参数
              qCutoff = qvalue_cutoff   # 🔧 使用验证后的参数
            )

            cat(sprintf("✅ biofree.qyKEGGtools成功！找到 %d 个显著通路\n",
                        nrow(result@result)))

            result

          }, error = function(e) {
            warning(sprintf("biofree.qyKEGGtools失败: %s", e$message))
            NULL
          })
        }
      }

      # 如果biofree.qyKEGGtools不可用或失败，尝试使用clusterProfiler::enrichKEGG
      if(is.null(kegg_obj) && require("clusterProfiler", quietly = TRUE)) {
        showNotification("使用clusterProfiler::enrichKEGG进行单列基因KEGG富集分析", type = "message")

        # 设置KEGG数据库的物种代码
        kegg_org <- if(input$single_gene_species == "mmu") "mmu" else "hsa"

        kegg_obj <- tryCatch({
          clusterProfiler::enrichKEGG(
            gene = entrez_ids,
            organism = kegg_org,
            pvalueCutoff = pvalue_cutoff,  # 🔧 使用验证后的参数
            pAdjustMethod = "BH",
            universe = universe
          )
        }, error = function(e) {
          cat(sprintf("❌ clusterProfiler::enrichKEGG失败: %s\n", e$message))
          showNotification(sprintf("KEGG分析失败: %s", e$message), type = "error")
          NULL
        })
      }

      if (is.null(kegg_obj) || nrow(kegg_obj@result) == 0) {
        showNotification("KEGG富集分析没有结果。", type = "warning")
        return(NULL)
      }

      df <- kegg_obj@result

      # 清理描述信息
      df$Description <- gsub(" - Mus musculus.*| - Homo sapiens.*", "", df$Description)

      # 将 ENTREZID 转换回 SYMBOL 用于显示
      all_entrez <- unique(unlist(strsplit(df$geneID, "/")))
      symbol_mapped <- AnnotationDbi::mapIds(db_obj,
                                             keys = all_entrez,
                                             column = "SYMBOL",
                                             keytype = "ENTREZID",
                                             multiVals = "first")

      df$geneID <- sapply(df$geneID, function(x) {
        ids <- unlist(strsplit(x, "/"))
        syms <- symbol_mapped[ids]
        syms[is.na(syms)] <- ids[is.na(syms)]
        paste(syms, collapse = "/")
      })

      # 添加原始基因数量信息
      attr(df, "input_genes_count") <- length(gene_symbols)
      attr(df, "mapped_genes_count") <- length(entrez_ids)

      return(df)

    }, error = function(e) {
      showNotification(paste("KEGG 分析错误:", e$message), type = "error")
      return(NULL)
    })
  })

  # --- 单列基因 KEGG 结果下载 ---
  output$download_single_gene_kegg <- downloadHandler(
    filename = function() {
      paste0("Single_Gene_KEGG_Enrichment_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(single_gene_kegg_data())
      write.csv(single_gene_kegg_data(), file, row.names = FALSE)
    }
  )

  # 单列基因KEGG图表生成reactive
  single_gene_kegg_plot_obj <- reactive({
    req(single_gene_kegg_data())
    df <- single_gene_kegg_data()

    # 计算Fold Enrichment（如果数据框中没有）
    if (!"FoldEnrichment" %in% colnames(df)) {
      # 从GeneRatio和BgRatio计算Fold Enrichment
      # GeneRatio格式: "5/120", BgRatio格式: "50/5000"
      df$FoldEnrichment <- sapply(1:nrow(df), function(i) {
        gene_ratio <- as.numeric(strsplit(df$GeneRatio[i], "/")[[1]])
        bg_ratio <- as.numeric(strsplit(df$BgRatio[i], "/")[[1]])

        # 处理可能的NA或Inf值
        if (length(gene_ratio) < 2 || length(bg_ratio) < 2) {
          return(NA)
        }
        if (gene_ratio[2] == 0 || bg_ratio[2] == 0) {
          return(NA)
        }

        fe <- (gene_ratio[1] / gene_ratio[2]) / (bg_ratio[1] / bg_ratio[2])
        return(ifelse(is.finite(fe), fe, NA))
      })

      # 确保是数值类型
      df$FoldEnrichment <- as.numeric(df$FoldEnrichment)
    }

    df_plot <- head(df[order(df$p.adjust),], 20)

    input_count <- attr(df, "input_genes_count")
    mapped_count <- attr(df, "mapped_genes_count")

    txt_col <- if(input$theme_toggle) "white" else "black"
    grid_col <- if(input$theme_toggle) "#444444" else "#cccccc"

    font_face <- if(input$single_gene_kegg_bold) "bold" else "plain"

    # 根据用户选择设置X轴变量
    if (input$single_gene_kegg_x_axis == "FoldEnrichment") {
      x_var <- df_plot$FoldEnrichment
      x_label <- "Fold Enrichment"
    } else {
      x_var <- df_plot$Count
      x_label <- "Gene Count"
    }

    # 使用aes()而不是aes_string()
    p <- ggplot(df_plot, aes(x = x_var, y = reorder(Description, x_var), size = x_var, color = p.adjust)) +
      geom_point() +
      scale_color_gradient(low = input$single_gene_kegg_high_col, high = input$single_gene_kegg_low_col) +
      theme_minimal() +
      labs(
        x = x_label,
        y = "",
        title = "单列基因 KEGG 富集分析",
        subtitle = paste("输入基因:", input_count, "个 | 成功映射:", mapped_count, "个")
      ) +
      theme(
        panel.background = element_rect(fill = "transparent", colour = NA),
        plot.background = element_rect(fill = "transparent", colour = NA),
        plot.title = element_text(color = txt_col, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(color = txt_col, hjust = 0.5),
        text = element_text(color = txt_col, size = input$single_gene_kegg_font_size, face = font_face),
        axis.text = element_text(color = txt_col, size = input$single_gene_kegg_font_size),
        legend.text = element_text(color = txt_col),
        legend.title = element_text(color = txt_col),
        axis.line = element_line(color = txt_col),
        panel.grid.major = element_line(color = grid_col),
        panel.grid.minor = element_line(color = grid_col)
      )

    return(p)
  })

  # 单列基因KEGG图表下载
  output$download_single_gene_kegg_plot <- downloadHandler(
    filename = function() {
      paste0("Single_Gene_KEGG_Dotplot_", Sys.Date(), ".", input$single_gene_kegg_export_format)
    },
    content = function(file) {
      req(single_gene_kegg_plot_obj())

      # 获取当前图表
      p <- single_gene_kegg_plot_obj()

      # 根据格式保存
      if (input$single_gene_kegg_export_format == "png") {
        png(file, width = 10, height = 8, units = "in", res = 300)
      } else if (input$single_gene_kegg_export_format == "pdf") {
        pdf(file, width = 10, height = 8)
      } else if (input$single_gene_kegg_export_format == "svg") {
        svg(file, width = 10, height = 8)
      }

      print(p)
      dev.off()
    }
  )

  # --- 单列基因 KEGG 点图 ---
  output$single_gene_kegg_dotplot <- renderPlot({
    single_gene_kegg_plot_obj()
  })

  # --- 单列基因 KEGG 结果表格 ---
  output$single_gene_kegg_table <- DT::renderDataTable({
    req(single_gene_kegg_data())
    DT::datatable(single_gene_kegg_data(), options = list(scrollX = TRUE), rownames = FALSE)
  })

  # =====================================================
  # 🤖 AI解读KEGG富集分析
  # =====================================================

  # 存储AI解读结果
  ai_kegg_result <- reactiveVal(NULL)

  # AI解读按钮响应
  observeEvent(input$ai_interpret_kegg, {

    # 验证API配置
    api_key <- load_zhipu_config()
    if (api_key == "") {
      showNotification("❌ 请先配置智谱AI API密钥！", type = "error", duration = 5)
      return(NULL)
    }

    # 验证富集分析结果
    kegg_res <- kegg_data_processed()
    if (is.null(kegg_res) || nrow(kegg_res) == 0) {
      showNotification("❌ 请先运行KEGG富集分析！", type = "error", duration = 5)
      return(NULL)
    }

    # 验证差异分析结果
    deg_res <- deg_results$deg_df
    if (is.null(deg_res) || nrow(deg_res) == 0) {
      showNotification("❌ 请先运行差异分析！", type = "error", duration = 5)
      return(NULL)
    }

    # 显示加载动画
    output$ai_kegg_interpretation <- renderUI({
      div(
        class = "ai-loading",
        style = "text-align: center; padding: 50px; background: #f8f9fa; border-radius: 10px; margin: 20px 0;",
        shiny::includeSpinner(spinner = TRUE, color = "#f093fb"),
        h4("🤖 AI正在分析KEGG富集结果...", style = "margin-top: 20px; color: #f093fb;"),
        p("这通常需要10-30秒，请稍候...", class = "text-muted")
      )
    })

    # 执行AI分析（同步调用，但通过renderUI保持UI响应）
    tryCatch({
        # 收集KEGG富集数据
        deg_info <- deg_res %>%
          summarize(
            n_total = n(),
            n_up = sum(Status == "Up", na.rm = TRUE),
            n_down = sum(Status == "Down", na.rm = TRUE),
            top_up = paste(head(SYMBOL[Status == "Up"], 20), collapse = ", "),
            top_down = paste(head(SYMBOL[Status == "Down"], 20), collapse = ", ")
          )

        kegg_info <- kegg_res %>%
          head(15) %>%
          summarize(
            n_terms = n(),
            top_terms = paste(head(Term, 5), collapse = "; ")
          )

        # 构建提示词
        prompt <- sprintf(
          '请作为一位资深生物信息学专家，深入解读以下KEGG通路富集分析结果：

## 实验背景
- 差异基因总数：%d 个
- 上调基因：%d 个
- 下调基因：%d 个

**主要上调基因**：%s

**主要下调基因**：%s

---

## KEGG 通路富集分析
检测到 %d 个显著富集的KEGG通路
**Top 5**：%s

---

请提供以下方面的专业解读（600-1000字）：

### 1. 核心通路发现
- 哪些信号通路和代谢途径最为显著？
- 这些通路反映了细胞或组织的什么状态？

### 2. 通路网络分析
- 通路之间的关联性和crosstalk
- 上游-下游信号通路关系
- 可能的级联反应

### 3. 疾病/表型关联
- 与哪些疾病、生理过程或表型相关？
- 潜在的病理机制或生理意义

### 4. 研究价值与启示
- 可能的药物靶点或生物标志物
- 对相关领域研究的启示
- 建议的后续实验验证方向

**要求**：
- 使用专业但易懂的学术语言
- 基于数据事实，避免过度推测
- 提供有见地的生物学解释
- 条理清晰，层次分明',
          deg_info$n_total,
          deg_info$n_up,
          deg_info$n_down,
          deg_info$top_up,
          deg_info$top_down,
          kegg_info$n_terms,
          kegg_info$top_terms
        )

        # 调用智谱AI
        cat("🤖 调用智谱AI API进行KEGG解读...\n")
        result <- call_zhipu_api(
          prompt = prompt,
          model = input$kegg_ai_model %||% "glm-4-air",
          temperature = 0.7,
          max_tokens = 2500
        )

        cat(sprintf("✅ KEGG AI分析完成！使用了 %d tokens\n", result$total_tokens))

        # 保存结果
        ai_kegg_result(result)

        # 显示结果
        output$ai_kegg_interpretation <- renderUI({
          tagList(
            # 成功提示
            div(
              class = "alert alert-success",
              style = "background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                     color: white; border: none; border-radius: 10px;",
              h4("✅ AI解读完成", style = "color: white; margin-top: 0;"),
              p(sprintf("使用模型: %s | Token使用: %d | 预估成本: ¥%.4f",
                result$model, result$total_tokens, result$total_tokens * 1 / 1000000),
                style = "color: rgba(255,255,255,0.9); margin-bottom: 0;")
            ),

            # AI解读内容
            div(
              class = "ai-interpretation-box",
              style = "background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                     padding: 30px; border-radius: 15px; margin: 20px 0;
                     box-shadow: 0 4px 20px rgba(0,0,0,0.1);",
              HTML(markdown::renderText(result$text))
            ),

            # 操作按钮
            fluidRow(
              column(6,
                actionButton("copy_kegg_ai_result", "📋 复制到剪贴板",
                            class = "btn-info btn-block",
                            icon = shiny::icon("copy"))
              ),
              column(6,
                downloadButton("download_kegg_ai_result", "💾 保存解读",
                              class = "btn-primary btn-block")
              )
            ),

            tags$hr(),

            # 继续提问区域
            h5("💬 继续提问"),
            p("如果您对AI解读有任何疑问，或者想深入了解某个方面，可以继续提问：", class = "text-muted"),
            textInput("kegg_followup_question", "您的问题...",
                     placeholder = "例如：能否详细解释一下细胞周期通路的作用机制？"),
            actionButton("ask_kegg_followup", "🚀 提问", class = "btn-success"),
            uiOutput("kegg_followup_answer")
          )
        })

        showNotification("✅ KEGG AI解读完成！", type = "message", duration = 5)

      }, error = function(e) {
        # 错误处理
        output$ai_kegg_interpretation <- renderUI({
          div(
            class = "alert alert-danger",
            h4("❌ AI解读失败"),
            p(e$message),
            p("可能的原因：", class = "text-muted"),
            tags$ul(
              tags$li("API密钥未配置或已过期"),
              tags$li("网络连接问题"),
              tags$li("API服务暂时不可用"),
              tags$li("请求超时或数据量过大")
            ),
            actionButton("retry_kegg_ai", "🔄 重试", class = "btn-warning")
          )
        })

        showNotification(paste("❌ KEGG AI解读失败:", e$message), type = "error", duration = 10)
      })
  })

  # 追问功能
  output$kegg_followup_answer <- renderUI({
    req(input$ask_kegg_followup, input$kegg_followup_question)

    tryCatch({
      # 简化的追问提示词
      followup_prompt <- sprintf(
        "基于之前的KEGG富集分析结果，用户追问：%s\n\n请提供详细解答。",
        input$kegg_followup_question
      )

      answer <- call_zhipu_simple(followup_prompt, model = "glm-4-air")

      div(
        class = "ai-followup-answer",
        style = "background: #e8f4f8; padding: 20px; border-radius: 10px; margin-top: 15px;
               border-left: 4px solid #f093fb;",
        h6("🤖 AI回答", style = "color: #f093fb; margin-top: 0;"),
        HTML(markdown::renderText(answer))
      )
    }, error = function(e) {
      div(class = "alert alert-warning", paste("❌ 抱歉，", e$message))
    })
  })

  # 下载AI解读结果
  output$download_kegg_ai_result <- downloadHandler(
    filename = function() {
      paste0("Biofree_AI_KEGG解读_", Sys.Date(), ".md")
    },
    content = function(file) {
      req(ai_kegg_result())
      result <- ai_kegg_result()

      # 添加元数据
      header <- paste0(
        "# Biofree AI KEGG通路分析解读\n",
        "-----\n\n",
        "**生成时间**: ", Sys.time(), "\n",
        "**分析版本**: Biofree v12\n",
        "**AI模型**: 智谱AI ", result$model, "\n",
        "**Token使用**: ", result$total_tokens, "\n",
        "-----\n\n"
      )

      writeLines(paste0(header, result$text), file)
    },
    contentType = "text/markdown"
  )

  # 返回KEGG结果供其他模块使用
  return(reactive({ kegg_data_processed() }))
}