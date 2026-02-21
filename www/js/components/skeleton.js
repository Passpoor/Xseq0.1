/**
 * 骨架屏加载组件
 * Skeleton Loading Component
 * 版本: 1.0
 */

class Skeleton {
  /**
   * 创建文本骨架
   */
  static text(options = {}) {
    const {
      width = '100%',
      height = 'md',
      lines = 1,
      className = ''
    } = options;

    const heights = {
      xs: 'skeleton-text-xs',
      sm: 'skeleton-text-sm',
      md: 'skeleton-text-md',
      lg: 'skeleton-text-lg',
      xl: 'skeleton-text-xl'
    };

    const heightClass = heights[height] || heights.md;

    if (lines === 1) {
      return `<div class="skeleton skeleton-text ${heightClass}" style="width: ${width};"></div>`;
    }

    // 多行文本
    let html = '<div class="skeleton-text-group">';
    for (let i = 0; i < lines; i++) {
      const lineWidth = i === lines - 1 ? '60%' : width;
      html += `<div class="skeleton skeleton-text ${heightClass}" style="width: ${lineWidth};"></div>`;
    }
    html += '</div>';

    return html;
  }

  /**
   * 创建圆形骨架
   */
  static circle(options = {}) {
    const {
      size = 'md',
      className = ''
    } = options;

    const sizes = {
      sm: 'skeleton-avatar-sm',
      md: 'skeleton-avatar-md',
      lg: 'skeleton-avatar-lg',
      xl: 'skeleton-avatar-xl'
    };

    const sizeClass = sizes[size] || sizes.md;

    return `<div class="skeleton skeleton-circle ${sizeClass} ${className}"></div>`;
  }

  /**
   * 创建卡片骨架
   */
  static card(options = {}) {
    const {
      withAvatar = false,
      lines = 3,
      className = ''
    } = options;

    let content = '';

    if (withAvatar) {
      content += `
        <div class="skeleton-card">
          <div style="display: flex; gap: 12px; align-items: flex-start;">
            ${this.circle({ size: 'lg' })}
            <div style="flex: 1;">
              <div class="skeleton skeleton-text skeleton-text-lg skeleton-text-60" style="margin-bottom: 8px;"></div>
              ${this.text({ lines, height: 'sm' })}
            </div>
          </div>
        </div>
      `;
    } else {
      content += `
        <div class="skeleton-card">
          <div class="skeleton-card-header"></div>
          <div class="skeleton-card-body">
            ${this.text({ lines })}
          </div>
        </div>
      `;
    }

    return content;
  }

  /**
   * 创建表格骨架
   */
  static table(options = {}) {
    const {
      rows = 5,
      columns = 4,
      className = ''
    } = options;

    let html = '<div class="skeleton-table-wrapper">';

    // 表头
    html += '<div class="skeleton-table-header" style="display: flex; gap: 16px; padding: 12px; border-bottom: 2px solid var(--border-light);">';
    for (let i = 0; i < columns; i++) {
      html += `<div class="skeleton" style="flex: 1; height: 16px;"></div>`;
    }
    html += '</div>';

    // 表体
    html += '<div class="skeleton-table-body">';
    for (let i = 0; i < rows; i++) {
      html += '<div class="skeleton-table-row" style="display: flex; gap: 16px; padding: 12px; border-bottom: 1px solid var(--border-light);">';
      for (let j = 0; j < columns; j++) {
        const width = j === 0 ? '60px' : '100%';
        html += `<div class="skeleton skeleton-text" style="flex: 1; height: 14px; width: ${width};"></div>`;
      }
      html += '</div>';
    }
    html += '</div>';

    html += '</div>';

    return html;
  }

  /**
   * 创建统计卡片骨架
   */
  static statCard(options = {}) {
    const {
      className = ''
    } = options;

    return `
      <div class="skeleton-stat-card ${className}">
        <div class="skeleton skeleton-circle skeleton-stat-icon"></div>
        <div class="skeleton skeleton-text skeleton-stat-value"></div>
        <div class="skeleton skeleton-text skeleton-stat-label"></div>
      </div>
    `;
  }

  /**
   * 创建图表骨架
   */
  static chart(options = {}) {
    const {
      type = 'bar',
      className = ''
    } = options;

    return `
      <div class="skeleton-chart ${className}">
        <div class="skeleton skeleton-text skeleton-chart-header"></div>
        <div class="skeleton-chart-content">
          <div class="skeleton skeleton-chart-bar"></div>
          <div class="skeleton skeleton-chart-bar"></div>
          <div class="skeleton skeleton-chart-bar"></div>
          <div class="skeleton skeleton-chart-bar"></div>
          <div class="skeleton skeleton-chart-bar"></div>
        </div>
      </div>
    `;
  }

