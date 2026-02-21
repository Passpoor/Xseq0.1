# =====================================================
# Xseq License Admin Tool - 授权管理工具
# =====================================================
# 用途：管理员添加/管理用户授权
# 使用：在 R 控制台运行 source("license_admin.R")
# =====================================================

library(jsonlite)

# 授权文件路径
LICENSE_FILE <- "licenses.json"

# =====================================================
# 创建新授权
# =====================================================

#' 添加新授权
#' @param machine_code 机器码
#' @param type 授权类型: trial, monthly, quarterly, yearly, permanent
#' @param user_name 用户名称
#' @param notes 备注
add_license <- function(machine_code, type = "monthly", user_name = "", notes = "") {

  # 标准化机器码
  machine_code <- toupper(gsub("[^A-Za-z0-9]", "", machine_code))
  machine_code <- paste(
    substr(machine_code, 1, 4),
    substr(machine_code, 5, 8),
    substr(machine_code, 9, 12),
    substr(machine_code, 13, 16),
    sep = "-"
  )

  # 计算过期时间
  expires_at <- switch(type,
    "trial" = as.character(Sys.Date() + 7),
    "monthly" = as.character(Sys.Date() + 30),
    "quarterly" = as.character(Sys.Date() + 90),
    "yearly" = as.character(Sys.Date() + 365),
    "permanent" = "2099-12-31",
    as.character(Sys.Date() + 30)  # 默认月度
  )

  # 试用版使用次数限制
  max_usage <- if (type == "trial") 10 else NULL

  # 读取现有授权
  licenses <- load_licenses()

  # 检查是否已存在
  existing_index <- NULL
  for (i in seq_along(licenses$licenses)) {
    if (toupper(licenses$licenses[[i]]$machine_code) == machine_code) {
      existing_index <- i
      break
    }
  }

  # 创建新授权
  new_license <- list(
    machine_code = machine_code,
    type = type,
    activated_at = as.character(Sys.Date()),
    expires_at = expires_at,
    usage_count = 0,
    max_usage = max_usage,
    status = "active",
    user_name = user_name,
    notes = notes
  )

  if (!is.null(existing_index)) {
    # 更新现有授权
    cat(sprintf("⚠️  机器码 %s 已存在，将更新授权\n", machine_code))
    licenses$licenses[[existing_index]] <- new_license
  } else {
    # 添加新授权
    licenses$licenses[[length(licenses$licenses) + 1]] <- new_license
    cat(sprintf("✅ 已添加新授权：%s\n", machine_code))
  }

  # 保存
  save_licenses(licenses)

  # 显示授权信息
  cat("\n📋 授权信息：\n")
  cat(sprintf("   机器码：%s\n", machine_code))
  cat(sprintf("   类型：%s\n", get_type_name(type)))
  cat(sprintf("   激活日期：%s\n", new_license$activated_at))
  cat(sprintf("   过期日期：%s\n", expires_at))
  if (type == "trial") {
    cat(sprintf("   使用次数限制：%d 次\n", max_usage))
  }
  cat(sprintf("   用户：%s\n", user_name))
  cat("\n💡 记得将 licenses.json 上传到 GitHub 私有仓库！\n")

  return(licenses)
}

#' 撤销授权
#' @param machine_code 机器码
revoke_license <- function(machine_code) {
  machine_code <- toupper(gsub("[^A-Za-z0-9]", "", machine_code))
  machine_code <- paste(
    substr(machine_code, 1, 4),
    substr(machine_code, 5, 8),
    substr(machine_code, 9, 12),
    substr(machine_code, 13, 16),
    sep = "-"
  )

  licenses <- load_licenses()

  for (i in seq_along(licenses$licenses)) {
    if (toupper(licenses$licenses[[i]]$machine_code) == machine_code) {
      licenses$licenses[[i]]$status <- "revoked"
      licenses$licenses[[i]]$revoked_at <- as.character(Sys.Date())
      cat(sprintf("✅ 已撤销授权：%s\n", machine_code))
      save_licenses(licenses)
      return(licenses)
    }
  }

  cat(sprintf("❌ 未找到机器码：%s\n", machine_code))
  return(licenses)
}

#' 删除授权
#' @param machine_code 机器码
remove_license <- function(machine_code) {
  machine_code <- toupper(gsub("[^A-Za-z0-9]", "", machine_code))
  machine_code <- paste(
    substr(machine_code, 1, 4),
    substr(machine_code, 5, 8),
    substr(machine_code, 9, 12),
    substr(machine_code, 13, 16),
    sep = "-"
  )

  licenses <- load_licenses()

  new_licenses <- list()
  found <- FALSE

  for (i in seq_along(licenses$licenses)) {
    if (toupper(licenses$licenses[[i]]$machine_code) != machine_code) {
      new_licenses[[length(new_licenses) + 1]] <- licenses$licenses[[i]]
    } else {
      found <- TRUE
    }
  }

  if (found) {
    licenses$licenses <- new_licenses
    save_licenses(licenses)
    cat(sprintf("✅ 已删除授权：%s\n", machine_code))
  } else {
    cat(sprintf("❌ 未找到机器码：%s\n", machine_code))
  }

  return(licenses)
}

