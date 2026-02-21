# ============================================================================
# 多文件Universe选择模块
# ============================================================================
# 用途：支持上传多个DE结果文件，自动计算它们的交集作为Universe
# 适用场景：A上调 ∩ B下调等交集分析
# ============================================================================

# ============================================================================
# 函数1: 多文件Universe选择UI
# ============================================================================

#' 多文件Universe选择UI
#'
#' @param id 模块ID
#' @param title 标题
#' @param min_files 最少文件数（默认2）
#' @param max_files 最多文件数（默认5）
#' @return UI元素
#' @export
multi_file_universe_ui <- function(id,
                                   title = "📊 上传多个DE结果文件",
                                   min_files = 2,
                                   max_files = 5) {
  ns <- NS(id)

  tagList(
    wellPanel(
      style = "background-color: #f0f8ff; border: 2px solid #4a90e2;",
      h4(title),
      p("对于交集分析（如 A上调 ∩ B下调），Universe应该是所有数据集的交集。请上传所有相关的DE结果文件。",
        class = "text-muted"),

      hr(),

      # 文件上传区域（动态）
      uiOutput(ns("file_upload_inputs")),

      hr(),

      # 添加/删除文件按钮
      fluidRow(
        column(6,
          actionButton(
            inputId = ns("add_file"),
            label = tagList(icon("plus"), "添加更多文件"),
            class = "btn-info btn-sm"
          )
        ),
        column(6,
          actionButton(
            inputId = ns("remove_file"),
            label = tagList(icon("minus"), "移除最后一个文件"),
            class = "btn-warning btn-sm"
          )
        )
      ),

      hr(),

      # 文件状态显示
      uiOutput(ns("file_status")),

      hr(),

      # 列名设置（每个文件独立）
      h5("📋 设置各文件的列名映射"),
      p("每个文件可能有不同的列名，请分别设置：", class="text-muted small"),

      uiOutput(ns("column_selectors")),

      hr(),

      # 预览Universe
      h5("🔍 Universe预览"),
      uiOutput(ns("universe_preview")),

      hr(),

      # 确认按钮
      fluidRow(
        column(12,
          align = "center",
          actionButton(
            inputId = ns("confirm_universe"),
            label = tagList(
              icon("check-circle"),
              strong("确认Universe设置")
            ),
            class = "btn-success btn-lg"
          )
        )
      )
    )
  )
}


# ============================================================================
# 函数2: 多文件Universe选择Server
# ============================================================================

