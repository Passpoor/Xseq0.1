#!/bin/bash

echo "================================================"
echo "   RNAseq分析工具 v8.1 - 启动脚本"
echo "================================================"
echo

# 检查R是否安装
if ! command -v R &> /dev/null; then
    echo "错误: 未找到R程序"
    echo "请先安装R: https://cran.r-project.org/"
    exit 1
fi

echo "正在启动RNAseq分析工具..."
echo

# 运行应用
R -e "shiny::runApp('app.R', launch.browser=TRUE)"