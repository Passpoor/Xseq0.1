# 测试chip_analysis.R语法
cat("正在检查chip_analysis.R语法...\n")

tryCatch({
  # 只解析语法，不执行
  parse("modules/chip_analysis.R")
  cat("✅ 语法检查通过！\n")
}, error = function(e) {
  cat("❌ 语法错误：\n")
  cat(conditionMessage(e), "\n")

  # 尝试找到错误位置
  msg <- conditionMessage(e)
  if (grepl(":(\\d+):(\\d+):", msg)) {
    match <- regmatches(msg, regexec(":(\\d+):(\\d+):", msg))[[1]]
    if (length(match) >= 3) {
      line_num <- as.integer(match[2])
      cat(sprintf("\n错误位置：第%d行\n", line_num))

      # 显示错误附近的代码
      lines <- readLines("modules/chip_analysis.R")
      start <- max(1, line_num - 5)
      end <- min(length(lines), line_num + 5)
      cat("\n错误附近的代码：\n")
      for (i in start:end) {
        prefix <- if (i == line_num) ">>> " else "    "
        cat(sprintf("%s%4d: %s\n", prefix, i, lines[i]))
      }
    }
  }
})
