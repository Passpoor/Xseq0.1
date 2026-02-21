# =====================================================
# Xseq License Module - 机器码授权系统
# =====================================================
# 功能：生成机器码、验证授权、管理激活状态
# =====================================================

# =====================================================
# 配置
# =====================================================

# 授权列表远程地址（GitHub 私有仓库 raw 链接）
# 需要替换为你的实际仓库地址
LICENSE_URL <- Sys.getenv("XSEQ_LICENSE_URL", "https://raw.githubusercontent.com/Passpoor/Xseq_do/main/licenses.json")

# 本地缓存文件
LICENSE_CACHE_FILE <- ".license_cache.rds"
MACHINE_CODE_FILE <- ".machine_code.rds"

# =====================================================
# 机器码生成
# =====================================================

#' 生成机器码
#' @return 机器码字符串（格式：XXXX-XXXX-XXXX-XXXX）
generate_machine_code <- function() {
  # 检查是否已有缓存的机器码
  if (file.exists(MACHINE_CODE_FILE)) {
    cached_code <- readRDS(MACHINE_CODE_FILE)
    if (!is.null(cached_code) && nchar(cached_code) > 0) {
      return(cached_code)
    }
  }

  # 收集硬件信息
  hardware_info <- c()

  # Windows 系统
  if (.Platform$OS.type == "windows") {
    # CPU ID
    cpu <- tryCatch({
      system("wmic cpu get processorid", intern = TRUE)
    }, error = function(e) { "" })
    cpu <- paste(cpu, collapse = "")
    cpu <- gsub("[^A-Za-z0-9]", "", cpu)
    cpu <- gsub("ProcessorId", "", cpu, ignore.case = TRUE)
    hardware_info <- c(hardware_info, cpu)

    # 主板序列号
    motherboard <- tryCatch({
      system("wmic baseboard get serialnumber", intern = TRUE)
    }, error = function(e) { "" })
    motherboard <- paste(motherboard, collapse = "")
    motherboard <- gsub("[^A-Za-z0-9]", "", motherboard)
    motherboard <- gsub("SerialNumber", "", motherboard, ignore.case = TRUE)
    hardware_info <- c(hardware_info, motherboard)

    # BIOS 序列号
    bios <- tryCatch({
      system("wmic bios get serialnumber", intern = TRUE)
    }, error = function(e) { "" })
    bios <- paste(bios, collapse = "")
    bios <- gsub("[^A-Za-z0-9]", "", bios)
    bios <- gsub("SerialNumber", "", bios, ignore.case = TRUE)
    hardware_info <- c(hardware_info, bios)

  } else {
    # Linux/Mac 系统
    # CPU 信息
    cpu <- tryCatch({
      if (file.exists("/proc/cpuinfo")) {
        cpuinfo <- readLines("/proc/cpuinfo")
        cpu_line <- cpuinfo[grep("model name|vendor_id", cpuinfo, ignore.case = TRUE)[1]]
        gsub(".*:", "", cpu_line)
      } else {
        system("sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'unknown'", intern = TRUE)
      }
    }, error = function(e) { "unknown" })
    hardware_info <- c(hardware_info, cpu)

    # 主板/硬件 UUID
    uuid <- tryCatch({
      if (file.exists("/sys/class/dmi/id/product_uuid")) {
        readLines("/sys/class/dmi/id/product_uuid", warn = FALSE)
      } else {
        system("ioreg -rd1 -c IOPlatformExpertDevice | grep IOPlatformUUID | awk -F'\"' '{print $4}' 2>/dev/null || echo 'unknown'", intern = TRUE)
      }
    }, error = function(e) { "unknown" })
    hardware_info <- c(hardware_info, uuid)

    # MAC 地址
    mac <- tryCatch({
      system("cat /sys/class/net/$(ip route | grep default | awk '{print $5}' | head -1)/address 2>/dev/null || ifconfig | grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1", intern = TRUE)
    }, error = function(e) { "unknown" })
    hardware_info <- c(hardware_info, mac)
  }

  # 合并所有硬件信息并生成哈希
  combined <- paste(hardware_info, collapse = "-")
  hash <- digest::digest(combined, algo = "sha256", serialize = FALSE)

  # 格式化为机器码（取前16位，分4组）
  hash_upper <- toupper(substr(hash, 1, 16))
  machine_code <- sprintf("%s-%s-%s-%s",
                          substr(hash_upper, 1, 4),
                          substr(hash_upper, 5, 8),
                          substr(hash_upper, 9, 12),
                          substr(hash_upper, 13, 16))

  # 缓存机器码
  saveRDS(machine_code, MACHINE_CODE_FILE)

  return(machine_code)
}

# =====================================================
# 授权验证
# =====================================================

