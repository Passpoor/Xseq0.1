# ============================================================================
# 通用列选择UI模块
# ============================================================================
# 用途：为所有需要上传DE结果文件的模块提供统一的列名选择UI
# 特性：动态读取CSV列名，用户手动选择对应的列，避免硬编码
# ============================================================================

# ============================================================================
# 函数1: 创建列选择UI（用于DE结果文件上传后）
# ============================================================================

#' 创建列选择UI模块
#'
#' @param id 模块ID（前缀）
#' @param title 标题
#' @param subtitle 副标题
#' @param show_auto_detect 是否显示自动检测结果（默认TRUE）
#' @return UI元素
#' @export
column_selector_ui <- function(id, title = "📋 列名映射设置",
                                subtitle = "请选择CSV文件中各列对应的含义",
                                show_auto_detect = TRUE) {

  ns <- NS(id)

  tagList(
    wellPanel(
      style = "background-color: #f8f9fa; border: 1px solid #dee2e6;",
      h4(title),
      p(subtitle, class = "text-muted"),

      # 自动检测结果提示（可选）
      if (show_auto_detect) {
        uiOutput(ns("auto_detect_info"))
      },

      hr(),

      # 列选择器
      fluidRow(
        # 基因ID列选择
        column(4,
          selectInput(
            inputId = ns("gene_col"),
            label = tagList(
              icon("dna"),
              strong("基因ID列"),
              tags$span(class = "badge bg-info", "必需")
            ),
            choices = c("请先上传文件" = ""),
            selected = NULL
          ),
          p("选择包含基因ID、基因符号或ENSEMBL ID的列", class = "help-block small text-muted")
        ),

        # log2FC列选择
        column(4,
          selectInput(
            inputId = ns("fc_col"),
            label = tagList(
              icon("arrows-alt-v"),
              strong("log2FC列"),
              tags$span(class = "badge bg-info", "必需")
            ),
            choices = c("请先上传文件" = ""),
            selected = NULL
          ),
          p("选择包含log2FoldChange或logFC的列", class = "help-block small text-muted")
        ),

        # p值列选择
        column(4,
          selectInput(
            inputId = ns("pval_col"),
            label = tagList(
              icon("calculator"),
              strong("p值列"),
              tags$span(class = "badge bg-warning", "必需")
            ),
            choices = c("请先上传文件" = ""),
            selected = NULL
          ),
          p("选择包含padj、pvalue或FDR的列", class = "help-block small text-muted")
        )
      ),

      hr(),

      # 验证按钮
      fluidRow(
        column(12,
          align = "center",
          actionButton(
            inputId = ns("validate_columns"),
            label = tagList(
              icon("check-circle"),
              strong("验证列选择")
            ),
            class = "btn-primary"
          ),
          br(), br(),
          uiOutput(ns("validation_result"))
        )
      )
    )
  )
}


# ============================================================================
# 函数2: 列选择服务器端逻辑
# ============================================================================

