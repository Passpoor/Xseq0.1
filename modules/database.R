# =====================================================
# 数据库管理模块
# =====================================================

# 数据库初始化
init_db <- function() {
  con <- dbConnect(SQLite(), DB_PATH)

  # 用户表 - 扩展字段支持注册功能
  if (!dbExistsTable(con, "users")) {
    # 创建新表
    dbExecute(con, "
      CREATE TABLE users (
        username TEXT PRIMARY KEY,
        password TEXT,
        name TEXT,
        email TEXT,
        school TEXT,
        permissions TEXT,
        is_active INTEGER DEFAULT 0,
        activation_code TEXT,
        created_at TEXT,
        activated_at TEXT
      )")
    # 默认管理员账号
    dbExecute(con, "INSERT OR IGNORE INTO users VALUES (?, ?, ?, ?, ?, ?, 1, NULL, datetime('now'), datetime('now'))",
              params = list(DEFAULT_ADMIN_USERNAME, DEFAULT_ADMIN_PASSWORD, DEFAULT_ADMIN_NAME,
                           "", "系统管理", DEFAULT_ADMIN_PERMISSIONS))

    # HaiboZhang 账户
    dbExecute(con, "INSERT OR IGNORE INTO users VALUES (?, ?, ?, ?, ?, ?, 1, NULL, datetime('now'), datetime('now'))",
              params = list("HaiboZhang", "sjtu214", "Haibo Zhang", "", "用户", "user"))

    cat("创建了新的users表（包含admin和HaiboZhang账户）\n")
  } else {
    # 表已存在，检查并添加缺失的列
    cat("users表已存在，检查列结构...\n")
    users_info <- dbGetQuery(con, "PRAGMA table_info(users)")
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
    for (col_name in names(new_columns)) {
      if (!col_name %in% existing_columns) {
        sql <- sprintf("ALTER TABLE users ADD COLUMN %s %s", col_name, new_columns[[col_name]])
        dbExecute(con, sql)
        cat("已添加列:", col_name, "\n")
      }
    }

    # 更新现有用户的默认值
    users_data <- dbGetQuery(con, "SELECT username FROM users")
    if (nrow(users_data) > 0) {
      for (i in 1:nrow(users_data)) {
        username <- users_data$username[i]

        # 检查并更新email
        current_email <- dbGetQuery(con, "SELECT email FROM users WHERE username = ?",
                                   params = list(username))
        if (nrow(current_email) > 0 && (is.na(current_email$email) || current_email$email == "")) {
          dbExecute(con, "UPDATE users SET email = ? WHERE username = ?",
                    params = list("", username))
        }

        # 检查并更新school
        current_school <- dbGetQuery(con, "SELECT school FROM users WHERE username = ?",
                                    params = list(username))
        if (nrow(current_school) > 0 && (is.na(current_school$school) || current_school$school == "")) {
          default_school <- if (username == "admin") "系统管理" else "未知"
          dbExecute(con, "UPDATE users SET school = ? WHERE username = ?",
                    params = list(default_school, username))
        }

        # 检查并更新is_active
        current_active <- dbGetQuery(con, "SELECT is_active FROM users WHERE username = ?",
                                    params = list(username))
        if (nrow(current_active) > 0 && (is.na(current_active$is_active) || current_active$is_active == 0)) {
          dbExecute(con, "UPDATE users SET is_active = 1 WHERE username = ?",
                    params = list(username))
        }
      }
      cat("已更新", nrow(users_data), "条用户记录\n")
    }
  }

  # 使用日志表
  if (!dbExistsTable(con, "usage_logs")) {
    dbExecute(con, "CREATE TABLE usage_logs (username TEXT, date TEXT, count INTEGER, PRIMARY KEY (username, date))")
    cat("创建了usage_logs表\n")
  }

  # 注册验证码表
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
    cat("创建了registration_codes表\n")
  }


  dbDisconnect(con)
  cat("数据库初始化完成\n")
}

# 检查使用限制
check_usage_limit <- function(username) {
  if(username == "admin") return(TRUE)
  con <- dbConnect(SQLite(), DB_PATH)
  on.exit(dbDisconnect(con))
  today <- as.character(Sys.Date())
  res <- dbGetQuery(con, "SELECT count FROM usage_logs WHERE username = ? AND date = ?", params = list(username, today))
  current_count <- if (nrow(res) == 0) 0 else res$count[1]
  if (current_count >= DAILY_LIMIT) return(FALSE)

  if (nrow(res) == 0) {
    dbExecute(con, "INSERT INTO usage_logs VALUES (?, ?, 1)", params = list(username, today))
  } else {
    dbExecute(con, "UPDATE usage_logs SET count = count + 1 WHERE username = ? AND date = ?", params = list(username, today))
  }
  return(TRUE)
}

# =====================================================
# 注册相关数据库函数
# =====================================================

# 检查用户名是否已存在
check_username_exists <- function(username) {
  con <- dbConnect(SQLite(), DB_PATH)
  on.exit(dbDisconnect(con))
  res <- dbGetQuery(con, "SELECT 1 FROM users WHERE username = ?", params = list(username))
  return(nrow(res) > 0)
}

# 检查邮箱是否已存在
check_email_exists <- function(email) {
  if (email == "" || is.na(email)) {
    return(FALSE)
  }
  con <- dbConnect(SQLite(), DB_PATH)
  on.exit(dbDisconnect(con))
  res <- dbGetQuery(con, "SELECT 1 FROM users WHERE email = ? AND email != ''", params = list(email))
  return(nrow(res) > 0)
}

# 保存注册验证码
save_registration_code <- function(email, code, username, real_name, school) {
  con <- dbConnect(SQLite(), DB_PATH)
  on.exit(dbDisconnect(con))

  # 设置验证码有效期（15分钟）
  created_at <- as.character(Sys.time())
  expires_at <- as.character(Sys.time() + 15 * 60)

  # 删除旧的验证码（如果有）
  dbExecute(con, "DELETE FROM registration_codes WHERE email = ?", params = list(email))

  # 插入新的验证码
  dbExecute(con, "
    INSERT INTO registration_codes (email, code, username, real_name, school, created_at, expires_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)",
    params = list(email, code, username, real_name, school, created_at, expires_at))
}

# 验证注册码
verify_registration_code <- function(email, code) {
  con <- dbConnect(SQLite(), DB_PATH)
  on.exit(dbDisconnect(con))

  # 检查验证码是否存在且未过期
  res <- dbGetQuery(con, "
    SELECT username, real_name, school
    FROM registration_codes
    WHERE email = ? AND code = ? AND expires_at > datetime('now')",
    params = list(email, code))

  if (nrow(res) == 1) {
    return(list(
      success = TRUE,
      username = res$username[1],
      real_name = res$real_name[1],
      school = res$school[1]
    ))
  } else {
    return(list(success = FALSE))
  }
}

# 创建新用户
create_new_user <- function(username, password, real_name, email, school) {
  con <- dbConnect(SQLite(), DB_PATH)
  on.exit(dbDisconnect(con))

  # 生成随机激活码（6位数字）
  activation_code <- sprintf("%06d", sample(100000:999999, 1))

  dbExecute(con, "
    INSERT INTO users (username, password, name, email, school, permissions, is_active, activation_code, created_at)
    VALUES (?, ?, ?, ?, ?, 'user', 1, ?, datetime('now'))",
    params = list(username, password, real_name, email, school, activation_code))

  # 删除已使用的验证码
  dbExecute(con, "DELETE FROM registration_codes WHERE email = ?", params = list(email))

  return(activation_code)
}

