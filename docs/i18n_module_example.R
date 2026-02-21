# =====================================================
# 模块国际化示例
# 展示如何在现有模块中添加多语言支持
# =====================================================

# 假设这是一个现有的分析模块
my_analysis_module_ui <- function(id) {
  ns <- NS(id)

  tagList(
    h4("分析参数"),  # 原始硬编码文本

    # ... 其他UI元素
  )
}

my_analysis_module_server <- function(input, output, session, translator_func) {
  # 使用翻译函数
  output$title <- renderUI({
    t <- translator_func()
    h4(t("my_analysis_title"))
  })
}

# =====================================================
# 修改后的版本 - 支持国际化
# =====================================================

# 1. UI部分 - 使用uiOutput动态渲染
my_analysis_module_ui_i18n <- function(id) {
  ns <- NS(id)

  tagList(
    # 标题使用动态渲染
    uiOutput(ns("module_title")),

    # 参数设置
    uiOutput(ns("params_section")),

    # 按钮
    actionButton(ns("run"), "run_analysis")  # 键名,会自动翻译
  )
}

# 2. Server部分 - 接收translator函数
my_analysis_module_server_i18n <- function(input, output, session, translator_func) {

  # 获取翻译函数
  t <- translator_func()

  # 渲染标题
  output$module_title <- renderUI({
    h4(t("my_analysis_title"))
  })

  # 渲染参数区域
  output$params_section <- renderUI({
    tagList(
      h5(t("analysis_params")),
      numericInput("param1", t("param1_label"), value = 0.05),
      selectInput("param2", t("param2_label"),
                  choices = c("Option A" = "a", "Option B" = "b"))
    )
  })

  # 按钮文本动态更新
  observe({
    # 注意：actionButton的标签在创建时固定,需要特殊处理
    # 可以使用JavaScript或重新渲染
  })
}

# =====================================================
# 在主应用中调用
# =====================================================

# 在 app.R 的 server 函数中:
server <- function(input, output, session) {

  # 创建翻译函数
  translator <- reactive({
    make_translator(current_language)
  })

  # 传递给模块
  my_analysis_module_server_i18n("analysis", translator = translator)
}

# =====================================================
# 简化方法 - 使用响应式文本
# =====================================================

# 对于简单的文本,可以直接使用 reactiveText
output$status_message <- renderText({
  t <- translator()()
  switch(input$status,
         "ready" = t("status_ready"),
         "running" = t("status_running"),
         "complete" = t("status_complete"),
         t("status_unknown"))
})

# =====================================================
# 表格列名翻译
# =====================================================

# 在显示数据表格时翻译列名
output$result_table <- DT::renderDataTable({
  t <- translator()()

  df <- get_results()

  # 重命名列
  names(df) <- c(
    t("col_gene"),
    t("col_pvalue"),
    t("col_foldchange"),
    t("col_pathway")
  )

  DT::datatable(df)
})

# =====================================================
# 图表标题和标签翻译
# =====================================================

output$plot <- renderPlot({
  t <- translator()()

  p <- ggplot(data, aes(x, y)) +
    geom_point() +
    labs(
      title = t("plot_title"),
      x = t("axis_x"),
      y = t("axis_y"),
      subtitle = t("plot_subtitle")
    )

  p
})

# =====================================================
# 通知消息翻译
# =====================================================

observeEvent(input$submit, {
  t <- translator()()

  tryCatch({
    # 执行分析
    run_analysis()

    # 成功消息
    showNotification(
      t("msg_success"),
      type = "message",
      duration = 3
    )

  }, error = function(e) {
    # 错误消息
    showNotification(
      paste(t("msg_error"), e$message),
      type = "error",
      duration = 5
    )
  })
})

# =====================================================
# 验证消息翻译
# =====================================================

# 使用 validate() 翻译验证消息
output$results <- renderUI({
  t <- translator()()

  validate(
    need(input$file, t("error_no_file")),
    need(input$param > 0, t("error_invalid_param"))
  )

  # 显示结果
})
