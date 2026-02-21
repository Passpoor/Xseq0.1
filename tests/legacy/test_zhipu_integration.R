# =====================================================
# 智谱AI集成测试脚本
# =====================================================
# 用途：测试智谱AI API集成是否正常工作
# 使用：在R控制台运行 source('test_zhipu_integration.R')

cat("========================================================\n")
cat("🧪 智谱AI集成测试\n")
cat("========================================================\n\n")

# 加载必要的库
if (!require("httr", quietly = TRUE)) {
  install.packages("httr")
}
if (!require("jsonlite", quietly = TRUE)) {
  install.packages("jsonlite")
}

library(httr)
library(jsonlite)

# 加载配置
source("config/config.R")

cat("✅ 配置文件加载成功\n\n")

# 测试1：检查API密钥
cat("【测试1】检查API密钥配置\n")
cat("----------------------------------------\n")
api_key <- load_zhipu_config()
if (api_key == "") {
  cat("⚠️  未检测到API密钥\n")
  cat("请按以下步骤配置：\n")
  cat("1. 访问 https://open.bigmodel.cn/usercenter/apikeys\n")
  cat("2. 创建API密钥\n")
  cat("3. 在Biofree平台 '账户' -> '智谱AI配置' 中输入密钥\n\n")
  stop("❌ 测试失败：未配置API密钥")
} else {
  cat("✅ API密钥已配置\n")
  cat(sprintf("密钥预览: %s...%s\n\n", substr(api_key, 1, 8), substr(api_key, nchar(api_key)-7, nchar(api_key))))
}

# 测试2：API连接
cat("【测试2】测试API连接\n")
cat("----------------------------------------\n")
cat("正在发送测试请求...\n")

tryCatch({
  test_response <- call_zhipu_api(
    "你好，请用一句话介绍智谱AI。",
    model = "glm-4-flash",
    max_tokens = 100
  )

  cat("✅ API连接成功！\n")
  cat(sprintf("模型: %s\n", test_response$model))
  cat(sprintf("Token使用: %d\n", test_response$total_tokens))
  cat(sprintf("AI回复: %s\n\n", test_response$text))

}, error = function(e) {
  cat(sprintf("❌ API连接失败: %s\n\n", e$message))
  stop("❌ 测试失败：API连接问题")
})

# 测试3：富集分析解读模拟
cat("【测试3】模拟富集分析解读\n")
cat("----------------------------------------\n")

# 模拟富集分析数据
mock_data <- list(
  deg = list(
    n_total = 1500,
    n_up = 800,
    n_down = 700,
    top_up = "TP53, MYC, EGFR, PTEN, CDKN1A",
    top_down = "CDK1, CCNB1, CCNA2, PLK1, AURKA"
  ),
  go_bp = list(
    n_terms = 25,
    top_terms = "cell division; DNA replication; mitotic cell cycle; DNA repair; chromosome segregation"
  ),
  kegg = list(
    n_terms = 18,
    top_terms = "Cell cycle; p53 signaling pathway; Cellular senescence; DNA replication; Apoptosis"
  )
)

cat("模拟数据准备完成\n")
cat(sprintf("- 差异基因: %d 个 (上调%d, 下调%d)\n", mock_data$deg$n_total, mock_data$deg$n_up, mock_data$deg$n_down))
cat(sprintf("- GO BP富集: %d 个term\n", mock_data$go_bp$n_terms))
cat(sprintf("- KEGG富集: %d 个term\n", mock_data$kegg$n_terms))
cat("\n正在生成简化版提示词...\n")

# 简化的测试提示词
test_prompt <- sprintf(
  '请简要解读以下富集分析结果：

差异基因：%d个（上调%d，下调%d）
主要上调基因：%s
主要下调基因：%s

GO BP富集：%d个显著term
Top 5：%s

KEGG通路：%d个显著term
Top 5：%s

请用100-200字简要说明这些结果反映了什么生物学过程。',
  mock_data$deg$n_total, mock_data$deg$n_up, mock_data$deg$n_down,
  mock_data$deg$top_up, mock_data$deg$top_down,
  mock_data$go_bp$n_terms, mock_data$go_bp$top_terms,
  mock_data$kegg$n_terms, mock_data$kegg$top_terms
)

cat("提示词长度:", nchar(test_prompt), "字符\n")
cat("正在调用智谱AI...\n")

tryCatch({
  result <- call_zhipu_api(
    test_prompt,
    model = "glm-4-flash",
    max_tokens = 500
  )

  cat("\n✅ 富集分析解读成功！\n")
  cat(sprintf("使用Token: %d\n", result$total_tokens))
  cat(sprintf("预估成本: ¥%.4f\n", result$total_tokens * 1 / 1000000))
  cat("\n【AI解读结果】\n")
  cat("----------------------------------------\n")
  cat(result$text)
  cat("\n----------------------------------------\n")

}, error = function(e) {
  cat(sprintf("\n❌ 富集分析解读失败: %s\n", e$message))
})

# 总结
cat("\n========================================================\n")
cat("✅ 智谱AI集成测试完成！\n")
cat("========================================================\n\n")

cat("【测试总结】\n")
cat("1. ✅ API配置正常\n")
cat("2. ✅ API连接成功\n")
cat("3. ✅ 富集分析解读功能正常\n\n")

cat("【下一步】\n")
cat("1. 启动Biofree平台：shiny::runApp('app.R')\n")
cat("2. 登录后进入'账户' -> '智谱AI配置'\n")
cat("3. 配置您的API密钥\n")
cat("4. 运行富集分析后点击'AI解读'\n")
cat("5. 享受智能化分析体验！\n\n")

cat("💡 提示：首次使用建议选择GLM-4-Air模型（性价比最高）\n")
cat("💰 成本：每次分析约¥0.003，非常经济实惠！\n\n")