  /**
   * 创建列表骨架
   */
  static list(options = {}) {
    const {
      items = 5,
      withAvatar = true,
      className = ''
    } = options;

    let html = `<div class="skeleton-list ${className}">`;

    for (let i = 0; i < items; i++) {
      html += '<div class="skeleton-list-item">';

      if (withAvatar) {
        html += '<div class="skeleton skeleton-circle skeleton-list-item-avatar"></div>';
      }

      html += `
        <div class="skeleton-list-item-content">
          <div class="skeleton skeleton-text skeleton-text-md skeleton-text-70"></div>
          <div class="skeleton skeleton-text skeleton-text-sm skeleton-text-50"></div>
        </div>
      `;

      html += '</div>';
    }

    html += '</div>';

    return html;
  }

  /**
   * 创建网格骨架
   */
  static grid(options = {}) {
    const {
      items = 6,
      columns = 3,
      cardType = 'default',
      className = ''
    } = options;

    let html = `<div class="skeleton-grid" style="grid-template-columns: repeat(${columns}, 1fr);" class="${className}">`;

    for (let i = 0; i < items; i++) {
      html += '<div class="skeleton-grid-item">';
      html += '<div class="skeleton skeleton-image"></div>';
      html += '<div class="skeleton skeleton-text skeleton-text-lg skeleton-text-80"></div>';
      html += '<div class="skeleton skeleton-text skeleton-text-sm skeleton-text-60"></div>';
      html += '</div>';
    }

    html += '</div>';

    return html;
  }

  /**
   * 创建输入框骨架
   */
  static input(options = {}) {
    const {
      label = true,
      className = ''
    } = options;

    let html = '<div class="skeleton-input-wrapper">';

    if (label) {
      html += '<div class="skeleton skeleton-text skeleton-text-sm skeleton-text-30" style="margin-bottom: 6px;"></div>';
    }

    html += '<div class="skeleton skeleton-input"></div>';
    html += '</div>';

    return html;
  }

  /**
   * 创建按钮骨架
   */
  static button(options = {}) {
    const {
      size = 'md',
      className = ''
    } = options;

    const sizes = {
      sm: 'skeleton-button-sm',
      md: 'skeleton-button-md',
      lg: 'skeleton-button-lg'
    };

    const sizeClass = sizes[size] || sizes.md;

    return `<div class="skeleton ${sizeClass} ${className}"></div>`;
  }

  /**
   * 创建页面骨架
   */
  static page(options = {}) {
    const {
      header = true,
      content = 'grid',
      className = ''
    } = options;

    let html = `<div class="skeleton-page ${className}">`;

    if (header) {
      html += `
        <div class="skeleton-page-header">
          <div class="skeleton skeleton-text skeleton-page-title"></div>
          <div class="skeleton skeleton-text skeleton-page-subtitle"></div>
        </div>
      `;
    }

    html += '<div class="skeleton-page-content">';

    if (content === 'grid') {
      html += this.grid({ items: 6, columns: 3 });
    } else if (content === 'list') {
      html += this.list({ items: 5 });
    } else if (content === 'card') {
      html += this.card();
    }

    html += '</div>';
    html += '</div>';

    return html;
  }

  /**
   * 将元素替换为骨架屏
   */
  static show(element, options = {}) {
    const el = typeof element === 'string'
      ? document.querySelector(element)
      : element;

    if (!el) return;

    // 保存原始内容
    const originalContent = el.innerHTML;
    el.dataset.skeletonOriginal = originalContent;

    // 插入骨架屏
    const type = options.type || 'card';
    el.innerHTML = this[type](options);

    // 添加加载类
    el.classList.add('skeleton-loading');
  }

  /**
   * 移除骨架屏,恢复原始内容
   */
  static hide(element) {
    const el = typeof element === 'string'
      ? document.querySelector(element)
      : element;

    if (!el || !el.dataset.skeletonOriginal) return;

    // 恢复原始内容
    el.innerHTML = el.dataset.skeletonOriginal;
    delete el.dataset.skeletonOriginal;

    // 移除加载类
    el.classList.remove('skeleton-loading');

    // 添加淡入动画
    el.style.opacity = '0';
    requestAnimationFrame(() => {
      el.style.transition = 'opacity 0.3s ease-in';
      el.style.opacity = '1';
    });
  }

  /**
   * 创建自定义骨架屏
   */
  static custom(html) {
    return `<div class="skeleton-wrapper">${html}</div>`;
  }
}

// Shiny 集成
if (typeof Shiny !== 'undefined') {
  Shiny.addCustomMessageHandler('skeleton-show', (message) => {
    const { selector, type = 'card', options = {} } = message;
    Skeleton.show(selector, { type, ...options });
  });

  Shiny.addCustomMessageHandler('skeleton-hide', (message) => {
    const { selector } = message;
    Skeleton.hide(selector);
  });
}

// 导出供全局使用
window.Skeleton = Skeleton;
