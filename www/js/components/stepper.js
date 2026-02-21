/**
 * 步骤指示器组件
 * Stepper Component
 * 版本: 1.0
 */

class Stepper {
  constructor(elementId, options = {}) {
    this.element = document.getElementById(elementId);
    if (!this.element) {
      console.error(`Stepper: Element with id "${elementId}" not found`);
      return;
    }

    this.steps = options.steps || [];
    this.currentStep = 0;
    this.orientation = options.orientation || 'horizontal'; // horizontal, vertical
    this.clickable = options.clickable !== undefined ? options.clickable : true;
    this.onStepChange = options.onStepChange || null;
    this.onNext = options.onNext || null;
    this.onBack = options.onBack || null;
    this.onComplete = options.onComplete || null;
    this.showStepNumbers = options.showStepNumbers !== undefined ? options.showStepNumbers : true;

    this.init();
  }

  /**
   * 初始化步骤指示器
   */
  init() {
    this.render();
    this.attachListeners();
    this.updateState();
  }

  /**
   * 渲染步骤指示器
   */
  render() {
    const isVertical = this.orientation === 'vertical';
    const clickableClass = this.clickable ? 'stepper-clickable' : '';

    this.element.className = `stepper stepper-${this.orientation} ${clickableClass}`;

    this.element.innerHTML = `
      <div class="stepper-track"></div>
      <div class="stepper-progress" style="width: 0%"></div>
      <div class="stepper-steps">
        ${this.steps.map((step, index) => `
          <div class="stepper-step"
               data-step="${index}"
               ${this.clickable ? 'tabindex="0"' : ''}>
            <div class="stepper-indicator" data-step="${index + 1}">
              ${this.renderIndicator(step, index)}
            </div>
            <div class="stepper-label">
              <div class="stepper-title">${this.escapeHtml(step.title)}</div>
              ${step.subtitle ? `<div class="stepper-subtitle">${this.escapeHtml(step.subtitle)}</div>` : ''}
            </div>
          </div>
        `).join('')}
      </div>
      <div class="stepper-content"></div>
      <div class="stepper-actions">
        <div class="stepper-actions-left">
          <button type="button" class="btn btn-secondary" id="stepper-back">
            ← 上一步
          </button>
        </div>
        <div class="stepper-actions-right">
          <button type="button" class="btn btn-primary" id="stepper-next">
            下一步 →
          </button>
        </div>
      </div>
    `;
  }

  /**
   * 渲染步骤指示器图标
   */
  renderIndicator(step, index) {
    if (step.icon) {
      return `<span data-icon="${step.icon}"></span>`;
    }
    return '';
  }

  /**
   * 附加事件监听器
   */
  attachListeners() {
    // 步骤点击事件
    if (this.clickable) {
      const stepElements = this.element.querySelectorAll('.stepper-step');
      stepElements.forEach((stepEl, index) => {
        stepEl.addEventListener('click', () => {
          this.goToStep(index);
        });

        stepEl.addEventListener('keydown', (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            this.goToStep(index);
          }
        });
      });
    }

    // 上一步按钮
    const backBtn = this.element.querySelector('#stepper-back');
    if (backBtn) {
      backBtn.addEventListener('click', () => {
        this.back();
      });
    }

