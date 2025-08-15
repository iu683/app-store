#!/bin/bash

# ==============================
# Lsky Pro 管理脚本
# 安装 / 更新 / 卸载 / 查看日志 / 自动端口检测
# ==============================

# 颜色输出函数
green() { echo -e "\033[32m$1\033[0m"; }
red()   { echo -e "\033[31m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }

WORK_DIR="/wwwroot/docker/lsky"
NETWORK_NAME="lsky_net"
LSKY_CONTAINER="lskypro"
MYSQL_CONTAINER="mysql-lsky"

mkdir -p "$WORK_DIR"

# 获取外网 IP
get_ip() {
    curl -s ipv4.ip.sb || curl -s ifconfig.me || curl -s ipinfo.io/ip
}

# 检测可用端口（默认 1128）
get_free_port() {
    local port=$1
    while ss -tuln | grep -q ":$port "; do
        ((port++))
    done
    echo "$port"
}

# 初始化 MySQL 数据库和用户
init_mysql_user() {
    local mysql_container=$1
    local root_pass=$2
    local db_name=$3
    local user=$4
    local pass=$5

    green "等待 MySQL 容器启动..."
    for i in {1..30}; do
        if docker exec "$mysql_container" mysqladmin ping -uroot -p"$root_pass" --silent &>/dev/null; then
            green "MySQL 已启动，开始初始化数据库..."
            break
        fi
        sleep 2
    done

    docker exec -i "$mysql_container" mysql -uroot -p"$root_pass" <<EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$user'@'%' IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$user'@'%';
FLUSH PRIVILEGES;
EOF
}

# 安装 Lsky Pro（新建 MySQL）
install_with_mysql() {
    cd "$WORK_DIR" || exit 1
    read -rp "请输入 MySQL root 密码: " MYSQL_ROOT_PASSWORD
    read -rp "请输入数据库名称: " MYSQL_DATABASE
    read -rp "请输入新建的数据库用户名: " MYSQL_USER
    read -rp "请输入该用户密码: " MYSQL_PASS

    WEB_PORT=$(get_free_port 1128)
    green "使用端口: $WEB_PORT"

    cat > docker-compose.yml <<EOF
version: '3'
services:
  ${LSKY_CONTAINER}:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    hostname: lskypro
    container_name: ${LSKY_CONTAINER}
    environment:
      - WEB_PORT=8089
      - DB_HOST=${MYSQL_CONTAINER}
      - DB_DATABASE=${MYSQL_DATABASE}
      - DB_USERNAME=${MYSQL_USER}
      - DB_PASSWORD=${MYSQL_PASS}
    volumes:
      - ./data:/var/www/html/
    ports:
      - "${WEB_PORT}:8089"
    networks:
      - ${NETWORK_NAME}

  ${MYSQL_CONTAINER}:
    image: mysql:5.7.22
    restart: unless-stopped
    hostname: ${MYSQL_CONTAINER}
    container_name: ${MYSQL_CONTAINER}
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf:/etc/mysql
      - ./mysql/log:/var/log/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    networks:
      - ${NETWORK_NAME}

networks:
  ${NETWORK_NAME}: {}
EOF

    docker-compose up -d
    init_mysql_user "${MYSQL_CONTAINER}" "$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" "$MYSQL_USER" "$MYSQL_PASS"

    green "部署完成！访问地址: http://$(get_ip):${WEB_PORT}"
}

# 安装 Lsky Pro（已有 MySQL）
install_with_existing_mysql() {
    cd "$WORK_DIR" || exit 1
    read -rp "请输入 MySQL 容器名称: " MYSQL_CONTAINER_EXIST
    read -rp "请输入数据库名称: " MYSQL_DATABASE
    read -rp "请输入数据库用户名: " MYSQL_USER
    read -rp "请输入数据库密码: " MYSQL_PASS

    WEB_PORT=$(get_free_port 1128)
    green "使用端口: $WEB_PORT"

    docker network create "${NETWORK_NAME}" >/dev/null 2>&1 || true
    docker network connect "${NETWORK_NAME}" "${MYSQL_CONTAINER_EXIST}" || true

    cat > docker-compose.yml <<EOF
version: '3'
services:
  ${LSKY_CONTAINER}:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    hostname: lskypro
    container_name: ${LSKY_CONTAINER}
    environment:
      - WEB_PORT=8089
      - DB_HOST=${MYSQL_CONTAINER_EXIST}
      - DB_DATABASE=${MYSQL_DATABASE}
      - DB_USERNAME=${MYSQL_USER}
      - DB_PASSWORD=${MYSQL_PASS}
    volumes:
      - ./data:/var/www/html/
    ports:
      - "${WEB_PORT}:8089"
    networks:
      - ${NETWORK_NAME}

networks:
  ${NETWORK_NAME}:
    external: true
EOF

    docker-compose up -d
    green "部署完成！访问地址: http://$(get_ip):${WEB_PORT}"
}

# 更新 Lsky Pro
update_lsky() {
    cd "$WORK_DIR" || exit 1
    docker-compose pull
    docker-compose up -d
    green "Lsky Pro 已更新完成！访问地址: http://$(get_ip):$(grep 'ports:' -A 1 docker-compose.yml | tail -n 1 | awk -F':' '{print $1}' | tr -d ' -')"
}

# 卸载 Lsky Pro
uninstall_lsky() {
    cd "$WORK_DIR" || exit 1
    docker-compose down
    read -rp "是否删除数据文件？[y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$WORK_DIR"
        green "已删除 Lsky Pro 数据文件！"
    fi
    green "Lsky Pro 已卸载！"
}

# 查看日志
show_logs() {
    docker logs -f ${LSKY_CONTAINER}
}

# 主菜单
main_menu() {
    clear
    green "========== Lsky Pro 管理菜单 =========="
    echo "1. 安装 Lsky Pro（新建 MySQL）"
    echo "2. 安装 Lsky Pro（已有 MySQL）"
    echo "3. 更新 Lsky Pro"
    echo "4. 卸载 Lsky Pro"
    echo "5. 查看 Lsky Pro 日志"
    echo "======================================"
    read -rp "请选择 [1-5]: " choice

    docker network create "${NETWORK_NAME}" >/dev/null 2>&1 || true

    case $choice in
        1) install_with_mysql ;;
        2) install_with_existing_mysql ;;
        3) update_lsky ;;
        4) uninstall_lsky ;;
        5) show_logs ;;
        *) red "无效选择" ;;
    esac
}

main_menu
