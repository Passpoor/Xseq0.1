/**
 * Toast 通知系统
 * 版本: 2.0
 * 功能: 提供可配置的通知提示
 */

class ToastSystem {
  constructor(options = {}) {
    this.container = null;
    this.toasts = [];
    this.maxToasts = options.maxToasts || 3;
    this.position = options.position || 'top-right';
    this.defaultDuration = options.defaultDuration || 4000;
    this.init();
  }

  /**
   * 初始化 Toast 容器
   */
  init() {
    // 创建或获取容器
    this.container = document.getElementById('toast-container');

    if (!this.container) {
      this.container = document.createElement('div');
      this.container.id = 'toast-container';
      this.container.className = `toast-container ${this.position}`;
      document.body.appendChild(this.container);
    }

    // 添加样式
    this.injectStyles();
  }

  /**
   * 注入样式
   */
  injectStyles() {
    if (document.getElementById('toast-styles')) return;

    const link = document.createElement('link');
    link.id = 'toast-styles';
    link.rel = 'stylesheet';
    link.href = 'css/components/toasts.css';
    document.head.appendChild(link);
  }

  /**
   * 显示 Toast
   * @param {Object} options - Toast 配置
   * @returns {HTMLElement} Toast 元素
   */
  show(options) {
    const config = {
      type: options.type || 'info', // success, error, warning, info
      title: options.title || '',
      message: options.message || '',
      duration: options.duration !== undefined ? options.duration : this.defaultDuration,
      actions: options.actions || [],
      icon: options.icon || null,
      closable: options.closable !== undefined ? options.closable : true,
      loading: options.loading || false
    };

    // 如果超过最大数量,移除最早的
    if (this.toasts.length >= this.maxToasts) {
      this.dismiss(this.toasts[0]);
    }

    // 创建 Toast 元素
    const toast = this.createToast(config);
    this.container.appendChild(toast);
    this.toasts.push(toast);

    // 自动关闭
    if (config.duration > 0 && !config.loading) {
      if (config.progressBar) {
        this.addProgressBar(toast, config.duration);
      }

      setTimeout(() => {
        this.dismiss(toast);
      }, config.duration);
    }

    return toast;
  }

  /**
   * 创建 Toast 元素
   */
  createToast(config) {
    const toast = document.createElement('div');
    toast.className = `toast toast-${config.type}${config.loading ? ' toast-loading' : ''}`;
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'polite');

    // 图标
    const icon = this.getIcon(config.type, config.icon);

    // 内容
    const content = `
      <div class="toast-icon">${icon}</div>
      <div class="toast-content">
        ${config.title ? `<div class="toast-title">${this.escapeHtml(config.title)}</div>` : ''}
        <div class="toast-message">${this.escapeHtml(config.message)}</div>
        ${config.actions.length ? this.renderActions(config.actions) : ''}
      </div>
      ${config.closable ? '<button class="toast-close" aria-label="关闭通知">&times;</button>' : ''}
    `;

    toast.innerHTML = content;

    // 关闭按钮事件
    if (config.closable) {
      const closeBtn = toast.querySelector('.toast-close');
      closeBtn.addEventListener('click', () => {
        this.dismiss(toast);
      });
    }

    // 触摸/点击关闭
    toast.addEventListener('click', (e) => {
      if (e.target.closest('.toast-actions') || e.target.closest('.toast-close')) {
        return;
      }
      // 可选: 点击 Toast 关闭
      // this.dismiss(toast);
    });

    return toast;
  }

  /**
   * 获取图标
   */
  getIcon(type, customIcon) {
    if (customIcon) return customIcon;

    const icons = {
      success: '✅',
      error: '❌',
      warning: '⚠️',
      info: 'ℹ️'
    };

    return icons[type] || icons.info;
  }

  /**
   * 渲染操作按钮
   */
  renderActions(actions) {
    return `
      <div class="toast-actions">
        ${actions.map(action => {
          const btnClass = action.primary ? 'btn-primary' : 'btn-secondary';
          return `<button class="btn-sm ${btnClass}" data-action="${action.id || ''}">${this.escapeHtml(action.label)}</button>`;
        }).join('')}
      </div>
    `;
  }

  /**
   * 添加进度条
   */
  addProgressBar(toast, duration) {
    const progress = document.createElement('div');
    progress.className = 'toast-progress';
    progress.style.animation = `toastProgress ${duration}ms linear`;
    toast.appendChild(progress);
  }

  /**
   * 关闭 Toast
   */
  dismiss(toast) {
    if (!toast || !toast.parentElement) return;

    toast.classList.add('toast-dismissing');

    setTimeout(() => {
      if (toast.parentElement) {
        toast.remove();
      }
      this.toasts = this.toasts.filter(t => t !== toast);
    }, 300); // 等待动画完成
  }

  /**
   * 清除所有 Toast
   */
  clear() {
    this.toasts.forEach(toast => {
      this.dismiss(toast);
    });
  }

  /**
   * 快捷方法: 成功
   */
  success(message, title = '', options = {}) {
    return this.show({
      type: 'success',
      title,
      message,
      ...options
    });
  }

  /**
   * 快捷方法: 错误
   */
  error(message, title = '', options = {}) {
    return this.show({
      type: 'error',
      title,
      message,
      duration: 0, // 错误默认不自动关闭
      ...options
    });
  }

  /**
   * 快捷方法: 警告
   */
  warning(message, title = '', options = {}) {
    return this.show({
      type: 'warning',
      title,
      message,
      ...options
    });
  }

  /**
   * 快捷方法: 信息
   */
  info(message, title = '', options = {}) {
    return this.show({
      type: 'info',
      title,
      message,
      ...options
    });
  }

  /**
   * 显示加载中
   */
  loading(message, title = '', options = {}) {
    return this.show({
      type: 'info',
      title,
      message,
      duration: 0,
      closable: false,
      loading: true,
      ...options
    });
  }

  /**
   * HTML 转义
   */
  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  /**
   * 更新位置
   */
  setPosition(position) {
    this.position = position;
    this.container.className = `toast-container ${this.position}`;
  }
}

// 创建全局实例
const toast = new ToastSystem();

// Shiny 集成
if (typeof Shiny !== 'undefined') {
  Shiny.addCustomMessageHandler('show-toast', (message) => {
    toast.show(message);
  });

  Shiny.addCustomMessageHandler('toast-success', (message) => {
    toast.success(message.message, message.title, message);
  });

  Shiny.addCustomMessageHandler('toast-error', (message) => {
    toast.error(message.message, message.title, message);
  });

  Shiny.addCustomMessageHandler('toast-warning', (message) => {
    toast.warning(message.message, message.title, message);
  });

  Shiny.addCustomMessageHandler('toast-info', (message) => {
    toast.info(message.message, message.title, message);
  });

  Shiny.addCustomMessageHandler('toast-clear', () => {
    toast.clear();
  });
}

// 导出供全局使用
window.toast = toast;
window.ToastSystem = ToastSystem;

// 添加进度条动画
const style = document.createElement('style');
style.textContent = `
  @keyframes toastProgress {
    from {
      transform: scaleX(1);
    }
    to {
      transform: scaleX(0);
    }
  }
`;
document.head.appendChild(style);
