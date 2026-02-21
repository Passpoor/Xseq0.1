# =====================================================
# Xseq v13.0 (Enhanced Modular Version)
# Author: 文献计量与基础医学
# Status: Complete with RNA-seq, Microarray, Single-cell Analysis Support
# =====================================================

# 设置上传大小限制（GEO SOFT/Series Matrix 可能很大，设为 2GB）
options(shiny.maxRequestSize = 2 * 1024^3)

# =====================================================
# 🔐 授权检查（在所有其他代码之前）
# =====================================================

# 加载授权模块
source("modules/license.R")
source("modules/license_ui.R")

# 生成机器码并检查授权状态
app_machine_code <- generate_machine_code()
app_license_status <- check_license(app_machine_code)

# 输出授权信息（调试用）
cat("\n════════════════════════════════════════════════════════════\n")
cat("🔐 Xseq 授权检查\n")
cat("════════════════════════════════════════════════════════════\n")
cat(sprintf("机器码: %s\n", app_machine_code))
cat(sprintf("状态: %s\n", get_license_status_text(app_license_status$status)))
if (app_license_status$status == "active") {
  cat(sprintf("授权类型: %s\n", get_license_type_text(app_license_status$type)))
  cat(sprintf("有效期至: %s\n", app_license_status$expires_at %||% "永久"))
}
cat("════════════════════════════════════════════════════════════\n\n")

# 加载必要的包
library(shiny)
library(shinyjs)
library(bslib)
library(RSQLite)
library(DBI)
library(ggplot2)
library(dplyr)
library(DT)
library(pheatmap)
library(plotly)
library(colourpicker)
library(shinyWidgets)
library(rlang)
library(later)

# 生物信包加载
suppressPackageStartupMessages({
  library(edgeR)
  library(limma)
  library(AnnotationDbi)
  library(clusterProfiler)
  try(library(org.Mm.eg.db), silent=TRUE)
  try(library(org.Hs.eg.db), silent=TRUE)
  try(library(biofree.qyKEGGtools), silent=TRUE)
  try(library(GseaVis), silent=TRUE)
  try(library(enrichplot), silent=TRUE)

  # === decoupleR 模块所需包 ===
  library(decoupleR)
  library(tibble)
  library(tidyr)
  library(ggrepel)
  library(RColorBrewer)

  # === 韦恩图所需包 ===
  library(VennDiagram)
  library(grid)
  library(gridExtra)
})

# ✨ 检测并加载 biofree.qyKEGGtools 版本（优先使用 v2.1.0）

# 检查 biofree.qyKEGGtools 是否已安装
biofree_version <- tryCatch({
  packageVersion("biofree.qyKEGGtools")
}, error = function(e) {
  NULL
})

# 检查是否支持 universe 参数
supports_universe <- FALSE
if (!is.null(biofree_version)) {
  func_args <- tryCatch({
    formals(biofree.qyKEGGtools::enrich_local_KEGG)
  }, error = function(e) NULL)

  if (!is.null(func_args)) {
    supports_universe <- "universe" %in% names(func_args)
  }
}

# 根据版本情况显示信息
if (!is.null(biofree_version)) {
  # 转换为字符串
  version_str <- as.character(biofree_version)

  if (supports_universe) {
    cat("✅ biofree.qyKEGGtools v", version_str, "已安装（支持 universe 参数）\n", sep = "")
    cat("   将优先使用 biofree.qyKEGGtools 进行 KEGG 分析\n")
  } else {
    cat("⚠️  biofree.qyKEGGtools v", version_str, "已安装（不支持 universe 参数）\n", sep = "")
    cat("   💡 建议更新到 v2.1.0: remotes::install_github('Passpoor/biofree.qyKEGGtools')\n")
  }
} else {
  cat("⚠️  biofree.qyKEGGtools 未安装\n")
  cat("   💡 安装: remotes::install_github('Passpoor/biofree.qyKEGGtools')\n")
}

# =====================================================
# 🔧 自动检查注释数据库版本（带缓存）
# =====================================================

cat("\n🔍 检查注释数据库版本...\n")

# 🆕 检查是否启用自动更新
AUTO_UPDATE_DB <- Sys.getenv("AUTO_UPDATE_DB", "FALSE")
AUTO_UPDATE_DB <- toupper(AUTO_UPDATE_DB) == "TRUE"

# 🆕 检查频率控制（默认7天检查一次）
CHECK_INTERVAL_DAYS <- as.numeric(Sys.getenv("DB_CHECK_INTERVAL_DAYS", "7"))

# 📁 缓存文件路径
CACHE_FILE <- ".db_version_cache.rds"

