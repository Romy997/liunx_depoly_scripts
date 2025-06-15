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