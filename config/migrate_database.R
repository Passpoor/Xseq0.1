# 数据库迁移脚本
# 更新现有的数据库表结构以支持注册功能

library(RSQLite)
library(DBI)

cat("开始数据库迁移...\n")

# 连接数据库
con <- dbConnect(SQLite(), "biofree_users.sqlite")

# 备份原始数据
cat("\n1. 备份原始数据...\n")
users_data <- dbGetQuery(con, "SELECT * FROM users")
usage_logs_data <- dbGetQuery(con, "SELECT * FROM usage_logs")

cat("备份了", nrow(users_data), "条用户记录和", nrow(usage_logs_data), "条使用日志\n")

# 检查当前表结构
cat("\n2. 检查当前表结构...\n")
users_info <- dbGetQuery(con, "PRAGMA table_info(users)")
print(users_info)

# 获取现有列名
existing_columns <- users_info$name

# 需要添加的新列
new_columns <- list(
  email = "TEXT",
  school = "TEXT",
  is_active = "INTEGER DEFAULT 0",
  activation_code = "TEXT",
  activated_at = "TEXT"
)

# 添加缺失的列
cat("\n3. 添加缺失的列...\n")
for (col_name in names(new_columns)) {
  if (!col_name %in% existing_columns) {
    sql <- sprintf("ALTER TABLE users ADD COLUMN %s %s", col_name, new_columns[[col_name]])
    dbExecute(con, sql)
    cat("已添加列:", col_name, "\n")
  } else {
    cat("列已存在:", col_name, "\n")
  }
}

# 创建registration_codes表（如果不存在）
cat("\n4. 创建registration_codes表...\n")
if (!dbExistsTable(con, "registration_codes")) {
  dbExecute(con, "
    CREATE TABLE registration_codes (
      email TEXT PRIMARY KEY,
      code TEXT,
      username TEXT,
      real_name TEXT,
      school TEXT,
      created_at TEXT,
      expires_at TEXT
    )")
  cat("已创建registration_codes表\n")
} else {
  cat("registration_codes表已存在\n")
}

# 更新现有用户的默认值
cat("\n5. 更新现有用户数据...\n")
if (nrow(users_data) > 0) {
  # 为现有用户设置默认值
  for (i in 1:nrow(users_data)) {
    username <- users_data$username[i]

    # 检查是否需要更新
    current_user <- dbGetQuery(con, "SELECT email, school, is_active FROM users WHERE username = ?",
                               params = list(username))

    # 如果email为空，设置为空字符串
    if (is.na(current_user$email) || current_user$email == "") {
      dbExecute(con, "UPDATE users SET email = ? WHERE username = ?",
                params = list("", username))
    }

    # 如果school为空，根据用户名设置默认值
    if (is.na(current_user$school) || current_user$school == "") {
      default_school <- if (username == "admin") "系统管理" else "未知"
      dbExecute(con, "UPDATE users SET school = ? WHERE username = ?",
                params = list(default_school, username))
    }

    # 设置is_active为1（已激活）
    if (is.na(current_user$is_active) || current_user$is_active == 0) {
      dbExecute(con, "UPDATE users SET is_active = 1 WHERE username = ?",
                params = list(username))
    }
  }
  cat("已更新", nrow(users_data), "条用户记录\n")
}

# 验证迁移结果
cat("\n6. 验证迁移结果...\n")
final_info <- dbGetQuery(con, "PRAGMA table_info(users)")
cat("users表最终结构:\n")
print(final_info)

# 显示迁移后的数据
cat("\n7. 迁移后的用户数据:\n")
final_data <- dbGetQuery(con, "SELECT username, name, email, school, is_active FROM users")
print(final_data)

# 关闭连接
dbDisconnect(con)

cat("\n✅ 数据库迁移完成！\n")
cat("现在可以正常使用注册功能了。\n")