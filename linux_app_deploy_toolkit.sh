#!/bin/bash

# 创建目录
mkdir -p app_deploy_toolkit

# 创建脚本文件
cat > app_deploy_toolkit/install_dependencies.sh << 'EOF'
#!/bin/bash

# 输出彩色文本的函数 - 移到脚本开头
print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_red() {
    echo -e "\e[31m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

# 脚本信息
SCRIPT_VERSION="1.0.0"
SCRIPT_DATE="2025-06-15"
SCRIPT_AUTHOR="Romy"
SCRIPT_NAME="应用依赖安装工具"

# 显示脚本信息
print_script_info() {
    echo "----------------------------------------"
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "作者: ${SCRIPT_AUTHOR}"
    echo "日期: ${SCRIPT_DATE}"
    echo "----------------------------------------"
    echo "使用 --help 参数查看使用说明"
    echo "----------------------------------------"
}

# 自检功能
check_environment() {
    print_yellow "正在检查环境..."
    
    # 检查是否为root用户或使用sudo
    if [ "$EUID" -ne 0 ]; then
        print_red "错误: 此脚本需要root权限。请使用sudo运行。"
        exit 1
    fi
    
    # 检查apt是否可用
    if ! command -v apt-get &> /dev/null; then
        print_red "错误: 此脚本需要apt包管理器。仅支持Debian/Ubuntu系统。"
        exit 1
    fi
    
    # 检查pip是否可用
    if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
        print_yellow "警告: 未检测到pip。将尝试安装..."
        sudo apt-get install -y python3-pip
        if [ $? -ne 0 ]; then
            print_red "错误: 无法安装pip。请手动安装后重试。"
            exit 1
        fi
    fi
    
    print_green "环境检查通过！"
}

# 检查命令执行状态
check_status() {
    if [ $? -eq 0 ]; then
        print_green "✅ $1 成功"
    else
        print_red "❌ $1 失败"
        exit 1
    fi
}

# 在解析参数前显示脚本信息并检查环境
print_script_info
check_environment

# 默认配置（可通过参数覆盖）
APP_NAME="myapp"
APP_DIR="/root/${APP_NAME}"
DATA_DIR="${APP_DIR}/data"
CONFIG_FILE="${APP_DIR}/config.json"
SCRIPT_PATH="/root/${APP_NAME}.py"
PYTHON_PACKAGES="requests"
SYSTEM_PACKAGES="wget"
BROWSER_INSTALL="false"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --app-name)
      APP_NAME="$2"
      shift 2
      ;;
    --app-dir)
      APP_DIR="$2"
      shift 2
      ;;
    --data-dir)
      DATA_DIR="$2"
      shift 2
      ;;
    --script-path)
      SCRIPT_PATH="$2"
      shift 2
      ;;
    --python-packages)
      PYTHON_PACKAGES="$2"
      shift 2
      ;;
    --system-packages)
      SYSTEM_PACKAGES="$2"
      shift 2
      ;;
    --install-browser)
      BROWSER_INSTALL="true"
      shift
      ;;
    --help)
      cat << HELP_TEXT
使用方法: $0 [选项]

描述:
  此脚本用于安装应用程序所需的依赖项，创建必要的目录结构，
  并设置基本配置。适用于Python应用、爬虫和网络服务等。

选项:
  --app-name NAME          应用名称 (默认: myapp)
  --app-dir DIR            应用目录 (默认: /root/应用名称)
  --data-dir DIR           数据目录 (默认: 应用目录/data)
  --script-path PATH       主脚本路径 (默认: /root/应用名称.py)
  --python-packages PKGS   Python包列表，空格分隔 (默认: requests)
                           例如: "selenium requests pandas"
  --system-packages PKGS   系统包列表，空格分隔 (默认: wget)
                           例如: "wget curl unzip"
  --install-browser        安装Chrome和ChromeDriver (默认: 不安装)
  --help                   显示此帮助信息

示例:
  # 基本用法
  sudo bash $0 --app-name myapp

  # 安装爬虫应用
  sudo bash $0 --app-name scraper --python-packages "selenium requests" --install-browser

  # 完整配置
  sudo bash $0 \\
    --app-name hkex_scraper \\
    --app-dir /root/hkex_pdfs \\
    --script-path /root/hkex_scraper.py \\
    --python-packages "selenium requests" \\
    --system-packages "wget unzip" \\
    --install-browser
HELP_TEXT
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

# 更新配置文件路径
CONFIG_FILE="${APP_DIR}/config.json"

# 显示安装开始信息
print_green "=== 开始安装 ${APP_NAME} 所需依赖 ==="
print_yellow "应用名称: ${APP_NAME}"
print_yellow "应用目录: ${APP_DIR}"
print_yellow "数据目录: ${DATA_DIR}"
print_yellow "主脚本: ${SCRIPT_PATH}"
print_yellow "Python包: ${PYTHON_PACKAGES}"
print_yellow "系统包: ${SYSTEM_PACKAGES}"
print_yellow "安装浏览器: ${BROWSER_INSTALL}"

# 更新包管理器
print_green "正在更新系统包..."
sudo apt-get update
check_status "系统包更新"

# 安装必要的系统依赖
if [ ! -z "${SYSTEM_PACKAGES}" ]; then
    print_green "正在安装系统依赖: ${SYSTEM_PACKAGES}..."
    sudo apt-get install -y ${SYSTEM_PACKAGES}
    check_status "系统依赖安装"
fi

# 安装 Python 包
if [ ! -z "${PYTHON_PACKAGES}" ]; then
    print_green "正在安装 Python 依赖包: ${PYTHON_PACKAGES}..."
    pip install ${PYTHON_PACKAGES}
    check_status "Python 依赖安装"
fi

# 安装浏览器（如果需要）
if [ "${BROWSER_INSTALL}" = "true" ]; then
    # 检查 Chrome 是否已安装
    if ! command -v google-chrome &> /dev/null; then
        print_green "正在安装 Chrome..."
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install -y ./google-chrome-stable_current_amd64.deb
        check_status "Chrome 安装"
        
        # 清理安装包
        rm google-chrome-stable_current_amd64.deb
    else
        print_green "Chrome 已安装，跳过安装步骤"
    fi

    # 安装 ChromeDriver
    print_green "正在安装 ChromeDriver..."
    sudo apt-get install -y chromium-chromedriver
    check_status "ChromeDriver 安装"

    # 验证 Chrome 和 ChromeDriver 版本兼容性
    chrome_version=$(google-chrome --version | awk '{print $3}' | cut -d. -f1)
    driver_version=$(chromedriver --version | awk '{print $2}' | cut -d. -f1)
    print_green "Chrome版本: $chrome_version, ChromeDriver版本: $driver_version"
fi

# 创建目录结构
print_green "正在创建目录结构..."
mkdir -p "${DATA_DIR}"
check_status "目录创建"

# 创建配置文件
print_green "正在创建配置文件..."
if [ ! -f "${CONFIG_FILE}" ]; then
    cat > "${CONFIG_FILE}" << EOF
{
    "app_name": "${APP_NAME}",
    "data_path": "${DATA_DIR}",
    "settings": {
        "debug": false,
        "max_retries": 3,
        "delay_between_requests": 2
    }
}
EOF
    check_status "配置文件创建"
else
    print_green "配置文件已存在，跳过创建"
fi

# 设置脚本和目录权限
print_green "正在设置权限..."
if [ -f "${SCRIPT_PATH}" ]; then
    chmod 755 "${SCRIPT_PATH}"
    check_status "脚本权限设置"
else
    print_red "⚠️ 主脚本 ${SCRIPT_PATH} 不存在，请确保上传该文件"
fi

chmod -R 755 "${APP_DIR}"
check_status "目录权限设置"

# 安装完成
print_green "=== ${APP_NAME} 依赖安装完成 ==="
print_green "目录结构:"
print_green "  - 主脚本: ${SCRIPT_PATH}"
print_green "  - 配置文件: ${CONFIG_FILE}"
print_green "  - 数据目录: ${DATA_DIR}"
print_green ""
print_green "现在您可以运行 install_service.sh 脚本来设置系统服务:"
print_green "bash install_service.sh --app-name ${APP_NAME} --script-path ${SCRIPT_PATH} --app-dir ${APP_DIR}"

EOF

cat > app_deploy_toolkit/install_service.sh << 'EOF'
#!/bin/bash

