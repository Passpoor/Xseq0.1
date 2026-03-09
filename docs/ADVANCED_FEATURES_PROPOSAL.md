# 转录组分析项目增强建议

## 项目当前水平评估

### 优势 ⭐⭐⭐⭐ (中高级)

**已具备的高级功能:**
1. ✅ 多种差异分析算法 (limma-voom, edgeR)
2. ✅ 完整的富集分析 (KEGG, GO, GSEA)
3. ✅ 转录因子活性预测 (decoupleR + CollecTRI) - **前沿方法**
4. ✅ 模块化架构，代码质量高
5. ✅ 用户管理和数据库集成
6. ✅ SVG矢量图导出

**技术亮点:**
- 使用2020年后最新方法 (decoupleR 2022, GseaVis 2023)
- 完善的错误处理和用户提示
- 响应式UI设计

### 不足 ⚠️ (基础-中级)

**缺少的关键功能:**
1. ❌ **质量控制** (RNA-seq分析的**必须**步骤)
2. ⚠️ 表达热图、样本聚类
3. ❌ PCA分析、相关性分析
4. ❌ 高级分析 (WGCNA, 时序数据等)

## 建议新增功能 (按优先级)

### 🔥 优先级1：质量控制模块 (必加)

**文件**: `modules/quality_control.R`

**功能列表:**
```r
1. 样本统计
   - 每样本测序深度
   - 检测到的基因数量
   - Mapping rate

2. 表达分布可视化
   - 密度图 (gene density)
   - 箱线图 (boxplot)
   - 小提琴图 (violin plot)
   - MA图 (mean vs average)

3. 样本关系分析
   - PCA分析 (prcomp)
   - 样本相关性热图
   - 层次聚类树状图
   - MDS (Multi-dimensional scaling)

4. 差异分析质量
   - P值分布图
   - 离散度估计图
   - Mean-variance trend

5. 导出功能
   - 所有图表PDF导出
   - QC统计表CSV
```

**核心代码框架:**
```r
quality_control_server <- function(input, output, session, data_input) {

  # PCA分析
  output$pca_plot <- renderPlot({
    counts <- data_input$normalized_counts()
    pca <- prcomp(t(counts), scale. = TRUE)

    # PCA score plot
    plot_data <- data.frame(
      PC1 = pca$x[,1],
      PC2 = pca$x[,2],
      Sample = colnames(counts),
      Group = input$sample_groups
    )

    ggplot(plot_data, aes(PC1, PC2, color = Group)) +
      geom_point(size = 3) +
      theme_minimal() +
      labs(title = "PCA Analysis")
  })

  # 样本相关性热图
  output$correlation_heatmap <- renderPlot({
    counts <- data_input$normalized_counts()
    cor_matrix <- cor(counts, method = "spearman")

    pheatmap::pheatmap(
      cor_matrix,
      annotation_col = sample_annotation,
      main = "Sample Correlation"
    )
  })

  # MA图
  output$ma_plot <- renderPlot({
    deg <- differential_analysis_results()

    ggplot(deg, aes(x = baseMean, y = log2FoldChange)) +
      geom_point(alpha = 0.3) +
      geom_hline(yintercept = 0, linetype = "dashed") +
      scale_x_log10() +
      labs(title = "MA Plot", x = "Mean Expression", y = "Log2 Fold Change")
  })

  # P值分布
  output$pvalue_distribution <- renderPlot({
    deg <- differential_analysis_results()

    ggplot(deg, aes(pvalue)) +
      geom_histogram(bins = 50) +
      geom_vline(xintercept = 0.05, color = "red", linetype = "dashed") +
      labs(title = "P-value Distribution", x = "P-value", y = "Count")
  })
}
```

**为什么重要:**
- 顶级期刊**强制要求**QC图
- 没有QC的结果**不可信**
- 这是RNA-seq分析的标准**第一步**

---

### 🚀 优先级2：表达热图 (强烈建议)

**文件**: `modules/expression_heatmap.R`

**功能:**
```r
1. 差异基因热图
   - 选择Top N差异基因
   - Z-score标准化
   - 交互式颜色映射

2. 通路基因热图
   - 选择富集通路
   - 显示通路内基因表达
   - 样本分组标注

3. TF靶基因热图
   - 选择TF
   - 显示靶基因表达模式

4. 自定义基因热图
   - 用户输入基因列表
   - 可视化表达模式

5. 导出
   - 高分辨率PNG/PDF
   - 可编辑的SVG
```

