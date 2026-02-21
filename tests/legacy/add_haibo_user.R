# 添加HaiboZhang用户脚本
# 如果数据库已经存在，运行此脚本添加新用户

cat("添加HaiboZhang用户...\n")

# 加载必要的包
library(RSQLite)
library(DBI)

# 数据库路径
DB_PATH <- "biofree_users.sqlite"

# 连接数据库
con <- dbConnect(RSQLite::SQLite(), DB_PATH)

# 检查用户是否已存在
existing_user <- dbGetQuery(con, "SELECT username FROM users WHERE username = ?", params = list("HaiboZhang"))

if (nrow(existing_user) == 0) {
  # 添加新用户
  dbExecute(con, "INSERT INTO users (username, password, name, email, school, permissions, is_active, created_at, activated_at) VALUES (?, ?, ?, ?, ?, ?, 1, datetime('now'), datetime('now'))",
            params = list("HaiboZhang", "sjtu214", "Haibo Zhang", "", "用户", "user"))

  cat("✅ 成功添加用户: HaiboZhang\n")
} else {
  cat("⚠️ 用户 HaiboZhang 已存在\n")
}

# 显示所有用户
cat("\n当前系统用户列表:\n")
users <- dbGetQuery(con, "SELECT username, name, permissions, is_active FROM users")
print(users)

# 关闭连接
dbDisconnect(con)

cat("\nHaiboZhang账户信息:\n")
cat("用户名: HaiboZhang\n")
cat("密码: sjtu214\n")
cat("姓名: Haibo Zhang\n")
cat("权限: 用户 (user)\n")
cat("状态: 已激活\n")