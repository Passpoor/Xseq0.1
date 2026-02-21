# =====================================================
# 数据输入模块
# =====================================================

# TCGA 条形码：从列名第4段判断样本类型（01–09 肿瘤，10–19 正常）
# 支持 TCGA-xx-xxxx-xx 或 TCGA.xx.xxxx.xx 格式
tcga_sample_type_from_barcode <- function(barcode) {
  if (is.na(barcode) || barcode == "") return(NA_character_)
  s <- as.character(barcode)
  parts <- strsplit(s, "[-.]")[[1]]
  if (length(parts) < 4) return(NA_character_)
  code <- sub("^([0-9]{2}).*", "\\1", parts[4])
  n <- suppressWarnings(as.integer(code))
  if (is.na(n)) return(NA_character_)
  if (n >= 1L && n <= 9L) return("tumor")
  if (n >= 10L && n <= 19L) return("normal")
  NA_character_
}

# 对列名批量分类，返回 list(normal = 字符向量, tumor = 字符向量)；排除 NA/空列名
tcga_classify_columns <- function(col_names) {
  col_names <- col_names[!is.na(col_names) & nzchar(trimws(col_names))]
  types <- vapply(col_names, tcga_sample_type_from_barcode, character(1))
  list(
    normal = col_names[types == "normal"],
    tumor  = col_names[types == "tumor"]
  )
}

# 检测文件开头是否为 BOM，返回使用的 fileEncoding 或 NULL（使用默认）
detect_csv_encoding <- function(filepath) {
  con <- file(filepath, "rb")
  on.exit(close(con), add = TRUE)
  bytes <- readBin(con, "raw", 4)
  # UTF-16 LE BOM: FF FE
  if (length(bytes) >= 2 && bytes[1] == as.raw(0xff) && bytes[2] == as.raw(0xfe))
    return("UTF-16LE")
  # UTF-16 BE BOM: FE FF
  if (length(bytes) >= 2 && bytes[1] == as.raw(0xfe) && bytes[2] == as.raw(0xff))
    return("UTF-16BE")
  # UTF-8 BOM: EF BB BF
  if (length(bytes) >= 3 && bytes[1] == as.raw(0xef) && bytes[2] == as.raw(0xbb) && bytes[3] == as.raw(0xbf))
    return("UTF-8")
  NULL
}

# 去除列名/字符中的 BOM（U+FEFF）
strip_bom <- function(x) {
  if (is.character(x)) {
    x <- gsub("^\uFEFF", "", x)
    x <- gsub("\uFEFF", "", x)
  }
  x
}

# 辅助函数：读取 CSV/CSV.GZ 或 TXT/TSV（Tab 分隔、UTF-8 等），自动处理 BOM
read_csv_file <- function(filepath, filename, header = TRUE, ...) {
  is_gzipped <- grepl("\\.gz$", filename)
  is_tab     <- grepl("\\.(txt|tsv)(\\.gz)?$", filename, ignore.case = TRUE)

  if (is_gzipped) {
    con <- gzfile(filepath)
    enc <- NULL
    if (!is_tab) {
      df <- read.csv(con, header = header, ...)
    } else {
      df <- read.delim(con, header = header, sep = "\t", ...)
    }
    close(con)
  } else {
    enc <- detect_csv_encoding(filepath)
    args <- list(file = filepath, header = header, ...)
    if (!is.null(enc)) args$fileEncoding <- enc
    if (is_tab) {
      args$sep <- "\t"
      df <- do.call("read.delim", args)
    } else {
      df <- do.call("read.csv", args)
    }
  }

  colnames(df) <- strip_bom(colnames(df))
  for (j in seq_len(ncol(df))) {
    if (is.character(df[[j]]))
      df[[j]] <- strip_bom(df[[j]])
  }
  df
}