#' 多文件Universe选择Server
#'
#' @param input,output,session 标准Shiny参数
#' @param min_files 最少文件数
#' @param max_files 最多文件数
#' @return 包含所有文件和Universe信息的reactive列表
#' @export
multi_file_universe_server <- function(input, output, session,
                                       min_files = 2,
                                       max_files = 5) {

  ns <- session$ns

  # 1. 动态生成文件上传输入框
  n_files <- reactiveVal(min_files)

  output$file_upload_inputs <- renderUI({
    n <- n_files()

    tagList(
      lapply(1:n, function(i) {
        div(
          style = "margin-bottom: 10px;",
          h5(sprintf("数据集 %d", i)),
          fileInput(
            inputId = ns(sprintf("file_%d", i)),
            label = NULL,
            buttonLabel = sprintf("上传数据集 %d（CSV）", i),
            accept = c("text/csv", "text/comma-separated-values")
          )
        )
      })
    )
  })

  # 2. 添加文件按钮
  observeEvent(input$add_file, {
    current <- n_files()
    if (current < max_files) {
      n_files(current + 1)
      showNotification(sprintf("已添加数据集 %d", current + 1),
                       type = "message", duration = 3)
    } else {
      showNotification(sprintf("最多支持 %d 个文件", max_files),
                       type = "warning", duration = 3)
    }
  })

  # 3. 移除文件按钮
  observeEvent(input$remove_file, {
    current <- n_files()
    if (current > min_files) {
      n_files(current - 1)
      showNotification(sprintf("已移除数据集 %d", current),
                       type = "message", duration = 3)
    } else {
      showNotification(sprintf("至少需要 %d 个文件", min_files),
                       type = "warning", duration = 3)
    }
  })

  # 4. 读取所有上传的文件
  all_files <- reactive({
    n <- n_files()

    files <- list()

    for (i in 1:n) {
      file_input_id <- sprintf("file_%d", i)
      file_info <- input[[file_input_id]]

      if (!is.null(file_info)) {
        files[[i]] <- list(
          index = i,
          name = file_info$name,
          path = file_info$datapath,
          size = file_info$size
        )
      }
    }

    return(files)
  })

  # 5. 显示文件状态
  output$file_status <- renderUI({
    files <- all_files()

    if (length(files) == 0) {
      return(div(class = "alert alert-warning",
                 "请上传至少 ", min_files, " 个DE结果文件"))
    }

    # 检查是否所有文件都上传了
    n <- n_files()
    if (length(files) < n) {
      return(div(class = "alert alert-info",
                 sprintf("已上传 %d/%d 个文件，请继续上传",
                         length(files), n)))
    }

    # 所有文件都上传了
    file_info_table <- lapply(files, function(f) {
      tags$tr(
        tags$td(sprintf("数据集 %d", f$index)),
        tags$td(strong(f$name)),
        tags$td(sprintf("%.2f MB", f$size / 1024 / 1024)),
        tags$td(tags$span(class = "badge bg-success", "✓ 已上传"))
      )
    })

    div(
      class = "alert alert-success",
      h5("✓ 所有文件已上传"),
      tags$table(
        class = "table table-condensed",
        tags$thead(
          tags$tr(
            tags$th("数据集"),
            tags$th("文件名"),
            tags$th("大小"),
            tags$th("状态")
          )
        ),
        tags$tbody(do.call(tagList, file_info_table))
      )
    )
  })

  # 6. 为每个文件生成列选择器
  output$column_selectors <- renderUI({
    files <- all_files()
    if (length(files) == 0) return(NULL)

    column_selectors <- lapply(files, function(f) {
      # 读取列名
      cols <- tryCatch({
        names(read.csv(f$path, nrows = 0, check.names = FALSE))
      }, error = function(e) {
        character(0)
      })

      if (length(cols) == 0) return(NULL)

      # 自动检测
      gene_col <- grep("^gene$|^Gene", cols, ignore.case = TRUE, value = TRUE)[1]
      fc_col <- grep("log2|fold|fc", cols, ignore.case = TRUE, value = TRUE)[1]
      pval_col <- grep("padj|pval|fdr", cols, ignore.case = TRUE, value = TRUE)[1]

      div(
        wellPanel(
          style = "background-color: #fafafa; margin-bottom: 10px;",
          h6(sprintf("数据集 %d: %s", f$index, f$name)),
          fluidRow(
            column(4,
              selectInput(
                inputId = ns(sprintf("gene_col_%d", f$index)),
                label = "基因ID列",
                choices = c("请选择..." = "", cols),
                selected = if (!is.na(gene_col) && !is.null(gene_col)) gene_col else ""
              )
            ),
            column(4,
              selectInput(
                inputId = ns(sprintf("fc_col_%d", f$index)),
                label = "log2FC列",
                choices = c("请选择..." = "", cols),
                selected = if (!is.na(fc_col) && !is.null(fc_col)) fc_col else ""
              )
            ),
            column(4,
              selectInput(
                inputId = ns(sprintf("pval_col_%d", f$index)),
                label = "p值列",
                choices = c("请选择..." = "", cols),
                selected = if (!is.na(pval_col) && !is.null(pval_col)) pval_col else ""
              )
            )
          )
        )
      )
    })

    do.call(tagList, column_selectors)
  })

  # 7. 计算Universe预览
  output$universe_preview <- renderUI({
    files <- all_files()
    if (length(files) == 0) return(NULL)

    # 读取每个文件的基因列
    universe_info <- list()

    for (f in files) {
      # 获取用户选择的列名
      gene_col_input <- input[[sprintf("gene_col_%d", f$index)]]

      if (!is.null(gene_col_input) && gene_col_input != "") {
        tryCatch({
          df <- read.csv(f$path)
          genes <- unique(df[[gene_col_input]])
          genes <- genes[!is.na(genes)]

          universe_info[[f$index]] <- list(
            dataset_name = sprintf("数据集 %d", f$index),
            n_genes = length(genes),
            genes = genes
          )
        }, error = function(e) {
          NULL
        })
      }
    }

    if (length(universe_info) < 2) {
      return(div(class = "alert alert-warning",
                 "请为每个文件选择基因ID列"))
    }

    # 计算交集
    all_genes_lists <- lapply(universe_info, function(x) x$genes)
    universe_intersect <- Reduce(intersect, all_genes_lists)

    # 创建预览表格
    preview_rows <- lapply(universe_info, function(info) {
      tags$tr(
        tags$td(info$dataset_name),
        tags$td(sprintf("%,d", info$n_genes)),
        tags$td(sprintf("%.1f%%", info$n_genes / length(universe_intersect) * 100))
      )
    })

    div(
      class = "alert alert-info",
      h5("Universe计算预览"),
      tags$table(
        class = "table table-striped",
        tags$thead(
          tags$tr(
            tags$th("数据集"),
            tags$th("基因数"),
            tags$th("相对Universe大小")
          )
        ),
        tags$tbody(do.call(tagList, preview_rows)),
        tags$tfoot(
          tags$tr(
            tags$td(strong("Universe (交集)")),
            tags$td(strong(sprintf("%,d", length(universe_intersect)))),
            tags$td(tags$span(class = "badge bg-primary", "100%"))
          ),
          style = "background-color: #e3f2fd;"
        )
      ),
      p("⚠️  Universe = 所有数据集基因的交集",
        class = "small text-muted")
    )
  })

  # 8. 确认按钮 - 返回最终结果
  final_result <- eventReactive(input$confirm_universe, {
    files <- all_files()

    if (length(files) < min_files) {
      showNotification(sprintf("至少需要 %d 个文件", min_files),
                       type = "error")
      return(NULL)
    }

    # 收集所有文件的信息
    datasets <- list()

    for (f in files) {
      # 获取列名选择
      gene_col <- input[[sprintf("gene_col_%d", f$index)]]
      fc_col <- input[[sprintf("fc_col_%d", f$index)]]
      pval_col <- input[[sprintf("pval_col_%d", f$index)]]

      if (is.null(gene_col) || gene_col == "") {
        showNotification(sprintf("数据集 %d: 请选择基因ID列", f$index),
                         type = "error")
        return(NULL)
      }

      # 读取数据
      df <- read.csv(f$path)

      datasets[[f$index]] <- list(
        index = f$index,
        name = f$name,
        path = f$path,
        df = df,
        gene_col = gene_col,
        fc_col = fc_col,
        pval_col = pval_col,
        genes <- unique(df[[gene_col]])
      )
    }

    # 计算Universe（所有数据集基因的交集）
    all_genes <- lapply(datasets, function(d) d$genes)
    universe <- Reduce(intersect, all_genes)

    showNotification(sprintf("✓ Universe设置完成！包含 %,d 个基因",
                           length(universe)),
                   type = "message", duration = 5)

    # 返回结果
    list(
      datasets = datasets,
      universe = universe,
      universe_size = length(universe),
      n_datasets = length(datasets),
      strategy = "multi_file_intersection"
    )
  })

  # 返回最终结果
  return(final_result)
}


