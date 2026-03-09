# Final cleanup script
$root = "D:\cherry_code\Biofree_project11.2\Biofree_project"

# Create directories if not exist
New-Item -ItemType Directory -Force -Path "$root\tests\root_tests" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\docs\reports" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\docs\guides" | Out-Null

Write-Host "Starting file cleanup..." -ForegroundColor Green

# Move R files (except app.R)
Get-ChildItem -Path $root -Filter "*.R" -File | Where-Object { $_.Name -ne "app.R" } | ForEach-Object {
    Write-Host "Moving $($_.Name)"
    Move-Item -Path $_.FullName -Destination "$root\tests\root_tests\" -Force
}

# Move report MD files
$reportPatterns = @("*FIX*.md", "*修复*.md", "*报告*.md", "*MODULE*.md",
                    "GSEA*.md", "TF*.md", "PATHWAY*.md", "KEGG*.md",
                    "*PROPOSAL*.md", "*SUMMARY*.md", "PLAN*.md", "FILE_*.md")

foreach ($pattern in $reportPatterns) {
    Get-ChildItem -Path $root -Filter $pattern -File | Where-Object { $_.Name -ne "README.md" } | ForEach-Object {
        Write-Host "Moving report $($_.Name)"
        Move-Item -Path $_.FullName -Destination "$root\docs\reports\" -Force
    }
}

# Move guide MD files
$guidePatterns = @("*指南*.md", "*说明*.md", "*USAGE*.md", "*使用*.md",
                   "AI*.md", "API*.md", "ULM*.md", "背景*.md",
                   "火山*.md", "差异*.md", "通透*.md", "文件*.md",
                   "智谱*.md", "基本*.md", "Ensembl*.md")

foreach ($pattern in $guidePatterns) {
    Get-ChildItem -Path $root -Filter $pattern -File | Where-Object { $_.Name -ne "README.md" } | ForEach-Object {
        Write-Host "Moving guide $($_.Name)"
        Move-Item -Path $_.FullName -Destination "$root\docs\guides\" -Force
    }
}

# Move remaining MD files (except README.md, PROJECT_SUMMARY.md, CHANGELOG.md)
Get-ChildItem -Path $root -Filter "*.md" -File | Where-Object {
    $_.Name -ne "README.md" -and
    $_.Name -ne "PROJECT_SUMMARY.md" -and
    $_.Name -ne "CHANGELOG.md"
} | ForEach-Object {
    Write-Host "Moving other doc $($_.Name)"
    Move-Item -Path $_.FullName -Destination "$root\docs\guides\" -Force
}

# Move batch and ps1 files
Get-ChildItem -Path $root -Filter "*.bat" -File | ForEach-Object {
    Write-Host "Moving $($_.Name)"
    Move-Item -Path $_.FullName -Destination "$root\tests\root_tests\" -Force
}

Get-ChildItem -Path $root -Filter "*.ps1" -File | ForEach-Object {
    Write-Host "Moving $($_.Name)"
    Move-Item -Path $_.FullName -Destination "$root\tests\root_tests\" -Force
}

# Move shell scripts
Get-ChildItem -Path $root -Filter "*.sh" -File | ForEach-Object {
    Write-Host "Moving $($_.Name)"
    Move-Item -Path $_.FullName -Destination "$root\tests\root_tests\" -Force
}

Write-Host "`nCleanup completed!" -ForegroundColor Green
