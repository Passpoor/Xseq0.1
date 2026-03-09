# 单细胞分析对接方案评估

## 🎯 核心思路：利用bulk RNA-seq结果解读单细胞数据

### 为什么这个方案可行？

**现有优势:**
1. ✅ 已有差异基因列表
2. ✅ 已有通路富集结果
3. ✅ 已有TF活性预测
4. ✅ 用户熟悉分析流程

**单细胞数据特点:**
- 细胞异质性
- 聚类和细胞类型
- 标记基因
- 细胞类型比例变化

**结合点:**
- 用bulk分析找到的"关键基因/通路/TF"去解读单细胞数据
- 用单细胞数据验证bulk结果的细胞类型来源
- 节省计算资源，提升分析速度

---

## 📊 方案对比

### 方案A：完整单细胞分析流程 ❌ (不现实)

**包含内容:**
```
1. 质控和过滤 (Seurat/Scanpy)
2. 标准化 (LogNormalize/SCTransform)
3. 降维 (PCA, UMAP, t-SNE)
4. 聚类 (Louvain/Leiden)
5. 细胞类型注释
6. 差异表达
7. 轨迹分析 (Monocle/PAGA)
8. 细胞通讯 (CellChat)
```

**问题:**
- ❌ 计算量巨大 (10K+细胞 x 20K基因)
- ❌ Shiny应用无法承受
- ❌ 需要专门的生物学知识
- ❌ 违背项目定位 (bulk分析工具)

**结论: 不推荐**

---

### 方案B：细胞反卷积分析 ⭐⭐⭐⭐⭐ (强烈推荐)

**原理:**
```
Bulk RNA-seq = 各种细胞类型的混合信号

细胞反卷积 = 从bulk数据中推断每种细胞类型的比例

例子:
心脏组织bulk RNA-seq
  ↓ 细胞反卷积
心肌细胞: 60%
成纤维细胞: 25%
内皮细胞: 10%
免疫细胞: 5%
```

**为什么适合?**
1. ✅ **输入**: bulk RNA-seq数据 (已有)
2. ✅ **输出**: 细胞类型比例 (新信息)
3. ✅ **计算**: 快速 (几分钟)
4. ✅ **生物学意义**: 明确
5. ✅ **可对接**: 与差异分析、TF活性结合

**主要算法:**
```r
1. CIBERSORTx (最流行)
   - LM22 signature matrix
   - 22种免疫细胞
   - P值和相关性

2. xCell
   - 64种细胞类型
   - 包含非免疫细胞
   - 速度快

3. EPIC
   - 实质组织
   - 癌症相关

4. quanTIseq
   - 免疫细胞
   - 实时定量
```

**实现工作量:**
```
基础版本 (1种算法): 1周
完整版本 (3-4种算法): 2-3周
可视化 (热图、箱线图): 1周
UI集成: 3-5天

总计: 3-4周
```

**核心代码框架:**
```r
# modules/cell_deconvolution.R

cell_deconvolution_server <- function(input, output, session, deg_results) {

  # 使用xCell (免费、快速)
  output$cell_proportion <- eventReactive(input$run_deconvolution, {
    library(xCell)

    # 获取表达矩阵
    expr_mat <- normalized_counts()

    # 细胞反卷积
    cell_props <- xCell::xCellAnalysis(expr_mat)

    # 返回细胞类型比例
    return(cell_props)
  })

  # 可视化
  output$cell_proportion_heatmap <- renderPlot({
    props <- cell_proportion()

    pheatmap::pheatmap(
      props,
      main = "Cell Type Proportions",
      cluster_rows = TRUE,
      cluster_cols = TRUE
    )
  })

  # 与分组关联
  output$cell_proportion_boxplot <- renderPlot({
    props <- cell_proportion()

    plot_data <- gather(props, key = "CellType", value = "Proportion")

    ggplot(plot_data, aes(x = Group, y = Proportion, fill = Group)) +
      geom_boxplot() +
      facet_wrap(~CellType, scales = "free_y") +
      theme_minimal()
  })
}
```

---

### 方案C：单细胞标记基因映射 ⭐⭐⭐⭐ (推荐)