# 输出彩色文本的函数 - 移到脚本开头
print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_red() {
    echo -e "\e[31m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

# 检查命令执行状态
check_status() {
    if [ $? -eq 0 ]; then
        print_green "✅ $1 成功"
    else
        print_red "❌ $1 失败"
        exit 1
    fi
}

# 脚本信息
SCRIPT_VERSION="1.0.0"
SCRIPT_DATE="2025-06-15"
SCRIPT_AUTHOR="Romy"
SCRIPT_NAME="应用服务安装工具"

# 自检功能
check_environment() {
    print_yellow "正在检查环境..."
    
    # 检查是否为root用户或使用sudo
    if [ "$EUID" -ne 0 ]; then
        print_red "错误: 此脚本需要root权限。请使用sudo运行。"
        exit 1
    fi
    
    # 检查systemd是否可用
    if ! command -v systemctl &> /dev/null; then
        print_red "错误: 此脚本需要systemd。不支持当前系统。"
        exit 1
    fi
    
    print_green "环境检查通过！"
}

# 显示脚本信息
print_script_info() {
    echo "----------------------------------------"
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "作者: ${SCRIPT_AUTHOR}"
    echo "日期: ${SCRIPT_DATE}"
    echo "----------------------------------------"
    echo "使用 --help 参数查看使用说明"
    echo "----------------------------------------"
}

# 在解析参数前显示脚本信息并检查环境
print_script_info
check_environment

# 默认配置（可通过参数覆盖）
APP_NAME="myapp"
APP_DIR="/root/${APP_NAME}"
SCRIPT_PATH="/root/${APP_NAME}.py"
APP_SHORT_NAME="${APP_NAME:0:5}"
DESCRIPTION="${APP_NAME} service"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --app-name)
      APP_NAME="$2"
      APP_SHORT_NAME="${APP_NAME:0:5}"
      shift 2
      ;;
    --app-dir)
      APP_DIR="$2"
      shift 2
      ;;
    --script-path)
      SCRIPT_PATH="$2"
      shift 2
      ;;
    --short-name)
      APP_SHORT_NAME="$2"
      shift 2
      ;;
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    --help)
      cat << HELP_TEXT
使用方法: $0 [选项]

描述:
  此脚本用于将Python应用程序设置为系统服务，创建必要的
  systemd服务文件，并生成便捷的管理命令。适用于需要持续
  运行的应用程序，如爬虫、API服务等。

选项:
  --app-name NAME       应用名称 (默认: myapp)
  --app-dir DIR         应用目录 (默认: /root/应用名称)
  --script-path PATH    主脚本路径 (默认: /root/应用名称.py)
  --short-name NAME     短名称，用于日志标识 (默认: 应用名称前5个字符)
  --description DESC    服务描述 (默认: 应用名称 service)
  --help                显示此帮助信息

示例:
  # 基本用法
  sudo bash $0 --app-name myapp

  # 完整配置
  sudo bash $0 \\
    --app-name hkex_scraper \\
    --app-dir /root/hkex_pdfs \\
    --script-path /root/hkex_scraper.py \\
    --short-name hkex \\
    --description "HKEX PDF Scraper Service"

注意:
  此脚本创建的服务将在系统启动时自动启动，并在崩溃时自动重启。
  脚本还会创建以下管理命令:
    - {应用名称}start   : 启动服务
    - {应用名称}stop    : 停止服务
    - {应用名称}restart : 重启服务
    - {应用名称}status  : 查看服务状态
    - {应用名称}log     : 查看服务日志
HELP_TEXT
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

# 显示安装开始信息
print_green "=== 开始为 ${APP_NAME} 创建系统服务 ==="
print_yellow "应用名称: ${APP_NAME}"
print_yellow "应用目录: ${APP_DIR}"
print_yellow "主脚本: ${SCRIPT_PATH}"
print_yellow "短名称: ${APP_SHORT_NAME}"
print_yellow "服务描述: ${DESCRIPTION}"

# 步骤1：创建Systemd服务文件
print_green "正在创建服务文件: /etc/systemd/system/${APP_NAME}.service..."
sudo tee /etc/systemd/system/${APP_NAME}.service > /dev/null << EOT
[Unit]
Description=${DESCRIPTION}
After=network.target

[Service]
User=root
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/python3 ${SCRIPT_PATH}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${APP_SHORT_NAME}
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOT
check_status "创建服务文件"

# 注册服务
print_green "正在注册服务..."
sudo systemctl daemon-reload
check_status "重新加载systemd配置"

sudo systemctl enable ${APP_NAME}.service
check_status "启用服务"

# 步骤2：启动脚本
print_green "正在创建启动脚本: /usr/local/bin/${APP_NAME}start..."
sudo tee /usr/local/bin/${APP_NAME}start > /dev/null << EOT
#!/bin/bash
echo "正在启动 ${APP_NAME} 服务..."
sudo systemctl start ${APP_NAME}.service
sleep 2
status=\$(sudo systemctl is-active ${APP_NAME}.service)
if [ "\$status" = "active" ]; then
    echo "✅ ${APP_NAME} 服务已成功启动！"
    echo "使用 '${APP_NAME}log' 查看日志"
    echo "使用 '${APP_NAME}status' 查看状态"
else
    echo "❌ ${APP_NAME} 服务启动失败。使用 '${APP_NAME}log' 查看错误日志。"
fi
EOT
check_status "创建启动脚本"

# 步骤3：停止脚本
print_green "正在创建停止脚本: /usr/local/bin/${APP_NAME}stop..."
sudo tee /usr/local/bin/${APP_NAME}stop > /dev/null << EOT
#!/bin/bash
echo "正在停止 ${APP_NAME} 服务..."
sudo systemctl stop ${APP_NAME}.service
sleep 2
status=\$(sudo systemctl is-active ${APP_NAME}.service)
if [ "\$status" = "inactive" ]; then
    echo "✅ ${APP_NAME} 服务已成功停止！"
else
    echo "❌ 无法停止 ${APP_NAME} 服务。尝试强制终止..."
    pid=\$(pgrep -f "python ${SCRIPT_PATH}")
    if [ -n "\$pid" ]; then
        sudo kill -9 \$pid
        echo "✅ 已强制终止 ${APP_NAME} 进程。"
    else
        echo "⚠️ 未找到 ${APP_NAME} 进程。"
    fi
fi
EOT
check_status "创建停止脚本"

# 步骤4：日志脚本
print_green "正在创建日志脚本: /usr/local/bin/${APP_NAME}log..."
sudo tee /usr/local/bin/${APP_NAME}log > /dev/null << EOT
#!/bin/bash
echo "显示 ${APP_NAME} 服务实时日志 (按 Ctrl+C 退出)..."
echo "-------------------------------------------"
sudo journalctl -u ${APP_NAME}.service -f
EOT
check_status "创建日志脚本"

# 步骤5：状态脚本
print_green "正在创建状态脚本: /usr/local/bin/${APP_NAME}status..."
sudo tee /usr/local/bin/${APP_NAME}status > /dev/null << EOT
#!/bin/bash
echo "${APP_NAME} 服务状态:"
echo "----------------"
sudo systemctl status ${APP_NAME}.service
EOT
check_status "创建状态脚本"

# 步骤6：重启脚本
print_green "正在创建重启脚本: /usr/local/bin/${APP_NAME}restart..."
sudo tee /usr/local/bin/${APP_NAME}restart > /dev/null << EOT
#!/bin/bash
echo "正在重启 ${APP_NAME} 服务..."
sudo systemctl restart ${APP_NAME}.service
sleep 2
status=\$(sudo systemctl is-active ${APP_NAME}.service)
if [ "\$status" = "active" ]; then
    echo "✅ ${APP_NAME} 服务已成功重启！"
    echo "使用 '${APP_NAME}log' 查看日志"
else
    echo "❌ ${APP_NAME} 服务重启失败。使用 '${APP_NAME}log' 查看错误日志。"
fi
EOT
check_status "创建重启脚本"

# 步骤7：赋予脚本权限
print_green "正在设置脚本权限..."
sudo chmod +x /usr/local/bin/${APP_NAME}start
sudo chmod +x /usr/local/bin/${APP_NAME}stop
sudo chmod +x /usr/local/bin/${APP_NAME}log
sudo chmod +x /usr/local/bin/${APP_NAME}status
sudo chmod +x /usr/local/bin/${APP_NAME}restart
check_status "设置脚本权限"

# 安装完成
print_green "=== ${APP_NAME} 服务安装完成 ==="
print_green "使用以下命令管理服务:"
print_green "  ${APP_NAME}start   - 启动服务"
print_green "  ${APP_NAME}stop    - 停止服务"
print_green "  ${APP_NAME}restart - 重启服务"
print_green "  ${APP_NAME}status  - 查看服务状态"
print_green "  ${APP_NAME}log     - 查看服务日志"
print_green ""
print_green "现在您可以运行以下命令启动服务:"
print_green "${APP_NAME}start"

EOF

cat > app_deploy_toolkit/setup_wizard.sh << 'EOF'
#!/bin/bash

# 彩色输出函数
print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

print_blue() {
    echo -e "\e[34m$1\e[0m"
}

print_red() {
    echo -e "\e[31m$1\e[0m"
}

# 检查脚本是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    print_red "错误: 此脚本需要root权限。请使用sudo运行。"
    exit 1
fi

# 检查依赖脚本是否存在
if [ ! -f "install_dependencies.sh" ] || [ ! -f "install_service.sh" ]; then
    print_red "错误: 未找到必要的安装脚本。请确保 install_dependencies.sh 和 install_service.sh 在当前目录。"
    exit 1
fi

# 显示欢迎信息
clear
print_blue "=================================================="
print_blue "           应用部署向导                           "
print_blue "=================================================="
echo ""
print_yellow "这个向导将帮助您配置和部署Python应用程序。"
echo ""

