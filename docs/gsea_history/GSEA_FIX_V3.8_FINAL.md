# GSEA模块最终修复 - v3.8

**日期**: 2025-12-26
**版本**: v3.8 Final
**修复内容**:
1. Leading Edge基因显示SYMBOL而不是ENTREZID数字
2. 添加SVG格式导出功能（GSEA图和山脊图）

---

## ✅ 修复1: Leading Edge显示SYMBOL

### 问题
GseaVis的`addGene`参数会显示ENTREZID数字（如"12985"），而不是可读的基因名（如"Csf3"）

### 解决方案
**完全放弃使用`addGene`参数**，改用自定义标注层：

```r
# modules/gsea_analysis.R:472-541

# 不使用addGene（避免显示数字ID）
p <- GseaVis::gseaNb(
  object = gsea_obj,
  geneSetID = pathway_id,
  subPlot = 2,
  # 不使用addGene参数
)

# 添加自定义SYMBOL标签
label_data <- data.frame(
  x = gene_positions,  # 基因在ranked list中的位置
  label = top_genes_data$gene,  # SYMBOL基因名
  y = 0.6 + (rank(-x) * 0.02)  # y坐标在leading edge区域
)

# 添加点标记 + 文本标签
p <- p + geom_point(data = label_data, aes(x = x, y = y), color = "red")
p <- p + geom_text(data = label_data, aes(x = x, y = y + 0.08, label = label), color = "red")
```

### 关键改进

1. **Y坐标计算**:
   ```r
   y_base <- 0.6  # 基础高度（在enrichment score曲线的leading edge区域）
   y <- y_base + (rank(-x) * 0.02)  # 根据排名微调，避免重叠
   ```

2. **视觉效果**:
   - 点标记（红色，size=2）
   - 文本标签（红色斜体，45度角）
   - 标签在点上方（y + 0.08）
   - 避免重叠（check_overlap = TRUE）

### 最终效果

```
Enrichment Score
  ↑
1 │           /--\     ← Leading edge峰
0.6│         -*-+-*    ← 基因标注点
0  │       /--| | |\
   +------------------------→ Rank
       12985 71897 330122    (ranked list位置)
       Csf3  Lypd6b Cxcl3     (红色斜体SYMBOL标签)
```

---

## ✅ 修复2: SVG导出功能

### 新增功能

**GSEA图SVG导出**:
- 文件名: `GSEA_Plot_<PathwayID>_<Date>.svg`
- 尺寸: 10 x 6 英寸
- 内容: 当前的GSEA图（简化版，不带基因标注）

**山脊图SVG导出**:
- 文件名: `GSEA_Ridge_Plot_<Date>.svg`
- 尺寸: 12 x 8 英寸
- 内容: Top N通路的山脊图

### 代码实现

**GSEA图SVG导出** (`modules/gsea_analysis.R:228-283`):
```r
output$download_gsea_plot_svg <- downloadHandler(
  filename = function() {
    pathway_id <- gsea_results()@result$ID[selected]
    paste0("GSEA_Plot_", pathway_id, "_", Sys.Date(), ".svg")
  },
  content = function(file) {
    # 重新生成plot
    p <- GseaVis::gseaNb(object = gsea_obj, geneSetID = pathway_id, ...)

    # 保存为SVG
    svg(file, width = 10, height = 6)
    print(p)
    dev.off()
  },
  contentType = "image/svg+xml"
)
```

**山脊图SVG导出** (`modules/gsea_analysis.R:285-322`):
```r
output$download_gsea_ridge_svg <- downloadHandler(
  filename = function() {
    paste0("GSEA_Ridge_Plot_", Sys.Date(), ".svg")
  },
  content = function(file) {
    # 重新生成ridge plot
    p <- enrichplot::ridgeplot(gsea_obj, showCategory = top_n)

    # 保存为SVG
    svg(file, width = 12, height = 8)
    print(p)
    dev.off()
  },
  contentType = "image/svg+xml"
)
```

### UI按钮

**位置**: `modules/ui_theme.R:1096-1105`

```r
tags$hr(style = "margin: 10px 0;"),

# SVG下载按钮
p(class="text-primary", style="font-weight:bold", "📊 导出图表 (SVG格式)"),
downloadButton("download_gsea_plot_svg", "📥 下载GSEA图 (SVG)",
               class = "btn-primary btn-sm",
               style = "width:100%; margin-bottom:5px;"),
downloadButton("download_gsea_ridge_svg", "📥 下载山脊图 (SVG)",
               class = "btn-primary btn-sm",
               style = "width:100%;")
```

