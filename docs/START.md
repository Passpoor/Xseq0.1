# BioFastFree v12.5 - 快速启动

> **生物信息学分析平台** | 基于 R Shiny

---

## 🚀 快速开始

### 运行应用

**Windows**:
```bash
launch_app.bat
```

**Linux/Mac**:
```bash
bash run_app.sh
```

**或在 R 中**:
```r
shiny::runApp("app.R")
```

### 访问应用

- **地址**: http://127.0.0.1:8080
- **账号**: admin
- **密码**: 1234

---

## 📚 完整文档

所有文档都在 `docs/` 文件夹中：

- **用户文档**: [docs/user_guide/](docs/user_guide/)
  - [完整用户手册](docs/user_guide/USER_MANUAL_COMPLETE.md) ⭐
  - [项目说明](docs/user_guide/PROJECT_MAIN_README.md)

- **开发文档**: [docs/development/](docs/development/)
  - [Bug修复总结](docs/development/BUG_SUMMARY_COMPLETE.md) ⭐
  - [KEGG调试指南](docs/development/KEGG_DEBUG_GUIDE.md)

- **文档索引**: [docs/INDEX.md](docs/INDEX.md)

---

## ✨ 核心功能

- 差异表达分析（limma-voom & edgeR）
- KEGG/GO 富集分析
- GSEA 分析
- 转录因子活性推断
- 韦恩图分析
- 多文件背景基因集（v12.5 最新功能）

---

## 🔧 常见问题

**数据库锁定?**
```r
source("scripts/cleanup/cleanup_r_locks.R")
```

**更多帮助**: 查看 [docs/INDEX.md](docs/INDEX.md)

---

**版本**: v12.5 | **更新**: 2025-01-04