data_input_server <- function(input, output, session, user_session) {

  # --- 数据读取 ---
  raw_data <- reactive({
    req(input$file, user_session$logged_in)
    df <- read_csv_file(input$file$datapath, input$file$name, header = TRUE)
    if (ncol(df) >= 2) {
      rownames(df) <- make.names(df[,1], unique = TRUE)
      df <- df[,-1, drop = FALSE]
    }
    df
  })

  # --- 差异基因结果读取 ---
  deg_file_data <- reactive({
    req(input$deg_file, user_session$logged_in)
    df <- read_csv_file(input$deg_file$datapath, input$deg_file$name, header = TRUE)
    return(df)
  })

  # 🆕 --- 芯片差异结果读取 ---
  chip_file_data <- reactive({
    req(input$chip_file, user_session$logged_in)
    df <- read_csv_file(input$chip_file$datapath, input$chip_file$name, header = TRUE)
    return(df)
  })

  # TCGA 分类结果（仅当勾选 TCGA 且数据存在时有效）
  tcga_groups <- reactive({
    if (!isTRUE(input$is_tcga_data)) return(NULL)
    req(raw_data())
    tcga_classify_columns(colnames(raw_data()))
  })

  output$group_selector <- renderUI({
    req(raw_data())
    cols <- colnames(raw_data())
    cols <- cols[!is.na(cols) & nzchar(trimws(cols))]
    if (isTRUE(input$is_tcga_data) && !is.null(tcga_groups())) {
      tg <- tcga_groups()
      n_normal <- length(tg$normal)
      n_tumor  <- length(tg$tumor)
      if (n_normal > 0 && n_tumor > 0) {
        tagList(
          helpText(sprintf("已按 TCGA 条形码第4段自动区分：正常 %d 个 → Control，肿瘤 %d 个 → Treatment。", n_normal, n_tumor), style = "color: #1565C0; font-size: 12px;"),
          selectInput("control_group", "Control组（正常）", choices = tg$normal, selected = tg$normal, multiple = TRUE),
          selectInput("treat_group", "Treatment组（肿瘤）", choices = tg$tumor, selected = tg$tumor, multiple = TRUE)
        )
      } else {
        tagList(
          helpText("未检测到 TCGA 条形码（列名需为 TCGA-xx-xxxx-xx 或 TCGA.xx.xxxx.xx，第4段 01–09=肿瘤、10–19=正常）。请取消勾选 TCGA 或手动选择分组。", style = "color: #856404; font-size: 12px;"),
          selectInput("control_group", "Control组", choices = cols, multiple = TRUE),
          selectInput("treat_group", "Treatment组", choices = cols, multiple = TRUE)
        )
      }
    } else {
      tagList(
        selectInput("control_group", "Control组", choices = cols, multiple = TRUE),
        selectInput("treat_group", "Treatment组", choices = cols, multiple = TRUE)
      )
    }
  })

  # --- 增强的注释函数 ---
  annotate_genes <- function(gene_ids, species_code) {
    db_pkg <- if(species_code == "Mm") "org.Mm.eg.db" else "org.Hs.eg.db"
    if (!require(db_pkg, character.only = TRUE, quietly = TRUE)) {
      warning("数据库包 ", db_pkg, " 未安装")
      return(NULL)
    }

    db_obj <- get(db_pkg)

    # 清理基因符号
    clean_ids <- trimws(gene_ids)
    clean_ids <- gsub("[\t\n\r]", "", clean_ids)

    # 对于Ensembl ID，保留版本号用于匹配（有些数据库需要版本号）
    # 对于非Ensembl ID，移除特殊字符
    is_ensembl <- grepl("^ENS", clean_ids, ignore.case = TRUE)
    clean_ids[!is_ensembl] <- gsub("[^[:alnum:]]", "", clean_ids[!is_ensembl])

    # 根据物种标准化大小写
    # 注意：对于ENSEMBL ID，保持原始格式以便匹配
    if (species_code == "Mm") {
      # 小鼠基因：首字母大写，其余小写（但ENSEMBL ID保持原样）
      clean_ids <- sapply(clean_ids, function(x) {
        if (grepl("^ENS", x, ignore.case = TRUE)) {
          # ENSEMBL ID：保持原样
          x
        } else if (grepl("^[A-Za-z]", x)) {
          # 普通基因符号：首字母大写，其余小写
          paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x))))
        } else {
          x
        }
      }, USE.NAMES = FALSE)
    } else {
      # 人类基因：全部大写（但ENSEMBL ID保持原样）
      clean_ids <- sapply(clean_ids, function(x) {
        if (grepl("^ENS", x, ignore.case = TRUE)) {
          # ENSEMBL ID：保持原样
          x
        } else {
          # 其他基因：全部大写
          toupper(x)
        }
      }, USE.NAMES = FALSE)
    }

    # 去除特殊字符
    clean_ids <- gsub("[^[:alnum:]]", "", clean_ids)

    cat("基因注释: 清理后基因数量 =", length(clean_ids), "\n")
    cat("前5个清理后的基因:", paste(head(clean_ids, 5), collapse=", "), "\n")

    # 尝试不同keytype，收集所有成功注释的基因
    all_anno <- data.frame()

    # 1. 首先尝试SYMBOL（最常用）
    tryCatch({
      # 只尝试在数据库中有匹配的基因
      valid_symbols <- clean_ids[clean_ids %in% keys(db_obj, keytype = "SYMBOL")]
      if (length(valid_symbols) > 0) {
        cat("找到", length(valid_symbols), "个有效的SYMBOL\n")
        anno <- AnnotationDbi::select(db_obj,
                                     keys = valid_symbols,
                                     columns = c("SYMBOL", "ENTREZID"),
                                     keytype = "SYMBOL")
        if (nrow(anno) > 0) {
          anno <- anno[!duplicated(anno$SYMBOL), ]
          all_anno <- rbind(all_anno, anno)
          cat("SYMBOL注释成功:", nrow(anno), "个基因\n")
        }
      } else {
        cat("没有有效的SYMBOL\n")
      }
    }, error = function(e) {
      cat("SYMBOL注释错误:", e$message, "\n")
    })

    # 2. 尝试ENSEMBL ID（带版本号和不带版本号）
    tryCatch({
      ensembl_ids <- clean_ids[grepl("^ENS", clean_ids, ignore.case = TRUE)]
      if (length(ensembl_ids) > 0) {
        # 首先尝试带版本号的ID
        valid_ensembl <- ensembl_ids[ensembl_ids %in% keys(db_obj, keytype = "ENSEMBL")]
        if (length(valid_ensembl) > 0) {
          cat("找到", length(valid_ensembl), "个有效的ENSEMBL ID (带版本号)\n")
          anno <- AnnotationDbi::select(db_obj,
                                       keys = valid_ensembl,
                                       columns = c("ENSEMBL", "SYMBOL", "ENTREZID"),
                                       keytype = "ENSEMBL")
          if (nrow(anno) > 0) {
            anno <- anno[!duplicated(anno$ENSEMBL), ]
            all_anno <- rbind(all_anno, anno)
            cat("ENSEMBL注释成功:", nrow(anno), "个基因\n")
          }
        }

        # 对于未匹配的Ensembl ID，尝试去除版本号后匹配
        unmatched_ensembl <- ensembl_ids[!ensembl_ids %in% valid_ensembl]
        if (length(unmatched_ensembl) > 0) {
          # 移除版本号
          ensembl_no_version <- gsub("\\..*", "", unmatched_ensembl)
          valid_no_version <- ensembl_no_version[ensembl_no_version %in% keys(db_obj, keytype = "ENSEMBL")]

          if (length(valid_no_version) > 0) {
            cat("找到", length(valid_no_version), "个有效的ENSEMBL ID (不带版本号)\n")
            anno <- AnnotationDbi::select(db_obj,
                                         keys = valid_no_version,
                                         columns = c("ENSEMBL", "SYMBOL", "ENTREZID"),
                                         keytype = "ENSEMBL")
            if (nrow(anno) > 0) {
              # 记录原始ID（带版本号）到数据库ID的映射
              anno$ORIGINAL_ENSEMBL <- unmatched_ensembl[match(valid_no_version, ensembl_no_version)]
              anno <- anno[!duplicated(anno$ENSEMBL), ]
              all_anno <- rbind(all_anno, anno)
              cat("ENSEMBL注释成功 (无版本号):", nrow(anno), "个基因\n")
            }
          }
        }
      }
    }, error = function(e) {
      cat("ENSEMBL注释错误:", e$message, "\n")
    })

    # 3. 尝试ENTREZID（如果输入已经是数字ID）
    tryCatch({
      numeric_ids <- clean_ids[grepl("^[0-9]+$", clean_ids)]
      if (length(numeric_ids) > 0) {
        valid_entrez <- numeric_ids[numeric_ids %in% keys(db_obj, keytype = "ENTREZID")]
        if (length(valid_entrez) > 0) {
          cat("找到", length(valid_entrez), "个有效的ENTREZID\n")
          anno <- AnnotationDbi::select(db_obj,
                                       keys = valid_entrez,
                                       columns = c("ENTREZID", "SYMBOL"),
                                       keytype = "ENTREZID")
          if (nrow(anno) > 0) {
            anno <- anno[!duplicated(anno$ENTREZID), ]
            all_anno <- rbind(all_anno, anno)
            cat("ENTREZID注释成功:", nrow(anno), "个基因\n")
          }
        }
      }
    }, error = function(e) {
      cat("ENTREZID注释错误:", e$message, "\n")
    })

    if (nrow(all_anno) > 0) {
      # 去重
      all_anno <- all_anno[!duplicated(all_anno), ]

      # 🔧 修复：确保小鼠基因符号格式正确
      # org.Mm.eg.db 可能返回全大写的SYMBOL，需要转换为正确的小鼠格式
      if (species_code == "Mm" && "SYMBOL" %in% colnames(all_anno)) {
        # 对于小鼠：将全大写的基因符号转换为首字母大写的格式
        # 注意：这是一个近似转换，因为无法100%确定官方命名规则
        # 但总比全大写（人类格式）要好
        all_uppercase_mask <- grepl("^[A-Z]+$", all_anno$SYMBOL) & nchar(all_anno$SYMBOL) > 2

        if (sum(all_uppercase_mask) > 0) {
          cat(sprintf("⚠️  检测到 %d 个全大写的小鼠基因符号，正在转换...\n", sum(all_uppercase_mask)))
          cat("转换示例前5个:", paste(head(all_anno$SYMBOL[all_uppercase_mask], 5), collapse=", "), "\n")

          # 转换为首字母大写，其余小写
          all_anno$SYMBOL[all_uppercase_mask] <- sapply(all_anno$SYMBOL[all_uppercase_mask], function(x) {
            paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x))))
          }, USE.NAMES = FALSE)

          cat("✅ 转换完成\n")
        }
      }

      cat("总注释成功:", nrow(all_anno), "个基因\n")

      # 确保有SYMBOL列
      if (!"SYMBOL" %in% colnames(all_anno)) {
        all_anno$SYMBOL <- NA
      }

      return(all_anno)
    } else {
      cat("所有注释尝试都失败\n")
      return(NULL)
    }
  }

  # --- 过滤假基因函数 ---
  filter_pseudo_genes <- function(df) {
    # 🔧 修复：过滤明确的假基因（Gm开头、Rik或-ps结尾）
    # 同时检查SYMBOL列和GeneID列

    # 统计过滤前的数量
    n_before <- nrow(df)

    # 检查哪些是假基因
    is_pseudo_in_symbol <- grepl("^Gm", df$SYMBOL, ignore.case = TRUE) |
                           grepl("Rik$", df$SYMBOL, ignore.case = TRUE) |
                           grepl("-ps$", df$SYMBOL, ignore.case = TRUE) |
                           grepl("-ps[0-9]", df$SYMBOL, ignore.case = TRUE) |
                           grepl("^ENSMUSG[0-9]+-PS", df$SYMBOL, ignore.case = TRUE)

    is_pseudo_in_geneid <- grepl("^Gm", df$GeneID, ignore.case = TRUE) |
                           grepl("Rik$", df$GeneID, ignore.case = TRUE) |
                           grepl("-ps$", df$GeneID, ignore.case = TRUE)

    # 标记假基因（SYMBOL或GeneID任一是假基因格式）
    is_pseudo <- is_pseudo_in_symbol | is_pseudo_in_geneid

    # 过滤掉假基因（保留不是假基因的）
    df_filtered <- df[!is_pseudo, ]

    removed_count <- n_before - nrow(df_filtered)
    if (removed_count > 0) {
      cat(sprintf("🧹 过滤了 %d 个假基因（Gm/Rik/-ps等格式）\n", removed_count))
      showNotification(paste("过滤了", removed_count, "个假基因（Gm/Rik/-ps等格式）"), type = "message")
    }

    return(df_filtered)
  }

  # 返回数据函数
  list(
    raw_data = raw_data,
    deg_file_data = deg_file_data,
    chip_file_data = chip_file_data,  # 🆕 添加芯片数据
    annotate_genes = annotate_genes,
    filter_pseudo_genes = filter_pseudo_genes
  )
}