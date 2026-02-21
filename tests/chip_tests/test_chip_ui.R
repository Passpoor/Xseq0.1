# 测试芯片分析UI是否正确加载
# 运行此脚本检查代码是否正确

cat("=== 检查芯片分析模块代码 ===\n\n")

# 读取chip_analysis.R文件
chip_file <- "modules/chip_analysis.R"

if (!file.exists(chip_file)) {
  cat("❌ 错误：找不到文件", chip_file, "\n")
} else {
  cat("✅ 找到文件:", chip_file, "\n\n")

  # 读取文件内容
  lines <- readLines(chip_file, warn = FALSE)

  # 检查关键代码
  cat("检查关键代码:\n")

  # 1. 检查UI部分是否有uiOutput调用
  ui_output_found <- any(grepl('uiOutput\\("chip_soft_column_selection_panel"\\)', lines))
  if (ui_output_found) {
    cat("✅ UI部分: 找到 uiOutput('chip_soft_column_selection_panel')\n")
  } else {
    cat("❌ UI部分: 未找到 uiOutput('chip_soft_column_selection_panel')\n")
  }

  # 2. 检查Server部分是否有renderUI定义
  renderui_found <- any(grepl('output\\$chip_soft_column_selection_panel <- renderUI', lines))
  if (renderui_found) {
    cat("✅ Server部分: 找到 output$chip_soft_column_selection_panel <- renderUI\n")
  } else {
    cat("❌ Server部分: 未找到 output$chip_soft_column_selection_panel <- renderUI\n")
  }

  # 3. 检查是否直接使用selectInput
  selectinput_found <- any(grepl('selectInput\\("chip_soft_id_col"', lines)) &&
                          any(grepl('selectInput\\("chip_soft_gene_col"', lines))
  if (selectinput_found) {
    cat("✅ selectInput: 找到直接生成的selectInput\n")
  } else {
    cat("❌ selectInput: 未找到selectInput或仍使用uiOutput嵌套\n")
  }

  # 4. 显示关键行号
  cat("\n关键代码位置:\n")
  for (i in seq_along(lines)) {
    if (grepl('uiOutput\\("chip_soft_column_selection_panel"\\)', lines[i])) {
      cat(sprintf("  第%d行 (UI): %s\n", i, lines[i]))
    }
    if (grepl('output\\$chip_soft_column_selection_panel <- renderUI', lines[i])) {
      cat(sprintf("  第%d行 (Server): %s\n", i, lines[i]))
    }
    if (grepl('selectInput\\("chip_soft_id_col"', lines[i]) ||
        grepl('selectInput\\("chip_soft_gene_col"', lines[i])) {
      cat(sprintf("  第%d行 (selectInput): %s\n", i, trimws(lines[i])))
    }
  }

  cat("\n=== 检查完成 ===\n\n")

  # 给出建议
  if (ui_output_found && renderui_found && selectinput_found) {
    cat("✅ 代码检查通过！\n\n")
    cat("接下来请:\n")
    cat("1. 完全关闭Shiny应用（不要只刷新浏览器）\n")
    cat("2. 重新启动应用\n")
    cat("3. 上传SOFT文件\n")
    cat("4. 检查是否出现黄色面板和下拉框\n")
  } else {
    cat("❌ 代码检查失败！可能需要重新应用修改。\n")
  }
}
