# =====================================================
# 深入学习 biofree.qyKEGGtools 包
# =====================================================

cat("\n========================================\n")
cat("biofree.qyKEGGtools 深度学习报告\n")
cat("========================================\n\n")

# 1. 检查包的安装和加载
cat("【1】包的安装状态\n")
cat("----------------------------------------\n")
if (!require("biofree.qyKEGGtools", quietly = TRUE)) {
  cat("❌ biofree.qyKEGGtools 未安装\n")
  cat("正在尝试安装...\n")
  install.packages("biofree.qyKEGGtools")
}

library(biofree.qyKEGGtools)
cat("✅ 包已加载\n")
cat("版本:", packageVersion("biofree.qyKEGGtools"), "\n")
cat("路径:", system.file(package = "biofree.qyKEGGtools"), "\n\n")

# 2. 分析 enrich_local_KEGG 函数
cat("【2】enrich_local_KEGG 函数分析\n")
cat("----------------------------------------\n")

# 2.1 查看函数签名
cat("\n2.1 函数签名:\n")
func_args <- formals(biofree.qyKEGGtools::enrich_local_KEGG)
cat("参数列表:\n")
for (arg_name in names(func_args)) {
  arg_value <- func_args[[arg_name]]
  cat(sprintf("  - %s: %s\n", arg_name,
              ifelse(is.null(arg_value) || is.symbol(arg_value),
                     "默认值: NULL",
                     paste0("默认值: ", deparse(arg_value)))))
}

# 2.2 查看函数源代码
cat("\n2.2 函数源代码:\n")
func_source <- capture.output(print(biofree.qyKEGGtools::enrich_local_KEGG))
cat(paste(func_source, collapse = "\n"), "\n")

# 2.3 查看函数文档
cat("\n2.3 函数文档:\n")
# 获取帮助文档的文本
help_text <- tryCatch({
  tools:::Rd2txt(utils::help("enrich_local_KEGG", package = "biofree.qyKEGGtools"))
}, error = function(e) {
  "无法获取文档"
})
cat(help_text, "\n")

# 3. 检查包的其他函数
cat("\n【3】包的所有导出函数\n")
cat("----------------------------------------\n")
exports <- ls("package:biofree.qyKEGGtools")
cat(sprintf("共找到 %d 个函数/对象:\n\n", length(exports)))

# 分类显示
functions_list <- character(0)
data_list <- character(0)
other_list <- character(0)

for (item in exports) {
  if (exists(item, mode = "function")) {
    functions_list <- c(functions_list, item)
  } else if (exists(item, mode = "list") || exists(item, mode = "environment")) {
    data_list <- c(data_list, item)
  } else {
    other_list <- c(other_list, item)
  }
}

cat("函数 (", length(functions_list), " 个):\n")
if (length(functions_list) > 0) {
  cat(paste("  -", functions_list), sep = "\n")
}

cat("\n数据/对象 (", length(data_list), " 个):\n")
if (length(data_list) > 0) {
  cat(paste("  -", data_list), sep = "\n")
}

cat("\n其他 (", length(other_list), " 个):\n")
if (length(other_list) > 0) {
  cat(paste("  -", other_list), sep = "\n")
}

# 4. 检查依赖的包
cat("\n【4】包的依赖关系\n")
cat("----------------------------------------\n")
deps <- tools::package_dependencies("biofree.qyKEGGtools",
                                    db = available.packages(),
                                    which = c("Depends", "Imports", "LinkingTo"),
                                    recursive = FALSE)