# 🔧 读取缓存
load_version_cache <- function() {
  if (file.exists(CACHE_FILE)) {
    tryCatch({
      cache <- readRDS(CACHE_FILE)
      # 检查缓存是否过期
      cache_date <- as.Date(cache$date)
      days_since_check <- as.numeric(Sys.Date() - cache_date)

      if (days_since_check < CHECK_INTERVAL_DAYS) {
        return(cache)
      }
    }, error = function(e) {
      # 缓存文件损坏，忽略
    })
  }
  return(NULL)
}

# 🔧 保存缓存
save_version_cache <- function(pkg_name, version, n_genes) {
  cache <- list(
    date = as.character(Sys.Date()),
    packages = list()
  )

  # 如果已有缓存文件，先读取
  if (file.exists(CACHE_FILE)) {
    tryCatch({
      old_cache <- readRDS(CACHE_FILE)
      cache$packages <- old_cache$packages
    }, error = function(e) {
      # 忽略，使用新缓存
    })
  }

  # 更新当前包的信息
  cache$packages[[pkg_name]] <- list(
    version = as.character(version),
    n_genes = n_genes
  )

  # 保存缓存
  tryCatch({
    saveRDS(cache, CACHE_FILE)
  }, error = function(e) {
    cat(sprintf("⚠️  无法保存缓存: %s\n", e$message))
  })
}

if (AUTO_UPDATE_DB) {
  cat(sprintf("🚀 已启用自动更新模式（每 %d 天检查一次）\n", CHECK_INTERVAL_DAYS))
}

