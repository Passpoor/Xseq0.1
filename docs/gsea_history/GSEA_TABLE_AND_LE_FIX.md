# GSEA模块最终修复 - 表格显示和Leading Edge基因

**修复日期**: 2025-12-26
**问题**: 表格显示空白，Leading Edge基因显示ENTREZID而非SYMBOL

---

## 已修复的问题

### 1. ✅ GSEA表格显示空白

**原因**:
- 使用了辅助函数`convert_core_enrichment_to_symbol()`直接修改原始数据框
- 导致DT::datatable无法正确渲染

**修复位置**: `modules/gsea_analysis.R:192-252`

**修复内容**:
```r
# ❌ 之前：使用辅助函数
df <- convert_core_enrichment_to_symbol(df, deg_results)
if ("core_enrichment" %in% colnames(df)) {
  df_show <- df %>% select(ID, ..., core_enrichment)
}

# ✅ 修复：直接内联转换逻辑
if ("core_enrichment" %in% colnames(df)) {
  # 获取差异分析数据
  deg_data <- deg_results()
  res <- deg_data$deg_df
  res_clean <- res[!is.na(res$SYMBOL) & !is.na(res$ENTREZID), ]
  res_clean <- res_clean %>% group_by(SYMBOL) %>% slice(1) %>% ungroup()

  # 创建映射
  entrez_to_symbol <- setNames(res_clean$SYMBOL, res_clean$ENTREZID)

  # 转换为显示列
  df$core_enrichment_display <- sapply(df$core_enrichment, function(x) {
    if (is.na(x) || !nzchar(x)) return("")
    genes <- unlist(strsplit(x, "/"))
    if (all(grepl("^[0-9]+$", genes))) {
      symbols <- entrez_to_symbol[genes]
      symbols <- symbols[!is.na(symbols)]
      paste(symbols, collapse = "/")
    } else {
      x
    }
  })

  # 选择显示列
  df_show <- df %>% select(ID, setSize, enrichmentScore, NES, pvalue, p.adjust, core_enrichment_display)
  colnames(df_show)[7] <- "core_enrichment"
}
```

**改进**:
- ✅ 不修改原始数据框
- ✅ 创建新的显示列`core_enrichment_display`
- ✅ 正确的列索引和搜索配置
- ✅ 表格可以正常渲染

---

### 2. ✅ Leading Edge基因始终显示SYMBOL

**原因**:
- Line 556的逻辑有缺陷
- 当`input$gsea_id_type == "SYMBOL"`时，直接使用`le_genes_raw`
- 但core_enrichment中的基因可能仍是ENTREZID格式

**修复位置**: `modules/gsea_analysis.R:548-568`

**修复内容**:
```r
# ❌ 之前：假设就是SYMBOL
le_genes_symbol <- le_genes_raw  # 默认假设就是SYMBOL

if (input$gsea_id_type == "ENTREZID") {
  # 只在ENTREZID模式下转换
  entrez_to_symbol <- setNames(res_clean$SYMBOL, res_clean$ENTREZID)
  le_genes_symbol <- entrez_to_symbol[le_genes_raw]
  le_genes_symbol <- le_genes_symbol[!is.na(le_genes_symbol)]
}

# ✅ 修复：始终检测并转换
le_genes_symbol <- le_genes_raw

# 检测是否为ENTREZID（纯数字）并转换为SYMBOL
if (all(grepl("^[0-9]+$", le_genes_raw))) {
  cat("🔄 检测到ENTREZID格式，正在转换为SYMBOL...\n")
  entrez_to_symbol <- setNames(res_clean$SYMBOL, res_clean$ENTREZID)
  le_genes_symbol <- entrez_to_symbol[le_genes_raw]
  le_genes_symbol <- le_genes_symbol[!is.na(le_genes_symbol)]
  cat(sprintf("✅ 转换后SYMBOL基因数量: %d\n", length(le_genes_symbol)))
} else {
  cat("✅ 已经是SYMBOL格式\n")
}
```

**改进**:
- ✅ 使用`grepl("^[0-9]+$", ...)`自动检测ENTREZID
- ✅ 无论GSEA使用什么ID类型，都转换为SYMBOL
- ✅ 详细的控制台输出
- ✅ 确保Leading Edge基因始终是SYMBOL格式

---

## 控制台输出示例

