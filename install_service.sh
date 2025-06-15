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
