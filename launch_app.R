# =====================================================
# 快速启动脚本
# =====================================================

# 设置工作目录
setwd("D:/cherry_code/Biofree_project11.2/Biofree_project")

# 加载必要的包
required_packages <- c("shiny", "clusterProfiler", "GseaVis",
                      "enrichplot", "ggplot2", "dplyr", "DT")

cat("正在检查和加载包...\n")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("安装 %s...\n", pkg))
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
  cat(sprintf("✅ %s 已加载\n", pkg))
}

# 启动应用
cat("\n========================================\n")
cat("🚀 启动Biofree应用\n")
cat("========================================\n\n")

cat("应用将在浏览器中打开...\n")
cat("URL: http://127.0.0.1:3838\n\n")

cat("💡 提示:\n")
cat("  • 使用Ctrl+C停止应用\n")
cat("  • 查看R控制台获取调试信息\n")
cat("  • GSEA分析中推荐使用SYMBOL作为ID类型\n\n")

# 运行应用
shiny::runApp(
  appDir = getwd(),
  launch.browser = TRUE,
  port = 3838
)
