# 检查括号平衡
lines <- readLines("modules/ui_theme.R", n = 640)

# 只检查前640行（到main_app_ui定义之前）
open_paren <- 0
close_paren <- 0

cat("Checking parentheses balance...\n")
for (i in 1:length(lines)) {
  line <- lines[i]
  open_paren <- open_paren + sum(strsplit(line, "")[[1]] == "(")
  close_paren <- close_paren + sum(strsplit(line, "")[[1]] == ")")

  if (i == 490) cat(sprintf("Line %d (login_ui start): open=%d, close=%d, diff=%d\n", i, open_paren, close_paren, open_paren - close_paren))
  if (i == 631) cat(sprintf("Line %d (login_ui end?): open=%d, close=%d, diff=%d\n", i, open_paren, close_paren, open_paren - close_paren))
  if (i == 637) cat(sprintf("Line %d (main_app_ui): open=%d, close=%d, diff=%d\n", i, open_paren, close_paren, open_paren - close_paren))
}

cat(sprintf("\nTotal: open=%d, close=%d, diff=%d\n", open_paren, close_paren, open_paren - close_paren))