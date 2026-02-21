# 测试注册模块语法
cat("测试注册模块语法...\n")

# 加载必要的库
library(RSQLite)
library(DBI)

# 设置测试配置
DB_PATH <- "test_biofree_users.sqlite"
DEFAULT_ADMIN_USERNAME <- "admin"
DEFAULT_ADMIN_PASSWORD <- "1234"
DEFAULT_ADMIN_NAME <- "管理员"
DEFAULT_ADMIN_PERMISSIONS <- "admin"
DAILY_LIMIT <- 100

# 加载数据库函数
source("modules/database.R")

# 测试数据库初始化
cat("\n1. 测试数据库初始化...\n")
init_db()
cat("数据库初始化成功\n")

# 测试用户名检查
cat("\n2. 测试用户名检查...\n")
username_exists <- check_username_exists("admin")
cat("admin用户名是否存在:", username_exists, "(应为TRUE)\n")

username_not_exists <- check_username_exists("testuser123")
cat("testuser123用户名是否存在:", username_not_exists, "(应为FALSE)\n")

# 测试邮箱检查
cat("\n3. 测试邮箱检查...\n")
email_exists <- check_email_exists("")
cat("空邮箱是否存在:", email_exists, "(应为FALSE)\n")

# 测试验证码保存和验证
cat("\n4. 测试验证码功能...\n")
test_email <- "test@example.com"
test_code <- "123456"
test_username <- "testuser"
test_name <- "测试用户"
test_school <- "测试学校"

save_registration_code(test_email, test_code, test_username, test_name, test_school)
cat("验证码保存成功\n")

verification_result <- verify_registration_code(test_email, test_code)
cat("验证码验证结果:", verification_result$success, "(应为TRUE)\n")
if (verification_result$success) {
  cat("用户名:", verification_result$username, "\n")
  cat("真实姓名:", verification_result$real_name, "\n")
  cat("学校:", verification_result$school, "\n")
}

# 测试错误验证码
wrong_result <- verify_registration_code(test_email, "999999")
cat("错误验证码验证结果:", wrong_result$success, "(应为FALSE)\n")

# 测试创建用户
cat("\n5. 测试创建用户...\n")
activation_code <- create_new_user("newuser", "password123", "新用户", "newuser@example.com", "新学校")
cat("用户创建成功，激活码:", activation_code, "\n")

# 验证新用户是否存在
new_user_exists <- check_username_exists("newuser")
cat("新用户是否存在:", new_user_exists, "(应为TRUE)\n")

# 清理测试数据库
cat("\n6. 清理测试文件...\n")
if (file.exists("test_biofree_users.sqlite")) {
  file.remove("test_biofree_users.sqlite")
  cat("测试数据库已删除\n")
}

cat("\n所有测试完成！\n")