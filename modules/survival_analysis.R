# =====================================================
# 生存分析模块 (Kaplan-Meier + Log-rank)
# =====================================================
# 支持 TCGA 临床表：vital_status, days_to_death, days_to_last_followup
# 支持按基因/分组列分层 (如 KRAS mut vs wild)
# =====================================================

if (!requireNamespace("survival", quietly = TRUE)) {
  stop("请先安装 survival 包: install.packages('survival')")
}
library(survival)

# 从 TCGA 表构建生存时间与事件
build_survival_tcga <- function(df, time_death = "days_to_death", time_follow = "days_to_last_followup", status_col = "vital_status", status_dead = "DECEASED") {
  if (!all(c(time_death, time_follow, status_col) %in% colnames(df)))
    return(NULL)
  time_d <- as.numeric(as.character(df[[time_death]]))
  time_f <- as.numeric(as.character(df[[time_follow]]))
  dead   <- toupper(trimws(as.character(df[[status_col]]))) %in% toupper(status_dead)
  time_d[is.na(time_d)] <- 0
  time_f[is.na(time_f)] <- 0
  time   <- ifelse(dead, time_d, time_f)
  event  <- as.integer(dead)
  list(time = time, event = event)
}

survival_analysis_ui <- function() {
  tagList(
    fluidRow(
      column(12,
        div(class = "info-box",
            style = "background: linear-gradient(135deg, #0d47a1 0%, #1565c0 100%); color: white; padding: 25px; border-radius: 15px; margin-bottom: 25px;",
            h4("📈 生存分析 (Kaplan-Meier)", style = "margin-top: 0; color: white;"),
            p("上传临床/生存表（如 TCGA），指定时间与终点列，可选按基因或分组列分层，绘制 KM 曲线并计算 Log-rank P 值。",
              style = "color: rgba(255,255,255,0.9); margin-bottom: 0;")
        )
      )
    ),
    fluidRow(
      column(4,
        wellPanel(
          h5("📁 数据上传", style = "color: #1565c0;"),
          fileInput("surv_file", "上传临床/生存表 (CSV/TXT)",
                    accept = c(".csv", ".csv.gz", ".txt", ".tsv", ".gz")),
          helpText("支持 TCGA 格式：含 vital_status、days_to_death、days_to_last_followup 时自动识别。", style = "font-size: 11px;"),
          hr(),
          h5("⏱️ 时间与终点", style = "color: #1565c0;"),
          checkboxInput("surv_use_tcga", "使用 TCGA 格式（自动：生存时间 + 终点）", value = TRUE),
          uiOutput("surv_tcga_cols_ui"),
          uiOutput("surv_manual_time_event_ui"),
          hr(),
          h5("📊 分层（可选）", style = "color: #1565c0;"),
          uiOutput("surv_strata_col_ui"),
          uiOutput("surv_strata_help_ui"),
          hr(),
          actionButton("surv_run", "📈 运行生存分析", class = "btn-primary", width = "100%")
        )
      ),
      column(8,
        uiOutput("surv_result_ui")
      )
    )
  )
}

