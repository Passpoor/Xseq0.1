# 邮件配置模板
# 使用QQ邮箱SMTP服务发送验证码邮件

# 安装必要的包
if (!require("mailR")) {
  install.packages("mailR")
  library(mailR)
}

# QQ邮箱SMTP配置
send_email_qq <- function(to_email, verification_code, username, real_name, school) {
  # 邮件主题
  subject <- "Biofree RNAseq分析平台 - 注册验证码"

  # 邮件内容
  body <- paste0(
    "尊敬的 ", real_name, " 用户，<br><br>",
    "感谢您注册 Biofree RNAseq分析平台！<br><br>",
    "<b>您的注册信息：</b><br>",
    "用户名：", username, "<br>",
    "真实姓名：", real_name, "<br>",
    "学校/单位：", school, "<br>",
    "注册邮箱：", to_email, "<br><br>",
    "<b style='color: red; font-size: 18px;'>验证码：", verification_code, "</b><br><br>",
    "验证码有效期为15分钟，请尽快完成注册。<br><br>",
    "如果这不是您本人的操作，请忽略此邮件。<br><br>",
    "祝您使用愉快！<br>",
    "Biofree 团队<br>",
    format(Sys.time(), "%Y年%m月%d日")
  )

  tryCatch({
    send.mail(
      from = "your_qq_email@qq.com",          # 发件人QQ邮箱
      to = to_email,                          # 收件人（用户）
      cc = "xseq_fastfreee@163.com",                # 抄送管理员邮箱
      subject = subject,
      body = body,
      html = TRUE,                            # 使用HTML格式
      smtp = list(
        host.name = "smtp.qq.com",           # QQ邮箱SMTP服务器
        port = 465,                          # SSL端口
        user.name = "your_qq_email@qq.com",  # QQ邮箱账号
        passwd = "your_authorization_code",  # 授权码（不是密码）
        ssl = TRUE                           # 使用SSL
      ),
      authenticate = TRUE,
      send = TRUE
    )
    cat("✅ 验证码邮件已发送到：", to_email, "\n")
    cat("✅ 抄送邮件已发送到：xseq_fastfreee@163.com\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ 邮件发送失败：", e$message, "\n")
    return(FALSE)
  })
}

# 163邮箱SMTP配置
send_email_163 <- function(to_email, verification_code, username, real_name, school) {
  subject <- "Biofree RNAseq分析平台 - 注册验证码"

  body <- paste0(
    "尊敬的 ", real_name, " 用户，<br><br>",
    "感谢您注册 Biofree RNAseq分析平台！<br><br>",
    "<b>您的注册信息：</b><br>",
    "用户名：", username, "<br>",
    "真实姓名：", real_name, "<br>",
    "学校/单位：", school, "<br>",
    "注册邮箱：", to_email, "<br><br>",
    "<b style='color: red; font-size: 18px;'>验证码：", verification_code, "</b><br><br>",
    "验证码有效期为15分钟，请尽快完成注册。<br><br>",
    "如果这不是您本人的操作，请忽略此邮件。<br><br>",
    "祝您使用愉快！<br>",
    "Biofree 团队<br>",
    format(Sys.time(), "%Y年%m月%d日")
  )

  tryCatch({
    send.mail(
      from = "your_email@163.com",           # 发件人163邮箱
      to = to_email,
      cc = "xseq_fastfreee@163.com",
      subject = subject,
      body = body,
      html = TRUE,
      smtp = list(
        host.name = "smtp.163.com",          # 163邮箱SMTP服务器
        port = 465,
        user.name = "your_email@163.com",    # 163邮箱账号
        passwd = "your_authorization_code",  # 授权码
        ssl = TRUE
      ),
      authenticate = TRUE,
      send = TRUE
    )
    cat("✅ 验证码邮件已发送到：", to_email, "\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ 邮件发送失败：", e$message, "\n")
    return(FALSE)
  })
}

# Gmail SMTP配置
send_email_gmail <- function(to_email, verification_code, username, real_name, school) {
  subject <- "Biofree RNAseq Analysis Platform - Verification Code"

  body <- paste0(
    "Dear ", real_name, ",<br><br>",
    "Thank you for registering with Biofree RNAseq Analysis Platform!<br><br>",
    "<b>Your registration information:</b><br>",
    "Username: ", username, "<br>",
    "Real Name: ", real_name, "<br>",
    "School/Organization: ", school, "<br>",
    "Email: ", to_email, "<br><br>",
    "<b style='color: red; font-size: 18px;'>Verification Code: ", verification_code, "</b><br><br>",
    "The verification code is valid for 15 minutes. Please complete your registration as soon as possible.<br><br>",
    "If this was not your action, please ignore this email.<br><br>",
    "Best regards,<br>",
    "文献计量与基础医学<br>",
    format(Sys.time(), "%Y-%m-%d")
  )

  tryCatch({
    send.mail(
      from = "your_email@gmail.com",
      to = to_email,
      cc = "xseq_fastfreee@163.com",
      subject = subject,
      body = body,
      html = TRUE,
      smtp = list(
        host.name = "smtp.gmail.com",
        port = 587,
        user.name = "your_email@gmail.com",
        passwd = "your_app_password",        # Gmail应用专用密码
        tls = TRUE                           # 使用TLS
      ),
      authenticate = TRUE,
      send = TRUE
    )
    cat("✅ Verification email sent to: ", to_email, "\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ Email sending failed: ", e$message, "\n")
    return(FALSE)
  })
}

# 使用说明
cat("📧 邮件配置说明\n")
cat("========================================\n")
cat("要启用真实邮件发送，请：\n\n")

cat("1. 选择邮箱服务商：\n")
cat("   - QQ邮箱（推荐国内使用）\n")
cat("   - 163邮箱\n")
cat("   - Gmail（国际使用）\n\n")

cat("2. 获取SMTP授权码：\n")
cat("   QQ邮箱：设置 → 账户 → POP3/IMAP/SMTP服务 → 生成授权码\n")
cat("   163邮箱：设置 → POP3/SMTP/IMAP → 客户端授权密码\n")
cat("   Gmail：Google账户 → 安全性 → 应用专用密码\n\n")

cat("3. 修改配置：\n")
cat("   - 将 'your_qq_email@qq.com' 改为你的QQ邮箱\n")
cat("   - 将 'your_authorization_code' 改为你的授权码\n")
cat("   - 根据需要修改发件人名称等信息\n\n")

cat("4. 集成到注册模块：\n")
cat("   将上述函数复制到 modules/registration.R 中\n")
cat("   替换原来的 send_verification_email 函数\n\n")

cat("5. 测试发送：\n")
cat("   运行以下命令测试邮件发送：\n")
cat("   send_email_qq('test@example.com', '123456', 'testuser', '测试用户', '测试学校')\n")
cat("========================================\n")