check_annotation_database <- function(pkg_name, species_name) {
  # 🔧 首先检查缓存
  cache <- load_version_cache()
  if (!is.null(cache) && !is.null(cache$packages[[pkg_name]])) {
    pkg_cache <- cache$packages[[pkg_name]]

    # 验证缓存的版本是否仍然有效
    current_version <- tryCatch({
      as.character(packageVersion(pkg_name))
    }, error = function(e) {
      NULL
    })

    if (!is.null(current_version) && current_version == pkg_cache$version) {
      # 版本未变化，使用缓存
      n_genes <- pkg_cache$n_genes

      # 🔧 修复：处理 n_genes 为 NA 的情况
      if (!is.na(n_genes) && n_genes >= 45000) {
        cat(sprintf("✅ %s v%s 已安装（包含 %d 个基因）[已缓存]\n",
                    species_name, current_version, n_genes))
        return(list(
          installed = TRUE,
          needs_update = FALSE,
          version = current_version,
          n_genes = n_genes,
          from_cache = TRUE
        ))
      } else if (is.na(n_genes)) {
        # 缓存中没有基因数量，但版本匹配，视为最新
        cat(sprintf("✅ %s v%s 已安装 [已缓存]\n",
                    species_name, current_version))
        return(list(
          installed = TRUE,
          needs_update = FALSE,
          version = current_version,
          n_genes = NA,
          from_cache = TRUE
        ))
      }
      # 如果 n_genes < 45000，说明可能需要更新，继续正常检查流程
    }
  }

  # 缓存未命中或需要更新，继续正常检查流程
  # 检查包是否安装
  if (!requireNamespace(pkg_name, quietly = TRUE)) {
    cat(sprintf("⚠️  %s (%s) 未安装\n", species_name, pkg_name))

    # 自动更新模式下自动安装
    if (AUTO_UPDATE_DB) {
      cat(sprintf("🚀 正在自动安装 %s...\n", species_name))
      tryCatch({
        BiocManager::install(pkg_name, update = TRUE, ask = FALSE)
        cat(sprintf("✅ %s 安装成功\n", species_name))
      }, error = function(e) {
        cat(sprintf("❌ %s 安装失败: %s\n", species_name, e$message))
      })
    }
    return(list(installed = FALSE, needs_update = FALSE))
  }

  # 获取当前版本
  current_version <- tryCatch({
    packageVersion(pkg_name)
  }, error = function(e) {
    NULL
  })

  if (is.null(current_version)) {
    cat(sprintf("❌ 无法获取 %s 版本信息\n", species_name))
    return(list(installed = TRUE, needs_update = FALSE, version = NULL))
  }

  # 获取数据库中的基因数量
  n_genes <- tryCatch({
    library(pkg_name, character.only = TRUE)
    db_obj <- get(pkg_name)
    nkeys(db_obj)
  }, error = function(e) {
    NA
  })

  # 🔧 更新缓存（保存基因数量）
  if (!is.na(n_genes)) {
    save_version_cache(pkg_name, current_version, n_genes)
  } else {
    # 如果获取失败，只保存版本号
    save_version_cache(pkg_name, current_version, NA)
  }

  # 检查是否需要更新（简单规则：如果基因数<45000，可能需要更新）
  needs_update <- is.na(n_genes) || n_genes < 45000

  version_str <- as.character(current_version)

  if (needs_update) {
    cat(sprintf("⚠️  %s v%s 可能需要更新\n", species_name, version_str))
    if (!is.na(n_genes)) {
      cat(sprintf("   当前包含 %d 个基因（最新版本应包含 50,000+ 个基因）\n", n_genes))
    }

    # 🆕 自动更新
    if (AUTO_UPDATE_DB) {
      cat(sprintf("🚀 正在自动更新 %s...\n", species_name))
      cat(sprintf("   这可能需要 5-10 分钟，请耐心等待...\n"))

      # 🔧 先尝试卸载包，避免锁定问题
      tryCatch({
        unloadNamespace(pkg_name)
      }, error = function(e) {
        # 卸载失败也不影响，继续尝试更新
      })

      tryCatch({
        BiocManager::install(pkg_name, update = TRUE, ask = FALSE,
                             quiet = FALSE,  # 显示安装进度
                             keep_outputs = TRUE)  # 保留安装日志

        # 🔧 修复：完全卸载旧版本后再验证
        # 避免nkeys函数不可用的race condition
        tryCatch({
          unloadNamespace(pkg_name)
        }, error = function(e) {
          # 如果卸载失败，忽略（可能本来就没加载）
        })

        # 重新加载包并验证
        library(pkg_name, character.only = TRUE)

        # 🔧 使用多种方法验证更新，避免依赖单一函数
        n_genes_new <- tryCatch({
          db_obj <- get(pkg_name)
          nkeys(db_obj)
        }, error = function(e) {
          # 如果nkeys失败，尝试其他方法
          tryCatch({
            # 使用length(keys())作为备选方法
            length(AnnotationDbi::keys(get(pkg_name)))
          }, error = function(e2) {
            # 如果还是失败，返回NA（更新可能成功了，但无法验证）
            NA
          })
        })

        version_new <- tryCatch({
          as.character(packageVersion(pkg_name))
        }, error = function(e) {
          "未知版本"
        })

        # 🔧 更新缓存（保存更新后的信息）
        if (!is.na(n_genes_new)) {
          save_version_cache(pkg_name, version_new, n_genes_new)
          cat(sprintf("✅ %s 已更新到 v%s（包含 %d 个基因）\n",
                      species_name, version_new, n_genes_new))
        } else {
          save_version_cache(pkg_name, version_new, NA)
          cat(sprintf("✅ %s 已更新到 v%s\n", species_name, version_new))
          cat("   注：无法立即验证基因数量，但更新应该已成功\n")
        }

        return(list(installed = TRUE, needs_update = FALSE, updated = TRUE))

      }, error = function(e) {
        error_msg <- e$message

        # 🔧 特殊处理：目录锁定错误
        if (grepl("不能锁定目录|cannot lock|00LOCK|locked", error_msg, ignore.case = TRUE)) {
          cat(sprintf("❌ %s 更新失败: 目录被锁定\n", species_name))
          cat("   💡 可能的原因：\n")
          cat("      1. 其他 R 进程正在使用此包\n")
          cat("      2. RStudio 或其他 R 编辑器正在运行\n")
          cat("      3. 之前的更新未完成（残留 00LOCK 文件）\n")
          cat("\n")
          cat("   📝 解决方法：\n")
          cat("      方法1 - 关闭其他 R 进程后重试\n")
          cat("      方法2 - 手动运行: BiocManager::install('%s', update=TRUE)\n", pkg_name)
          cat("      方法3 - 删除残留文件: file.remove('C:/Users/13260/AppData/Local/R/win-library/4.5/00LOCK')\n")
          cat("\n")
          cat("   ⏭️  将跳过此更新，继续使用当前版本\n")
          return(list(installed = TRUE, needs_update = TRUE, updated = FALSE, lock_error = TRUE))
        } else {
          # 其他错误
          cat(sprintf("❌ %s 更新失败: %s\n", species_name, error_msg))
          cat(sprintf("   💡 请手动运行: BiocManager::install('%s', update=TRUE)\n", pkg_name))
          return(list(installed = TRUE, needs_update = TRUE, updated = FALSE))
        }
      })
    } else {
      cat(sprintf("   💡 更新命令: BiocManager::install('%s', update=TRUE)\n", pkg_name))
      cat(sprintf("   💡 或启用自动更新: Sys.setenv(AUTO_UPDATE_DB='TRUE'); source('launch_app.R')\n"))
    }
  } else {
    cat(sprintf("✅ %s v%s 已安装（包含 %d 个基因）\n", species_name, version_str, n_genes))
  }

  return(list(
    installed = TRUE,
    needs_update = needs_update,
    version = version_str,
    n_genes = n_genes
  ))
}

