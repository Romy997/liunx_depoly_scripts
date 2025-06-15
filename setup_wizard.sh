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
