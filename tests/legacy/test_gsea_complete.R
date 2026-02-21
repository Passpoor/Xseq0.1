# =====================================================
# GSEA完整测试脚本
# =====================================================

cat("
╔════════════════════════════════════════════════════════╗
║         GSEA模块完整测试 - v3.2 Final                  ║
║                                                        ║
║  测试内容：                                            ║
║  1. 表格显示                                           ║
║  2. core_enrichment列显示SYMBOL                        ║
║  3. Leading Edge基因提取                               ║
║  4. GSEA图基因名注释                                    ║
╚════════════════════════════════════════════════════════╝

")

# =====================================================
# 步骤1: 环境检查
# =====================================================

cat("\n📋 步骤1: 检查R环境\n")
cat("─────────────────────────────────────────\n")

# 检查必要包
required_pkgs <- c("shiny", "DT", "dplyr", "clusterProfiler")
for (pkg in required_pkgs) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  ✅ %s\n", pkg))
  } else {
    cat(sprintf("  ❌ %s - 需要安装\n", pkg))
  }
}

# =====================================================
# 步骤2: 模块文件检查
# =====================================================

cat("\n📋 步骤2: 检查模块文件\n")
cat("─────────────────────────────────────────\n")

module_files <- c(
  "modules/gsea_analysis.R",
  "modules/ui_theme.R",
  "modules/data_input.R",
  "modules/differential_analysis.R"
)

for (f in module_files) {
  if (file.exists(f)) {
    cat(sprintf("  ✅ %s\n", f))
  } else {
    cat(sprintf("  ❌ %s - 缺失\n", f))
  }
}

# =====================================================
# 步骤3: 代码关键点检查
# =====================================================

cat("\n📋 步骤3: 检查关键代码\n")
cat("─────────────────────────────────────────\n")

gsea_code <- readLines("modules/gsea_analysis.R", warn = FALSE)

checks <- list(
  "output$gsea_table定义" = "output\\$gsea_table.*<-.*DT::renderDataTable",
  "core_enrichment处理" = "core_enrichment.*sapply",
  "ENTREZID转SYMBOL" = "grepl.*\\^\\[0-9\\]\\+\\$",
  "data.frame创建" = "data\\.frame.*ID.*setSize",
  "DT::datatable调用" = "DT::datatable.*df_show"
)

for (check_name in names(checks)) {
  pattern <- checks[[check_name]]
  if (any(grepl(pattern, gsea_code))) {
    cat(sprintf("  ✅ %s\n", check_name))
  } else {
    cat(sprintf("  ❌ %s - 未找到\n", check_name))
  }
}

# =====================================================
# 步骤4: 测试DT功能
# =====================================================

cat("\n📋 步骤4: 测试DT::datatable\n")
cat("─────────────────────────────────────────\n")

tryCatch({
  library(DT)

  # 模拟GSEA结果
  test_data <- data.frame(
    ID = c("GO_001", "GO_002", "GO_003"),
    setSize = c(50, 75, 100),
    enrichmentScore = c(0.55, 0.62, 0.48),
    NES = c(1.8, 2.1, 1.6),
    pvalue = c(0.001, 0.005, 0.01),
    p.adjust = c(0.01, 0.03, 0.05),
    core_enrichment = c("Csf3/Lypd6b/Cxcl3", "Il1r2/Tnf/Il6", "Stat1/Stat2/Irf7"),
    stringsAsFactors = FALSE
  )

  # 测试DT渲染
  dt <- DT::datatable(
    test_data,
    options = list(
      scrollX = TRUE,
      pageLength = 5,
      columnDefs = list(
        list(targets = 7, searchable = TRUE)
      )
    ),
    rownames = FALSE
  )

  cat("  ✅ DT::datatable 创建成功\n")
  cat(sprintf("  ✅ 测试数据: %d 行 x %d 列\n", nrow(test_data), ncol(test_data)))
  cat("  ✅ 包含core_enrichment列\n")

}, error = function(e) {
  cat(sprintf("  ❌ DT测试失败: %s\n", e$message))
})

# =====================================================
# 步骤5: 启动应用
# =====================================================

cat("\n📋 步骤5: 准备启动应用\n")
cat("─────────────────────────────────────────\n")

cat("\n现在可以启动应用进行测试：\n\n")

cat("方法1 - 在RStudio中：\n")
cat("  1. 打开 app.R\n")
cat("  2. 点击 'Run App' 按钮\n")
cat("  3. 或按 Ctrl+Shift+Enter\n\n")

cat("方法2 - 使用命令行：\n")
cat("  source('app.R')\n\n")

cat("方法3 - 使用批处理（Windows）：\n")
cat("  双击 launch_app.bat\n\n")

# =====================================================
# 测试清单
# =====================================================

cat("
╔════════════════════════════════════════════════════════╗
║                  测试清单                              ║
╚════════════════════════════════════════════════════════╝

✅ 1. 启动应用并登录
✅ 2. 上传表达矩阵文件
✅ 3. 配置样本分组
✅ 4. 运行差异分析
✅ 5. 运行GSEA分析（上传GMT文件）

检查项目：

📊 GSEA结果表格：
  □ 表格正常显示（非空白）
  □ 有7列数据
  □ core_enrichment列显示基因名（如Csf3/Lypd6b/...）
  □ 可以在搜索框输入基因名搜索

📈 GSEA富集图：
  □ 点击表格某一行后显示GSEA图
  □ 图上显示基因名称（如Csf3）
  □ 不显示数字ID（如12985）
  □ 基因名是红色或绿色

⚙️  参数调整：
  □ 可以调整'展示基因数'滑块
  □ 可以选择'基因排序方式'
  □ 可以调整'展示山脊图的通路数'

🖥️  控制台输出：
  □ 看到'✅ 提取了 N 个真正的Leading Edge基因'
  □ 看到'✅ Leading Edge基因示例: Csf3, ...'
  □ 看到'✅ 基因名称注释已添加（SYMBOL格式）'

╔════════════════════════════════════════════════════════╗
║              常见问题解决                              ║
╚════════════════════════════════════════════════════════╝

Q1: 表格还是空白？
A1: 检查R控制台是否有错误信息
    检查浏览器控制台（F12）是否有JavaScript错误

Q2: core_enrichment显示数字ID？
A2: 确认差异分析数据包含SYMBOL和ENTREZID列
    查看控制台是否显示'检测到ENTREZID格式'

Q3: GSEA图没有基因名？
A3: 确认点击了表格中的某一行
    查看'展示基因数'设置
    检查extract_leading_edge_genes是否成功

Q4: 参数调整无效？
A4: 刷新页面重试
    检查UI控件是否正确连接
    查看R控制台是否有reactive错误

")

cat("═════════════════════════════════════════════════════════\n")
cat("                测试准备完成！祝测试顺利！\n")
cat("═════════════════════════════════════════════════════════\n")
