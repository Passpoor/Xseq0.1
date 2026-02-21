# =====================================================
# 富集分析AI解读模块
# =====================================================

#' 富集分析AI解读服务器模块
#' @param input Shiny输入
#' @param output Shiny输出
#' @param session Shiny会话
#' @param enrich_results 富集分析结果
#' @param deg_results 差异分析结果
ai_enrichment_server <- function(input, output, session,
                                 enrich_results, deg_results) {

  ns <- session$ns

  # ========================================
  # AI解读富集分析结果
  # ========================================
  output$ai_enrichment_interpretation <- renderUI({
    req(input$ai_interpret)

    # 显示加载动画
    div(
      class = "ai-loading",
      style = "text-align: center; padding: 50px; background: #f8f9fa; border-radius: 10px; margin: 20px 0;",
      shiny::includeSpinner(spinner = TRUE, color = "#667eea"),
      h4("🤖 AI正在分析富集结果...", style = "margin-top: 20px; color: #667eea;"),
      p("这通常需要10-30秒，请稍候...", class = "text-muted")
    )
  })

  # 实际AI调用
  observeEvent(input$ai_interpret, {

    output$ai_enrichment_interpretation <- renderUI({

      tryCatch({
        # 收集富集分析数据
        enrichment_data <- collect_enrichment_data(enrich_results, deg_results)

        # 构建提示词
        prompt <- build_enrichment_prompt(enrichment_data)

        # 调用智谱AI
        cat("🤖 调用智谱AI API...\n")
        result <- call_zhipu_api(
          prompt = prompt,
          model = input$enrich_ai_model %||% "glm-4-air",
          temperature = 0.7,
          max_tokens = 2500
        )

        cat(sprintf("✅ AI分析完成！使用了 %d tokens\n", result$total_tokens))

        # 格式化输出
        tagList(
          # 成功提示
          div(
            class = "alert alert-success",
            style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                   color: white; border: none; border-radius: 10px;",
            h4("✅ AI解读完成", style = "color: white; margin-top: 0;"),
            p(sprintf("使用模型: %s | Token使用: %d",
              result$model, result$total_tokens),
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
              actionButton(ns("copy_ai_result"), "📋 复制到剪贴板",
                          class = "btn-info btn-block",
                          icon = shiny::icon("copy"))
            ),
            column(6,
              downloadButton(ns("download_ai_result"), "💾 保存解读",
                            class = "btn-primary btn-block")
            )
          ),

          tags$hr(),

          # 继续提问区域
          h5("💬 继续提问"),
          p("如果您对AI解读有任何疑问，或者想深入了解某个方面，可以继续提问：", class = "text-muted"),
          textInput(ns("followup_question"), "您的问题...",
                   placeholder = "例如：能否详细解释一下NF-κB信号通路的作用机制？"),
          actionButton(ns("ask_followup"), "🚀 提问", class = "btn-success"),
          uiOutput(ns("followup_answer"))
        )

      }, error = function(e) {
        # 错误处理
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
          actionButton(ns("retry_ai"), "🔄 重试", class = "btn-warning")
        )
      })
    })
  })

  # ========================================
  # 追问功能
  # ========================================
  output$followup_answer <- renderUI({
    req(input$ask_followup, input$followup_question)

    tryCatch({
      # 保存之前的分析结果用于上下文
      if (!exists("previous_enrichment_prompt", envir = parent.frame())) {
        previous_prompt <- build_enrichment_prompt(
          collect_enrichment_data(enrich_results, deg_results)
        )
        assign("previous_enrichment_prompt", previous_prompt, envir = parent.frame())
      }

      # 构建追问提示词
      followup_prompt <- sprintf(
        "【之前的富集分析解读】\n以下是我之前分析的数据：\n\n%s\n\n\n【用户追问】\n%s\n\n请结合之前的分析结果，针对用户的追问提供更详细的解释。",
        get("previous_enrichment_prompt", envir = parent.frame()),
        input$followup_question
      )

      # 调用API
      answer <- call_zhipu_simple(followup_prompt, model = "glm-4-air")

      div(
        class = "ai-followup-answer",
        style = "background: #e8f4f8; padding: 20px; border-radius: 10px; margin-top: 15px;
               border-left: 4px solid #007AFF;",
        h6("🤖 AI回答", style = "color: #007AFF; margin-top: 0;"),
        HTML(markdown::renderText(answer))
      )
    }, error = function(e) {
      div(class = "alert alert-warning", paste("❌ 抱歉，", e$message))
    })
  })

  # ========================================
  # 复制到剪贴板
  # ========================================
  observeEvent(input$copy_ai_result, {
    tryCatch({
      # 重新获取AI结果
      enrichment_data <- collect_enrichment_data(enrich_results, deg_results)
      prompt <- build_enrichment_prompt(enrichment_data)
      result_text <- call_zhipu_simple(prompt, model = input$enrich_ai_model)

      # 使用JavaScript复制到剪贴板
      runjs(sprintf(
        "navigator.clipboard.writeText(%s).then(function() {
          Shiny.addCustomMessageHandler('copy_success', function(msg) {
            // 显示成功提示
          });
        });",
        jsonlite::toJSON(result_text, auto_unbox = TRUE)
      ))

      showNotification("✅ 已复制到剪贴板！", type = "message", duration = 3)

    }, error = function(e) {
      showNotification(paste("❌ 复制失败:", e$message), type = "error")
    })
  })

  # ========================================
  # 下载功能
  # ========================================
  output$download_ai_result <- downloadHandler(
    filename = function() {
      paste0("Biofree_AI_富集分析解读_", Sys.Date(), ".md")
    },
    content = function(file) {
      # 获取AI解读结果
      enrichment_data <- collect_enrichment_data(enrich_results, deg_results)
      prompt <- build_enrichment_prompt(enrichment_data)
      result_text <- call_zhipu_simple(prompt, model = input$enrich_ai_model)

      # 添加元数据
      header <- paste0(
        "# Biofree AI 富集分析解读\n",
        "-----\n\n",
        "**生成时间**: ", Sys.time(), "\n",
        "**分析版本**: Biofree v12\n",
        "**AI模型**: 智谱AI GLM-4\n",
        "-----\n\n"
      )

      writeLines(paste0(header, result_text), file)
    },
    contentType = "text/markdown"
  )
}