cat("直接依赖:\n")
if (length(deps[[1]]) > 0) {
  cat(paste("  -", deps[[1]]), sep = "\n")
} else {
  cat("  无直接依赖\n")

# 5. 查看包的目录结构
cat("\n【5】包的目录结构\n")
cat("----------------------------------------\n")
pkg_path <- system.file(package = "biofree.qyKEGGtools")
dirs <- list.dirs(pkg_path, full.names = FALSE, recursive = TRUE)
cat(paste(dirs, sep = "\n"), "\n")

# 6. 检查是否有示例数据
cat("\n【6】示例数据\n")
cat("----------------------------------------\n")
data_files <- list.files(pkg_path, pattern = "\\.rda|\\.rdata|\\.rds$", recursive = TRUE, ignore.case = TRUE)
if (length(data_files) > 0) {
  cat(sprintf("找到 %d 个数据文件:\n", length(data_files)))
  cat(paste("  -", data_files), sep = "\n")
} else {
  cat("未找到示例数据文件\n")
}

# 7. 测试函数功能
cat("\n【7】功能测试\n")
cat("----------------------------------------\n")

# 使用简单的测试基因
test_genes <- c("672", "7157", "7422", "5295", "7158")
cat(sprintf("测试基因 (ENTREZID): %s\n", paste(test_genes, collapse = ", ")))
cat(sprintf("测试物种: hsa (人类)\n\n"))

# 测试调用
test_result <- tryCatch({
  cat("调用 enrich_local_KEGG...\n")
  result <- enrich_local_KEGG(
    gene = test_genes,
    species = "hsa",
    pCutoff = 0.05
  )

  cat("\n✅ 调用成功\n\n")

  # 分析返回值
  cat("返回值类型:", class(result), "\n")
  cat("返回值结构:\n")
  str(result, max.level = 2)

  # 如果是 enrichResult 对象
  if (inherits(result, "enrichResult")) {
    cat("\n这是一个 enrichResult 对象\n")
    cat("结果表格维度:", dim(result@result), "\n")

    if (nrow(result@result) > 0) {
      cat("\n前5个富集通路:\n")
      print(head(result@result[, c("ID", "Description", "p.adjust", "geneID")], 5))
    } else {
      cat("\n没有显著富集的通路\n")
    }

    # 检查是否有 universe 参数
    cat("\n检查 enrichResult 对象的槽:\n")
    slots <- slotNames(result)
    cat(paste("  -", slots), sep = "\n")

    if ("universe" %in% slots) {
      cat("\n✅ 支持 universe 参数\n")
      cat("universe 内容:", head(result@universe, 10), "...\n")
    } else {
      cat("\n❌ 不支持 universe 参数（未在 enrichResult 对象中存储）\n")
    }
  } else if (is.data.frame(result)) {
    cat("\n这是一个数据框\n")
    cat("维度:", dim(result), "\n")
    if (nrow(result) > 0) {
      cat("\n前5行:\n")
      print(head(result, 5))
    }
  }

  result
}, error = function(e) {
  cat("\n❌ 测试失败\n")
  cat("错误信息:", e$message, "\n")
  NULL
})

# 8. 与 clusterProfiler::enrichKEGG 对比
cat("\n【8】与 clusterProfiler::enrichKEGG 的对比\n")
cat("----------------------------------------\n")

if (require("clusterProfiler", quietly = TRUE)) {
  cat("✅ clusterProfiler 已安装\n\n")

  # 获取 clusterProfiler::enrichKEGG 的参数
  cp_args <- formals(clusterProfiler::enrichKEGG)
  cat("clusterProfiler::enrichKEGG 参数:\n")
  for (arg_name in names(cp_args)) {
    cat(sprintf("  - %s\n", arg_name))
  }

  # 对比 universe 参数支持
  if ("universe" %in% names(cp_args)) {
    cat("\n✅ clusterProfiler::enrichKEGG 支持 universe 参数\n")
  } else {
    cat("\n❌ clusterProfiler::enrichKEGG 不支持 universe 参数\n")
  }

  # 测试 clusterProfiler::enrichKEGG
  cat("\n测试 clusterProfiler::enrichKEGG...\n")
  cp_result <- tryCatch({
    result <- clusterProfiler::enrichKEGG(
      gene = test_genes,
      organism = "hsa",
      pvalueCutoff = 0.05
    )
    cat("✅ clusterProfiler::enrichKEGG 调用成功\n")
    result
  }, error = function(e) {
    cat("⚠️ clusterProfiler::enrichKEGG 调用失败:", e$message, "\n")
    NULL
  })

  if (!is.null(cp_result)) {
    cat("\nclusterProfiler 结果数量:", nrow(cp_result@result), "\n")
  }

} else {
  cat("❌ clusterProfiler 未安装\n")
}

# 9. 性能测试（如果两个包都可用）
cat("\n【9】性能对比（可选）\n")
cat("----------------------------------------\n")

if (!is.null(test_result) && !is.null(cp_result)) {
  cat("可以进行性能对比测试\n")
} else {
  cat("无法进行性能对比测试\n")
}

# 10. 总结和建议
cat("\n【10】总结和建议\n")
cat("----------------------------------------\n")

cat("关于 biofree.qyKEGGtools::enrich_local_KEGG:\n")
cat("1. 函数用途: 本地 KEGG 通路富集分析\n")
cat("2. 主要参数: gene, species, pCutoff, qCutoff\n")
cat("3. 返回值类型:", class(test_result)[1], "\n")

if (inherits(test_result, "enrichResult")) {
  cat("4. 兼容性: 与 clusterProfiler 的 enrichResult 类兼容\n")
} else {
  cat("4. 兼容性: 使用自定义数据框格式\n")
}

cat("5. universe 参数支持: ",
    if ("universe" %in% names(func_args)) "是" else "否",
    "\n")

cat("\n使用建议:\n")

if (!("universe" %in% names(func_args))) {
  cat("⚠️ 注意: enrich_local_KEGG 不支持 universe 参数\n")
  cat("   - 这意味着无法自定义背景基因集\n")
  cat("   - 统计检验使用数据库内置的全基因组背景\n")
  cat("   - 可能增加假阳性率\n")
  cat("   - 建议: 对于需要精确背景基因集的分析，考虑使用 clusterProfiler::enrichKEGG\n")
}

cat("\n替代方案:\n")
if (require("clusterProfiler", quietly = TRUE)) {
  cat("✅ clusterProfiler::enrichKEGG\n")
  cat("   - 优点: 支持 universe 参数，文档完善，社区活跃\n")
  cat("   - 缺点: 需要网络连接下载 KEGG 数据（首次使用）\n")
}

cat("\n========================================\n")
cat("报告结束\n")
cat("========================================\n\n")
