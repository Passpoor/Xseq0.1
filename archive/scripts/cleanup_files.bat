@echo off
chcp 65001 >nul
cd /d "D:\cherry_code\Biofree_project11.2\Biofree_project"

echo ======================================
echo 开始清理项目文件...
echo ======================================

set /a count_r=0
set /a count_md_rep=0
set /a count_md_guid=0

:: 移动所有 .R 文件（除了 app.R）
for %%f in (*.R) do (
    if /i not "%%f"=="app.R" (
        echo 移动: %%f
        move "%%f" "tests\root_tests\" >nul 2>&1
        set /a count_r+=1
    )
)

:: 移动修复/报告相关的 .md 文件
for %%f in (*修复*.md *报告*.md *FIX*.md *MODULE*.md GSEA*.md TF*.md PATHWAY*.md KEGG*.md *PROPOSAL*.md) do (
    if exist "%%f" (
        echo 移动报告: %%f
        move "%%f" "docs\reports\" >nul 2>&1
        set /a count_md_rep+=1
    )
)

:: 移动指南相关的 .md 文件
for %%f in (*指南*.md *说明*.md *使用*.md AI*.md API*.md ULM*.md) do (
    if exist "%%f" (
        echo 移动指南: %%f
        move "%%f" "docs\guides\" >nul 2>&1
        set /a count_md_guid+=1
    )
)

:: 移动剩余的 .md 文件（除了 README.md）
for %%f in (*.md) do (
    if /i not "%%f"=="README.md" (
        if /i not "%%f"=="PROJECT_SUMMARY.md" (
            if /i not "%%f"=="CHANGELOG.md" (
                echo 移动其他文档: %%f
                move "%%f" "docs\guides\" >nul 2>&1
            )
        )
    )
)

:: 移动其他文件
if exist run_app.sh move run_app.sh tests\root_tests\ >nul 2>&1
if exist run_app.bat move run_app.bat tests\root_tests\ >nul 2>&1
if exist *.ps1 move *.ps1 tests\root_tests\ >nul 2>&1

echo.
echo ======================================
echo 清理完成！
echo R文件: %count_r% 个
echo 报告文档: %count_md_rep% 个
echo 指南文档: %count_md_guid% 个
echo ======================================

pause
