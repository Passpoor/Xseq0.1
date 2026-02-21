# KEGG/GO分析错误诊断脚本
library(shiny)
library(AnnotationDbi)
library(dplyr)

# 模拟差异分析结果数据
create_test_data <- function() {
  # 创建测试数据 - 包含常见问题
  gene_ids <- c(
    # 正常的人类基因符号（大写）
    "TP53", "BRCA1", "EGFR", "MYC", "ACTB", "GAPDH",
    # 正常的小鼠基因符号（首字母大写）
    "Trp53", "Brca1", "Egfr", "Myc", "Actb", "Gapdh",
    # 可能的问题基因符号
    "tp53",  # 小写
    "BRCA-1", # 包含连字符
    "EGFR ",  # 包含空格
    "MYC\t",  # 包含制表符
    "ENSG00000141510", # ENSEMBL ID
    "ENSMUSG00000059552", # 小鼠ENSEMBL ID
    "12345",  # ENTREZID
    "gene1",  # 自定义ID
    "LOC100101", # LOC基因
    "Gm12345", # 假基因
    "Rik123",  # Rik基因
    "gene-ps"  # 假基因后缀
  )

  n_genes <- length(gene_ids)
  test_data <- data.frame(
    GeneID = gene_ids,
    logFC = rnorm(n_genes, 0, 2),
    p_val = runif(n_genes, 0, 0.05),
    p_val_adj = runif(n_genes, 0, 0.05),
    Status = sample(c("Up", "Down"), n_genes, replace = TRUE),
    stringsAsFactors = FALSE
  )

  return(test_data)
}

# 测试基因注释函数
test_annotation <- function(gene_ids, species_code) {
  cat("\n=== 测试基因注释函数 ===\n")
  cat("物种:", species_code, "\n")
  cat("基因数量:", length(gene_ids), "\n")
  cat("前10个基因:", paste(head(gene_ids, 10), collapse=", "), "\n")

  db_pkg <- if(species_code == "Mm") "org.Mm.eg.db" else "org.Hs.eg.db"
  cat("使用的数据库包:", db_pkg, "\n")

  if (!require(db_pkg, character.only = TRUE, quietly = TRUE)) {
    cat("错误: 数据库包", db_pkg, "未安装\n")
    return(NULL)
  }

  db_obj <- get(db_pkg)
  clean_ids <- gsub("\\..*", "", gene_ids)

  # 清理基因符号
  clean_ids <- trimws(clean_ids)  # 去除空格
  clean_ids <- gsub("[\t\n\r]", "", clean_ids)  # 去除空白字符

  cat("清理后的基因符号示例:", paste(head(clean_ids, 5), collapse=", "), "\n")

  # 尝试不同keytype
  keytypes_to_try <- c("SYMBOL", "ENSEMBL", "ENTREZID", "ALIAS")

  for (keytype in keytypes_to_try) {
    cat("\n尝试keytype:", keytype, "\n")

    tryCatch({
      # 先检查是否有匹配的key
      keys_in_db <- keys(db_obj, keytype = keytype)
      matched <- clean_ids[clean_ids %in% keys_in_db]

      if (length(matched) > 0) {
        cat("  找到", length(matched), "个匹配的基因\n")
        cat("  匹配的基因示例:", paste(head(matched, 5), collapse=", "), "\n")

        # 尝试注释
        anno <- AnnotationDbi::select(db_obj,
                                     keys = matched,
                                     columns = c("SYMBOL", "ENTREZID"),
                                     keytype = keytype)

        if (nrow(anno) > 0) {
          cat("  成功注释", nrow(anno), "个基因\n")
          print(head(anno))
          return(anno)
        }
      } else {
        cat("  没有找到匹配的基因\n")
      }
    }, error = function(e) {
      cat("  错误:", e$message, "\n")
    })
  }

  cat("\n所有keytype尝试都失败了\n")
  return(NULL)
}

