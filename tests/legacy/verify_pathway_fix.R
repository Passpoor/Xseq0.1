# 快速验证脚本 - 通路活性模块修复
# 运行此脚本验证修复是否生效

cat("===================================================\n")
cat("通路活性模块修复验证\n")
cat("===================================================\n\n")

# 1. 检查关键代码是否存在
cat("1. 检查修复代码...\n")

module_path <- "modules/pathway_activity.R"
if (!file.exists(module_path)) {
  cat("   ❌ 错误: modules/pathway_activity.R 不存在\n")
  quit(status = 1)
}

module_lines <- readLines(module_path, warn = FALSE)

# 检查 stats_df 构建是否包含 ENTREZID 保留
stats_df_fix <- any(grepl('select\\(SYMBOL, ENTREZID, log2FoldChange\\)', module_lines))
cat(sprintf("   stats_df 保留 ENTREZID: %s\n", ifelse(stats_df_fix, "✅", "❌")))

# 检查矩阵构建是否使用先 select 再转换
matrix_fix <- any(grepl('select\\(SYMBOL, log2FoldChange\\) %>%.*column_to_rownames', module_lines, perl = TRUE))
cat(sprintf("   矩阵构建先 select 后转换: %s\n", ifelse(matrix_fix, "✅", "❌")))

# 检查是否包含矩阵列名确保
colname_fix <- any(grepl('colnames\\(mat_input\\) <- "log2FoldChange"', module_lines))
cat(sprintf("   矩阵列名命名: %s\n", ifelse(colname_fix, "✅", "❌")))

# 2. 检查数据流
cat("\n2. 检查数据流配置...\n")

# 检查 app.R 是否正确传递 kegg_results
app_lines <- readLines("app.R", warn = FALSE)
app_call <- any(grepl('pathway_activity_server\\(input, output, session, user_session, deg_results, kegg_results\\)', app_lines))
cat(sprintf("   app.R 传递 kegg_results: %s\n", ifelse(app_call, "✅", "❌")))

# 检查模块函数签名
func_sig <- any(grepl('pathway_activity_server.*function.*kegg_results', module_lines))
cat(sprintf("   模块接收 kegg_results: %s\n", ifelse(func_sig, "✅", "❌")))

# 3. 关键修复验证
cat("\n3. 关键修复验证...\n")

# 修复 1: stats_df 保留 ENTREZID
line_51 <- module_lines[51]  # select(SYMBOL, ENTREZID, log2FoldChange)
fix1_check <- grepl("select\\(SYMBOL, ENTREZID, log2FoldChange\\)", line_51)
cat(sprintf("   修复1 - stats_df 保留 ENTREZID: %s\n", ifelse(fix1_check, "✅", "❌")))
cat("       代码: ", trimws(line_51), "\n")

# 修复 2: 矩阵构建先 select
# 找到所有 select(SYMBOL, log2FoldChange) 行
select_lines <- which(grepl('select\\(SYMBOL, log2FoldChange\\)', module_lines))
if (length(select_lines) > 0) {
  cat(sprintf("   修复2 - 矩阵构建先 select: ✅ (找到 %d 处)\n", length(select_lines)))
  for (i in head(select_lines, 2)) {
    cat("       行", i, ": ", trimws(module_lines[i]), "\n")
  }
} else {
  cat("   修复2 - 矩阵构建先 select: ❌\n")
}

# 4. 预期的输出格式
cat("\n4. 预期的控制台输出...\n")
cat("   运行通路活性分析后，应该看到:\n")
cat("   📊 表达矩阵维度: XXXX 基因 x 1 样本  ✅ (不是 2 样本)\n")
cat("   📊 匹配的基因数: XXX (100.0%)\n")
cat("   📊 通路网络构建完成: XXX 通路, XXXX 相互关系\n")
cat("   📊 MOR分布: 激活=XXXX, 抑制=XXXX  ✅ (两者都有)\n")
cat("   📊 活跃通路: ~50%, 抑制通路: ~50%  ✅ (不是 100%/0%)\n")

# 5. 测试建议
cat("\n5. 测试步骤...\n")
cat("   1. 在 RStudio 控制台运行: .rs.restartR()\n")
cat("   2. 重新运行应用: source('app.R'); shiny::runApp()\n")
cat("   3. 进入 '🧬 KEGG 富集分析' 标签\n")
cat("   4. 运行 KEGG 分析并等待完成\n")
cat("   5. 切换到 '🛤️ 通路活性' 标签\n")
cat("   6. 点击 '🚀 运行通路活性分析'\n")
cat("   7. 检查控制台输出是否符合上述预期\n")

# 6. 总结
cat("\n===================================================\n")
all_checks <- stats_df_fix && matrix_fix && colname_fix && app_call && func_sig

if (all_checks) {
  cat("✅ 所有关键检查通过！\n")
  cat("修复已正确应用，可以开始测试。\n")
} else {
  cat("⚠️  部分检查未通过，请检查代码。\n")
}
cat("===================================================\n")
