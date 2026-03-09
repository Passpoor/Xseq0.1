# PowerShell script to test R syntax
$RPath = "R"
$TestScript = @"
tryCatch({
  source('modules/ui_theme.R')
  cat('SUCCESS: File loaded correctly\n')
}, error=function(e) {
  cat('ERROR:', conditionMessage(e), '\n')
})
"@

$TestScript | Out-File -FilePath "test_ui.R" -Encoding UTF8
& $RPath CMD BATCH test_ui.R test_ui_output.txt
Get-Content test_ui_output.txt | Select-Object -Last 20
