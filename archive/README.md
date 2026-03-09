# 归档目录说明

此目录包含Biofree项目的历史文件和临时文件，这些文件在项目开发过程中产生，现已归档以保持项目结构清晰。

## 目录结构

### tests/
包含所有的测试脚本、调试脚本和验证脚本：
- `test_*.R` - 各种功能测试脚本
- `debug_*.R` - 调试脚本
- `diagnose_*.R` - 诊断脚本
- `verify_*.R` - 验证脚本

这些脚本用于开发过程中测试和验证各种功能，现已完成历史使命。

### tools/
包含文件整理和组织工具：
- `auto_organize_md.py` - Markdown文档自动整理工具
- `organize_files.R` - 文件整理脚本
- `organize_files_safe.R` - 安全的文件整理脚本
- `organize_project_files.R` - 项目文件整理工具

### scripts/
包含各种批处理和PowerShell脚本：
- `cleanup_files.bat` - 清理批处理脚本
- `finalize_cleanup.ps1` - 最终清理PowerShell脚本
- `organize_md.bat` - 整理Markdown的批处理脚本
- `run_organize.bat` - 运行整理的批处理脚本
- `temp_move_tests.ps1` - 临时移动测试的脚本
- `test_ui.ps1` - UI测试脚本

## 注意事项

1. **不建议删除**：这些文件可能在未来需要参考，不建议删除
2. **历史参考**：可以查看这些文件了解项目开发历史
3. **按需使用**：如果需要重新运行某些测试或整理，可以从此目录取回
4. **版本控制**：建议将此目录纳入版本控制，以便追溯

## 清理时间
2026年1月22日

## 清理目的
- 保持项目根目录整洁
- 提高项目可维护性
- 保留历史文件以备参考
- 便于快速定位核心文件
