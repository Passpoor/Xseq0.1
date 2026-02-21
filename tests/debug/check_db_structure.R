# 检查当前数据库结构
library(RSQLite)
library(DBI)

cat("检查当前数据库结构...\n")

# 连接数据库
con <- dbConnect(SQLite(), "biofree_users.sqlite")

# 检查所有表
cat("\n1. 数据库中的所有表:\n")
tables <- dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type='table'")
print(tables)

# 检查users表结构
cat("\n2. users表结构:\n")
users_info <- dbGetQuery(con, "PRAGMA table_info(users)")
print(users_info)

# 检查现有数据
cat("\n3. users表中的数据:\n")
users_data <- dbGetQuery(con, "SELECT * FROM users")
print(users_data)

# 关闭连接
dbDisconnect(con)

cat("\n检查完成！\n")