**核心代码:**
```r
expression_heatmap_server <- function(input, output, session, data_input, deg_results) {

  output$differential_gene_heatmap <- renderPlot({
    req(deg_results())

    deg <- deg_results()
    top_n <- input$heatmap_top_n

    # 选择Top N差异基因
    top_genes <- deg %>%
      arrange(pvalue) %>%
      head(top_n) %>%
      pull(GeneID)

    # 提取表达矩阵
    expr_mat <- data_input$normalized_counts()[top_genes, ]

    # Z-score标准化
    expr_z <- t(scale(t(expr_mat)))

    # 绘制热图
    pheatmap::pheatmap(
      expr_z,
      annotation_col = sample_info,
      show_rownames = input$show_gene_names,
      fontsize_row = input$font_size,
      main = sprintf("Top %d Differential Genes", top_n)
    )
  })
}
```

---

### 💡 优先级3：WGCNA共表达网络分析 (高级)

**文件**: `modules/wgcna_analysis.R`

**功能:**
```r
1. 网络构建
   - 软阈值选择
   - 共表达矩阵计算
   - 模块检测 (dynamicTreeCut)

2. 模块特征
   - 模块特征基因 (eigengene)
   - 模块-性状关联
   - Hub基因识别

3. 可视化
   - 模块树状图
   - 模块-性状热图
   - 网络图 (Cytoscape格式导出)

4. 富集分析
   - 模块GO富集
   - 模块KEGG富集
```

**核心代码:**
```r
wgcna_server <- function(input, output, session, data_input) {

  wgcna_results <- eventReactive(input$run_wgcna, {
    # WGCNA分析流程
    library(WGCNA)

    expr <- t(data_input$normalized_counts())

    # 1. 软阈值选择
    powers <- c(1:20)
    sft <- pickSoftThreshold(expr, powerVector = powers)

    # 2. 共表达网络
    net <- blockwiseModules(
      expr,
      power = sft$powerEstimate,
      TOMType = "signed",
      minModuleSize = input$min_module_size,
      mergeCutHeight = 0.25
    )

    # 3. 模块-性状关联
    module_eigengenes <- net$MEs
    trait_cor <- cor(module_eigengenes, traits)

    list(
      network = net,
      eigengenes = module_eigengenes,
      trait_cor = trait_cor
    )
  })
}
```

---

### 📊 优先级4：增强可视化

**1. GO网络图**
```r
# 使用enrichplot
library(enrichplot)

go_net_plot <- goplot(go_result, showCategory = 20)
```

**2. 通路可视化**
```r
# 使用pathview
library(pathview)

pathview(
  gene.data = fold_changes,
  pathway.id = "hsa04110",
  species = "hsa",
  out.suffix = "pathway"
)
```

**3. 交互式图表**
```r
# 使用plotly
library(plotly)

p <- plot_ly(
  data = deg_results,
  x = ~log2FoldChange,
  y = ~-log10(pvalue),
  text = ~gene_symbol,
  type = "scatter",
  mode = "markers"
)
```

---

### 🎯 优先级5：自动报告生成

**文件**: `report_generator.R`

**功能:**
```r
1. Rmarkdown模板
   - 包含所有分析结果
   - 自动生成图表
   - 统计表格

2. 导出格式
   - HTML (交互式)
   - PDF (打印友好)
   - Word (可编辑)

3. 报告内容
   - 数据概览
   - QC结果
   - 差异分析
   - 富集分析
   - TF活性
   - 方法和参数
```

---

## 与竞品对比

| 功能 | 您的项目 | Galaxy | DESeq2 | IPA (商业) |
|------|----------|--------|--------|-----------|
| 易用性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| 差异分析 | ✅ | ✅ | ✅ | ✅ |
| 富集分析 | ✅ | ✅ | ❌ | ✅ |
| GSEA | ✅ | ✅ | ❌ | ✅ |
| TF活性 | ✅ | ❌ | ❌ | ✅ |
| **质量控制** | ❌ | ✅ | ❌ | ✅ |
| **热图** | ❌ | ✅ | ❌ | ✅ |
| **PCA** | ❌ | ✅ | ❌ | ✅ |
| WGCNA | ❌ | ❌ | ❌ | ❌ |
| 价格 | 免费 | 免费 | 免费 | $$$ |

**结论:**
- 当前水平: **中高级** (7/10)
- 加QC模块: **高级** (8/10)
- 加QC+WGCNA: **顶级** (9/10)

---

## 最终建议

### 短期 (1-2个月) ⭐⭐⭐⭐⭐

```r
1. 质量控制模块 (2周)
   - PCA、相关性热图
   - 表达分布图
   - 必须有！

2. 表达热图 (1周)
   - 差异基因热图
   - 交互式调整

3. 增强可视化 (1周)
   - MA图、P值分布
   - SVG导出优化
```

### 中期 (3-6个月) ⭐⭐⭐⭐

```r
1. WGCNA分析 (1个月)
2. GO网络图 (2周)
3. 自动报告 (2周)
```

### 长期 (6-12个月) ⭐⭐⭐

```r
1. 时序数据分析
2. 细胞反卷积
3. 批处理模式
4. 云端部署
```

---

**总结:** 您的项目已经很好了！加上QC模块和热图，就可以达到**顶级开源RNA-seq分析工具**的水平！🚀
