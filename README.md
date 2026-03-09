# Xseq

Xseq is a web-based R/Shiny platform for comprehensive bioinformatics analysis of RNA-seq and microarray data, offering differential expression analysis, functional enrichment (KEGG/GO/GSEA), transcription factor and pathway activity inference, and interactive visualization.

**Repository:** [https://github.com/Passpoor/Xseq0.1](https://github.com/Passpoor/Xseq0.1)

---

## 项目概述 | About

Xseq（原 BioFastFree）是模块化的生物信息学分析平台，基于 Shiny 开发，提供从差异表达、富集分析到通路活性推断的完整流程，支持科幻主题 UI 与日夜模式切换。

---

## 功能特性 | Features

### 核心功能
- **差异表达分析**: limma-voom、edgeR；支持 1v1 / nvn 比较
- **富集分析**: KEGG（含本地/背景基因）、GO、GSEA（含 Leading Edge 与 GPSAdb 延伸提示）
- **通路活性推断**: ULM/WMEAN/AUCell/GSVA（decoupleR），基于 KEGG 富集结果
- **转录因子活性**: CollecTRI 网络与 decoupleR
- **韦恩图、火山图**: 多组交集、多种差异结果格式

### 界面与扩展
- 科幻主题、玻璃拟态、响应式布局
- GSEA 模块内提示可配合 [GPSAdb](https://www.gpsadb.com/) fastGPSA 做延伸分析

---

## 安装与运行 | Install & Run

### 要求
- R >= 4.0
- 需安装 Shiny、BiocManager 及以下依赖

### 1. 克隆仓库
```bash
git clone https://github.com/Passpoor/Xseq0.1.git
cd Xseq0.1
```

### 2. 安装 R 包
在 R 中执行：
```r
install.packages(c("shiny", "shinyjs", "bslib", "ggplot2", "dplyr", "DT",
  "pheatmap", "plotly", "colourpicker", "shinyWidgets", "rlang",
  "edgeR", "limma", "AnnotationDbi", "clusterProfiler", "decoupleR",
  "tibble", "tidyr", "ggrepel", "RColorBrewer", "VennDiagram", "grid", "gridExtra"))

if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install(c("org.Mm.eg.db", "org.Hs.eg.db", "GseaVis", "enrichplot"))

# KEGG 本地富集（可选，推荐从 GitHub 安装）
remotes::install_github("Passpoor/biofree.qyKEGGtools", upgrade = "never")
```

### 3. 启动应用
```r
shiny::runApp("app.R")
```
或使用项目内脚本：`launch_app.R`、`run_app.bat` / `run_app.sh`。

---

## 项目结构 | Structure

```
├── app.R                 # 主入口
├── config/               # 配置
├── modules/              # Shiny 模块
│   ├── ui_theme.R        # 主题与布局
│   ├── data_input.R      # 数据上传与注释
│   ├── differential_analysis.R
│   ├── kegg_enrichment.R
│   ├── gsea_analysis.R
│   ├── pathway_activity.R # 通路活性推断
│   ├── tf_activity.R
│   └── venn_diagram.R
├── workflow/             # 工作流脚本
├── tests/                # 测试
└── docs/                 # 文档
```

---

## 许可证 | License

MIT License. See [LICENSE](LICENSE) for details.
