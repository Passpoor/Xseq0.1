# =====================================================
# 配置文件
# =====================================================

# 数据库路径
DB_PATH <- "biofree_users.sqlite"

# 每日使用限制
DAILY_LIMIT <- 100

# 应用配置
APP_TITLE <- "Biofree"
APP_VERSION <- "12"

# 默认管理员账户 (首次运行后请立即修改密码)
DEFAULT_ADMIN_USERNAME <- "admin"
DEFAULT_ADMIN_PASSWORD <- "PleaseChangeThisPassword123!"
DEFAULT_ADMIN_NAME <- "Administrator"
DEFAULT_ADMIN_PERMISSIONS <- "admin"

# DeepSeek API配置
DEEPSEEK_API_KEY <- Sys.getenv("DEEPSEEK_API_KEY", "")
DEEPSEEK_API_URL <- "https://api.deepseek.com/v1/chat/completions"

# =====================================================
# 智谱AI API配置
# =====================================================
ZHIPU_API_KEY <- Sys.getenv("ZHIPU_API_KEY", "")
ZHIPU_API_URL <- "https://open.bigmodel.cn/api/paas/v4/chat/completions"
ZHIPU_MODEL <- "glm-4-air"  # 可选: glm-4-flash, glm-4-air, glm-4-plus

# 智谱AI配置存储函数
save_zhipu_config <- function(api_key) {
  config_file <- "zhipu_config.RData"
  config <- list(zhipu_api_key = api_key)
  save(config, file = config_file)
}

# 智谱AI配置加载函数
load_zhipu_config <- function() {
  config_file <- "zhipu_config.RData"
  if (file.exists(config_file)) {
    load(config_file)
    return(config$zhipu_api_key)
  } else {
    return("")
  }
}

# 初始化时加载智谱AI配置
if (interactive()) {
  ZHIPU_API_KEY <- load_zhipu_config()
}

# API配置存储函数
save_api_config <- function(api_key) {
  config_file <- "api_config.RData"
  config <- list(deepseek_api_key = api_key)
  save(config, file = config_file)
}

# API配置加载函数
load_api_config <- function() {
  config_file <- "api_config.RData"
  if (file.exists(config_file)) {
    load(config_file)
    return(config$deepseek_api_key)
  } else {
    return("")
  }
}

# 初始化时加载API配置
if (interactive()) {
  DEEPSEEK_API_KEY <- load_api_config()
}