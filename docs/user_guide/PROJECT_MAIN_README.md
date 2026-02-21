# BioFastFree v11.2

> **增强模块化的生物信息学分析平台**
> 基于R Shiny的转录组数据分析工具

---

## 🚀 快速开始

### 安装

```bash
# 克隆项目
git clone https://github.com/your-repo/Biofree_project.git
cd Biofree_project

# 安装R依赖（在R中运行）
source("install_packages.R")
```

### 运行

```bash
# Windows
launch_app.bat

# Linux/Mac
bash run_app.sh

# 或在R中
shiny::runApp("app.R")
```

### 访问

- **默认地址**: http://127.0.0.1:8080
- **账号**: admin
- **密码**: 1234

---

## 📚 文档导航

### 👤 用户文档

**完整用户手册**: [docs/user_guide/USER_MANUAL_COMPLETE.md](docs/user_guide/USER_MANUAL_COMPLETE.md)

包含：
- 项目简介和快速开始
- 核心功能详解（差异分析、富集分析、GSEA、韦恩图、转录因子）
- 高级功能（多文件背景基因集、基因助手）
- **富集分析最佳实践** ⭐
- 常见问题解答
- 故障排除指南

### 👨‍💻 开发文档

**Bug修复总结**: [docs/development/BUG_SUMMARY_COMPLETE.md](docs/development/BUG_SUMMARY_COMPLETE.md)

包含：
- 11个已修复Bug的完整记录
- 详细的诊断步骤和解决方案
- 综合诊断工具
- 最佳实践总结

**项目整理报告**: [docs/development/PROJECT_CLEANUP_REPORT.md](docs/development/PROJECT_CLEANUP_REPORT.md)

**文档整合说明**: [docs/development/DOCS_INTEGRATION_SUMMARY.md](docs/development/DOCS_INTEGRATION_SUMMARY.md)

---

## ✨ 核心功能

- **差异表达分析**: limma-voom & edgeR
- **富集分析**: KEGG & GO 功能富集
- **GSEA分析**: 基因集富集分析
- **转录因子活性**: decoupleR推断
- **韦恩图**: 多组交集分析
- **增强火山图**: 多格式支持

### v11.2 新功能

- ✅ 多文件背景基因集上传（2-5个CSV）
- ✅ 自动交集计算作为Universe
- ✅ 智能列名检测
- ✅ 实时Universe预览

---

## 🎯 快速链接

| 需求 | 文档 |
|------|------|
| 快速上手 | [用户手册第1-2章](docs/user_guide/USER_MANUAL_COMPLETE.md) |
| 富集分析最佳实践 | [用户手册第5章](docs/user_guide/USER_MANUAL_COMPLETE.md#富集分析最佳实践) ⭐ |
| 遇到Bug | [Bug总结](docs/development/BUG_SUMMARY_COMPLETE.md) |
| Universe选择 | [Universe核心原则](docs/UNIVERSE_CORE_PRINCIPLES.md) |

---

## 📁 项目结构

```
Biofree_project/
├── app.R                          # 主应用
├── config/                        # 配置文件
├── modules/                       # 功能模块
├── scripts/                       # 工具脚本
│   ├── cleanup/                   # 清理脚本
│   └── tests/                     # 测试脚本
├── docs/                          # 📖 文档目录
│   ├── user_guide/                # 用户文档
│   │   ├── USER_MANUAL_COMPLETE.md  # 完整用户手册
│   │   └── README.md                 # 项目说明
│   └── development/               # 开发文档
│       ├── BUG_SUMMARY_COMPLETE.md   # Bug修复总结
│       ├── PROJECT_CLEANUP_REPORT.md
│       └── DOCS_INTEGRATION_SUMMARY.md
├── data/                          # 数据目录
└── tests/                         # 测试目录
```

---

## 🔧 常见问题

### Q: 数据库锁定怎么办？

```r
source("scripts/cleanup/cleanup_r_locks.R")
```

详见 [Bug总结 - 数据库锁定](docs/development/BUG_SUMMARY_COMPLETE.md#1-数据库锁定问题)

### Q: KEGG查询失败？

检查网络连接，查看 [KEGG调试指南](docs/KEGG_DEBUG_GUIDE.md)

### Q: 如何选择背景基因集？

**最重要的问题！** 详见：
- [Universe核心原则](docs/UNIVERSE_CORE_PRINCIPLES.md)
- [富集分析完整指南](docs/ENRICHMENT_UNIVERSE_GUIDE.md)
- [用户手册第5章](docs/user_guide/USER_MANUAL_COMPLETE.md#富集分析最佳实践)

---

## 📝 更新日志

### v11.2 (2025-01-03)
- 多文件背景基因集上传
- 自动交集计算
- 增强的错误提示

### v11.1 (2024-12-10)
- 修复基因注释错误
- 增强基因匹配算法

---

## 📄 许可证

本项目仅供学习和研究使用。

---

## 🤝 贡献

欢迎贡献代码、报告Bug或提出建议！

---

**最后更新**: 2025-01-04
**版本**: v11.2
**维护者**: Development Team
