#!/bin/bash
# Lsky Pro 管理脚本
# 路径: /wwwroot/docker/lsky

WORK_DIR="/wwwroot/docker/lsky"
MYSQL_CONTAINER="mysql-lsky"
LSKY_CONTAINER="lskypro"
NETWORK_NAME="lsky-net"

green() { echo -e "\033[32m$1\033[0m"; }
red()   { echo -e "\033[31m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }

# 等待 MySQL 启动
wait_for_mysql() {
    local container=$1
    local root_pass=$2
    green "等待 MySQL 容器启动..."
    for i in {1..30}; do
        if docker exec "$container" mysqladmin ping -uroot -p"$root_pass" --silent &>/dev/null; then
            green "MySQL 已启动，开始初始化数据库..."
            return 0
        fi
        sleep 2
    done
    red "MySQL 启动超时！"
    exit 1
}

# 初始化 MySQL 用户和数据库
init_mysql_user() {
    local container=$1
    local root_pass=$2
    local db_name=$3
    local user=$4
    local pass=$5

    docker exec -i "$container" mysql -uroot -p"$root_pass" <<EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$user'@'%' IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$user'@'%';
FLUSH PRIVILEGES;
EOF
}

# 安装 Lsky Pro + MySQL
install_with_mysql() {
    if [ -d "$WORK_DIR/mysql/data/mysql" ]; then
        red "检测到已有 MySQL 数据文件，请先卸载旧版或删除 $WORK_DIR/mysql/data 后重试！"
        exit 1
    fi

    read -p "请输入 MySQL root 密码: " MYSQL_ROOT_PASSWORD
    read -p "请输入 Lsky 数据库名 (默认: lsky): " DB_NAME
    DB_NAME=${DB_NAME:-lsky}
    read -p "请输入 Lsky 数据库用户名 (默认: lsky): " DB_USER
    DB_USER=${DB_USER:-lsky}
    read -p "请输入 Lsky 数据库密码: " DB_PASS

    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || exit

    cat > docker-compose.yml <<EOF
version: '3'
services:
  lskypro:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    hostname: $LSKY_CONTAINER
    container_name: $LSKY_CONTAINER
    environment:
      - WEB_PORT=8089
      - DB_HOST=$MYSQL_CONTAINER
      - DB_DATABASE=$DB_NAME
      - DB_USERNAME=$DB_USER
      - DB_PASSWORD=$DB_PASS
    volumes:
      - ./data:/var/www/html/
    ports:
      - "1128:8089"
    networks:
      - $NETWORK_NAME

  $MYSQL_CONTAINER:
    image: mysql:5.7.22
    restart: unless-stopped
    hostname: $MYSQL_CONTAINER
    container_name: $MYSQL_CONTAINER
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf:/etc/mysql
      - ./mysql/log:/var/log/mysql
    environment:
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
    networks:
      - $NETWORK_NAME

networks:
  $NETWORK_NAME: {}
EOF

    docker-compose up -d
    wait_for_mysql "$MYSQL_CONTAINER" "$MYSQL_ROOT_PASSWORD"
    init_mysql_user "$MYSQL_CONTAINER" "$MYSQL_ROOT_PASSWORD" "$DB_NAME" "$DB_USER" "$DB_PASS"

    IP=$(curl -s ifconfig.me)
    green "部署完成！访问地址: http://$IP:1128"
    yellow "数据库信息:"
    echo "  主机: $MYSQL_CONTAINER"
    echo "  数据库: $DB_NAME"
    echo "  用户: $DB_USER"
    echo "  密码: $DB_PASS"
}

# 安装 Lsky Pro (使用已有 MySQL)
install_with_existing_mysql() {
    read -p "请输入 MySQL 容器名: " MYSQL_EXIST_CONTAINER
    read -p "请输入数据库名: " DB_NAME
    read -p "请输入数据库用户名: " DB_USER
    read -p "请输入数据库密码: " DB_PASS

    docker network create $NETWORK_NAME >/dev/null 2>&1 || true
    docker network connect $NETWORK_NAME "$MYSQL_EXIST_CONTAINER" || true

    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || exit

    cat > docker-compose.yml <<EOF
version: '3'
services:
  lskypro:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    hostname: $LSKY_CONTAINER
    container_name: $LSKY_CONTAINER
    environment:
      - WEB_PORT=8089
      - DB_HOST=$MYSQL_EXIST_CONTAINER
      - DB_DATABASE=$DB_NAME
      - DB_USERNAME=$DB_USER
      - DB_PASSWORD=$DB_PASS
    volumes:
      - ./data:/var/www/html/
    ports:
      - "1128:8089"
    networks:
      - $NETWORK_NAME

networks:
  $NETWORK_NAME:
    external: true
EOF

    docker-compose up -d
    IP=$(curl -s ifconfig.me)
    green "部署完成！访问地址: http://$IP:1128"
}

# 更新 Lsky Pro
update_lsky() {
    cd "$WORK_DIR" || exit
    docker-compose pull lskypro
    docker-compose up -d
    green "Lsky Pro 已更新完成！"
}

# 查看日志
show_logs() {
    docker logs -f $LSKY_CONTAINER
}

# 卸载
uninstall_lsky() {
    cd "$WORK_DIR" || exit
    docker-compose down
    read -p "是否删除数据文件? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        rm -rf "$WORK_DIR"
        green "数据已删除！"
    fi
    green "Lsky Pro 已卸载完成！"
}

# 菜单
while true; do
    echo "===== Lsky Pro 管理脚本 ====="
    echo "1) 安装 Lsky Pro + MySQL"
    echo "2) 安装 Lsky Pro (使用已有 MySQL)"
    echo "3) 更新 Lsky Pro"
    echo "4) 查看 Lsky Pro 日志"
    echo "5) 卸载 Lsky Pro"
    echo "0) 退出"
    read -p "请选择: " CHOICE
    case $CHOICE in
        1) install_with_mysql ;;
        2) install_with_existing_mysql ;;
        3) update_lsky ;;
        4) show_logs ;;
        5) uninstall_lsky ;;
        0) exit 0 ;;
        *) red "无效的选择" ;;
    esac
done