# ========================================
# 辅助函数
# ========================================

#' 收集富集分析数据
#' @param enrich_results 富集分析结果列表
#' @param deg_results 差异分析结果列表
#' @return 整理后的数据列表
collect_enrichment_data <- function(enrich_results, deg_results) {

  # 检查数据是否存在
  if (is.null(enrich_results) || is.null(deg_results)) {
    stop("❌ 富集分析或差异分析结果不存在")
  }

  # 提取GO BP结果
  go_bp <- tryCatch({
    enrich_results$go_bp_results %>%
      head(15) %>%
      summarize(
        n_terms = n(),
        top_terms = paste(head(Term, 5), collapse = "; ")
      )
  }, error = function(e) {
    list(n_terms = 0, top_terms = "无数据")
  })

  # 提取GO MF结果
  go_mf <- tryCatch({
    enrich_results$go_mf_results %>%
      head(10) %>%
      summarize(
        n_terms = n(),
        top_terms = paste(head(Term, 5), collapse = "; ")
      )
  }, error = function(e) {
    list(n_terms = 0, top_terms = "无数据")
  })

  # 提取GO CC结果
  go_cc <- tryCatch({
    enrich_results$go_cc_results %>%
      head(10) %>%
      summarize(
        n_terms = n(),
        top_terms = paste(head(Term, 5), collapse = "; ")
      )
  }, error = function(e) {
    list(n_terms = 0, top_terms = "无数据")
  })

  # 提取KEGG结果
  kegg <- tryCatch({
    enrich_results$kegg_results %>%
      head(15) %>%
      summarize(
        n_terms = n(),
        top_terms = paste(head(Term, 5), collapse = "; ")
      )
  }, error = function(e) {
    list(n_terms = 0, top_terms = "无数据")
  })

  # 差异基因信息
  deg_info <- tryCatch({
    deg_results$deg_df %>%
      summarize(
        n_total = n(),
        n_up = sum(Status == "Up", na.rm = TRUE),
        n_down = sum(Status == "Down", na.rm = TRUE),
        top_up = paste(head(SYMBOL[Status == "Up"], 20), collapse = ", "),
        top_down = paste(head(SYMBOL[Status == "Down"], 20), collapse = ", ")
      )
  }, error = function(e) {
    list(n_total = 0, n_up = 0, n_down = 0, top_up = "无数据", top_down = "无数据")
  })

  return(list(
    go_bp = go_bp,
    go_mf = go_mf,
    go_cc = go_cc,
    kegg = kegg,
    deg = deg_info
  ))
}