**原理:**
```
Bulk分析找到的差异基因
  ↓
映射到单细胞标记基因数据库
  ↓
推测哪些细胞类型最相关
```

**数据库:**
```r
1. CellMarker (人/小鼠)
   - 组织特异性标记基因
   - 手工整理

2. PanglaoDB
   - 单细胞标记基因
   - 多种组织/细胞类型

3. Human Cell Atlas
   - 官方细胞图谱
   - 高质量注释

4. Mouse Cell Atlas
   - 小鼠细胞图谱
```

**实现方式:**
```r
# modules/sc_marker_mapping.R

sc_marker_server <- function(input, output, session, deg_results) {

  # 1. 加载标记基因数据库
  marker_db <- reactive({
    # 从CellMarker/PanglaoDB下载
    load_marker_database(input$organism)
  })

  # 2. 映射差异基因
  output$cell_type_enrichment <- eventReactive(input$map_markers, {
    deg_genes <- deg_results()$deg_df$SYMBOL
    markers <- marker_db()

    # 超几何检验
    for (cell_type in unique(markers$cell_type)) {
      cell_markers <- markers$gene[markers$cell_type == cell_type]
      overlap <- intersect(deg_genes, cell_markers)

      # Fisher精确检验
      pval <- fisher.test(
        matrix(c(length(overlap),
                 length(setdiff(cell_markers, deg_genes)),
                 length(setdiff(deg_genes, cell_markers)),
                 n_all_genes - length(deg_genes) - length(cell_markers) + length(overlap)),
               nrow = 2)
      )$p.value

      results <- rbind(results, data.frame(
        CellType = cell_type,
        Overlap = length(overlap),
        Pvalue = pval,
        Markers = paste(cell_markers, collapse = ",")
      ))
    }

    return(results)
  })

  # 3. 可视化
  output$cell_type_barplot <- renderPlot({
    results <- cell_type_enrichment()

    ggplot(results, aes(x = reorder(CellType, -log10(Pvalue)), y = -log10(Pvalue))) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(title = "Enriched Cell Types",
           x = "Cell Type",
           y = "-log10(P-value)")
  })
}
```

**优势:**
- ✅ 不需要单细胞数据
- ✅ 计算快速
- ✅ 生物学解释明确
- ✅ 可与TF活性、通路分析结合

**工作量:** 2-3周

---

### 方案D：细胞类型特异性基因表达 ⭐⭐⭐ (可选)

**原理:**
```
利用CellMarker数据库
  ↓
查看某细胞类型的标记基因在bulk数据中的表达
  ↓
推测该细胞类型的活性
```

**实现:**
```r
# modules/celltype_specific_expression.R

output$celltype_expr <- renderPlot({
  markers <- get_cell_markers(input$cell_type, input$organism)

  # 提取表达数据
  expr_data <- normalized_counts()[markers, ]

  # 热图
  pheatmap::pheatmap(
    expr_data,
    annotation_col = sample_info,
    main = paste(input$cell_type, "Marker Genes"),
    scale = "row"
  )
})
```

**工作量:** 1周

---

### 方案E：细胞-细胞通讯预测 ⭐⭐⭐ (进阶)

**原理:**
```
基于TF活性和配体-受体数据库
  ↓
预测细胞间通讯
  ↓
可视化通讯网络
```

**数据库:**
```r
1. CellChatDB
   - 配体-受体对
   - 信号通路
   - 细胞类型特异性

2. CellTalkDB
   - 人/小鼠
   - 多种组织

3. iTALK
   - 免疫细胞通讯
```

**实现:**
```r
# modules/cell_communication.R

cell_comm_server <- function(input, output, session, tf_results) {

  # 获取高活性TF
  active_tfs <- tf_results() %>%
    filter(score > input$tf_score_cutoff)

  # 映射到配体-受体
  comm_pairs <- predict_communication(active_tfs, cellchatdb)

  # 可视化网络
  output$comm_network <- renderPlot({
    ggraph::ggraph(comm_pairs, layout = "kk") +
      geom_edge_link(aes(color = pathway)) +
      geom_node_point(aes(size = degree)) +
      geom_node_label(aes(label = cell_type))
  })
}
```

**工作量:** 3-4周

---

## 🎯 最佳组合方案

