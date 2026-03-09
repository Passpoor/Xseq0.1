@echo off
echo ================================================
echo    BioFastFree v11.0 - 启动脚本
echo ================================================
echo.

REM 检查R是否安装
where R >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到R程序
    echo 请先安装R: https://cran.r-project.org/
    pause
    exit /b 1
)

echo 正在启动BioFastFree分析工具...
echo.

REM 运行应用
R -e "shiny::runApp('app.R', launch.browser=TRUE)"

pause