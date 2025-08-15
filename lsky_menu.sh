#!/bin/bash
#========================================
# Lsky Pro 部署 & 管理 菜单脚本（自动配置数据库）
# Author: xiaoxim 专用
#========================================

WORK_DIR="/wwwroot/docker/lsky"
LSKY_PORT=1128
LSKY_CONTAINER="lskypro"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit

# 彩色输出
green()  { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
red()    { echo -e "\033[31m$1\033[0m"; }
get_ip() { hostname -I 2>/dev/null | awk '{print $1}'; }

# 检查端口
check_port() {
    if lsof -i:"$LSKY_PORT" 2>/dev/null | grep -q LISTEN; then
        red "端口 $LSKY_PORT 已被占用，请修改脚本中的 LSKY_PORT 后重试！"
        exit 1
    fi
}

# 自动在 MySQL 创建数据库和用户
init_mysql_user() {
    local mysql_container=$1
    local root_pass=$2
    local db_name=$3
    local user=$4
    local pass=$5
    green "初始化 MySQL 数据库和用户..."
    docker exec -i "$mysql_container" mysql -uroot -p"$root_pass" <<EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\`;
CREATE USER IF NOT EXISTS '$user'@'%' IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$user'@'%';
FLUSH PRIVILEGES;
EOF
}

# 生成 docker-compose.yml (方案A)
generate_compose_a() {
    read -rp "请输入 MySQL root 密码: " MYSQL_ROOT_PASSWORD
    read -rp "请输入数据库名称: " MYSQL_DATABASE
    read -rp "请输入数据库用户名: " MYSQL_USER
    read -rp "请输入数据库密码: " MYSQL_PASS

cat > docker-compose.yml <<EOF
version: '3'
services:
  lskypro:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    container_name: ${LSKY_CONTAINER}
    environment:
      - WEB_PORT=8089
      - DB_HOST=mysql-lsky
      - DB_DATABASE=${MYSQL_DATABASE}
      - DB_USERNAME=${MYSQL_USER}
      - DB_PASSWORD=${MYSQL_PASS}
    volumes:
      - ./data:/var/www/html/
    ports:
      - "${LSKY_PORT}:8089"
    networks:
      - lsky-net

  mysql-lsky:
    image: mysql:5.7.22
    restart: unless-stopped
    container_name: mysql-lsky
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf:/etc/mysql
      - ./mysql/log:/var/log/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    networks:
      - lsky-net

networks:
  lsky-net: {}
EOF

    docker-compose up -d
    sleep 10
    init_mysql_user "mysql-lsky" "$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" "$MYSQL_USER" "$MYSQL_PASS"
}

# 生成 docker-compose.yml (方案B)
generate_compose_b() {
    read -rp "请输入已有 MySQL 容器名: " MYSQL_CONTAINER
    read -rp "请输入 MySQL root 密码: " MYSQL_ROOT_PASSWORD
    read -rp "请输入数据库名称: " MYSQL_DATABASE
    read -rp "请输入数据库用户名: " MYSQL_USER
    read -rp "请输入数据库密码: " MYSQL_PASS

    docker network create lsky_net &>/dev/null
    docker network connect lsky_net "$MYSQL_CONTAINER" &>/dev/null

cat > docker-compose.yml <<EOF
version: '3'
services:
  lskypro:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
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
      - "${LSKY_PORT}:8089"
    networks:
      - lsky_net

networks:
  lsky_net:
    external: true
EOF

    docker-compose up -d
    init_mysql_user "$MYSQL_CONTAINER" "$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" "$MYSQL_USER" "$MYSQL_PASS"
}

# 启动完成提示
finish_msg() {
    local ip=$(get_ip)
    local pub_ip=$(curl -s ifconfig.me || echo "公网IP获取失败")
    green "部署完成！"
    echo "内网访问: http://${ip}:${LSKY_PORT}"
    echo "公网访问: http://${pub_ip}:${LSKY_PORT}"
}

# 更新 Lsky Pro
update_lsky() {
    green "更新 Lsky Pro..."
    docker-compose pull lskypro
    docker-compose up -d
    green "更新完成！"
}

# 卸载 Lsky Pro
uninstall_lsky() {
    read -rp "是否保留数据? [y/N]: " keep
    docker-compose down
    if [[ ! "$keep" =~ ^[Yy]$ ]]; then
        rm -rf "$WORK_DIR"
        green "已删除所有文件和数据。"
    else
        green "已卸载 Lsky Pro，但保留了数据。"
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
            finish_msg
            ;;
        2)
            check_port
            generate_compose_b
            finish_msg
            ;;
        3)
            update_lsky
            ;;
        4)
            uninstall_lsky
            ;;
        5)
            exit 0
            ;;
        *)
            red "无效选择，请重新输入！"
            ;;
    esac
done
