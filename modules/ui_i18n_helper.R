# =====================================================
# UI国际化辅助函数
# 用于动态翻译UI元素
# =====================================================

# 创建翻译后的textInput
textInput_i18n <- function(inputId, translator_func, ...) {
  uiOutput(inputId, inline = TRUE)
}

# 渲染翻译后的textInput
renderTextInputs <- function(input, output, session, translator_func) {
  t <- translator_func()

  # 渲染所有需要翻译的输入框
  output$file_label <- renderUI({
    tags$span(t("main_upload_counts"))
  })

  output$species_label <- renderUI({
    tags$span(t("main_select_species"))
  })

  output$data_source_label <- renderUI({
    tags$span(t("main_data_source"))
  })

  # ... 可以添加更多
}

# 批量替换UI文本的函数
replace_ui_text <- function(ui_elements, translator_func) {
  t <- translator_func()

  # 定义所有需要翻译的UI元素映射
  translations_map <- list(
    # 主界面
    "分析工作台" = t("main_workbench"),
    "数据设置" = t("main_data_settings"),
    "数据来源" = t("main_data_source"),
    "原始Counts矩阵" = t("main_source_counts"),
    "差异基因结果" = t("main_source_deg"),
    "芯片差异结果" = t("main_source_chip"),
    "夜间模式" = t("main_night_mode"),
    "上传 Counts Matrix (CSV)" = t("main_upload_counts"),
    "上传差异基因 (CSV)" = t("main_upload_deg"),
    "上传芯片差异结果 (CSV)" = t("main_upload_chip"),
    "物种" = t("main_select_species"),
    "差异参数" = t("main_diff_params"),
    "显著性指标" = t("main_significance"),
    "P阈值" = t("main_p_threshold"),
    "FC阈值" = t("main_fc_threshold"),
    "开始分析" = t("main_analyze"),
    "加载差异基因" = t("main_load_deg"),

    # 结果显示
    "火山图" = t("results_volcano_plot"),
    "热图" = t("results_heatmap"),
    "结果表格" = t("results_table"),
    "下载结果" = t("results_download"),
    "暂无数据" = t("results_no_data"),
    "处理中..." = t("results_processing"),

    # KEGG
    "KEGG通路富集分析" = t("kegg_title"),
    "运行KEGG分析" = t("kegg_run"),
    "富集参数" = t("kegg_enrich_params"),
    "显示前" = t("kegg_show_top"),
    "条通路" = t("kegg_pathways"),

    # GO
    "GO功能富集分析" = t("go_title"),
    "运行GO分析" = t("go_run"),

    # GSEA
    "GSEA基因集富集分析" = t("gsea_title"),
    "运行GSEA" = t("gsea_run"),

    # 通用
    "提交" = t("common_submit"),
    "重置" = t("common_reset"),
    "下载" = t("common_download"),
    "保存" = t("common_save"),
    "加载" = t("common_load"),

    # 消息
    "上传成功" = t("msg_upload_success"),
    "分析正在运行，请稍候..." = t("msg_analysis_running"),
    "分析完成" = t("msg_analysis_complete"),
    "请先上传文件" = t("msg_error_no_file")
  )

  return(translations_map)
}

# JavaScript函数：动态替换页面文本
create_i18n_js <- function() {
  tags$script(HTML("
    // 存储翻译字典
    window.i18n_translations = {
      zh: {},
      en: {}
    };

    // 设置翻译
    function setTranslations(lang, translations) {
      window.i18n_translations[lang] = translations;
    }

    // 更新页面文本
    function updatePageText(lang) {
      const translations = window.i18n_translations[lang];
      if (!translations) return;

      // 遍历所有翻译并更新
      for (const [original, translated] of Object.entries(translations)) {
        // 查找所有包含原始文本的元素
        const walk = document.createTreeWalker(
          document.body,
          NodeFilter.SHOW_TEXT,
          null,
          false
        );

        let node;
        while (node = walk.nextNode()) {
          if (node.textContent.trim() === original) {
            node.textContent = translated;
          }
        }
      }
    }

    // 监听语言变化
    $(document).on('shiny:inputchanged', function(event) {
      if (event.name === 'language_switcher' || event.name === 'login_language_switcher') {
        updatePageText(event.value);
      }
    });
  "))
}
