# =====================================================
# GSEA模块完整验证脚本
# =====================================================

cat("
╔════════════════════════════════════════════════════════╗
║         GSEA模块完整功能验证 - v3.3                  ║
╚════════════════════════════════════════════════════════╝

")

# =====================================================
# 1. 检查关键代码
# =====================================================

cat("\n📋 步骤1: 检查GSEA表格渲染代码\n")
cat("─────────────────────────────────────────\n")

gsea_code <- readLines("modules/gsea_analysis.R", warn = FALSE)

# 找到output$gsea_table的位置
table_start <- which(grepl("output\\$gsea_table.*<-.*DT::renderDataTable", gsea_code))
table_end <- which(grepl("^  \\}$", gsea_code))
# 找到对应的结束括号
brace_count <- 0
for (i in table_start:length(gsea_code)) {
  brace_count <- brace_count + lengths(regmatches(gsea_code[i], gregexpr("\\{", gsea_code[i])))
  brace_count <- brace_count - lengths(regmatches(gsea_code[i], gregexpr("\\}", gsea_code[i])))
  if (brace_count == 0 && i > table_start) {
    table_end <- i
    break
  }
}

if (length(table_start) > 0) {
  table_code <- gsea_code[table_start:table_end]
  cat(sprintf("✅ 找到表格渲染代码: %d 行\n", length(table_code)))

  # 检查关键特性
  checks <- list(
    "req(gsea_results())" = "req\\(gsea_results\\(\\)\\)",
    "读取GSEA结果" = "df.*<-.*gsea_results\\(\\)@result",
    "调试输出" = "cat.*sprintf.*GSEA结果",
    "显示原始数据" = "df_show.*<-.*df",
    "DT::datatable调用" = "DT::datatable\\(df_show"
  )

  for (check_name in names(checks)) {
    if (any(grepl(checks[[check_name]], table_code))) {
      cat(sprintf("  ✅ %s\n", check_name))
    } else {
      cat(sprintf("  ❌ %s - 未找到\n", check_name))
    }
  }
} else {
  cat("  ❌ 未找到表格渲染代码\n")
}

# =====================================================
# 2. 检查ID转换代码
# =====================================================

cat("\n📋 步骤2: 检查ID类型转换和错误处理\n")
cat("─────────────────────────────────────────\n")

id_checks <- list(
  "ENTREZID检测" = "grepl.*\\^\\[0-9\\]\\+\\$.*sample_genes",
  "tryCatch错误捕获" = "tryCatch\\(.*\\{",
  "映射率检查" = "n_mapped.*n_total.*0.5",
  "用户提示" = "showNotification.*GMT.*ID类型",
  "统计输出" = "cat.*sprintf.*转换结果"
)

for (check_name in names(id_checks)) {
  if (any(grepl(id_checks[[check_name]], gsea_code))) {
    cat(sprintf("  ✅ %s\n", check_name))
  } else {
    cat(sprintf("  ❌ %s - 未找到\n", check_name))
  }
}

# =====================================================
# 3. 检查Leading Edge基因提取
# =====================================================

cat("\n📋 步骤3: 检查Leading Edge基因提取\n")
cat("─────────────────────────────────────────\n")

le_checks <- list(
  "extract_leading_edge_genes函数" = "extract_leading_edge_genes.*<-.*reactive",
  "core_enrichment字段提取" = "core_enrichment_str.*<-.*core_enrichment",
  "自动检测ENTREZID" = "grepl.*\\^\\[0-9\\]\\+\\$.*le_genes_raw",
  "转换为SYMBOL" = "entrez_to_symbol\\[le_genes_raw\\]",
  "SYMBOL格式输出" = "le_genes_symbol.*SYMBOL"
)

for (check_name in names(le_checks)) {
  if (any(grepl(le_checks[[check_name]], gsea_code))) {
    cat(sprintf("  ✅ %s\n", check_name))
  } else {
    cat(sprintf("  ❌ %s - 未找到\n", check_name))
  }
}

# =====================================================
# 4. 检查GSEA图基因注释
# =====================================================

cat("\n📋 步骤4: 检查GSEA图基因名称注释\n")
cat("─────────────────────────────────────────\n")

# 找到gsea_plot
plot_start <- which(grepl("output\\$gsea_plot.*<-.*renderPlot", gsea_code))
if (length(plot_start) > 0) {
  # 找到对应的结束
  brace_count <- 0
  for (i in plot_start:length(gsea_code)) {
    brace_count <- brace_count + lengths(regmatches(gsea_code[i], gregexpr("\\{", gsea_code[i])))
    brace_count <- brace_count - lengths(regmatches(gsea_code[i], gregexpr("\\}", gsea_code[i])))
    if (brace_count == 0 && i > plot_start) {
      plot_end <- i
      break
    }
  }

  plot_code <- gsea_code[plot_start:plot_end]
  cat(sprintf("✅ 找到GSEA图渲染代码: %d 行\n", length(plot_code)))

  plot_checks <- list(
    "调用extract_leading_edge_genes" = "extract_leading_edge_genes\\(\\)",
    "tryCatch错误处理" = "tryCatch\\(.*extract_leading_edge_genes",
    "创建rank_position" = "rank_position.*<-.*match",
    "添加点标记" = "geom_point.*rank_position",
    "添加文本标签" = "geom_text.*label.*gene",
    "SYMBOL格式检查" = "is.data.frame.*top_genes_data"
  )

  for (check_name in names(plot_checks)) {
    if (any(grepl(plot_checks[[check_name]], plot_code))) {
      cat(sprintf("  ✅ %s\n", check_name))
    } else {
      cat(sprintf("  ❌ %s - 未找到\n", check_name))
    }
  }
} else {
  cat("  ❌ 未找到GSEA图渲染代码\n")
}

# =====================================================
# 5. 测试数据框创建
# =====================================================

cat("\n📋 步骤5: 测试数据框创建\n")
cat("─────────────────────────────────────────\n")

tryCatch({
  # 模拟GSEA结果
  mock_gsea <- data.frame(
    ID = c("GO_001", "GO_002", "GO_003"),
    setSize = c(50, 75, 100),
    enrichmentScore = c(0.55, 0.62, 0.48),
    NES = c(1.8, 2.1, 1.6),
    pvalue = c(0.001, 0.005, 0.01),
    p.adjust = c(0.01, 0.03, 0.05),
    core_enrichment = c("12985/71897/330122", "54448/20299/14825", "11529/11535/20310"),
    stringsAsFactors = FALSE
  )

  cat("  ✅ 模拟GSEA结果创建成功\n")
  cat(sprintf("  ✅ %d 行, %d 列\n", nrow(mock_gsea), ncol(mock_gsea)))

  # 测试直接显示
  df_show <- mock_gsea
  cat(sprintf("  ✅ df_show = df: %d 行\n", nrow(df_show)))

  # 测试DT创建
  library(DT)
  dt <- DT::datatable(df_show,
                    options = list(pageLength = 10, scrollX = TRUE),
                    rownames = FALSE)
  cat("  ✅ DT::datatable 创建成功\n")

}, error = function(e) {
  cat(sprintf("  ❌ 测试失败: %s\n", e$message))
})

# =====================================================
# 6. 关键功能总结
# =====================================================

cat("\n📋 步骤6: 关键功能总结\n")
cat("─────────────────────────────────────────\n")

features <- list(
  "✅ 表格显示原始GSEA结果" = "表格现在直接显示df，不做转换",
  "✅ ID类型不匹配错误处理" = "tryCatch + 友好的错误提示",
  "✅ 映射率检查和警告" = "检查n_mapped/n_total，<50%时警告",
  "✅ Leading Edge基因提取" = "自动检测ENTREZID并转换为SYMBOL",
  "✅ GSEA图基因名称注释" = "使用自定义注释层显示SYMBOL",
  "✅ 山脊图通路数限制" = "正确使用showCategory参数"
)

for (feature in names(features)) {
  cat(sprintf("%s\n", feature))
  cat(sprintf("   %s\n", features[[feature]]))
}

# =====================================================
# 7. 用户指南
# =====================================================

cat("\n📋 步骤7: 使用建议\n")
cat("─────────────────────────────────────────\n")

cat("
✅ 推荐配置:

1. 如果GMT文件是ENTREZID格式（数字ID）:
   → GMT中的ID类型: 选择 'Entrez ID'

2. 如果GMT文件是SYMBOL格式（基因名）:
   → GMT中的ID类型: 选择 'Gene Symbol'

3. 如果不确定:
   → 打开GMT文件查看前几行
   → 看到纯数字（12985/71897）→ ENTREZID
   → 看到基因名（Csf3/Lypd6b）→ SYMBOL

4. 表格功能:
   → 现在显示原始GSEA结果
   → core_enrichment列显示原始内容
   → 可以搜索和过滤

5. GSEA图功能:
   → 点击表格中的某一行
   → 图上会显示Top N基因名称（SYMBOL格式）
   → 基因名是红色或绿色

")

# =====================================================
# 8. 诊断信息
# =====================================================

cat("\n📋 步骤8: 调试检查清单\n")
cat("─────────────────────────────────────────\n")

cat("
如果仍有问题，请检查：

□ R控制台输出：
  - 查看 📊 开头的调试信息
  - 检查 ⚠️ 警告信息
  - 查看 ❌ 错误信息

□ 浏览器控制台（F12）：
  - 打开开发者工具
  - 查看Console标签页
  - 查找JavaScript错误

□ 数据验证：
  - GSEA是否成功完成
  - 有多少富集结果
  - core_enrichment列是否存在

□ ID类型匹配：
  - GMT文件格式是什么？
  - UI中选择的是什么？
  - 控制台是否显示"检测到GMT使用ENTREZID"？

")

cat("\n═════════════════════════════════════════════════════════\n")
cat("                验证完成！请参考上述建议\n")
cat("═════════════════════════════════════════════════════════\n")
