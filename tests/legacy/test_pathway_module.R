# 测试通路活性分析模块是否正确加载
# 运行此脚本来验证模块集成

cat("===================================================\n")
cat("通路活性分析模块测试\n")
cat("===================================================\n\n")

# 1. 检查模块文件是否存在
cat("1. 检查模块文件...\n")
if (file.exists("modules/pathway_activity.R")) {
  cat("   ✅ modules/pathway_activity.R 存在\n")
} else {
  cat("   ❌ modules/pathway_activity.R 不存在！\n")
  quit(status = 1)
}

# 2. 检查 app.R 是否正确引用模块
cat("\n2. 检查 app.R 引用...\n")
app_content <- readLines("app.R", warn = FALSE)

if (any(grepl('source\\("modules/pathway_activity.R"\\)', app_content))) {
  cat("   ✅ app.R 正确加载模块\n")
} else {
  cat("   ❌ app.R 未加载模块！\n")
}

# 3. 检查模块调用
cat("\n3. 检查模块调用...\n")
if (any(grepl('pathway_activity_server\\(input, output, session, user_session, deg_results, kegg_results\\)', app_content))) {
  cat("   ✅ 模块调用正确（包含 kegg_results 参数）\n")
} else if (any(grepl('pathway_activity_server', app_content))) {
  cat("   ⚠️  模块已调用但参数可能不正确\n")
  for (i in seq_along(app_content)) {
    if (grepl('pathway_activity_server', app_content[i])) {
      cat("   行", i, ":", app_content[i], "\n")
    }
  }
} else {
  cat("   ❌ app.R 中未找到模块调用！\n")
}

# 4. 检查 UI 中的 tabPanel
cat("\n4. 检查 UI 定义...\n")
ui_content <- readLines("modules/ui_theme.R", warn = FALSE)
pathway_tab_lines <- grep('tabPanel.*通路活性', ui_content, value = TRUE)

if (length(pathway_tab_lines) > 0) {
  cat("   ✅ UI 中找到通路活性标签\n")
  for (line in pathway_tab_lines) {
    cat("   ", line, "\n")
  }
} else {
  cat("   ❌ UI 中未找到通路活性标签！\n")
}

# 5. 检查模块函数签名
cat("\n5. 检查模块函数签名...\n")
module_content <- readLines("modules/pathway_activity.R", warn = FALSE)
func_def <- module_content[grepl('pathway_activity_server.*function', module_content)]

if (length(func_def) > 0) {
  cat("   找到函数定义:\n")
  cat("   ", func_def, "\n")

  if (grepl('kegg_results', func_def)) {
    cat("   ✅ 函数签名包含 kegg_results 参数\n")
  } else {
    cat("   ❌ 函数签名缺少 kegg_results 参数！\n")
  }
} else {
  cat("   ❌ 未找到函数定义！\n")
}

# 6. 检查数据访问模式
cat("\n6. 检查数据访问模式...\n")
data_access <- module_content[grepl('kegg_results\\(\\)', module_content)]
if (length(data_access) > 0) {
  cat("   ✅ 使用正确的数据访问模式: kegg_results()\n")
} else {
  cat("   ⚠️  未找到 kegg_results() 调用\n")
}

wrong_access <- module_content[grepl('input\\$kegg_results_for_pathway', module_content)]
if (length(wrong_access) > 0) {
  cat("   ❌ 仍在使用错误的访问模式: input$kegg_results_for_pathway\n")
} else {
  cat("   ✅ 没有使用错误的访问模式\n")
}

cat("\n===================================================\n")
cat("测试完成！\n")
cat("===================================================\n\n")

cat("建议：\n")
cat("1. 如果所有测试都通过，请重启 R 会话和应用\n")
cat("2. 清除浏览器缓存或使用无痕模式\n")
cat("3. 检查 RStudio 控制台是否有错误信息\n")
cat("4. 确认在 KEGG 分析完成后再运行通路活性分析\n")
