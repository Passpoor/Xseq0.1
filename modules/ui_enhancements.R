# =====================================================
# UI 增强模块
# UI Enhancements Module
# 版本: 2.0
# 说明: 集成所有UI增强功能的主模块
# =====================================================

# 辅助函数: 添加CSS和JavaScript资源
addUIEnhancements <- function() {
  # CSS 文件列表
  cssFiles <- c(
    "css/design-tokens.css",
    "css/components/components.css",
    "css/components/toasts.css",
    "css/components/skeleton.css",
    "css/components/stepper.css",
    "css/layouts/responsive.css",
    "css/animations/animations.css"
  )

  # JavaScript 文件列表
  jsFiles <- c(
    "js/components/toast.js",
    "js/components/skeleton.js",
    "js/components/stepper.js"
  )

  # 生成标签
  tags <- list()

  # 添加CSS
  for (cssFile in cssFiles) {
    tags[[length(tags) + 1]] <- tags$link(
      rel = "stylesheet",
      href = paste0("www/", cssFile)
    )
  }

  # 添加JavaScript
  for (jsFile in jsFiles) {
    tags[[length(tags) + 1]] <- tags$script(
      src = paste0("www/", jsFile)
    )
  }

  return(tags$div(class = "ui-enhancements-loaded", tags))
}

# =====================================================
# Toast 通知函数
# =====================================================

#' 显示 Toast 通知
#'
#' @param session Shiny session 对象
#' @param type 通知类型: "success", "error", "warning", "info"
#' @param title 标题
#' @param message 消息内容
#' @param duration 持续时间(毫秒),0表示不自动关闭
#' @param actions 操作按钮列表,每个元素是包含label和id的列表
#'
#' @return NULL
#' @export
#'
#' @examples
#' # 在 Shiny server 中使用
#' observeEvent(input$analyze, {
#'   showToast(
#'     session,
#'     type = "success",
#'     title = "分析完成",
#'     message = "差异分析已成功完成"
#'   )
#' })
showToast <- function(session, type = "info", title = "", message = "",
                     duration = 4000, actions = NULL) {
  session$sendCustomMessage("show-toast", list(
    type = type,
    title = title,
    message = message,
    duration = duration,
    actions = actions
  ))
}

#' 快捷函数: 成功通知
toastSuccess <- function(session, message, title = "") {
  showToast(session, type = "success", title = title, message = message)
}

#' 快捷函数: 错误通知
toastError <- function(session, message, title = "") {
  showToast(session, type = "error", title = title, message = message, duration = 0)
}

#' 快捷函数: 警告通知
toastWarning <- function(session, message, title = "") {
  showToast(session, type = "warning", title = title, message = message)
}

#' 快捷函数: 信息通知
toastInfo <- function(session, message, title = "") {
  showToast(session, type = "info", title = title, message = message)
}

#' 清除所有 Toast
toastClear <- function(session) {
  session$sendCustomMessage("toast-clear", list())
}

# =====================================================
# 骨架屏函数
# =====================================================

#' 显示骨架屏加载状态
#'
#' @param session Shiny session 对象
#' @param selector CSS 选择器
#' @param type 骨架屏类型: "card", "table", "chart", "list", "stat"
#' @param options 额外选项列表
#'
#' @return NULL
#' @export
showSkeleton <- function(session, selector, type = "card", options = list()) {
  session$sendCustomMessage("skeleton-show", list(
    selector = selector,
    type = type,
    options = options
  ))
}

#' 隐藏骨架屏加载状态
#'
#' @param session Shiny session 对象
#' @param selector CSS 选择器
#'
#' @return NULL
#' @export
hideSkeleton <- function(session, selector) {
  session$sendCustomMessage("skeleton-hide", list(
    selector = selector
  ))
}

# =====================================================
# 增强组件UI函数
# =====================================================

#' 创建增强按钮
#'
#' @param inputId 输入ID
#' @param label 按钮文本
#' @param icon 图标(可选)
#' @param class 额外的CSS类
#' @param size 按钮大小: "sm", "md", "lg"
#' @param type 按钮类型: "primary", "secondary", "success", "danger", "ghost"
#' @param loading 是否显示加载状态
#' @param ... 其他参数传递给 actionButton
#'
#' @return 按钮 UI 元素
#' @export
enhancedButton <- function(inputId, label, icon = NULL, class = NULL,
                           size = "md", type = "primary",
                           loading = FALSE, ...) {
  btnClass <- paste0("btn btn-", type, " btn-", size)

  if (!is.null(class)) {
    btnClass <- paste(btnClass, class)
  }

  if (loading) {
    btnClass <- paste(btnClass, "btn-loading")
  }

  iconHtml <- if (!is.null(icon)) {
    tags$span(class = "btn-icon", icon)
  } else {
    NULL
  }

  tags$button(
    id = inputId,
    type = "button",
    class = btnClass,
    class = if (!is.null(class)) class else NULL,
    iconHtml,
    label,
    ...
  )
}

