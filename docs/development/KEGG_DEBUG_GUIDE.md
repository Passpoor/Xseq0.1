# 🔍 KEGG "参数长度为零" 错误调试指南

**错误信息**："参数长度为零"
**更新时间**：2025-01-02
**状态**：已增强调试和错误处理

---

## 🔧 已添加的调试功能

### 1. 参数验证（第754-763行）

```r
# 验证必需的输入参数
if (is.null(input$single_gene_species) || input$single_gene_species == "") {
  showNotification("错误：请选择物种", type = "error")
  return(NULL)
}

if (is.null(input$single_gene_kegg_p) || input$single_gene_kegg_p == "") {
  showNotification("错误：请设置P值阈值", type = "error")
  return(NULL)
}
```

**效果**：
- ✅ 提前发现NULL或空参数
- ✅ 显示友好的错误消息
- ✅ 避免模糊的"参数长度为零"错误

---

### 2. 详细日志输出（第737-752行）

```r
cat("🔧 单列基因KEGG富集分析...\n")
cat(sprintf("📊 输入基因数量: %d\n", length(entrez_ids)))
cat(sprintf("📊 物种: %s\n", input$single_gene_species))
cat(sprintf("📊 P值阈值: %s\n", input$single_gene_kegg_p))
cat(sprintf("📊 背景基因数量: %s\n",
    ifelse(is.null(universe), "NULL (使用全基因组)", length(universe))))
```

**显示**：
- 输入基因数量
- 物种
- P值阈值
- 背景基因数量

---

### 3. 调试模式（第745-752行）

启用调试模式：
```r
Sys.setenv(SHINY_DEBUG = "TRUE")
```

**显示额外信息**：
- `entrez_ids` 类别
- `entrez_ids` 长度
- 前5个基因示例
- 所有输入参数值

---

### 4. 增强的错误处理（第795-804行）

```r
}, error = function(e) {
  cat(sprintf("❌ enrich_local_KEGG_v2失败: %s\n", e$message))
  cat(sprintf("   错误类型: %s\n", class(e)[1]))
  cat(sprintf("   当前参数:\n"))
  cat(sprintf("     - 基因数量: %d\n", length(entrez_ids)))
  cat(sprintf("     - 物种: %s\n", input$single_gene_species))
  cat(sprintf("     - P值: %s\n", input$single_gene_kegg_p))
  showNotification(sprintf("KEGG分析失败: %s", e$message), type = "error", duration = 15)
  NULL
})
```

**显示**：
- 详细的错误消息
- 错误类型
- 所有相关参数的值
- 持续时间15秒的通知

---

## 🐛 可能的问题和解决方案

### 问题 1：物种参数为 NULL

**症状**：
```
📊 物种: NULL
```

**原因**：用户没有选择物种

**解决**：
- 现在会显示："错误：请选择物种"
- 不会继续执行，避免崩溃

---

### 问题 2：P值阈值为 NULL

**症状**：
```
📊 P值阈值: NULL
```

**原因**：用户没有设置P值阈值

**解决**：
- 现在会显示："错误：请设置P值阈值"
- 不会继续执行，避免崩溃

---

### 问题 3：基因列表为空

**症状**：
```
📊 输入基因数量: 0
```

**原因**：基因转换失败

**解决**：
- 现在会显示："错误：没有有效的 ENTREZID 进行KEGG分析"
- 不会继续执行，避免崩溃

---

### 问题 4：输入参数类型错误

**症状**：
```
❌ enrich_local_KEGG_v2失败: ...
   错误类型: simpleError / error
   当前参数:
     - 基因数量: 440
     - 物种: mmu
     - P值: 0.05
```

**可能原因**：
- `input$single_gene_kegg_p` 是字符串而不是数值
- `input$single_gene_species` 包含空格或特殊字符

**解决**：
检查UI定义，确保：
```r
# 正确
numericInput("single_gene_kegg_p", "P值阈值", value = 0.05, min = 0.001, max = 1)

# 错误
textInput("single_gene_kegg_p", "P值阈值", value = "0.05")  # 字符串！
```

---

## 🧪 启用调试模式

### 方法 1：在 R 控制台中设置

```r
Sys.setenv(SHINY_DEBUG = "TRUE")
source("launch_app.R")
```

### 方法 2：在 launch_app.R 中设置

```r
# 在 launch_app.R 开头添加
Sys.setenv(SHINY_DEBUG = "TRUE")
```

### 方法 3：临时启用

```r
# 运行应用
shiny::runApp("app.R")

# 在另一个 R 会话中
Sys.setenv(SHINY_DEBUG = "TRUE")
```

---

## 📊 调试输出示例

### 正常情况

```
🔧 单列基因KEGG富集分析...
📊 输入基因数量: 440
📊 物种: mmu
📊 P值阈值: 0.05
📊 背景基因数量: NULL (使用全基因组)

🔍 调试信息：
  entrez_ids 类别: character
  entrez_ids 长度: 440
  前5个基因: 22059, 17869, 13656, 12056, 12476
  input$single_gene_species: mmu
  input$single_gene_kegg_p: 0.05

✅ 使用 enrich_local_KEGG_v2（支持universe参数）
🔍 调用 enrich_local_KEGG_v2...
✅ enrich_local_KEGG_v2成功！找到 50 个显著通路
```

### 错误情况

```
🔧 单列基因KEGG富集分析...
📊 输入基因数量: 0
❌ 错误：没有有效的 ENTREZID 进行KEGG分析
```

或者

```
🔧 单列基因KEGG富集分析...
📊 输入基因数量: 440
📊 物种: NULL
❌ 错误：请选择物种
```

---

## ✅ 修改总结

### 修改的文件

**文件**：`modules/kegg_enrichment.R`

**修改位置**：
1. **第731-735行**：基因数量检查
2. **第737-752行**：详细日志输出
3. **第754-763行**：参数验证
4. **第787行**：调用前日志
5. **第795-804行**：增强错误处理

**总计**：
- 新增代码：约30行
- 修改代码：约10行
- 删除代码：0行

---

## 🎯 下一步调试步骤

### 1. 重启应用

```r
# 启用调试模式
Sys.setenv(SHINY_DEBUG = "TRUE")

# 重启应用
setwd("D:/cherry_code/Biofree_project11.2/Biofree_project")
source("launch_app.R")
```

### 2. 重新运行分析

- 输入基因列表
- 选择物种
- 设置P值
- 点击运行

### 3. 查看控制台输出

您应该看到：
```
🔧 单列基因KEGG富集分析...
📊 输入基因数量: 440
📊 物种: mmu
📊 P值阈值: 0.05
...
```

### 4. 查看详细调试信息

如果启用了 `SHINY_DEBUG`，您会看到：
```
🔍 调试信息：
  entrez_ids 类别: character
  entrez_ids 长度: 440
  前5个基因: 22059, 17869, 13656, 12056, 12476
  input$single_gene_species: mmu
  input$single_gene_kegg_p: 0.05
```

### 5. 如果仍然出错

复制完整的错误消息，包括：
- 所有 📊 开头的参数信息
- 🔍 调试信息（如果启用）
- ❌ 错误消息
- 错误类型

---

## 📝 报告问题时请包含

1. **完整的控制台输出**
2. **输入的基因列表**（前10个基因）
3. **选择的物种**
4. **P值阈值设置**
5. **是否使用背景基因集**
6. **错误消息的完整文本**

这样我可以准确定位问题！

---

**更新完成**：2025-01-02
**状态**：✅ 已增强调试功能
**建议**：启用调试模式，重新运行分析，查看详细输出
