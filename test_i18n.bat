@echo off
REM =====================================================
REM Biofree 国际化测试启动脚本
REM =====================================================

echo ========================================
echo   Biofree i18n Test / 国际化测试
echo ========================================
echo.

echo Starting test application / 启动测试应用...
echo.

Rscript -e "setwd('D:/cherry_code/Biofree_project11.2/Biofree_project'); source('test_i18n.R')"

pause
