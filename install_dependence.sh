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
