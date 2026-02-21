# 测试设计矩阵和对比矩阵的正确性
cat("测试设计矩阵和对比矩阵构建\n\n")

# 模拟与代码相同的情况
ctrl <- c("ctrl1", "ctrl2")
trt <- c("trt1", "trt2", "trt3")

cat("1. 模拟数据:\n")
cat("   对照组:", paste(ctrl, collapse=", "), " (n=", length(ctrl), ")\n", sep="")
cat("   处理组:", paste(trt, collapse=", "), " (n=", length(trt), ")\n\n", sep="")

# 创建分组因子（与代码完全相同）
group <- factor(c(rep("C", length(ctrl)), rep("T", length(trt))))
cat("2. 分组因子（代码中的方式）:\n")
cat("   group =", paste(group, collapse=", "), "\n")
cat("   水平(levels):", paste(levels(group), collapse=", "), "\n")
cat("   因子水平顺序:", paste(levels(group), collapse=", "), "\n")
cat("   参考组（第一个水平）:", levels(group)[1], "\n\n")

# 创建设计矩阵
design <- model.matrix(~ group)
cat("3. 原始设计矩阵:\n")
print(design)
cat("\n   原始列名:", paste(colnames(design), collapse=", "), "\n")
cat("   注意: 第二列是", colnames(design)[2], "\n\n")

# 代码中的重命名
colnames(design) <- c("Control", "Treatment")
cat("4. 重命名后的设计矩阵（代码中的操作）:\n")
cat("   列名:", paste(colnames(design), collapse=", "), "\n")
cat("   问题: 重命名可能不匹配实际含义！\n")
cat("         Intercept 被重命名为 'Control'\n")
cat("         groupT 被重命名为 'Treatment'\n\n")

# 尝试创建对比矩阵
cat("5. 尝试创建对比矩阵:\n")
tryCatch({
  cm <- limma::makeContrasts(TvsC = Treatment - Control, levels = design)
  cat("   ✓ 对比矩阵创建成功\n")
  print(cm)
}, error = function(e) {
  cat("   ✗ 错误:", e$message, "\n")
})

cat("\n6. 正确的方式应该是:\n")
# 重新创建正确的设计矩阵
design_correct <- model.matrix(~ group)
cat("   保持原始列名:", paste(colnames(design_correct), collapse=", "), "\n")
cat("   正确的对比矩阵: TvsC = groupT - groupC\n")
cat("   但groupC不存在（在截距中）\n\n")

cat("7. 正确的对比设置方式:\n")
cat("   方式1: 使用默认对比\n")
cat("     cm <- makeContrasts(TvsC = groupT, levels = design_correct)\n")
cat("     因为 groupT 已经代表 T vs C 的差异\n\n")

cat("   方式2: 显式设置因子水平\n")
group_explicit <- factor(c(rep("Control", length(ctrl)), rep("Treatment", length(trt))),
                         levels = c("Control", "Treatment"))
design_explicit <- model.matrix(~ group_explicit)
cat("     分组因子:", paste(group_explicit, collapse=", "), "\n")
cat("     设计矩阵列名:", paste(colnames(design_explicit), collapse=", "), "\n")
cat("     对比矩阵: TvsC = Treatment - Control\n")

cat("\n8. edgeR的对比方向:\n")
cat("   exactTest默认比较: 第二个水平 vs 第一个水平\n")
cat("   当前因子水平: ", paste(levels(group), collapse=", "), "\n")
cat("   所以比较: ", levels(group)[2], "vs", levels(group)[1], "\n")
cat("   即: 处理组(T) vs 对照组(C)\n")

cat("\n测试完成！\n")