#' 列选择服务器端逻辑
#'
#' @param input,output,session 标准Shiny参数
#' @param file_reactive 包含CSV文件的reactive表达式
#' @param auto_detect 是否尝试自动检测列名（默认TRUE）
#' @return 包含选定列名的reactive列表
#' @export
column_selector_server <- function(input, output, session,
                                    file_reactive,
                                    auto_detect = TRUE) {

  ns <- session$ns

  # 1. 读取文件并提取列名
  column_names <- reactive({
    req(file_reactive())

    file_path <- file_reactive()$datapath

    tryCatch({
      # 读取CSV（只读取第一行获取列名）
      col_names <- names(read.csv(file_path, nrows = 0, check.names = FALSE))

      return(col_names)

    }, error = function(e) {
      showNotification(
        paste("读取文件失败:", e$message),
        type = "error",
        duration = 10
      )
      return(NULL)
    })
  })

  # 2. 自动检测列名（如果启用）
  auto_detected <- reactive({
    req(column_names())

    if (!auto_detect) {
      return(list(
        gene_col = NULL,
        fc_col = NULL,
        pval_col = NULL
      ))
    }

    cols <- column_names()

    # 简单的模式匹配
    detect_gene <- grep("^gene$|^Gene$|^gene_id$|^GeneID$|^Symbol$|^gene_symbol$|^ensembl", cols,
                      ignore.case = TRUE, value = TRUE)[1]

    detect_fc <- grep("^log2.*fc|^log.*fold|^logFC|^fold.*change", cols,
                     ignore.case = TRUE, value = TRUE)[1]

    detect_pval <- grep("^padj|^p.*adjust|^fdr|^pvalue|^p_val", cols,
                       ignore.case = TRUE, value = TRUE)[1]

    list(
      gene_col = detect_gene,
      fc_col = detect_fc,
      pval_col = detect_pval
    )
  })

  # 3. 更新下拉菜单选项
  observe({
    cols <- column_names()
    req(cols)

    # 获取自动检测的结果
    detected <- auto_detected()

    # 更新基因列选择器
    updateSelectInput(
      session = session,
      inputId = "gene_col",
      choices = c("请选择..." = "", cols),
      selected = if (!is.null(detected$gene_col)) detected$gene_col else ""
    )

    # 更新log2FC列选择器
    updateSelectInput(
      session = session,
      inputId = "fc_col",
      choices = c("请选择..." = "", cols),
      selected = if (!is.null(detected$fc_col)) detected$fc_col else ""
    )

    # 更新p值列选择器
    updateSelectInput(
      session = session,
      inputId = "pval_col",
      choices = c("请选择..." = "", cols),
      selected = if (!is.null(detected$pval_col)) detected$pval_col else ""
    )

    # 显示自动检测结果
    output$auto_detect_info <- renderUI({
      detected <- auto_detected()

      if (!is.null(detected$gene_col) || !is.null(detected$fc_col) || !is.null(detected$pval_col)) {
        div(
          class = "alert alert-info",
          h5("🤖 自动检测结果"),
          p("系统已尝试自动识别列名，请检查是否正确："),
          tags$ul(
            if (!is.null(detected$gene_col)) {
              tags$li(strong("基因ID列: "), detected$gene_col)
            } else {
              tags$li(strong("基因ID列: "), tags$span(class = "text-muted", "未识别"))
            },
            if (!is.null(detected$fc_col)) {
              tags$li(strong("log2FC列: "), detected$fc_col)
            } else {
              tags$li(strong("log2FC列: "), tags$span(class = "text-muted", "未识别"))
            },
            if (!is.null(detected$pval_col)) {
              tags$li(strong("p值列: "), detected$pval_col)
            } else {
              tags$li(strong("p值列: "), tags$span(class = "text-muted", "未识别"))
            }
          ),
          p("⚠️  如果自动识别错误，请在上方手动选择正确的列", class = "small text-muted")
        )
      } else {
        div(
          class = "alert alert-warning",
          h5("⚠️  无法自动识别列名"),
          p("请手动选择各列对应的含义")
        )
      }
    })
  })

  # 4. 验证按钮逻辑
  observeEvent(input$validate_columns, {
    req(input$gene_col, input$fc_col, input$pval_col)

    # 读取部分数据验证
    file_path <- file_reactive()$datapath
    df_sample <- read.csv(file_path, nrows = 10)

    issues <- list()

    # 检查列是否存在
    if (!input$gene_col %in% names(df_sample)) {
      issues <- c(issues, paste("❌ 基因ID列 '", input$gene_col, "' 不存在"))
    } else {
      genes <- df_sample[[input$gene_col]]
      n_na <- sum(is.na(genes))
      if (n_na > 0) {
        issues <- c(issues, paste("⚠️  基因ID列包含 ", n_na, " 个NA值"))
      }
    }

    if (!input$fc_col %in% names(df_sample)) {
      issues <- c(issues, paste("❌ log2FC列 '", input$fc_col, "' 不存在"))
    } else {
      fc <- df_sample[[input$fc_col]]
      if (!is.numeric(fc)) {
        issues <- c(issues, paste("⚠️  log2FC列 '", input$fc_col, "' 不是数值类型"))
      }
    }

    if (!input$pval_col %in% names(df_sample)) {
      issues <- c(issues, paste("❌ p值列 '", input$pval_col, "' 不存在"))
    } else {
      pvals <- df_sample[[input$pval_col]]
      if (!is.numeric(pvals)) {
        issues <- c(issues, paste("⚠️  p值列 '", input$pval_col, "' 不是数值类型"))
      }
    }

    # 显示验证结果
    output$validation_result <- renderUI({
      if (length(issues) == 0) {
        div(
          class = "alert alert-success",
          h4("✅ 验证通过！"),
          p("所有列选择正确，可以开始分析"),
          tags$ul(
            tags$li(strong("基因ID列: "), input$gene_col),
            tags$li(strong("log2FC列: "), input$fc_col),
            tags$li(strong("p值列: "), input$pval_col)
          )
        )
      } else {
        div(
          class = "alert alert-danger",
          h4("❌ 发现问题"),
          tagList(issues)
        )
      }
    })
  })

  # 5. 返回选定的列名（供其他模块使用）
  selected_columns <- reactive({
    list(
      gene_col = input$gene_col,
      fc_col = input$fc_col,
      pval_col = input$pval_col
    )
  })

  return(selected_columns)
}


