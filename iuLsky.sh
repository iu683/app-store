#!/bin/bash

WORK_DIR="/wwwroot/docker/lsky"
LOG_FILE="${WORK_DIR}/lsky_deploy.log"
MYSQL_CONTAINER="db_mysql"
MYSQL_ROOT_PWD="root123456"
LSKY_DB_NAME="lsky"
LSKY_DB_USER="lsky"
LSKY_DB_PWD="998021"
LSKY_PORT="1128"
NETWORK_NAME="lsky_net"

# 颜色
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 日志函数
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# 检查 MySQL 容器
check_mysql_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${MYSQL_CONTAINER}$"; then
        log "[✔] 检测到 MySQL 容器 ${MYSQL_CONTAINER}"
    else
        log "[✘] 未检测到 MySQL 容器 ${MYSQL_CONTAINER}，请先创建 MySQL 容器"
        exit 1
    fi
}

# 等待 MySQL 启动
wait_for_mysql() {
    log "[...] 等待 MySQL 启动..."
    for i in {1..30}; do
        if docker exec ${MYSQL_CONTAINER} mysqladmin ping -h localhost -p${MYSQL_ROOT_PWD} --silent &>/dev/null; then
            log "[✔] MySQL 已启动"
            return
        fi
        sleep 2
    done
    log "[✘] MySQL 启动超时"
    exit 1
}

# 创建 Lsky 数据库和用户
create_lsky_db() {
    log "[...] 创建数据库 ${LSKY_DB_NAME} 和用户 ${LSKY_DB_USER}"
    docker exec -i ${MYSQL_CONTAINER} mysql -uroot -p${MYSQL_ROOT_PWD} <<EOF
CREATE DATABASE IF NOT EXISTS \`${LSKY_DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${LSKY_DB_USER}'@'%' IDENTIFIED BY '${LSKY_DB_PWD}';
GRANT ALL PRIVILEGES ON \`${LSKY_DB_NAME}\`.* TO '${LSKY_DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    log "[✔] 数据库和用户创建完成"
}

# 检查并创建网络
create_network() {
    if ! docker network ls | grep -q "$NETWORK_NAME"; then
        docker network create $NETWORK_NAME
        log "[✔] 已创建网络 $NETWORK_NAME"
    else
        log "[✔] 网络 $NETWORK_NAME 已存在"
    fi

    if ! docker network inspect $NETWORK_NAME | grep -q "$MYSQL_CONTAINER"; then
        docker network connect $NETWORK_NAME $MYSQL_CONTAINER
        log "[✔] MySQL 已加入网络 $NETWORK_NAME"
    else
        log "[✔] MySQL 已在网络 $NETWORK_NAME 中"
    fi
}

# 创建 docker-compose.yml
create_docker_compose() {
    mkdir -p ${WORK_DIR}
    cat > ${WORK_DIR}/docker-compose.yml <<EOF
version: '3'
services:
  lskypro:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    hostname: lsky
    container_name: lsky
    environment:
      - WEB_PORT=8089
      - DB_HOST=${MYSQL_CONTAINER}
      - DB_DATABASE=${LSKY_DB_NAME}
      - DB_USERNAME=${LSKY_DB_USER}
      - DB_PASSWORD=${LSKY_DB_PWD}
    volumes:
      - ./data:/var/www/html/
    ports:
      - "${LSKY_PORT}:8089"
    networks:
      - $NETWORK_NAME

networks:
  $NETWORK_NAME:
    external: true
EOF
    log "[✔] docker-compose.yml 已生成"
}

# 部署 Lsky Pro
deploy_lsky() {
    check_mysql_container
    wait_for_mysql
    create_lsky_db
    create_network
    create_docker_compose
    cd ${WORK_DIR} && docker-compose up -d
    log "[✔] Lsky Pro 部署完成！访问：http://IP:${LSKY_PORT}"
}

# 更新 Lsky Pro
update_lsky() {
    cd ${WORK_DIR} && docker-compose pull && docker-compose up -d
    log "[✔] Lsky Pro 更新完成"
}

# 卸载 Lsky Pro
uninstall_lsky() {
    cd ${WORK_DIR} && docker-compose down
    log "[✔] Lsky Pro 已停止"
    echo -e "${YELLOW}是否删除 Lsky 数据文件（不包括 MySQL 数据）？[y/N]${RESET}"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf ${WORK_DIR}/data
        log "[✔] Lsky 数据已删除"
    fi
}

# 菜单
while true; do
    echo -e "${GREEN}====== Lsky Pro 管理菜单 ======${RESET}"
    echo "1. 部署 Lsky Pro"
    echo "2. 更新 Lsky Pro"
    echo "3. 卸载 Lsky Pro"
    echo "4. 查看日志"
    echo "0. 退出"
    read -p "请输入选项: " choice
    case $choice in
        1) deploy_lsky ;;
        2) update_lsky ;;
        3) uninstall_lsky ;;
        4) 
            if [[ -f "$LOG_FILE" ]]; then
                echo -e "${YELLOW}====== Lsky 部署日志 ======${RESET}"
                cat "$LOG_FILE"
            else
                echo -e "${RED}日志文件不存在${RESET}"
            fi
            ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
done