# 收集基本信息
read -p "请输入应用名称 (默认: myapp): " APP_NAME
APP_NAME=${APP_NAME:-myapp}

read -p "请输入应用目录 (默认: /root/${APP_NAME}): " APP_DIR
APP_DIR=${APP_DIR:-/root/${APP_NAME}}

read -p "请输入主脚本路径 (默认: /root/${APP_NAME}.py): " SCRIPT_PATH
SCRIPT_PATH=${SCRIPT_PATH:-/root/${APP_NAME}.py}

read -p "请输入Python包列表 (空格分隔，默认: requests): " PYTHON_PACKAGES
PYTHON_PACKAGES=${PYTHON_PACKAGES:-requests}

read -p "请输入系统包列表 (空格分隔，默认: wget): " SYSTEM_PACKAGES
SYSTEM_PACKAGES=${SYSTEM_PACKAGES:-wget}

read -p "是否需要安装Chrome和ChromeDriver？(y/n，默认: n): " INSTALL_BROWSER
INSTALL_BROWSER=${INSTALL_BROWSER:-n}

BROWSER_FLAG=""
if [[ $INSTALL_BROWSER == "y" || $INSTALL_BROWSER == "Y" ]]; then
    BROWSER_FLAG="--install-browser"
fi

# 确认信息
echo ""
print_yellow "请确认以下信息:"
echo "应用名称: ${APP_NAME}"
echo "应用目录: ${APP_DIR}"
echo "主脚本路径: ${SCRIPT_PATH}"
echo "Python包: ${PYTHON_PACKAGES}"
echo "系统包: ${SYSTEM_PACKAGES}"
echo "安装浏览器: ${INSTALL_BROWSER}"
echo ""

read -p "是否继续？(y/n，默认: y): " CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "已取消安装。"
    exit 0
fi

# 创建应用目录（如果不存在）
if [ ! -d "$APP_DIR" ]; then
    print_yellow "创建应用目录: $APP_DIR"
    mkdir -p "$APP_DIR"
    if [ $? -ne 0 ]; then
        print_red "错误: 无法创建目录 $APP_DIR"
        exit 1
    fi
fi

