# 检查 biofree.qyKEGGtools 包状态
# 在R控制台中运行此脚本

cat("\n========================================\n")
cat("biofree.qyKEGGtools 包状态检查\n")
cat("========================================\n\n")

# 1. 检查包是否安装
cat("1. 检查包安装状态...\n")
is_installed <- require("biofree.qyKEGGtools", quietly = TRUE)

if (is_installed) {
  cat("   ✅ biofree.qyKEGGtools 已安装\n")
  cat("   版本:", as.character(packageVersion("biofree.qyKEGGtools")), "\n")
} else {
  cat("   ❌ biofree.qyKEGGtools 未安装\n")
  cat("\n安装方法:\n")
  cat("   方法1: install.packages('biofree.qyKEGGtools')\n")
  cat("   方法2: remotes::install_github('username/biofree.qyKEGGtools')\n")
}

# 2. 检查函数是否存在
if (is_installed) {
  cat("\n2. 检查 enrich_local_KEGG 函数...\n")
  if (exists("enrich_local_KEGG", mode = "function")) {
    cat("   ✅ enrich_local_KEGG 函数存在\n")

    # 查看函数参数
    args <- formals(biofree.qyKEGGtools::enrich_local_KEGG)
    cat("   函数参数:", paste(names(args), collapse = ", "), "\n")
  } else {
    cat("   ❌ enrich_local_KEGG 函数不存在\n")
  }
}

cat("\n========================================\n")
cat("检查完成\n")
cat("========================================\n\n")
