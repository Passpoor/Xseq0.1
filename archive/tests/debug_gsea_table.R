# =====================================================
# GSEA表格调试脚本
# =====================================================
# 用法：在R控制台中运行 source("debug_gsea_table.R")

cat("========================================\n")
cat("GSEA表格调试工具\n")
cat("========================================\n\n")

# 1. 检查必要的包
cat("1. 检查R包...\n")
required_packages <- c("shiny", "clusterProfiler", "DT", "dplyr")
missing_packages <- c()

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  } else {
    cat(sprintf("  ✅ %s\n", pkg))
  }
}

if (length(missing_packages) > 0) {
  cat(sprintf("\n❌ 缺少包: %s\n", paste(missing_packages, collapse = ", ")))
  cat("请运行: install.packages(c(...))\n")
  quit(save = "no")
}

cat("\n")

# 2. 检查模块文件
cat("2. 检查模块文件...\n")
if (!file.exists("modules/gsea_analysis.R")) {
  cat("  ❌ modules/gsea_analysis.R 不存在\n")
  quit(save = "no")
} else {
  cat("  ✅ modules/gsea_analysis.R 存在\n")
}

if (!file.exists("modules/ui_theme.R")) {
  cat("  ❌ modules/ui_theme.R 不存在\n")
  quit(save = "no")
} else {
  cat("  ✅ modules/ui_theme.R 存在\n")
}

cat("\n")

# 3. 检查关键函数
cat("3. 检查GSEA模块代码...\n")
gsea_code <- readLines("modules/gsea_analysis.R", warn = FALSE)

# 检查output$gsea_table
if (any(grepl("output\\$gsea_table", gsea_code))) {
  cat("  ✅ 找到 output$gsea_table 定义\n")
} else {
  cat("  ❌ 未找到 output$gsea_table 定义\n")
}

# 检查core_enrichment处理
if (any(grepl("core_enrichment", gsea_code))) {
  cat("  ✅ 找到 core_enrichment 处理代码\n")
} else {
  cat("  ❌ 未找到 core_enrichment 处理代码\n")
}

# 检查ENTREZID到SYMBOL转换
if (any(grepl("entrez_to_symbol", gsea_code))) {
  cat("  ✅ 找到 ID 转换代码\n")
} else {
  cat("  ❌ 未找到 ID 转换代码\n")
}

cat("\n")

# 4. 测试DT::datatable
cat("4. 测试DT::datatable...\n")
tryCatch({
  # 创建测试数据
  test_df <- data.frame(
    ID = c("PATHWAY1", "PATHWAY2"),
    setSize = c(100, 200),
    enrichmentScore = c(0.5, 0.6),
    NES = c(1.5, 1.8),
    pvalue = c(0.001, 0.01),
    p.adjust = c(0.01, 0.05),
    core_enrichment = c("Gene1/Gene2", "Gene3/Gene4"),
    stringsAsFactors = FALSE
  )

  # 测试DT渲染
  dt_table <- DT::datatable(test_df,
                            options = list(
                              scrollX = TRUE,
                              pageLength = 5,
                              columnDefs = list(
                                list(targets = 7, searchable = TRUE)
                              )
                            ),
                            rownames = FALSE)

  cat("  ✅ DT::datatable 测试成功\n")
  cat(sprintf("  测试数据: %d 行, %d 列\n", nrow(test_df), ncol(test_df)))
}, error = function(e) {
  cat(sprintf("  ❌ DT::datatable 测试失败: %s\n", e$message))
})

cat("\n")

# 5. 检查常见错误
cat("5. 检查常见问题...\n")

# 检查是否有%>%但dplyr未加载
has_pipe <- any(grepl("%>%", gsea_code))
loads_dplyr <- any(grepl("library\\(dplyr\\)", gsea_code)) ||
                 any(grepl("require\\(dplyr\\)", gsea_code))

if (has_pipe && !loads_dplyr) {
  cat("  ⚠️  警告: 代码使用%>%但可能未加载dplyr\n")
} else {
  cat("  ✅ dplyr加载检查通过\n")
}

# 检查是否有data.frame()创建
has_dataframe <- any(grepl("data\\.frame\\(", gsea_code))
if (has_dataframe) {
  cat("  ✅ 使用data.frame()创建表格\n")
} else {
  cat("  ⚠️  可能缺少data.frame()创建\n")
}

cat("\n")

# 6. 诊断建议
cat("========================================\n")
cat("诊断建议\n")
cat("========================================\n\n")

cat("如果表格仍然不显示，请检查：\n\n")
cat("1. R控制台输出：\n")
cat("   - 查找错误信息（红色文字）\n")
cat("   - 查找警告信息\n\n")

cat("2. 浏览器控制台（F12）：\n")
cat("   - 打开浏览器开发者工具\n")
cat("   - 查看Console标签页\n")
cat("   - 查找JavaScript错误\n\n")

cat("3. 网络请求：\n")
cat("   - 在浏览器开发者工具中\n")
cat("   - 打开Network标签页\n")
cat("   - 查找失败的请求\n\n")

cat("4. 数据验证：\n")
cat("   - 确认GSEA分析成功完成\n")
cat("   - 确认有富集结果\n")
cat("   - 确认core_enrichment列存在\n\n")

cat("========================================\n")
cat("调试完成\n")
cat("========================================\n")
