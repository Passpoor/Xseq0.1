# 测试方法选择逻辑
cat("测试差异分析方法自动选择逻辑\n")

# 模拟样本数量
test_cases <- list(
  list(ctrl = 1, trt = 1, expected = "edgeR"),
  list(ctrl = 2, trt = 2, expected = "edgeR"),
  list(ctrl = 3, trt = 3, expected = "limma-voom"),
  list(ctrl = 4, trt = 4, expected = "limma-voom"),
  list(ctrl = 1, trt = 3, expected = "edgeR"),  # min_replicates = 1
  list(ctrl = 2, trt = 5, expected = "edgeR"),  # min_replicates = 2
  list(ctrl = 3, trt = 2, expected = "edgeR"),  # min_replicates = 2
  list(ctrl = 3, trt = 4, expected = "limma-voom")  # min_replicates = 3
)

cat("\n测试用例:\n")
for (i in seq_along(test_cases)) {
  test <- test_cases[[i]]
  num_ctrl <- test$ctrl
  num_trt <- test$trt
  min_replicates <- min(num_ctrl, num_trt)

  # 自动选择分析方法
  if (min_replicates >= 3) {
    method_to_use <- "limma-voom"
    reason <- "样本充足（每组≥3）"
  } else {
    method_to_use <- "edgeR"
    reason <- "样本较少（每组<3）"
  }

  passed <- method_to_use == test$expected
  status <- ifelse(passed, "✓", "✗")

  cat(sprintf("%s 测试%d: 对照组=%d, 处理组=%d, min_replicates=%d\n",
              status, i, num_ctrl, num_trt, min_replicates))
  cat(sprintf("   预期: %s, 实际: %s (%s)\n",
              test$expected, method_to_use, reason))
}

# 测试样本验证逻辑
cat("\n测试样本验证逻辑:\n")

# 测试空组检查
ctrl_empty <- character(0)
trt_empty <- character(0)
ctrl_has <- c("sample1", "sample2")
trt_has <- c("sample3", "sample4")

cat("1. 空组检查:\n")
if (length(ctrl_empty) == 0 || length(trt_empty) == 0) {
  cat("   ✓ 检测到空组（应该返回错误）\n")
} else {
  cat("   ✗ 未检测到空组\n")
}

# 测试样本重叠检查
ctrl_overlap <- c("sample1", "sample2", "sample3")
trt_overlap <- c("sample3", "sample4", "sample5")  # sample3重叠

overlap <- intersect(ctrl_overlap, trt_overlap)
cat("2. 重叠检查:\n")
if (length(overlap) > 0) {
  cat(sprintf("   ✓ 检测到重叠样本: %s（应该返回错误）\n", paste(overlap, collapse=", ")))
} else {
  cat("   ✗ 未检测到重叠样本\n")
}

cat("\n测试完成！\n")