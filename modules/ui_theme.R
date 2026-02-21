# =====================================================
#  🍎 Apple-style UI + Dark Mode
#  完整 UI 模块（完全替换你之前的 sci_fi UI）
# =====================================================

library(shiny)
library(shinyWidgets)
library(colourpicker)
library(shinyjs)
library(bslib)

# =====================================================
# 🍎 Apple 风格主题样式（完整可运行版）
# =====================================================

sci_fi_css <- tags$style(HTML("
/* 基础字体 - 添加微妙渐变背景 */
body {
    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(135deg, #F5F5F7 0%, #EFEFF4 50%, #F5F5F7 100%);  /* 🔥 添加微妙渐变 */
    margin: 0;
    padding: 0;
    font-size: 14px;
    min-height: 100vh;  /* 🔥 确保背景覆盖整个视口 */
}

/* 响应式字体大小 */
@media (max-width: 1200px) {
    body {
        font-size: 13px;
    }
}

@media (max-width: 768px) {
    body {
        font-size: 12px;
    }
}

@media (max-width: 480px) {
    body {
        font-size: 11px;
    }
}

/* 夜间模式 - 添加微妙渐变背景 */
.dark-mode {
    background: linear-gradient(135deg, #1C1C1E 0%, #252528 50%, #1C1C1E 100%) !important;  /* 🔥 深色模式渐变 */
    color: #FFFFFF !important;
    min-height: 100vh;
}

/* 夜间模式下的所有元素 */
.dark-mode,
.dark-mode body,
.dark-mode .navbar,
.dark-mode .sidebar-panel,
.dark-mode .main-panel,
.dark-mode .well-panel,
.dark-mode .tab-pane,
.dark-mode .shiny-html-output,
.dark-mode .container-fluid,
.dark-mode .shiny-text-output,
.dark-mode .form-group,
.dark-mode .control-label,
.dark-mode .help-block,
.dark-mode .text-muted,
.dark-mode .radio,
.dark-mode .checkbox,
.dark-mode .well,
.dark-mode .panel,
.dark-mode .panel-body {
    color: #FFFFFF !important;
    background-color: #1C1C1E !important;
}

/* 所有文本元素强制白色 */
.dark-mode h1,
.dark-mode h2,
.dark-mode h3,
.dark-mode h4,
.dark-mode h5,
.dark-mode h6,
.dark-mode p,
.dark-mode span,
.dark-mode div,
.dark-mode label {
    color: #FFFFFF !important;
}

/* 文件上传组件 */
.dark-mode .shiny-input-container,
.dark-mode .form-group,
.dark-mode .control-label {
    color: #FFFFFF !important;
}

.dark-mode .shiny-file-input-label,
.dark-mode .input-group-addon {
    color: #FFFFFF !important;
    background-color: #2C2C2E !important;
    border-color: #444444 !important;
}

/* 按钮组 */
.dark-mode .btn-group,
.dark-mode .btn-group .btn {
    color: #FFFFFF !important;
}

/* 下载按钮 */
.dark-mode .download-button,
.dark-mode .shiny-download-link {
    color: #FFFFFF !important;
}

/* 文件浏览区域 */
.dark-mode .file-input,
.dark-mode .shiny-bound-input {
    color: #FFFFFF !important;
}

/* 进度条 */
.dark-mode .progress,
.dark-mode .progress-bar {
    background-color: #2C2C2E !important;
    color: #FFFFFF !important;
}

/* Shiny特定组件 */
.dark-mode .shiny-bound-output,
.dark-mode .shiny-html-output,
.dark-mode .shiny-text-output,
.dark-mode .shiny-plot-output,
.dark-mode .shiny-table-output {
    color: #FFFFFF !important;
    background-color: #1C1C1E !important;
}

/* 文件上传进度 */
.dark-mode .shiny-file-input-progress,
.dark-mode .progress-text {
    color: #FFFFFF !important;
}

/* 文件上传按钮 */
.dark-mode .btn-file {
    color: #FFFFFF !important;
    background-color: #2C2C2E !important;
    border-color: #444444 !important;
}

/* 文件上传区域 */
.dark-mode .file-input-wrapper,
.dark-mode .file-input-name {
    color: #FFFFFF !important;
}

/* 下载链接 */
.dark-mode a[download],
.dark-mode .shiny-download-link a {
    color: #0A84FF !important;
}

/* 开发者简介模块夜间模式 */
.dark-mode #login_panel ol,
.dark-mode #login_panel ul,
.dark-mode #login_panel li {
    color: #FFFFFF !important;
}

/* 基因助手输出区域夜间模式 */
.dark-mode div[style*='background-color: #f8f9fa'] {
    background-color: #2C2C2E !important;
    border-color: #444444 !important;
}

.dark-mode .shiny-text-output {
    color: #FFFFFF !important;
}

.dark-mode #login_panel div[style*='background-color: #F8F9FA'] {
    background-color: #2C2C2E !important;
    color: #FFFFFF !important;
}

.dark-mode #login_panel h4,
.dark-mode #login_panel h5 {
    color: #FFFFFF !important;
}

/* 输入框特殊处理 */
.dark-mode .form-control,
.dark-mode .selectize-input {
    color: #000000 !important;
    background-color: #FFFFFF !important;
}

.dark-mode select {
    color: #000000 !important;
    background-color: #FFFFFF !important;
}

/* 下拉菜单选项样式 */
.dark-mode select option {
    color: #000000 !important;
    background-color: #FFFFFF !important;
}

/* Selectize下拉菜单选项样式 */
.dark-mode .selectize-dropdown {
    background-color: #FFFFFF !important;
    border: 1px solid #444444 !important;
}

.dark-mode .selectize-dropdown .option {
    color: #000000 !important;
    background-color: #FFFFFF !important;
}

.dark-mode .selectize-dropdown .option:hover {
    background-color: #F0F0F0 !important;
    color: #000000 !important;
}

.dark-mode .selectize-dropdown .active {
    background-color: #007AFF !important;
    color: #FFFFFF !important;
}

/* 按钮 */
.dark-mode .btn {
    color: #FFFFFF !important;
}

/* 表格 */
.dark-mode table,
.dark-mode th,
.dark-mode td {
    color: #FFFFFF !important;
    background-color: #2C2C2E !important;
}

/* 标签页 */
.dark-mode .nav-tabs .nav-link {
    color: #CCCCCC !important;
}

.dark-mode .nav-tabs .nav-link.active {
    color: #0A84FF !important;
}

.dark-mode .nav-tabs .nav-link:hover {
    color: #FFFFFF !important;
}

a { color: #007AFF; }
.dark-mode a { color: #0A84FF; }

/* 密码显示/隐藏按钮样式 */
#toggle-password {
  user-select: none;
  outline: none;
  transition: color 0.3s ease;
}

#toggle-password:hover {
  color: #0056b3 !important;
}

.dark-mode #toggle-password:hover {
  color: #007AFF !important;
}

/* 导航栏 - 简化效果提升速度 */
.navbar {
    background-color: rgba(255,255,255,0.95) !important;
    border-bottom: 1px solid rgba(0,0,0,0.05);
}
.dark-mode .navbar {
    background-color: rgba(28,28,30,0.95) !important;
    border-bottom: 1px solid rgba(255,255,255,0.05);
}
.navbar-brand, .nav-link {
    color: #111 !important;
    font-weight: 500;
}
.dark-mode .navbar-brand, .dark-mode .nav-link {
    color: #F2F2F7 !important;
}

/* 面板 - 增强阴影效果提升视觉层次 */
.sidebar-panel, .main-panel, .well-panel, .tab-pane {
    background-color: #FFFFFF !important;
    border-radius: 14px;
    padding: 20px;
    border: 1px solid rgba(0,0,0,0.06);
    box-shadow: 0 4px 16px rgba(0,0,0,0.08);  /* 🔥 增强阴影：更明显更有层次 */
    transition: box-shadow 0.3s ease;  /* 🔥 添加柔和过渡效果 */
}

/* 面板hover效果 */
.sidebar-panel:hover, .main-panel:hover, .well-panel:hover {
    box-shadow: 0 6px 24px rgba(0,0,0,0.12);  /* 🔥 hover时阴影更深 */
}

.dark-mode .sidebar-panel,
.dark-mode .main-panel,
.dark-mode .well-panel,
.dark-mode .tab-pane {
    background-color: #2C2C2E !important;
    border: 1px solid rgba(255,255,255,0.08);
    box-shadow: 0 4px 16px rgba(0,0,0,0.5);  /* 🔥 增强深色模式阴影 */
    transition: box-shadow 0.3s ease;
}

.dark-mode .sidebar-panel:hover,
.dark-mode .main-panel:hover,
.dark-mode .well-panel:hover {
    box-shadow: 0 6px 24px rgba(0,0,0,0.7);  /* 🔥 深色模式hover效果 */
}

/* 按钮 */
.btn {
    border-radius: 10px !important;
    padding: 8px 14px !important;
    font-weight: 500 !important;
    border: none !important;
    font-size: 14px !important;
}

/* 响应式按钮字体大小 */
@media (max-width: 1200px) {
    .btn {
        font-size: 13px !important;
        padding: 7px 12px !important;
    }
}

@media (max-width: 768px) {
    .btn {
        font-size: 12px !important;
        padding: 6px 10px !important;
    }
}