# 检查主脚本是否存在
if [ ! -f "$SCRIPT_PATH" ]; then
    print_yellow "注意: 主脚本 $SCRIPT_PATH 不存在。"
    read -p "是否创建一个示例脚本？(y/n，默认: y): " CREATE_SCRIPT
    CREATE_SCRIPT=${CREATE_SCRIPT:-y}
    
    if [[ $CREATE_SCRIPT == "y" || $CREATE_SCRIPT == "Y" ]]; then
        print_yellow "创建示例脚本: $SCRIPT_PATH"
        cat > "$SCRIPT_PATH" << EOT
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
${APP_NAME} - 示例应用
创建日期: $(date +%Y-%m-%d)
"""

import os
import time
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('${APP_NAME}')

def main():
    """主函数"""
    logger.info("应用启动")
    
    try:
        # 应用主循环
        while True:
            logger.info("应用正在运行...")
            time.sleep(60)  # 每分钟记录一次
            
    except KeyboardInterrupt:
        logger.info("接收到中断信号，应用退出")
    except Exception as e:
        logger.error(f"发生错误: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main())
EOT
        chmod +x "$SCRIPT_PATH"
    fi
fi

# 执行安装依赖脚本
echo ""
print_blue "步骤1: 安装依赖"
echo ""

DEPENDENCIES_CMD="bash install_dependencies.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --python-packages \"${PYTHON_PACKAGES}\" --system-packages \"${SYSTEM_PACKAGES}\" ${BROWSER_FLAG}"

echo "执行命令: ${DEPENDENCIES_CMD}"
echo ""
eval ${DEPENDENCIES_CMD}

# 检查依赖安装是否成功
if [ $? -ne 0 ]; then
    print_red "依赖安装失败，请检查错误信息。"
    read -p "是否继续安装服务？(y/n，默认: n): " CONTINUE_ANYWAY
    CONTINUE_ANYWAY=${CONTINUE_ANYWAY:-n}
    
    if [[ $CONTINUE_ANYWAY != "y" && $CONTINUE_ANYWAY != "Y" ]]; then
        print_red "安装中止。"
        exit 1
    fi
fi

# 询问是否安装服务
echo ""
read -p "是否要将应用设置为系统服务？(y/n，默认: y): " INSTALL_SERVICE
INSTALL_SERVICE=${INSTALL_SERVICE:-y}

if [[ $INSTALL_SERVICE == "y" || $INSTALL_SERVICE == "Y" ]]; then
    # 收集服务信息
    read -p "请输入服务短名称 (用于日志标识，默认: ${APP_NAME:0:5}): " SHORT_NAME
    SHORT_NAME=${SHORT_NAME:-${APP_NAME:0:5}}
    
    read -p "请输入服务描述 (默认: ${APP_NAME} service): " DESCRIPTION
    DESCRIPTION=${DESCRIPTION:-"${APP_NAME} service"}
    
    # 执行安装服务脚本
    echo ""
    print_blue "步骤2: 安装服务"
    echo ""
    
    SERVICE_CMD="bash install_service.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --short-name \"${SHORT_NAME}\" --description \"${DESCRIPTION}\""
    
    echo "执行命令: ${SERVICE_CMD}"
    echo ""
    eval ${SERVICE_CMD}
    
    # 检查服务安装是否成功
    if [ $? -ne 0 ]; then
        print_red "服务安装失败，请检查错误信息。"
        exit 1
    fi
    
    # 询问是否立即启动服务
    echo ""
    read -p "是否立即启动服务？(y/n，默认: y): " START_SERVICE
    START_SERVICE=${START_SERVICE:-y}
    
    if [[ $START_SERVICE == "y" || $START_SERVICE == "Y" ]]; then
        echo ""
        print_blue "步骤3: 启动服务"
        echo ""
        ${APP_NAME}start
    else
        echo ""
        print_green "安装完成！您可以稍后使用以下命令启动服务:"
        echo "${APP_NAME}start"
    fi
else
    echo ""
    print_green "依赖安装完成！"
    echo "您可以手动运行脚本: python3 ${SCRIPT_PATH}"
fi

echo ""
print_green "感谢使用应用部署向导！"
print_yellow "如有问题，请参考文档或联系管理员。"

EOF

# 创建README文件
cat > app_deploy_toolkit/README.md << 'EOF'
# 应用部署工具包

这个工具包包含两个脚本，用于简化Python应用程序的部署和管理：

1. `install_dependencies.sh` - 安装应用所需的依赖和配置
2. `install_service.sh` - 将应用设置为系统服务

## 快速入门

### 步骤1：安装依赖

```bash
sudo bash install_dependencies.sh --app-name myapp --python-packages "requests pandas"
```

### 步骤2：安装服务

```bash
sudo bash install_service.sh --app-name myapp
```

### 步骤3：启动服务

```bash
myappstart
```

## 详细使用说明

### install_dependencies.sh

此脚本用于安装应用程序所需的依赖项，创建必要的目录结构，并设置基本配置。

#### 参数

| 参数 | 描述 | 默认值 | 示例 |
|------|------|--------|------|
| `--app-name` | 应用名称 | myapp | `--app-name scraper` |
| `--app-dir` | 应用目录 | /root/应用名称 | `--app-dir /opt/scraper` |
| `--data-dir` | 数据目录 | 应用目录/data | `--data-dir /var/data/scraper` |
| `--script-path` | 主脚本路径 | /root/应用名称.py | `--script-path /opt/scraper/main.py` |
| `--python-packages` | Python包列表 | requests | `--python-packages "selenium requests"` |
| `--system-packages` | 系统包列表 | wget | `--system-packages "wget curl"` |
| `--install-browser` | 安装Chrome和ChromeDriver | 不安装 | `--install-browser` |

#### 示例

```bash
# 基本用法
sudo bash install_dependencies.sh --app-name myapp

# 安装爬虫应用
sudo bash install_dependencies.sh \
  --app-name hkex_scraper \
  --app-dir /root/hkex_pdfs \
  --script-path /root/hkex_scraper.py \
  --python-packages "selenium opencc-python-reimplemented requests webdriver_manager" \
  --system-packages "wget unzip" \
  --install-browser
```

### install_service.sh

此脚本用于将Python应用程序设置为系统服务，创建必要的systemd服务文件，并生成便捷的管理命令。

#### 参数

| 参数 | 描述 | 默认值 | 示例 |
|------|------|--------|------|
| `--app-name` | 应用名称 | myapp | `--app-name scraper` |
| `--app-dir` | 应用目录 | /root/应用名称 | `--app-dir /opt/scraper` |
| `--script-path` | 主脚本路径 | /root/应用名称.py | `--script-path /opt/scraper/main.py` |
| `--short-name` | 短名称，用于日志标识 | 应用名称前5个字符 | `--short-name scrap` |
| `--description` | 服务描述 | 应用名称 service | `--description "Web Scraper Service"` |

#### 示例

```bash
# 基本用法
sudo bash install_service.sh --app-name myapp

# 完整配置
sudo bash install_service.sh \
  --app-name hkex_scraper \
  --app-dir /root/hkex_pdfs \
  --script-path /root/hkex_scraper.py \
  --short-name hkex \
  --description "HKEX PDF Scraper Service"
```

## 管理命令

安装服务后，将创建以下命令用于管理服务：

- `{应用名称}start` - 启动服务
- `{应用名称}stop` - 停止服务
- `{应用名称}restart` - 重启服务
- `{应用名称}status` - 查看服务状态
- `{应用名称}log` - 查看服务日志

例如，如果应用名称为 "hkex_scraper"，则命令为：
- `hkex_scraperstart`
- `hkex_scraperstop`
- 等等...

## 常见场景

### 1. 部署爬虫应用

```bash
# 安装依赖
sudo bash install_dependencies.sh \
  --app-name myscraper \
  --python-packages "selenium requests bs4" \
  --install-browser

# 安装服务
sudo bash install_service.sh --app-name myscraper

# 启动服务
myscraperstart
```

### 2. 部署API服务

```bash
# 安装依赖
sudo bash install_dependencies.sh \
  --app-name myapi \
  --python-packages "flask gunicorn"

# 安装服务
sudo bash install_service.sh --app-name myapi

# 启动服务
myapistart
```
```

## 3. 添加交互式向导

为了进一步简化使用，我们可以创建一个交互式向导脚本 `setup_wizard.sh`，引导用户完成配置过程：

```bash
#!/bin/bash

# 彩色输出函数
print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

print_blue() {
    echo -e "\e[34m$1\e[0m"
}

# 显示欢迎信息
clear
print_blue "=================================================="
print_blue "           应用部署向导                           "
print_blue "=================================================="
echo ""
print_yellow "这个向导将帮助您配置和部署Python应用程序。"
echo ""

# 收集基本信息
read -p "请输入应用名称 (默认: myapp): " APP_NAME
APP_NAME=${APP_NAME:-myapp}

read -p "请输入应用目录 (默认: /root/${APP_NAME}): " APP_DIR
APP_DIR=${APP_DIR:-/root/${APP_NAME}}

read -p "请输入主脚本路径 (默认: /root/${APP_NAME}.py): " SCRIPT_PATH
SCRIPT_PATH=${SCRIPT_PATH:-/root/${APP_NAME}.py}

read -p "请输入Python包列表 (空格分隔，默认: requests): " PYTHON_PACKAGES
PYTHON_PACKAGES=${PYTHON_PACKAGES:-requests}

read -p "请输入系统包列表 (空格分隔，默认: wget): " SYSTEM_PACKAGES
SYSTEM_PACKAGES=${SYSTEM_PACKAGES:-wget}

read -p "是否需要安装Chrome和ChromeDriver？(y/n，默认: n): " INSTALL_BROWSER
INSTALL_BROWSER=${INSTALL_BROWSER:-n}

BROWSER_FLAG=""
if [[ $INSTALL_BROWSER == "y" || $INSTALL_BROWSER == "Y" ]]; then
    BROWSER_FLAG="--install-browser"
fi

# 确认信息
echo ""
print_yellow "请确认以下信息:"
echo "应用名称: ${APP_NAME}"
echo "应用目录: ${APP_DIR}"
echo "主脚本路径: ${SCRIPT_PATH}"
echo "Python包: ${PYTHON_PACKAGES}"
echo "系统包: ${SYSTEM_PACKAGES}"
echo "安装浏览器: ${INSTALL_BROWSER}"
echo ""

read -p "是否继续？(y/n，默认: y): " CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "已取消安装。"
    exit 0
fi

# 执行安装依赖脚本
echo ""
print_blue "步骤1: 安装依赖"
echo ""

DEPENDENCIES_CMD="sudo bash install_dependencies.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --python-packages \"${PYTHON_PACKAGES}\" --system-packages \"${SYSTEM_PACKAGES}\" ${BROWSER_FLAG}"

echo "执行命令: ${DEPENDENCIES_CMD}"
echo ""
eval ${DEPENDENCIES_CMD}

# 询问是否安装服务
echo ""
read -p "是否要将应用设置为系统服务？(y/n，默认: y): " INSTALL_SERVICE
INSTALL_SERVICE=${INSTALL_SERVICE:-y}

if [[ $INSTALL_SERVICE == "y" || $INSTALL_SERVICE == "Y" ]]; then
    # 收集服务信息
    read -p "请输入服务短名称 (用于日志标识，默认: ${APP_NAME:0:5}): " SHORT_NAME
    SHORT_NAME=${SHORT_NAME:-${APP_NAME:0:5}}
    
    read -p "请输入服务描述 (默认: ${APP_NAME} service): " DESCRIPTION
    DESCRIPTION=${DESCRIPTION:-"${APP_NAME} service"}
    
    # 执行安装服务脚本
    echo ""
    print_blue "步骤2: 安装服务"
    echo ""
    
    SERVICE_CMD="sudo bash install_service.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --short-name \"${SHORT_NAME}\" --description \"${DESCRIPTION}\""
    
    echo "执行命令: ${SERVICE_CMD}"
    echo ""
    eval ${SERVICE_CMD}
    
    # 询问是否立即启动服务
    echo ""
    read -p "是否立即启动服务？(y/n，默认: y): " START_SERVICE
    START_SERVICE=${START_SERVICE:-y}
    
    if [[ $START_SERVICE == "y" || $START_SERVICE == "Y" ]]; then
        echo ""
        print_blue "步骤3: 启动服务"
        echo ""
        ${APP_NAME}start
    else
        echo ""
        print_green "安装完成！您可以稍后使用以下命令启动服务:"
        echo "${APP_NAME}start"
    fi
else
    echo ""
    print_green "依赖安装完成！"
    echo "您可以手动运行脚本: python3 ${SCRIPT_PATH}"
fi

echo ""
print_green "感谢使用应用部署向导！"
```

## 4. 为每个脚本添加版本信息和自检功能

在每个脚本的开头添加版本信息，并添加自检功能以确保环境满足要求：

### install_dependencies.sh 添加内容

```bash
#!/bin/bash

# 脚本信息
SCRIPT_VERSION="1.0.0"
SCRIPT_DATE="2025-06-15"
SCRIPT_AUTHOR="Romy"
SCRIPT_NAME="应用依赖安装工具"

# 自检功能
check_environment() {
    print_yellow "正在检查环境..."
    
    # 检查是否为root用户或使用sudo
    if [ "$EUID" -ne 0 ]; then
        print_red "错误: 此脚本需要root权限。请使用sudo运行。"
        exit 1
    fi
    
    # 检查apt是否可用
    if ! command -v apt-get &> /dev/null; then
        print_red "错误: 此脚本需要apt包管理器。仅支持Debian/Ubuntu系统。"
        exit 1
    fi
    
    # 检查pip是否可用
    if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
        print_yellow "警告: 未检测到pip。将尝试安装..."
        sudo apt-get install -y python3-pip
        if [ $? -ne 0 ]; then
            print_red "错误: 无法安装pip。请手动安装后重试。"
            exit 1
        fi
    fi
    
    print_green "环境检查通过！"
}

# 显示脚本信息
print_script_info() {
    echo "----------------------------------------"
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "作者: ${SCRIPT_AUTHOR}"
    echo "日期: ${SCRIPT_DATE}"
    echo "----------------------------------------"
    echo "使用 --help 参数查看使用说明"
    echo "----------------------------------------"
}

# 在解析参数前显示脚本信息并检查环境
print_script_info
check_environment

# 其余脚本内容...
```

### install_service.sh 添加内容

```bash
#!/bin/bash

# 脚本信息
SCRIPT_VERSION="1.0.0"
SCRIPT_DATE="2025-06-15"
SCRIPT_AUTHOR="Romy"
SCRIPT_NAME="应用服务安装工具"

# 自检功能
check_environment() {
    print_yellow "正在检查环境..."
    
    # 检查是否为root用户或使用sudo
    if [ "$EUID" -ne 0 ]; then
        print_red "错误: 此脚本需要root权限。请使用sudo运行。"
        exit 1
    fi
    
    # 检查systemd是否可用
    if ! command -v systemctl &> /dev/null; then
        print_red "错误: 此脚本需要systemd。不支持当前系统。"
        exit 1
    fi
    
    print_green "环境检查通过！"
}

# 显示脚本信息
print_script_info() {
    echo "----------------------------------------"
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "作者: ${SCRIPT_AUTHOR}"
    echo "日期: ${SCRIPT_DATE}"
    echo "----------------------------------------"
    echo "使用 --help 参数查看使用说明"
    echo "----------------------------------------"
}

# 在解析参数前显示脚本信息并检查环境
print_script_info
check_environment

# 其余脚本内容...
```

## 5. 创建一个简单的安装包

将所有脚本和文档打包成一个简单的安装包，用户只需下载并解压即可使用：

```bash
#!/bin/bash

# 创建目录
mkdir -p app_deploy_toolkit

# 创建脚本文件
cat > app_deploy_toolkit/install_dependencies.sh << 'EOF'
#!/bin/bash
# 这里是完整的install_dependencies.sh内容
EOF

cat > app_deploy_toolkit/install_service.sh << 'EOF'
#!/bin/bash
# 这里是完整的install_service.sh内容
EOF

cat > app_deploy_toolkit/setup_wizard.sh << 'EOF'
#!/bin/bash

# 彩色输出函数
print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

print_blue() {
    echo -e "\e[34m$1\e[0m"
}

print_red() {
    echo -e "\e[31m$1\e[0m"
}

# 检查脚本是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    print_red "错误: 此脚本需要root权限。请使用sudo运行。"
    exit 1
fi

# 卸载应用的函数
uninstall_app() {
    clear
    print_blue "=================================================="
    print_blue "           应用卸载向导                           "
    print_blue "=================================================="
    echo ""
    print_yellow "这个向导将帮助您卸载之前部署的Python应用程序。"
    echo ""

    # 获取应用名称
    read -p "请输入要卸载的应用名称: " APP_NAME
    if [ -z "$APP_NAME" ]; then
        print_red "错误: 应用名称不能为空。"
        exit 1
    fi

    # 确认卸载
    echo ""
    print_yellow "警告: 即将卸载 ${APP_NAME} 应用及其服务。此操作不可逆。"
    read -p "是否继续？(y/n): " CONFIRM
    if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
        echo "已取消卸载。"
        exit 0
    fi

    # 停止并禁用服务
    print_yellow "正在停止并禁用服务..."
    if systemctl is-active --quiet ${APP_NAME}.service 2>/dev/null; then
        systemctl stop ${APP_NAME}.service
        print_green "服务已停止。"
    else
        print_yellow "服务未运行或不存在。"
    fi

    if systemctl is-enabled --quiet ${APP_NAME}.service 2>/dev/null; then
        systemctl disable ${APP_NAME}.service
        print_green "服务已禁用。"
    else
        print_yellow "服务未启用或不存在。"
    fi

    # 删除服务文件
    if [ -f "/etc/systemd/system/${APP_NAME}.service" ]; then
        rm /etc/systemd/system/${APP_NAME}.service
        systemctl daemon-reload
        print_green "服务文件已删除。"
    else
        print_yellow "服务文件不存在，跳过删除。"
    fi

    # 删除管理命令
    print_yellow "正在删除管理命令..."
    local commands_deleted=0
    for cmd in start stop restart status log; do
        if [ -f "/usr/local/bin/${APP_NAME}${cmd}" ]; then
            rm -f "/usr/local/bin/${APP_NAME}${cmd}"
            ((commands_deleted++))
        fi
    done
    
    if [ $commands_deleted -gt 0 ]; then
        print_green "管理命令已删除。"
    else
        print_yellow "未找到管理命令，跳过删除。"
    fi

    # 询问是否删除应用目录
    read -p "是否删除应用目录和数据？(y/n，默认: n): " DELETE_DIR
    DELETE_DIR=${DELETE_DIR:-n}

    if [[ $DELETE_DIR == "y" || $DELETE_DIR == "Y" ]]; then
        # 获取应用目录
        read -p "请输入应用目录 (默认: /root/${APP_NAME}): " APP_DIR
        APP_DIR=${APP_DIR:-/root/${APP_NAME}}
        
        if [ -d "$APP_DIR" ]; then
            print_yellow "正在删除应用目录: $APP_DIR"
            rm -rf "$APP_DIR"
            print_green "应用目录已删除。"
        else
            print_yellow "应用目录不存在，跳过删除。"
        fi
        
        # 询问是否删除主脚本
        read -p "是否删除主脚本？(y/n，默认: n): " DELETE_SCRIPT
        DELETE_SCRIPT=${DELETE_SCRIPT:-n}
        
        if [[ $DELETE_SCRIPT == "y" || $DELETE_SCRIPT == "Y" ]]; then
            read -p "请输入主脚本路径 (默认: /root/${APP_NAME}.py): " SCRIPT_PATH
            SCRIPT_PATH=${SCRIPT_PATH:-/root/${APP_NAME}.py}
            
            if [ -f "$SCRIPT_PATH" ]; then
                rm "$SCRIPT_PATH"
                print_green "主脚本已删除。"
            else
                print_yellow "主脚本不存在，跳过删除。"
            fi
        fi
    fi

    print_green "=== ${APP_NAME} 应用已成功卸载 ==="
    exit 0
}

# 安装应用的函数
install_app() {
    # 检查依赖脚本是否存在
    if [ ! -f "install_dependencies.sh" ] || [ ! -f "install_service.sh" ]; then
        print_red "错误: 未找到必要的安装脚本。请确保 install_dependencies.sh 和 install_service.sh 在当前目录。"
        exit 1
    fi

    # 显示欢迎信息
    clear
    print_blue "=================================================="
    print_blue "           应用部署向导                           "
    print_blue "=================================================="
    echo ""
    print_yellow "这个向导将帮助您配置和部署Python应用程序。"
    echo ""

    # 收集基本信息
    read -p "请输入应用名称 (默认: myapp): " APP_NAME
    APP_NAME=${APP_NAME:-myapp}

    read -p "请输入应用目录 (默认: /root/${APP_NAME}): " APP_DIR
    APP_DIR=${APP_DIR:-/root/${APP_NAME}}

    read -p "请输入主脚本路径 (默认: /root/${APP_NAME}.py): " SCRIPT_PATH
    SCRIPT_PATH=${SCRIPT_PATH:-/root/${APP_NAME}.py}

    read -p "请输入Python包列表 (空格分隔，默认: requests): " PYTHON_PACKAGES
    PYTHON_PACKAGES=${PYTHON_PACKAGES:-requests}

    read -p "请输入系统包列表 (空格分隔，默认: wget): " SYSTEM_PACKAGES
    SYSTEM_PACKAGES=${SYSTEM_PACKAGES:-wget}

    read -p "是否需要安装Chrome和ChromeDriver？(y/n，默认: n): " INSTALL_BROWSER
    INSTALL_BROWSER=${INSTALL_BROWSER:-n}

    BROWSER_FLAG=""
    if [[ $INSTALL_BROWSER == "y" || $INSTALL_BROWSER == "Y" ]]; then
        BROWSER_FLAG="--install-browser"
    fi

    # 确认信息
    echo ""
    print_yellow "请确认以下信息:"
    echo "应用名称: ${APP_NAME}"
    echo "应用目录: ${APP_DIR}"
    echo "主脚本路径: ${SCRIPT_PATH}"
    echo "Python包: ${PYTHON_PACKAGES}"
    echo "系统包: ${SYSTEM_PACKAGES}"
    echo "安装浏览器: ${INSTALL_BROWSER}"
    echo ""

    read -p "是否继续？(y/n，默认: y): " CONFIRM
    CONFIRM=${CONFIRM:-y}

    if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
        echo "已取消安装。"
        exit 0
    fi

    # 创建应用目录（如果不存在）
    if [ ! -d "$APP_DIR" ]; then
        print_yellow "创建应用目录: $APP_DIR"
        mkdir -p "$APP_DIR"
        if [ $? -ne 0 ]; then
            print_red "错误: 无法创建目录 $APP_DIR"
            exit 1
        fi
    fi

    # 检查主脚本是否存在
    if [ ! -f "$SCRIPT_PATH" ]; then
        print_yellow "注意: 主脚本 $SCRIPT_PATH 不存在。"
        read -p "是否创建一个示例脚本？(y/n，默认: y): " CREATE_SCRIPT
        CREATE_SCRIPT=${CREATE_SCRIPT:-y}
        
        if [[ $CREATE_SCRIPT == "y" || $CREATE_SCRIPT == "Y" ]]; then
            print_yellow "创建示例脚本: $SCRIPT_PATH"
            cat > "$SCRIPT_PATH" << EOT
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
${APP_NAME} - 示例应用
创建日期: $(date +%Y-%m-%d)
"""