survival_analysis_server <- function(input, output, session, user_session) {
  output$survival_analysis_ui_output <- renderUI({
    survival_analysis_ui()
  })

  surv_data <- reactiveValues(raw = NULL, surv_obj = NULL, strata = NULL, fit = NULL, pval = NULL)

  # 读取上传文件（复用 data_input 的 read_csv_file 若在全局；此处自实现简单读取）
  observeEvent(input$surv_file, {
    req(input$surv_file, user_session$logged_in)
    path <- input$surv_file$datapath
    name <- input$surv_file$name
    is_tab <- grepl("\\.(txt|tsv)(\\.gz)?$", name, ignore.case = TRUE)
    enc <- NULL
    if (!grepl("\\.gz$", name)) {
      con <- file(path, "rb")
      b <- readBin(con, "raw", 4)
      close(con)
      if (length(b) >= 2 && b[1] == as.raw(0xff) && b[2] == as.raw(0xfe)) enc <- "UTF-16LE"
      if (length(b) >= 3 && b[1] == as.raw(0xef) && b[2] == as.raw(0xbb) && b[3] == as.raw(0xbf)) enc <- "UTF-8"
    }
    args <- list(file = path, header = TRUE, stringsAsFactors = FALSE)
    if (!is.null(enc)) args$fileEncoding <- enc
    if (grepl("\\.gz$", name)) {
      args$file <- gzfile(path)
      args$sep <- if (is_tab) "\t" else ","
      args$fileEncoding <- NULL
      surv_data$raw <- do.call(read.delim, args)
    } else {
      args$sep <- if (is_tab) "\t" else ","
      if (!is.null(enc)) args$fileEncoding <- enc
      surv_data$raw <- do.call(read.delim, args)
    }
    surv_data$fit <- NULL
    surv_data$pval <- NULL
  })

  output$surv_tcga_cols_ui <- renderUI({
    req(surv_data$raw, input$surv_use_tcga)
    cnames <- colnames(surv_data$raw)
    has_tcga <- all(c("vital_status", "days_to_death", "days_to_last_followup") %in% cnames)
    if (!has_tcga) {
      return(helpText("未检测到 TCGA 列（vital_status, days_to_death, days_to_last_followup），请取消勾选并手动选择时间/终点列。", style = "color: #856404;"))
    }
    helpText("已识别 TCGA 格式，将用 days_to_last_followup/days_to_death 与 vital_status 构建生存数据。", style = "color: #2e7d32;")
  })

  output$surv_manual_time_event_ui <- renderUI({
    req(surv_data$raw, !isTRUE(input$surv_use_tcga))
    cols <- colnames(surv_data$raw)
    tagList(
      selectInput("surv_time_col", "时间列（天数）", choices = c("", cols)),
      selectInput("surv_event_col", "终点列（0/1 或 事件标识）", choices = c("", cols)),
      helpText("终点列：0=删失，1=事件；若为文字（如 LIVING/DECEASED），请在下方选择“事件”取值。", style = "font-size: 11px;"),
      textInput("surv_event_value", "事件取值（文字时填，如 DECEASED）", value = "DECEASED", placeholder = "DECEASED 或 1")
    )
  })

  output$surv_strata_col_ui <- renderUI({
    req(surv_data$raw)
    cols <- colnames(surv_data$raw)
    selectInput("surv_strata_col", "分层列（如基因突变）", choices = c("不分层" = "", cols))
  })

  output$surv_strata_help_ui <- renderUI({
    req(input$surv_strata_col, nzchar(input$surv_strata_col))
    helpText("将按该列不同取值分组绘制 KM 曲线并做 Log-rank 检验。", style = "font-size: 11px;")
  })

  output$surv_result_ui <- renderUI({
    req(surv_data$fit)
    tagList(
      fluidRow(
        column(12,
          h4("Kaplan-Meier 曲线"),
          plotOutput("surv_km_plot", height = "480px"),
          hr(),
          h4("Log-rank 检验"),
          verbatimTextOutput("surv_logrank"),
          hr(),
          downloadButton("surv_download_plot", "下载图片", class = "btn-secondary")
        )
      )
    )
  })

  observeEvent(input$surv_run, {
    req(surv_data$raw, user_session$logged_in)
    df <- surv_data$raw
    n <- nrow(df)

    msg_id <- showNotification("正在计算生存分析…", type = "message", duration = NULL)
    on.exit(removeNotification(msg_id), add = TRUE)

    time <- event <- NULL
    if (isTRUE(input$surv_use_tcga) && all(c("vital_status", "days_to_death", "days_to_last_followup") %in% colnames(df))) {
      obj <- build_survival_tcga(df)
      if (is.null(obj)) {
        showNotification("TCGA 列格式异常，请检查或改用手动选择。", type = "error")
        return()
      }
      time  <- obj$time
      event <- obj$event
    } else {
      req(input$surv_time_col, input$surv_event_col, nzchar(input$surv_time_col), nzchar(input$surv_event_col))
      time  <- as.numeric(as.character(df[[input$surv_time_col]]))
      ev    <- df[[input$surv_event_col]]
      event_val <- trimws(input$surv_event_value)
      if (event_val == "") event_val <- "1"
      if (is.numeric(ev)) {
        event <- as.integer(ev != 0)
      } else {
        event <- as.integer(toupper(trimws(as.character(ev))) %in% toupper(strsplit(event_val, "[,;]")[[1]]))
      }
    }

    valid <- !is.na(time) & time >= 0 & !is.na(event)
    if (sum(valid) < 5) {
      showNotification("有效样本数过少（需至少 5 例），请检查时间/终点列。", type = "error")
      return()
    }
    time  <- time[valid]
    event <- event[valid]
    df_use <- df[valid, , drop = FALSE]

    strata_col <- input$surv_strata_col
    if (!is.null(strata_col) && nzchar(strata_col) && strata_col %in% colnames(df_use)) {
      group <- as.character(df_use[[strata_col]])
      group[is.na(group) | trimws(group) == ""] <- "NA"
      surv_data$strata <- group
      d <- data.frame(time = time, event = event, group = group)
      fit <- tryCatch(survfit(Surv(time, event) ~ group, data = d), error = function(e) NULL)
    } else {
      surv_data$strata <- NULL
      d <- data.frame(time = time, event = event)
      fit <- tryCatch(survfit(Surv(time, event) ~ 1, data = d), error = function(e) NULL)
    }
    if (is.null(fit)) {
      showNotification("survfit 计算失败，请检查数据与分层列。", type = "error")
      return()
    }
    surv_data$fit <- fit

    if (!is.null(surv_data$strata)) {
      sd_obj <- tryCatch(survdiff(Surv(time, event) ~ group, data = d), error = function(e) NULL)
      surv_data$pval <- if (!is.null(sd_obj) && length(sd_obj$n) > 1)
        as.numeric(1 - pchisq(sd_obj$chisq, length(sd_obj$n) - 1)) else NA_real_
    } else {
      surv_data$pval <- NA_real_
    }

    showNotification("生存分析完成。", type = "message")
  })

  output$surv_km_plot <- renderPlot({
    req(surv_data$fit)
    fit <- surv_data$fit
    nstrata <- length(fit$strata)
    cols <- if (nstrata > 0) seq_len(nstrata) + 1 else 2
    plot(fit, col = cols, lwd = 2, xlab = "Time (days)", ylab = "Survival probability", main = "Kaplan-Meier curve")
    if (nstrata > 0) legend("bottomleft", legend = names(fit$strata), col = cols, lwd = 2, bty = "n")
  })

  output$surv_logrank <- renderPrint({
    req(surv_data$fit)
    if (!is.null(surv_data$strata) && !is.na(surv_data$pval)) {
      cat("Log-rank test p-value:", format.pval(surv_data$pval, digits = 4), "\n")
    } else {
      cat("(单组 KM，无分层，无 Log-rank)\n")
      print(summary(surv_data$fit))
    }
  })

  output$surv_download_plot <- downloadHandler(
    filename = function() paste0("KM_plot_", Sys.Date(), ".png"),
    content = function(file) {
      fit <- surv_data$fit
      nstrata <- length(fit$strata)
      cols <- if (nstrata > 0) seq_len(nstrata) + 1 else 2
      png(file, width = 800, height = 600, res = 120)
      plot(fit, col = cols, lwd = 2, xlab = "Time (days)", ylab = "Survival probability", main = "Kaplan-Meier curve")
      if (nstrata > 0) legend("bottomleft", legend = names(fit$strata), col = cols, lwd = 2, bty = "n")
      dev.off()
    }
  )
}
