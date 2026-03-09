import re

# 读取文件
with open(r'D:\cherry_code\Biofree_project11.2\Biofree_project\modules\chip_analysis.R', 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

print('=== 检查芯片分析模块代码 ===\n')

# 检查关键代码
print('检查关键代码:')

# 1. 检查UI部分
ui_found = any('uiOutput("chip_soft_column_selection_panel")' in line for line in lines)
print('✅ UI部分: ' + ('找到' if ui_found else '未找到') + ' uiOutput')

# 2. 检查Server部分
server_found = any('output$chip_soft_column_selection_panel <- renderUI' in line for line in lines)
print('✅ Server部分: ' + ('找到' if server_found else '未找到') + ' renderUI定义')

# 3. 检查selectInput
select_id = any('selectInput("chip_soft_id_col"' in line for line in lines)
select_gene = any('selectInput("chip_soft_gene_col"' in line for line in lines)
print('✅ selectInput: ' + ('找到' if (select_id and select_gene) else '未找到') + ' 直接生成的selectInput')

# 显示关键行
print('\n关键代码位置:')
for i, line in enumerate(lines, 1):
    if 'uiOutput("chip_soft_column_selection_panel")' in line:
        print(f'  第{i}行 (UI): {line.strip()}')
    if 'output$chip_soft_column_selection_panel <- renderUI' in line:
        print(f'  第{i}行 (Server): {line.strip()}')
    if 'selectInput("chip_soft_id_col"' in line or 'selectInput("chip_soft_gene_col"' in line:
        print(f'  第{i}行 (selectInput): {line.strip()}')

result = '✅ 全部通过' if (ui_found and server_found and select_id and select_gene) else '❌ 检查失败'
print(f'\n=== 结果: {result} ===')

if ui_found and server_found and select_id and select_gene:
    print('\n请完全重启应用后测试！')