# ============================================================================
# 使用示例
# ============================================================================

# 示例：在KEGG模块中使用多文件Universe
# ======================================

# kegg_enrichment_ui <- function(id) {
#   ns <- NS(id)
#
#   tagList(
#     h4("KEGG富集分析 - 多数据集交集模式"),
#
#     # 多文件Universe选择
#     multi_file_universe_ui(
#       id = ns("multi_file"),
#       title = "上传多个DE结果文件",
#       min_files = 2,
#       max_files = 3
#     ),
#
#     hr(),
#
#     # 设置每个数据集的筛选条件
#     h5("设置每个数据集的筛选条件"),
#     uiOutput(ns("threshold_inputs")),
#
#     hr(),
#
#     actionButton(ns("run_kegg"), "🚀 运行KEGG分析", class = "btn-primary")
#   )
# }
#
# kegg_enrichment_server <- function(id) {
#   moduleServer(id, function(input, output, session) {
#     ns <- session$ns
#
#     # 多文件Universe
#     multi_file_result <- multi_file_universe_server(
#       id = "multi_file",
#       min_files = 2,
#       max_files = 3
#     )
#
#     # 动态生成阈值设置
#     output$threshold_inputs <- renderUI({
#       req(multi_file_result())
#
#       datasets <- multi_file_result()$datasets
#
#       tagList(
#         lapply(datasets, function(d) {
#           div(
#             style = "margin-bottom: 10px;",
#             h6(sprintf("数据集 %d", d$index)),
#             fluidRow(
#               column(6,
#                 sliderInput(
#                   inputId = ns(sprintf("fc_threshold_%d", d$index)),
#                   label = "log2FC阈值",
#                   min = -5, max = 5, value = 1, step = 0.1
#                 )
#               ),
#               column(6,
#                 numericInput(
#                   inputId = ns(sprintf("pval_threshold_%d", d$index)),
#                   label = "p值阈值",
#                   min = 0.001, max = 0.5, value = 0.05
#                 )
#               )
#             )
#           )
#         })
#       )
#     })
#
#     # 执行KEGG分析
#     observeEvent(input$run_kegg, {
#       req(multi_file_result())
#
#       result <- multi_file_result()
#       datasets <- result$datasets
#       universe <- result$universe
#
#       # 从每个数据集中筛选基因
#       target_gene_lists <- list()
#
#       for (d in datasets) {
#         fc_thresh <- input[[sprintf("fc_threshold_%d", d$index)]]
#         pval_thresh <- input[[sprintf("pval_threshold_%d", d$index)]]
#
#         df <- d$df
#
#         # 筛选
#         target_genes <- df[[d$gene_col]][
#           df[[d$fc_col]] > fc_thresh &
#           df[[d$pval_col]] < pval_thresh
#         ]
#
#         target_gene_lists[[d$index]] <- target_genes
#       }
#
#       # 计算交集（例如：数据集1上调 ∩ 数据集2下调）
#       target_genes <- Reduce(intersect, target_gene_lists)
#
#       message(sprintf("Target基因数: %d", length(target_genes)))
#       message(sprintf("Universe基因数: %d", length(universe)))
#
#       # 执行KEGG分析
#       kegg_result <- enrichKEGG(
#         gene = target_genes,
#         universe = universe,
#         organism = "mmu",
#         pvalueCutoff = 0.05
#       )
#
#       # 显示结果...
#     })
#   })
# }


print("✅ 多文件Universe选择模块加载完成！")
print("📖 查看文档末尾的使用示例")
