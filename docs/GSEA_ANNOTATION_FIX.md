# GSEA基因名称注释 - 快速修复

## 修复的问题

**错误**: `找不到对象'id_col'`

**原因**: 在`renderPlot`函数内部添加基因名称注释时，使用了`id_col`和`res_clean`变量，但这些变量在`renderPlot`作用域内未定义。

## 修复内容

**文件**: `modules/gsea_analysis.R`
**位置**: lines 424-432

在添加基因名称注释之前，增加了必要的变量定义：

```r
# 获取差异分析数据用于计算ranked list位置
deg_data <- deg_results()
res <- deg_data$deg_df
id_col <- if(input$gsea_id_type == "SYMBOL") "SYMBOL" else "ENTREZID"
res_clean <- res[!is.na(res[[id_col]]) & !is.na(res$log2FoldChange), ]
res_clean <- res_clean %>%
  group_by(!!sym(id_col)) %>%
  filter(abs(log2FoldChange) == max(abs(log2FoldChange))) %>%
  ungroup()
```

## 功能说明

修复后，GSEA图会自动显示基因名称注释：

1. **基因来源**: 从`core_enrichment`列提取Leading Edge基因
2. **显示数量**: 由`gsea_top_genes`参数控制（默认20个）
3. **排序方式**: 根据`gsea_gene_order`参数选择
4. **注释样式**:
   - 亮色主题：红色基因名
   - 暗色主题：黄色基因名
   - 45度角倾斜，避免重叠

## 控制台输出示例

```
📝 添加基因名称注释到GSEA图...
✅ 准备标注 20 个基因名称
✅ 基因名称注释已添加
```

## 使用建议

1. **推荐配置**:
   - ID类型: SYMBOL（自动转换GMT文件）
   - 基因排序: GSEA Leading Edge基因
   - Top N基因: 20

2. **查看效果**:
   - 运行GSEA分析
   - 点击结果表格中的某一行
   - GSEA图上会显示Top N基因名称（如`Csf3`, `Lypd6b`, `Cxcl3`）

## 测试步骤

1. 启动应用：`launch_app.bat`
2. 登录并上传数据
3. 运行差异分析
4. 运行GSEA分析
5. 点击GSEA结果表格的某一行
6. 查看生成的GSEA图：
   - 应该看到基因名称标注（红色或黄色）
   - 基因名标注在它们对应的ranked list位置

---

**状态**: ✅ 已修复
**版本**: 2.1
**更新日期**: 2025-12-26