#' 从远程获取授权列表
#' @return 授权列表（列表格式）
fetch_license_list <- function() {
  tryCatch({
    # 尝试从远程获取
    response <- httr::GET(LICENSE_URL, httr::timeout(10))

    if (httr::status_code(response) == 200) {
      content <- httr::content(response, "text", encoding = "UTF-8")
      licenses <- jsonlite::fromJSON(content)

      # 缓存到本地
      saveRDS(licenses, LICENSE_CACHE_FILE)

      return(licenses)
    } else {
      # 远程失败，尝试本地缓存
      if (file.exists(LICENSE_CACHE_FILE)) {
        return(readRDS(LICENSE_CACHE_FILE))
      }
      return(NULL)
    }
  }, error = function(e) {
    # 网络错误，尝试本地缓存
    if (file.exists(LICENSE_CACHE_FILE)) {
      return(readRDS(LICENSE_CACHE_FILE))
    }
    return(NULL)
  })
}

#' 检查机器码是否已授权
#' @param machine_code 机器码
#' @return 包含授权信息的列表，未授权返回 NULL
check_license <- function(machine_code = NULL) {
  if (is.null(machine_code)) {
    machine_code <- generate_machine_code()
  }

  licenses <- fetch_license_list()

  if (is.null(licenses)) {
    return(list(
      status = "error",
      message = "无法连接授权服务器，请检查网络连接"
    ))
  }

  # 查找匹配的授权
  if (is.list(licenses) && !is.null(licenses$licenses)) {
    license_list <- licenses$licenses
  } else if (is.list(licenses)) {
    license_list <- licenses
  } else {
    return(list(
      status = "unlicensed",
      message = "未找到授权信息"
    ))
  }

  # 查找当前机器码
  for (i in seq_along(license_list)) {
    license <- license_list[[i]]
    if (is.list(license) && !is.null(license$machine_code)) {
      if (toupper(license$machine_code) == toupper(machine_code)) {
        # 找到匹配的授权，检查有效期
        return(validate_license_info(license))
      }
    } else if (is.character(license)) {
      # 简单格式：machine_code 作为键
      if (toupper(names(license_list)[i]) == toupper(machine_code)) {
        return(validate_license_info(license))
      }
    }
  }

  return(list(
    status = "unlicensed",
    message = "此设备尚未激活"
  ))
}

#' 验证授权详细信息
#' @param license 授权信息
#' @return 验证结果
validate_license_info <- function(license) {
  if (is.list(license)) {
    # 检查状态
    if (!is.null(license$status) && license$status == "revoked") {
      return(list(
        status = "revoked",
        message = "授权已被撤销"
      ))
    }

    # 检查有效期
    if (!is.null(license$expires_at)) {
      expires_date <- as.Date(license$expires_at)
      if (Sys.Date() > expires_date) {
        return(list(
          status = "expired",
          message = paste("授权已过期，过期日期：", license$expires_at),
          expires_at = license$expires_at
        ))
      }
    }

    # 检查使用次数（试用版）
    if (!is.null(license$max_usage) && !is.null(license$usage_count)) {
      if (license$usage_count >= license$max_usage) {
        return(list(
          status = "exhausted",
          message = paste("试用次数已用完 (", license$usage_count, "/", license$max_usage, ")"),
          usage_count = license$usage_count,
          max_usage = license$max_usage
        ))
      }
    }

    # 授权有效
    return(list(
      status = "active",
      message = "授权有效",
      type = license$type %||% "standard",
      expires_at = license$expires_at,
      usage_count = license$usage_count,
      max_usage = license$max_usage,
      activated_at = license$activated_at,
      user_name = license$user_name
    ))
  }

  return(list(
    status = "active",
    message = "授权有效"
  ))
}

#' 增加使用次数
#' @return 是否成功
increment_usage <- function() {
  # 这个函数在本地记录使用次数
  # 实际使用次数由远程服务器控制
  usage_file <- ".usage_count.rds"
  current_count <- 0
  if (file.exists(usage_file)) {
    current_count <- readRDS(usage_file)
  }
  saveRDS(current_count + 1, usage_file)
  return(TRUE)
}

# =====================================================
# 工具函数
# =====================================================

#' 空值合并运算符
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' 获取授权状态描述
#' @param status 状态码
#' @return 状态描述
get_license_status_text <- function(status) {
  texts <- list(
    active = "✅ 已激活",
    unlicensed = "⚠️ 未激活",
    expired = "❌ 已过期",
    revoked = "❌ 已撤销",
    exhausted = "❌ 次数用完",
    error = "❌ 连接错误"
  )
  return(texts[[status]] %||% status)
}

#' 获取授权类型描述
#' @param type 类型代码
#' @return 类型描述
get_license_type_text <- function(type) {
  texts <- list(
    trial = "试用版 (7天/10次)",
    monthly = "月度版 (30天)",
    quarterly = "季度版 (90天)",
    yearly = "年度版 (365天)",
    permanent = "永久版",
    standard = "标准版"
  )
  return(texts[[type]] %||% type)
}

# =====================================================
# 初始化检查
# =====================================================

# 确保必要的包已加载
ensure_packages <- function() {
  packages <- c("digest", "httr", "jsonlite")
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
  }
}

# 自动加载
ensure_packages()
