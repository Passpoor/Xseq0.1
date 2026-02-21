# =====================================================
# 国际化功能验证脚本
# 快速检查i18n系统是否正常工作
# =====================================================

cat("========================================\n")
cat("Biofree i18n 功能验证\n")
cat("========================================\n\n")

# 1. 检查文件存在性
cat("1️⃣ 检查文件...\n")
files_to_check <- c(
  "modules/i18n.R",
  "modules/i18n_js.R",
  "modules/ui_theme.R",
  "app.R"
)

for (file in files_to_check) {
  if (file.exists(file)) {
    cat(sprintf("   ✅ %s\n", file))
  } else {
    cat(sprintf("   ❌ %s 缺失!\n", file))
  }
}

cat("\n")

# 2. 加载i18n模块
cat("2️⃣ 加载i18n模块...\n")
tryCatch({
  source("modules/i18n.R")
  cat("   ✅ i18n.R 加载成功\n")
}, error = function(e) {
  cat("   ❌ i18n.R 加载失败:", e$message, "\n")
})

tryCatch({
  source("modules/i18n_js.R")
  cat("   ✅ i18n_js.R 加载成功\n")
}, error = function(e) {
  cat("   ❌ i18n_js.R 加载失败:", e$message, "\n")
})

cat("\n")

# 3. 测试翻译函数
cat("3️⃣ 测试翻译函数...\n")
test_keys <- c(
  "main_workbench",
  "kegg_title",
  "go_title",
  "common_submit"
)

for (key in test_keys) {
  zh_text <- t_(key, "zh")
  en_text <- t_(key, "en")
  cat(sprintf("   • %s\n", key))
  cat(sprintf("     中文: %s\n", zh_text))
  cat(sprintf("     英文: %s\n", en_text))
}

cat("\n")

# 4. 检查翻译覆盖率
cat("4️⃣ 翻译统计...\n")
zh_keys <- length(translations$zh)
en_keys <- length(translations$en)
cat(sprintf("   中文翻译键: %d\n", zh_keys))
cat(sprintf("   英文翻译键: %d\n", en_keys))
cat(sprintf("   覆盖率: %d%%\n", min(zh_keys, en_keys) * 100 / max(zh_keys, en_keys)))

cat("\n")

# 5. 检查app.R集成
cat("5️⃣ 检查app.R集成...\n")
app_content <- readLines("app.R", warn = FALSE)
if (any(grepl("modules/i18n", app_content))) {
  cat("   ✅ app.R 已加载i18n模块\n")
} else {
  cat("   ⚠️  app.R 未加载i18n模块\n")
}

if (any(grepl("add_i18n_to_header", app_content))) {
  cat("   ✅ app.R 已添加i18n JavaScript\n"
} else {
  cat("   ⚠️  app.R 未添加i18n JavaScript\n")
}

cat("\n")

# 6. 检查语言切换器
cat("6️⃣ 检查语言切换器...\n")
ui_content <- readLines("modules/ui_theme.R", warn = FALSE)
if (any(grepl('language_switcher', ui_content))) {
  cat("   ✅ 导航栏语言切换器已添加\n")
} else {
  cat("   ⚠️  未找到导航栏语言切换器\n")
}

if (any(grepl('login_language_switcher', ui_content))) {
  cat("   ✅ 登录页语言切换器已添加\n")
} else {
  cat("   ⚠️  未找到登录页语言切换器\n")
}

cat("\n")

# 总结
cat("========================================\n")
cat("✅ 验证完成！\n")
cat("========================================\n\n")

cat("📝 下一步:\n")
cat("   1. 运行应用: source('launch_app.R')\n")
cat("   2. 测试语言切换功能\n")
cat("   3. 检查所有模块翻译\n")
cat("\n")

cat("💡 提示:\n")
cat("   - 登录页和主应用右上角都有语言切换器\n")
cat("   - 切换后所有文本应该立即更新\n")
cat("   - 如有未翻译的文本,请参考 I18N_COMPLETE_GUIDE.md\n")
cat("\n")
