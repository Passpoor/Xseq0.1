# =====================================================
# 国际化版本的登录UI
# =====================================================

# 动态登录UI - 根据语言切换显示不同文本
login_ui_dynamic <- function() {
  uiOutput("login_ui_translated")
}

# 登录UI渲染函数
render_login_ui <- function(input, output, session, translator_func) {
  output$login_ui_translated <- renderUI({
    t <- translator_func()

    tagList(
      wellPanel(
        id = "login_panel",

        # 登录页面的语言切换器
        tags$div(style="position: absolute; top: 20px; right: 20px; z-index: 1000;",
                 selectInput("login_language_switcher",
                             NULL,
                             choices = c("🇨🇳 中文" = "zh", "🇺🇸 English" = "en"),
                             selected = input$login_language_switcher %||% "zh",
                             width = "120px")
        ),

        # Logo和标题显示
        tags$div(class="text-center", style="margin-bottom: 20px; min-height: 300px; display: flex; flex-direction: column; align-items: center; justify-content: center;",
                 # Logo显示
                 tags$img(src="logo.png",
                          alt="Biofree Logo",
                          style="max-height: 300px; width: auto; object-fit: contain; margin-bottom: 20px;",
                          class="img-responsive",
                          id="main-logo"
                 ),
                 # 文字标题（logo加载失败时显示）
                 tags$h1(id="text-title",
                         class="text-center",
                         style="font-size: 28px; margin: 0; display: none;",
                         span(style="color: #007AFF;", "Biofree"),
                         span(style="color: #6E6E73; font-weight: normal;", "v12")
                 ),
                 # JavaScript处理logo加载和论文展开/折叠
                 tags$script(HTML("
                   document.addEventListener('DOMContentLoaded', function() {
                     var img = document.getElementById('main-logo');
                     var textTitle = document.getElementById('text-title');
                     if (img && textTitle) {
                       img.onload = function() {
                         textTitle.style.display = 'none';
                         img.style.display = 'block';
                       };
                       img.onerror = function() {
                         img.style.display = 'none';
                         textTitle.style.display = 'block';
                       };
                     }
                   });

                   function toggleOldPapers() {
                     var oldPapers = document.getElementById('old-papers');
                     var btn = document.getElementById('toggle-papers');
                     if (oldPapers.style.display === 'none') {
                       oldPapers.style.display = 'block';
                       btn.innerHTML = '📕 收起早期论文 ▲';
                     } else {
                       oldPapers.style.display = 'none';
                       btn.innerHTML = '📖 查看早期论文 ▼';
                     }
                   }
                 "))
        ),

        # biofree简介
        tags$div(class="text-center", style="margin-bottom: 35px; color: #6E6E73;",
                 tags$p(t("login_info"), style="font-size: 18px; margin-bottom: 12px;"),
                 tags$p(t("login_features_title"), style="font-size: 16px; margin-bottom: 0;")
        ),

        tags$hr(style="margin: 30px 0;"),

        # 开发者信息
        tags$div(style="margin-bottom: 35px;",
                 tags$h4(paste("👨‍💻", t("login_developer_title")), style="color: #007AFF; margin-bottom: 20px; font-size: 22px;"),
                 tags$p(paste("•", t("login_developer_name")), style="margin-bottom: 12px; font-size: 18px;"),
                 tags$p("• 邮箱：xseq_fastfreee@163.com", style="margin-bottom: 12px; font-size: 18px;"),
                 tags$p("• 版本：12", style="margin-bottom: 12px; font-size: 18px;"),
                 tags$p("• 更新日期：2026年1月3日", style="margin-bottom: 0; font-size: 18px;")
        ),

        tags$hr(style="margin: 30px 0;"),

        # 登录表单
        tags$h3(class="text-center", style="margin-bottom: 25px; color: #111; font-size: 24px;",
                paste(t("login_welcome"))),
        textInput("login_user", t("login_username"), placeholder = t("login_username")),
        div(style="position: relative; display: flex; align-items: center; margin-top: 15px;",
            passwordInput("login_password", t("login_password"), placeholder = t("login_password"), width = "calc(100% - 40px)"),
            div(
              style="position: absolute; right: 10px; cursor: pointer; padding: 8px;",
              id = "toggle-password",
              HTML('<span style="font-size: 16px; color: #007AFF;" onclick="togglePassword()">👁</span>')
            )
        ),
        actionButton("login_button", t("login_button"), class="btn-primary", width="100%", style="margin-top: 20px;"),

        tags$hr(style="margin: 30px 0;"),

        # 开发者简介模块 - 两栏布局
        tags$div(style="margin-bottom: 30px;",
                 tags$h4("📚 " + t("login_developer_title"), style="color: #007AFF; margin-bottom: 30px; font-size: 22px;"),

                 fluidRow(
                   column(6,
                          tags$h5("🎓 发表论文", style="color: #34C759; margin-bottom: 15px; font-size: 18px;"),
                          tags$div(id = "papers-container",
                                   style="max-height: 300px; overflow-y: auto; background-color: #F8F9FA; padding: 20px; border-radius: 10px; margin-bottom: 20px;",
                                   tags$div(style="margin: 0; padding-left: 10px; font-size: 14px; line-height: 1.6;",

                                            tags$p(style="font-weight: bold; margin-bottom: 10px; color: #007AFF;", "2025年"),
                                            tags$ol(style="margin-left: 20px; margin-bottom: 15px;",
                                                    tags$li(HTML("<strong>Yu Qiao</strong>, et al. (2025). Research Hotspots of Nectin-4. <em>Hum Vaccines Immunother</em>. (Accepted)")),
                                                    tags$li(HTML("Mengkai Li, Tao Wang, <strong>Yu Qiao</strong>, et al. (2025). LMO7 Suppresses Macrophage Phagocytosis. <em>Adv Sci (Weinh)</em>."))
                                            ),

                                            tags$p(style="font-weight: bold; margin-bottom: 10px; color: #007AFF;", "2024年"),
                                            tags$ol(style="margin-left: 20px; margin-bottom: 15px;",
                                                    tags$li(HTML("Zhiming Wang, <strong>Yu Qiao</strong>, et al. (2024). Adenovirus promotes anti-tumor immunity. <em>Acta Pharmacol Sin</em>.")),
                                                    tags$li(HTML("<strong>Yu Qiao</strong>, et al. (2024). Causal effects between personality and lung cancer. <em>Front Psychiatry</em>."))
                                            ),

                                            tags$p(style="font-weight: bold; margin-bottom: 10px; color: #007AFF;", "2023年"),
                                            tags$ol(style="margin-left: 20px; margin-bottom: 15px;",
                                                    tags$li(HTML("Ruoxuan Liu, <strong>Yu Qiao</strong>, et al. (2023). Bibliometric analysis of PND. <em>Aging Med</em>."))
                                            ),

                                            # 折叠的早期论文（默认隐藏）
                                            tags$div(id = "old-papers", style="display: none;",
                                                    tags$p(style="font-weight: bold; margin-bottom: 10px; color: #007AFF;", "2022年及更早"),
                                                    tags$ol(style="margin-left: 20px; margin-bottom: 15px;",
                                                            tags$li(HTML("Siyuan Chen, <strong>Yu Qiao</strong>, et al. (2022). Bibliometric study of NSCLC. <em>Front Oncol</em>.")),
                                                            tags$li(HTML("Zishu Wang, <strong>Yu Qiao</strong>. TIM-3 in cancer research. <em>J Bengbu Med Univ</em>.")),
                                                            tags$li(HTML("<strong>Yu Qiao</strong>, et al. (2020). Research of Basic Public Health Services. <em>Chin J Public Health Manag</em>."))
                                                    )
                                            )
                                   ),
                                   # "查看全部"按钮
                                   tags$button(
                                     id = "toggle-papers",
                                     class = "btn btn-info",
                                     style = "width: 100%; margin-top: 10px; font-size: 13px;",
                                     onclick = "toggleOldPapers()",
                                     "📖 查看早期论文 ▼"
                                   )
                          )
                   ),
                   column(6,
                          tags$h5("🏫 讲师经历", style="color: #FF9F0A; margin-bottom: 15px; font-size: 18px;"),
                          tags$div(style="max-height: 300px; overflow-y: auto; background-color: #F8F9FA; padding: 20px; border-radius: 10px; margin-bottom: 20px;",
                                   tags$ul(style="margin: 0; padding-left: 25px; font-size: 15px; line-height: 1.6;",
                                           tags$li("2023年至今 医课佳、顶刊研习社 - 文献计量分析成稿训练营、文献计量分析速成班 - 课程总监"),
                                           tags$li("2022年 临床科学家 - 文献检索，文献管理公开课，文献计量分析专题课程 - 主讲人"),
                                           tags$li("2023年 Hanson临床科研 - 文献计量分析及论文发表训练营 - 主讲人"),
                                           tags$li("2024年 医咖会团队 - 文献计量分析与SCI论文撰写技巧全解析 - 主讲人"),
                                           tags$li("2022年 临床科学家 - 【医学文献】中文版pubmed！Medreading（播放量2.3万） - 主讲人")
                                   )
                          )
                   )
                 )
        )
      )
    )
  })
}
