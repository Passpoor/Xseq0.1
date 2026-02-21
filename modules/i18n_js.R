# =====================================================
# JavaScript动态国际化模块
# 通过JavaScript实现前端文本即时翻译
# =====================================================

# 生成完整的翻译JavaScript代码
create_i18n_javascript <- function() {

  js_code <- '
  // =====================================================
  // Biofree i18n 动态翻译系统
  // =====================================================

  (function() {
    // 翻译字典
    const translations = {
      zh: {
        // 主界面
        "分析工作台": "分析工作台",
        "数据设置": "数据设置",
        "数据来源": "数据来源",
        "原始Counts矩阵": "原始Counts矩阵",
        "差异基因结果": "差异基因结果",
        "芯片差异结果": "芯片差异结果",
        "夜间模式": "夜间模式",
        "上传 Counts Matrix (CSV)": "上传 Counts Matrix (CSV)",
        "上传差异基因 (CSV)": "上传差异基因 (CSV)",
        "上传芯片差异结果 (CSV)": "上传芯片差异结果 (CSV)",
        "物种": "物种",
        "差异参数": "差异参数",
        "显著性指标": "显著性指标",
        "P阈值": "P阈值",
        "FC阈值": "FC阈值",
        "开始分析": "开始分析",
        "加载差异基因": "加载差异基因",

        // KEGG
        "KEGG通路富集分析": "KEGG通路富集分析",
        "运行KEGG分析": "运行KEGG分析",
        "富集参数": "富集参数",
        "显示前": "显示前",
        "条通路": "条通路",
        "使用本地数据库": "使用本地数据库",
        "研究主题": "研究主题",
        "AI模型": "AI模型",
        "AI解读": "AI解读",

        // GO
        "GO功能富集分析": "GO功能富集分析",
        "运行GO分析": "运行GO分析",
        "GO类别": "GO类别",
        "生物学过程 (BP)": "生物学过程 (BP)",
        "分子功能 (MF)": "分子功能 (MF)",
        "细胞组分 (CC)": "细胞组分 (CC)",
        "全部": "全部",

        // GSEA
        "GSEA基因集富集分析": "GSEA基因集富集分析",
        "运行GSEA": "运行GSEA",

        // 结果
        "火山图": "火山图",
        "热图": "热图",
        "结果表格": "结果表格",
        "下载结果": "下载结果",
        "暂无数据": "暂无数据",
        "处理中...": "处理中...",

        // 通用
        "提交": "提交",
        "重置": "重置",
        "下载": "下载",
        "保存": "保存",
        "加载": "加载",

        // 消息
        "上传成功": "上传成功",
        "分析正在运行，请稍候...": "分析正在运行，请稍候...",
        "分析完成": "分析完成",
        "请先上传文件": "请先上传文件",

        // 帮助文本
        "注：分析方法将根据样本数量自动选择。每组样本数≥3时使用limma-voom，<3时使用edgeR。":
          "注：分析方法将根据样本数量自动选择。每组样本数≥3时使用limma-voom，<3时使用edgeR。",
        "CSV文件应包含以下列：p_val, avg_log2FC, pct.1, pct.2, p_val_adj, gene":
          "CSV文件应包含以下列：p_val, avg_log2FC, pct.1, pct.2, p_val_adj, gene"
      },

      en: {
        // Main Interface
        "分析工作台": "Analysis Workbench",
        "数据设置": "Data Settings",
        "数据来源": "Data Source",
        "原始Counts矩阵": "Raw Counts Matrix",
        "差异基因结果": "DEG Results",
        "芯片差异结果": "Chip Results",
        "夜间模式": "Night Mode",
        "上传 Counts Matrix (CSV)": "Upload Counts Matrix (CSV)",
        "上传差异基因 (CSV)": "Upload DEG File (CSV)",
        "上传芯片差异结果 (CSV)": "Upload Chip Results (CSV)",
        "物种": "Species",
        "差异参数": "Differential Parameters",
        "显著性指标": "Significance Metric",
        "P阈值": "P Threshold",
        "FC阈值": "FC Threshold",
        "开始分析": "Start Analysis",
        "加载差异基因": "Load DEGs",

        // KEGG
        "KEGG通路富集分析": "KEGG Pathway Enrichment",
        "运行KEGG分析": "Run KEGG Analysis",
        "富集参数": "Enrichment Parameters",
        "显示前": "Show Top",
        "条通路": "Pathways",
        "使用本地数据库": "Use Local Database",
        "研究主题": "Research Topic",
        "AI模型": "AI Model",
        "AI解读": "AI Interpretation",

        // GO
        "GO功能富集分析": "GO Functional Enrichment",
        "运行GO分析": "Run GO Analysis",
        "GO类别": "GO Category",
        "生物学过程 (BP)": "Biological Process (BP)",
        "分子功能 (MF)": "Molecular Function (MF)",
        "细胞组分 (CC)": "Cellular Component (CC)",
        "全部": "All",

        // GSEA
        "GSEA基因集富集分析": "GSEA Gene Set Enrichment",
        "运行GSEA": "Run GSEA",

        // Results
        "火山图": "Volcano Plot",
        "热图": "Heatmap",
        "结果表格": "Results Table",
        "下载结果": "Download Results",
        "暂无数据": "No Data Available",
        "处理中...": "Processing...",

        // Common
        "提交": "Submit",
        "重置": "Reset",
        "下载": "Download",
        "保存": "Save",
        "加载": "Load",

        // Messages
        "上传成功": "Upload Successful",
        "分析正在运行，请稍候...": "Analysis is running, please wait...",
        "分析完成": "Analysis Complete",
        "请先上传文件": "Please upload a file first",

        // Help text
        "注：分析方法将根据样本数量自动选择。每组样本数≥3时使用limma-voom，<3时使用edgeR。":
          "Note: Analysis method is automatically selected based on sample size. limma-voom for n≥3, edgeR for n<3.",
        "CSV文件应包含以下列：p_val, avg_log2FC, pct.1, pct.2, p_val_adj, gene":
          "CSV file should contain columns: p_val, avg_log2FC, pct.1, pct.2, p_val_adj, gene"
      }
    };

    // 当前语言
    let currentLang = "zh";

    // 翻译单个文本节点
    function translateTextNode(node, lang) {
      const text = node.textContent.trim();
      if (translations[lang] && translations[lang][text]) {
        node.textContent = translations[lang][text];
      }
    }

    // 翻译整个页面
    function translatePage(lang) {
      currentLang = lang;

      // 遍历所有文本节点
      const walker = document.createTreeWalker(
        document.body,
        NodeFilter.SHOW_TEXT,
        {
          acceptNode: function(node) {
            // 跳过脚本和样式
            if (node.parentElement.tagName === "SCRIPT" ||
                node.parentElement.tagName === "STYLE") {
              return NodeFilter.FILTER_REJECT;
            }
            // 只处理有实际内容的节点
            if (node.textContent.trim().length > 0) {
              return NodeFilter.FILTER_ACCEPT;
            }
            return NodeFilter.FILTER_REJECT;
          }
        }
      );

      let node;
      const nodesToUpdate = [];
      while (node = walker.nextNode()) {
        nodesToUpdate.push(node);
      }

      // 批量更新
      nodesToUpdate.forEach(function(node) {
        translateTextNode(node, lang);
      });

      console.log("Page translated to: " + lang);
    }

    // 监听语言切换
    $(document).on("shiny:inputchanged", function(event) {
      if (event.name === "language_switcher" || event.name === "login_language_switcher") {
        translatePage(event.value);
      }
    });

    // 初始化
    $(document).on("shiny:connected", function() {
      console.log("i18n system initialized");
      // 初始翻译（可选）
      setTimeout(function() {
        translatePage("zh");
      }, 500);
    });

    // 暴露到全局
    window.biofree_i18n = {
      translate: translatePage,
      getCurrentLang: function() { return currentLang; }
    };

  })();
  '

  tags$script(HTML(js_code))
}

# 将i18n JS添加到应用的header
add_i18n_to_header <- function() {
  tagList(
    create_i18n_javascript()
  )
}