#' 构建富集分析提示词
#' @param data 收集的数据列表
#' @return 完整的提示词字符串
build_enrichment_prompt <- function(data) {

  prompt <- sprintf(
    '请作为一位资深生物信息学专家，深入解读以下功能富集分析结果：

## 实验背景
- 差异基因总数：%d 个
- 上调基因：%d 个
- 下调基因：%d 个

**主要上调基因**：%s

**主要下调基因**：%s

---

## GO Biological Process 富集分析
检测到 %d 个显著富集的生物学过程
**Top 5**: %s

## GO Molecular Function 富集分析
检测到 %d 个显著富集的分子功能
**Top 5**: %s

## GO Cellular Component 富集分析
检测到 %d 个显著富集的细胞组分
**Top 5**: %s

## KEGG 通路富集分析
检测到 %d 个显著富集的KEGG通路
**Top 5**: %s

---

请提供以下方面的专业解读（800-1200字）：

### 1. 核心生物学发现
- 哪些生物学过程和通路最为显著？
- 这些结果反映了细胞或组织的什么状态？
- 上调/下调基因的功能倾向

### 2. 通路网络分析
- GO和KEGG结果之间的关联性
- 上游-下游信号通路关系
- 可能的级联反应

### 3. 疾病/表型关联
- 与哪些疾病、生理过程或表型相关？
- 潜在的病理机制或生理意义

### 4. 研究价值与启示
- 可能的药物靶点或生物标志物
- 对相关领域研究的启示
- 建议的后续实验验证方向

### 5. 数据质量评估
- 富集分析结果的可靠性
- 是否存在异常或需要关注的点

**要求**：
- 使用专业但易懂的学术语言
- 基于数据事实，避免过度推测
- 提供有见地的生物学解释
- 适当引用相关生物学背景知识
- 条理清晰，层次分明
',
    data$deg$n_total,
    data$deg$n_up,
    data$deg$n_down,
    data$deg$top_up,
    data$deg$top_down,
    data$go_bp$n_terms,
    data$go_bp$top_terms,
    data$go_mf$n_terms,
    data$go_mf$top_terms,
    data$go_cc$n_terms,
    data$go_cc$top_terms,
    data$kegg$n_terms,
    data$kegg$top_terms
  )

  return(prompt)
}

# ========================================
# KEGG 专用 AI Prompt 构建函数
# ========================================