#' 延长授权
#' @param machine_code 机器码
#' @param days 延长天数
extend_license <- function(machine_code, days = 30) {
  machine_code <- toupper(gsub("[^A-Za-z0-9]", "", machine_code))
  machine_code <- paste(
    substr(machine_code, 1, 4),
    substr(machine_code, 5, 8),
    substr(machine_code, 9, 12),
    substr(machine_code, 13, 16),
    sep = "-"
  )

  licenses <- load_licenses()

  for (i in seq_along(licenses$licenses)) {
    if (toupper(licenses$licenses[[i]]$machine_code) == machine_code) {
      current_expires <- as.Date(licenses$licenses[[i]]$expires_at)
      new_expires <- current_expires + days
      licenses$licenses[[i]]$expires_at <- as.character(new_expires)
      licenses$licenses[[i]]$status <- "active"
      cat(sprintf("✅ 已延长授权：%s\n", machine_code))
      cat(sprintf("   新过期日期：%s (延长 %d 天)\n", new_expires, days))
      save_licenses(licenses)
      return(licenses)
    }
  }

  cat(sprintf("❌ 未找到机器码：%s\n", machine_code))
  return(licenses)
}

#' 列出所有授权
list_licenses <- function() {
  licenses <- load_licenses()

  cat("\n📋 授权列表\n")
  cat("============================================================\n")

  if (length(licenses$licenses) == 0) {
    cat("暂无授权记录\n")
    return(invisible(licenses))
  }

  for (i in seq_along(licenses$licenses)) {
    lic <- licenses$licenses[[i]]
    status_icon <- switch(lic$status,
      "active" = "✅",
      "revoked" = "❌",
      "⚠️"
    )

    cat(sprintf("\n%s [%d] %s\n", status_icon, i, lic$machine_code))
    cat(sprintf("   类型：%s | 状态：%s\n",
                get_type_name(lic$type),
                lic$status))
    cat(sprintf("   激活：%s | 过期：%s\n",
                lic$activated_at %||% "N/A",
                lic$expires_at %||% "N/A"))
    if (!is.null(lic$user_name) && nchar(lic$user_name) > 0) {
      cat(sprintf("   用户：%s\n", lic$user_name))
    }
  }

  cat("\n============================================================\n")
  cat(sprintf("共 %d 条授权记录\n", length(licenses$licenses)))

  return(invisible(licenses))
}

#' 查询授权
#' @param machine_code 机器码
query_license <- function(machine_code) {
  machine_code <- toupper(gsub("[^A-Za-z0-9]", "", machine_code))
  machine_code <- paste(
    substr(machine_code, 1, 4),
    substr(machine_code, 5, 8),
    substr(machine_code, 9, 12),
    substr(machine_code, 13, 16),
    sep = "-"
  )

  licenses <- load_licenses()

  for (i in seq_along(licenses$licenses)) {
    if (toupper(licenses$licenses[[i]]$machine_code) == machine_code) {
      lic <- licenses$licenses[[i]]
      cat("\n📋 授权详情\n")
      cat("============================================================\n")
      cat(sprintf("机器码：%s\n", lic$machine_code))
      cat(sprintf("类型：%s\n", get_type_name(lic$type)))
      cat(sprintf("状态：%s\n", lic$status))
      cat(sprintf("激活日期：%s\n", lic$activated_at %||% "N/A"))
      cat(sprintf("过期日期：%s\n", lic$expires_at %||% "N/A"))
      if (!is.null(lic$max_usage)) {
        cat(sprintf("使用次数：%d / %d\n", lic$usage_count %||% 0, lic$max_usage))
      }
      if (!is.null(lic$user_name) && nchar(lic$user_name) > 0) {
        cat(sprintf("用户：%s\n", lic$user_name))
      }
      if (!is.null(lic$notes) && nchar(lic$notes) > 0) {
        cat(sprintf("备注：%s\n", lic$notes))
      }
      cat("============================================================\n")
      return(invisible(lic))
    }
  }

  cat(sprintf("❌ 未找到机器码：%s\n", machine_code))
  return(invisible(NULL))
}

# =====================================================
# 内部函数
# =====================================================

load_licenses <- function() {
  if (file.exists(LICENSE_FILE)) {
    licenses <- jsonlite::fromJSON(LICENSE_FILE, simplifyVector = FALSE)
    if (is.null(licenses$licenses)) {
      licenses <- list(licenses = licenses)
    }
    return(licenses)
  }
  return(list(
    version = "1.0",
    updated_at = as.character(Sys.Date()),
    contact = "xseq_fastfreee@163.com",
    licenses = list()
  ))
}

save_licenses <- function(licenses) {
  licenses$updated_at <- as.character(Sys.Date())
  json_str <- jsonlite::toJSON(licenses, auto_unbox = TRUE, pretty = TRUE)
  writeLines(json_str, LICENSE_FILE)
  cat(sprintf("💾 已保存到 %s\n", LICENSE_FILE))
}

get_type_name <- function(type) {
  names <- list(
    trial = "试用版 (7天/10次)",
    monthly = "月度版 (30天)",
    quarterly = "季度版 (90天)",
    yearly = "年度版 (365天)",
    permanent = "永久版"
  )
  return(names[[type]] %||% type)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# =====================================================
# 显示帮助
# =====================================================

cat("
╔════════════════════════════════════════════════════════════╗
║           Xseq License Admin Tool v1.0                     ║
║           授权管理工具                                      ║
╠════════════════════════════════════════════════════════════╣
║  可用命令：                                                 ║
║                                                            ║
║  add_license('机器码', '类型', '用户名')                    ║
║    类型: trial / monthly / quarterly / yearly / permanent  ║
║                                                            ║
║  revoke_license('机器码')     - 撤销授权                   ║
║  remove_license('机器码')     - 删除授权                   ║
║  extend_license('机器码', 天数) - 延长授权                 ║
║  query_license('机器码')      - 查询授权                   ║
║  list_licenses()              - 列出所有授权               ║
║                                                            ║
║  示例：                                                     ║
║  add_license('A3F8B2C1D4E5F6A7', 'monthly', '张三')        ║
╚════════════════════════════════════════════════════════════╝
")
