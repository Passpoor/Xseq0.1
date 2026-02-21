# 检查数据库结构
library(RSQLite)
library(DBI)

cat("检查数据库结构...\n")

# 连接数据库
con <- dbConnect(SQLite(), "biofree_users.sqlite")

# 检查表结构
cat("\n1. 用户表结构:\n")
users_info <- dbGetQuery(con, "PRAGMA table_info(users)")
print(users_info)

cat("\n2. 注册验证码表结构:\n")
codes_info <- dbGetQuery(con, "PRAGMA table_info(registration_codes)")
print(codes_info)

# 检查现有用户
cat("\n3. 现有用户:\n")
users <- dbGetQuery(con, "SELECT username, name, email, school, permissions, is_active FROM users")
print(users)

# 检查验证码表
cat("\n4. 验证码表内容:\n")
codes <- dbGetQuery(con, "SELECT email, username, real_name, school FROM registration_codes")
if (nrow(codes) > 0) {
  print(codes)
} else {
  cat("验证码表为空\n")
}

# 关闭连接
dbDisconnect(con)

cat("\n数据库检查完成！\n")