#' 创建增强输入框
#'
#' @param inputId 输入ID
#' @param label 标签
#' @param value 初始值
#' @param placeholder 占位符文本
#' @param helpText 帮助文本
#' @param required 是否必填
#' @param size 输入框大小: "sm", "md", "lg"
#' @param ... 其他参数传递给 textInput
#'
#' @return 输入框 UI 元素
#' @export
enhancedInput <- function(inputId, label, value = "", placeholder = "",
                         helpText = NULL, required = FALSE,
                         size = "md", ...) {
  inputWrapper <- div(
    class = "input-group",
    label <- tags$label(
      class = paste0("input-label", if (required) " input-label-required" else ""),
      `for` = inputId,
      label
    ),
    div(
      class = "input-wrapper",
      tags$input(
        id = inputId,
        type = "text",
        class = paste0("form-control form-control-", size),
        value = value,
        placeholder = placeholder,
        `required` = if (required) "required" else NULL
      )
    ),
    if (!is.null(helpText)) {
      tags$small(class = "input-help", helpText)
    }
  )

  return(inputWrapper)
}

#' 创建统计卡片
#'
#' @param title 卡片标题
#' @param value 数值
#' @param subtitle 副标题
#' @param icon 图标
#' @param iconType 图标类型: "primary", "success", "warning", "error"
#' @param href 点击链接(可选)
#' @param ... 其他参数
#'
#' @return 卡片 UI 元素
#' @export
statCard <- function(title, value, subtitle = "", icon = NULL,
                    iconType = "primary", href = NULL, ...) {
  cardClass <- "stat-card"
  if (!is.null(href)) {
    cardClass <- paste(cardClass, "hover-scale")
  }

  iconHtml <- if (!is.null(icon)) {
    tags$div(
      class = paste0("stat-icon stat-icon-", iconType),
      icon
    )
  } else {
    NULL
  }

  content <- tags$div(
    class = cardClass,
    iconHtml,
    tags$div(
      class = "stat-content",
      tags$div(class = "stat-value", value),
      tags$div(class = "stat-label", title),
      if (subtitle != "") {
        tags$div(class = "stat-subtitle", subtitle)
      }
    )
  )

  if (!is.null(href)) {
    content <- tags$a(href = href, class = "stat-card-link", content)
  }

  return(content)
}

#' 创建增强卡片
#'
#' @param title 卡片标题
#' @param content 卡片内容
#' @param footer 卡片底部(可选)
#' @param status 状态: "primary", "success", "warning", "error"
#' @param hoverable 是否可悬停
#' @param ... 其他参数
#'
#' @return 卡片 UI 元素
#' @export
enhancedCard <- function(title, content, footer = NULL, status = NULL,
                        hoverable = FALSE, ...) {
  cardClass <- "card"
  if (hoverable) cardClass <- paste(cardClass, "card-hoverable")
  if (!is.null(status)) cardClass <- paste(cardClass, paste0("border-", status))

  tags$div(
    class = cardClass,
    tags$div(
      class = "card-header",
      tags$h4(class = "card-title", title)
    ),
    tags$div(
      class = "card-body",
      content
    ),
    if (!is.null(footer)) {
      tags$div(class = "card-footer", footer)
    }
  )
}

#' 创建可折叠面板
#'
#' @param inputId 输入ID
#' @param title 面板标题
#' @param content 面板内容
#' @param expanded 是否默认展开
#' @param icon 图标(可选)
#' @param ... 其他参数
#'
#' @return 面板 UI 元素
#' @export
collapsiblePanel <- function(inputId, title, content, expanded = FALSE,
                             icon = NULL, ...) {
  panelId <- paste0("panel-", inputId)

  tags$div(
    id = panelId,
    class = paste0("panel", if (expanded) " expanded" else ""),
    `data-expanded` = expanded,
    tags$div(
      class = "panel-header",
      `data-toggle` = "collapse",
      `data-target` = paste0("#", panelId, "-body"),
      title,
      if (!is.null(icon)) {
        tags$span(class = "panel-icon", icon)
      }
    ),
    tags$div(
      id = paste0(panelId, "-body"),
      class = "panel-body",
      `aria-expanded` = expanded,
      content
    )
  )
}

#' 创建进度条
#'
#' @param inputId 输入ID
#' @param value 进度值(0-100)
#' @param striped 是否显示条纹
#' @param animated 是否动画
#' @param status 状态: "primary", "success", "warning", "error"
#' @param size 大小: "sm", "md", "lg"
#' @param showLabel 是否显示百分比标签
#'
#' @return 进度条 UI 元素
#' @export
enhancedProgress <- function(inputId, value = 0, striped = TRUE,
                            animated = TRUE, status = "primary",
                            size = "md", showLabel = TRUE) {
  progressClass <- paste0("progress progress-", size)
  barClass <- paste0("progress-bar progress-bar-", status)
  if (striped) barClass <- paste(barClass, " progress-bar-striped")
  if (animated) barClass <- paste(barClass, " progress-bar-animated")

  tags$div(
    class = progressClass,
    tags$div(
      id = inputId,
      class = barClass,
      role = "progressbar",
      style = paste0("width: ", value, "%"),
      `aria-valuenow` = value,
      `aria-valuemin` = 0,
      `aria-valuemax` = 100,
      if (showLabel) paste0(value, "%") else NULL
    )
  )
}