# 测试KEGG/GO分析中的基因转换
test_kegg_go_conversion <- function() {
  cat("=== 测试KEGG/GO分析中的基因转换 ===\n")

  # 创建测试数据
  test_data <- create_test_data()

  # 测试人类基因
  cat("\n--- 测试人类基因 ---\n")
  human_genes <- test_data$GeneID
  human_anno <- test_annotation(human_genes, "Hs")

  # 测试小鼠基因
  cat("\n--- 测试小鼠基因 ---\n")
  mouse_genes <- test_data$GeneID
  mouse_anno <- test_annotation(mouse_genes, "Mm")

  # 检查差异分析结果中的ENTREZID
  cat("\n=== 检查差异分析结果中的ENTREZID ===\n")

  # 模拟差异分析结果
  if (!is.null(human_anno)) {
    # 合并注释结果
    res <- merge(test_data, human_anno, by.x = "GeneID", by.y = "SYMBOL", all.x = TRUE)

    cat("人类基因注释结果:\n")
    cat("总基因数:", nrow(res), "\n")
    cat("成功注释的基因数:", sum(!is.na(res$ENTREZID)), "\n")
    cat("未注释的基因数:", sum(is.na(res$ENTREZID)), "\n")

    # 显示未注释的基因
    unannotated <- res[is.na(res$ENTREZID), "GeneID"]
    cat("未注释的基因示例:", paste(head(unannotated, 10), collapse=", "), "\n")
  }

  # 测试mapIds函数（KEGG/GO模块中使用的）
  cat("\n=== 测试mapIds函数 ===\n")

  if (require("org.Hs.eg.db", quietly = TRUE)) {
    test_symbols <- c("TP53", "BRCA1", "NOT_A_GENE", "tp53", "BRCA-1")

    cat("测试基因符号:", paste(test_symbols, collapse=", "), "\n")

    tryCatch({
      entrez_ids <- AnnotationDbi::mapIds(org.Hs.eg.db,
                                         keys = test_symbols,
                                         column = "ENTREZID",
                                         keytype = "SYMBOL",
                                         multiVals = "first")
      cat("mapIds结果:\n")
      print(entrez_ids)
    }, error = function(e) {
      cat("mapIds错误:", e$message, "\n")
      cat("错误类型:", class(e), "\n")
    })
  }
}

# 检查包安装情况
check_packages <- function() {
  cat("=== 检查必要的R包 ===\n")

  required_packages <- c(
    "shiny", "shinyjs", "bslib", "RSQLite", "DBI", "ggplot2", "dplyr", "DT",
    "pheatmap", "plotly", "colourpicker", "shinyWidgets", "rlang",
    "edgeR", "limma", "AnnotationDbi", "clusterProfiler",
    "org.Mm.eg.db", "org.Hs.eg.db", "decoupleR", "tibble", "tidyr",
    "ggrepel", "RColorBrewer", "VennDiagram", "grid", "gridExtra"
  )

  for (pkg in required_packages) {
    if (require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat("✓", pkg, "\n")
    } else {
      cat("✗", pkg, "未安装\n")
    }
  }
}

# 运行诊断
cat("开始KEGG/GO分析错误诊断...\n")
check_packages()
test_kegg_go_conversion()

cat("\n=== 常见问题解决方案 ===\n")
cat("1. 基因符号大小写问题:\n")
cat("   - 人类基因: 必须大写 (TP53, 不是 tp53)\n")
cat("   - 小鼠基因: 首字母大写 (Trp53, 不是 trp53)\n")
cat("2. 特殊字符问题:\n")
cat("   - 去除空格、制表符、连字符等特殊字符\n")
cat("3. ID类型问题:\n")
cat("   - 确保输入的是基因符号(SYMBOL)，不是ENSEMBL ID或ENTREZID\n")
cat("4. 数据库问题:\n")
cat("   - 确保 org.Hs.eg.db 和 org.Mm.eg.db 已正确安装\n")
cat("5. 数据清理:\n")
cat("   - 在调用mapIds前清理基因符号:\n")
cat("     clean_ids <- trimws(gene_ids)\n")
cat("     clean_ids <- gsub('[^[:alnum:]]', '', clean_ids)\n")