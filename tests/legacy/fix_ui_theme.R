# 修复ui_theme.R文件中的语法错误
cat("开始修复ui_theme.R文件语法错误...\n")

# 读取当前文件
lines <- readLines("modules/ui_theme.R", warn = FALSE)

# 找到问题区域 - 在2024年部分缺少一个闭合括号
cat("检查括号匹配问题...\n")

# 检查每一行的括号平衡
for (i in 1:length(lines)) {
  line <- lines[i]
  open_paren <- gregexpr("\\(", line)[[1]]
  close_paren <- gregexpr("\\)", line)[[1]]

  open_count <- if(open_paren[1] == -1) 0 else length(open_paren)
  close_count <- if(close_paren[1] == -1) 0 else length(close_paren)

  if(open_count != close_count) {
    cat(sprintf("第%d行括号不平衡: %d个开括号, %d个闭括号\n", i, open_count, close_count))
    cat(sprintf("内容: %s\n", substr(line, 1, 100)))
  }
}

cat("\n修复方案:\n")
cat("1. 修复HTML结构中的括号匹配问题\n")
cat("2. 确保所有的tags$li()都有正确的闭合\n")
cat("3. 检查函数定义的完整性\n")

cat("\n建议手动检查以下区域:\n")
cat("- 第540-566行: 2025年论文部分\n")
cat("- 第546-552行: 2024年论文部分\n")
cat("- 第588行附近: main_app_ui函数定义\n")

cat("修复完成后请检查语法:\n")
cat("source('modules/ui_theme.R')\n")