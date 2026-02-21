# ============================================================================
# 通用列选择模块 - 快速集成示例
# ============================================================================
# 这个文件展示如何在现有模块中集成列选择功能
# ============================================================================

# ----------------------------------------------------------------------------
# 示例1: 改造现有的KEGG模块
# ----------------------------------------------------------------------------

# === 改造前（硬编码） ===
#
# kegg_enrichment_server_old <- function(input, output, session, deg_results) {
#   # 硬编码列名
#   observeEvent(input$run_kegg, {
#     df <- deg_results()
#
#     # ❌ 硬编码：假设列名是固定的
#     genes <- df$gene
#     log2fc <- df$log2FoldChange
#     pvals <- df$padj
#
#     # 如果用户的CSV列名不同，这里会报错！
#   })
# }

# === 改造后（使用列选择模块） ===

# 在模块开头加载列选择模块
source("scripts/column_selector_module.R")

kegg_enrichment_server_new <- function(input, output, session, deg_results) {

  # 1. 添加文件上传reactive（如果没有的话）
  de_file_reactive <- reactive({
    input$de_file  # 假设UI中有fileInput("de_file", ...)
  })

  # 2. 初始化列选择模块
  selected_cols <- column_selector_server(
    id = "col_selector",
    file_reactive = de_file_reactive,
    auto_detect = TRUE  # 启用自动检测
  )

  # 3. 在分析时使用选定的列名
  observeEvent(input$run_kegg, {
    req(selected_cols()$gene_col)  # 确保已选择列

    # 读取数据
    df <- read.csv(de_file_reactive()$datapath)

    # ✅ 使用用户选择的列名（而不是硬编码）
    genes <- df[[selected_cols()$gene_col]]
    log2fc <- df[[selected_cols()$fc_col]]
    pvals <- df[[selected_cols()$pval_col]]

    # 应用阈值
    fc_threshold <- input$fc_threshold %or% 1
    pval_threshold <- input$pval_threshold %or% 0.05

    target_genes <- genes[
      !is.na(log2fc) &
      !is.na(pvals) &
      log2fc > fc_threshold &
      pvals < pval_threshold
    ]

    # 自动提取Universe
    universe <- genes[!is.na(genes)]

    # 执行KEGG分析
    result <- enrichKEGG(
      gene = target_genes,
      universe = universe,
      organism = "mmu",
      pvalueCutoff = 0.05
    )

    # 显示结果...
  })

  # 返回选定的列名（供其他模块使用）
  return(selected_cols)
}


# ----------------------------------------------------------------------------
# 示例2: 改造火山图模块（使用简化版）
# ----------------------------------------------------------------------------

# === 改造前 ===
#
# volcano_server_old <- function(input, output, session) {
#   output$volcano_plot <- renderPlot({
#     req(input$de_file)
#
#     df <- read.csv(input$de_file$datapath)
#
#     # ❌ 硬编码列名
#     ggplot(df, aes(x = log2FoldChange, y = -log10(padj))) +
#       geom_point()
#   })
# }

# === 改造后 ===

volcano_server_new <- function(input, output, session) {

  de_file_reactive <- reactive(input$de_file)

  # 使用简化版列选择器
  detected_cols <- single_file_column_selector_server(
    id = "col_selector",
    file_reactive = de_file_reactive
  )

  output$volcano_plot <- renderPlot({
    req(input$confirm_columns)

    # 读取数据
    df <- read.csv(de_file_reactive()$datapath)

    # ✅ 使用检测到的列名
    plot_data <- data.frame(
      gene = df[[detected_cols()$gene_col]],
      log2fc = df[[detected_cols()$fc_col]],
      neg_log10_pval = -log10(df[[detected_cols()$pval_col]])
    )

    # 绘制火山图
    ggplot(plot_data, aes(x = log2fc, y = neg_log10_pval)) +
      geom_point(aes(color = log2fc > 1 | neg_log10_pval > -log10(0.05)),
                 alpha = 0.6, size = 1.5) +
      scale_color_manual(values = c("TRUE" = "red", "FALSE" = "grey")) +
      geom_vline(xintercept = c(-1, 1), linetype = "dashed", color = "blue") +
      geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "blue") +
      labs(x = "log2 Fold Change",
           y = "-log10(p-value)",
           title = "火山图",
           color = "显著") +
      theme_minimal() +
      theme(legend.position = "top")
  })
}


# ----------------------------------------------------------------------------
# 示例3: 最小集成（只需要3行代码）
# ----------------------------------------------------------------------------

minimal_integration_example <- function(input, output, session) {

  # 第1行：定义文件reactive
  file_data <- reactive(input$file)

  # 第2行：调用列选择模块
  cols <- column_selector_server("my_id", file_data, auto_detect = TRUE)

  # 第3行：使用选定的列名
  observeEvent(input$run_analysis, {
    df <- read.csv(file_data()$datapath)
    my_genes <- df[[cols()$gene_col]]  # 完成！
  })
}


# ----------------------------------------------------------------------------
# 示例4: 在模块化Shiny应用中使用
# ----------------------------------------------------------------------------

