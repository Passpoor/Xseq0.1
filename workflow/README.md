# BioFastFree Snakemake Workflow

转录组差异分析与功能富集的命令行可复现流程，对应 [BioFastFree](https://github.com/yourusername/BioFastFree) Shiny 应用的分析逻辑。

## 工作流结构

```
workflow/
├── Snakefile              # 主工作流
├── config/
│   └── config.yaml        # 配置文件
├── scripts/               # R 分析脚本
│   ├── 01_differential_analysis.R   # 差异分析 (limma-voom / edgeR)
│   ├── 02_volcano_plot.R            # 火山图
│   ├── 03_kegg_enrichment.R         # KEGG 富集
│   ├── 04_go_enrichment.R           # GO 富集
│   ├── 05_gsea_analysis.R           # GSEA (需 GMT 文件)
│   └── 06_tf_activity.R             # 转录因子活性
├── data/                  # 输入数据
│   ├── counts.csv         # Counts 矩阵
│   ├── design.csv         # 实验设计
│   └── README.md          # 数据格式说明
├── envs/
│   └── environment.yaml   # Conda 环境
└── results/               # 输出目录 (自动创建)
```

## 数据依赖

| 文件 | 说明 |
|------|------|
| `data/counts.csv` | Counts 矩阵，首列=GeneID，其余列=样本 counts |
| `data/design.csv` | 实验设计，含 `sample`, `group` (Control/Treatment) |

详见 `data/README.md`。

## 快速开始

### 1. 安装依赖 (R 包)

在 R 中安装：

```r
if (!require("BiocManager")) install.packages("BiocManager")
BiocManager::install(c("edgeR", "limma", "clusterProfiler", "org.Mm.eg.db", "org.Hs.eg.db", "AnnotationDbi", "enrichplot"))
install.packages(c("dplyr", "ggplot2", "ggrepel", "decoupleR", "tidyr", "tibble"))
```

或使用 Conda：

```bash
conda env create -f envs/environment.yaml
conda activate biofastfree
```

### 2. 安装 Snakemake

```bash
pip install snakemake
# 或 conda install snakemake
```

### 3. 准备数据

- 将 Counts 矩阵保存为 `data/counts.csv`
- 将实验设计保存为 `data/design.csv`（参考 `data/design.csv` 示例）

### 4. 运行工作流

在 `workflow/` 目录下执行：

```bash
cd workflow
snakemake -j 4
```

使用 4 个核心并行运行。首次运行会依次执行：

1. 差异分析 → `results/biofastfree_deg_results.csv`
2. 火山图 → `results/biofastfree_volcano.pdf`
3. KEGG 富集 → `results/biofastfree_kegg_enrichment.csv` + 点图
4. GO 富集 → `results/biofastfree_go_enrichment.csv` + 点图
5. TF 活性 → `results/biofastfree_tf_activity.csv` + 图

### 5. 可选：GSEA

若需 GSEA，需提供 GMT 文件：

1. 在 `config/config.yaml` 中设置 `gsea.gmt_file: "data/your_pathways.gmt"`
2. 运行：`snakemake results/biofastfree_gsea_results.csv`

## 配置说明

编辑 `config/config.yaml` 可修改：

| 参数 | 说明 | 默认 |
|------|------|------|
| `input.counts` | Counts 文件路径 | data/counts.csv |
| `input.design` | 实验设计路径 | data/design.csv |
| `species` | 物种 (Mm/Hs) | Mm |
| `kegg_species` | KEGG 代码 (mmu/hsa) | mmu |
| `differential.pval_cutoff` | P 阈值 | 0.05 |
| `differential.log2fc_cutoff` | log2FC 阈值 | 1.0 |
| `kegg.direction` | 富集方向 (Up/Down/All) | Up |
| `go.ontology` | GO 类型 (BP/MF/CC/ALL) | ALL |
| `tf_activity.method` | TF 算法 (ulm/mlm/wsum/viper) | ulm |

## 输出文件

| 文件 | 说明 |
|------|------|
| `results/biofastfree_deg_results.csv` | 差异分析结果 |
| `results/biofastfree_volcano.pdf` | 火山图 |
| `results/biofastfree_kegg_enrichment.csv` | KEGG 富集表 |
| `results/biofastfree_kegg_dotplot.pdf` | KEGG 点图 |
| `results/biofastfree_go_enrichment.csv` | GO 富集表 |
| `results/biofastfree_go_dotplot.pdf` | GO 点图 |
| `results/biofastfree_tf_activity.csv` | TF 活性表 |
| `results/biofastfree_tf_activity.pdf` | TF 活性图 |
| `results/logs/` | 各步骤日志 |

## 与 Shiny 应用的对应关系

| Snakemake 规则 | BioFastFree Shiny 模块 |
|----------------|------------------------|
| differential_analysis | data_input + differential_analysis |
| volcano_plot | differential_analysis (火山图) |
| kegg_enrichment | kegg_enrichment |
| go_enrichment | go_analysis |
| gsea_analysis | gsea_analysis |
| tf_activity | tf_activity |

## 故障排除

1. **CollecTRI 网络**：TF 活性分析首次运行会下载 CollecTRI 网络，需网络连接。可将 `collectri_mouse.rds` 或 `collectri_human.rds` 置于工作目录复用。
2. **KEGG 富集**：若 `clusterProfiler::enrichKEGG` 失败（如网络限制），可尝试安装 `biofree.qyKEGGtools` 使用本地 KEGG 数据库。
3. **物种注释**：确保已安装对应物种的 org 包：`org.Mm.eg.db` (小鼠) 或 `org.Hs.eg.db` (人类)。

## 许可

与 BioFastFree 主项目保持一致。