### GSEA运行和表格生成
```
🔍 提取Leading Edge基因，selected=1, pathway_id=GOMF_SIGNALING_RECEPTOR_REGULATOR_ACTIVITY
🔍 core_enrichment内容: 12985/71897/330122/54448/...
🔍 原始Leading Edge基因数量: 111 (ID类型: ENTREZID)
🔄 检测到ENTREZID格式，正在转换为SYMBOL...
✅ 转换后SYMBOL基因数量: 111
✅ 提取了 20 个真正的Leading Edge基因 (ID类型: SYMBOL)
✅ Leading Edge基因示例: Csf3, Lypd6b, Cxcl3, Il36a, Ccl22
```

### GSEA图生成
```
📝 准备在GSEA图上标记 20 个Leading Edge基因
基因列表: Csf3, Lypd6b, Cxcl3, Il36a, Ccl22, ...
📝 添加基因名称注释到GSEA图...
✅ 准备标注 20 个基因名称（SYMBOL格式）
✅ 基因名称注释已添加（SYMBOL格式）
```

---

## 功能验证清单

### ✅ GSEA结果表格
- [x] 表格正常显示（非空白）
- [x] core_enrichment列显示SYMBOL基因名（如`Csf3/Lypd6b/...`）
- [x] 支持搜索core_enrichment列
- [x] 分页功能正常
- [x] 数字列正确格式化

### ✅ Leading Edge基因提取
- [x] 从core_enrichment字段正确提取
- [x] 自动检测ENTREZID并转换为SYMBOL
- [x] 始终返回SYMBOL格式
- [x] 控制台输出详细信息

### ✅ GSEA图显示
- [x] 显示SYMBOL基因名（如`Csf3`）
- [x] 不显示ENTREZID（如`12985`）
- [x] 点标记 + 文本标签
- [x] 颜色适配主题（红色/绿色）
- [x] 基因名45度角显示

---

## 技术细节

### 表格显示修复关键点
1. **不修改原始数据框**：创建新列而不是修改原列
2. **内联转换逻辑**：避免使用辅助函数造成的数据框引用问题
3. **动态列配置**：根据实际列数设置DT选项
4. **列索引检查**：确保列索引有效（`ncols >= 7`）

### Leading Edge基因修复关键点
1. **自动检测ID类型**：使用`grepl("^[0-9]+$", ...)`检测ENTREZID
2. **智能转换**：无论输入是什么，都转换为SYMBOL
3. **详细日志**：每一步都有控制台输出
4. **容错处理**：移除无法映射的基因

---

## 使用建议

### 推荐配置
```
ID类型: SYMBOL或ENTREZID（都可以）
基因排序: GSEA Leading Edge基因
Top N基因: 20
```

### 测试步骤
1. 启动应用：`source("app.R")` 或 `launch_app.bat`
2. 登录并上传数据
3. 运行差异分析
4. 运行GSEA分析
5. **检查表格**：
   - 表格应该有数据（非空白）
   - core_enrichment列显示`Csf3/Lypd6b/...`
6. **检查GSEA图**：
   - 点击表格某一行
   - 查看GSEA图
   - 确认图上显示基因名（如`Csf3`）

---

## 常见问题

### Q1: 表格还是空白？
A: 检查以下几点：
1. GSEA是否成功运行（查看控制台输出）
2. 是否有显著富集结果
3. 浏览器控制台是否有JavaScript错误

### Q2: core_enrichment列显示的还是数字？
A: 确认：
1. 差异分析数据中有SYMBOL和ENTREZID列
2. 控制台是否显示"✅ 转换后SYMBOL基因数量"
3. 如果数字无法映射到SYMBOL，会显示为空

### Q3: GSEA图上没有基因名称？
A: 检查：
1. 是否点击了表格中的某一行
2. extract_leading_edge_genes是否成功（查看控制台）
3. `gsea_top_genes`参数是否设置过小

---

## 总结

### 修复的核心问题
1. ✅ 表格显示空白 - 修复数据框处理逻辑
2. ✅ Leading Edge显示ENTREZID - 添加自动检测和转换
3. ✅ 代码重复 - 内联转换逻辑避免辅助函数问题

### 功能完整性
- ✅ 表格正常显示
- ✅ core_enrichment显示SYMBOL
- ✅ Leading Edge基因始终是SYMBOL
- ✅ GSEA图显示基因名称
- ✅ 完善的错误处理
- ✅ 详细的调试输出

---

**状态**: ✅ 完全修复
**版本**: 3.2 Final
**更新日期**: 2025-12-26
**作者**: Biofree Development Team
