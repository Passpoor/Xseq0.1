# 测试分组因子和设计矩阵构建
cat("测试分组因子和设计矩阵构建逻辑\n\n")

# 模拟数据
ctrl <- c("ctrl1", "ctrl2", "ctrl3")
trt <- c("trt1", "trt2", "trt3")

cat("1. 原始数据顺序:\n")
cat("   对照组样本:", paste(ctrl, collapse=", "), "\n")
cat("   处理组样本:", paste(trt, collapse=", "), "\n\n")

# 创建分组因子（与代码中相同的方式）
group <- factor(c(rep("C", length(ctrl)), rep("T", length(trt))))
cat("2. 分组因子创建:\n")
cat("   group =", paste(group, collapse=", "), "\n")
cat("   水平(levels):", paste(levels(group), collapse=", "), "\n")
cat("   第一个水平（参考组）:", levels(group)[1], "\n\n")

# 创建设计矩阵
design <- model.matrix(~ group)
cat("3. 设计矩阵:\n")
print(design)
cat("\n   列名:", colnames(design), "\n")
cat("   注意: 第一列是截距，第二列是", colnames(design)[2], "\n\n")

# 解释设计矩阵
cat("4. 设计矩阵解释:\n")
cat("   - 截距列(Intercept): 代表参考组的平均值\n")
cat("   - groupT列: 代表处理组(T)相对于参考组(C)的差异\n")
cat("   - 参考组是:", levels(group)[1], "\n")
cat("   - 所以 groupT = Treatment - Control\n\n")

# 检查对比矩阵
cat("5. 对比矩阵（代码中的设置）:\n")
cat("   cm <- makeContrasts(TvsC = Treatment - Control, levels = design)\n")
cat("   这意味着: TvsC = Treatment - Control\n")
cat("   即: 处理组 vs 对照组\n\n")

# 验证列名匹配
cat("6. 验证列名匹配:\n")
if ("Treatment" %in% colnames(design) && "Control" %in% colnames(design)) {
  cat("   ✓ 设计矩阵列名正确: Control, Treatment\n")
} else {
  actual_names <- colnames(design)
  cat("   ✗ 设计矩阵列名不匹配!\n")
  cat("      实际列名:", paste(actual_names, collapse=", "), "\n")
  cat("      期望列名: Control, Treatment\n")
}

# 检查因子水平顺序的影响
cat("\n7. 因子水平顺序测试:\n")
group_reversed <- factor(c(rep("C", length(ctrl)), rep("T", length(trt))), levels = c("T", "C"))
cat("   如果反转因子水平: levels = c('T', 'C')\n")
cat("   分组因子:", paste(group_reversed, collapse=", "), "\n")
cat("   水平:", paste(levels(group_reversed), collapse=", "), "\n")
cat("   第一个水平（参考组）:", levels(group_reversed)[1], "\n")

design_reversed <- model.matrix(~ group_reversed)
cat("   设计矩阵列名:", colnames(design_reversed), "\n")
cat("   此时参考组是 T（处理组），对比方向会反转！\n")

cat("\n测试完成！\n")