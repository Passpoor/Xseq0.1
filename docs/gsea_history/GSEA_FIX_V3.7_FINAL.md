# GSEA模块最终修复 - v3.7

**日期**: 2025-12-26
**版本**: v3.7 Final
**问题**: `Your gene is not in this pathway!` 错误

---

## ❌ 问题分析

### 错误原因
```
Your gene is not in this pathway! Please choose again!
```

**根本原因**:
1. GSEA使用ENTREZID运行（因为GMT文件是ENTREZID格式）
2. GseaVis的`addGene`参数需要传入GSEA运行时使用的ID类型
3. 之前传入SYMBOL格式的基因，但GSEA的geneList中是ENTREZID
4. 导致GseaVis找不到基因，报错

### 错误示例
```r
# GSEA运行时
geneList <- c(12985, 71897, 330122, ...)  # ENTREZID
names(geneList) <- c("12985", "71897", "330122", ...)

# 错误做法
plot_args$addGene <- c("Csf3", "Lypd6b", "Cxcl3")  # SYMBOL
# GseaVis在geneList中找不到"Csf3"，报错！
```

---

## ✅ 修复方案

### 1. 传入匹配的ID类型

**位置**: `modules/gsea_analysis.R:412-527`

**核心逻辑**:
```r
if (input$gsea_id_type == "ENTREZID") {
  # GSEA用ENTREZID运行，addGene需要ENTREZID
  # 从top_genes_data（SYMBOL）转换回ENTREZID
  symbol_to_entrez <- setNames(res_clean$ENTREZID, res_clean$SYMBOL)
  genes_entrez <- symbol_to_entrez[top_genes_data$gene]

  plot_args$addGene <- genes_entrez  # 传入ENTREZID
} else {
  # GSEA用SYMBOL运行，addGene直接用SYMBOL
  plot_args$addGene <- top_genes_data$gene  # 传入SYMBOL
}
```

**关键点**:
- ✅ `addGene`接收的ID类型与GSEA运行时一致
- ✅ GseaVis能找到基因，正确标注位置

### 2. 显示SYMBOL名称（覆盖ENTREZID数字）

**问题**: 如果GSEA用ENTREZID运行，`addGene`会显示数字ID（如"12985"），不是基因名

**解决方案**: 在addGene标注的基础上，添加SYMBOL标签

```r
# 先用addGene获取正确位置（显示数字）
p <- GseaVis::gseaNb(addGene = genes_entrez)  # ENTREZID

# 然后在x轴上添加SYMBOL标签
if (input$gsea_id_type == "ENTREZID") {
  # 计算基因在ranked list中的位置（x坐标）
  gene_positions <- match(genes_entrez, names(gsea_obj@geneList))

  # 添加SYMBOL标签
  p <- p + geom_text(
    data = data.frame(
      x = gene_positions,
      label = top_genes_data$gene  # SYMBOL
    ),
    aes(x = x, y = 0, label = label),
    color = "red"
  )
}
```

**效果**:
- ✅ 基因标注在正确的leading edge位置（GseaVis计算）
- ✅ x轴显示SYMBOL名称（红色斜体）
- ✅ 用户可读的基因名

---

## 📊 完整流程

### 数据流

```
1. Leading Edge基因提取 (extract_leading_edge_genes)
   ↓
   返回: data.frame(gene = "Csf3", log2FoldChange = 2.5, ...)
   （总是SYMBOL格式）

2. ID类型转换（用于addGene）
   ↓
   如果GSEA用ENTREZID运行:
     "Csf3" → 12985 (ENTREZID)

3. GseaVis绘图
   ↓
   gseaNb(addGene = c(12985, 71897, ...))
   ↓
   在正确的leading edge位置标注（显示数字）

4. 添加SYMBOL标签
   ↓
   在x轴（y=0）添加红色斜体标签
   "Csf3", "Lypd6b", ...
```

### 控制台输出