import os
import time
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('${APP_NAME}')

def main():
    """主函数"""
    logger.info("应用启动")
    
    try:
        # 应用主循环
        while True:
            logger.info("应用正在运行...")
            time.sleep(60)  # 每分钟记录一次
            
    except KeyboardInterrupt:
        logger.info("接收到中断信号，应用退出")
    except Exception as e:
        logger.error(f"发生错误: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main())
EOT
            chmod +x "$SCRIPT_PATH"
        fi
    fi

    # 执行安装依赖脚本
    echo ""
    print_blue "步骤1: 安装依赖"
    echo ""

    DEPENDENCIES_CMD="bash install_dependencies.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --python-packages \"${PYTHON_PACKAGES}\" --system-packages \"${SYSTEM_PACKAGES}\" ${BROWSER_FLAG}"

    echo "执行命令: ${DEPENDENCIES_CMD}"
    echo ""
    eval ${DEPENDENCIES_CMD}

    # 检查依赖安装是否成功
    if [ $? -ne 0 ]; then
        print_red "依赖安装失败，请检查错误信息。"
        read -p "是否继续安装服务？(y/n，默认: n): " CONTINUE_ANYWAY
        CONTINUE_ANYWAY=${CONTINUE_ANYWAY:-n}
        
        if [[ $CONTINUE_ANYWAY != "y" && $CONTINUE_ANYWAY != "Y" ]]; then
            print_red "安装中止。"
            exit 1
        fi
    fi

    # 询问是否安装服务
    echo ""
    read -p "是否要将应用设置为系统服务？(y/n，默认: y): " INSTALL_SERVICE
    INSTALL_SERVICE=${INSTALL_SERVICE:-y}

    if [[ $INSTALL_SERVICE == "y" || $INSTALL_SERVICE == "Y" ]]; then
        # 收集服务信息
        read -p "请输入服务短名称 (用于日志标识，默认: ${APP_NAME:0:5}): " SHORT_NAME
        SHORT_NAME=${SHORT_NAME:-${APP_NAME:0:5}}
        
        read -p "请输入服务描述 (默认: ${APP_NAME} service): " DESCRIPTION
        DESCRIPTION=${DESCRIPTION:-"${APP_NAME} service"}
        
        # 执行安装服务脚本
        echo ""
        print_blue "步骤2: 安装服务"
        echo ""
        
        SERVICE_CMD="bash install_service.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --short-name \"${SHORT_NAME}\" --description \"${DESCRIPTION}\""
        
        echo "执行命令: ${SERVICE_CMD}"
        echo ""
        eval ${SERVICE_CMD}
        
        # 检查服务安装是否成功
        if [ $? -ne 0 ]; then
            print_red "服务安装失败，请检查错误信息。"
            exit 1
        fi
        
        # 询问是否立即启动服务
        echo ""
        read -p "是否立即启动服务？(y/n，默认: y): " START_SERVICE
        START_SERVICE=${START_SERVICE:-y}
        
        if [[ $START_SERVICE == "y" || $START_SERVICE == "Y" ]]; then
            echo ""
            print_blue "步骤3: 启动服务"
            echo ""
            ${APP_NAME}start
        else
            echo ""
            print_green "安装完成！您可以稍后使用以下命令启动服务:"
            echo "${APP_NAME}start"
        fi
    else
        echo ""
        print_green "依赖安装完成！"
        echo "您可以手动运行脚本: python3 ${SCRIPT_PATH}"
    fi

    echo ""
    print_green "感谢使用应用部署向导！"
    print_yellow "如有问题，请参考文档或联系管理员。"
}

