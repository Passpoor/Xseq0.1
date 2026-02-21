# =====================================================
# 国际化 (i18n) 模块 - 完整版 - 支持中英文切换
# =====================================================

# 创建完整翻译字典
translations <- list(
  zh = list(
    # ===== 登录界面 =====
    login_title = "Biofree 生物信息学分析平台",
    login_username = "用户名",
    login_password = "密码",
    login_button = "登录",
    login_welcome = "欢迎使用 Biofree",
    login_info = "强大的生物信息学数据分析工具",
    login_features_title = "主要功能",
    login_feature_1 = "差异基因分析",
    login_feature_2 = "KEGG 通路富集分析",
    login_feature_3 = "GO 功能富集分析",
    login_feature_4 = "GSEA 基因集富集分析",
    login_developer_title = "开发者",
    login_developer_name = "Developer",
    login_developer_role = "生物信息学研究者",

    # ===== 导航栏 =====
    nav_data_input = "数据输入",
    nav_deg = "差异分析",
    nav_kegg = "KEGG分析",
    nav_go = "GO分析",
    nav_gsea = "GSEA分析",
    nav_tf = "转录因子",
    nav_pathway = "通路活性",
    nav_chip = "芯片数据",
    nav_venn = "韦恩图",
    nav_settings = "设置",
    nav_language = "语言",

    # ===== 主界面 =====
    main_workbench = "分析工作台",
    main_data_settings = "数据设置",
    main_data_source = "数据来源",
    main_source_counts = "原始Counts矩阵",
    main_source_deg = "差异基因结果",
    main_source_chip = "芯片差异结果",
    main_night_mode = "夜间模式",

    # ===== 数据上传 =====
    main_upload_counts = "上传 Counts Matrix (CSV)",
    main_upload_deg = "上传差异基因 (CSV)",
    main_upload_chip = "上传芯片差异结果 (CSV)",
    main_select_species = "物种",
    main_mouse = "小鼠",
    main_human = "人类",
    main_samples_control = "Control组样本",
    main_samples_treat = "Treatment组样本",

    # ===== 差异参数 =====
    main_diff_params = "差异参数",
    main_significance = "显著性指标",
    main_pval_padj = "padj",
    main_pval_pvalue = "pvalue",
    main_p_threshold = "P阈值",
    main_fc_threshold = "FC阈值",
    main_edgeR_dispersion = "edgeR 离散值 (Dispersion^0.5)",
    main_edgeR_note = "注：分析方法将根据样本数量自动选择。每组样本数≥3时使用limma-voom，<3时使用edgeR。",
    main_deg_note = "CSV文件应包含以下列：p_val, avg_log2FC, pct.1, pct.2, p_val_adj, gene",
    main_load_deg = "加载差异基因",
    main_analyze = "开始分析",

    # ===== 结果显示 =====
    results_volcano_plot = "火山图",
    results_heatmap = "热图",
    results_pca = "PCA分析",
    results_table = "结果表格",
    results_download = "下载结果",
    results_no_data = "暂无数据",
    results_processing = "处理中...",
    results_up_genes = "上调基因",
    results_down_genes = "下调基因",
    results_total = "总计",

    # ===== KEGG分析 =====
    kegg_title = "KEGG通路富集分析",
    kegg_pvalue = "P值阈值",
    kegg_qvalue = "Q值阈值",
    kegg_run = "运行KEGG分析",
    kegg_results = "富集结果",
    kegg_dotplot = "点图",
    kegg_barplot = "柱状图",
    kegg_pathway = "通路图",
    kegg_enrich_params = "富集参数",
    kegg_show_top = "显示前",
    kegg_pathways = "条通路",
    kegg_local_db = "使用本地数据库",
    kegg_research_topic = "研究主题",
    kegg_ai_model = "AI模型",
    kegg_ai_interpret = "AI解读",

    # ===== GO分析 =====
    go_title = "GO功能富集分析",
    go_ontology = "GO类别",
    go_bp = "生物学过程 (BP)",
    go_mf = "分子功能 (MF)",
    go_cc = "细胞组分 (CC)",
    go_all = "全部",
    go_run = "运行GO分析",
    go_evidence = "证据代码",
    go_show_top = "显示前",
    go_terms = "个术语",
    go_research_topic = "研究主题",
    go_ai_model = "AI模型",
    go_ai_interpret = "AI解读",

    # ===== GSEA分析 =====
    gsea_title = "GSEA基因集富集分析",
    gsea_params = "GSEA参数",
    gsea_gene_set = "基因集类型",
    gsea_kegg = "KEGG",
    gsea_go = "GO",
    gsea_min_size = "最小基因集大小",
    gsea_max_size = "最大基因集大小",
    gsea_permutation = "置换次数",
    gsea_score_type = "得分类型",
    gsea_run = "运行GSEA",
    gsea_plot_title = "GSEA富集图",

    # ===== 转录因子 =====
    tf_title = "转录因子活性分析",
    tf_method = "分析方法",
    tf_run = "运行分析",
    tf_results = "活性结果",

    # ===== 通路活性 =====
    pathway_title = "通路活性分析",
    pathway_run = "运行分析",
    pathway_results = "活性评分",

    # ===== 芯片数据 =====
    chip_title = "芯片数据分析",
    chip_run = "运行分析",
    chip_results = "分析结果",

    # ===== 韦恩图 =====
    venn_title = "韦恩图分析",
    venn_sets = "输入基因集",
    venn_set1 = "基因集1",
    venn_set2 = "基因集2",
    venn_set3 = "基因集3",
    venn_set4 = "基因集4",
    venn_plot = "生成韦恩图",

    # ===== AI功能 =====
    ai_interpretation = "AI智能解读",
    ai_interpret_kegg = "AI解读KEGG结果",
    ai_interpret_go = "AI解读GO结果",
    ai_assistant = "基因助手",
    ai_ask_question = "提问",
    ai_placeholder = "请输入您的问题...",
    ai_generating = "AI正在生成解读...",
    ai_complete = "解读完成",
    ai_error = "解读失败",
    ai_model = "AI模型",
    ai_topic = "研究主题",
    ai_run = "开始解读",

    # ===== API配置 =====
    api_config_title = "API配置",
    api_key = "API密钥",
    api_save = "保存配置",
    api_test = "测试连接",
    api_zhipu_key = "智谱AI密钥",
    api_deepseek_key = "DeepSeek密钥",

    # ===== 通用 =====
    common_submit = "提交",
    common_reset = "重置",
    common_download = "下载",
    common_back = "返回",
    common_next = "下一步",
    common_processing = "处理中...",
    common_complete = "完成",
    common_error = "错误",
    common_warning = "警告",
    common_success = "成功",
    common_cancel = "取消",
    common_confirm = "确认",
    common_save = "保存",
    common_load = "加载",
    common_search = "搜索",
    common_filter = "筛选",
    common_sort = "排序",
    common_export = "导出",

    # ===== 消息 =====
    msg_upload_success = "上传成功",
    msg_upload_fail = "上传失败",
    msg_analysis_running = "分析正在运行，请稍候...",
    msg_analysis_complete = "分析完成",
    msg_error_no_file = "请先上传文件",
    msg_error_invalid_params = "参数无效",
    msg_error_analysis = "分析出错",
    msg_save_success = "保存成功",
    msg_save_fail = "保存失败",
    msg_loading = "加载中...",
    msg_no_results = "无结果",

    # ===== 帮助提示 =====
    help_species = "选择实验物种",
    help_pval = "显著性水平阈值",
    help_fc = "差异表达倍数阈值",
    help_qval = "多重检验校正后的P值",
    help_ontology = "GO基因本体分类",
    help_gene_set = "基因集类型选择",
    help_permutation = "排列检验次数"
  ),

  en = list(
    # ===== Login Page =====
    login_title = "Biofree Bioinformatics Analysis Platform",
    login_username = "Username",
    login_password = "Password",
    login_button = "Login",
    login_welcome = "Welcome to Biofree",
    login_info = "Powerful Bioinformatics Data Analysis Tool",
    login_features_title = "Key Features",
    login_feature_1 = "Differential Gene Analysis",
    login_feature_2 = "KEGG Pathway Enrichment",
    login_feature_3 = "GO Functional Enrichment",
    login_feature_4 = "GSEA Gene Set Enrichment",
    login_developer_title = "Developer",
    login_developer_name = "Qiao Yu",
    login_developer_role = "Bioinformatics Researcher",

    # ===== Navigation =====
    nav_data_input = "Data Input",
    nav_deg = "Diff Analysis",
    nav_kegg = "KEGG",
    nav_go = "GO",
    nav_gsea = "GSEA",
    nav_tf = "TF Activity",
    nav_pathway = "Pathway Activity",
    nav_chip = "Chip Data",
    nav_venn = "Venn Diagram",
    nav_settings = "Settings",
    nav_language = "Language",

    # ===== Main Interface =====
    main_workbench = "Analysis Workbench",
    main_data_settings = "Data Settings",
    main_data_source = "Data Source",
    main_source_counts = "Raw Counts Matrix",
    main_source_deg = "DEG Results",
    main_source_chip = "Chip Results",
    main_night_mode = "Night Mode",

    # ===== Data Upload =====
    main_upload_counts = "Upload Counts Matrix (CSV)",
    main_upload_deg = "Upload DEG File (CSV)",
    main_upload_chip = "Upload Chip Results (CSV)",
    main_select_species = "Species",
    main_mouse = "Mouse",
    main_human = "Human",
    main_samples_control = "Control Group Samples",
    main_samples_treat = "Treatment Group Samples",

    # ===== Diff Parameters =====
    main_diff_params = "Differential Parameters",
    main_significance = "Significance Metric",
    main_pval_padj = "padj",
    main_pval_pvalue = "pvalue",
    main_p_threshold = "P Threshold",
    main_fc_threshold = "FC Threshold",
    main_edgeR_dispersion = "edgeR Dispersion (Dispersion^0.5)",
    main_edgeR_note = "Note: Analysis method is automatically selected based on sample size. limma-voom for n≥3, edgeR for n<3.",
    main_deg_note = "CSV file should contain columns: p_val, avg_log2FC, pct.1, pct.2, p_val_adj, gene",
    main_load_deg = "Load DEGs",
    main_analyze = "Start Analysis",

    # ===== Results Display =====
    results_volcano_plot = "Volcano Plot",
    results_heatmap = "Heatmap",
    results_pca = "PCA Analysis",
    results_table = "Results Table",
    results_download = "Download Results",
    results_no_data = "No Data Available",
    results_processing = "Processing...",
    results_up_genes = "Up-regulated Genes",
    results_down_genes = "Down-regulated Genes",
    results_total = "Total",

    # ===== KEGG Analysis =====
    kegg_title = "KEGG Pathway Enrichment",
    kegg_pvalue = "P-value Threshold",
    kegg_qvalue = "Q-value Threshold",
    kegg_run = "Run KEGG Analysis",
    kegg_results = "Enrichment Results",
    kegg_dotplot = "Dot Plot",
    kegg_barplot = "Bar Plot",
    kegg_pathway = "Pathway Plot",
    kegg_enrich_params = "Enrichment Parameters",
    kegg_show_top = "Show Top",
    kegg_pathways = "Pathways",
    kegg_local_db = "Use Local Database",
    kegg_research_topic = "Research Topic",
    kegg_ai_model = "AI Model",
    kegg_ai_interpret = "AI Interpretation",

    # ===== GO Analysis =====
    go_title = "GO Functional Enrichment",
    go_ontology = "GO Category",
    go_bp = "Biological Process (BP)",
    go_mf = "Molecular Function (MF)",
    go_cc = "Cellular Component (CC)",
    go_all = "All",
    go_run = "Run GO Analysis",
    go_evidence = "Evidence Code",
    go_show_top = "Show Top",
    go_terms = "Terms",
    go_research_topic = "Research Topic",
    go_ai_model = "AI Model",
    go_ai_interpret = "AI Interpretation",

    # ===== GSEA Analysis =====
    gsea_title = "GSEA Gene Set Enrichment",
    gsea_params = "GSEA Parameters",
    gsea_gene_set = "Gene Set Type",
    gsea_kegg = "KEGG",
    gsea_go = "GO",
    gsea_min_size = "Min Gene Set Size",
    gsea_max_size = "Max Gene Set Size",
    gsea_permutation = "Permutations",
    gsea_score_type = "Score Type",
    gsea_run = "Run GSEA",
    gsea_plot_title = "GSEA Enrichment Plot",

    # ===== Transcription Factor =====
    tf_title = "Transcription Factor Activity",
    tf_method = "Analysis Method",
    tf_run = "Run Analysis",
    tf_results = "Activity Results",

    # ===== Pathway Activity =====
    pathway_title = "Pathway Activity Analysis",
    pathway_run = "Run Analysis",
    pathway_results = "Activity Score",

    # ===== Chip Data =====
    chip_title = "Chip Data Analysis",
    chip_run = "Run Analysis",
    chip_results = "Analysis Results",

    # ===== Venn Diagram =====
    venn_title = "Venn Diagram Analysis",
    venn_sets = "Input Gene Sets",
    venn_set1 = "Gene Set 1",
    venn_set2 = "Gene Set 2",
    venn_set3 = "Gene Set 3",
    venn_set4 = "Gene Set 4",
    venn_plot = "Generate Venn Diagram",

    # ===== AI Features =====
    ai_interpretation = "AI Interpretation",
    ai_interpret_kegg = "AI Interpret KEGG",
    ai_interpret_go = "AI Interpret GO",
    ai_assistant = "Gene Assistant",
    ai_ask_question = "Ask",
    ai_placeholder = "Enter your question...",
    ai_generating = "AI is generating interpretation...",
    ai_complete = "Interpretation Complete",
    ai_error = "Interpretation Failed",
    ai_model = "AI Model",
    ai_topic = "Research Topic",
    ai_run = "Start Interpretation",

    # ===== API Configuration =====
    api_config_title = "API Configuration",
    api_key = "API Key",
    api_save = "Save Configuration",
    api_test = "Test Connection",
    api_zhipu_key = "Zhipu AI Key",
    api_deepseek_key = "DeepSeek Key",

    # ===== Common =====
    common_submit = "Submit",
    common_reset = "Reset",
    common_download = "Download",
    common_back = "Back",
    common_next = "Next",
    common_processing = "Processing...",
    common_complete = "Complete",
    common_error = "Error",
    common_warning = "Warning",
    common_success = "Success",
    common_cancel = "Cancel",
    common_confirm = "Confirm",
    common_save = "Save",
    common_load = "Load",
    common_search = "Search",
    common_filter = "Filter",
    common_sort = "Sort",
    common_export = "Export",

    # ===== Messages =====
    msg_upload_success = "Upload Successful",
    msg_upload_fail = "Upload Failed",
    msg_analysis_running = "Analysis is running, please wait...",
    msg_analysis_complete = "Analysis Complete",
    msg_error_no_file = "Please upload a file first",
    msg_error_invalid_params = "Invalid Parameters",
    msg_error_analysis = "Analysis Error",
    msg_save_success = "Saved Successfully",
    msg_save_fail = "Save Failed",
    msg_loading = "Loading...",
    msg_no_results = "No Results",

    # ===== Help Tips =====
    help_species = "Select experimental species",
    help_pval = "Significance level threshold",
    help_fc = "Fold change threshold for differential expression",
    help_qval = "Adjusted P-value after multiple testing correction",
    help_ontology = "GO Gene Ontology category",
    help_gene_set = "Select gene set type",
    help_permutation = "Number of permutations for permutation test"
  )
)

# 获取翻译文本的函数
t_ <- function(key, lang = "zh") {
  if (is.null(lang)) lang <- "zh"
  if (!(lang %in% names(translations))) lang <- "zh"

  text <- tryCatch({
    translations[[lang]][[key]]
  }, error = function(e) {
    NULL
  })

  if (is.null(text)) {
    # 如果翻译不存在,返回key本身
    return(key)
  }

  return(text)
}

# 创建响应式翻译函数
make_translator <- function(language_input) {
  function(key) {
    lang <- language_input()
    t_(key, lang)
  }
}
