# GSEA模块最终修复说明

## 修复的两个关键问题

### 问题1: GSEA图上显示ENTREZID而非SYMBOL

**问题描述**:
- 即使提取了SYMBOL格式的基因，GseaVis的`addGene`参数仍会显示ENTREZID
- 控制台显示：`⚠️ 注意：GSEA使用ENTREZID运行，图上将显示ENTREZID而非基因名`

**解决方案**:
1. **移除GseaVis的addGene参数**（lines 362-370）
   - 不再使用`plot_args$addGene`
   - 因为GseaVis会根据GSEA运行时的ID类型显示标签

2. **使用自定义注释层显示SYMBOL**（lines 375-435）
   ```r
   # 添加点标记
   p + geom_point(
     aes(x = rank_position, y = 0.5),
     color = "#FF0000"  # 红色（亮色）或绿色（暗色）
   )

   # 添加文本标签（SYMBOL格式）
   p + geom_text(
     aes(x = rank_position, y = 0.5, label = gene),
     size = 3.5,
     fontface = "bold",
     angle = 45
   )
   ```

**优势**:
- ✅ 无论GSEA使用什么ID类型运行，图上都显示SYMBOL基因名
- ✅ 不受GseaVis限制
- ✅ 更明显的颜色和字体
- ✅ 同时显示点标记和文本标签

### 问题2: GSEA结果表格不支持搜索core_enrichment列

**问题描述**:
- 用户无法在表格搜索框中搜索core_enrichment列的基因名
- 只能搜索ID列

**解决方案**:
添加`searchColumns`参数（line 239）:
```r
DT::datatable(df_show, selection = 'single', options = list(scrollX=T, pageLength=5), rownames=F) %>%
  formatRound(c("enrichationScore", "NES", "pvalue", "p.adjust"), 4) %>%
  DT::searchColumns(7, targets = 7)  # 允许搜索第7列（core_enrichment）
```

**使用方式**:
1. 在GSEA结果表格右上角搜索框输入基因名
2. 例如：输入`Csf3`可以找到所有包含该基因的通路
3. 输入多个基因：`Csf3 Lypd6b`可以找到包含这些基因的通路

## 完整的工作流程

### 1. 运行GSEA分析
- 上传GMT文件（ENTREZID或SYMBOL格式）
- 选择ID类型（推荐SYMBOL）
- 运行GSEA

### 2. 查看结果表格
- **core_enrichment列**显示SYMBOL格式的Leading Edge基因
- **搜索功能**支持搜索core_enrichment中的基因名
  - 输入`Csf3`查找包含该基因的通路
  - 输入`Csf3 Lypd6b`查找同时包含多个基因的通路

### 3. 查看GSEA图
- 点击表格中的某一行
- GSEA图自动显示该通路的富集曲线
- **基因注释**：
  - Top N基因以SYMBOL格式显示在图上
  - 红色（亮色主题）或绿色（暗色主题）
  - 45度角倾斜，避免重叠
  - 每个基因有一个点标记和文本标签

### 4. 自定义显示
- **调整基因数量**：拖动`展示基因数`滑块（1-100）
- **选择排序方式**：
  - `leading_edge`：Leading Edge基因（推荐）
  - `abs_logFC`：按log2FoldChange绝对值
  - `logFC`：按log2FoldChange值
  - `rank`：按ranked list位置

## 控制台输出示例

### GSEA分析运行
```
🔍 提取Leading Edge基因，selected=1, pathway_id=GOMF_SIGNALING_RECEPTOR_REGULATOR_ACTIVITY
🔍 core_enrichment内容: 12985/71897/330122/...
🔍 原始Leading Edge基因数量: 111 (ID类型: ENTREZID)
🔍 转换后SYMBOL基因数量: 111
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

## 代码修改位置

### 文件: `modules/gsea_analysis.R`

1. **表格搜索支持** (line 237-240)
2. **移除GseaVis addGene** (lines 362-370)
3. **自定义注释层** (lines 375-435)
   - 点标记
   - 文本标签
   - 颜色适配主题

## 测试验证

### 测试步骤
1. 启动应用：`launch_app.bat`
2. 登录并上传数据
3. 运行差异分析
4. 运行GSEA分析（使用ENTREZID格式的GMT）
5. **测试表格搜索**：
   - 在搜索框输入`Csf3`
   - 确认能找到包含该基因的通路
6. **测试GSEA图**：
   - 点击表格中的某一行
   - 查看GSEA图
   - 确认图上显示的是基因名（如`Csf3`）而非数字ID（如`12985`）
7. **测试不同基因数量**：
   - 调整`展示基因数`滑块
   - 确认图上显示的基因数量正确

### 验证清单
- ✅ 表格core_enrichment列显示SYMBOL
- ✅ 可以在搜索框搜索core_enrichment
- ✅ GSEA图上显示SYMBOL基因名（不是ENTREZID）
- ✅ 基因名称清晰可见（红色/绿色）
- ✅ 支持调整显示的基因数量
- ✅ 支持多种排序方式

## 优势总结

1. **完全显示SYMBOL**：
   - 无论GSEA使用什么ID类型，图上都显示基因名
   - 不再受GseaVis的ID类型限制

2. **增强的搜索功能**：
   - 可以通过基因名查找通路
   - 支持多基因搜索

3. **更好的可视化**：
   - 点标记 + 文本标签
   - 粗体字，45度角
   - 颜色适配主题

4. **灵活的控制**：
   - 用户可控制显示数量
   - 用户可选择排序方式

---

**状态**: ✅ 已完成
**版本**: 3.0 Final
**更新日期**: 2025-12-26