# 检查小鼠数据库
mm_status <- check_annotation_database("org.Mm.eg.db", "小鼠")

# 检查人类数据库
hs_status <- check_annotation_database("org.Hs.eg.db", "人类")

# 总结
cat("\n")

# 🔧 修复：处理 needs_update 为 NA 的情况
mm_needs_update <- isTRUE(mm_status$needs_update)
hs_needs_update <- isTRUE(hs_status$needs_update)

if (mm_needs_update || hs_needs_update) {
  if (!AUTO_UPDATE_DB) {
    cat("📝 建议: 更新注释数据库可以提高基因注释成功率\n")
    cat("   选项1 - 手动更新（运行以下命令）:\n\n")
    if (mm_needs_update) {
      cat("   BiocManager::install('org.Mm.eg.db', update=TRUE, ask=FALSE)\n")
    }
    if (hs_needs_update) {
      cat("   BiocManager::install('org.Hs.eg.db', update=TRUE, ask=FALSE)\n")
    }
    cat("\n")
    cat("   选项2 - 启用自动更新:\n")
    cat("   Sys.setenv(AUTO_UPDATE_DB='TRUE')\n")
    cat("   source('launch_app.R')\n")
    cat("\n")
  }
} else {
  cat("✅ 所有注释数据库都是最新版本\n")
}

cat("\n")

# 只有在 biofree.qyKEGGtools 未安装或不支持 universe 时才加载补丁
if (is.null(biofree_version) || !supports_universe) {
  cat("\n📦 加载备用补丁...\n")

  # 优先级1: 加载v2版本（独立函数）
  if (file.exists("modules/enrich_local_KEGG_v2.R")) {
    source("modules/enrich_local_KEGG_v2.R")
    cat("✅ enrich_local_KEGG_v2 已加载（支持 universe 参数）\n")
  } else if (file.exists("patch_biofree_simple.R")) {
    # 优先级2: 应用简化版补丁
    source("patch_biofree_simple.R")
    cat("✅ 简化版补丁已加载（支持 universe 参数）\n")
  } else if (file.exists("patch_biofree_qykeggtools.R")) {
    # 优先级3: 应用完整版补丁
    source("patch_biofree_qykeggtools.R")
    cat("✅ 完整版补丁已加载（支持 universe 参数）\n")
  } else {
    cat("❌ 未找到任何补丁文件\n")
  }
}

cat("\n")

# ===============================
# 加载模块
# =====================================================

# 加载配置
source("config/config.R")

# 加载核心模块
source("modules/database.R")
source("modules/ui_theme.R")
source("modules/data_input.R")
source("modules/differential_analysis.R")
source("modules/kegg_enrichment.R")
source("modules/go_analysis.R")   # GO分析模块
source("modules/gsea_analysis.R")
source("modules/tf_activity.R")
source("modules/pathway_activity.R")  # 🆕 通路活性分析模块
source("modules/chip_analysis.R")      # 🆕 芯片数据分析模块
source("modules/survival_analysis.R")   # 🆕 生存分析模块
source("modules/venn_diagram.R")
source("modules/api_config.R")

# 加载AI模块
source("modules/ai_api.R")
source("modules/ai_enrichment.R")

# 加载国际化模块
source("modules/i18n.R")
source("modules/i18n_js.R")

# ===============================
# 主应用
# =====================================================

# 初始化数据库（仅在已激活时）
if (app_license_status$status == "active") {
  init_db()
}