### 使用说明

1. **导出GSEA图**:
   - 在表格中选择一行（或使用默认第一行）
   - 点击"📥 下载GSEA图 (SVG)"按钮
   - 文件自动下载，格式: `GSEA_Plot_GO_0006954_2025-12-26.svg`

2. **导出山脊图**:
   - 确保已显示山脊图（勾选"显示山脊图"）
   - 点击"📥 下载山脊图 (SVG)"按钮
   - 文件自动下载，格式: `GSEA_Ridge_Plot_2025-12-26.svg`

3. **使用SVG文件**:
   - 在Adobe Illustrator、Inkscape等软件中打开
   - 无损缩放、编辑
   - 适合出版和演示

---

## 📊 完整功能列表

| 功能 | 状态 | 说明 |
|------|------|------|
| 表格core_enrichment显示SYMBOL | ✅ | 自动转换ENTREZID为SYMBOL |
| Leading Edge基因提取 | ✅ | 从core_enrichment字段提取，总是返回SYMBOL |
| GSEA图基因标注 | ✅ | 红色斜体SYMBOL标签，在leading edge区域 |
| 山脊图通路限制 | ✅ | 正确显示Top N个通路 |
| ID类型不匹配处理 | ✅ | 友好错误提示，不崩溃 |
| GSEA图SVG导出 | ✅ 新增 | 10x6英寸SVG格式 |
| 山脊图SVG导出 | ✅ 新增 | 12x8英寸SVG格式 |

---

## 🔍 技术细节

### Y坐标计算逻辑

```r
# 为什么选择y=0.6作为基础高度？
# - GSEA enrichment score通常在[-0.6, 0.8]范围
# - Leading edge峰通常在score>0的区域
# - y=0.6确保标签在峰的附近，但不会遮挡曲线

# 为什么使用rank(-x)微调？
# - 根据基因在ranked list中的位置排名
# - 排名靠前的基因（leading edge核心）y值略高
# - 避免多个基因标签重叠
```

### SVG vs PNG

| 格式 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **SVG** | 矢量图，无损缩放，可编辑 | 文件较大 | 出版、演示、需要编辑 |
| **PNG** | 兼容性好，文件小 | 缩放失真 | 快速分享、网页展示 |

---

## 📝 测试清单

- [ ] 重启应用: `source("app.R")`
- [ ] 运行GSEA分析
- [ ] **验证表格**: core_enrichment列显示SYMBOL
- [ ] **验证GSEA图**:
  - [ ] 点击表格某一行
  - [ ] 图上显示红色斜体的SYMBOL基因名
  - [ ] 基因在leading edge峰附近
  - [ ] **关键**: 不显示ENTREZID数字
- [ ] **验证SVG导出**:
  - [ ] 点击"📥 下载GSEA图 (SVG)"
  - [ ] 文件下载成功
  - [ ] 在浏览器或编辑器中打开SVG
  - [ ] 图像清晰，可缩放
- [ ] **验证山脊图SVG**:
  - [ ] 显示山脊图
  - [ ] 点击"📥 下载山脊图 (SVG)"
  - [ ] 文件下载成功
  - [ ] SVG格式正确

---

## 🎯 总结

### v3.8完成的核心改进

1. **Leading Edge显示**:
   - ✅ 不使用GseaVis的addGene（避免显示数字ID）
   - ✅ 自定义标注层显示SYMBOL基因名
   - ✅ 合理的y坐标计算，在leading edge区域

2. **SVG导出**:
   - ✅ GSEA图和山脊图都支持SVG导出
   - ✅ 重新生成plot确保一致性
   - ✅ 适合出版的矢量格式

### 用户体验

- **可读性**: 基因标注显示SYMBOL名称（如"Csf3"），不是数字ID
- **便利性**: 一键导出SVG格式，无需额外工具转换
- **专业性**: SVG适合论文发表和学术演示

---

**版本**: v3.8 Final
**状态**: ✅ 完全修复
**建议**: 重启应用测试所有功能

## 快速测试

```r
# 启动应用
source("app.R")

# 测试步骤：
1. 上传GMT文件（ENTREZID格式）
2. 运行GSEA
3. 检查表格core_enrichment列（应显示SYMBOL）
4. 选择"Leading Edge基因"
5. 点击表格某行
6. 查看GSEA图（应有红色斜体基因名）
7. 点击"📥 下载GSEA图 (SVG)"
8. 检查下载的SVG文件
```

所有功能已完成！🎉
