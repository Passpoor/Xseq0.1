# UI 增强系统使用文档

## 📋 目录

1. [快速开始](#快速开始)
2. [核心功能](#核心功能)
3. [组件库](#组件库)
4. [动画效果](#动画效果)
5. [响应式设计](#响应式设计)
6. [最佳实践](#最佳实践)
7. [API参考](#api参考)

---

## 🚀 快速开始

### 1. 安装与引入

在你的 `app.R` 或 `ui.R` 文件顶部添加:

```r
# 加载UI增强模块
source("modules/ui_enhancements.R")

# 在UI中添加资源
ui <- fluidPage(
  # 添加所有CSS和JS资源
  addUIEnhancements(),

  # 你的其他UI代码...
)
```

### 2. 基础示例

```r
# 在server.R中使用
server <- function(input, output, session) {
  # 显示Toast通知
  observeEvent(input$analyzeButton, {
    toastInfo(session, "分析开始", "正在处理数据...")

    # 模拟分析完成
    setTimeout(function() {
      toastSuccess(session, "分析完成!", "发现1,234个差异基因")
    }, 2000)
  })
}
```

---

## 🎯 核心功能

### Toast 通知系统

#### 显示不同类型的消息

```r
# 成功消息
toastSuccess(session, message = "操作成功!", title = "完成")

# 错误消息
toastError(session, message = "上传失败", title = "错误")

# 警告消息
toastWarning(session, message = "检测到缺失值", title = "注意")

# 信息消息
toastInfo(session, message = "正在保存...", title = "提示")
```

#### 自定义Toast

```r
showToast(
  session,
  type = "success",
  title = "导出完成",
  message = "文件已保存到 downloads 文件夹",
  duration = 5000,  # 5秒后自动关闭
  actions = list(
    list(id = "view", label = "查看", primary = TRUE),
    list(id = "dismiss", label = "关闭")
  )
)
```

#### 带操作按钮的Toast

```r
showToast(
  session,
  type = "warning",
  title = "数据版本提示",
  message = "当前使用的注释数据库可能不是最新版本",
  actions = list(
    list(id = "update", label = "立即更新", primary = TRUE),
    list(id = "later", label = "稍后提醒")
  )
)

# 在server中处理按钮点击
observeEvent(input$toast_action, {
  if (input$toast_action == "update") {
    # 执行更新操作
  }
})
```

### 骨架屏加载状态

#### 显示卡片加载

```r
# 显示骨架屏
showSkeleton(session, selector = "#results-card", type = "card")

# 数据加载完成后隐藏
observeEvent(input$data_loaded, {
  hideSkeleton(session, selector = "#results-card")
})
```

#### 显示表格加载

```r
# 表格骨架屏
showSkeleton(
  session,
  selector = "#gene-table",
  type = "table",
  options = list(rows = 10, columns = 5)
)
```

#### 显示图表加载

```r
# 图表骨架屏
showSkeleton(
  session,
  selector = "#volcano-plot",
  type = "chart",
  options = list(type = "bar")
)
```

---

## 🧩 组件库

### 增强按钮

```r
# 基础按钮
enhancedButton("btn1", "点击我", type = "primary")

# 带图标的按钮
enhancedButton(
  "btn2",
  "开始分析",
  icon = icon("rocket"),
  type = "success"
)

# 不同尺寸
enhancedButton("btn3", "小按钮", size = "sm", type = "primary")
enhancedButton("btn4", "大按钮", size = "lg", type = "primary")

# 带加载状态
enhancedButton(
  "btn5",
  "提交中...",
  type = "primary",
  loading = TRUE
)

# 在server中切换加载状态
observeEvent(input$btn5, {
  setButtonLoading(session, "btn5", loading = TRUE)

  # 执行操作...

  setButtonLoading(session, "btn5", loading = FALSE)
})
```

### 增强输入框

```r
# 基础输入框
enhancedInput(
  inputId = "username",
  label = "用户名",
  placeholder = "请输入用户名",
  required = TRUE
)

# 带帮助文本
enhancedInput(
  inputId = "email",
  label = "邮箱地址",
  placeholder = "your@email.com",
  helpText = "我们将发送确认邮件到此地址",
  required = TRUE
)

# 不同尺寸
enhancedInput(
  inputId = "search",
  label = "搜索",
  placeholder = "输入关键词...",
  size = "lg"
)
```

### 统计卡片

```r
# 基础卡片
statCard(
  title = "差异基因数",
  value = "1,234",
  subtitle = "↑ 12.5% vs 上次",
  icon = "📈",
  iconType = "primary"
)

# 不同图标类型
statCard("上调", "678", "+55%", "⬆️", "success")
statCard("下调", "556", "-45%", "⬇️", "error")
statCard("警告", "3", "需要注意", "⚠️", "warning")

# 可点击的卡片
statCard(
  title = "KEGG通路",
  value = "45",
  subtitle = "点击查看详情",
  icon = "🧬",
  iconType = "primary",
  href = "#kegg-results"
)
```

### 可折叠面板

```r
# 基础面板
collapsiblePanel(
  inputId = "panel1",
  title = "高级参数",
  content = div(
    numericInput("param1", "参数1", 10),
    numericInput("param2", "参数2", 0.05)
  ),
  expanded = FALSE
)

# 带图标的面板
collapsiblePanel(
  inputId = "panel2",
  title = "分析选项",
  content = "面板内容...",
  icon = "⚙️",
  expanded = TRUE
)

# 嵌套面板
collapsiblePanel(
  inputId = "panel3",
  title = "质量控制",
  content = div(
    collapsiblePanel("qc1", "样本QC", "内容..."),
    collapsiblePanel("qc2", "基因QC", "内容...")
  )
)
```

### 进度条

```r
# 基础进度条
enhancedProgress(
  inputId = "progress1",
  value = 65,
  status = "primary",
  showLabel = TRUE
)

# 不同状态
enhancedProgress("progress2", 80, status = "success")
enhancedProgress("progress3", 45, status = "warning")
enhancedProgress("progress4", 20, status = "error")

# 更新进度条
observe({
  # 假设有个进度值
  progress <- calculateProgress()
  updateProgress(session, "progress1", progress)
})
```

### 文件上传

```r
# 基础文件上传
enhancedFileInput(
  inputId = "datafile",
  label = "拖拽文件到此处 或 点击上传",
  accept = ".csv,.csv.gz,.txt",
  maxSize = 100
)

# 多文件上传
enhancedFileInput(
  inputId = "files",
  label = "上传多个数据文件",
  accept = ".csv",
  multiple = TRUE
)
```

### 徽章

```r
# 基础徽章
badge("新功能", type = "primary")
badge("成功", type = "success")
badge("警告", type = "warning")
badge("错误", type = "error")

# 在文本中使用
tags$span(
  "差异基因数 ",
  badge("1,234", type = "primary")
)

# 圆点徽章
badge("", type = "success", dot = TRUE)
```

---

## 🎨 动画效果

### 淡入淡出

```r
# 添加CSS类
tags$div(
  class = "fade-in",
  "内容会淡入显示"
)

# 带方向
tags$div(class = "fade-in-up", "从下方淡入")
tags$div(class = "fade-in-down", "从上方淡入")
tags$div(class = "fade-in-left", "从左侧淡入")
tags$div(class = "fade-in-right", "从右侧淡入")
```

### 悬停效果

```r
# 悬停提升
tags$div(
  class = "card hover-lift",
  "鼠标悬停时卡片会提升"
)

# 悬停放大
tags$button(
  class = "btn hover-scale",
  "鼠标悬停时会放大"
)

# 悬停发光
tags$div(
  class = "hover-glow",
  "悬停时会产生发光效果"
)
```

### 加载动画

```r
# 旋转加载器
tags$div(class = "spinner", "加载中...")

# 点状加载器
tags$div(
  class = "dots-loading",
  tags$span(),
  tags$span(),
  tags$span()
)

# 条形加载器
tags$div(
  class = "bar-loading",
  tags$span(),
  tags$span(),
  tags$span(),
  tags$span(),
  tags$span()
)
```

### 特殊效果

```r
# 脉冲效果
tags$div(class = "pulse", "持续闪烁")

# 弹跳进入
tags$div(class = "bounce-in", "弹跳进入")

# 漂浮动画
tags$div(class = "float", "上下漂浮")

# 心跳
tags$div(class = "heartbeat", "心跳效果")
```

---

## 📱 响应式设计

### 网格系统

```r
# 响应式列布局
fluidRow(
  # 移动端:1列, 平板:2列, 桌面:3列
  column(
    c(12, 6, 4),  # xs=12, md=6, lg=4
    statCard("标题1", "数值1", "副标题1", "📊")
  ),
  column(
    c(12, 6, 4),
    statCard("标题2", "数值2", "副标题2", "📈")
  ),
  column(
    c(12, 6, 4),
    statCard("标题3", "数值3", "副标题3", "📉")
  )
)

# 使用预定义的列类
fluidRow(
  column(4, div(class = "col-xs-12 col-md-4", "内容"))
)
```

### 隐藏/显示元素

```r
# 在特定屏幕尺寸隐藏
tags$div(
  class = "hide-xs hide-sm",  # 仅在平板和桌面显示
  "这段内容不在手机上显示"
)

tags$div(
  class = "hide-md hide-lg",  # 仅在移动端显示
  "这段内容仅在手机上显示"
)
```

### 移动端优化

```r
# 触摸友好的按钮
enhancedButton(
  "mobileBtn",
  "点击我",
  class = "mobile-full-width"  # 移动端全宽
)

# 移动端堆叠布局
fluidRow(
  class = "row-mobile-stack",  # 移动端自动堆叠
  column(6, "左侧内容"),
  column(6, "右侧内容")
)
```

---

## 💡 最佳实践

### 1. 使用骨架屏提升加载体验

```r
# ❌ 不好: 只显示"加载中..."
h4("加载中...")

# ✅ 好: 显示骨架屏,让用户知道内容即将出现
showSkeleton(session, "#content-area", type = "card")
```

### 2. 使用Toast提供反馈

```r
# ❌ 不好: 使用alert阻断用户
alert("分析完成!")

# ✅ 好: 使用Toast非阻塞提示
toastSuccess(session, "分析完成!", "发现1,234个差异基因")
```

### 3. 合理使用动画

```r
# ❌ 不好: 过多动画干扰用户
tags$div(class = "pulse heartbeat float", "重要通知")

# ✅ 好: 微妙的动画引导注意
tags$div(class = "fade-in", "新内容")
```

### 4. 响应式优先

```r
# ❌ 不好: 固定宽度
tags$div(style = "width: 1200px;", "内容")

# ✅ 好: 响应式宽度
fluidRow(
  column(12,
    class = "container",
    "内容"
  )
)
```

### 5. 可访问性考虑

```r
# ✅ 为所有交互元素添加标签
enhancedInput(
  inputId = "email",
  label = "邮箱地址",  # 清晰的标签
  helpText = "请输入有效的邮箱地址"  # 额外帮助
)

# ✅ 使用语义化HTML
tags$button(
  type = "button",
  `aria-label` = "关闭对话框",
  icon("times")
)
```

---

## 📚 API参考

### Toast函数

| 函数 | 说明 |
|------|------|
| `showToast(session, type, title, message, duration, actions)` | 显示自定义Toast |
| `toastSuccess(session, message, title)` | 显示成功消息 |
| `toastError(session, message, title)` | 显示错误消息 |
| `toastWarning(session, message, title)` | 显示警告消息 |
| `toastInfo(session, message, title)` | 显示信息消息 |
| `toastClear(session)` | 清除所有Toast |

### 骨架屏函数

| 函数 | 说明 |
|------|------|
| `showSkeleton(session, selector, type, options)` | 显示骨架屏 |
| `hideSkeleton(session, selector)` | 隐藏骨架屏 |

### 组件函数

| 函数 | 说明 |
|------|------|
| `enhancedButton(inputId, label, ...)` | 创建增强按钮 |
| `enhancedInput(inputId, label, ...)` | 创建增强输入框 |
| `statCard(title, value, ...)` | 创建统计卡片 |
| `enhancedCard(title, content, ...)` | 创建增强卡片 |
| `collapsiblePanel(inputId, title, ...)` | 创建可折叠面板 |
| `enhancedProgress(inputId, value, ...)` | 创建进度条 |
| `enhancedFileInput(inputId, label, ...)` | 创建文件上传 |
| `badge(text, type, ...)` | 创建徽章 |

### 工具函数

| 函数 | 说明 |
|------|------|
| `updateProgress(session, inputId, value)` | 更新进度条 |
| `setButtonLoading(session, inputId, loading)` | 设置按钮加载状态 |
| `toggleDarkMode(session, enabled)` | 切换深色模式 |

---

## 🔧 自定义配置

### 修改主题颜色

在你的自定义CSS中覆盖变量:

```css
:root {
  /* 修改主色调 */
  --color-primary: #FF6B6B;
  --color-success: #51CF66;
  --color-error: #FF6B6B;

  /* 修改间距 */
  --spacing-lg: 20px;
  --spacing-xl: 28px;

  /* 修改圆角 */
  --radius-md: 10px;
  --radius-lg: 16px;
}
```

### 自定义动画速度

```css
:root {
  --duration-fast: 100ms;    /* 默认150ms */
  --duration-normal: 300ms;  /* 默认200ms */
  --duration-slow: 500ms;    /* 默认300ms */
}
```

---

## 🐛 常见问题

### Q: Toast不显示?

A: 确保已经调用 `addUIEnhancements()` 并检查浏览器控制台是否有错误。

### Q: 骨架屏不消失?

A: 确保选择器正确且调用了 `hideSkeleton()`。

### Q: 移动端样式混乱?

A: 检查是否引入了 `responsive.css` 并使用响应式网格系统。

### Q: 深色模式不工作?

A: 确保在body元素上添加了 `dark-mode` 类。

---

## 📞 支持

如有问题或建议,请联系：xseq_fastfreee@163.com

---

## 📄 许可证

本UI增强系统是 Biofree 项目的一部分。