#' 创建文件上传区域
#'
#' @param inputId 输入ID
#' @param label 标签
#' @param accept 接受的文件类型
#' @param multiple 是否允许多个文件
#' @param maxSize 最大文件大小(MB)
#'
#' @return 文件上传 UI 元素
#' @export
enhancedFileInput <- function(inputId, label = "拖拽文件到此处 或 点击上传",
                              accept = ".csv,.csv.gz,.txt,.tsv",
                              multiple = FALSE, maxSize = 100) {
  tags$div(
    class = "file-upload",
    `data-accept` = accept,
    `data-multiple` = multiple,
    tags$span(class = "file-upload-icon", "📁"),
    tags$div(class = "file-upload-title", label),
    tags$div(
      class = "file-upload-hint",
      paste0("支持 ", accept, " 格式 | 最大 ", maxSize, "MB")
    ),
    tags$input(
      id = inputId,
      type = "file",
      class = "file-upload-input",
      accept = accept,
      multiple = if (multiple) "multiple" else NULL
    )
  )
}

#' 创建徽章
#'
#' @param text 徽章文本
#' @param type 徽章类型: "primary", "success", "warning", "error", "secondary"
#' @param pill 是否为药丸形状
#' @param dot 是否为圆点
#'
#' @return 徽章 UI 元素
#' @export
badge <- function(text, type = "primary", pill = TRUE, dot = FALSE) {
  badgeClass <- paste0("badge badge-", type)
  if (pill) badgeClass <- paste(badgeClass, "badge-pill")
  if (dot) badgeClass <- paste(badgeClass, "badge-dot")

  tags$span(class = badgeClass, text)
}

# =====================================================
# 工具函数
# =====================================================

#' 更新进度条
#'
#' @param session Shiny session 对象
#' @param inputId 进度条输入ID
#' @param value 进度值(0-100)
#'
#' @return NULL
#' @export
updateProgress <- function(session, inputId, value) {
  session$sendCustomMessage("update-progress", list(
    id = inputId,
    value = value
  ))
}

#' 设置按钮加载状态
#'
#' @param session Shiny session 对象
#' @param inputId 按钮输入ID
#' @param loading 是否显示加载状态
#'
#' @return NULL
#' @export
setButtonLoading <- function(session, inputId, loading = TRUE) {
  session$sendCustomMessage("set-button-loading", list(
    id = inputId,
    loading = loading
  ))
}

#' 切换深色模式
#'
#' @param session Shiny session 对象
#' @param enabled 是否启用深色模式
#'
#' @return NULL
#' @export
toggleDarkMode <- function(session, enabled = NULL) {
  session$sendCustomMessage("toggle-dark-mode", list(
    enabled = enabled
  ))
}

# =====================================================
# 示例使用
# =====================================================

#' 示例: 创建包含所有UI增强的页面
#'
#' @return Shiny UI 定义
#' @export
exampleEnhancedUI <- function() {
  fluidPage(
    # 添加UI增强资源
    addUIEnhancements(),

    # 页面标题
    h1("UI 增强示例"),

    # 统计卡片行
    fluidRow(
      column(4, statCard("差异基因", "1,234", "↑ 12.5%", "📈", "primary")),
      column(4, statCard("上调基因", "678", "+55%", "⬆️", "success")),
      column(4, statCard("下调基因", "556", "-45%", "⬇️", "error"))
    ),

    # 按钮组
    fluidRow(
      column(12,
        h3("增强按钮"),
        enhancedButton("btn1", "主要按钮", type = "primary"),
        enhancedButton("btn2", "成功按钮", type = "success"),
        enhancedButton("btn3", "危险按钮", type = "danger"),
        enhancedButton("btn4", "幽灵按钮", type = "ghost")
      )
    ),

    # 可折叠面板
    fluidRow(
      column(12,
        h3("可折叠面板"),
        collapsiblePanel("panel1", "点击展开", p("这是面板内容"), icon = "▼"),
        collapsiblePanel("panel2", "高级设置", p("更多选项"), icon = "⚙")
      )
    ),

    # 进度条
    fluidRow(
      column(12,
        h3("进度条"),
        enhancedProgress("progress1", 65, status = "primary"),
        enhancedProgress("progress2", 80, status = "success")
      )
    )
  )
}

# 在 ui.R 中使用:
# library(shiny)
# source("modules/ui_enhancements.R")
#
# shinyUI(fluidPage(
#   addUIEnhancements(),
#   # 你的其他UI代码
# ))
