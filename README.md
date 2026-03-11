# YuanSeq

<div align="center">

**An Integrated R/Shiny Platform for RNA-seq, Microarray & Single-Cell Downstream Analysis**

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![R](https://img.shields.io/badge/R-%3E4.0-blue.svg)](https://www.r-project.org/)
[![Platform](https://img.shields.io/badge/Platform-Shiny-green.svg)](https://shiny.posit.co/)

**Developer:** [Yu Qiao (乔宇)](https://github.com/Passpoor) · PhD in Pharmacology · SJTU School of Pharmacy

**Supervisors:** [Prof. Feng Qian](https://pharm.sjtu.edu.cn/szdy/2862.html), [Prof. Lei Sun](https://pharm.sjtu.edu.cn/szdy/2870.html)

*Part of the **Yuanclaw** project at SJTU School of Pharmacy*

</div>

---

## 📖 Overview

**YuanSeq** is a modular, all-in-one bioinformatics analysis platform for comprehensive downstream analysis of bulk RNA-seq, microarray, and **single-cell cluster-derived pseudobulk data**.

### Key Features

| Module | Description | Methods |
|--------|-------------|---------|
| 🔬 **Differential Expression** | RNA-seq / microarray DE analysis | limma-voom, edgeR; 1v1 / nvn comparisons |
| 🧬 **Functional Enrichment** | KEGG, GO, GSEA analysis | clusterProfiler, local KEGG (no rate limit) |
| 🛤️ **Pathway Activity** | Pathway activity inference | ULM, WMEAN, AUCell, GSVA (decoupleR) |
| 🔬 **TF Activity** | Transcription factor activity | CollecTRI network + decoupleR |
| 🆕 **Single-Cell Support** | Downstream analysis for scRNA-seq cluster markers | Use cluster DEGs for enrichment & activity inference |
| 🤖 **AI Interpretation** | AI-powered biological interpretation | DeepSeek, OpenAI, Zhipu AI, Local models |
| 📊 **Visualization** | Interactive plots with sci-fi themed UI | ggplot2, plotly, pheatmap |

---

## 🚀 Installation & Launch

### Quick Start (Recommended)

```r
# Install and launch YuanSeq
if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
remotes::install_github("Passpoor/Yuanseq", upgrade = "never")
YuanSeq::run_app()
```

### Configure AI API (Optional)

```r
# Copy config template
config_dir <- file.path(Sys.getenv("USERPROFILE"), ".yuanseq")  # Windows
# config_dir <- "~/.yuanseq"  # Mac/Linux
dir.create(config_dir, showWarnings = FALSE)
file.copy(system.file("api_config.example.json", package = "YuanSeq"),
          file.path(config_dir, "api_config.json"))
```

Edit `api_config.json` with your API key:

```json
{
  "provider": "deepseek",
  "api_key": "YOUR_API_KEY",
  "model": "deepseek-chat"
}
```

**Supported AI Providers:**

| Provider | `provider` value | Recommended Model |
|----------|------------------|-------------------|
| [DeepSeek](https://www.deepseek.com/) | `deepseek` | deepseek-chat |
| [OpenAI](https://openai.com/) | `openai` | gpt-4o |
| [Zhipu AI](https://www.bigmodel.cn/) | `zhipu` | glm-4-flash |
| [Local Models](https://ollama.com/) | `local` | custom |

> ⚠️ **Data Security**: External API calls send data to third-party servers. For sensitive data, use local models.

---

### Alternative: Local Install

```bash
git clone https://github.com/Passpoor/Yuanseq.git
cd Yuanseq
```

```r
source("install.R")  # Install dependencies
source("run.R")      # Launch app
```

---

## 🤖 AI Interpretation

YuanSeq integrates AI-powered biological interpretation:

- **Context-aware analysis** based on sample metadata (organism, tissue, treatment)
- **Multi-format export**: Markdown, HTML (with embedded figures), PDF
- **Real-time progress indicator**
- **Conversation history tracking**

---

## 🆕 Single-Cell Downstream Analysis

YuanSeq supports downstream analysis of **single-cell RNA-seq data**:

- Import cluster marker genes from Seurat, Scanpy, or other scRNA-seq tools
- Perform KEGG/GO/GSEA enrichment on cluster-specific DEGs
- Infer pathway and TF activity for each cell cluster
- Compare biological programs across cell subpopulations

---

## 🙏 Acknowledgments

YuanSeq integrates and acknowledges the following open-source projects:

| Category | Packages | Use |
|----------|----------|-----|
| **Framework** | [shiny](https://cran.r-project.org/package=shiny), [shinyjs](https://cran.r-project.org/package=shinyjs), [bslib](https://cran.r-project.org/package=bslib), [DT](https://cran.r-project.org/package=DT), [plotly](https://cran.r-project.org/package=plotly) | App framework & UI |
| **DE Analysis** | [edgeR](https://bioconductor.org/packages/edgeR/), [limma](https://bioconductor.org/packages/limma/) | Differential expression |
| **Enrichment** | [clusterProfiler](https://bioconductor.org/packages/clusterProfiler/), [enrichplot](https://bioconductor.org/packages/enrichplot/), [GseaVis](https://bioconductor.org/packages/GseaVis/) | GO/KEGG/GSEA |
| **Local KEGG** | [biofree.qyKEGGtools](https://github.com/Passpoor/biofree.qyKEGGtools) | Offline KEGG enrichment |
| **Activity** | [decoupleR](https://bioconductor.org/packages/decoupleR/) | Pathway/TF activity |
| **Visualization** | [ggplot2](https://cran.r-project.org/package=ggplot2), [pheatmap](https://cran.r-project.org/package=pheatmap), [ggrepel](https://cran.r-project.org/package=ggrepel) | Plotting |
| **AI** | [httr](https://cran.r-project.org/package=httr), [jsonlite](https://cran.r-project.org/package=jsonlite) | API calls |

Thanks to R, Bioconductor, and all package developers!

---

## 📁 Project Structure

```
Yuanseq/
├── app.R                      # Main entry
├── api_config.example.json    # API config template
├── modules/
│   ├── ui_theme.R             # Theme & layout
│   ├── data_input.R           # Data upload
│   ├── differential_analysis.R
│   ├── kegg_enrichment.R
│   ├── gsea_analysis.R
│   ├── pathway_activity.R
│   ├── tf_activity.R
│   ├── ai_interpretation.R    # AI interpretation
│   └── venn_diagram.R
├── R/                         # Package functions
├── inst/shiny/                # Packaged Shiny app
└── config/                    # Configuration
```

---

## 📄 License

[MIT License](LICENSE)
