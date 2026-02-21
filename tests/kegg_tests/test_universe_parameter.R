# =====================================================
# 测试 enrich_local_KEGG universe 参数
# =====================================================

cat("\n========================================\n")
cat("enrich_local_KEGG Universe 参数测试\n")
cat("========================================\n\n")

# 加载必要的包
required_packages <- c("biofree.qyKEGGtools", "org.Hs.eg.db")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("❌ 包 %s 未安装，请先安装:\n", pkg))
    cat(sprintf("   BiocManager::install('%s')\n", pkg))
    stop("缺少必要的包")
  }
}

cat("✅ 所有必要的包已加载\n\n")

# =====================================================
# 函数1：检查 enrich_local_KEGG 是否支持 universe
# =====================================================

check_universe_support <- function() {
  cat("1️⃣ 检查 enrich_local_KEGG 是否支持 universe 参数...\n")

  # 获取函数参数
  func_args <- formals(biofree.qyKEGGtools::enrich_local_KEGG)
  arg_names <- names(func_args)

  cat(sprintf("   函数参数: %s\n", paste(arg_names, collapse = ", ")))

  if ("universe" %in% arg_names) {
    cat("   ✅ 支持 universe 参数\n")
    return(TRUE)
  } else {
    cat("   ❌ 不支持 universe 参数\n")
    return(FALSE)
  }
}

# =====================================================
# 函数2：测试基础功能
# =====================================================

test_basic_functionality <- function() {
  cat("\n2️⃣ 测试基础功能...\n")

  # 准备测试数据
  deg_genes <- c("672", "7157", "7422", "5295", "7158")  # TP53, TGFBR1, BRAF, PIK3R1, TGFBR2

  cat(sprintf("   测试基因: %s\n", paste(deg_genes, collapse = ", ")))

  # 测试：不使用 universe
  cat("\n   测试 A: 不使用 universe（默认行为）...\n")

  tryCatch({
    result1 <- biofree.qyKEGGtools::enrich_local_KEGG(
      gene = deg_genes,
      species = "hsa",
      pCutoff = 0.05
    )

    cat(sprintf("   ✅ 成功！找到 %d 个显著通路\n", nrow(result1@result)))
    cat(sprintf("   输入基因数: %d\n", length(result1@gene)))
    cat(sprintf("   背景基因数: %s\n",
                ifelse(is.null(result1@universe), "NULL (全基因组)",
                       length(result1@universe))))

    if (nrow(result1@result) > 0) {
      cat("\n   Top 3 通路:\n")
      print(head(result1@result[, c("ID", "Description", "p.adjust", "BgRatio")], 3))
    }

    return(result1)

  }, error = function(e) {
    cat(sprintf("   ❌ 失败: %s\n", e$message))
    return(NULL)
  })
}

# =====================================================
# 函数3：测试 universe 参数（如果支持）
# =====================================================

test_universe_parameter <- function(has_universe_support) {
  cat("\n3️⃣ 测试 universe 参数...\n")

  if (!has_universe_support) {
    cat("   ⚠️ 跳过：当前版本不支持 universe 参数\n")
    cat("   💡 建议：使用 clusterProfiler::enrichKEGG 或更新 biofree.qyKEGGtools\n")
    return(NULL)
  }

  # 准备测试数据
  deg_genes <- c("672", "7157", "7422", "5295", "7158")
  background_genes <- c(
    "672", "7157", "7422", "5295", "7158", "1956",
    "673", "7423", "898", "9133", "10000", "20000",
    "30000", "40000", "50000", "60000", "70000"
  )

  cat(sprintf("   差异基因: %d 个\n", length(deg_genes)))
  cat(sprintf("   背景基因: %d 个\n", length(background_genes)))

  # 测试：使用 universe
  cat("\n   测试 B: 使用 universe（自定义背景）...\n")

  tryCatch({
    result2 <- biofree.qyKEGGtools::enrich_local_KEGG(
      gene = deg_genes,
      species = "hsa",
      universe = background_genes,
      pCutoff = 0.05
    )

    cat(sprintf("   ✅ 成功！找到 %d 个显著通路\n", nrow(result2@result)))
    cat(sprintf("   输入基因数: %d\n", length(result2@gene)))
    cat(sprintf("   背景基因数: %d\n", length(result2@universe)))

    if (nrow(result2@result) > 0) {
      cat("\n   Top 3 通路:\n")
      print(head(result2@result[, c("ID", "Description", "p.adjust", "BgRatio")], 3))

      # 验证 BgRatio
      bg_ratio <- strsplit(result2@result$BgRatio[1], "/")[[1]]
      M <- as.numeric(bg_ratio[2])

      cat(sprintf("\n   验证: BgRatio 分母 = %d (期望 %d) %s\n",
                  M, length(background_genes),
                  ifelse(M == length(background_genes), "✅", "❌")))
    }

    return(result2)

  }, error = function(e) {
    cat(sprintf("   ❌ 失败: %s\n", e$message))
    return(NULL)
  })
}

# =====================================================
# 函数4：测试参数验证
# =====================================================