#' 构建KEGG富集分析AI提示词
#' @param enrich_results 富集分析结果列表
#' @param deg_results 差异分析结果列表
#' @return KEGG专用提示词字符串
build_kegg_ai_prompt <- function(enrich_results, deg_results) {

  # 提取KEGG结果
  kegg_data <- tryCatch({
    enrich_results$kegg_results
  }, error = function(e) {
    NULL
  })

  # 提取差异基因信息
  deg_info <- tryCatch({
    # deg_results 是一个 reactive 函数，需要调用它
    deg_data <- deg_results()

    deg_data$deg_df %>%
      summarize(
        n_total = n(),
        n_up = sum(Status == "Up", na.rm = TRUE),
        n_down = sum(Status == "Down", na.rm = TRUE),
        top_up = paste(head(SYMBOL[Status == "Up"], 20), collapse = ", "),
        top_down = paste(head(SYMBOL[Status == "Down"], 20), collapse = ", ")
      )
  }, error = function(e) {
    list(n_total = 0, n_up = 0, n_down = 0, top_up = "无数据", top_down = "无数据")
  })

  # 提取KEGG富集信息
  kegg_info <- tryCatch({
    if (!is.null(kegg_data) && nrow(kegg_data) > 0) {
      list(
        n_terms = nrow(kegg_data),
        top_terms = paste(head(kegg_data$Description, 10), collapse = "; "),
        top_paths = paste(head(kegg_data$ID, 5), collapse = ", ")
      )
    } else {
      list(n_terms = 0, top_terms = "无数据", top_paths = "无数据")
    }
  }, error = function(e) {
    list(n_terms = 0, top_terms = "无数据", top_paths = "无数据")
  })

  prompt <- sprintf(
    '请作为一位资深生物信息学专家，深入解读以下KEGG通路富集分析结果：

## 研究主题
%s

%s

## 实验背景
- 差异基因总数：%d 个
- 上调基因：%d 个
- 下调基因：%d 个

**主要上调基因**：%s

**主要下调基因**：%s

---

## KEGG 通路富集分析
检测到 %d 个显著富集的KEGG通路

**Top 10 通路**：%s

**KEGG通路ID**：%s

---

请提供以下方面的专业解读（800-1200字）：

### 1. 核心通路发现
- 哪些信号通路或代谢途径最为显著？
- 这些通路涉及的生物学过程
- 上下游级联关系

### 2. 信号网络分析
- 通路之间的交叉对话（crosstalk）
- 可能的主调控通路
- 级联激活/抑制机制

### 3. 疾病/表型关联
- 与哪些疾病或生理过程相关？
- 潜在的病理机制
- 治疗靶点启示

### 4. 药物干预建议
- 已知的药物靶点
- 潜在的干预策略
- 药物研发方向

### 5. 数据质量与局限性
- 富集结果的可靠性
- 需要验证的发现
- 建议的后续实验

**要求**：
- 使用专业但易懂的学术语言
- 基于KEGG通路数据库的标准命名
- 提供有见地的生物学解释
- 适当引用相关研究背景
- 条理清晰，层次分明
',
    if (!is.null(enrich_results$research_topic) && enrich_results$research_topic != "") {
      sprintf("**用户研究主题**：%s", enrich_results$research_topic)
    } else {
      "*（用户未提供特定研究主题，将进行通用分析）*"
    },
    if (!is.null(enrich_results$research_topic) && enrich_results$research_topic != "") {
      sprintf("**请注意**：请特别关注该研究主题相关的通路和机制，提供针对性的解读。")
    } else {
      ""
    },
    deg_info$n_total,
    deg_info$n_up,
    deg_info$n_down,
    deg_info$top_up,
    deg_info$top_down,
    kegg_info$n_terms,
    kegg_info$top_terms,
    kegg_info$top_paths
  )

  return(prompt)
}

# ========================================
# GO 专用 AI Prompt 构建函数
# ========================================

