# =====================================================
# 国际化测试脚本
# =====================================================

# 加载必要的包
library(shiny)
library(shinyjs)

# 加载配置和国际化模块
source("config/config.R")
source("modules/i18n.R")

# 简单的测试UI
ui <- fluidPage(
  titlePanel("Biofree - Language Test / 语言测试"),

  sidebarLayout(
    sidebarPanel(
      h4("Settings / 设置"),

      # 语言切换器
      selectInput("language",
                  "Language / 语言",
                  choices = c("🇨🇳 中文" = "zh", "🇺🇸 English" = "en"),
                  selected = "zh"),

      hr(),

      # 测试按钮
      actionButton("test", "Test Translation / 测试翻译")
    ),

    mainPanel(
      uiOutput("translated_content")
    )
  )
)

# 服务器逻辑
server <- function(input, output, session) {

  # 当前语言
  current_language <- reactiveVal("zh")

  # 监听语言切换
  observeEvent(input$language, {
    current_language(input$language)
    showNotification(
      paste("Language changed to / 语言已切换为:", input$language),
      type = "message"
    )
  })

  # 翻译函数
  translator <- reactive({
    make_translator(current_language)
  })

  # 渲染翻译内容
  output$translated_content <- renderUI({
    t <- translator()()

    tagList(
      h2(t("login_title")),
      h4(t("login_features_title")),

      tags$ul(
        tags$li(t("login_feature_1")),
        tags$li(t("login_feature_2")),
        tags$li(t("login_feature_3")),
        tags$li(t("login_feature_4"))
      ),

      hr(),

      h3("Navigation Test / 导航测试"),
      tags$ul(
        tags$li(t("nav_data_input")),
        tags$li(t("nav_deg")),
        tags$li(t("nav_kegg")),
        tags$li(t("nav_go")),
        tags$li(t("nav_gsea"))
      ),

      hr(),

      h3("Common Terms / 通用术语"),
      tags$ul(
        tags$li(paste("Submit:", t("common_submit"))),
        tags$li(paste("Download:", t("common_download"))),
        tags$li(paste("Success:", t("common_success")))
      )
    )
  })

  # 测试按钮
  observeEvent(input$test, {
    t <- translator()()
    showModal(modalDialog(
      title = "Translation Test / 翻译测试",
      paste("Current Language / 当前语言:", current_language()),
      br(), br(),
      paste("Welcome / 欢迎:", t("login_welcome")),
      paste("Username:", t("login_username")),
      paste("Password:", t("login_password")),
      easyClose = TRUE
    ))
  })
}

# 运行应用
shinyApp(ui = ui, server = server)
