# =====================================================
# Xseq License UI - 激活界面模块
# =====================================================
# 显示机器码和激活状态的 UI
# =====================================================

# 激活界面 CSS
license_ui_css <- "
<style>
.license-container {
  max-width: 500px;
  margin: 100px auto;
  padding: 40px;
  background: linear-gradient(145deg, #1a1a2e, #16213e);
  border-radius: 20px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.3);
  text-align: center;
  font-family: 'Segoe UI', system-ui, sans-serif;
}

.license-title {
  color: #fff;
  font-size: 28px;
  font-weight: 600;
  margin-bottom: 30px;
}

.license-icon {
  font-size: 64px;
  margin-bottom: 20px;
}

.machine-code-box {
  background: #0f0f23;
  border: 2px solid #007AFF;
  border-radius: 10px;
  padding: 20px;
  margin: 20px 0;
}

.machine-code {
  font-family: 'Consolas', 'Monaco', monospace;
  font-size: 24px;
  color: #00ff88;
  letter-spacing: 4px;
  font-weight: bold;
}

.machine-code-label {
  color: #888;
  font-size: 14px;
  margin-bottom: 10px;
}

.contact-info {
  color: #aaa;
  font-size: 16px;
  margin: 20px 0;
}

.contact-email {
  color: #007AFF;
  font-weight: 500;
}

.copy-btn {
  background: linear-gradient(135deg, #007AFF, #0056b3);
  color: white;
  border: none;
  padding: 12px 30px;
  border-radius: 25px;
  font-size: 16px;
  cursor: pointer;
  margin: 10px 5px;
  transition: all 0.3s ease;
}

.copy-btn:hover {
  transform: scale(1.05);
  box-shadow: 0 5px 20px rgba(0,122,255,0.4);
}

.check-btn {
  background: linear-gradient(135deg, #00ff88, #00cc6a);
  color: #000;
  border: none;
  padding: 12px 30px;
  border-radius: 25px;
  font-size: 16px;
  cursor: pointer;
  margin: 10px 5px;
  transition: all 0.3s ease;
}

.check-btn:hover {
  transform: scale(1.05);
  box-shadow: 0 5px 20px rgba(0,255,136,0.4);
}

.status-box {
  padding: 15px;
  border-radius: 10px;
  margin: 20px 0;
}

.status-pending {
  background: rgba(255, 193, 7, 0.2);
  border: 1px solid #ffc107;
  color: #ffc107;
}

.status-active {
  background: rgba(0, 255, 136, 0.2);
  border: 1px solid #00ff88;
  color: #00ff88;
}

.status-error {
  background: rgba(255, 59, 48, 0.2);
  border: 1px solid #ff3b30;
  color: #ff3b30;
}

.steps-info {
  text-align: left;
  color: #888;
  font-size: 14px;
  margin: 20px 0;
  padding: 15px;
  background: rgba(255,255,255,0.05);
  border-radius: 10px;
}

.steps-info ol {
  margin: 10px 0;
  padding-left: 20px;
}

.steps-info li {
  margin: 8px 0;
}

.loading-spinner {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 3px solid rgba(255,255,255,.3);
  border-radius: 50%;
  border-top-color: #007AFF;
  animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
"

# 生成激活界面 HTML
generate_license_ui <- function(machine_code, license_status = NULL) {

  status_html <- ""
  status_class <- "status-pending"

  if (!is.null(license_status)) {
    if (license_status$status == "active") {
      status_class <- "status-active"
      status_html <- sprintf("
        <div class='status-box %s'>
          <div style='font-size: 24px;'>✅</div>
          <div style='font-size: 18px; margin-top: 10px;'>激活成功！</div>
          <div style='margin-top: 10px; font-size: 14px;'>
            授权类型: %s<br>
            有效期至: %s
          </div>
        </div>
      ",
      status_class,
      get_license_type_text(license_status$type),
      license_status$expires_at %||% "永久"
      )
    } else if (license_status$status == "error") {
      status_class <- "status-error"
      status_html <- sprintf("
        <div class='status-box %s'>
          <div style='font-size: 24px;'>⚠️</div>
          <div style='font-size: 16px; margin-top: 10px;'>%s</div>
        </div>
      ", status_class, license_status$message)
    } else if (license_status$status == "expired") {
      status_class <- "status-error"
      status_html <- sprintf("
        <div class='status-box %s'>
          <div style='font-size: 24px;'>❌</div>
          <div style='font-size: 16px; margin-top: 10px;'>授权已过期</div>
          <div style='margin-top: 10px; font-size: 14px;'>%s</div>
        </div>
      ", status_class, license_status$message)
    }
  }

  if (status_html == "") {
    status_html <- sprintf("
      <div class='status-box %s'>
        <div style='font-size: 24px;'>⏳</div>
        <div style='font-size: 16px; margin-top: 10px;'>等待激活</div>
      </div>
    ", status_class)
  }

  html <- sprintf("
%s
<div class='license-container'>
  <div class='license-title'>🔐 Xseq 激活</div>

  <div class='machine-code-label'>您的机器码</div>
  <div class='machine-code-box'>
    <div class='machine-code' id='machine-code'>%s</div>
  </div>

  <button class='copy-btn' onclick=\"navigator.clipboard.writeText('%s').then(() => alert('机器码已复制！'))\">
    📋 复制机器码
  </button>

  <div class='contact-info'>
    请将机器码发送至邮箱激活：<br>
    <span class='contact-email'>📧 xseq_fastfreee@163.com</span>
  </div>

  <div class='steps-info'>
    <strong>激活步骤：</strong>
    <ol>
      <li>复制上方机器码</li>
      <li>发送邮件至 <span style='color:#007AFF'>xseq_fastfreee@163.com</span></li>
      <li>邮件中请注明：姓名、学校/单位、申请类型（试用/月度/年度）</li>
      <li>等待管理员激活（通常 24 小时内）</li>
      <li>收到激活通知后，点击下方按钮验证</li>
    </ol>
  </div>

  %s

  <div style='margin-top: 20px;'>
    <button class='check-btn' onclick='Shiny.setInputValue(\"check_license\", 1, {priority: \"event\"})'>
      🔄 检查激活状态
    </button>
  </div>
</div>

<script>
// 自动复制功能
function copyMachineCode() {
  var code = document.getElementById('machine-code').innerText;
  navigator.clipboard.writeText(code).then(function() {
    alert('机器码已复制到剪贴板！');
  });
}
</script>
",
  license_ui_css,
  machine_code,
  machine_code,
  status_html
  )

  return(html)
}

# 生成激活成功界面
generate_activated_ui <- function(license_info) {
  html <- sprintf("
%s
<div class='license-container'>
  <div class='license-icon'>✅</div>
  <div class='license-title'>激活成功！</div>

  <div class='status-box status-active'>
    <div style='font-size: 18px;'>
      <strong>授权信息</strong>
    </div>
    <div style='margin-top: 15px; text-align: left;'>
      <p>📋 授权类型：%s</p>
      <p>📅 有效期至：%s</p>
      %s
    </div>
  </div>

  <div style='margin-top: 20px;'>
    <button class='check-btn' onclick='location.reload()' style='padding: 15px 40px;'>
      🚀 开始使用
    </button>
  </div>
</div>
",
  license_ui_css,
  get_license_type_text(license_info$type),
  license_info$expires_at %||% "永久有效",
  if (!is.null(license_info$user_name)) sprintf("<p>👤 用户：%s</p>", license_info$user_name) else ""
  )

  return(html)
}