### **推荐方案: A + B + C** ⭐⭐⭐⭐⭐

**第一阶段 (2-3周): 细胞反卷积**
```r
1. xCell分析 (快速、免费)
2. CIBERSORTx (需要注册，但更准确)
3. 可视化:
   - 细胞比例热图
   - 分组对比箱线图
   - 相关性分析
```

**第二阶段 (2-3周): 标记基因映射**
```r
1. CellMarker数据库
2. PanglaoDB
3. 超几何检验
4. 可视化:
   - 细胞类型富集图
   - 标记基因表达热图
```

**第三阶段 (3-4周): 整合分析**
```r
1. 细胞比例 ↔ 差异表达
2. 细胞比例 ↔ TF活性
3. 细胞比例 ↔ 通路富集
4. 综合报告
```

**总工作量:** 7-10周
**价值提升:** ⭐⭐⭐⭐⭐

---

## 📊 与现有模块的整合

### 数据流整合

```
现有分析:
  差异基因 → 通路富集 → TF活性
                    ↓
            单细胞分析 (新增)
                    ↓
  细胞反卷积 → 细胞类型富集 → 通讯预测
                    ↓
            整合可视化
  - 细胞比例 vs TF活性
  - 细胞比例 vs 通路活性
  - 细胞类型标记基因表达
```

### UI整合

```
主界面添加:
  ┌─────────────────────────────┐
  │ 🧬 Bulk RNA-seq Analysis    │
  │  ├─ 差异分析                │
  │  ├─ 富集分析                │
  │  └─ TF活性                  │
  │                              │
  │ 📊 Single Cell Integration  │ (新增)
  │  ├─ 细胞反卷积               │
  │  ├─ 标记基因映射             │
  │  └─ 细胞-细胞通讯            │
  └─────────────────────────────┘
```

---

## 🚀 实施路线图

### **Phase 1: 细胞反卷积 (3周)** ⭐⭐⭐⭐⭐

```r
Week 1: 基础功能
  - xCell集成
  - 基本可视化
  - UI框架

Week 2: 增强功能
  - CIBERSORTx (可选)
  - quanTIseq
  - 多算法对比

Week 3: 可视化完善
  - 热图、箱线图
  - 与分组关联
  - 导出功能
```

### **Phase 2: 标记基因映射 (3周)** ⭐⭐⭐⭐

```r
Week 4-5: 数据库集成
  - CellMarker
  - PanglaoDB
  - 超几何检验

Week 6: 可视化
  - 细胞类型富集图
  - 标记基因热图
  - 通路整合
```

### **Phase 3: 整合分析 (4周)** ⭐⭐⭐⭐⭐

```r
Week 7-8: 关联分析
  - 细胞比例 vs TF活性
  - 细胞比例 vs 通路活性
  - 统计检验

Week 9-10: 高级可视化
  - 网络图
  - 综合报告
  - 导出功能
```

---

## 📝 代码示例：细胞反卷积模块

### 完整实现框架