test_parameter_validation <- function(has_universe_support) {
  cat("\n4️⃣ 测试参数验证...\n")

  if (!has_universe_support) {
    cat("   ⚠️ 跳过：当前版本不支持 universe 参数\n")
    return()
  }

  deg_genes <- c("672", "7157")

  # 测试1: 空的 universe
  cat("\n   测试 C: 空 universe（应该报错）...\n")

  tryCatch({
    result <- biofree.qyKEGGtools::enrich_local_KEGG(
      gene = deg_genes,
      species = "hsa",
      universe = character(0),
      pCutoff = 0.05
    )
    cat("   ❌ 应该报错但没有！\n")

  }, error = function(e) {
    cat(sprintf("   ✅ 正确捕获错误: %s\n", conditionMessage(e)))
  })

  # 测试2: 无效的 universe
  cat("\n   测试 D: 无效的 universe（应该报错）...\n")

  tryCatch({
    result <- biofree.qyKEGGtools::enrich_local_KEGG(
      gene = deg_genes,
      species = "hsa",
      universe = c("invalid1", "invalid2"),
      pCutoff = 0.05
    )
    cat("   ❌ 应该报错但没有！\n")

  }, error = function(e) {
    cat(sprintf("   ✅ 正确捕获错误: %s\n", conditionMessage(e)))
  })
}

# =====================================================
# 函数5：对比测试（有/无 universe）
# =====================================================

test_comparison <- function(has_universe_support, result1, result2) {
  cat("\n5️⃣ 对比测试（有/无 universe）...\n")

  if (!has_universe_support || is.null(result1) || is.null(result2)) {
    cat("   ⚠️ 跳过：缺少必要的测试结果\n")
    return()
  }

  cat(sprintf("   无 universe: %d 个通路\n", nrow(result1@result)))
  cat(sprintf("   有 universe: %d 个通路\n", nrow(result2@result)))

  # 共同通路
  common <- intersect(result1@result$ID, result2@result$ID)
  cat(sprintf("   共同通路: %d 个\n", length(common)))

  if (nrow(result1@result) > 0 && nrow(result2@result) > 0) {
    # 对比 BgRatio
    cat("\n   BgRatio 对比（第一个通路）:\n")
    cat(sprintf("   无 universe: %s\n", result1@result$BgRatio[1]))
    cat(sprintf("   有 universe: %s\n", result2@result$BgRatio[1]))
  }
}

# =====================================================
# 函数6：与 clusterProfiler 对比
# =====================================================

test_comparison_clusterprofiler <- function() {
  cat("\n6️⃣ 与 clusterProfiler::enrichKEGG 对比...\n")

  if (!require("clusterProfiler", quietly = TRUE)) {
    cat("   ⚠️ clusterProfiler 未安装，跳过此测试\n")
    return()
  }

  # 准备测试数据
  deg_genes <- c("672", "7157", "7422", "5295", "7158")
  background_genes <- c(
    "672", "7157", "7422", "5295", "7158", "1956",
    "673", "7423", "898", "9133", "10000"
  )

  cat(sprintf("   差异基因: %d 个\n", length(deg_genes)))
  cat(sprintf("   背景基因: %d 个\n", length(background_genes)))

  tryCatch({
    result_cp <- clusterProfiler::enrichKEGG(
      gene = deg_genes,
      organism = "hsa",
      universe = background_genes,
      pvalueCutoff = 0.05
    )

    cat(sprintf("   ✅ clusterProfiler 成功！找到 %d 个显著通路\n",
                nrow(result_cp@result)))

    if (nrow(result_cp@result) > 0) {
      cat("\n   Top 3 通路:\n")
      print(head(result_cp@result[, c("ID", "Description", "p.adjust", "BgRatio")], 3))
    }

    return(result_cp)

  }, error = function(e) {
    cat(sprintf("   ❌ clusterProfiler 失败: %s\n", e$message))
    return(NULL)
  })
}

# =====================================================
# 主测试流程
# =====================================================

main <- function() {
  cat("开始测试...\n\n")

  # 步骤1：检查 universe 支持
  has_universe_support <- check_universe_support()

  # 步骤2：测试基础功能
  result1 <- test_basic_functionality()

  # 步骤3：测试 universe 参数
  result2 <- test_universe_parameter(has_universe_support)

  # 步骤4：测试参数验证
  test_parameter_validation(has_universe_support)

  # 步骤5：对比测试
  test_comparison(has_universe_support, result1, result2)

  # 步骤6：与 clusterProfiler 对比
  result_cp <- test_comparison_clusterprofiler()

  # =====================================================
  # 总结
  # =====================================================

  cat("\n========================================\n")
  cat("测试总结\n")
  cat("========================================\n\n")

  cat(sprintf("1. universe 参数支持: %s\n",
              ifelse(has_universe_support, "✅ 是", "❌ 否")))

  cat(sprintf("2. 基础功能测试: %s\n",
              ifelse(!is.null(result1), "✅ 通过", "❌ 失败")))

  if (has_universe_support) {
    cat(sprintf("3. universe 参数测试: %s\n",
                ifelse(!is.null(result2), "✅ 通过", "❌ 失败")))
  }

  cat(sprintf("4. clusterProfiler 可用: %s\n",
              ifelse(!is.null(result_cp), "✅ 是", "❌ 否")))

  cat("\n")

  if (!has_universe_support) {
    cat("💡 建议:\n")
    cat("   1. 使用 clusterProfiler::enrichKEGG（支持 universe）\n")
    cat("   2. 或更新 biofree.qyKEGGtools 到支持 universe 的版本\n")
    cat("   3. 参考文档: docs/ENRICH_LOCAL_KEGG_UNIVERSE_IMPLEMENTATION.md\n")
  } else {
    cat("✅ 恭喜！您的 enrich_local_KEGG 已支持 universe 参数\n")
  }

  cat("\n========================================\n")
  cat("测试完成\n")
  cat("========================================\n\n")
}

# 运行主测试
main()
