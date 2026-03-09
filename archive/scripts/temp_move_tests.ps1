$root = "D:\cherry_code\Biofree_project11.2\Biofree_project"
$dest = "D:\cherry_code\Biofree_project11.2\Biofree_project\tests\root_tests"

$testFiles = @(
  "test_registration.R",
  "check_db.R",
  "check_db_structure.R",
  "migrate_database.R",
  "test_background_fix.R",
  "test_gene_symbols.R",
  "diagnose_kegg_go.R",
  "test_fix_cleanup.R",
  "debug_full_pipeline.R",
  "test_fix_validation.R",
  "test_simple_fix.R",
  "test_fix_safe.R",
  "test_full_pipeline.R",
  "verify_fix_complete.R",
  "gene_symbol_validator.R",
  "test_background_conversion_fix.R",
  "test_ensembl_fix.R",
  "test_volcano_fix.R",
  "test_volcano_fix_final.R",
  "test_complete_fix.R",
  "test_volcano_data_fix.R",
  "fix_ui_theme.R",
  "add_haibo_user.R",
  "check_parens.R",
  "fix_volcano_log2foldchange.R",
  "test_method_selection.R",
  "test_notification_types.R",
  "test_group_factor.R",
  "test_design_matrix.R",
  "test_gsea_module.R",
  "launch_app.R",
  "debug_gsea_table.R",
  "test_gsea_complete.R",
  "verify_gsea_complete.R",
  "test_gsea_fixes.R",
  "organize_files.R",
  "organize_files_safe.R",
  "execute_org.R",
  "test_syntax.R",
  "test_zhipu_integration.R",
  "test_pathway_module.R",
  "verify_pathway_fix.R",
  "install_packages.R"
)

$count = 0
foreach ($file in $testFiles) {
  $source = Join-Path $root $file
  if (Test-Path $source) {
    Write-Host "Moving: $file"
    Move-Item -Path $source -Destination $dest -Force
    $count++
  }
}

Write-Host "`nMoved $count test files to $dest"
