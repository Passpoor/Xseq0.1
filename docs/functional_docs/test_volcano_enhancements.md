# 火山图功能优化总结

## 已完成的功能改进

### 1. 点透明度调整 ✅
- 添加了 `point_alpha` 滑块控件 (0.1-1.0)
- 在交互式火山图中使用 `opacity = input$point_alpha`
- 在静态导出图中使用 `alpha = input$point_alpha`

### 2. X轴(log2FoldChange)范围调整 ✅
- 添加了 `x_axis_min` 和 `x_axis_max` 数值输入框
- 默认值：-10 到 15
- 在交互式火山图中使用 `range = c(input$x_axis_min, input$x_axis_max)`
- 在静态导出图中使用 `xlim(input$x_axis_min, input$x_axis_max)`

### 3. Y轴类型选择 ✅
- 添加了 `y_axis_type` 选择器
- 选项："-log10(pvalue)" 和 "-log10(padj)"
- 默认选择 "-log10(pvalue)"
- 动态更新Y轴标题和计算方式

### 4. 坐标轴标签大小调整 ✅
- 添加了 `axis_label_size` 滑块 (10-20)
- 添加了 `axis_title_size` 滑块 (12-24)
- 应用于X轴和Y轴的标签和标题

### 5. 火山图导出功能 ✅
- 添加了PNG和PDF导出选项
- 可自定义导出图片的宽度和高度
- 使用高质量PNG (300 DPI) 和PDF格式
- 导出按钮位于火山图下方

### 6. PDF导出包支持 ✅
- 在 `install_packages.R` 中添加了 `svglite` 和 `Cairo` 包
- 这些包提供高质量的PDF导出功能

## 文件修改详情

### 1. `install_packages.R`
- 添加了 `svglite` 和 `Cairo` 包到CRAN包列表

### 2. `modules/ui_theme.R`
- 重新设计了火山图标签页的UI布局
- 添加了所有新的控制选项
- 添加了导出功能区域

### 3. `modules/differential_analysis.R`
- 更新了交互式火山图代码，集成所有新功能
- 添加了静态火山图生成函数用于导出
- 实现了PNG/PDF下载处理器

## 使用说明

1. **点样式设置**：
   - 点大小：5-15像素
   - 点透明度：0.1-1.0

2. **坐标轴设置**：
   - X轴范围：可自定义最小值和最大值
   - Y轴类型：可选择使用pvalue或padj
   - 标签大小：10-20像素
   - 标题大小：12-24像素

3. **导出设置**：
   - 格式：PNG或PDF
   - 尺寸：可自定义宽度和高度（英寸）
   - 点击"下载火山图"按钮导出

## 技术实现

- **交互式火山图**：使用 `plotly` 库，支持鼠标悬停查看基因信息
- **静态火山图**：使用 `ggplot2` 库，用于高质量导出
- **PDF导出**：使用R内置的 `pdf()` 函数，支持向量图形
- **PNG导出**：使用 `png()` 函数，300 DPI高质量输出

所有功能都已集成到现有的应用中，用户现在可以完全自定义火山图的外观并导出高质量的图片用于论文发表。