# GSEA模块测试指南

## 🚀 快速启动

### 方法1: 使用批处理文件（Windows）
双击运行 `launch_app.bat`

### 方法2: 使用R脚本
```r
# 在R或RStudio中运行
source("launch_app.R")
```

### 方法3: 在RStudio中
1. 打开 `app.R`
2. 点击右上角的 "Run App" 按钮
3. 或按 `Ctrl+Shift+Enter`

## 🧪 运行测试

### 测试GSEA模块功能
```r
source("test_gsea_module.R")
```

这个脚本会检查：
- ✅ 必要的R包是否安装
- ✅ 模块文件是否存在
- ✅ GSEA功能是否正确实现
- ✅ UI配置是否完整

## 📊 GSEA模块功能说明

### 核心功能
1. **真正的Leading Edge基因提取**
   - 从GSEA的`core_enrichment`字段提取
   - 这些是驱动通路富集的核心基因

2. **多种基因排序方式**
   - 🔥 GSEA Leading Edge基因（推荐）
   - 按log2FoldChange绝对值
   - 按log2FoldChange值
   - 按基因在ranked list中的位置

3. **双ID类型支持**
   - SYMBOL（推荐，显示基因名如`Csf3`）
   - ENTREZID（显示数字ID如`12985`）

4. **可视化功能**
   - GseaVis富集图（带基因标记）
   - 山脊图多通路可视化
   - 自定义基因列表标记

### 使用建议

#### 推荐配置（最佳显示效果）
```
ID类型: SYMBOL ✅
基因排序: GSEA Leading Edge基因
Top N基因: 20
```

#### 高级用户配置
```
ID类型: ENTREZID（当GMT文件要求时）
基因排序: 按log2FoldChange绝对值
Top N基因: 50
```

## 🔍 调试信息

运行GSEA时，控制台会显示详细调试信息：

```
🔍 提取Leading Edge基因，selected=1, pathway_id=GO_XXX
🔍 core_enrichment内容: 12985/71897/...
🔍 原始Leading Edge基因数量: 111 (ID类型: ENTREZID)
🔍 转换后SYMBOL基因数量: 111
✅ 提取了 20 个真正的Leading Edge基因
✅ Leading Edge基因示例: Csf3, Lypd6b, Cxcl3...
✅ 使用SYMBOL基因（显示基因名）: 20 个
```

## ⚠️ 常见问题

### Q1: 图上显示的是数字ID而不是基因名？
**A**: 这是因为使用了ENTREZID作为ID类型。
- **解决方法**: 在UI中选择SYMBOL作为ID类型
- 当前会显示映射关系: `12985 -> Csf3`

### Q2: 山脊图显示"找不到对象'selected'"？
**A**: 这是enrichplot包的内部问题。
- **解决方法**: 已添加错误处理，会显示友好的错误信息
- 可以尝试减少显示的通路数量

### Q3: "Your gene is not in this pathway!"？
**A**: 基因ID类型不匹配。
- **检查**: GMT文件的ID类型与选择的ID类型是否一致
- **解决**: 使用SYMBOL类型，或确保GMT使用ENTREZID

## 📝 代码文件说明

| 文件 | 说明 |
|------|------|
| `app.R` | 主应用文件 |
| `modules/gsea_analysis.R` | GSEA分析模块（核心） |
| `modules/ui_theme.R` | UI界面定义 |
| `modules/data_input.R` | 数据输入模块 |
| `modules/differential_analysis.R` | 差异分析模块 |
| `test_gsea_module.R` | 测试脚本 |
| `launch_app.R` | 快速启动脚本 |
| `launch_app.bat` | Windows批处理启动器 |

## 🎯 测试步骤

1. **启动应用**
   ```
   双击 launch_app.bat
   ```

2. **登录系统**
   - 使用测试账号或注册新账号

3. **上传数据**
   - 上传表达矩阵文件
   - 配置样本分组

4. **运行差异分析**
   - 设置差异分析参数
   - 等待分析完成

5. **运行GSEA分析**
   - 上传GMT文件
   - 选择ID类型（推荐SYMBOL）
   - 点击"运行GSEA"

6. **查看结果**
   - 点击GSEA结果表格中的某一行
   - 查看带Leading Edge基因标记的GSEA图
   - 可选：显示山脊图

7. **检查调试输出**
   - 在R控制台查看详细的调试信息
   - 确认Leading Edge基因正确提取

## ✅ 成功标志

如果看到以下输出，说明一切正常：
```
✅ 提取了 20 个真正的Leading Edge基因 (ID类型: SYMBOL)
✅ Leading Edge基因示例: Csf3, Lypd6b, Cxcl3...
✅ 使用SYMBOL基因（显示基因名）: 20 个
```

图上应该显示基因名称（如`Csf3`）而不是数字ID。

## 📞 获取帮助

如果遇到问题：
1. 查看`test_gsea_module.R`的输出
2. 检查R控制台的错误信息
3. 确认所有必要的包已安装
4. 查看本指南的常见问题部分

---

**版本**: 1.0
**更新日期**: 2025-12-26
**作者**: Biofree Development Team
