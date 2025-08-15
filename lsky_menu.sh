#!/bin/bash
#========================================
# Lsky Pro 部署 & 管理 菜单脚本
# Author: xiaoxim 专用
#========================================

WORK_DIR="/wwwroot/docker/lsky"
MYSQL_CONTAINER_NAME="db_mysql" # 已有 MySQL 容器名（方案B用）
LSKY_PORT=1128
LSKY_SERVICE_NAME="lskypro"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

# 彩色输出函数
green()  { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red()    { echo -e "\033[31m$1\033[0m"; }

# 获取本机IP
get_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

# 检查端口是否占用
check_port() {
    if command -v lsof &>/dev/null; then
        if lsof -i:"$LSKY_PORT" | grep -q LISTEN; then
            red "端口 $LSKY_PORT 已被占用，请修改脚本中的 LSKY_PORT 变量后重试！"
            exit 1
        fi
    else
        yellow "未检测到 lsof，自动安装中..."
        apt update && apt install -y lsof
        check_port
    fi
}

# 生成 docker-compose.yml (方案A)
generate_compose_a() {
cat > docker-compose.yml <<EOF
version: '3'
services:
  lskypro:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    hostname: lskypro
    container_name: lskypro
    environment:
      - WEB_PORT=8089
    volumes:
      - ./data:/var/www/html/
    ports:
      - "${LSKY_PORT}:8089"
    networks:
      - lsky-net

  mysql-lsky:
    image: mysql:5.7.22
    restart: unless-stopped
    hostname: mysql-lsky
    container_name: mysql-lsky
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf:/etc/mysql
      - ./mysql/log:/var/log/mysql
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: lsky-data
    networks:
      - lsky-net

networks:
  lsky-net: {}
EOF
}

# 生成 docker-compose.yml (方案B)
generate_compose_b() {
    docker network create lsky_net &>/dev/null
    docker network connect lsky_net "$MYSQL_CONTAINER_NAME" &>/dev/null

cat > docker-compose.yml <<EOF
version: '3'
services:
  lskypro:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    hostname: lsky
    container_name: lsky
    environment:
      - WEB_PORT=8089
      - DB_HOST=${MYSQL_CONTAINER_NAME}
      - DB_DATABASE=lsky
      - DB_USERNAME=lsky
      - DB_PASSWORD=123456
    volumes:
      - ./data:/var/www/html/
    ports:
      - "${LSKY_PORT}:8089"
    networks:
      - lsky_net

networks:
  lsky_net:
    external: true
EOF
}

# 启动服务
start_service() {
    green "启动 Lsky Pro..."
    docker-compose up -d
    local ip=$(get_ip)
    green "部署完成！访问地址: http://${ip}:${LSKY_PORT}"
}

# 更新服务
update_service() {
    green "更新 Lsky Pro..."
    docker-compose pull
    docker-compose up -d
    local ip=$(get_ip)
    green "更新完成！访问地址: http://${ip}:${LSKY_PORT}"
}

# 卸载服务
uninstall_service() {
    red "⚠ 这将会停止并删除容器、网络以及数据！"
    read -rp "确定要卸载 Lsky Pro 吗？(y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker-compose down -v
        rm -rf "$WORK_DIR"
        green "Lsky Pro 已卸载！"
    else
        yellow "已取消卸载操作。"
    fi
}

# 主菜单
while true; do
    echo ""
    green "===== Lsky Pro 管理菜单 ====="
    echo "1) 部署 Lsky Pro + MySQL (新建)"
    echo "2) 部署 Lsky Pro (连接已有 MySQL)"
    echo "3) 更新 Lsky Pro"
    echo "4) 卸载 Lsky Pro"
    echo "5) 退出"
    echo "============================="
    read -rp "请选择操作 [1-5]: " choice

    case "$choice" in
        1)
            check_port
            generate_compose_a
            start_service
            ;;
        2)
            check_port
            read -rp "请输入已有 MySQL 容器名(默认: $MYSQL_CONTAINER_NAME): " input_name
            MYSQL_CONTAINER_NAME="${input_name:-$MYSQL_CONTAINER_NAME}"
            generate_compose_b
            green "请确保 MySQL 中已创建数据库和用户："
            yellow "CREATE DATABASE lsky;"
            yellow "CREATE USER 'lsky'@'%' IDENTIFIED BY '123456';"
            yellow "GRANT ALL PRIVILEGES ON lsky.* TO 'lsky'@'%';"
            yellow "FLUSH PRIVILEGES;"
            start_service
            ;;
        3)
            update_service
            ;;
        4)
            uninstall_service
            ;;
        5)
            exit 0
            ;;
        *)
            red "无效选择，请重新输入！"
            ;;
    esac
done
