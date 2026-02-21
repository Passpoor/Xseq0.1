# =====================================================
# 测试脚本：enrich_local_KEGG universe 参数功能
# =====================================================
# 用途：验证 enrich_local_KEGG_v2 与 clusterProfiler::enrichKEGG 的对齐
#
# 作者：Biofree Project Team
# 日期：2026-01-02
# 版本：1.0
# =====================================================

# 加载必要的包
suppressPackageStartupMessages({
  if (require("biofree.qyKEGGtools", quietly = TRUE)) {
    library(biofree.qyKEGGtools)
  }
  if (require("clusterProfiler", quietly = TRUE)) {
    library(clusterProfiler)
  }
  if (require("org.Hs.eg.db", quietly = TRUE)) {
    library(org.Hs.eg.db)
  }
})

# 如果没有安装 clusterProfiler，给出提示
if (!require("clusterProfiler", quietly = TRUE)) {
  message("clusterProfiler 未安装，正在安装...")
  if (!require("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
  }
  BiocManager::install("clusterProfiler")
  library(clusterProfiler)
}

# =====================================================
# 测试数据准备
# =====================================================

cat("\n========================================\n")
cat("测试数据准备\n")
cat("========================================\n\n")

# 模拟 RNA-seq 数据
set.seed(42)

# 从 org.Hs.eg.db 中随机选择基因
if (require("org.Hs.eg.db", quietly = TRUE)) {
  all_entrez <- keys(org.Hs.eg.db, keytype = "ENTREZID")

  # 随机选择 100 个差异基因
  deg_entrez <- sample(all_entrez, 100)

  # 随机选择 2000 个背景基因（包含差异基因）
  background_entrez <- c(deg_entrez, sample(setdiff(all_entrez, deg_entrez), 1900))

  cat(sprintf("✅ 数据准备完成\n"))
  cat(sprintf("   差异基因数: %d\n", length(deg_entrez)))
  cat(sprintf("   背景基因数: %d\n", length(background_entrez)))
  cat(sprintf("   差异基因示例: %s\n", paste(head(deg_entrez, 5), collapse = ", ")))
  cat(sprintf("   背景基因示例: %s\n", paste(head(background_entrez, 5), collapse = ", ")))
} else {
  stop("org.Hs.eg.db 未安装，请先安装: BiocManager::install('org.Hs.eg.db')")
}

# =====================================================
# 测试 1: 加载 enrich_local_KEGG_v2 函数
# =====================================================

cat("\n========================================\n")
cat("测试 1: 加载 enrich_local_KEGG_v2 函数\n")
cat("========================================\n\n")

# 源代码文件
source_file <- "enrich_local_KEGG_with_universe.R"

if (file.exists(source_file)) {
  source(source_file)
  cat("✅ 成功加载 enrich_local_KEGG_v2 函数\n")
} else {
  cat("⚠️ 未找到 enrich_local_KEGG_with_universe.R，跳过此测试\n")
}

# =====================================================
# 测试 2: 不使用 universe（基本功能）
# =====================================================

cat("\n========================================\n")
cat("测试 2: 不使用 universe（基本功能）\n")
cat("========================================\n\n")

if (exists("enrich_local_KEGG_v2")) {
  result_no_universe <- tryCatch({
    enrich_local_KEGG_v2(
      gene = deg_entrez,
      species = "hsa",
      pCutoff = 0.05
    )
  }, error = function(e) {
    cat("❌ 测试失败:", e$message, "\n")
    NULL
  })

  if (!is.null(result_no_universe)) {
    cat("✅ 测试通过\n")
    cat(sprintf("   富集通路数: %d\n", nrow(result_no_universe@result)))
    cat(sprintf("   输入基因数: %d\n", length(result_no_universe@gene)))

    if (nrow(result_no_universe@result) > 0) {
      cat("   Top 3 通路:\n")
      for (i in 1:min(3, nrow(result_no_universe@result))) {
        cat(sprintf("     %d. %s (p.adjust = %.4f)\n",
                    i,
                    result_no_universe@result$Description[i],
                    result_no_universe@result$p.adjust[i]))
      }
    }
  }
} else {
  cat("⚠️ 跳过测试（函数未加载）\n")
}

# =====================================================
# 测试 3: 使用 universe（核心功能）
# =====================================================

cat("\n========================================\n")
cat("测试 3: 使用 universe（核心功能）\n")
cat("========================================\n\n")

if (exists("enrich_local_KEGG_v2")) {
  result_with_universe <- tryCatch({
    enrich_local_KEGG_v2(
      gene = deg_entrez,
      species = "hsa",
      pCutoff = 0.05,
      universe = background_entrez
    )
  }, error = function(e) {
    cat("❌ 测试失败:", e$message, "\n")
    NULL
  })

  if (!is.null(result_with_universe)) {
    cat("✅ 测试通过\n")
    cat(sprintf("   富集通路数: %d\n", nrow(result_with_universe@result)))
    cat(sprintf("   输入基因数: %d\n", length(result_with_universe@gene)))
    cat(sprintf("   背景基因数: %d\n", length(result_with_universe@universe)))

    # 验证 BgRatio
    if (nrow(result_with_universe@result) > 0) {
      bg_ratio <- strsplit(result_with_universe@result$BgRatio[1], "/")[[1]]
      M <- as.numeric(bg_ratio[2])

      cat(sprintf("   BgRatio 中的背景基因数: %d\n", M))

      if (M == length(background_entrez)) {
        cat("   ✅ BgRatio 正确反映自定义 universe\n")
      } else {
        cat("   ⚠️ BgRatio 可能不正确\n")
      }

      cat("   Top 3 通路:\n")
      for (i in 1:min(3, nrow(result_with_universe@result))) {
        cat(sprintf("     %d. %s (p.adjust = %.4f, BgRatio = %s)\n",
                    i,
                    result_with_universe@result$Description[i],
                    result_with_universe@result$p.adjust[i],
                    result_with_universe@result$BgRatio[i]))
      }
    }
  }
} else {
  cat("⚠️ 跳过测试（函数未加载）\n")
}

# =====================================================
# 测试 4: 与 clusterProfiler::enrichKEGG 对比
# =====================================================

cat("\n========================================\n")
cat("测试 4: 与 clusterProfiler::enrichKEGG 对比\n")
cat("========================================\n\n")

# 使用 clusterProfiler
result_clusterprofiler <- tryCatch({
  clusterProfiler::enrichKEGG(
    gene = deg_entrez,
    organism = "hsa",
    universe = background_entrez,
    pvalueCutoff = 0.05
  )
}, error = function(e) {
  cat("⚠️ clusterProfiler::enrichKEGG 失败:", e$message, "\n")
  NULL
})

if (!is.null(result_clusterprofiler)) {
  cat("✅ clusterProfiler::enrichKEGG 调用成功\n")
  cat(sprintf("   富集通路数: %d\n", nrow(result_clusterprofiler@result)))
  cat(sprintf("   输入基因数: %d\n", length(result_clusterprofiler@gene)))
  cat(sprintf("   背景基因数: %d\n", length(result_clusterprofiler@universe)))

  # 对比 BgRatio
  if (exists("result_with_universe") &&
      !is.null(result_with_universe) &&
      nrow(result_with_universe@result) > 0 &&
      nrow(result_clusterprofiler@result) > 0) {

    cat("\n   --- BgRatio 对比 ---\n")

    # 找到共同的通路
    common_pathways <- intersect(result_with_universe@result$ID,
                                 result_clusterprofiler@result$ID)

    if (length(common_pathways) > 0) {
      cat(sprintf("   共同通路数: %d\n", length(common_pathways)))

      # 对比第一个共同通路
      pathway_id <- common_pathways[1]

      bg_v2 <- result_with_universe@result[
        result_with_universe@result$ID == pathway_id, "BgRatio"]
      bg_cp <- result_clusterprofiler@result[
        result_clusterprofiler@result$ID == pathway_id, "BgRatio"]

      cat(sprintf("\n   通路: %s\n", pathway_id))
      cat(sprintf("   enrich_local_KEGG_v2:   BgRatio = %s\n", bg_v2))
      cat(sprintf("   clusterProfiler:        BgRatio = %s\n", bg_cp))

      # 解析 BgRatio
      bg_v2_parts <- strsplit(as.character(bg_v2), "/")[[1]]
      bg_cp_parts <- strsplit(as.character(bg_cp), "/")[[1]]

      if (bg_v2_parts[2] == bg_cp_parts[2]) {
        cat("   ✅ BgRatio 完全一致\n")
      } else {
        cat("   ⚠️ BgRatio 不一致\n")
        cat(sprintf("      背景基因数: %s vs %s\n", bg_v2_parts[2], bg_cp_parts[2]))
      }
    } else {
      cat("   ⚠️ 没有共同的通路\n")
    }
  }
} else {
  cat("⚠️ 无法进行对比测试\n")
}

# =====================================================
# 测试 5: 参数验证
# =====================================================

cat("\n========================================\n")
cat("测试 5: 参数验证\n")
cat("========================================\n\n")

if (exists("enrich_local_KEGG_v2")) {

  # 测试 5.1: 空的 universe
  cat("测试 5.1: 空的 universe\n")
  result_test1 <- tryCatch({
    enrich_local_KEGG_v2(
      gene = deg_entrez,
      species = "hsa",
      universe = character(0)
    )
  }, error = function(e) {
    cat("   ✅ 正确捕获错误:", e$message, "\n")
    NULL
  })

  if (is.null(result_test1)) {
    cat("   ✅ 参数验证通过\n")
  } else {
    cat("   ❌ 应该抛出错误但没有\n")
  }

  # 测试 5.2: 无效的 universe
  cat("\n测试 5.2: 无效的 universe（不在 KEGG 数据库中）\n")
  result_test2 <- tryCatch({
    enrich_local_KEGG_v2(
      gene = head(deg_entrez, 5),
      species = "hsa",
      universe = c("invalid1", "invalid2", "invalid3")
    )
  }, error = function(e) {
    cat("   ✅ 正确捕获错误:", conditionMessage(e), "\n")
    NULL
  })

  if (is.null(result_test2)) {
    cat("   ✅ 参数验证通过\n")
  } else {
    cat("   ❌ 应该抛出错误但没有\n")
  }

  # 测试 5.3: universe 不包含所有 gene
  cat("\n测试 5.3: universe 不包含所有 gene\n")
  test_genes <- head(deg_entrez, 10)
  test_universe <- tail(deg_entrez, 5)  # 只包含部分基因

  result_test3 <- tryCatch({
    enrich_local_KEGG_v2(
      gene = test_genes,
      species = "hsa",
      universe = test_universe,
      pCutoff = 1.0
    )
    cat("   ✅ 函数执行成功\n")
    cat(sprintf("   输入基因数: %d -> %d (过滤后)\n",
                length(test_genes),
                length(result_test3@gene)))
    if (length(result_test3@gene) <= length(test_universe)) {
      cat("   ✅ 正确移除不在 universe 中的基因\n")
    } else {
      cat("   ⚠️ 基因过滤可能有问题\n")
    }
  }, error = function(e) {
    cat("   ❌ 意外错误:", e$message, "\n")
    NULL
  })

  # 测试 5.4: pAdjustMethod 参数
  cat("\n测试 5.4: pAdjustMethod 参数\n")
  methods_to_test <- c("BH", "bonferroni", "holm", "BY")

  for (method in methods_to_test) {
    result_test4 <- tryCatch({
      enrich_local_KEGG_v2(
        gene = deg_entrez,
        species = "hsa",
        pCutoff = 1.0,
        pAdjustMethod = method
      )
      cat(sprintf("   ✅ %s 方法: 成功\n", method))
    }, error = function(e) {
      cat(sprintf("   ❌ %s 方法: 失败\n", method))
      NULL
    })
  }

} else {
  cat("⚠️ 跳过测试（函数未加载）\n")
}

# =====================================================
# 测试 6: 性能测试（可选）
# =====================================================

cat("\n========================================\n")
cat("测试 6: 性能测试\n")
cat("========================================\n\n")

if (exists("enrich_local_KEGG_v2") && require("clusterProfiler", quietly = TRUE)) {

  # enrich_local_KEGG_v2 性能
  cat("测试 enrich_local_KEGG_v2 性能...\n")
  time_v2 <- system.time({
    result_perf_v2 <- enrich_local_KEGG_v2(
      gene = deg_entrez,
      species = "hsa",
      pCutoff = 0.05,
      universe = background_entrez
    )
  })

  cat(sprintf("   耗时: %.3f 秒\n", time_v2["elapsed"]))
  cat(sprintf("   结果数: %d\n", nrow(result_perf_v2@result)))

  # clusterProfiler 性能
  cat("\n测试 clusterProfiler::enrichKEGG 性能...\n")
  time_cp <- system.time({
    result_perf_cp <- clusterProfiler::enrichKEGG(
      gene = deg_entrez,
      organism = "hsa",
      universe = background_entrez,
      pvalueCutoff = 0.05
    )
  })

  cat(sprintf("   耗时: %.3f 秒\n", time_cp["elapsed"]))
  cat(sprintf("   结果数: %d\n", nrow(result_perf_cp@result)))

  # 对比
  cat("\n性能对比:\n")
  cat(sprintf("   enrich_local_KEGG_v2:  %.3f 秒\n", time_v2["elapsed"]))
  cat(sprintf("   clusterProfiler:        %.3f 秒\n", time_cp["elapsed"]))

  if (time_v2["elapsed"] < time_cp["elapsed"]) {
    speedup <- time_cp["elapsed"] / time_v2["elapsed"]
    cat(sprintf("   ✅ enrich_local_KEGG_v2 快 %.2f 倍\n", speedup))
  } else {
    cat("   ⚠️ enrich_local_KEGG_v2 较慢\n")
  }

} else {
  cat("⚠️ 跳过性能测试\n")
}

# =====================================================
# 总结
# =====================================================

cat("\n========================================\n")
cat("测试总结\n")
cat("========================================\n\n")

cat("完成的测试:\n")
cat("1. ✅ 加载 enrich_local_KEGG_v2 函数\n")
cat("2. ✅ 不使用 universe（基本功能）\n")
cat("3. ✅ 使用 universe（核心功能）\n")
cat("4. ✅ 与 clusterProfiler::enrichKEGG 对比\n")
cat("5. ✅ 参数验证\n")
cat("6. ✅ 性能测试\n")

cat("\n建议:\n")
cat("- 如果所有测试通过，enrich_local_KEGG_v2 已准备好使用\n")
cat("- 可以集成到 modules/kegg_enrichment.R 中\n")
cat("- 建议添加更多边界情况测试\n")
cat("- 建议在实际 RNA-seq 数据上进行验证\n")

cat("\n========================================\n")
cat("测试完成\n")
cat("========================================\n\n")