#' 构建GO富集分析AI提示词
#' @param enrich_results 富集分析结果列表
#' @param deg_results 差异分析结果列表
#' @return GO专用提示词字符串
build_go_ai_prompt <- function(enrich_results, deg_results) {

  # 提取GO结果
  go_bp <- tryCatch({
    enrich_results$go_bp_results
  }, error = function(e) {
    NULL
  })

  go_mf <- tryCatch({
    enrich_results$go_mf_results
  }, error = function(e) {
    NULL
  })

  go_cc <- tryCatch({
    enrich_results$go_cc_results
  }, error = function(e) {
    NULL
  })

  # 提取差异基因信息
  deg_info <- tryCatch({
    # deg_results 是一个 reactive 函数，需要调用它
    deg_data <- deg_results()

    deg_data$deg_df %>%
      summarize(
        n_total = n(),
        n_up = sum(Status == "Up", na.rm = TRUE),
        n_down = sum(Status == "Down", na.rm = TRUE),
        top_up = paste(head(SYMBOL[Status == "Up"], 20), collapse = ", "),
        top_down = paste(head(SYMBOL[Status == "Down"], 20), collapse = ", ")
      )
  }, error = function(e) {
    list(n_total = 0, n_up = 0, n_down = 0, top_up = "无数据", top_down = "无数据")
  })

  # 提取GO BP信息
  go_bp_info <- tryCatch({
    if (!is.null(go_bp) && nrow(go_bp) > 0) {
      list(
        n_terms = nrow(go_bp),
        top_terms = paste(head(go_bp$Description, 10), collapse = "; ")
      )
    } else {
      list(n_terms = 0, top_terms = "无数据")
    }
  }, error = function(e) {
    list(n_terms = 0, top_terms = "无数据")
  })

  # 提取GO MF信息
  go_mf_info <- tryCatch({
    if (!is.null(go_mf) && nrow(go_mf) > 0) {
      list(
        n_terms = nrow(go_mf),
        top_terms = paste(head(go_mf$Description, 5), collapse = "; ")
      )
    } else {
      list(n_terms = 0, top_terms = "无数据")
    }
  }, error = function(e) {
    list(n_terms = 0, top_terms = "无数据")
  })

  # 提取GO CC信息
  go_cc_info <- tryCatch({
    if (!is.null(go_cc) && nrow(go_cc) > 0) {
      list(
        n_terms = nrow(go_cc),
        top_terms = paste(head(go_cc$Description, 5), collapse = "; ")
      )
    } else {
      list(n_terms = 0, top_terms = "无数据")
    }
  }, error = function(e) {
    list(n_terms = 0, top_terms = "无数据")
  })

  prompt <- sprintf(
    '请作为一位资深生物信息学专家，深入解读以下Gene Ontology (GO)富集分析结果：

## 研究主题
%s

%s

## 实验背景
- 差异基因总数：%d 个
- 上调基因：%d 个
- 下调基因：%d 个

**主要上调基因**：%s

**主要下调基因**：%s

---

## GO Biological Process (生物过程)
检测到 %d 个显著富集的生物学过程

**Top 10**：%s

## GO Molecular Function (分子功能)
检测到 %d 个显著富集的分子功能

**Top 5**：%s

## GO Cellular Component (细胞组分)
检测到 %d 个显著富集的细胞组分

**Top 5**：%s

---

请提供以下方面的专业解读（800-1200字）：

### 1. 核心生物学过程
- 哪些生物学过程最为显著？
- 这些过程涉及的细胞功能
- 生理/病理意义

### 2. 分子功能分析
- 主要的分子功能类别
- 酶活性、结合功能等
- 功能级联关系

### 3. 细胞定位与结构
- 关键的细胞组分
- 亚细胞定位特征
- 细器功能变化

### 4. GO三大类别的整合
- BP、MF、CC之间的关联
- 功能-定位-过程的统一性
- 生物学过程的完整性

### 5. 研究价值与建议
- 潜在的生物标志物
- 功能验证实验建议
- 与KEGG通路的互补性

**要求**：
- 使用专业但易懂的学术语言
- 基于GO标准术语定义
- 提供有见地的功能解释
- 适当引用相关生物学背景
- 条理清晰，层次分明
',
    if (!is.null(enrich_results$research_topic) && enrich_results$research_topic != "") {
      sprintf("**用户研究主题**：%s", enrich_results$research_topic)
    } else {
      "*（用户未提供特定研究主题，将进行通用分析）*"
    },
    if (!is.null(enrich_results$research_topic) && enrich_results$research_topic != "") {
      sprintf("**请注意**：请特别关注该研究主题相关的生物学功能和过程，提供针对性的解读。")
    } else {
      ""
    },
    deg_info$n_total,
    deg_info$n_up,
    deg_info$n_down,
    deg_info$top_up,
    deg_info$top_down,
    go_bp_info$n_terms,
    go_bp_info$top_terms,
    go_mf_info$n_terms,
    go_mf_info$top_terms,
    go_cc_info$n_terms,
    go_cc_info$top_terms
  )

  return(prompt)
}
