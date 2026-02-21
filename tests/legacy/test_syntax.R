# 测试UI文件语法
tryCatch({
  source("modules/ui_theme.R")
  cat("✅ SUCCESS: ui_theme.R loaded successfully!\n")
}, error = function(e) {
  cat("❌ ERROR:", e$message, "\n")
  cat("   At line:", attr(e, "line"), "\n")
})