# 在app.R中的集成示例

library(shiny)

# 加载列选择模块
source("scripts/column_selector_module.R")

# UI部分
ui <- fluidPage(
  titlePanel("Biofree - 增强版"),

  sidebarLayout(
    sidebarPanel(
      # 文件上传
      fileInput("de_file", "上传DE结果（CSV）"),

      hr(),

      # 列选择模块（完整版）
      column_selector_ui(
        id = "col_selector",
        title = "📋 设置列名",
        subtitle = "请选择CSV中各列的含义"
      ),

      hr(),

      # 分析参数
      sliderInput("fc_threshold", "log2FC阈值", -5, 5, value = 1),
      numericInput("pval_threshold", "p值阈值", value = 0.05),

      # 运行按钮
      actionButton("run_kegg", "🚀 运行KEGG分析", class = "btn-primary btn-lg")
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("KEGG结果",
                 DT::dataTableOutput("kegg_table")
        ),
        tabPanel("富集图",
                 plotOutput("enrichment_plot")
        )
      )
    )
  )
)

# Server部分
server <- function(input, output, session) {

  # 文件reactive
  de_file <- reactive({
    input$de_file
  })

  # 列选择模块
  selected_cols <- column_selector_server(
    id = "col_selector",
    file_reactive = de_file,
    auto_detect = TRUE
  )

  # KEGG分析
  kegg_results <- eventReactive(input$run_kegg, {
    req(de_file, selected_cols()$gene_col)

    # 显示进度
    withProgress(message = "正在读取数据...", value = 0, {

      # 读取数据
      df <- read.csv(de_file()$datapath)

      incProgress(0.3, detail = "提取基因...")

      # 使用选定的列名
      genes <- df[[selected_cols()$gene_col]]
      log2fc <- df[[selected_cols()$fc_col]]
      pvals <- df[[selected_cols()$pval_col]]

      incProgress(0.6, detail = "执行KEGG分析...")

      # 筛选基因
      target_genes <- genes[
        !is.na(log2fc) &
        !is.na(pvals) &
        log2fc > input$fc_threshold &
        pvals < input$pval_threshold
      ]

      # 自动提取Universe
      universe <- genes[!is.na(genes)]

      # KEGG分析
      result <- enrichKEGG(
        gene = target_genes,
        universe = universe,
        organism = "mmu",
        pvalueCutoff = 0.05,
        qvalueCutoff = 0.2
      )

      incProgress(1, detail = "完成！")

      return(result)
    })
  })

  # 显示结果表格
  output$kegg_table <- DT::renderDataTable({
    req(kegg_results())
    DT::datatable(
      as.data.frame(kegg_results()),
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        order = list(list(5, 'asc'))  # 按p.adjust排序
      ),
      filter = 'top'
    )
  })

  # 显示富集图
  output$enrichment_plot <- renderPlot({
    req(kegg_results())

    library(enrichplot)

    dotplot(kegg_results(), showCategory = 20) +
      ggtitle("KEGG富集分析") +
      theme_bw()
  })
}

# 运行应用
shinyApp(ui, server)


# ----------------------------------------------------------------------------
# 示例5: 测试不同格式的CSV
# ----------------------------------------------------------------------------

# 测试脚本
test_column_selector <- function() {

  # 创建测试数据（不同列名格式）
  test_formats <- list(
    DESeq2 = data.frame(
      gene = paste0("Gene", 1:100),
      baseMean = rnorm(100),
      log2FoldChange = rnorm(100),
      lfcSE = rnorm(100),
      stat = rnorm(100),
      pvalue = runif(100),
      padj = runif(100)
    ),

    edgeR = data.frame(
      Gene = paste0("Gene", 1:100),
      logFC = rnorm(100),
      logCPM = rnorm(100),
      Likelihood = rnorm(100),
      PValue = runif(100),
      FDR = runif(100)
    ),

    custom = data.frame(
      GeneSymbol = paste0("Gene", 1:100),
      Log2FC = rnorm(100),
      P_value = runif(100),
      Adjusted_P = runif(100)
    )
  )

  # 保存测试文件
  for (format_name in names(test_formats)) {
    filename <- paste0("test_", format_name, ".csv")
    write.csv(test_formats[[format_name]], filename, row.names = FALSE)
    message("✅ 创建测试文件: ", filename)
    message("   列名: ", paste(colnames(test_formats[[format_name]]), collapse = ", "))
  }

  message("\n💡 现在可以在Shiny应用中测试这些文件了！")
}

# 运行测试
# test_column_selector()


# ============================================================================
# 总结：集成只需3步
# ============================================================================

# Step 1: 加载模块
# source("scripts/column_selector_module.R")

# Step 2: 在UI中添加列选择UI
# column_selector_ui("col_selector")

# Step 3: 在Server中调用列选择模块
# selected_cols <- column_selector_server("col_selector", file_reactive, TRUE)

# 完成！现在用户可以上传任意格式的CSV了！

print("✅ 快速集成示例加载完成！")
print("📖 查看 COLUMN_SELECTOR_USAGE_GUIDE.md 获取详细说明")