# ============================================================================
# 函数3: 简化版 - 单文件列选择（用于单列基因富集分析）
# ============================================================================

#' 单文件列选择UI（简化版）
#'
#' @param id 模块ID
#' @param title 标题
#' @return UI元素
#' @export
single_file_column_selector_ui <- function(id,
                                           title = "📋 文件列识别") {
  ns <- NS(id)

  wellPanel(
    style = "background-color: #f8f9fa;",
    h4(title),
    p("系统将自动读取您上传的CSV文件，请确认列名映射：", class = "text-muted"),

    uiOutput(ns("column_mapping_display")),
    br(),
    actionButton(ns("confirm_columns"), "✅ 确认列选择", class = "btn-success")
  )
}


#' 单文件列选择服务器
#'
#' @param input,output,session 标准参数
#' @param file_reactive 文件reactive
#' @return 列名reactive
#' @export
single_file_column_selector_server <- function(input, output, session,
                                               file_reactive) {
  ns <- session$ns

  detected_columns <- reactive({
    req(file_reactive())

    file_path <- file_reactive()$datapath
    cols <- names(read.csv(file_path, nrows = 0))

    # 自动检测
    gene_col <- grep("^gene$|^Gene", cols, ignore.case = TRUE, value = TRUE)[1]
    fc_col <- grep("log2|fold|fc", cols, ignore.case = TRUE, value = TRUE)[1]
    pval_col <- grep("padj|pval|fdr", cols, ignore.case = TRUE, value = TRUE)[1]

    list(
      gene_col = if (is.na(gene_col)) cols[1] else gene_col,
      fc_col = fc_col,
      pval_col = pval_col
    )
  })

  output$column_mapping_display <- renderUI({
    cols <- detected_columns()

    tagList(
      tags$table(
        class = "table table-bordered",
        tags$tr(
          tags$th("用途"),
          tags$th("CSV列名"),
          tags$th("状态")
        ),
        tags$tr(
          tags$td(strong("基因ID")),
          tags$td(code(cols$gene_col)),
          tags$td(tags$span(class = "badge bg-success", "自动识别"))
        ),
        if (!is.null(cols$fc_col) && !is.na(cols$fc_col)) {
          tags$tr(
            tags$td("log2FC"),
            tags$td(code(cols$fc_col)),
            tags$td(tags$span(class = "badge bg-success", "自动识别"))
          )
        },
        if (!is.null(cols$pval_col) && !is.na(cols$pval_col)) {
          tags$tr(
            tags$td("p值"),
            tags$td(code(cols$pval_col)),
            tags$td(tags$span(class = "badge bg-success", "自动识别"))
          )
        }
      )
    )
  })

  return(detected_columns)
}


# ============================================================================
# 使用示例
# ============================================================================

# 示例1: 在KEGG富集模块中使用
# ======================================
# UI部分
# kegg_ui <- function() {
#   tagList(
#     fileInput("kegg_file", "上传DE结果CSV"),
#     br(),
#     column_selector_ui("kegg_col_selector")
#   )
# }
#
# Server部分
# kegg_server <- function(input, output, session) {
#   file_data <- reactive({
#     req(input$kegg_file)
#     input$kegg_file
#   })
#
#   selected_cols <- column_selector_server(
#     "kegg_col_selector",
#     file_reactive = file_data,
#     auto_detect = TRUE
#   )
#
#   # 使用选定的列名
#   observeEvent(input$run_kegg, {
#     cols <- selected_cols()
#
#     df <- read.csv(input$kegg_file$datapath)
#     genes <- df[[cols$gene_col]]
#     fc <- df[[cols$fc_col]]
#     pvals <- df[[cols$pval_col]]
#
#     # 执行KEGG分析...
#   })
# }

# 示例2: 在火山图模块中使用（简化版）
# ======================================
# volcano_ui <- function() {
#   tagList(
#     fileInput("volcano_file", "上传DE结果CSV"),
#     single_file_column_selector_ui("volcano_selector")
#   )
# }
#
# volcano_server <- function(input, output, session) {
#   file_data <- reactive(input$volcano_file)
#
#   cols <- single_file_column_selector_server(
#     "volcano_selector",
#     file_reactive = file_data
#   )
#
#   observeEvent(input$confirm_columns, {
#     df <- read.csv(input$volcano_file$datapath)
#     genes <- df[[cols()$gene_col]]
#     # 使用数据...
#   })
# }


print("✅ 通用列选择模块加载完成！")
print("使用示例: 参考文件末尾的注释")
