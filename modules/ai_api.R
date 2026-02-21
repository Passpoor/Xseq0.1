# =====================================================
# 智谱AI API调用模块
# =====================================================

#' 调用智谱AI API
#' @param prompt 提示词
#' @param model 模型名称（默认glm-4-air）
#' @param temperature 温度参数（0-1，默认0.7）
#' @param max_tokens 最大生成长度
#' @return API响应列表（包含text、token使用情况等）
call_zhipu_api <- function(prompt,
                           model = "glm-4-air",
                           temperature = 0.7,
                           max_tokens = 2000) {

  # 从配置加载API密钥
  api_key <- load_zhipu_config()

  if (api_key == "") {
    stop("❌ 未配置智谱AI API密钥！请在'账户'->'智谱AI配置'中设置。")
  }

  # 构建请求
  request_body <- list(
    model = model,
    messages = list(
      list(
        role = "system",
        content = "你是一位资深的生物信息学专家，精通转录组学、蛋白质组学和代谢组学数据分析。你擅长用专业但易懂的语言解读复杂的组学数据，为科研人员提供有价值的生物学见解。"
      ),
      list(
        role = "user",
        content = prompt
      )
    ),
    temperature = temperature,
    max_tokens = max_tokens,
    top_p = 0.9,
    stream = FALSE
  )

  # 发送请求
  tryCatch({
    response <- httr::POST(
      ZHIPU_API_URL,
      httr::add_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type" = "application/json"
      ),
      body = jsonlite::toJSON(request_body, auto_unbox = TRUE),
      httr::timeout(30)
    )

    # 检查响应
    if (httr::http_error(response)) {
      error_content <- httr::content(response, "text", encoding = "UTF-8")
      stop(paste("❌ 智谱AI API调用失败:", httr::status_code(response), "\n", error_content))
    }

    # 解析响应
    content <- httr::content(response)
    result <- content$choices[[1]]$message$content

    # 返回结果和token使用情况
    list(
      text = result,
      prompt_tokens = content$usage$prompt_tokens,
      completion_tokens = content$usage$completion_tokens,
      total_tokens = content$usage$total_tokens,
      model = model
    )

  }, error = function(e) {
    stop(paste("❌ 智谱AI API调用异常:", e$message))
  })
}

#' 简化版API调用（只返回文本）
#' @param prompt 提示词
#' @param model 模型名称
#' @return AI回复文本
call_zhipu_simple <- function(prompt, model = "glm-4-air") {
  result <- call_zhipu_api(prompt, model = model)
  return(result$text)
}

#' 测试智谱AI API连接
#' @return 测试结果列表
test_zhipu_api <- function() {

  tryCatch({
    cat("🧪 正在测试智谱AI API连接...\n")

    result <- call_zhipu_api(
      "你好，请用一句话介绍智谱AI。",
      model = "glm-4-flash",
      max_tokens = 100
    )

    list(
      success = TRUE,
      message = "✅ API连接成功！",
      model = result$model,
      response = result$text,
      tokens_used = result$total_tokens
    )

  }, error = function(e) {
    list(
      success = FALSE,
      message = paste("❌ API连接失败:", e$message)
    )
  })
}