# 创建UI（根据授权状态显示不同界面）
if (app_license_status$status != "active") {
  # 未激活：显示激活界面
  ui <- fluidPage(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        body {
          background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f0f23 100%);
          min-height: 100vh;
          margin: 0;
          font-family: 'Segoe UI', system-ui, sans-serif;
        }
      "))
    ),
    uiOutput("license_ui")
  )
} else {
  # 已激活：显示主应用
  ui <- fluidPage(
    useShinyjs(),
    tags$head(
      sci_fi_css,
      add_i18n_to_header(),  # 添加i18n JavaScript
      tags$style(HTML("
        body { color: inherit; }
        .small-box { color: #fff !important; }
        .shiny-notification {
          position: fixed;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          border-radius: 10px;
          backdrop-filter: blur(10px);
        }
      "))
    ),
    uiOutput("app_ui")
  )
}

# 创建Server
server <- function(input, output, session) {

  # =====================================================
  # 🔐 授权界面逻辑（未激活时显示）
  # =====================================================

  # 当前授权状态（响应式）
  current_license_status <- reactiveVal(app_license_status)

  # 渲染授权界面
  output$license_ui <- renderUI({
    HTML(generate_license_ui(app_machine_code, current_license_status()))
  })

  # 检查授权状态按钮
  observeEvent(input$check_license, {
    # 重新检查授权
    status <- check_license(app_machine_code)
    current_license_status(status)

    if (status$status == "active") {
      showNotification("✅ 激活成功！正在启动应用...", type = "message")
      # 延迟刷新页面
      Sys.sleep(1)
      session$reload()
    } else if (status$status == "expired") {
      showNotification("❌ 授权已过期，请联系管理员续期", type = "error")
    } else if (status$status == "revoked") {
      showNotification("❌ 授权已被撤销", type = "error")
    } else {
      showNotification("⏳ 尚未激活，请等待管理员处理", type = "warning")
    }
  })

  # 如果未激活，不执行后续代码
  if (app_license_status$status != "active") {
    return(NULL)
  }

  # =====================================================
  # 主应用逻辑（已激活后执行）
  # =====================================================

  # 初始化用户会话
  user_session <- reactiveValues(
    logged_in = FALSE,
    info = data.frame(username=NA, name=NA, permissions=NA, stringsAsFactors=FALSE)
  )

  # 初始化语言设置 (默认中文)
  current_language <- reactiveVal("zh")

  # 创建响应式翻译函数
  translator <- reactive({
    make_translator(current_language)
  })

  # 登录页面的语言切换
  observeEvent(input$login_language_switcher, {
    current_language(input$login_language_switcher)
  }, ignoreInit = TRUE)

  # 设置初始主题 - 使用默认主题，依赖CSS夜间模式
  initial_theme <- bs_theme(version = 5)

  # =====================================================
  # 登录逻辑
  # =====================================================

  # 动态渲染 UI
  output$app_ui <- renderUI({
    if (user_session$logged_in == FALSE) {
      # 只显示登录面板
      div(class="container-fluid", style="padding: 50px;", login_ui)
    } else {
      main_app_ui(user_session$info$name, initial_theme)
    }
  })

  # 监听登录按钮
  observeEvent(input$login_button, {
    req(input$login_user, input$login_password)

    con <- dbConnect(SQLite(), DB_PATH)
    on.exit(dbDisconnect(con))

    # 检查用户名和密码
    res <- dbGetQuery(con,
                      "SELECT username, name, permissions FROM users WHERE username = ? AND password = ?",
                      params = list(input$login_user, input$login_password))

    if (nrow(res) == 1) {
      user_session$logged_in <- TRUE
      user_session$info <- res[1, ]

      showNotification(paste0("登录成功! 欢迎您，", user_session$info$name), type = "message")


      # 登录成功后，立即激活科幻模式
      runjs('document.body.classList.add("sci-fi-mode", "mode-transition");')

      # 重置面板显示为登录（为下次登录做准备）
    } else {
      showNotification("用户名或密码错误!", type = "error")
    }
  })

  # =====================================================
  # 主题切换逻辑
  # =====================================================

  observeEvent(input$theme_toggle, {
    if(input$theme_toggle) {
      # 夜间模式
      session$sendCustomMessage("toggle-darkmode", TRUE)
    } else {
      # 日间模式
      session$sendCustomMessage("toggle-darkmode", FALSE)
    }
  }, ignoreInit = TRUE)

  # =====================================================
  # 语言切换逻辑
  # =====================================================

  observeEvent(input$language_switcher, {
    current_language(input$language_switcher)
    # 显示通知
    lang_name <- if(input$language_switcher == "zh") "中文" else "English"
    showNotification(paste("Language / 语言:", lang_name), type = "message", duration = 2)
  }, ignoreInit = TRUE)

  # =====================================================
  # 调用各功能模块
  # =====================================================

  # 数据输入模块
  data_input_server(input, output, session, user_session)

  # API配置模块
  api_config <- api_config_server(input, output, session, user_session)

  # 差异分析模块
  deg_results <- differential_analysis_server(input, output, session, user_session)

  # KEGG富集模块
  kegg_results <- kegg_enrichment_server(input, output, session, user_session, deg_results)

  # GO富集分析模块
  go_results <- go_analysis_server(input, output, session, user_session, deg_results)

  # GSEA分析模块
  gsea_analysis_server(input, output, session, user_session, deg_results)

  # 转录因子活性模块
  tf_activity_server(input, output, session, user_session, deg_results)

  # 🆕 通路活性分析模块
  # 运行通路活性分析模块（与KEGG富集分析联动）
  pathway_activity_server(input, output, session, user_session, deg_results, kegg_results)

  # 韦恩图模块
  venn_diagram_server(input, output, session, user_session)

  # 🆕 芯片数据分析模块
  chip_analysis_server(input, output, session, user_session, deg_results)

  # 🆕 生存分析模块
  survival_analysis_server(input, output, session, user_session)

  # =====================================================
  # AI 模块集成
  # =====================================================

  # 创建富集分析结果容器（用于AI解读）
  enrich_results <- reactiveValues(
    go_bp_results = NULL,
    go_mf_results = NULL,
    go_cc_results = NULL,
    kegg_results = NULL
  )

  # 监听GO分析结果，更新容器
  observe({
    req(go_results)
    # 从GO分析模块获取结果
    tryCatch({
      # go_results 是一个 reactive 函数，调用它获取数据
      go_data <- go_results()

      # 提取三大类别的结果
      if (!is.null(go_data)) {
        # 根据选择的GO类别提取对应结果
        if (input$go_ontology == "BP" || input$go_ontology == "ALL") {
          enrich_results$go_bp_results <- go_data
        }
        if (input$go_ontology == "MF" || input$go_ontology == "ALL") {
          enrich_results$go_mf_results <- go_data
        }
        if (input$go_ontology == "CC" || input$go_ontology == "ALL") {
          enrich_results$go_cc_results <- go_data
        }
      }
    }, error = function(e) {
      # 如果GO分析未运行，保持NULL
    })
  })

  # 监听KEGG分析结果，更新容器
  observe({
    req(kegg_results)
    tryCatch({
      # kegg_results 是一个 reactive 函数，调用它获取数据
      enrich_results$kegg_results <- kegg_results()
    }, error = function(e) {
      # 如果KEGG分析未运行，保持NULL
    })
  })

  # AI解读模块 - KEGG
  observeEvent(input$ai_interpret_kegg, {
    # 保存研究主题到 enrich_results
    enrich_results$research_topic <- input$kegg_research_topic

    # 创建进度状态
    progress <- reactiveValues(
      stage = "preparing",  # preparing, connecting, sending, generating, complete, error
      message = "准备中...",
      percent = 0
    )

    # 初始UI：显示进度
    output$ai_kegg_interpretation <- renderUI({
      div(
        class = "ai-progress-container",
        style = "padding: 30px; background: #f8f9fa; border-radius: 10px; margin: 20px 0;",

        # 标题和当前状态
        h4("🤖 AI解读KEGG富集结果", style = "color: #667eea; margin-top: 0;"),
        div(
          id = "ai-status-message",
          style = "font-size: 16px; margin: 20px 0; color: #555; font-weight: 500;",
          progress$message
        ),

        # 进度条
        div(
          class = "progress",
          style = "height: 25px; background-color: #e9ecef; border-radius: 12px; overflow: hidden;",
          div(
            class = "progress-bar progress-bar-striped progress-bar-animated",
            role = "progressbar",
            style = paste0("width: ", progress$percent, "%; background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);"),
            sprintf("%d%%", progress$percent)
          )
        ),

        # 详细步骤说明
        tags$div(
          id = "ai-steps",
          style = "margin-top: 20px; font-size: 13px; color: #777;",
          tags$ul(style = "list-style: none; padding-left: 0;",
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "preparing") "#667eea" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage == "preparing") "🔄" else "⏳"), "准备数据和提示词"),
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "connecting") "#667eea" else if(progress$stage == "preparing") "#667eea" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage %in% c("preparing", "connecting")) "🔄" else "⏳"), "连接到智谱AI服务器"),
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "sending") "#667eea" else if(progress$stage %in% c("preparing", "connecting")) "#667eea" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage %in% c("preparing", "connecting", "sending")) "🔄" else "⏳"), "发送分析请求"),
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "generating") "#667eea" else if(progress$stage %in% c("preparing", "connecting", "sending")) "#667eea" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage %in% c("preparing", "connecting", "sending", "generating")) "🔄" else "⏳"), "AI正在生成解读（10-30秒）"),
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "complete") "#28a745" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage == "complete") "✅" else "⏳"), "解读完成")
          )
        ),

        # 提示信息
        if(progress$stage == "generating") {
          tags$div(style = "margin-top: 15px; padding: 10px; background: #fff3cd; border-left: 4px solid #ffc107; border-radius: 4px; font-size: 12px; color: #856404;",
                   "💡 AI正在深度分析KEGG通路数据，这可能需要10-30秒，请耐心等待...")
        }
      )
    })

    # 验证数据
    kegg_data <- enrich_results$kegg_results
    if (is.null(kegg_data) || nrow(kegg_data) == 0) {
      progress$stage <- "error"
      progress$message <- "❌ 未检测到KEGG分析结果"
      output$ai_kegg_interpretation <- renderUI({
        div(
          class = "alert alert-warning",
          h4("⚠️ 未检测到KEGG分析结果"),
          p("请先运行KEGG富集分析，然后再使用AI解读功能。")
        )
      })
      return(NULL)
    }

    # 阶段1：准备数据（延迟0.5秒）
    later::later(function() {
      progress$stage <- "connecting"
      progress$message <- "🔌 正在连接智谱AI服务器..."
      progress$percent <- 20
    }, delay = 0.5)

    # 阶段2：连接和发送（延迟1秒）
    later::later(function() {
      progress$stage <- "sending"
      progress$message <- "📤 正在发送分析请求..."
      progress$percent <- 40
    }, delay = 1.0)

    # 阶段3：AI生成（延迟1.5秒后开始实际调用）
    later::later(function() {
      progress$stage <- "generating"
      progress$message <- "🤖 AI正在深度分析KEGG通路数据..."
      progress$percent <- 60

      # 实际调用API
      tryCatch({
        # 构建KEGG专用提示词
        prompt <- build_kegg_ai_prompt(enrich_results, deg_results)

        # 调用智谱AI API
        result <- call_zhipu_api(
          prompt = prompt,
          model = input$kegg_ai_model %||% "glm-4-air",
          temperature = 0.7,
          max_tokens = 2500
        )

        # 完成
        progress$stage <- "complete"
        progress$message <- "✅ 解读完成！"
        progress$percent <- 100

        # 显示结果
        output$ai_kegg_interpretation <- renderUI({
          tagList(
            div(
              class = "alert alert-success",
              style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                     color: white; border: none; border-radius: 10px;",
              h4("✅ KEGG AI解读完成", style = "color: white; margin-top: 0;"),
              p(sprintf("模型: %s | Token使用: %d",
                result$model, result$total_tokens),
                style = "color: rgba(255,255,255,0.9); margin-bottom: 0;")
            ),
            div(
              class = "ai-interpretation-box",
              style = "background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                     padding: 30px; border-radius: 15px; margin: 20px 0;
                     box-shadow: 0 4px 20px rgba(0,0,0,0.1);",
              HTML(markdown::renderText(result$text))
            )
          )
        })

      }, error = function(e) {
        progress$stage <- "error"
        progress$message <- "❌ AI解读失败"
        progress$percent <- 0

        output$ai_kegg_interpretation <- renderUI({
          div(
            class = "alert alert-danger",
            h4("❌ AI解读失败"),
            p(e$message),
            p("可能的原因：", class = "text-muted"),
            tags$ul(
              tags$li("API密钥未配置或已过期"),
              tags$li("网络连接问题"),
              tags$li("API服务暂时不可用"),
              tags$li("请求超时（数据量过大）")
            )
          )
        })
      })
    })
  })

  # AI解读模块 - GO
  observeEvent(input$ai_interpret_go, {
    # 保存研究主题到 enrich_results
    enrich_results$research_topic <- input$go_research_topic

    # 创建进度状态
    progress <- reactiveValues(
      stage = "preparing",
      message = "准备中...",
      percent = 0
    )

    # 初始UI：显示进度（与KEGG类似）
    output$ai_go_interpretation <- renderUI({
      div(
        class = "ai-progress-container",
        style = "padding: 30px; background: #f8f9fa; border-radius: 10px; margin: 20px 0;",
        h4("🤖 AI解读GO富集结果", style = "color: #667eea; margin-top: 0;"),
        div(style = "font-size: 16px; margin: 20px 0; color: #555; font-weight: 500;", progress$message),
        div(
          class = "progress",
          style = "height: 25px; background-color: #e9ecef; border-radius: 12px; overflow: hidden;",
          div(
            class = "progress-bar progress-bar-striped progress-bar-animated",
            role = "progressbar",
            style = paste0("width: ", progress$percent, "%; background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);"),
            sprintf("%d%%", progress$percent)
          )
        ),
        tags$div(style = "margin-top: 20px; font-size: 13px; color: #777;",
          tags$ul(style = "list-style: none; padding-left: 0;",
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "preparing") "#667eea" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage == "preparing") "🔄" else "⏳"), "准备GO富集数据"),
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "connecting") "#667eea" else if(progress$stage == "preparing") "#667eea" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage %in% c("preparing", "connecting")) "🔄" else "⏳"), "连接智谱AI"),
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "sending") "#667eea" else if(progress$stage %in% c("preparing", "connecting")) "#667eea" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage %in% c("preparing", "connecting", "sending")) "🔄" else "⏳"), "发送分析请求"),
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "generating") "#667eea" else if(progress$stage %in% c("preparing", "connecting", "sending")) "#667eea" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage %in% c("preparing", "connecting", "sending", "generating")) "🔄" else "⏳"), "AI生成解读（10-30秒）"),
            tags$li(style = paste0("margin: 8px 0; color: ", if(progress$stage == "complete") "#28a745" else "#ccc", ";"),
                      span(style = "margin-right: 8px;", if(progress$stage == "complete") "✅" else "⏳"), "解读完成")
          )
        ),
        if(progress$stage == "generating") {
          tags$div(style = "margin-top: 15px; padding: 10px; background: #fff3cd; border-left: 4px solid #ffc107; border-radius: 4px; font-size: 12px; color: #856404;",
                   "💡 AI正在深度分析GO生物学过程，这可能需要10-30秒...")
        }
      )
    })

    # 验证数据
    go_data <- enrich_results$go_bp_results
    if (is.null(go_data) || nrow(go_data) == 0) {
      progress$stage <- "error"
      output$ai_go_interpretation <- renderUI({
        div(class = "alert alert-warning",
            h4("⚠️ 未检测到GO分析结果"),
            p("请先运行GO富集分析，然后再使用AI解读功能。"))
      })
      return(NULL)
    }

    # 阶段1：准备（0.5秒）
    later::later(function() {
      progress$stage <- "connecting"
      progress$message <- "🔌 连接智谱AI服务器..."
      progress$percent <- 20
    }, delay = 0.5)

    # 阶段2：连接（1秒）
    later::later(function() {
      progress$stage <- "sending"
      progress$message <- "📤 发送分析请求..."
      progress$percent <- 40
    }, delay = 1.0)

    # 阶段3：生成（1.5秒后调用API）
    later::later(function() {
      progress$stage <- "generating"
      progress$message <- "🤖 AI正在深度分析GO生物学过程..."
      progress$percent <- 60

      tryCatch({
        prompt <- build_go_ai_prompt(enrich_results, deg_results)
        result <- call_zhipu_api(
          prompt = prompt,
          model = input$go_ai_model %||% "glm-4-air",
          temperature = 0.7,
          max_tokens = 2500
        )

        progress$stage <- "complete"
        progress$message <- "✅ 解读完成！"
        progress$percent <- 100

        output$ai_go_interpretation <- renderUI({
          tagList(
            div(
              class = "alert alert-success",
              style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                     color: white; border: none; border-radius: 10px;",
              h4("✅ GO AI解读完成", style = "color: white; margin-top: 0;"),
              p(sprintf("模型: %s | Token使用: %d",
                result$model, result$total_tokens),
                style = "color: rgba(255,255,255,0.9); margin-bottom: 0;")
            ),
            div(
              class = "ai-interpretation-box",
              style = "background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                     padding: 30px; border-radius: 15px; margin: 20px 0;
                     box-shadow: 0 4px 20px rgba(0,0,0,0.1);",
              HTML(markdown::renderText(result$text))
            )
          )
        })

      }, error = function(e) {
        progress$stage <- "error"
        progress$message <- "❌ AI解读失败"
        output$ai_go_interpretation <- renderUI({
          div(
            class = "alert alert-danger",
            h4("❌ AI解读失败"),
            p(e$message)
          )
        })
      })
    })
  })

  # 基因助手功能
  observeEvent(input$ask_gene_assistant, {
    req(input$gene_assistant_input)

    output$gene_assistant_output <- renderPrint({
      cat("🤖 正在咨询基因助手...\n\n")

      tryCatch({
        # 构建基因助手提示词
        prompt <- sprintf(
          "作为一位资深生物信息学专家，请回答以下与基因相关的问题：

## 用户问题
%s

## 可用数据上下文
如果有相关的差异基因数据，请结合数据进行回答。

请提供专业、准确、基于科学证据的回答。",
          input$gene_assistant_input
        )

        # 调用AI API
        result <- call_zhipu_simple(prompt, model = "glm-4-air")

        cat(result)

      }, error = function(e) {
        cat("❌ 查询失败:", e$message, "\n")
        cat("请检查API配置是否正确。")
      })
    })
  })

}

# =====================================================
# 🚀 启动应用
# =====================================================
shinyApp(ui = ui, server = server, options = list(launch.browser = TRUE))