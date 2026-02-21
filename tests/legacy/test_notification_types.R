# 测试showNotification的type参数
cat("测试showNotification type参数有效性\n\n")

# showNotification的有效type参数
valid_types <- c("default", "message", "warning", "error")

# 从代码中提取所有showNotification调用
code_lines <- readLines("modules/differential_analysis.R")
notification_lines <- grep("showNotification", code_lines, value = TRUE)

cat("找到的showNotification调用:\n")
for (i in seq_along(notification_lines)) {
  line <- notification_lines[i]

  # 提取type参数值
  if (grepl('type = "', line)) {
    # 提取引号内的内容
    match <- regmatches(line, regexpr('type = "([^"]*)"', line))
    if (length(match) > 0) {
      type_value <- gsub('type = "', '', match)
      type_value <- gsub('"', '', type_value)

      # 检查是否有效
      is_valid <- type_value %in% valid_types
      status <- ifelse(is_valid, "✓", "✗")

      cat(sprintf("%s 行内容: %s\n", status, substr(line, 1, 80)))
      if (!is_valid) {
        cat(sprintf("   错误: type='%s' 无效，有效值为: %s\n",
                    type_value, paste(valid_types, collapse=", ")))
      } else {
        cat(sprintf("   正确: type='%s'\n", type_value))
      }
    }
  }
}

cat("\n所有showNotification调用检查完成！\n")