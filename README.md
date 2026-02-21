# Xseq - Bioinformatics Analysis Platform

> A comprehensive web-based platform for RNA-seq and microarray analysis with AI-powered interpretation.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-%3E%3D4.0-blue.svg)](https://www.r-project.org/)

## Features

- **RNA-seq Analysis**: Differential expression analysis using limma-voom/edgeR
- **Microarray Analysis**: Support for GEO SOFT format and various platforms
- **Functional Enrichment**: KEGG, GO, and GSEA analysis
- **TF Activity**: Transcription factor activity inference using decoupleR
- **Pathway Activity**: Pathway activity scoring and visualization
- **AI Integration**: Intelligent result interpretation powered by AI
- **Interactive Visualization**: Volcano plots, heatmaps, and more

## Installation

### Quick Install (Recommended)

Run this command in R/RStudio:

```r
source("https://raw.githubusercontent.com/Passpoor/Xseq/main/install.R")
```

### Manual Install

```bash
# Clone the repository
git clone https://github.com/Passpoor/Xseq.git

# Run the application
cd Xseq
Rscript -e "shiny::runApp('app.R')"
```

## Activation

Xseq requires activation before use:

1. **Launch the application** - Your machine code will be displayed
2. **Send machine code** to: xseq_fastfreee@163.com
3. **Include in email**:
   - Your name
   - Institution/University
   - License type (Trial/Monthly/Yearly)
4. **Wait for activation** (usually within 24 hours)
5. **Click "Check Status"** to verify activation

## License Types

| Type | Duration | Usage |
|------|----------|-------|
| Trial | 7 days | 10 uses |
| Monthly | 30 days | Unlimited |
| Yearly | 365 days | Unlimited |

## Requirements

- R >= 4.0
- RStudio (recommended)

### R Packages

The installer will automatically install required packages:
- shiny, shinydashboard, DT, ggplot2, plotly
- limma, edgeR, clusterProfiler
- org.Hs.eg.db, org.Mm.eg.db

## Screenshots

![Xseq Interface](images/screenshot.png)

## Contact

- Email: xseq_fastfreee@163.com
- GitHub: [https://github.com/Passpoor/Xseq](https://github.com/Passpoor/Xseq)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use Xseq in your research, please cite:

```
Xseq: A web-based platform for bioinformatics analysis
文献计量与基础医学
https://github.com/Passpoor/Xseq
```

---

Made with by 文献计量与基础医学
