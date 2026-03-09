# GSEA基因名称注释功能说明

## 功能介绍

在GSEA富集图上，现在会自动显示用户自定义的Top N基因名称作为注释。这些基因名称来自表格中`core_enrichment`列的Leading Edge基因。

## 工作原理

### 1. 基因来源
- 从您点击的GSEA结果表格行中提取`core_enrichment`基因
- 这些是驱动该通路富集的核心基因（Leading Edge genes）

### 2. 显示数量控制
- 由UI中的**"展示基因数"**（`gsea_top_genes`）参数控制
- 默认显示Top 20个基因
- 可调整显示1-100个基因

### 3. 排序方式
支持4种基因排序方式：
1. **GSEA Leading Edge基因**（推荐）- 按在ranked list中的位置
2. **按log2FoldChange绝对值** - 最大的变化优先
3. **按log2FoldChange值** - 正值最大的优先
4. **按基因排名** - 在ranked list中的位置

### 4. 注释样式
- **位置**: 基因在ranked list中的位置（x轴）
- **颜色**:
  - 亮色主题：红色
  - 暗色主题：黄色
- **角度**: 45度倾斜，避免重叠
- **字体**: 小号字体（size=3）

## 使用示例

### 场景1: 查看某个通路的Leading Edge基因

1. 运行GSEA分析
2. 在结果表格中点击感兴趣的通路行
3. 设置"展示基因数"为20（默认）
4. 选择"基因排序方式"为"GSEA Leading Edge基因"
5. 查看GSEA图：
   - 图上会显示20个基因名称（如`Csf3`, `Lypd6b`, `Cxcl3`等）
   - 基因名标注在它们对应的ranked list位置

### 场景2: 显示更多或更少的基因

1. 调整"展示基因数"滑块
   - 拖到50: 显示Top 50个基因
   - 拖到10: 显示Top 10个基因
2. GSEA图会自动更新，显示相应数量的基因名

### 场景3: 按不同方式排序基因

1. 选择"基因排序方式"为"按log2FoldChange绝对值"
2. GSEA图会优先显示变化最显著的基因名称

## 控制台输出

生成GSEA图时，控制台会显示详细信息：

```
🔍 提取Leading Edge基因，selected=1, pathway_id=GO_Biological_Process
✅ 提取了 20 个真正的Leading Edge基因 (ID类型: SYMBOL)
✅ Leading Edge基因示例: Csf3, Lypd6b, Cxcl3, Il1r2, Fgf7...

📝 添加基因名称注释到GSEA图...
✅ 准备标注 20 个基因名称
✅ 基因名称注释已添加
```

## 技术细节

### 代码位置
`modules/gsea_analysis.R` lines 417-451

### 实现逻辑
```r
# 1. 从extract_leading_edge_genes获取Top N基因数据
top_genes_data <- extract_leading_edge_genes()

# 2. 计算每个基因在ranked list中的位置（用于x坐标）
top_genes_data$rank_position <- match(top_genes_data$gene, names(gene_list))

# 3. 添加文本注释层到GSEA图
p <- p + geom_text(
  data = top_genes_data,
  aes(x = rank_position, y = 0.5, label = gene),
  size = 3,
  color = "red",  # 或黄色（暗色主题）
  angle = 45
)
```

### 与GseaVis的区别

| 功能 | GseaVis addGene | 新增注释层 |
|------|----------------|-----------|
| 用途 | 在图上标记基因位置 | 显示基因名称文本 |
| ID要求 | 必须与GSEA运行ID类型一致 | 始终使用SYMBOL |
| 显示形式 | 点标记 | 文本标签 |
| 控制方式 | 内部自动 | 用户自定义Top N |

**两者互不干扰，可以同时显示！**

## 常见问题

### Q: 为什么有些基因没有显示名称？
A: 可能原因：
1. 基因不在ranked list中（没有log2FoldChange值）
2. ID映射失败（ENTREZID无法转换为SYMBOL）
3. 基因数量超过设置的Top N

### Q: 基因名称重叠怎么办？
A: 解决方法：
1. 减少"展示基因数"
2. 基因名已设置45度角倾斜，尽量减少重叠
3. 保存为高分辨率图片可更清晰

### Q: 注释颜色可以自定义吗？
A: 当前根据主题自动选择：
- 亮色主题：红色（便于阅读）
- 暗色主题：黄色（高对比度）

### Q: 可以只显示特定基因吗？
A: 当前功能显示Top N基因。如需自定义基因列表，请使用"自定义基因列表"功能。

## 优势

1. **直观**: 直接在图上看到基因名称，无需对照ID
2. **灵活**: 可控制显示数量和排序方式
3. **智能**: 自动从core_enrichment提取Leading Edge基因
4. **兼容**: 不影响GseaVis的原有功能
5. **主题适配**: 自动适配亮/暗色主题

---

**版本**: 2.0
**更新日期**: 2025-12-26
**作者**: Biofree Development Team
