# 完整诊断RNAseq分析流程
library(AnnotationDbi)
library(dplyr)
library(tidyr)

cat("=== RNAseq分析流程完整诊断 ===\n\n")

# 1. 检查数据库包
cat("1. 检查数据库包安装情况:\n")
db_packages <- c("org.Hs.eg.db", "org.Mm.eg.db", "clusterProfiler", "AnnotationDbi")
for (pkg in db_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("  ✓", pkg, "已安装\n")
  } else {
    cat("  ✗", pkg, "未安装\n")
  }
}

# 2. 模拟数据输入模块的基因注释函数
cat("\n2. 测试数据输入模块的基因注释函数:\n")

simulate_annotate_genes <- function(gene_ids, species_code) {
  db_pkg <- if(species_code == "Mm") "org.Mm.eg.db" else "org.Hs.eg.db"
  if (!require(db_pkg, character.only = TRUE, quietly = TRUE)) {
    cat("  错误: 数据库包", db_pkg, "未安装\n")
    return(NULL)
  }

  db_obj <- get(db_pkg)
  clean_ids <- gsub("\\..*", "", gene_ids)

  cat("  输入基因数量:", length(gene_ids), "\n")
  cat("  清理后基因数量:", length(clean_ids), "\n")
  cat("  前5个基因:", paste(head(clean_ids, 5), collapse=", "), "\n")

  # 尝试不同keytype
  results <- list()

  # 尝试ENSEMBL
  tryCatch({
    ensembl_genes <- clean_ids[grepl("^ENS", clean_ids)]
    if (length(ensembl_genes) > 0) {
      cat("  检测到ENSEMBL ID:", length(ensembl_genes), "个\n")
      anno <- AnnotationDbi::select(db_obj,
                                   keys = ensembl_genes,
                                   columns = c("SYMBOL", "ENTREZID"),
                                   keytype = "ENSEMBL")
      if (nrow(anno) > 0) {
        cat("  ENSEMBL注释成功:", nrow(anno), "个基因\n")
        results$ensembl <- anno
      }
    }
  }, error = function(e) {
    cat("  ENSEMBL注释错误:", e$message, "\n")
  })

  # 尝试SYMBOL
  tryCatch({
    # 清理基因符号
    symbol_genes <- clean_ids
    symbol_genes <- trimws(symbol_genes)
    symbol_genes <- gsub("[^[:alnum:]]", "", symbol_genes)

    if (species_code == "Hs") {
      symbol_genes <- toupper(symbol_genes)
    } else if (species_code == "Mm") {
      symbol_genes <- sapply(symbol_genes, function(x) {
        if (grepl("^[A-Za-z]", x)) {
          paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x))))
        } else {
          x
        }
      }, USE.NAMES = FALSE)
    }

    cat("  标准化后的SYMBOL:", paste(head(symbol_genes, 5), collapse=", "), "\n")

    anno <- AnnotationDbi::select(db_obj,
                                 keys = symbol_genes,
                                 columns = c("ENTREZID", "SYMBOL"),
                                 keytype = "SYMBOL")
    if (nrow(anno) > 0) {
      cat("  SYMBOL注释成功:", nrow(anno), "个基因\n")
      results$symbol <- anno
    } else {
      cat("  SYMBOL注释失败: 无匹配结果\n")
    }
  }, error = function(e) {
    cat("  SYMBOL注释错误:", e$message, "\n")
  })

  # 合并结果
  if (length(results) > 0) {
    final_result <- do.call(rbind, results)
    final_result <- final_result[!duplicated(final_result), ]
    cat("  总注释成功:", nrow(final_result), "个基因\n")
    return(final_result)
  } else {
    cat("  所有注释尝试都失败\n")
    return(NULL)
  }
}

# 3. 测试实际数据
cat("\n3. 测试实际数据流程:\n")

# 模拟差异分析结果
test_deg_data <- function() {
  # 创建测试差异分析结果
  set.seed(123)
  n_genes <- 100

  # 混合各种基因ID类型
  gene_ids <- c(
    # 人类基因符号
    paste0("GENE", 1:30),
    # 小鼠基因符号
    paste0("Gene", 31:60),
    # ENSEMBL ID
    paste0("ENSG00000", 1000000 + 1:20),
    # 带特殊字符的基因
    paste0("Gene-", 61:70),
    # 带空格的基因
    paste0("Gene ", 71:80),
    # 小写基因
    paste0("gene", 81:90),
    # 大写基因
    paste0("GENE", 91:100)
  )

  deg_df <- data.frame(
    GeneID = gene_ids[1:n_genes],
    logFC = rnorm(n_genes, 0, 2),
    p_val = runif(n_genes, 0, 0.05),
    p_val_adj = runif(n_genes, 0, 0.05),
    Status = sample(c("Up", "Down"), n_genes, replace = TRUE),
    stringsAsFactors = FALSE
  )

  return(deg_df)
}

