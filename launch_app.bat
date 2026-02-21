@echo off
echo ========================================
echo Biofree应用启动器
echo ========================================
echo.

REM 检查R是否安装
where R >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 未找到R语言环境
    echo 请安装R并添加到系统PATH
    pause
    exit /b 1
)

echo 正在启动Biofree应用...
echo.

REM 切换到项目目录
cd /d "D:\cherry_code\Biofree_project11.2\Biofree_project"

REM 启动R并运行启动脚本
Rscript.exe launch_app.R

pause
