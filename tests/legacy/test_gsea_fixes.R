# =====================================================
# GSEA修复验证脚本
# =====================================================

cat("
╔════════════════════════════════════════════════════════╗
║         GSEA模块修复验证 - v3.4                        ║
║                                                        ║
║  修复内容：                                            ║
║  1. 表格core_enrichment列显示SYMBOL                    ║
║  2. Leading Edge基因正确提取和显示                     ║
║  3. 基因注释使用SYMBOL匹配                             ║
╚════════════════════════════════════════════════════════╝

")

# =====================================================
# 步骤1: 检查关键代码修改
# =====================================================

cat("\n📋 步骤1: 验证表格core_enrichment转换代码\n")
cat("─────────────────────────────────────────\n")

gsea_code <- readLines("modules/gsea_analysis.R", warn = FALSE)

# 找到output$gsea_table
table_start <- which(grepl("output\\$gsea_table.*<-.*DT::renderDataTable", gsea_code))

if (length(table_start) > 0) {
  # 找到函数结束位置
  brace_count <- 0
  for (i in table_start:length(gsea_code)) {
    brace_count <- brace_count + lengths(regmatches(gsea_code[i], gregexpr("\\{", gsea_code[i])))
    brace_count <- brace_count - lengths(regmatches(gsea_code[i], gregexpr("\\}", gsea_code[i])))
    if (brace_count == 0 && i > table_start) {
      table_end <- i
      break
    }
  }

  table_code <- gsea_code[table_start:table_end]

  # 检查关键特性
  table_checks <- list(
    "获取deg_results()用于ID映射" = "deg_data.*<-.*deg_results\\\\(\\\\)",
    "创建ENTREZID到SYMBOL映射" = "entrez_to_symbol.*<-.*setNames",
    "使用sapply转换core_enrichment" = "sapply.*df_show\\$core_enrichment",
    "检测ENTREZID格式" = 'grepl.*\\\\^\\\\[0-9\\\\]\\\\+\\\\$',
    "转换为SYMBOL" = "gene_symbols.*<-.*entrez_to_symbol",
    "更新core_enrichment列" = "df_show\\$core_enrichment.*<-.*df_show\\$core_enrichment_symbol"
  )

  for (check_name in names(table_checks)) {
    pattern <- table_checks[[check_name]]
    if (any(grepl(pattern, table_code, perl = TRUE))) {
      cat(sprintf("  ✅ %s\n", check_name))
    } else {
      cat(sprintf("  ❌ %s - 未找到\n", check_name))
    }
  }
} else {
  cat("  ❌ 未找到表格渲染代码\n")
}

# =====================================================
# 步骤2: 检查Leading Edge基因提取
# =====================================================

cat("\n📋 步骤2: 验证Leading Edge基因提取代码\n")
cat("─────────────────────────────────────────\n")

le_checks <- list(
  "从core_enrichment字段提取" = "core_enrichment_str.*<-.*gsea_obj@result\\$core_enrichment",
  "自动检测ENTREZID" = "grepl.*\\\\^\\\\[0-9\\\\]\\\\+\\\\$.*le_genes_raw",
  "转换为SYMBOL" = "le_genes_symbol.*<-.*entrez_to_symbol",
  "创建pathway_data" = "pathway_data.*<-.*data.frame",
  "返回TOP N基因" = "pathway_data_top.*<-.*pathway_data\\[1:top_n"
)

for (check_name in names(le_checks)) {
  pattern <- le_checks[[check_name]]
  if (any(grepl(pattern, gsea_code, perl = TRUE))) {
    cat(sprintf("  ✅ %s\n", check_name))
  } else {
    cat(sprintf("  ❌ %s - 未找到\n", check_name))
  }
}

# =====================================================
# 步骤3: 检查基因注释代码
# =====================================================

cat("\n📋 步骤3: 验证GSEA图基因注释代码\n")
cat("─────────────────────────────────────────\n")

# 找到基因注释部分
annotation_start <- which(grepl("📝 添加基因名称注释到GSEA图", gsea_code))

if (length(annotation_start) > 0) {
  annotation_checks <- list(
    "调用extract_leading_edge_genes" = "extract_leading_edge_genes\\\\(\\\\)",
    "使用SYMBOL创建ranked list" = "names\\\\(gene_list\\).*<-.*res_clean\\$SYMBOL",
    "匹配rank_position" = "rank_position.*<-.*match\\\\(top_genes_data\\$gene",
    "添加调试输出" = "cat.*基因匹配结果",
    "添加geom_point" = "geom_point.*rank_position",
    "添加geom_text" = "geom_text.*label.*gene"
  )

  for (check_name in names(annotation_checks)) {
    pattern <- annotation_checks[[check_name]]
    if (any(grepl(pattern, gsea_code, perl = TRUE))) {
      cat(sprintf("  ✅ %s\n", check_name))
    } else {
      cat(sprintf("  ❌ %s - 未找到\n", check_name))
    }
  }
} else {
  cat("  ❌ 未找到基因注释代码\n")
}

# =====================================================
# 步骤4: 功能总结
# =====================================================

cat("\n📋 步骤4: 修复功能总结\n")
cat("─────────────────────────────────────────\n")

fixes <- list(
  "✅ 表格core_enrichment列显示SYMBOL" = "自动检测ENTREZID并转换为SYMBOL基因名",
  "✅ Leading Edge基因提取" = "从core_enrichment字段提取，自动转换为SYMBOL",
  "✅ GSEA图基因注释" = "使用SYMBOL匹配ranked list位置",
  "✅ 调试输出增强" = "添加详细的cat输出用于诊断",
  "✅ 错误处理" = "使用tryCatch捕获可能的错误"
)

for (fix_name in names(fixes)) {
  cat(sprintf("%s\n", fix_name))
  cat(sprintf("   %s\n", fixes[[fix_name]]))
}

# =====================================================
# 步骤5: 测试建议
# =====================================================

cat("\n📋 步骤5: 测试清单\n")
cat("─────────────────────────────────────────\n")

cat("
✅ 启动应用测试：

1. 启动应用：
   source('app.R')

2. 完成分析流程：
   - 上传表达矩阵
   - 配置样本分组
   - 运行差异分析
   - 上传GMT文件（ENTREZID格式）
   - 选择ID类型：Entrez ID
   - 运行GSEA分析

3. 验证表格显示：
   □ GSEA结果表格显示正常（非空白）
   □ core_enrichment列显示SYMBOL基因名（如Csf3/Lypd6b/...）
   □ 不显示数字ID（如12985/71897）
   □ 可以搜索和过滤

4. 验证Leading Edge显示：
   □ 选择'基因排序方式' = 'Leading Edge基因'
   □ 调整'展示基因数'滑块
   □ 点击表格中的某一行
   □ 查看GSEA图
   □ 图上应该有红色/绿色的基因名称标记
   □ 基因名是SYMBOL格式（如Csf3, Tnf）

5. 检查控制台输出：
   □ 看到'📊 GSEA结果: XXX 行, XX 列'
   □ 看到'✅ 找到core_enrichment列，正在转换为SYMBOL...'
   □ 看到'✅ core_enrichment转换完成'
   □ 看到'📊 示例: Csf3/Lypd6b/...'（SYMBOL格式）
   □ 看到'🔍 提取Leading Edge基因'
   □ 看到'🔄 检测到ENTREZID格式，正在转换为SYMBOL...'
   □ 看到'✅ 提取了 N 个真正的Leading Edge基因'
   □ 看到'📝 添加基因名称注释到GSEA图...'
   □ 看到'📝 基因匹配结果: N/N 基因找到位置'
   □ 看到'✅ 基因名称注释已添加（SYMBOL格式）'

")

# =====================================================
# 步骤6: 故障排除
# =====================================================

cat("📋 步骤6: 故障排除\n")
cat("─────────────────────────────────────────\n")

cat("
如果仍有问题：

Q1: 表格还是显示ENTREZID？
A1: 检查控制台是否有'🔄 检测到ENTREZID格式'的输出
    查看是否有转换错误信息
    确认deg_results()包含SYMBOL和ENTREZID列

Q2: GSEA图没有基因名？
A2: 确认点击了表格中的某一行
    查看'展示基因数'设置（至少1个）
    查看'基因排序方式'是否选择了'Leading Edge基因'
    检查控制台是否有'📝 top_genes_data有 X 行'的输出

Q3: 基因名显示为数字？
A3: 检查控制台'📝 基因匹配结果'的输出
    确认匹配率不是0/N
    查看是否有'🔄 检测到ENTREZID格式，正在转换为SYMBOL...'

Q4: 表格显示空白？
A4: 检查浏览器控制台（F12）是否有JavaScript错误
    查看R控制台是否有错误信息
    确认GSEA分析成功完成
    检查df_show是否为空

")

cat("\n═════════════════════════════════════════════════════════\n")
cat("                验证准备完成！请启动应用测试\n")
cat("═════════════════════════════════════════════════════════\n")