# 测试人类数据
cat("\n--- 测试人类数据 ---\n")
human_deg <- test_deg_data()
cat("人类差异分析数据行数:", nrow(human_deg), "\n")
cat("前5个GeneID:", paste(head(human_deg$GeneID, 5), collapse=", "), "\n")

human_anno <- simulate_annotate_genes(human_deg$GeneID, "Hs")

if (!is.null(human_anno)) {
  # 合并注释结果
  human_result <- merge(human_deg, human_anno, by.x = "GeneID", by.y = "SYMBOL", all.x = TRUE)
  cat("人类数据注释结果:\n")
  cat("  总基因数:", nrow(human_result), "\n")
  cat("  成功注释:", sum(!is.na(human_result$ENTREZID)), "\n")
  cat("  未注释:", sum(is.na(human_result$ENTREZID)), "\n")

  # 检查未注释的基因
  unannotated <- human_result[is.na(human_result$ENTREZID), "GeneID"]
  cat("  未注释基因示例:", paste(head(unannotated, 10), collapse=", "), "\n")
}

# 4. 测试KEGG分析需要的ENTREZID
cat("\n4. 测试KEGG分析流程:\n")

if (!is.null(human_anno) && "ENTREZID" %in% colnames(human_anno)) {
  # 模拟KEGG分析
  entrez_ids <- na.omit(unique(human_anno$ENTREZID))
  cat("  可用的ENTREZID数量:", length(entrez_ids), "\n")

  if (length(entrez_ids) > 0) {
    cat("  前5个ENTREZID:", paste(head(entrez_ids, 5), collapse=", "), "\n")

    # 测试KEGG分析
    if (require("clusterProfiler", quietly = TRUE)) {
      cat("  测试clusterProfiler::enrichKEGG...\n")
      tryCatch({
        # 使用少量基因测试
        test_entrez <- head(entrez_ids, 10)
        kegg_result <- clusterProfiler::enrichKEGG(
          gene = test_entrez,
          organism = "hsa",
          pvalueCutoff = 0.05,
          pAdjustMethod = "BH"
        )

        if (!is.null(kegg_result) && nrow(kegg_result@result) > 0) {
          cat("  ✓ KEGG分析成功!\n")
          cat("    找到通路:", nrow(kegg_result@result), "个\n")
        } else {
          cat("  ⚠ KEGG分析无结果（可能是基因太少）\n")
        }
      }, error = function(e) {
        cat("  ✗ KEGG分析错误:", e$message, "\n")
      })
    }
  }
}

# 5. 检查实际错误
cat("\n5. 检查常见错误原因:\n")
cat("  a) 基因符号格式问题:\n")
cat("     - 大小写不正确\n")
cat("     - 包含特殊字符\n")
cat("     - 包含空格或制表符\n")
cat("  b) 数据库问题:\n")
cat("     - 数据库包未加载\n")
cat("     - 物种选择错误\n")
cat("  c) 数据流程问题:\n")
cat("     - 差异分析未生成ENTREZID\n")
cat("     - 数据传递错误\n")

# 6. 建议的修复步骤
cat("\n6. 建议的修复步骤:\n")
cat("  1. 在差异分析模块添加基因符号清理\n")
cat("  2. 确保annotate_genes函数正确处理各种ID类型\n")
cat("  3. 在KEGG/GO模块添加输入验证\n")
cat("  4. 添加详细的错误日志\n")

# 7. 创建修复测试
cat("\n7. 创建修复测试脚本...\n")

test_cleanup_function <- function() {
  clean_gene_symbols <- function(gene_symbols, species_code) {
    cleaned <- trimws(gene_symbols)
    cleaned <- gsub("[\t\n\r]", "", cleaned)

    if (species_code == "mmu" || species_code == "Mm") {
      cleaned <- sapply(cleaned, function(x) {
        if (grepl("^[A-Za-z]", x)) {
          paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x))))
        } else {
          x
        }
      }, USE.NAMES = FALSE)
    } else {
      cleaned <- toupper(cleaned)
    }

    cleaned <- gsub("[^[:alnum:]]", "", cleaned)
    return(cleaned)
  }

  # 测试
  test_genes <- c("tp53", "TP53", "Trp53", "trp53", "BRCA-1", "EGFR ", "gene\t123")
  cat("  测试基因:", paste(test_genes, collapse=", "), "\n")

  human_clean <- clean_gene_symbols(test_genes, "Hs")
  cat("  人类清理后:", paste(human_clean, collapse=", "), "\n")

  mouse_clean <- clean_gene_symbols(test_genes, "Mm")
  cat("  小鼠清理后:", paste(mouse_clean, collapse=", "), "\n")

  return(list(human = human_clean, mouse = mouse_clean))
}

test_cleanup_function()

cat("\n=== 诊断完成 ===\n")
cat("请检查以上输出，重点关注:\n")
cat("1. 数据库包是否安装正确\n")
cat("2. 基因注释成功率\n")
cat("3. ENTREZID生成情况\n")
cat("4. 基因符号清理效果\n")