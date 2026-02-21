# 检查项目结构
setwd("D:/cherry_code/Biofree_project11.2/Biofree_project")

# 列出根目录文件
root_files <- list.files(pattern = "^[^.]", full.names = FALSE)
cat("根目录文件:\n")
print(root_files)

# 列出目录
dirs <- list.files(pattern = "^[^.]", full.names = FALSE)
cat("\n根目录:\n")
for (d in dirs) {
  if (dir.exists(d)) {
    cat(sprintf("  📁 %s/\n", d))
  }
}