@media (max-width: 480px) {
    .btn {
        font-size: 11px !important;
        padding: 5px 8px !important;
    }
}
.btn-primary { background-color: #007AFF !important; color: white !important; }
.dark-mode .btn-primary { background-color: #0A84FF !important; }

.btn-success { background-color: #34C759 !important; color: white !important; }
.btn-warning { background-color: #FF9F0A !important; }
.btn-info { background-color: #5AC8FA !important; }

/* 🔥 增强按钮hover效果 - 添加transform和阴影 */
.btn:hover {
    transform: translateY(-2px);  /* 🔥 向上浮动 */
    box-shadow: 0 4px 12px rgba(0,122,255,0.3);  /* 🔥 添加阴影 */
    opacity: 1;  /* 🔥 不再降低opacity */
}

.btn-primary:hover {
    box-shadow: 0 4px 12px rgba(0,122,255,0.4);
}

.btn-success:hover {
    box-shadow: 0 4px 12px rgba(52,199,89,0.4);
}

.btn-warning:hover {
    box-shadow: 0 4px 12px rgba(255,159,10,0.4);
}

.btn-info:hover {
    box-shadow: 0 4px 12px rgba(90,200,250,0.4);
}

/* 深色模式按钮hover */
.dark-mode .btn:hover {
    box-shadow: 0 4px 12px rgba(10,132,255,0.5);
}

.dark-mode .btn-primary:hover {
    box-shadow: 0 4px 12px rgba(10,132,255,0.6);
}

/* 输入框 - 移除过渡效果提升速度 */
.form-control, .selectize-input {
    background-color: #FAFAFC !important;
    border-radius: 10px !important;
    border: 1px solid rgba(0,0,0,0.08) !important;
    height: 38px;
}

/* 下拉菜单选项样式 */
select option {
    color: #000000 !important;
    background-color: #FFFFFF !important;
}

/* Selectize下拉菜单选项样式 */
.selectize-dropdown {
    background-color: #FFFFFF !important;
    border: 1px solid rgba(0,0,0,0.1) !important;
}

.selectize-dropdown .option {
    color: #000000 !important;
    background-color: #FFFFFF !important;
}

.selectize-dropdown .option:hover {
    background-color: #F0F0F0 !important;
    color: #000000 !important;
}

.selectize-dropdown .active {
    background-color: #007AFF !important;
    color: #FFFFFF !important;
}
.form-control:focus, .selectize-input.focus {
    border-color: #007AFF !important;
    box-shadow: 0 0 0 3px rgba(0,122,255,0.15);
}
.dark-mode .form-control,
.dark-mode .selectize-input {
    background-color: #3A3A3C !important;
    border: 1px solid rgba(255,255,255,0.1) !important;
    color: #F2F2F7 !important;
}
.dark-mode .form-control:focus {
    border-color: #0A84FF !important;
    box-shadow: 0 0 0 3px rgba(10,132,255,0.2);
}

/* 标签页 */
.nav-tabs .nav-link {
    border: none !important;
    padding: 10px 16px !important;
    color: #6E6E73;
}
.nav-tabs .nav-link.active {
    color: #007AFF !important;
    border-bottom: 3px solid #007AFF !important;
    background: transparent !important;
    font-weight: 600;
}
.dark-mode .nav-tabs .nav-link.active {
    color: #0A84FF !important;
    border-bottom: 3px solid #0A84FF !important;
}

/* DataTable */
.dataTables_wrapper { color: #111 !important; }
.dark-mode .dataTables_wrapper { color: #F2F2F7 !important; }

/* 登录面板 */
#login_panel {
    max-width: 1400px;
    width: 100%;
    margin: auto;
    background-color: #FFFFFF !important;
    border: 1px solid rgba(0,0,0,0.06);
    border-radius: 16px;
    padding: 60px;
    box-shadow: 0 6px 20px rgba(0,0,0,0.1);
    color: #111 !important;
}
.dark-mode #login_panel {
    background-color: #2C2C2E !important;
    border: 1px solid rgba(255,255,255,0.08);
    box-shadow: 0 6px 20px rgba(0,0,0,0.55);
    color: #FFFFFF !important;
}

/* 登录面板内的文本 - 强制白色 */
#login_panel h1, #login_panel h2, #login_panel h3, #login_panel h4, #login_panel p, #login_panel span {
    color: inherit !important;
}

.dark-mode #login_panel h1, .dark-mode #login_panel h2, .dark-mode #login_panel h3,
.dark-mode #login_panel h4, .dark-mode #login_panel p, .dark-mode #login_panel span {
    color: #FFFFFF !important;
}

/* 登录面板内的输入框标签 */
#login_panel label {
    color: inherit !important;
}

.dark-mode #login_panel label {
    color: #FFFFFF !important;
}

/* AI解读框样式 */
.ai-interpretation-box {
    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, sans-serif;
    line-height: 1.8;
    color: #333;
}

.ai-interpretation-box h1,
.ai-interpretation-box h2,
.ai-interpretation-box h3,
.ai-interpretation-box h4 {
    color: #2c3e50;
    margin-top: 1.5em;
    margin-bottom: 0.8em;
}

.ai-interpretation-box p {
    margin-bottom: 1em;
}

.ai-interpretation-box ul,
.ai-interpretation-box ol {
    margin-bottom: 1em;
    padding-left: 2em;
}

.ai-interpretation-box li {
    margin-bottom: 0.5em;
}

.ai-interpretation-box strong {
    color: #007AFF;
    font-weight: 600;
}

/* AI加载动画 */
.ai-loading .fa-spinner {
    font-size: 3em;
    color: #667eea;
}

/* 深色模式下的AI解读框 */
.dark-mode .ai-interpretation-box {
    color: #E5E5E5;
}

.dark-mode .ai-interpretation-box h1,
.dark-mode .ai-interpretation-box h2,
.dark-mode .ai-interpretation-box h3,
.dark-mode .ai-interpretation-box h4 {
    color: #FFFFFF;
}

.dark-mode .ai-interpretation-box strong {
    color: #0A84FF;
}
"))

# =====================================================
# JS 控制：主题切换（自动加 body.dark-mode）
# =====================================================

theme_js <- tags$script(HTML("
Shiny.addCustomMessageHandler('toggle-darkmode', function(is_dark){
    if(is_dark){
        document.body.classList.add('dark-mode');
    } else {
        document.body.classList.remove('dark-mode');
    }
});

// 密码显示/隐藏功能
function togglePassword() {
    var passwordInput = document.getElementById('login_password');
    var toggleBtn = document.getElementById('toggle-password');

    if (passwordInput && toggleBtn) {
        if (passwordInput.type === 'password') {
            passwordInput.type = 'text';
            toggleBtn.innerHTML = '<span style=\"font-size: 16px; color: #007AFF;\" onclick=\"togglePassword()\">👁</span>';
        } else {
            passwordInput.type = 'password';
            toggleBtn.innerHTML = '<span style=\"font-size: 16px; color: #007AFF;\" onclick=\"togglePassword()\">👁️</span>';
        }
    }
}
"))

# 移除了Font Awesome依赖，使用emoji替代

# =====================================================
# 登录界面
# =====================================================

login_ui <- tagList(
  # font_awesome,  # 已移除Font Awesome依赖，使用emoji替代
  wellPanel(
    id = "login_panel",

    # 登录页面的语言切换器
    tags$div(style="position: absolute; top: 20px; right: 20px; z-index: 1000;",
             selectInput("login_language_switcher",
                         NULL,
                         choices = c("🇨🇳 中文" = "zh", "🇺🇸 English" = "en"),
                         selected = "zh",
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
                     span(style="color: #007AFF;", "Xseq"),
                     span(style="color: #6E6E73; font-weight: normal;", " v13.0")
             ),
             # JavaScript处理logo加载和论文展开/折叠
             tags$script(HTML("
               document.addEventListener('DOMContentLoaded', function() {
                 var img = document.getElementById('main-logo');
                 var textTitle = document.getElementById('text-title');
                 if (img && textTitle) {
                   // 图片加载成功时隐藏文字标题
                   img.onload = function() {
                     textTitle.style.display = 'none';
                     img.style.display = 'block';
                   };
                   // 图片加载失败时显示文字标题
                   img.onerror = function() {
                     img.style.display = 'none';
                     textTitle.style.display = 'block';
                   };
                 }
               });

               // 🔥 论文展开/折叠函数
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
    
    # Xseq 简介
    tags$div(class="text-center", style="margin-bottom: 35px; color: #6E6E73;",
             tags$p("Xseq - 专业的组学数据分析平台", style="font-size: 18px; margin-bottom: 12px;"),
             tags$p("集成 RNA-seq、芯片数据、单细胞亚群分析，海量组学可视化图于一体", style="font-size: 16px; margin-bottom: 0;")
    ),

    tags$hr(style="margin: 30px 0;"),

    # 开发者信息
    tags$div(style="margin-bottom: 35px;",
             tags$h4("👨‍💻 开发者信息", style="color: #007AFF; margin-bottom: 20px; font-size: 22px;"),
             tags$p("• 开发者：文献计量与基础医学", style="margin-bottom: 12px; font-size: 18px;"),
             tags$p("• 邮箱：xseq_fastfreee@163.com", style="margin-bottom: 12px; font-size: 18px;"),
             tags$p("• 版本：13.0", style="margin-bottom: 12px; font-size: 18px;"),
             tags$p("• 更新日期：2026年1月14日", style="margin-bottom: 0; font-size: 18px;")
    ),

    tags$hr(style="margin: 30px 0;"),

    # 登录表单
    tags$h3(class="text-center", style="margin-bottom: 25px; color: #111; font-size: 24px;", "欢迎登录系统"),
    textInput("login_user", "用户名", placeholder = "请输入用户名"),
    div(style="position: relative; display: flex; align-items: center; margin-top: 15px;",
        passwordInput("login_password", "密码", placeholder = "请输入密码", width = "calc(100% - 40px)"),
        div(
          style="position: absolute; right: 10px; cursor: pointer; padding: 8px;",
          id = "toggle-password",
          HTML('<span style="font-size: 16px; color: #007AFF;" onclick="togglePassword()">👁</span>')
        )
    ),
    actionButton("login_button", "登录系统", class="btn-primary", width="100%", style="margin-top: 20px;"),

    tags$hr(style="margin: 30px 0;"),
    
    # 开发者简介模块 - 两栏布局
    tags$div(style="margin-bottom: 30px;",
             tags$h4("📚 开发者简介", style="color: #007AFF; margin-bottom: 30px; font-size: 22px;"),
             
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

                                        # 🔥 折叠的早期论文（默认隐藏）
                                        tags$div(id = "old-papers", style="display: none;",
                                                tags$p(style="font-weight: bold; margin-bottom: 10px; color: #007AFF;", "2022年及更早"),
                                                tags$ol(style="margin-left: 20px; margin-bottom: 15px;",
                                                        tags$li(HTML("Siyuan Chen, <strong>Yu Qiao</strong>, et al. (2022). Bibliometric study of NSCLC. <em>Front Oncol</em>.")),
                                                        tags$li(HTML("Zishu Wang, <strong>Yu Qiao</strong>. TIM-3 in cancer research. <em>J Bengbu Med Univ</em>.")),
                                                        tags$li(HTML("<strong>Yu Qiao</strong>, et al. (2020). Research of Basic Public Health Services. <em>Chin J Public Health Manag</em>."))
                                                )
                                        )
                               ),
                               # 🔥 "查看全部"按钮
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

# =====================================================
# 主界面 UI
# =====================================================

main_app_ui <- function(user_name, initial_theme) {

  navbarPage(
    title = tagList(
    # Logo显示（更大尺寸）
    tags$img(src="logo.png",
             alt="Biofree Logo",
             style="height: 60px; margin-right: 15px; vertical-align: middle;",
             class="img-responsive",
             id="navbar-logo",
             onerror = "this.style.display='none'; document.getElementById('navbar-title').style.display='inline';"
    ),
    # 文字标题（logo加载失败时显示）
    tags$span(id="navbar-title",
             style="vertical-align: middle; display: none; color: #007AFF;",
             paste("Xseq v13.0 (", user_name, ")")),
    # 语言切换器
    tags$div(style="display: inline-block; margin-left: 30px; vertical-align: middle;",
             selectInput("language_switcher",
                         NULL,
                         choices = c("🇨🇳 中文" = "zh", "🇺🇸 English" = "en"),
                         selected = "zh",
                         width = "120px")
    )
  ),
    id = "navbar",
    theme = bslib::bs_theme(version = 5),
    header = tagList(
      sci_fi_css,
      theme_js,
      useShinyjs()
    ),
    collapsible = TRUE,

    # 🆕 FigFree KEGG绘图工具（纯HTML版本）
    tabPanel("📊 FigFree工具",
             tags$div(style = "height: calc(100vh - 80px);",
               tags$iframe(
                 src = "figfree.html",
                 style = "width: 100%; height: 100%; border: none;",
                 frameborder = "0"
               )
             )
    ),

    tabPanel("分析工作台",
             sidebarLayout(
               sidebarPanel(
                 width = 3,
                 class = "sidebar-panel",
                 
                 materialSwitch(
                   inputId = "theme_toggle",
                   label = span("🌙 夜间模式"),
                   value = FALSE,
                   status = "primary"
                 ),
                 
                 tags$hr(),
                 
                 h4("数据设置"),
                 radioButtons("data_source", "数据来源",
                              choices = c("原始Counts矩阵" = "counts",
                                          "差异基因结果" = "deg",
                                          "芯片差异结果" = "chip"),
                              inline = TRUE),
                 
                 conditionalPanel(
                   condition = "input.data_source == 'counts'",
                   fileInput("file", "上传 Counts Matrix (CSV/TXT/TSV)", accept = c(".csv", ".csv.gz", ".gz", ".txt", ".tsv")),
                   helpText("支持 CSV（逗号分隔）或 TXT/TSV（Tab 分隔）；UTF-8/UTF-16 自动识别。", style = "font-size: 11px; color: #666;"),
                   selectInput("species_select", "物种", choices = c("Mouse (org.Mm.eg.db)" = "Mm", "Human (org.Hs.eg.db)" = "Hs")),
                   checkboxInput("is_tcga_data", "TCGA 数据（按条形码自动区分肿瘤/正常）", value = FALSE),
                   helpText("勾选后将从列名第4段判断：01–09=肿瘤，10–19=正常，并自动填充对照组/处理组。", style = "font-size: 11px; color: #666;"),
                   uiOutput("group_selector"),

                   # 样本数量显示
                   uiOutput("sample_count_display"),

                   tags$hr(),
                   h4("差异参数"),
                   selectInput("pval_type", "显著性指标", choices = c("padj", "pvalue")),
                   splitLayout(
                     numericInput("pval_cutoff", "P阈值", 0.05, step = 0.01),
                     numericInput("log2fc_cutoff", "FC阈值", 1, step = 0.5)
                   ),

                   numericInput("edgeR_dispersion", "edgeR 离散度 (Dispersion^0.5)",
                                value = 0.1, min = 0, max = 1, step = 0.01),
                   helpText(class="text-muted", "注：分析方法将根据样本数量自动选择。每组样本数≥3时使用limma-voom，<3时使用edgeR。"),

                   # 方法选择已改为自动，隐藏原选择器
                   hidden(selectInput("method", "方法", choices = c("limma-voom", "edgeR"), selected = "limma-voom"))
                 ),

                 conditionalPanel(
                   condition = "input.data_source == 'deg'",
                   fileInput("deg_file", "上传差异基因 (CSV/TXT/TSV)", accept = c(".csv", ".csv.gz", ".gz", ".txt", ".tsv")),
                   selectInput("deg_species", "物种", choices = c("Mouse (org.Mm.eg.db)" = "Mm", "Human (org.Hs.eg.db)" = "Hs")),

                   helpText(class="text-muted",
                            "CSV文件应包含以下列：p_val, avg_log2FC, pct.1, pct.2, p_val_adj, gene"),

                   tags$hr(),
                   h4("差异参数"),
                   selectInput("deg_pval_type", "显著性指标",
                               choices = c("调整P值" = "p_val_adj", "原始P值" = "p_val")),
                   splitLayout(
                     numericInput("deg_pval_cutoff", "P阈值", 0.05, step = 0.01),
                     numericInput("deg_log2fc_cutoff", "FC阈值", 0.25, step = 0.1)
                   ),

                   tags$hr(),
                   actionButton("load_deg", "加载差异基因", class = "btn-info", width = "100%")
                 ),

                 # 🆕 芯片差异结果导入
                 conditionalPanel(
                   condition = "input.data_source == 'chip'",
                   fileInput("chip_file", "上传芯片差异结果 (CSV/TXT/TSV)", accept = c(".csv", ".csv.gz", ".gz", ".txt", ".tsv")),
                   selectInput("chip_species", "物种", choices = c("Mouse (org.Mm.eg.db)" = "mmu", "Human (org.Hs.eg.db)" = "hsa")),

                   helpText(class="text-info",
                            "CSV文件应包含以下列：logFC, AveExpr, t, P.Value, adj.P.Val, B, SYMBOL, ID",
                            br(),
                            "这是从芯片分析模块导出的limma差异分析结果。"),

                   tags$hr(),
                   h4("差异参数"),
                   selectInput("chip_pval_type", "显著性指标",
                               choices = c("调整P值" = "adj.P.Val", "原始P值" = "P.Value")),
                   splitLayout(
                     numericInput("chip_pval_cutoff", "P阈值", 0.05, step = 0.01),
                     numericInput("chip_log2fc_cutoff", "FC阈值", 1, step = 0.5)
                   ),

                   tags$hr(),
                   actionButton("load_chip", "加载芯片差异结果", class = "btn-primary", width="100%")
                 ),
                 
                 tags$hr(),
                 actionButton("analyze", "开始分析", class="btn-success", width="100%"),
                 br(), br(),
                 downloadButton("download_results", "下载结果", class="btn-info", style="width:100%")
               ),
               
               mainPanel(
                 class="main-panel",
                 tabsetPanel(
                   tabPanel("📊 数据概览", icon = icon("table"),
                            br(),
                            uiOutput("deg_summary"),  # 🆕 差异基因统计信息
                            tags$hr(),
                            DT::dataTableOutput("deg_table")
                   ),

                   tabPanel("📖 分析指标说明", icon = icon("info-circle"),
                            br(),
                            fluidRow(
                              column(12,
                                wellPanel(
                                  h4("📊 差异分析统计指标", style = "color: #337ab7;"),
                                  tags$div(
                                    style = "padding: 15px;",
                                    tags$table(
                                      class = "table table-striped table-bordered",
                                      tags$thead(
                                        tags$tr(
                                          tags$th(width = "20%", "指标名称"),
                                          tags$th(width = "15%", "列名"),
                                          tags$th(width = "65%", "说明")
                                        )
                                      ),
                                      tags$tbody(
                                        tags$tr(
                                          tags$td(tags$strong("log2FoldChange")),
                                          tags$td(tags$code("log2FoldChange")),
                                          tags$td("log2倍数变化值，正值表示上调，负值表示下调。绝对值越大，差异越显著。")
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("P值")),
                                          tags$td(tags$code("pvalue")),
                                          tags$td("原始统计显著性P值，未进行多重检验校正。")
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("校正P值 (padj/FDR)")),
                                          tags$td(tags$code("padj")),
                                          tags$td(tags$span(class = "text-primary", tags$strong("BH方法校正后的P值，用于控制假发现率(FDR)。")),
                                               tags$br(),
                                               "这是推荐的筛选指标。当 padj < 0.05 时，表示假阳性率控制在5%以内。")
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("T统计量")),
                                          tags$td(tags$code("t_stat")),
                                          tags$td("moderated t统计量，用于评估差异的可靠性。")
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("基础均值")),
                                          tags$td(tags$code("baseMean")),
                                          tags$td("所有样本的归一化counts平均值。")
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("logCPM")),
                                          tags$td(tags$code("logCPM")),
                                          tags$td("log2转换的每百万reads数(CPM)，用于评估表达水平。")
                                        )
                                      )
                                    )
                                  )
                                )
                              ),
                              column(12,
                                wellPanel(
                                  h4("🔧 分析参数说明", style = "color: #337ab7;"),
                                  tags$div(
                                    style = "padding: 15px;",
                                    tags$table(
                                      class = "table table-striped table-bordered",
                                      tags$thead(
                                        tags$tr(
                                          tags$th(width = "25%", "参数名称"),
                                          tags$th(width = "20%", "默认值"),
                                          tags$th(width = "55%", "说明")
                                        )
                                      ),
                                      tags$tbody(
                                        tags$tr(
                                          tags$td(tags$strong("显著性指标")),
                                          tags$td(tags$code("padj")),
                                          tags$td("用于筛选差异基因的P值类型：", tags$code("padj"), "（推荐）或 ", tags$code("pvalue"))
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("P阈值")),
                                          tags$td(tags$code("0.05")),
                                          tags$td("显著性阈值，P值小于该值的基因被认为是差异表达基因。")
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("FC阈值")),
                                          tags$td(tags$code("1")),
                                          tags$td("log2倍数变化阈值，绝对值大于该值的基因被认为是差异表达基因。", tags$br(),
                                               tags$em("注：log2FC = 1 表示2倍变化，log2FC = 2 表示4倍变化"))
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("分析方法")),
                                          tags$td(tags$span(class = "label label-success", "自动选择")),
                                          tags$td(HTML("<ul><li><strong>limma-voom</strong>: 每组样本数 ≥ 3 时使用（推荐）</li><li><strong>edgeR</strong>: 每组样本数 < 3 时使用</li></ul>"))
                                        ),
                                        tags$tr(
                                          tags$td(tags$strong("edgeR离散度")),
                                          tags$td(tags$code("0.1")),
                                          tags$td("edgeR方法的离散度参数，仅在样本重复数少时使用。")
                                        )
                                      )
                                    )
                                  )
                                )
                              ),
                              column(12,
                                wellPanel(
                                  h4("💡 筛选建议", style = "color: #337ab7;"),
                                  tags$div(
                                    style = "padding: 15px;",
                                    HTML("<ul>
                                      <li><strong>严格筛选</strong>: <code>padj < 0.05</code> 且 <code>|log2FC| > 1</code>
                                        <ul>
                                          <li>适合发表和后续实验验证</li>
                                          <li>假阳性率低（< 5%）</li>
                                          <li>可能遗漏一些真实差异基因</li>
                                        </ul>
                                      </li>
                                      <li><strong>宽松筛选</strong>: <code>pvalue < 0.05</code> 且 <code>|log2FC| > 0.5</code>
                                        <ul>
                                          <li>适合探索性分析</li>
                                          <li>可获得更多候选基因</li>
                                          <li>假阳性率较高，需要进一步验证</li>
                                        </ul>
                                      </li>
                                      <li><strong>推荐流程</strong>:
                                        <ul>
                                          <li>首先使用 <code>padj</code> 筛选获得高可信度基因集</li>
                                          <li>然后结合生物学意义和文献报道进行综合判断</li>
                                          <li>对于关键基因，建议进行qPCR等实验验证</li>
                                        </ul>
                                      </li>
                                    </ul>")
                                  )
                                )
                              ),
                              column(12,
                                wellPanel(
                                  h4("📚 统计方法说明", style = "color: #337ab7;"),
                                  tags$div(
                                    style = "padding: 15px;",
                                    tags$h5(tags$strong("limma-voom 方法")),
                                    tags$p("适用于样本重复数充足的情况（每组 ≥ 3 个样本）。"),
                                    HTML("<ul>
                                      <li>VOOM变换：将counts数据转换为适合线性模型的形式</li>
                                      <li>线性建模：使用limma的线性模型进行差异分析</li>
                                      <li>经验贝叶斯：平滑方差估计，提高统计效力</li>
                                      <li>优势： <span class='text-success'>统计效力高、假阳性率低、适合复杂实验设计</span></li>
                                    </ul>"),
                                    tags$h5(tags$strong("edgeR 方法")),
                                    tags$p("适用于样本重复数较少的情况（每组 < 3 个样本）。"),
                                    HTML("<ul>
                                      <li>基于负二项分布：直接对counts数据建模</li>
                                      <li>精确检验：使用exactTest进行两组比较</li>
                                      <li>离散度估计：当有重复时自动估计，无重复时使用固定值</li>
                                      <li>优势： <span class='text-warning'>适合小样本、无需VOOM变换</span></li>
                                    </ul>")
                                  )
                                )
                              )
                            )
                   ),

                   tabPanel("🌋 火山图", icon = icon("chart-area"),
                            fluidRow(
                              column(9,
                                     plotlyOutput("interactive_volcano", height = "600px"),
                                     tags$br(),
                                     wellPanel(
                                       h4("📤 导出火山图"),
                                       splitLayout(
                                         numericInput("export_width", "宽度 (英寸)", 10, min = 5, max = 20),
                                         numericInput("export_height", "高度 (英寸)", 8, min = 5, max = 20)
                                       ),
                                       radioButtons("export_format", "导出格式",
                                                    choices = c("PNG" = "png", "PDF" = "pdf", "SVG" = "svg"),
                                                    selected = "png", inline = TRUE),
                                       downloadButton("download_volcano", "📥 下载火山图",
                                                      class = "btn-success", style = "width:100%")
                                     ),
                                     tags$br(),
                                     wellPanel(
                                       h4("🤖 基因助手查询"),
                                       textAreaInput("gene_assistant_input", "基因相关问题查询",
                                                    placeholder = "例如: 请帮我查找与细胞周期调控相关的关键基因\n或者: 解释TP53在肿瘤发生中的作用\n或者: 列出常见的免疫检查点基因",
                                                    rows = 3),
                                       actionButton("ask_gene_assistant", "咨询基因助手",
                                                    class = "btn-info", style = "width:100%"),
                                       tags$hr(),
                                       h4("🔍 查询结果"),
                                       div(style = "height: 400px; overflow-y: auto; border: 1px solid #ddd; padding: 10px; border-radius: 5px; background-color: #f8f9fa;",
                                           verbatimTextOutput("gene_assistant_output")
                                       )
                                     )
                              ),
                              column(3,
                                     wellPanel(
                                       h4("🎨 火山图设置"),

                                       tags$hr(),
                                       h4("🔍 基因标签设置"),
                                       textInput("custom_genes_input", "自定义显示基因 (逗号分隔)",
                                                 placeholder = "例如: TP53, MYC, EGFR"),
                                       actionButton("show_custom_genes", "显示自定义基因",
                                                    class = "btn-primary", style = "width:100%"),
                                       actionButton("clear_custom_genes", "清除自定义基因",
                                                    class = "btn-warning", style = "width:100%; margin-top: 5px;"),

                                       tags$hr(),
                                       h4("🔧 标签样式设置"),
                                       sliderInput("gene_label_size", "标签字体大小", 8, 16, 10),
                                       checkboxInput("gene_label_bold", "标签加粗", value = FALSE),
                                       colourInput("gene_label_color", "标签颜色", "#2c3e50"),

                                       tags$hr(),
                                       h4("🔧 点样式设置"),
                                       sliderInput("point_size", "点大小", 5, 15, 6),
                                       sliderInput("point_alpha", "点透明度", 0.1, 1, 0.7),

                                       tags$hr(),
                                       h4("📊 坐标轴设置"),
                                       selectInput("y_axis_type", "Y轴类型",
                                                   choices = c("-log10(pvalue)" = "pvalue",
                                                               "-log10(padj)" = "padj"),
                                                   selected = "pvalue"),
                                       splitLayout(
                                         numericInput("x_axis_min", "X轴最小值", -10),
                                         numericInput("x_axis_max", "X轴最大值", 15)
                                       ),
                                       sliderInput("axis_label_size", "坐标轴标签大小", 10, 20, 14),
                                       sliderInput("axis_title_size", "坐标轴标题大小", 12, 24, 16),

                                       tags$hr(),
                                       h4("🎨 颜色设置"),
                                       colourInput("up_color", "上调颜色", "#e74c3c"),
                                       colourInput("down_color", "下调颜色", "#3498db"),

                                       tags$hr(),
                                       checkboxInput("show_grid", "显示背景方格", value = TRUE)
                                     )
                              )
                            )
                   ),

                   tabPanel("🧬 KEGG富集", icon = icon("project-diagram"),
                            tabsetPanel(
                              tabPanel("基于差异基因",
                                       sidebarLayout(
                                         sidebarPanel(
                                           width = 3,
                                           class = "sidebar-panel",
                                           h4("🔧 分析设置"),
                                           radioButtons("kegg_direction", "方向",
                                                        choices = c("上调" = "Up", "下调" = "Down", "全部" = "All"),
                                                        selected = "Up"),
                                           selectInput("kegg_species", "物种代码", choices = c("hsa", "mmu")),
                                           numericInput("kegg_p", "P Cutoff", 0.05),
                                           actionButton("run_kegg", "运行 KEGG", class = "btn-warning"),

                                           tags$hr(),
                                           h4("🎨 绘图样式"),
                                           selectInput("kegg_x_axis", "X轴显示",
                                                       choices = c("基因数量" = "Count",
                                                                 "富集倍数" = "FoldEnrichment"),
                                                       selected = "Count"),
                                           sliderInput("kegg_font_size", "字体大小", 10, 20, 12),
                                           checkboxInput("kegg_bold", "字体加粗", value = FALSE),
                                           colourInput("kegg_low_col", "低显著颜色 (Low)", "#3498db"),
                                           colourInput("kegg_high_col", "高显著颜色 (High)", "#e74c3c"),

                                           tags$hr(),
                                           h5("📤 导出图表"),
                                           radioButtons("kegg_export_format", "导出格式",
                                                       choices = c("PNG" = "png", "PDF" = "pdf", "SVG" = "svg"),
                                                       selected = "png", inline = TRUE),
                                           downloadButton("download_kegg_plot", "下载KEGG图表", class="btn-sm btn-success"),
                                           tags$hr(),
                                           downloadButton("download_kegg", "下载结果表", class="btn-sm btn-light"),

                                           tags$hr(),

                                           # 🤖 AI解读区域
                                           div(
                                             class = "well",
                                             style = paste0(
                                               "background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); ",
                                               "color: white; padding: 20px; border-radius: 12px; ",
                                               "box-shadow: 0 4px 15px rgba(240, 147, 251, 0.4);"
                                             ),
                                             h5("🤖 AI智能解读", style = "color: white; margin-top: 0;"),
                                             p("让智谱AI帮您深入理解KEGG通路富集结果",
                                               style = "color: rgba(255,255,255,0.9); font-size: 13px; margin-bottom: 10px;"),
                                             p(class="text-muted", style = "color: rgba(255,255,255,0.7); font-size: 12px; margin-bottom: 10px;",
                                               "• 专业解读KEGG通路富集\n• 揭示信号通路和代谢途径\n• 提供疾病关联和研究价值"),

                                             tags$hr(style = "margin: 10px 0; border-color: rgba(255,255,255,0.3);"),

                                             # 研究主题输入
                                             textInput("kegg_research_topic",
                                                      "🎯 研究主题（可选）",
                                                      placeholder = "例如：肺癌免疫治疗机制、糖尿病并发症等",
                                                      value = ""),
                                             helpText(class="text-muted", style = "color: rgba(255,255,255,0.6); font-size: 11px;",
                                                      "提供您的研究主题，AI将提供更有针对性的解读"),

                                             selectInput("kegg_ai_model", "AI模型",
                                                        choices = c(
                                                          "GLM-4-Air (推荐)" = "glm-4-air",
                                                          "GLM-4-Flash (快速)" = "glm-4-flash"
                                                        ),
                                                        selected = "glm-4-air"),

                                             actionButton("ai_interpret_kegg", "🚀 启动AI解读",
                                                         class = "btn-light btn-sm",
                                                         icon = icon("robot"),
                                                         style = "width: 100%; margin-top: 10px;")
                                           )
                                         ),
                                         mainPanel(
                                           class = "main-panel",
                                           plotOutput("kegg_dotplot", height = "600px"),
                                           tags$br(),
                                           h4("详细结果表 (ID已转Symbol)"),
                                           DT::dataTableOutput("kegg_table"),

                                           tags$hr(),

                                           # 🤖 AI解读结果输出
                                           uiOutput("ai_kegg_interpretation")
                                         )
                                       )
                              ),

                              tabPanel("基于基因列表",
                                       sidebarLayout(
                                         sidebarPanel(
                                           width = 3,
                                           class = "sidebar-panel",
                                           h4("🔧 单列基因 KEGG 分析"),

                                           # 主基因列表（如交集基因）
                                           fileInput("single_gene_file", "上传基因列表 (CSV - 待分析基因)",
                                                     accept = c(".csv"),
                                                     placeholder = "包含 SYMBOL 列的文件"),
                                           helpText(class="text-muted",
                                                    "CSV 文件应包含一列名为 'SYMBOL' 的基因符号"),

                                           tags$hr(),
                                           # 🆕 背景基因集设置（支持多文件）
                                           h5("🧬 背景基因集设置 (可选)"),
                                           helpText(class="text-info",
                                                    "💡 如果你的基因是两个数据集的交集，请上传两个数据集的全集"),
                                           helpText(class="text-muted small",
                                                    "💡 系统将自动计算所有上传文件的基因交集作为Universe"),

                                           # 动态文件上传区域
                                           uiOutput("background_files_upload_ui"),

                                           # 添加/删除文件按钮
                                           fluidRow(
                                             column(6,
                                               actionButton("add_background_file", "➕ 添加更多文件",
                                                          class = "btn-info btn-sm")
                                             ),
                                             column(6,
                                               actionButton("remove_background_file", "➖ 移除文件",
                                                          class = "btn-warning btn-sm")
                                             )
                                           ),

                                           # 文件状态显示
                                           uiOutput("background_files_status"),

                                           # 列名设置（动态生成）
                                           uiOutput("background_files_columns"),

                                           # Universe预览
                                           uiOutput("background_universe_preview"),

                                           conditionalPanel(
                                               condition = "input.background_gene_count_kegg == null",
                                               numericInput("background_gene_count_kegg", "或手动输入背景基因数量",
                                                           value = NA, min = 100, step = 100),
                                               helpText(class="text-muted small",
                                                        "留空则使用全基因组作为背景。例如：3000")
                                           ),

                                           tags$hr(),
                                           selectInput("single_gene_species", "物种代码",
                                                       choices = c("Human" = "hsa", "Mouse" = "mmu")),
                                           numericInput("single_gene_kegg_p", "P Cutoff", 0.05),
                                           actionButton("run_single_gene_kegg", "运行 KEGG", class = "btn-primary"),

                                           tags$hr(),
                                           h4("🎨 绘图样式"),
                                           selectInput("single_gene_kegg_x_axis", "X轴显示",
                                                       choices = c("基因数量" = "Count",
                                                                 "富集倍数" = "FoldEnrichment"),
                                                       selected = "Count"),
                                           sliderInput("single_gene_kegg_font_size", "字体大小", 10, 20, 12),
                                           checkboxInput("single_gene_kegg_bold", "字体加粗", value = FALSE),
                                           colourInput("single_gene_kegg_low_col", "低显著颜色 (Low)", "#3498db"),
                                           colourInput("single_gene_kegg_high_col", "高显著颜色 (High)", "#e74c3c"),

                                           tags$hr(),
                                           h5("📤 导出图表"),
                                           radioButtons("single_gene_kegg_export_format", "导出格式",
                                                       choices = c("PNG" = "png", "PDF" = "pdf", "SVG" = "svg"),
                                                       selected = "png", inline = TRUE),
                                           downloadButton("download_single_gene_kegg_plot", "下载KEGG图表", class="btn-sm btn-success"),
                                           tags$hr(),
                                           downloadButton("download_single_gene_kegg", "下载结果表", class="btn-sm btn-light")
                                         ),
                                         mainPanel(
                                           class = "main-panel",
                                           plotOutput("single_gene_kegg_dotplot", height = "600px"),
                                           tags$br(),
                                           h4("详细结果表 (ID已转Symbol)"),
                                           DT::dataTableOutput("single_gene_kegg_table")
                                         )
                                       )
                              )
                            )
                   ),

                   tabPanel("🧬 GO分析", icon = icon("dna"),
                            tabsetPanel(
                              tabPanel("基于差异基因",
                                       sidebarLayout(
                                         sidebarPanel(
                                           width = 3,
                                           class = "sidebar-panel",
                                           h4("🔧 分析设置"),
                                           radioButtons("go_direction", "方向",
                                                        choices = c("上调" = "Up", "下调" = "Down", "全部" = "All"),
                                                        selected = "Up"),
                                           selectInput("go_species", "物种代码", choices = c("hsa", "mmu")),
                                           selectInput("go_ontology", "GO类别",
                                                       choices = c("生物过程" = "BP",
                                                                   "分子功能" = "MF",
                                                                   "细胞组分" = "CC"),
                                                       selected = "BP"),
                                           numericInput("go_p", "P Cutoff", 0.05),
                                           numericInput("go_top_n", "显示Top N", 20, min = 5, max = 50),
                                           actionButton("run_go", "运行 GO分析", class = "btn-warning"),

                                           tags$hr(),
                                           h4("🎨 绘图样式"),
                                           selectInput("go_x_axis", "X轴属性",
                                                       choices = c("Gene Ratio" = "GeneRatio",
                                                                   "Background Ratio" = "BgRatio",
                                                                   "Gene Count" = "Count",
                                                                   "Fold Enrichment" = "FoldEnrichment"),
                                                       selected = "GeneRatio"),
                                           sliderInput("go_font_size", "字体大小", 10, 20, 12),
                                           checkboxInput("go_bold", "字体加粗", value = FALSE),
                                           colourInput("go_low_col", "低显著颜色 (Low)", "#3498db"),
                                           colourInput("go_high_col", "高显著颜色 (High)", "#e74c3c"),

                                           tags$hr(),
                                           h5("📤 导出图表"),
                                           radioButtons("go_export_format", "导出格式",
                                                       choices = c("PNG" = "png", "PDF" = "pdf", "SVG" = "svg"),
                                                       selected = "png", inline = TRUE),
                                           downloadButton("download_go_plot", "下载GO图表", class="btn-sm btn-success"),
                                           tags$hr(),
                                           downloadButton("download_go", "下载结果表", class="btn-sm btn-light"),

                                           tags$hr(),

                                           # 🤖 AI解读区域
                                           div(
                                             class = "well",
                                             style = paste0(
                                               "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); ",
                                               "color: white; padding: 20px; border-radius: 12px; ",
                                               "box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);"
                                             ),
                                             h5("🤖 AI智能解读", style = "color: white; margin-top: 0;"),
                                             p("让智谱AI帮您深入理解GO富集分析结果的生物学意义",
                                               style = "color: rgba(255,255,255,0.9); font-size: 13px; margin-bottom: 10px;"),
                                             p(class="text-muted", style = "color: rgba(255,255,255,0.7); font-size: 12px; margin-bottom: 10px;",
                                               "• 专业解读GO富集结果\n• 揭示生物学过程和功能\n• 提供研究价值和建议"),

                                             tags$hr(style = "margin: 10px 0; border-color: rgba(255,255,255,0.3);"),

                                             # 研究主题输入
                                             textInput("go_research_topic",
                                                      "🎯 研究主题（可选）",
                                                      placeholder = "例如：肿瘤发生机制、神经退行性疾病等",
                                                      value = ""),
                                             helpText(class="text-muted", style = "color: rgba(255,255,255,0.6); font-size: 11px;",
                                                      "提供您的研究主题，AI将提供更有针对性的解读"),

                                             selectInput("go_ai_model", "AI模型",
                                                        choices = c(
                                                          "GLM-4-Air (推荐)" = "glm-4-air",
                                                          "GLM-4-Flash (快速)" = "glm-4-flash"
                                                        ),
                                                        selected = "glm-4-air"),

                                             actionButton("ai_interpret_go", "🚀 启动AI解读",
                                                         class = "btn-light btn-sm",
                                                         icon = icon("robot"),
                                                         style = "width: 100%; margin-top: 10px;")
                                           )
                                         ),
                                         mainPanel(
                                           class = "main-panel",
                                           plotOutput("go_dotplot", height = "600px"),
                                           tags$br(),
                                           h4("详细结果表"),
                                           DT::dataTableOutput("go_table"),

                                           tags$hr(),

                                           # 🤖 AI解读结果输出
                                           uiOutput("ai_go_interpretation")
                                         )
                                       )
                              ),

                              tabPanel("基于基因列表",
                                       sidebarLayout(
                                         sidebarPanel(
                                           width = 3,
                                           class = "sidebar-panel",
                                           h4("🔧 单列基因 GO 分析"),

                                           # 主基因列表（如交集基因）
                                           fileInput("single_gene_go_file", "上传基因列表 (CSV - 待分析基因)",
                                                     accept = c(".csv"),
                                                     placeholder = "包含 SYMBOL 列的文件"),
                                           helpText(class="text-muted",
                                                    "CSV 文件应包含一列名为 'SYMBOL' 的基因符号"),

                                           tags$hr(),
                                           # 🆕 背景基因集设置
                                           h5("🧬 背景基因集设置 (可选)"),
                                           helpText(class="text-info",
                                                    "💡 如果你的基因是两个数据集的交集，请上传两个数据集的全集"),
                                           fileInput("background_gene_file_go", "上传背景基因集 (CSV)",
                                                     accept = c(".csv")),
                                           helpText(class="text-muted small",
                                                    "包含所有检测到的基因（如两个数据集的并集）"),

                                           conditionalPanel(
                                               condition = "input.background_gene_file_go == null",
                                               numericInput("background_gene_count_go", "或手动输入背景基因数量",
                                                           value = NA, min = 100, step = 100),
                                               helpText(class="text-muted small",
                                                        "留空则使用全基因组作为背景。例如：3000")
                                           ),

                                           tags$hr(),
                                           selectInput("single_gene_species_go", "物种代码",
                                                       choices = c("Human" = "hsa", "Mouse" = "mmu")),
                                           selectInput("single_gene_go_ontology", "GO类别",
                                                       choices = c("生物过程" = "BP",
                                                                   "分子功能" = "MF",
                                                                   "细胞组分" = "CC"),
                                                       selected = "BP"),
                                           numericInput("single_gene_go_p", "P Cutoff", 0.05),
                                           actionButton("run_single_gene_go", "运行 GO分析", class = "btn-primary"),

                                           tags$hr(),
                                           h4("🎨 绘图样式"),
                                           selectInput("single_gene_go_x_axis", "X轴属性",
                                                       choices = c("Gene Ratio" = "GeneRatio",
                                                                   "Background Ratio" = "BgRatio",
                                                                   "Gene Count" = "Count",
                                                                   "Fold Enrichment" = "FoldEnrichment"),
                                                       selected = "GeneRatio"),
                                           sliderInput("single_gene_go_font_size", "字体大小", 10, 20, 12),
                                           checkboxInput("single_gene_go_bold", "字体加粗", value = FALSE),
                                           colourInput("single_gene_go_low_col", "低显著颜色 (Low)", "#3498db"),
                                           colourInput("single_gene_go_high_col", "高显著颜色 (High)", "#e74c3c"),

                                           tags$hr(),
                                           h5("📤 导出图表"),
                                           radioButtons("single_gene_go_export_format", "导出格式",
                                                       choices = c("PNG" = "png", "PDF" = "pdf", "SVG" = "svg"),
                                                       selected = "png", inline = TRUE),
                                           downloadButton("download_single_gene_go_plot", "下载GO图表", class="btn-sm btn-success"),
                                           tags$hr(),
                                           downloadButton("download_single_gene_go", "下载结果表", class="btn-sm btn-light")
                                         ),
                                         mainPanel(
                                           class = "main-panel",
                                           plotOutput("single_gene_go_dotplot", height = "600px"),
                                           tags$br(),
                                           h4("详细结果表"),
                                           DT::dataTableOutput("single_gene_go_table")
                                         )
                                       )
                              )
                            )
                   ),

                   tabPanel("🌊 GSEA分析", icon = icon("water"),
                            sidebarLayout(
                              sidebarPanel(
                                width = 3,
                                class = "sidebar-panel",
                                h4("🔧 GSEA 设置"),
                                fileInput("gmt_file", "上传 GMT 文件", accept = c(".gmt")),
                                helpText(class="text-muted", "支持大文件上传 (Max 100MB)"),

                                selectInput("gsea_id_type", "GMT中的ID类型",
                                            choices = c("Gene Symbol (推荐)" = "SYMBOL",
                                                       "Entrez ID" = "ENTREZID"),
                                            selected = "SYMBOL"),
                                helpText(class="text-info small",
                                         "💡 推荐使用Symbol以在图上显示基因名称（如Csf3）"),

                                numericInput("gsea_pvalue", "Pvalue Cutoff", 0.05),
                                actionButton("run_gsea", "运行 GSEA", class = "btn-primary"),
                                tags$hr(),

                                h4("🎨 绘图调整"),
                                p(class="text-muted", "拖动滑块调整统计值位置"),
                                sliderInput("gsea_stats_x", "统计值水平位置 (X)", min = 0, max = 1, value = 0.6, step = 0.05),
                                sliderInput("gsea_stats_y", "统计值垂直位置 (Y)", min = 0, max = 1, value = 0.8, step = 0.05),

                                tags$hr(),

                                h4("🧬 基因展示设置"),
                                p(class="text-muted", "在GSEA图上标记Leading Edge基因"),
                                numericInput("gsea_top_genes", "自动标记Top N基因", value = 20, min = 5, max = 100, step = 5),
                                selectInput("gsea_gene_order", "基因排序方式",
                                            choices = c("🔥 GSEA Leading Edge基因（顶峰基因）" = "leading_edge",
                                                       "按log2FoldChange绝对值" = "abs_logFC",
                                                       "按log2FoldChange值" = "logFC",
                                                       "按基因在ranked list中的位置" = "rank"),
                                            selected = "leading_edge"),
                                textInput("custom_gene_list", "自定义基因列表 (可选)",
                                          placeholder = "例如: Entpd8, Htr2a, Nt5e, Actn3"),
                                helpText(class="text-muted small",
                                         "留空则自动显示Top N基因。支持逗号、分号或空格分隔。"),

                                tags$hr(),

                                h4("📊 多通路可视化"),
                                p(class="text-muted", "使用gseaRidge展示多个通路的基因分布"),
                                numericInput("gsea_ridge_pathways", "选择Top N通路", value = 10, min = 3, max = 20, step = 1),
                                checkboxInput("show_gsea_ridge", "显示山脊图", value = FALSE),

                                tags$hr(),

                                h4("📤 GSEA结果导出"),
                                div(class = "gsea-export-section",
                                    p(strong("导出选项:")),
                                    radioButtons("gsea_export_type", "导出内容",
                                                 choices = c("完整结果表" = "full",
                                                             "显著结果表 (P < 0.05)" = "significant",
                                                             "Top 50 通路" = "top50"),
                                                 selected = "full"),
                                    numericInput("gsea_export_topn", "Top N 通路 (仅Top N模式)",
                                                 value = 50, min = 10, max = 200, step = 10),
                                    downloadButton("download_gsea_full", "📥 下载完整结果",
                                                   class = "btn-success btn-sm",
                                                   style = "width:100%; margin-bottom:5px;"),
                                    downloadButton("download_gsea_sig", "📥 下载显著结果",
                                                   class = "btn-warning btn-sm",
                                                   style = "width:100%; margin-bottom:5px;"),
                                    downloadButton("download_gsea_top", "📥 下载Top N结果",
                                                   class = "btn-info btn-sm",
                                                   style = "width:100%; margin-bottom:5px;"),

                                    tags$hr(style = "margin: 10px 0;"),

                                    # SVG下载按钮
                                    p(class="text-primary", style="font-weight:bold", "📊 导出图表 (SVG格式)"),
                                    downloadButton("download_gsea_plot_svg", "📥 下载GSEA图 (SVG)",
                                                   class = "btn-primary btn-sm",
                                                   style = "width:100%; margin-bottom:5px;"),
                                    downloadButton("download_gsea_ridge_svg", "📥 下载山脊图 (SVG)",
                                                   class = "btn-primary btn-sm",
                                                   style = "width:100%;")
                                ),

                                tags$hr(),
                                p(class="text-muted", "注：GSEA 基于 log2FoldChange 排序。SVG格式可无损缩放，适合出版。")
                              ),
                              mainPanel(
                                class = "main-panel",
                                fluidRow(
                                  column(12,
                                         h4("GseaVis 可视化"),
                                         p(class="text-muted", "点击下方表格中的某一行，即可显示对应的 GSEA 图，图中会自动标记Leading Edge基因（红色斜体标注）。"),
                                         plotOutput("gsea_plot", height = "600px")
                                  )
                                ),
                                tags$hr(),
                                # 山脊图输出
                                conditionalPanel(
                                  condition = "input.show_gsea_ridge",
                                  fluidRow(
                                    column(12,
                                           h4("GseaRidge 多通路山脊图"),
                                           p(class="text-muted", "展示Top N个GSEA通路的基因分布山脊图"),
                                           plotOutput("gsea_ridge_plot", height = "800px")
                                    )
                                  ),
                                  tags$hr()
                                ),
                                h4("GSEA 结果表"),
                                DT::dataTableOutput("gsea_table")
                              )
                            )
                   ),

                   tabPanel("🔬 转录因子活性", icon = icon("dna"),
                            sidebarLayout(
                              sidebarPanel(
                                width = 3,
                                class = "sidebar-panel",
                                h4("🧬 TF 活性推断"),
                                helpText(class="text-muted", "使用 decoupleR 推断转录因子活性。"),

                                # 🆕 算法选择
                                selectInput("tf_method", "推断算法",
                                            choices = c(
                                              "ULM (单变量线性模型)" = "ulm",
                                              "MLM (多变量线性模型)" = "mlm",
                                              "WMEAN (加权平均)" = "wmean",
                                              "WSUM (加权求和)" = "wsum"
                                            ),
                                            selected = "ulm"),
                                helpText(class="text-muted small", "ULM: 快速准确 | MLM: 考虑共调控 | WMEAN/WSUM: 简单加权"),

                                numericInput("tf_min_size", "TF靶基因最小数量", 5, min = 1, step = 1),

                                tags$hr(),
                                actionButton("run_tf_activity", "运行 TF 活性分析", class = "btn-info"),
                                tags$hr(),

                                h4("🎨 绘图样式"),
                                sliderInput("tf_top_n", "显示 Top N 个TF", 10, 50, 20),
                                colourInput("tf_active_col", "激活颜色", "#e74c3c"),
                                colourInput("tf_inactive_col", "失活颜色", "#3498db"),

                                tags$hr(),
                                h5("🎯 网络图自定义"),
                                sliderInput("tf_network_node_size", "节点大小倍数", 0.5, 3, 1, step = 0.1),
                                sliderInput("tf_network_label_size", "标签大小", 2, 6, 3.5, step = 0.5),
                                colourInput("tf_tf_node_col", "TF节点颜色", "#2ecc71"),
                                colourInput("tf_consistent_act_col", "一致-激活节点", "#27ae60"),
                                colourInput("tf_consistent_rep_col", "一致-抑制节点", "#2980b9"),
                                colourInput("tf_inconsistent_act_col", "不一致-激活节点", "#c0392b"),
                                colourInput("tf_inconsistent_rep_col", "不一致-抑制节点", "#2c3e50"),
                                colourInput("tf_neutral_col", "未知节点", "#95a5a6"),

                                tags$hr(),
                                h5("🎯 散点图自定义"),
                                sliderInput("tf_scatter_point_size", "散点大小", 1, 6, 3, step = 0.5),
                                sliderInput("tf_scatter_alpha", "散点透明度", 0.1, 1, 0.7, step = 0.1),
                                sliderInput("tf_scatter_label_size", "标签大小", 2, 6, 3, step = 0.5),
                                sliderInput("tf_scatter_n_labels", "显示标签数量", 0, 30, 15, step = 1),

                                tags$hr(),
                                downloadButton("download_tf_results", "下载 TF 结果表", class="btn-sm btn-light")
                              ),
                              mainPanel(
                                class = "main-panel",
                                fluidRow(
                                  column(12,
                                         h4("TF 活性变化柱状图 (Treatment vs Control)"),
                                         plotOutput("tf_activity_bar_plot", height = "600px")
                                  )
                                ),
                                tags$hr(),
                                h4("转录因子活性结果表"),
                                DT::dataTableOutput("tf_activity_table"),

                                tags$hr(),
                                h4("所选 TF 靶基因调控一致性散点图"),
                                p(class="text-muted", "图中的颜色显示了靶基因的实际差异表达方向与 TF 调控网络预设方向的匹配程度。"),
                                # 🆕 一致性统计
                                uiOutput("tf_consistency_summary"),
                                tags$br(),
                                plotOutput("tf_target_plot", height = "600px"),

                                tags$hr(),
                                h4("所选 TF 靶基因调控网络"),
                                p(class="text-muted", "显示TF与其靶基因的调控关系。红色=激活，蓝色=抑制，实线=一致，虚线=不一致。"),
                                # 🆕 交互式网络图
                                plotlyOutput("tf_network_plot_interactive", height = "700px"),
                                # 静态图用于导出
                                hidden(plotOutput("tf_network_plot_static", height = "700px")),
                                tags$br(),
                                checkboxInput("use_static_network", "使用静态图（用于SVG导出）", FALSE),
                                # 🆕 SVG下载按钮
                                downloadButton("download_tf_network_svg", "📥 下载网络图 (SVG)", class = "btn-sm btn-primary"),
                                downloadButton("download_tf_scatter_svg", "📥 下载散点图 (SVG)", class = "btn-sm btn-primary"),

                                # 🆕 数据导出按钮
                                downloadButton("download_tf_scatter_data", "💾 导出靶基因数据 (CSV)", class = "btn-sm btn-success"),

                                tags$hr(),
                                h4("所选 TF 的靶基因详细信息"),
                                p(class="text-muted", "请在上方 '转录因子活性结果表' 中点击一行，查看其靶基因。"),
                                DT::dataTableOutput("tf_target_table")
                              )
                            )
                   ),

                   tabPanel("🔷 韦恩图", icon = icon("object-group"),
                            sidebarLayout(
                              sidebarPanel(
                                width = 3,
                                class = "sidebar-panel",
                                h4("🔷 韦恩图设置"),

                                numericInput("venn_sets", "集合数量",
                                             value = 2, min = 2, max = 5, step = 1),

                                uiOutput("venn_inputs"),

                                tags$hr(),
                                h4("🎨 绘图样式"),
                                colourInput("venn_color1", "集合1颜色", "#1f77b4"),
                                colourInput("venn_color2", "集合2颜色", "#ff7f0e"),
                                colourInput("venn_color3", "集合3颜色", "#2ca02c"),
                                colourInput("venn_color4", "集合4颜色", "#d62728"),
                                colourInput("venn_color5", "集合5颜色", "#9467bd"),

                                sliderInput("venn_alpha", "透明度", 0.3, 0.8, 0.5),

                                tags$hr(),
                                actionButton("generate_venn", "生成韦恩图",
                                             class = "btn-primary btn-lg",
                                             width = "100%")
                              ),

                              mainPanel(
                                class = "main-panel",
                                fluidRow(
                                  column(12,
                                         h4("交互式韦恩图"),
                                         p(class="text-muted",
                                           "点击图中的交集区域查看详细信息，交集内容会自动复制到剪贴板。"),

                                         plotOutput("venn_plot",
                                                    click = "venn_click",
                                                    height = "500px"),

                                         tags$br(),

                                         uiOutput("venn_result_ui"),

                                         tags$hr(),

                                         h4("详细交集数据"),
                                         DT::dataTableOutput("venn_table")
                                  )
                                )
                              )
                            )
                   ),

                   # 🆕 通路活性分析
                   tabPanel("🛤️ 通路活性", icon = icon("project-diagram"),
                            sidebarLayout(
                              sidebarPanel(
                                width = 3,
                                class = "sidebar-panel",
                                h4("🧬 KEGG 通路活性推断"),
                                helpText(class="text-muted", "基于 KEGG 富集结果推断通路活性。"),

                                tags$hr(),

                                # 方法选择
                                selectInput("pathway_method", "推断方法",
                                            choices = c(
                                              "ULM (推荐)" = "ulm",
                                              "WMEAN (加权平均)" = "wmean"
                                              # "AUCell" = "aucell",  # ❌ 需要多样本表达矩阵
                                              # "GSVA" = "gsva"      # ❌ 需要多样本表达矩阵
                                            ),
                                            selected = "ulm"),

                                # 方法说明
                                uiOutput("pathway_method_info"),

                                # 警告信息
                                helpText(class="text-muted",
                                         style = "color: #f39c12; font-size: 11px;",
                                         "⚠️ 注意: AUCell和GSVA方法需要原始表达矩阵，暂不可用。"),

                                tags$hr(),

                                # 最小基因集大小
                                numericInput("pathway_minsize", "最小基因集大小",
                                            value = 5, min = 3, max = 50),

                                helpText(class="text-muted",
                                         "通路至少包含的基因数量"),

                                tags$hr(),

                                # 显示数量
                                sliderInput("pathway_top_n", "显示 Top N 通路",
                                           min = 5, max = 50, value = 20, step = 5),

                                tags$hr(),

                                # 颜色设置
                                colourInput("pathway_active_col", "激活通路颜色",
                                           value = "#e74c3c"),
                                colourInput("pathway_inactive_col", "抑制通路颜色",
                                           value = "#3498db"),

                                tags$hr(),

                                # 热图字体大小设置
                                numericInput("pathway_heatmap_fontsize", "热图字体大小",
                                            value = 10, min = 6, max = 20, step = 1),

                                helpText(class="text-muted",
                                         "调整热图中基因名和分数的字体大小"),

                                # 柱状图字体大小设置
                                numericInput("pathway_bar_fontsize", "柱状图字体大小",
                                            value = 10, min = 6, max = 20, step = 1),

                                helpText(class="text-muted",
                                         "调整柱状图中的标题、轴标签和图例字体大小"),

                                tags$hr(),

                                # 运行按钮
                                actionButton("run_pathway_activity", "🚀 运行通路活性分析",
                                            class = "btn-primary btn-block",
                                            icon = icon("play"),
                                            style = "margin-top: 10px;"),

                                # 统计摘要
                                uiOutput("pathway_summary"),

                                tags$hr(),

                                # 下载按钮
                                downloadButton("download_pathway_results", "📥 下载结果",
                                              class = "btn-success btn-block"),

                                helpText(class="text-muted",
                                         "💡 提示：请先运行 KEGG 富集分析",
                                         style = "color: #f39c12; font-size: 11px;")
                              ),
                              mainPanel(
                                class = "main-panel",

                                # 结果展示
                                tabsetPanel(
                                  id = "pathway_tabs",
                                  type = "tabs",

                                  # 算法说明
                                  tabPanel("📖 算法说明",
                                           h4("🧠 什么是通路活性分析？"),
                                           uiOutput("pathway_algorithm_intro"),

                                           tags$hr(),

                                           h4("🔬 ULM 方法原理"),
                                           uiOutput("pathway_ulm_explanation"),

                                           tags$hr(),

                                           h4("📊 结果解读指南"),
                                           uiOutput("pathway_result_guide"),

                                           tags$hr(),

                                           h4("💡 实际应用案例"),
                                           uiOutput("pathway_example_use_case"),

                                           tags$hr(),

                                           h4("❓ 常见问题"),
                                           uiOutput("pathway_faq")
                                  ),

                                  # 柱状图
                                  tabPanel("柱状图",
                                           fluidRow(
                                             column(10,
                                                    h4("通路活性排名")
                                             ),
                                             column(2,
                                                    align = "right",
                                                    downloadButton("download_pathway_bar_png",
                                                                 "📥 PNG",
                                                                 class = "btn-sm btn-primary"),
                                                    downloadButton("download_pathway_bar_svg",
                                                                 "📥 SVG",
                                                                 class = "btn-sm btn-info")
                                             )
                                           ),
                                           plotOutput("pathway_activity_bar_plot",
                                                    height = "600px"),
                                           tags$br(),
                                           h4("详细结果表"),
                                           DT::dataTableOutput("pathway_activity_table")
                                  ),

                                  # 热图
                                  tabPanel("热图",
                                           fluidRow(
                                             column(10,
                                                    h4("通路活性热图")
                                             ),
                                             column(2,
                                                    align = "right",
                                                    downloadButton("download_pathway_heatmap_png",
                                                                 "📥 PNG",
                                                                 class = "btn-sm btn-primary"),
                                                    downloadButton("download_pathway_heatmap_svg",
                                                                 "📥 SVG",
                                                                 class = "btn-sm btn-info")
                                             )
                                           ),
                                           plotOutput("pathway_activity_heatmap",
                                                    height = "600px")
                                  )
                                )
                              )
                            )
                   ),

                   # 🆕 芯片数据分析
                   tabPanel("🧬 芯片分析", icon = icon("microchip"),
                            uiOutput("chip_analysis_ui_output")
                   ),
                   # 🆕 生存分析
                   tabPanel("📈 生存分析", icon = icon("chart-line"),
                            uiOutput("survival_analysis_ui_output")
                   )
                 )
               )
             )
    ),

    navbarMenu("👤 账户", icon = icon("user-circle"),
               tabPanel("信息", uiOutput("user_info_ui")),
               tabPanel("🤖 智谱AI配置",
                        wellPanel(
                          h4("🤖 智谱AI API配置"),

                          p(class="text-muted",
                            "智谱AI（Zhipu AI）提供强大的大语言模型服务，支持专业的生物信息学分析解读。"),

                          tags$hr(),

                          # API密钥输入
                          passwordInput("zhipu_api_key_input",
                                       "智谱AI API密钥",
                                       value = load_zhipu_config(),
                                       placeholder = "输入您的智谱AI API密钥"),

                          helpText(class="text-muted",
                                   "获取API密钥：",
                                   tags$a(href="https://open.bigmodel.cn/usercenter/apikeys",
                                          target="_blank",
                                          "https://open.bigmodel.cn/usercenter/apikeys")),

                          # 模型选择
                          selectInput("zhipu_model", "选择模型",
                                     choices = c(
                                       "GLM-4-Air (推荐)" = "glm-4-air",
                                       "GLM-4-Flash (快速)" = "glm-4-flash",
                                       "GLM-4-Plus (高级)" = "glm-4-plus"
                                     ),
                                     selected = "glm-4-air"),

                          # 参数设置
                          sliderInput("zhipu_temperature", "创造性程度",
                                     min = 0, max = 1, value = 0.7, step = 0.1),

                          numericInput("zhipu_max_tokens", "最大生成长度",
                                      value = 2500, min = 500, max = 4000),

                          tags$hr(),

                          # 保存按钮
                          actionButton("save_zhipu_key", "💾 保存API配置",
                                      class = "btn-success", style = "width:100%"),

                          tags$hr(),

                          # API状态
                          h4("🔍 API状态"),
                          verbatimTextOutput("zhipu_api_status"),
                          actionButton("test_zhipu_api", "🧪 测试API连接",
                                      class = "btn-info", style = "width:100%"),

                          tags$hr(),

                          # 使用说明
                          h4("📖 使用说明"),
                          tags$div(style="background: #f8f9fa; padding: 15px; border-radius: 8px;",
                                   tags$ul(style="font-size: 13px; color: #6E6E73;",
                                           tags$li("GLM-4-Flash：快速响应，适合简单解读"),
                                           tags$li("GLM-4-Air：平衡速度和质量，性价比最高"),
                                           tags$li("GLM-4-Plus：深度分析，适合复杂推理"),
                                           tags$li("建议首次使用GLM-4-Air"),
                                           tags$li("价格：约¥0.004/次分析")
                                   )
                          )
                        )
               ),
               tabPanel("🔧 DeepSeek配置",
                        wellPanel(
                          h4("🤖 DeepSeek API配置"),
                          passwordInput("api_key_input", "DeepSeek API密钥",
                                       value = "",
                                       placeholder = "输入您的DeepSeek API密钥"),
                          helpText(class="text-muted",
                                   "获取API密钥：https://platform.deepseek.com/api_keys"),
                          actionButton("save_api_key", "保存API密钥",
                                       class = "btn-success", style = "width:100%"),
                          tags$hr(),
                          h4("🔍 API状态"),
                          verbatimTextOutput("api_status"),
                          actionButton("test_api", "测试API连接",
                                       class = "btn-info", style = "width:100%")
                        )
               ),
    )
  )
}


