# =====================================================
# AI provider updates
# Latest OpenAI-compatible endpoints and model lists for YuanSeq
# =====================================================

# This file is sourced after modules/ai_interpretation.R.
# It overrides provider metadata and call_ai_api() without modifying the long core module.

api_providers <- list(
  openai = list(
    name = "OpenAI",
    endpoint = "https://api.openai.com/v1/chat/completions",
    models = c("gpt-4o", "gpt-4o-mini", "gpt-4.1", "gpt-4.1-mini", "gpt-4-turbo", "gpt-4"),
    default_model = "gpt-4o"
  ),
  zhipu = list(
    name = "Zhipu AI / GLM",
    endpoint = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
    models = c(
      "glm-5.1",
      "glm-5",
      "glm-5-turbo",
      "glm-4.7",
      "glm-4.7-flashx",
      "glm-4.7-flash",
      "glm-4.6",
      "glm-4.5-air",
      "glm-4.5-airx",
      "glm-4-long",
      "glm-4-flashx-250414",
      "glm-4-flash-250414"
    ),
    default_model = "glm-5.1"
  ),
  zhipu_coding = list(
    name = "Zhipu AI / GLM Coding Endpoint",
    endpoint = "https://open.bigmodel.cn/api/coding/paas/v4/chat/completions",
    models = c(
      "glm-5.1",
      "glm-5",
      "glm-5-turbo",
      "glm-4.7",
      "glm-4.6"
    ),
    default_model = "glm-5.1"
  ),
  deepseek = list(
    name = "DeepSeek",
    endpoint = "https://api.deepseek.com/chat/completions",
    models = c(
      "deepseek-v4-flash",
      "deepseek-v4-pro",
      "deepseek-chat",
      "deepseek-reasoner"
    ),
    default_model = "deepseek-v4-flash"
  ),
  local = list(
    name = "Local OpenAI-compatible Model",
    endpoint = "http://localhost:8000/v1/chat/completions",
    models = c("custom"),
    default_model = "custom"
  ),
  custom = list(
    name = "Custom OpenAI-compatible API",
    endpoint = "",
    models = c("custom"),
    default_model = "custom"
  )
)

#' Call an OpenAI-compatible AI API
#' This override supports api_endpoint and custom_endpoint, updated GLM/DeepSeek endpoints,
#' and optional DeepSeek thinking parameters.
call_ai_api <- function(prompt, config) {

  if (is.null(config$api_key) || config$api_key == "") {
    return(list(
      success = FALSE,
      error = "API Key 未配置，请先设置 API Key"
    ))
  }

  provider <- config$provider %||% "deepseek"
  provider_config <- api_providers[[provider]]

  if (is.null(provider_config)) {
    return(list(
      success = FALSE,
      error = paste("未知的 API 提供商:", provider)
    ))
  }

  endpoint <- config$api_endpoint %||% config$custom_endpoint
  if (is.null(endpoint) || endpoint == "") {
    endpoint <- provider_config$endpoint
  }

  model <- config$model
  if (is.null(model) || model == "") {
    model <- provider_config$default_model
  }

  tryCatch({
    request_body <- list(
      model = model,
      messages = list(
        list(role = "system", content = "你是一位专业的生物信息学分析师，擅长RNA-seq数据分析和生物学解读。"),
        list(role = "user", content = prompt)
      ),
      max_tokens = config$max_tokens %||% 4000,
      temperature = config$temperature %||% 0.7
    )

    # DeepSeek V4 supports optional thinking mode and reasoning effort.
    # Leave them disabled unless explicitly set in the config to keep backward compatibility.
    if (provider == "deepseek") {
      if (!is.null(config$reasoning_effort) && config$reasoning_effort != "") {
        request_body$reasoning_effort <- config$reasoning_effort
      }
      if (isTRUE(config$thinking_enabled)) {
        request_body$thinking <- list(type = "enabled")
      }
    }

    response <- httr::POST(
      url = endpoint,
      httr::add_headers(
        `Content-Type` = "application/json",
        `Authorization` = paste("Bearer", config$api_key)
      ),
      body = jsonlite::toJSON(request_body, auto_unbox = TRUE),
      encode = "raw",
      httr::timeout(120)
    )

    if (httr::http_error(response)) {
      error_content <- httr::content(response, "text", encoding = "UTF-8")
      return(list(
        success = FALSE,
        error = paste("API 请求失败:", httr::status_code(response), error_content)
      ))
    }

    result <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"), simplifyVector = FALSE)

    content_text <- NULL
    tokens_used <- NA

    if (!is.null(result$choices) && length(result$choices) > 0) {
      choice <- result$choices[[1]]
      if (!is.null(choice$message)) {
        content_text <- choice$message$content
      } else if (!is.null(choice$text)) {
        content_text <- choice$text
      }
      if (!is.null(result$usage)) {
        tokens_used <- result$usage$total_tokens %||% NA
      }
    } else if (!is.null(result$data)) {
      if (!is.null(result$data$choices) && length(result$data$choices) > 0) {
        choice <- result$data$choices[[1]]
        if (!is.null(choice$message)) {
          content_text <- choice$message$content
        } else if (!is.null(choice$content)) {
          content_text <- choice$content
        }
      }
      if (!is.null(result$data$usage)) {
        tokens_used <- result$data$usage$total_tokens %||% NA
      }
    } else if (!is.null(result$error)) {
      error_msg <- if (is.list(result$error)) {
        result$error$message %||% toString(result$error)
      } else {
        toString(result$error)
      }
      return(list(
        success = FALSE,
        error = paste("API 返回错误:", error_msg)
      ))
    }

    if (is.null(content_text) || content_text == "") {
      return(list(
        success = FALSE,
        error = paste("无法解析 API 响应结构。响应预览:", substr(toString(result), 1, 500))
      ))
    }

    return(list(
      success = TRUE,
      content = content_text,
      tokens_used = tokens_used,
      model = model
    ))

  }, error = function(e) {
    return(list(
      success = FALSE,
      error = paste("API 调用出错:", e$message)
    ))
  })
}
