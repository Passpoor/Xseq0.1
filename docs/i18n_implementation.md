# Biofree 国际化 (i18n) 实现文档

## 概述

已为 Biofree 项目添加了中英文双语支持。用户可以通过界面上的语言切换器在中文和英文之间切换。

## 文件结构

### 新增文件

1. **`modules/i18n.R`** - 核心国际化模块
   - 包含所有中英文翻译
   - 提供翻译函数 `t_()` 和 `make_translator()`
   - 支持响应式语言切换

2. **`test_i18n.R`** - 国际化测试应用
   - 用于测试翻译功能
   - 简单的界面演示语言切换

3. **`test_i18n_launch.R`** - 测试应用启动脚本

### 修改文件

1. **`app.R`**
   - 加载国际化模块
   - 添加语言状态管理
   - 添加语言切换监听器

2. **`modules/ui_theme.R`**
   - 在导航栏添加语言切换器
   - 在登录界面添加语言切换器

## 使用方法

### 1. 测试国际化功能

运行测试应用：
```r
source("test_i18n_launch.R")
```

或者在 R 控制台中：
```r
setwd("D:/cherry_code/Biofree_project11.2/Biofree_project")
shiny::runApp("test_i18n.R", port = 3839)
```

### 2. 在主应用中使用

启动主应用：
```r
source("launch_app.R")
```

语言切换器位置：
- **登录界面**: 右上角
- **主应用界面**: 导航栏标题右侧

## 翻译键 (Translation Keys)

当前已实现的翻译键包括：

### 登录界面
- `login_title` - 应用标题
- `login_username` - 用户名
- `login_password` - 密码
- `login_button` - 登录按钮
- `login_welcome` - 欢迎信息
- `login_info` - 平台介绍
- `login_features_title` - 功能标题
- `login_feature_1/2/3/4` - 各项功能
- `login_developer_title` - 开发者标题
- `login_developer_name` - 开发者姓名
- `login_developer_role` - 开发者角色

### 导航栏
- `nav_data_input` - 数据输入
- `nav_deg` - 差异分析
- `nav_kegg` - KEGG分析
- `nav_go` - GO分析
- `nav_gsea` - GSEA分析
- `nav_tf` - 转录因子
- `nav_pathway` - 通路活性
- `nav_chip` - 芯片数据
- `nav_venn` - 韦恩图
- `nav_settings` - 设置
- `nav_language` - 语言

### 通用
- `common_submit` - 提交
- `common_reset` - 重置
- `common_download` - 下载
- `common_back` - 返回
- `common_next` - 下一步
- `common_processing` - 处理中
- `common_complete` - 完成
- `common_error` - 错误
- `common_warning` - 警告
- `common_success` - 成功

## 如何添加新的翻译

### 1. 在 `modules/i18n.R` 中添加翻译键

编辑 `translations` 列表：

```r
translations <- list(
  zh = list(
    my_new_text = "新的中文文本"
  ),
  en = list(
    my_new_text = "New English Text"
  )
)
```

### 2. 在UI中使用翻译

使用响应式翻译函数：

```r
# 在server函数中
translator <- reactive({
  make_translator(current_language)
})

# 在renderUI或输出中使用
output$my_output <- renderUI({
  t <- translator()()
  h3(t("my_new_text"))
})
```

或在模块中传递翻译函数：

```r
# 模块函数定义
my_module_server <- function(input, output, session, translator_func) {
  output$text <- renderUI({
    h3(translator_func()("my_new_text"))
  })
}
```

## 当前实现状态

### ✅ 已完成
- [x] 创建翻译配置文件
- [x] 添加语言切换器UI
- [x] 实现语言切换逻辑
- [x] 创建测试应用
- [x] 核心翻译键定义

### ⏳ 待完成 (需要根据实际需求)
- [ ] 更新登录界面使用翻译
- [ ] 更新主应用所有文本使用翻译
- [ ] 更新各个功能模块使用翻译
- [ ] 添加更多翻译键
- [ ] 测试所有功能模块

## 技术实现细节

### 翻译函数

1. **`t_(key, lang)`** - 静态翻译函数
   ```r
   text <- t_("login_title", "zh")  # 返回 "Biofree 生物信息学分析平台"
   ```

2. **`make_translator(language_input)`** - 响应式翻译工厂
   ```r
   translator <- make_translator(current_language)
   t <- translator()  # 返回绑定了当前语言的翻译函数
   text <- t("login_title")
   ```

### 响应式更新

使用 Shiny 的 `reactiveVal` 和 `observeEvent` 实现动态语言切换：

```r
# 初始化语言
current_language <- reactiveVal("zh")

# 监听切换
observeEvent(input$language_switcher, {
  current_language(input$language_switcher)
})

# 自动更新UI
output$content <- renderUI({
  translator()()("my_key")  # 当语言改变时自动重新渲染
})
```

## 注意事项

1. **默认语言**: 应用默认使用中文 (`zh`)
2. **语言代码**: 使用 ISO 639-1 标准语言代码
   - `zh` - 中文
   - `en` - 英文
3. **缺失翻译**: 如果某个键在当前语言中不存在,会返回键名本身
4. **性能**: 翻译函数很轻量,不会影响性能

## 下一步建议

1. **渐进式翻译**: 不要一次性翻译所有内容,建议按模块逐步进行
2. **优先级**: 先翻译用户最常接触的界面(导航、表单、按钮)
3. **测试**: 每翻译一个模块后都要测试两种语言下的显示效果
4. **一致性**: 保持术语翻译的一致性,可以创建术语表
5. **专业翻译**: 对于专业术语,建议请专业人士审核翻译

## 联系与支持

如有问题或建议,请联系：xseq_fastfreee@163.com

---

**最后更新**: 2026-01-09
**版本**: v12.5 i18n