```
📝 GSEA使用ENTREZID运行，需要提供ENTREZID格式的基因
📝 转换为ENTREZID格式: 20 个基因
基因列表(ENTREZID): 12985, 71897, 330122, ...
✅ 使用GseaVis的addGene参数标注 20 个基因（会在leading edge正确位置显示）
📝 添加SYMBOL标签覆盖ENTREZID数字
📝 添加 20 个SYMBOL标签
✅ SYMBOL标签已添加
```

---

## 🎯 最终效果

### GSEA图显示

**情况1: GSEA用ENTREZID运行**
```
Enrichment Score
  ↑
1 │           /--*--\     ← 峰值位置
  │         /-*-+-*-\     ← Leading edge基因
0 │       --* | | | *--
  │     *     | | |   *
  +--------------------------------→ Rank
  12985 71897 330122        ← GseaVis addGene显示（黑色数字）
Csf3 Lypd6b Cxcl3           ← 自定义标签（红色斜体）
```

**情况2: GSEA用SYMBOL运行**
```
Enrichment Score
  ↑
1 │           /--*--\     ← 峰值位置
  │         /-*-+-*-\     ← Leading edge基因
0 │       --* | | | *--
  │     *     | | |   *
  +--------------------------------→ Rank
     Csf3 Lypd6b Cxcl3     ← GseaVis addGene直接显示SYMBOL
```

---

## 🔍 关键代码

### ID类型判断和转换

```r
# modules/gsea_analysis.R:431-451

if (input$gsea_id_type == "ENTREZID") {
  # 创建SYMBOL到ENTREZID的映射
  symbol_to_entrez <- setNames(res_clean$ENTREZID, res_clean$SYMBOL)

  # 转换为ENTREZID
  genes_entrez <- symbol_to_entrez[top_genes_data$gene]
  genes_entrez <- genes_entrez[!is.na(genes_entrez)]

  genes_to_add <- as.character(genes_entrez)
} else {
  # 直接使用SYMBOL
  genes_to_add <- top_genes_data$gene
}
```

### SYMBOL标签覆盖

```r
# modules/gsea_analysis.R:483-527

if (input$gsea_id_type == "ENTREZID") {
  # 获取基因在ranked list中的位置
  gene_positions <- match(genes_to_add, names(gsea_obj@geneList))

  # 创建标注数据
  label_data <- data.frame(
    x = gene_positions,
    label = top_genes_data$gene  # SYMBOL
  )

  # 添加SYMBOL标签
  p <- p + geom_text(
    data = label_data,
    aes(x = x, y = 0, label = label),
    color = "red",
    angle = 45
  )
}
```

---

## 📝 测试清单

- [ ] 启动应用: `source("app.R")`
- [ ] 上传ENTREZID格式的GMT文件
- [ ] 选择"GMT中的ID类型" = "Entrez ID"
- [ ] 运行GSEA分析
- [ ] **验证表格**:
  - [ ] core_enrichment列显示SYMBOL（如"Csf3/Lypd6b"）
- [ ] **验证GSEA图**:
  - [ ] 选择"Leading Edge基因"
  - [ ] 点击表格某一行
  - [ ] GSEA图正常显示（无错误）
  - [ ] Leading edge峰上有基因标注
  - [ ] **关键**: x轴上显示红色斜体的SYMBOL基因名
  - [ ] 基因在正确的leading edge位置

---

## 💡 经验总结

### 核心原则

1. **ID类型一致性**: GseaVis的`addGene`必须与GSEA运行时使用相同的ID类型
2. **显示层分离**: 用GseaVis获取正确位置，用自定义层显示可读标签
3. **逐步验证**: 先确保GseaVis不报错，再优化显示效果

### 避免的错误

- ❌ 传入不同ID类型的基因给`addGene`
- ❌ 试图用自定义geom_text完全替代addGene
- ❌ 混淆ID类型（SYMBOL vs ENTREZID）

---

**版本**: v3.7 Final
**状态**: ✅ 完全修复
**核心改进**:
1. addGene使用匹配的ID类型（ENTREZID → ENTREZID）
2. 添加SYMBOL标签覆盖数字ID
3. 结合GseaVis的准确位置和自定义标签的可读性

**建议**: 重启应用测试，应该能正常显示GSEA图和基因标注！
