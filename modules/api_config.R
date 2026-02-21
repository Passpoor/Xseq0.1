# =====================================================
# API配置模块
# =====================================================

api_config_server <- function(input, output, session, user_session) {

  # =====================================================
  # 智谱AI配置
  # =====================================================

  # 加载已保存的智谱AI密钥
  observe({
    if (user_session$logged_in) {
      zhipu_api_key <- load_zhipu_config()
      updateTextInput(session, "zhipu_api_key_input", value = zhipu_api_key)
    }
  })

  # 保存智谱AI密钥
  observeEvent(input$save_zhipu_key, {
    req(input$zhipu_api_key_input)

    if (nchar(input$zhipu_api_key_input) > 0) {
      save_zhipu_config(input$zhipu_api_key_input)
      showNotification("✅ 智谱AI API密钥已保存", type = "message")

      # 更新全局配置
      ZHIPU_API_KEY <<- input$zhipu_api_key_input
    } else {
      showNotification("请输入有效的API密钥", type = "warning")
    }
  })

  # 显示智谱AI API状态
  output$zhipu_api_status <- renderText({
    api_key <- load_zhipu_config()

    if (nchar(api_key) == 0) {
      "❌ 未配置智谱AI API密钥\n请在上方输入并保存您的智谱AI API密钥"
    } else {
      config_file <- "zhipu_config.RData"
      if (file.exists(config_file)) {
        mtime <- file.info(config_file)$mtime
        paste("✅ 智谱AI API密钥已配置\n",
              "密钥预览:", substr(api_key, 1, 8), "...",
              substr(api_key, nchar(api_key)-7, nchar(api_key)), "\n",
              "最后更新:", format(mtime, "%Y-%m-%d %H:%M:%S"))
      } else {
        "✅ 智谱AI API密钥已配置\n但配置文件未找到，请重新保存"
      }
    }
  })

  # 测试智谱AI API连接
  observeEvent(input$test_zhipu_api, {
    api_key <- load_zhipu_config()

    if (nchar(api_key) == 0) {
      showNotification("❌ 请先配置智谱AI API密钥", type = "warning", duration = 5)
      return()
    }

    # 显示测试中提示
    output$zhipu_api_status <- renderText({
      "🧪 正在测试智谱AI API连接...\n请稍候"
    })

    # 使用isolate避免频繁触发
    result <- isolate({
      tryCatch({
        test_zhipu_api()
      }, error = function(e) {
        list(success = FALSE, message = e$message)
      })
    })

    if (result$success) {
      showNotification(
        paste("✅ 智谱AI API连接成功！\n模型:", result$model, "\n回复:", result$response),
        type = "message",
        duration = 10
      )

      # 更新状态输出
      output$zhipu_api_status <- renderText({
        paste("✅ 智谱AI API连接测试成功！\n",
              "模型:", result$model, "\n",
              "Token使用:", result$tokens_used, "\n",
              "AI回复:", result$response)
      })
    } else {
      showNotification(
        paste("❌ 智谱AI API连接失败\n", result$message),
        type = "error",
        duration = 10
      )

      # 更新状态输出
      output$zhipu_api_status <- renderText({
        paste("❌ API连接失败\n", result$message)
      })
    }
  })

  # =====================================================
  # DeepSeek配置
  # =====================================================

  # 加载已保存的API密钥
  observe({
    if (user_session$logged_in) {
      api_key <- load_api_config()
      updateTextInput(session, "api_key_input", value = api_key)
    }
  })

  # 保存API密钥
  observeEvent(input$save_api_key, {
    req(input$api_key_input)

    if (nchar(input$api_key_input) > 0) {
      save_api_config(input$api_key_input)
      showNotification("API密钥已保存", type = "message")

      # 更新全局配置
      DEEPSEEK_API_KEY <<- input$api_key_input
    } else {
      showNotification("请输入有效的API密钥", type = "warning")
    }
  })

  # 显示API状态
  output$api_status <- renderText({
    api_key <- load_api_config()

    if (nchar(api_key) == 0) {
      "❌ 未配置API密钥\n请在上方输入并保存您的DeepSeek API密钥"
    } else {
      paste("✅ API密钥已配置\n",
            "密钥长度:", nchar(api_key), "字符\n",
            "最后更新:", file.info("api_config.RData")$mtime)
    }
  })

  # 测试API连接
  observeEvent(input$test_api, {
    api_key <- load_api_config()

    if (nchar(api_key) == 0) {
      showNotification("请先配置API密钥", type = "warning")
      return()
    }

    showNotification("正在测试API连接...", type = "message")

    tryCatch({
      # 构建简单的测试请求
      response <- httr::POST(
        url = DEEPSEEK_API_URL,
        httr::add_headers(
          "Authorization" = paste("Bearer", api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = "deepseek-chat",
          messages = list(
            list(role = "user", content = "请回复'连接成功'")
          ),
          max_tokens = 10,
          temperature = 0.1,
          stream = FALSE
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(10)  # 10秒超时
      )

      if (httr::status_code(response) == 200) {
        showNotification("✅ API连接测试成功", type = "message")
      } else {
        showNotification(paste("❌ API连接失败，状态码:", httr::status_code(response)), type = "error")
      }

    }, error = function(e) {
      showNotification(paste("❌ API连接测试失败:", e$message), type = "error")
    })
  })

  # 返回API密钥获取函数
  get_api_key <- reactive({
    load_api_config()
  })

  return(list(
    get_api_key = get_api_key
  ))
}