    // 下一步按钮
    const nextBtn = this.element.querySelector('#stepper-next');
    if (nextBtn) {
      nextBtn.addEventListener('click', () => {
        this.next();
      });
    }
  }

  /**
   * 更新步骤状态
   */
  updateState() {
    const steps = this.element.querySelectorAll('.stepper-step');
    const progressBar = this.element.querySelector('.stepper-progress');

    // 更新进度条
    const progress = (this.currentStep / (this.steps.length - 1)) * 100;
    if (progressBar) {
      progressBar.style.width = `${progress}%`;
    }

    // 更新步骤状态
    steps.forEach((step, index) => {
      step.classList.remove('pending', 'active', 'completed', 'error');

      if (index < this.currentStep) {
        step.classList.add('completed');
      } else if (index === this.currentStep) {
        step.classList.add('active');
      } else {
        step.classList.add('pending');
      }

      // 更新指示器内容
      const indicator = step.querySelector('.stepper-indicator');
      if (index < this.currentStep) {
        // 已完成 - 显示 ✓
        indicator.textContent = '';
      } else if (index === this.currentStep) {
        // 当前 - 显示步骤号
        indicator.textContent = this.showStepNumbers ? (index + 1) : '';
        if (this.steps[index].icon) {
          indicator.innerHTML = `<span data-icon="${this.steps[index].icon}"></span>`;
        }
      } else {
        // 待处理 - 显示步骤号
        indicator.textContent = this.showStepNumbers ? (index + 1) : '';
      }
    });

    // 更新按钮状态
    this.updateButtons();

    // 触发回调
    if (this.onStepChange) {
      this.onStepChange(this.currentStep, this.steps[this.currentStep]);
    }
  }

  /**
   * 更新按钮状态
   */
  updateButtons() {
    const backBtn = this.element.querySelector('#stepper-back');
    const nextBtn = this.element.querySelector('#stepper-next');

    if (backBtn) {
      backBtn.disabled = this.currentStep === 0;
    }

    if (nextBtn) {
      const isLastStep = this.currentStep === this.steps.length - 1;
      nextBtn.textContent = isLastStep ? '完成' : '下一步 →';
      nextBtn.classList.toggle('btn-success', isLastStep);
    }
  }

  /**
   * 下一步
   */
  async next() {
    if (this.currentStep < this.steps.length - 1) {
      // 如果有回调,等待回调结果
      if (this.onNext) {
        const canProceed = await this.onNext(this.currentStep, this.steps[this.currentStep]);
        if (canProceed === false) return;
      }

      this.currentStep++;
      this.updateState();
      this.showPane(this.currentStep);
    } else {
      // 完成所有步骤
      if (this.onComplete) {
        this.onComplete();
      }
    }
  }

  /**
   * 上一步
   */
  back() {
    if (this.currentStep > 0) {
      if (this.onBack) {
        this.onBack(this.currentStep, this.steps[this.currentStep]);
      }

      this.currentStep--;
      this.updateState();
      this.showPane(this.currentStep);
    }
  }

  /**
   * 跳转到指定步骤
   */
  goToStep(index) {
    if (!this.clickable) return;
    if (index < 0 || index >= this.steps.length) return;

    this.currentStep = index;
    this.updateState();
    this.showPane(this.currentStep);
  }

  /**
   * 显示指定步骤的内容面板
   */
  showPane(index) {
    const contentContainer = this.element.querySelector('.stepper-content');

    if (!contentContainer) return;

    // 隐藏所有面板
    const panes = contentContainer.querySelectorAll('.stepper-pane');
    panes.forEach(pane => pane.classList.remove('active'));

    // 显示当前面板
    let currentPane = contentContainer.querySelector(`[data-pane="${index}"]`);
    if (!currentPane) {
      // 创建新面板
      currentPane = document.createElement('div');
      currentPane.className = 'stepper-pane';
      currentPane.dataset.pane = index;
      currentPane.innerHTML = this.steps[index].content || '';

      if (this.steps[index].template) {
        currentPane.innerHTML = this.steps[index].template;
      }

      contentContainer.appendChild(currentPane);
    }

    currentPane.classList.add('active');

    // 触发步骤内容显示事件
    if (this.steps[index].onShow) {
      this.steps[index].onShow(currentPane);
    }
  }

  /**
   * 设置步骤内容
   */
  setStepContent(index, content) {
    if (index < 0 || index >= this.steps.length) return;

    const contentContainer = this.element.querySelector('.stepper-content');
    if (!contentContainer) return;

    let pane = contentContainer.querySelector(`[data-pane="${index}"]`);
    if (!pane) {
      pane = document.createElement('div');
      pane.className = 'stepper-pane';
      pane.dataset.pane = index;
      contentContainer.appendChild(pane);
    }

    pane.innerHTML = content;

    if (index === this.currentStep) {
      pane.classList.add('active');
    }
  }

  /**
   * 添加步骤
   */
  addStep(step) {
    this.steps.push(step);
    this.render();
    this.attachListeners();
    this.updateState();
  }

  /**
   * 移除步骤
   */
  removeStep(index) {
    if (index < 0 || index >= this.steps.length) return;

    this.steps.splice(index, 1);

    if (this.currentStep >= this.steps.length) {
      this.currentStep = this.steps.length - 1;
    }

    this.render();
    this.attachListeners();
    this.updateState();
  }

  /**
   * 禁用步骤
   */
  disableStep(index) {
    const stepEl = this.element.querySelector(`[data-step="${index}"]`);
    if (stepEl) {
      stepEl.classList.add('disabled');
    }
  }

  /**
   * 启用步骤
   */
  enableStep(index) {
    const stepEl = this.element.querySelector(`[data-step="${index}"]`);
    if (stepEl) {
      stepEl.classList.remove('disabled');
    }
  }

  /**
   * 标记步骤为错误状态
   */
  markStepError(index) {
    const stepEl = this.element.querySelector(`[data-step="${index}"]`);
    if (stepEl) {
      stepEl.classList.remove('completed', 'active');
      stepEl.classList.add('error');
    }
  }

  /**
   * 清除步骤错误状态
   */
  clearStepError(index) {
    const stepEl = this.element.querySelector(`[data-step="${index}"]`);
    if (stepEl) {
      stepEl.classList.remove('error');
    }
  }

  /**
   * 重置步骤指示器
   */
  reset() {
    this.currentStep = 0;
    this.updateState();
    this.showPane(0);
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
   * 销毁步骤指示器
   */
  destroy() {
    this.element.innerHTML = '';
    this.steps = [];
    this.currentStep = 0;
  }
}

// Shiny 集成
if (typeof Shiny !== 'undefined') {
  Shiny.addCustomMessageHandler('stepper-next', (message) => {
    const { id } = message;
    const stepperElement = document.getElementById(id);
    if (stepperElement && stepperElement.stepperInstance) {
      stepperElement.stepperInstance.next();
    }
  });

  Shiny.addCustomMessageHandler('stepper-back', (message) => {
    const { id } = message;
    const stepperElement = document.getElementById(id);
    if (stepperElement && stepperElement.stepperInstance) {
      stepperElement.stepperInstance.back();
    }
  });

  Shiny.addCustomMessageHandler('stepper-go-to', (message) => {
    const { id, step } = message;
    const stepperElement = document.getElementById(id);
    if (stepperElement && stepperElement.stepperInstance) {
      stepperElement.stepperInstance.goToStep(step);
    }
  });

  Shiny.addCustomMessageHandler('stepper-reset', (message) => {
    const { id } = message;
    const stepperElement = document.getElementById(id);
    if (stepperElement && stepperElement.stepperInstance) {
      stepperElement.stepperInstance.reset();
    }
  });
}

// 导出供全局使用
window.Stepper = Stepper;

// 自动初始化
document.addEventListener('DOMContentLoaded', () => {
  const stepperElements = document.querySelectorAll('[data-stepper]');
  stepperElements.forEach(element => {
    const stepsData = element.dataset.steps;
    if (stepsData) {
      try {
        const steps = JSON.parse(stepsData);
        const stepper = new Stepper(element.id, { steps });
        element.stepperInstance = stepper;
      } catch (e) {
        console.error('Failed to parse stepper steps:', e);
      }
    }
  });
});