```r
# modules/cell_deconvolution.R

cell_deconvolution_server <- function(input, output, session, data_input, deg_results) {

  # ========================================
  # 1. 细胞反卷积分析
  # ========================================

  cell_props <- eventReactive(input$run_cell_deconvolution, {
    req(data_input$normalized_counts())

    showNotification("正在进行细胞反卷积分析...", type = "message")

    # 获取表达矩阵
    expr_mat <- data_input$normalized_counts()

    # 选择算法
    tryCatch({
      if (input$deconv_method == "xcell") {
        # 使用xCell
        library(xCell)
        props <- xCell::xCellAnalysis(expr_mat)

      } else if (input$deconv_method == "cibersort") {
        # 使用CIBERSORTx (需要签名矩阵)
        library(CIBERSORTx)
        sig_matrix <- load_signature_matrix(input$tissue_type)
        props <- CIBERSORTx::cibersortx_sig(
          expr_mat,
          sig_matrix,
          perm = 1000
        )

      } else if (input$deconv_method == "quantiseq") {
        # 使用quanTIseq
        library(immuneDeconv)
        props <- immuneDeconv::deconvolute(
          expr_mat,
          method = "quantiseq"
        )
      }

      showNotification("细胞反卷积完成!", type = "message")
      return(props)

    }, error = function(e) {
      showNotification(paste("细胞反卷积失败:", e$message), type = "error")
      return(NULL)
    })
  })

  # ========================================
  # 2. 细胞比例热图
  # ========================================

  output$cell_prop_heatmap <- renderPlot({
    req(cell_props())

    props <- cell_props()

    # 添加样本分组信息
    annotation_col <- data.frame(
      Group = data_input$sample_groups()
    )
    rownames(annotation_col) <- colnames(props)

    # 绘制热图
    pheatmap::pheatmap(
      props,
      annotation_col = annotation_col,
      main = "Cell Type Proportions",
      cluster_rows = TRUE,
      cluster_cols = TRUE,
      display_numbers = TRUE,
      number_format = "%.2f",
      color = colorRampPalette(c("navy", "white", "firebrick3"))(50)
    )
  })

  # ========================================
  # 3. 分组对比箱线图
  # ========================================

  output$cell_prop_boxplot <- renderPlot({
    req(cell_props())

    props <- cell_props()
    sample_info <- data_input$sample_info()

    # 整理数据
    plot_data <- reshape2::melt(
      as.matrix(props),
      varnames = c("Sample", "CellType"),
      value.name = "Proportion"
    )

    plot_data$Group <- sample_info[plot_data$Sample, "Group"]

    # 绘制箱线图
    ggplot(plot_data, aes(x = Group, y = Proportion, fill = Group)) +
      geom_boxplot(outlier.shape = NA) +
      geom_point(position = position_jitter(width = 0.2), alpha = 0.5) +
      facet_wrap(~CellType, scales = "free_y", ncol = 4) +
      labs(
        title = "Cell Type Proportions by Group",
        x = "Group",
        y = "Proportion"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        strip.text = element_text(face = "bold")
      )
  })

  # ========================================
  # 4. 与差异分析整合
  # ========================================

  output$cell_prop_degs <- renderPlot({
    req(cell_props(), deg_results())

    props <- cell_props()
    deg <- deg_results()$deg_df

    # 计算细胞比例与差异基因数量的相关性
    cell_types <- colnames(props)

    results <- data.frame()
    for (ct in cell_types) {
      prop <- props[, ct]

      # 计算相关性
      for (gene in rownames(deg)) {
        expr <- data_input$normalized_counts()[gene, ]

        cor_test <- cor.test(prop, expr, method = "spearman")

        results <- rbind(results, data.frame(
          CellType = ct,
          Gene = gene,
          Cor = cor_test$estimate,
          Pvalue = cor_test$p.value
        ))
      }
    }

    # 选择top相关
    top_cor <- results %>%
      filter(!is.na(Pvalue)) %>%
      arrange(Pvalue) %>%
      head(50)

    # 热图
    cor_mat <- reshape2::acast(
      top_cor,
      Gene ~ CellType,
      value.var = "Cor"
    )

    pheatmap::pheatmap(
      cor_mat,
      main = "Cell Type - Gene Expression Correlation",
      cluster_rows = TRUE,
      cluster_cols = TRUE,
      color = colorRampPalette(c("blue", "white", "red"))(50)
    )
  })

  # ========================================
  # 5. 导出结果
  # ========================================

  output$download_cell_props <- downloadHandler(
    filename = function() {
      paste0("Cell_Proportions_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(cell_props())
      write.csv(cell_props(), file, row.names = TRUE)
    }
  )
}
```

---

## 🎯 总结与建议

### ✅ 强烈推荐添加

**1. 细胞反卷积** ⭐⭐⭐⭐⭐
- 工作量: 2-3周
- 价值: 极高
- 难度: 中等

**2. 标记基因映射** ⭐⭐⭐⭐
- 工作量: 2-3周
- 价值: 高
- 难度: 中等

**3. 整合可视化** ⭐⭐⭐⭐⭐
- 工作量: 3-4周
- 价值: 极高
- 难度: 中等

### 总计
- **工作量**: 7-10周
- **价值**: 让项目从"bulk分析工具"升级为"整合分析平台"
- **竞争力**: 大幅提升，区别于其他bulk分析工具

---

**我的建议**: 先从**细胞反卷积**开始，这是最容易实现且价值最高的功能！