# 更新应用的函数
update_app() {
    clear
    print_blue "=================================================="
    print_blue "           应用更新向导                           "
    print_blue "=================================================="
    echo ""
    print_yellow "这个向导将帮助您更新现有的Python应用程序。"
    echo ""

    # 获取应用名称
    read -p "请输入要更新的应用名称: " APP_NAME
    if [ -z "$APP_NAME" ]; then
        print_red "错误: 应用名称不能为空。"
        exit 1
    fi

    # 检查应用是否存在
    if ! systemctl list-units --type=service | grep -q "${APP_NAME}.service"; then
        print_yellow "警告: 未找到名为 ${APP_NAME} 的服务。"
        read -p "是否继续更新？(y/n，默认: n): " CONTINUE
        CONTINUE=${CONTINUE:-n}
        if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
            echo "已取消更新。"
            exit 0
        fi
    fi

    # 获取应用目录和脚本路径
    read -p "请输入应用目录 (默认: /root/${APP_NAME}): " APP_DIR
    APP_DIR=${APP_DIR:-/root/${APP_NAME}}

    read -p "请输入主脚本路径 (默认: /root/${APP_NAME}.py): " SCRIPT_PATH
    SCRIPT_PATH=${SCRIPT_PATH:-/root/${APP_NAME}.py}

    # 检查目录和脚本是否存在
    if [ ! -d "$APP_DIR" ]; then
        print_red "错误: 应用目录 $APP_DIR 不存在。"
        read -p "是否创建此目录？(y/n，默认: y): " CREATE_DIR
        CREATE_DIR=${CREATE_DIR:-y}
        if [[ $CREATE_DIR == "y" || $CREATE_DIR == "Y" ]]; then
            mkdir -p "$APP_DIR"
        else
            print_red "更新取消。"
            exit 1
        fi
    fi

    # 询问更新内容
    echo ""
    print_yellow "请选择要更新的内容:"
    echo "1) 仅更新Python依赖包"
    echo "2) 仅更新系统依赖包"
    echo "3) 更新Python和系统依赖包"
    echo "4) 更新主脚本"
    echo "5) 更新服务配置"
    echo "6) 全部更新"
    echo ""
    read -p "请选择 (默认: 6): " UPDATE_OPTION
    UPDATE_OPTION=${UPDATE_OPTION:-6}

    # 根据选择执行更新
    case $UPDATE_OPTION in
        1|3|6)
            # 更新Python依赖
            read -p "请输入Python包列表 (空格分隔): " PYTHON_PACKAGES
            if [ ! -z "$PYTHON_PACKAGES" ]; then
                print_yellow "正在更新Python依赖包..."
                pip install -U $PYTHON_PACKAGES
                if [ $? -eq 0 ]; then
                    print_green "Python依赖包更新成功。"
                else
                    print_red "Python依赖包更新失败。"
                fi
            fi
            ;;
    esac

    case $UPDATE_OPTION in
        2|3|6)
            # 更新系统依赖
            read -p "请输入系统包列表 (空格分隔): " SYSTEM_PACKAGES
            if [ ! -z "$SYSTEM_PACKAGES" ]; then
                print_yellow "正在更新系统依赖包..."
                apt-get update && apt-get install -y $SYSTEM_PACKAGES
                if [ $? -eq 0 ]; then
                    print_green "系统依赖包更新成功。"
                else
                    print_red "系统依赖包更新失败。"
                fi
            fi
            ;;
    esac

    case $UPDATE_OPTION in
        4|6)
            # 更新主脚本
            read -p "是否更新主脚本？(y/n，默认: n): " UPDATE_SCRIPT
            UPDATE_SCRIPT=${UPDATE_SCRIPT:-n}
            if [[ $UPDATE_SCRIPT == "y" || $UPDATE_SCRIPT == "Y" ]]; then
                print_yellow "请选择更新方式:"
                echo "1) 从文件上传"
                echo "2) 从URL下载"
                echo "3) 创建新的示例脚本"
                read -p "请选择 (默认: 1): " SCRIPT_UPDATE_METHOD
                SCRIPT_UPDATE_METHOD=${SCRIPT_UPDATE_METHOD:-1}

                case $SCRIPT_UPDATE_METHOD in
                    1)
                        print_yellow "请将新脚本上传到服务器，然后提供路径"
                        read -p "新脚本路径: " NEW_SCRIPT_PATH
                        if [ -f "$NEW_SCRIPT_PATH" ]; then
                            cp "$NEW_SCRIPT_PATH" "$SCRIPT_PATH"
                            chmod +x "$SCRIPT_PATH"
                            print_green "脚本已更新。"
                        else
                            print_red "错误: 无法找到指定的脚本文件。"
                        fi
                        ;;
                    2)
                        read -p "请输入脚本URL: " SCRIPT_URL
                        if [ ! -z "$SCRIPT_URL" ]; then
                            wget -O "$SCRIPT_PATH" "$SCRIPT_URL"
                            if [ $? -eq 0 ]; then
                                chmod +x "$SCRIPT_PATH"
                                print_green "脚本已从URL下载并更新。"
                            else
                                print_red "错误: 无法从URL下载脚本。"
                            fi
                        fi
                        ;;
                    3)
                        # 创建示例脚本（与安装函数中的代码相同）
                        print_yellow "创建示例脚本: $SCRIPT_PATH"
                        cat > "$SCRIPT_PATH" << EOT
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
${APP_NAME} - 示例应用
创建日期: $(date +%Y-%m-%d)
"""

import os
import time
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('${APP_NAME}')

def main():
    """主函数"""
    logger.info("应用启动")
    
    try:
        # 应用主循环
        while True:
            logger.info("应用正在运行...")
            time.sleep(60)  # 每分钟记录一次
            
    except KeyboardInterrupt:
        logger.info("接收到中断信号，应用退出")
    except Exception as e:
        logger.error(f"发生错误: {e}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main())
EOT
                        chmod +x "$SCRIPT_PATH"
                        print_green "示例脚本已创建。"
                        ;;
                esac
            fi
            ;;
    esac

    case $UPDATE_OPTION in
        5|6)
            # 更新服务配置
            if [ -f "/etc/systemd/system/${APP_NAME}.service" ]; then
                read -p "是否更新服务配置？(y/n，默认: n): " UPDATE_SERVICE
                UPDATE_SERVICE=${UPDATE_SERVICE:-n}
                if [[ $UPDATE_SERVICE == "y" || $UPDATE_SERVICE == "Y" ]]; then
                    read -p "请输入服务短名称 (用于日志标识，默认: ${APP_NAME:0:5}): " SHORT_NAME
                    SHORT_NAME=${SHORT_NAME:-${APP_NAME:0:5}}
                    
                    read -p "请输入服务描述 (默认: ${APP_NAME} service): " DESCRIPTION
                    DESCRIPTION=${DESCRIPTION:-"${APP_NAME} service"}
                    
                    # 重新创建服务文件
                    print_yellow "正在更新服务配置..."
                    
                    # 先停止服务
                    if systemctl is-active --quiet ${APP_NAME}.service; then
                        systemctl stop ${APP_NAME}.service
                    fi
                    
                    # 更新服务文件
                    cat > /etc/systemd/system/${APP_NAME}.service << EOT
[Unit]
Description=${DESCRIPTION}
After=network.target

[Service]
User=root
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/python3 ${SCRIPT_PATH}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SHORT_NAME}
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOT
                    
                    # 重新加载systemd配置
                    systemctl daemon-reload
                    
                    # 如果服务之前是启用的，则重新启用
                    if systemctl is-enabled --quiet ${APP_NAME}.service; then
                        systemctl enable ${APP_NAME}.service
                    fi
                    
                    print_green "服务配置已更新。"
                    
                    # 询问是否重启服务
                    read -p "是否重启服务？(y/n，默认: y): " RESTART_SERVICE
                    RESTART_SERVICE=${RESTART_SERVICE:-y}
                    if [[ $RESTART_SERVICE == "y" || $RESTART_SERVICE == "Y" ]]; then
                        systemctl restart ${APP_NAME}.service
                        print_green "服务已重启。"
                    fi
                fi
            else
                print_yellow "未找到服务配置文件，跳过服务更新。"
                read -p "是否重新安装服务？(y/n，默认: n): " REINSTALL_SERVICE
                REINSTALL_SERVICE=${REINSTALL_SERVICE:-n}
                if [[ $REINSTALL_SERVICE == "y" || $REINSTALL_SERVICE == "Y" ]]; then
                    read -p "请输入服务短名称 (用于日志标识，默认: ${APP_NAME:0:5}): " SHORT_NAME
                    SHORT_NAME=${SHORT_NAME:-${APP_NAME:0:5}}
                    
                    read -p "请输入服务描述 (默认: ${APP_NAME} service): " DESCRIPTION
                    DESCRIPTION=${DESCRIPTION:-"${APP_NAME} service"}
                    
                    # 执行安装服务脚本
                    SERVICE_CMD="bash install_service.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --short-name \"${SHORT_NAME}\" --description \"${DESCRIPTION}\""
                    
                    echo "执行命令: ${SERVICE_CMD}"
                    eval ${SERVICE_CMD}
                fi
            fi
            ;;
    esac

    print_green "=== ${APP_NAME} 应用更新完成 ==="
    exit 0
}

# 主菜单
clear
print_blue "=================================================="
print_blue "           Python应用部署工具包                    "
print_blue "           版本: 1.0.0                            "
print_blue "=================================================="
echo ""
print_yellow "请选择要执行的操作:"
echo "1) 安装新应用"
echo "2) 更新现有应用"
echo "3) 卸载应用"
echo "4) 退出"
echo ""
read -p "请选择 (默认: 1): " MENU_OPTION
MENU_OPTION=${MENU_OPTION:-1}

case $MENU_OPTION in
    1)
        install_app
        ;;
    2)
        update_app
        ;;
    3)
        uninstall_app
        ;;
    4|*)
        echo "退出程序。"
        exit 0
        ;;
esac

EOF

# 创建README文件
cat > app_deploy_toolkit/README.md << 'EOF'
# 应用部署工具包

这个工具包包含两个脚本，用于简化Python应用程序的部署和管理：

1. `install_dependencies.sh` - 安装应用所需的依赖和配置
2. `install_service.sh` - 将应用设置为系统服务

## 快速入门

### 步骤1：安装依赖

```bash
sudo bash install_dependencies.sh --app-name myapp --python-packages "requests pandas"
```

### 步骤2：安装服务

```bash
sudo bash install_service.sh --app-name myapp
```

### 步骤3：启动服务

```bash
myappstart
```

## 详细使用说明

### install_dependencies.sh

此脚本用于安装应用程序所需的依赖项，创建必要的目录结构，并设置基本配置。

#### 参数

| 参数 | 描述 | 默认值 | 示例 |
|------|------|--------|------|
| `--app-name` | 应用名称 | myapp | `--app-name scraper` |
| `--app-dir` | 应用目录 | /root/应用名称 | `--app-dir /opt/scraper` |
| `--data-dir` | 数据目录 | 应用目录/data | `--data-dir /var/data/scraper` |
| `--script-path` | 主脚本路径 | /root/应用名称.py | `--script-path /opt/scraper/main.py` |
| `--python-packages` | Python包列表 | requests | `--python-packages "selenium requests"` |
| `--system-packages` | 系统包列表 | wget | `--system-packages "wget curl"` |
| `--install-browser` | 安装Chrome和ChromeDriver | 不安装 | `--install-browser` |

#### 示例

```bash
# 基本用法
sudo bash install_dependencies.sh --app-name myapp

# 安装爬虫应用
sudo bash install_dependencies.sh \
  --app-name hkex_scraper \
  --app-dir /root/hkex_pdfs \
  --script-path /root/hkex_scraper.py \
  --python-packages "selenium opencc-python-reimplemented requests webdriver_manager" \
  --system-packages "wget unzip" \
  --install-browser
```

### install_service.sh

此脚本用于将Python应用程序设置为系统服务，创建必要的systemd服务文件，并生成便捷的管理命令。

#### 参数

| 参数 | 描述 | 默认值 | 示例 |
|------|------|--------|------|
| `--app-name` | 应用名称 | myapp | `--app-name scraper` |
| `--app-dir` | 应用目录 | /root/应用名称 | `--app-dir /opt/scraper` |
| `--script-path` | 主脚本路径 | /root/应用名称.py | `--script-path /opt/scraper/main.py` |
| `--short-name` | 短名称，用于日志标识 | 应用名称前5个字符 | `--short-name scrap` |
| `--description` | 服务描述 | 应用名称 service | `--description "Web Scraper Service"` |

#### 示例

```bash
# 基本用法
sudo bash install_service.sh --app-name myapp

# 完整配置
sudo bash install_service.sh \
  --app-name hkex_scraper \
  --app-dir /root/hkex_pdfs \
  --script-path /root/hkex_scraper.py \
  --short-name hkex \
  --description "HKEX PDF Scraper Service"
```

## 管理命令

安装服务后，将创建以下命令用于管理服务：

- `{应用名称}start` - 启动服务
- `{应用名称}stop` - 停止服务
- `{应用名称}restart` - 重启服务
- `{应用名称}status` - 查看服务状态
- `{应用名称}log` - 查看服务日志

例如，如果应用名称为 "hkex_scraper"，则命令为：
- `hkex_scraperstart`
- `hkex_scraperstop`
- 等等...

## 常见场景

### 1. 部署爬虫应用

```bash
# 安装依赖
sudo bash install_dependencies.sh \
  --app-name myscraper \
  --python-packages "selenium requests bs4" \
  --install-browser

# 安装服务
sudo bash install_service.sh --app-name myscraper

# 启动服务
myscraperstart
```

### 2. 部署API服务

```bash
# 安装依赖
sudo bash install_dependencies.sh \
  --app-name myapi \
  --python-packages "flask gunicorn"

# 安装服务
sudo bash install_service.sh --app-name myapi

# 启动服务
myapistart
```
```

## 3. 添加交互式向导

为了进一步简化使用，我们可以创建一个交互式向导脚本 `setup_wizard.sh`，引导用户完成配置过程：

```bash
#!/bin/bash

# 彩色输出函数
print_green() {
    echo -e "\e[32m$1\e[0m"
}

print_yellow() {
    echo -e "\e[33m$1\e[0m"
}

print_blue() {
    echo -e "\e[34m$1\e[0m"
}

# 显示欢迎信息
clear
print_blue "=================================================="
print_blue "           应用部署向导                           "
print_blue "=================================================="
echo ""
print_yellow "这个向导将帮助您配置和部署Python应用程序。"
echo ""

# 收集基本信息
read -p "请输入应用名称 (默认: myapp): " APP_NAME
APP_NAME=${APP_NAME:-myapp}

read -p "请输入应用目录 (默认: /root/${APP_NAME}): " APP_DIR
APP_DIR=${APP_DIR:-/root/${APP_NAME}}

read -p "请输入主脚本路径 (默认: /root/${APP_NAME}.py): " SCRIPT_PATH
SCRIPT_PATH=${SCRIPT_PATH:-/root/${APP_NAME}.py}

read -p "请输入Python包列表 (空格分隔，默认: requests): " PYTHON_PACKAGES
PYTHON_PACKAGES=${PYTHON_PACKAGES:-requests}

read -p "请输入系统包列表 (空格分隔，默认: wget): " SYSTEM_PACKAGES
SYSTEM_PACKAGES=${SYSTEM_PACKAGES:-wget}

read -p "是否需要安装Chrome和ChromeDriver？(y/n，默认: n): " INSTALL_BROWSER
INSTALL_BROWSER=${INSTALL_BROWSER:-n}

BROWSER_FLAG=""
if [[ $INSTALL_BROWSER == "y" || $INSTALL_BROWSER == "Y" ]]; then
    BROWSER_FLAG="--install-browser"
fi

# 确认信息
echo ""
print_yellow "请确认以下信息:"
echo "应用名称: ${APP_NAME}"
echo "应用目录: ${APP_DIR}"
echo "主脚本路径: ${SCRIPT_PATH}"
echo "Python包: ${PYTHON_PACKAGES}"
echo "系统包: ${SYSTEM_PACKAGES}"
echo "安装浏览器: ${INSTALL_BROWSER}"
echo ""

read -p "是否继续？(y/n，默认: y): " CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "已取消安装。"
    exit 0
fi

# 执行安装依赖脚本
echo ""
print_blue "步骤1: 安装依赖"
echo ""

DEPENDENCIES_CMD="sudo bash install_dependencies.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --python-packages \"${PYTHON_PACKAGES}\" --system-packages \"${SYSTEM_PACKAGES}\" ${BROWSER_FLAG}"

echo "执行命令: ${DEPENDENCIES_CMD}"
echo ""
eval ${DEPENDENCIES_CMD}

# 询问是否安装服务
echo ""
read -p "是否要将应用设置为系统服务？(y/n，默认: y): " INSTALL_SERVICE
INSTALL_SERVICE=${INSTALL_SERVICE:-y}

if [[ $INSTALL_SERVICE == "y" || $INSTALL_SERVICE == "Y" ]]; then
    # 收集服务信息
    read -p "请输入服务短名称 (用于日志标识，默认: ${APP_NAME:0:5}): " SHORT_NAME
    SHORT_NAME=${SHORT_NAME:-${APP_NAME:0:5}}
    
    read -p "请输入服务描述 (默认: ${APP_NAME} service): " DESCRIPTION
    DESCRIPTION=${DESCRIPTION:-"${APP_NAME} service"}
    
    # 执行安装服务脚本
    echo ""
    print_blue "步骤2: 安装服务"
    echo ""
    
    SERVICE_CMD="sudo bash install_service.sh --app-name \"${APP_NAME}\" --app-dir \"${APP_DIR}\" --script-path \"${SCRIPT_PATH}\" --short-name \"${SHORT_NAME}\" --description \"${DESCRIPTION}\""
    
    echo "执行命令: ${SERVICE_CMD}"
    echo ""
    eval ${SERVICE_CMD}
    
    # 询问是否立即启动服务
    echo ""
    read -p "是否立即启动服务？(y/n，默认: y): " START_SERVICE
    START_SERVICE=${START_SERVICE:-y}
    
    if [[ $START_SERVICE == "y" || $START_SERVICE == "Y" ]]; then
        echo ""
        print_blue "步骤3: 启动服务"
        echo ""
        ${APP_NAME}start
    else
        echo ""
        print_green "安装完成！您可以稍后使用以下命令启动服务:"
        echo "${APP_NAME}start"
    fi
else
    echo ""
    print_green "依赖安装完成！"
    echo "您可以手动运行脚本: python3 ${SCRIPT_PATH}"
fi

echo ""
print_green "感谢使用应用部署向导！"
```

## 4. 为每个脚本添加版本信息和自检功能

在每个脚本的开头添加版本信息，并添加自检功能以确保环境满足要求：

### install_dependencies.sh 添加内容

```bash
#!/bin/bash

# 脚本信息
SCRIPT_VERSION="1.0.0"
SCRIPT_DATE="2025-06-15"
SCRIPT_AUTHOR="Romy"
SCRIPT_NAME="应用依赖安装工具"

# 自检功能
check_environment() {
    print_yellow "正在检查环境..."
    
    # 检查是否为root用户或使用sudo
    if [ "$EUID" -ne 0 ]; then
        print_red "错误: 此脚本需要root权限。请使用sudo运行。"
        exit 1
    fi
    
    # 检查apt是否可用
    if ! command -v apt-get &> /dev/null; then
        print_red "错误: 此脚本需要apt包管理器。仅支持Debian/Ubuntu系统。"
        exit 1
    fi
    
    # 检查pip是否可用
    if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
        print_yellow "警告: 未检测到pip。将尝试安装..."
        sudo apt-get install -y python3-pip
        if [ $? -ne 0 ]; then
            print_red "错误: 无法安装pip。请手动安装后重试。"
            exit 1
        fi
    fi
    
    print_green "环境检查通过！"
}

# 显示脚本信息
print_script_info() {
    echo "----------------------------------------"
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "作者: ${SCRIPT_AUTHOR}"
    echo "日期: ${SCRIPT_DATE}"
    echo "----------------------------------------"
    echo "使用 --help 参数查看使用说明"
    echo "----------------------------------------"
}

# 在解析参数前显示脚本信息并检查环境
print_script_info
check_environment

# 其余脚本内容...
```

### install_service.sh 添加内容

```bash
#!/bin/bash

# 脚本信息
SCRIPT_VERSION="1.0.0"
SCRIPT_DATE="2025-06-15"
SCRIPT_AUTHOR="Romy"
SCRIPT_NAME="应用服务安装工具"

# 自检功能
check_environment() {
    print_yellow "正在检查环境..."
    
    # 检查是否为root用户或使用sudo
    if [ "$EUID" -ne 0 ]; then
        print_red "错误: 此脚本需要root权限。请使用sudo运行。"
        exit 1
    fi
    
    # 检查systemd是否可用
    if ! command -v systemctl &> /dev/null; then
        print_red "错误: 此脚本需要systemd。不支持当前系统。"
        exit 1
    fi
    
    print_green "环境检查通过！"
}

# 显示脚本信息
print_script_info() {
    echo "----------------------------------------"
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "作者: ${SCRIPT_AUTHOR}"
    echo "日期: ${SCRIPT_DATE}"
    echo "----------------------------------------"
    echo "使用 --help 参数查看使用说明"
    echo "----------------------------------------"
}

# 在解析参数前显示脚本信息并检查环境
print_script_info
check_environment

# 其余脚本内容...
```

## 5. 创建一个简单的安装包

将所有脚本和文档打包成一个简单的安装包，用户只需下载并解压即可使用：

```bash
#!/bin/bash

# 创建目录
mkdir -p app_deploy_toolkit

# 创建脚本文件
cat > app_deploy_toolkit/install_dependencies.sh << 'EOF'
#!/bin/bash
# 这里是完整的install_dependencies.sh内容
EOF

cat > app_deploy_toolkit/install_service.sh << 'EOF'
#!/bin/bash
# 这里是完整的install_service.sh内容
EOF

cat > app_deploy_toolkit/setup_wizard.sh << 'EOF'
#!/bin/bash
# 这里是完整的setup_wizard.sh内容
EOF

# 创建README文件
cat > app_deploy_toolkit/README.md << 'EOF'
# 应用部署工具包
# 这里是完整的README.md内容
EOF

# 设置权限
chmod +x app_deploy_toolkit/*.sh

# 创建压缩包
tar -czvf app_deploy_toolkit.tar.gz app_deploy_toolkit/

echo "安装包已创建: app_deploy_toolkit.tar.gz"
echo "用户可以使用以下命令解压并使用:"
echo "tar -xzvf app_deploy_toolkit.tar.gz"
echo "cd app_deploy_toolkit"
echo "sudo bash setup_wizard.sh"
```

## 总结

通过以上几种方式，我们可以大大提升用户对脚本的理解和使用体验：

1. **详细的帮助文档**：提供全面的参数说明和使用示例
2. **README.md文件**：提供完整的文档、表格和常见场景
3. **交互式向导**：引导用户完成配置，无需记忆参数
4. **自检功能**：确保环境满足要求，减少安装失败
5. **安装包**：简化分发和安装过程
EOF

# 设置权限
chmod +x app_deploy_toolkit/*.sh

# 创建压缩包
tar -czvf app_deploy_toolkit.tar.gz app_deploy_toolkit/

echo "安装包已创建: app_deploy_toolkit.tar.gz"
echo "用户可以使用以下命令解压并使用:"
echo "tar -xzvf app_deploy_toolkit.tar.gz"
echo "cd app_deploy_toolkit"
echo "sudo bash setup_wizard.sh"
```

## 总结

通过以上几种方式，我们可以大大提升用户对脚本的理解和使用体验：

1. **详细的帮助文档**：提供全面的参数说明和使用示例
2. **README.md文件**：提供完整的文档、表格和常见场景
3. **交互式向导**：引导用户完成配置，无需记忆参数
4. **自检功能**：确保环境满足要求，减少安装失败
5. **安装包**：简化分发和安装过程
EOF

# 设置权限
chmod +x app_deploy_toolkit/*.sh

# 创建压缩包
tar -czvf app_deploy_toolkit.tar.gz app_deploy_toolkit/

echo "安装包已创建: app_deploy_toolkit.tar.gz"
echo "用户可以使用以下命令解压并使用:"
echo "tar -xzvf app_deploy_toolkit.tar.gz"
echo "cd app_deploy_toolkit"
echo "sudo bash setup_wizard.sh"
