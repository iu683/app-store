#!/bin/bash
# Lsky Pro 一键管理脚本

# 配置
WORK_DIR="/wwwroot/docker/lsky"
MYSQL_CONTAINER="mysql-lsky"
MYSQL_PASSWORD="78dada57"
MYSQL_DATABASE="lsky"
MYSQL_USER="root"
LSKY_CONTAINER="lskypro"
LSKY_PORT=1128

# 自动检测可用端口
find_free_port() {
    local port=$1
    while ss -tuln | grep -q ":$port "; do
        echo "端口 $port 已被占用，尝试下一个..."
        port=$((port + 1))
    done
    echo $port
}

# 安装 Lsky Pro
install_lsky() {
    mkdir -p "${WORK_DIR}"
    cd "${WORK_DIR}" || exit

    LSKY_PORT=$(find_free_port ${LSKY_PORT})

    # 检查 MySQL 容器
    if docker ps -a --format '{{.Names}}' | grep -q "^${MYSQL_CONTAINER}$"; then
        echo "检测到已有 MySQL 容器: ${MYSQL_CONTAINER}"
        if [ "$(docker inspect -f '{{.State.Running}}' ${MYSQL_CONTAINER})" != "true" ]; then
            echo "MySQL 容器未运行，正在启动..."
            docker start ${MYSQL_CONTAINER}
        fi
        MYSQL_SERVICE=""
    else
        MYSQL_SERVICE="
  ${MYSQL_CONTAINER}:
    image: mysql:5.7.22
    restart: unless-stopped
    container_name: ${MYSQL_CONTAINER}
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf:/etc/mysql
      - ./mysql/log:/var/log/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
    networks:
      - lsky-net
"
    fi

    # 生成 docker-compose.yml
    cat > docker-compose.yml <<EOF
version: '3'
services:
  ${LSKY_CONTAINER}:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    container_name: ${LSKY_CONTAINER}
    environment:
      - WEB_PORT=8089
      - DB_HOST=${MYSQL_CONTAINER}
      - DB_DATABASE=${MYSQL_DATABASE}
      - DB_USERNAME=${MYSQL_USER}
      - DB_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - ./data:/var/www/html/
    ports:
      - "${LSKY_PORT}:8089"
    networks:
      - lsky-net
${MYSQL_SERVICE}
networks:
  lsky-net: {}
EOF

    docker compose up -d

    SERVER_IP=$(curl -s ifconfig.me)
    echo "=== 部署完成 ==="
    echo "访问地址: http://${SERVER_IP}:${LSKY_PORT}"
    echo "数据库容器: ${MYSQL_CONTAINER}"
    echo "数据库名: ${MYSQL_DATABASE}"
    echo "数据库用户: ${MYSQL_USER}"
    echo "数据库密码: ${MYSQL_PASSWORD}"
    echo "使用菜单中的“查看日志”选项来查看运行日志"
}

# 更新 Lsky Pro
update_lsky() {
    cd "${WORK_DIR}" || exit
    docker compose pull ${LSKY_CONTAINER}
    docker compose up -d ${LSKY_CONTAINER}
    echo "Lsky Pro 已更新完成！"
}

# 卸载 Lsky Pro
uninstall_lsky() {
    cd "${WORK_DIR}" || exit
    docker compose down
    rm -rf "${WORK_DIR}"
    echo "Lsky Pro 已卸载！"
}

# 查看日志
view_logs() {
    docker logs -f ${LSKY_CONTAINER}
}

# 查看访问信息
view_info() {
    SERVER_IP=$(curl -s ifconfig.me)
    echo "=== Lsky Pro 信息 ==="
    echo "访问地址: http://${SERVER_IP}:${LSKY_PORT}"
    echo "数据库容器: ${MYSQL_CONTAINER}"
    echo "数据库名: ${MYSQL_DATABASE}"
    echo "数据库用户: ${MYSQL_USER}"
    echo "数据库密码: ${MYSQL_PASSWORD}"
}

# 菜单
while true; do
    clear
    echo "=== Lsky Pro 管理菜单 ==="
    echo "1. 安装 Lsky Pro"
    echo "2. 更新 Lsky Pro"
    echo "3. 卸载 Lsky Pro"
    echo "4. 查看日志"
    echo "5. 查看访问信息"
    echo "0. 退出"
    read -rp "请选择操作: " choice
    case "$choice" in
        1) install_lsky ;;
        2) update_lsky ;;
        3) uninstall_lsky ;;
        4) view_logs ;;
        5) view_info ;;
        0) exit 0 ;;
        *) echo "无效选择，请重试。" ;;
    esac
    read -rp "按回车键继续..."
done
