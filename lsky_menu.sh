#!/bin/bash
# Lsky Pro 一键部署脚本（带日志、访问地址和管理功能）

WORK_DIR="/wwwroot/docker/lsky"
MYSQL_CONTAINER="mysql-lsky"
MYSQL_PASSWORD="78dada57"
MYSQL_DATABASE="lsky"
ADMIN_EMAIL="arcticfuiry@hotmail.com"
ADMIN_PASSWORD="2635382860"
LSKY_CONTAINER="lskypro"
LSKY_PORT="1128"

mkdir -p $WORK_DIR
cd $WORK_DIR

install_lsky() {
    echo "=== 创建 docker-compose.yml ==="
    cat > docker-compose.yml <<EOF
version: '3'
services:
  lskypro:
    image: halcyonazure/lsky-pro-docker:latest
    restart: unless-stopped
    hostname: lsky
    container_name: lskypro
    environment:
      - WEB_PORT=8089
      - DB_HOST=${MYSQL_CONTAINER}
      - DB_PORT=3306
      - DB_DATABASE=${MYSQL_DATABASE}
      - DB_USERNAME=root
      - DB_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - ./data:/var/www/html/
    ports:
      - "${LSKY_PORT}:8089"
    networks:
      - lsky_net

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
      MYSQL_ROOT_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
    networks:
      - lsky_net

networks:
  lsky_net:
    external: false
EOF

    echo "=== 启动 Lsky Pro 和 MySQL 容器 ==="
    docker compose up -d

    echo "=== 等待 MySQL 启动中（最长 20 秒）==="
    for i in {1..20}; do
        if docker exec ${MYSQL_CONTAINER} mysqladmin -uroot -p${MYSQL_PASSWORD} ping &>/dev/null; then
            echo "MySQL 已启动"
            break
        fi
        sleep 1
    done

    if ! docker exec ${MYSQL_CONTAINER} mysqladmin -uroot -p${MYSQL_PASSWORD} ping &>/dev/null; then
        echo "❌ MySQL 启动失败，日志如下："
        docker logs ${MYSQL_CONTAINER}
        exit 1
    fi

    echo "=== 生成管理员密码哈希 ==="
    HASH=$(docker run --rm alpine sh -c "apk add --no-cache php81 php81-pecl-bcrypt >/dev/null && php81 -r \"echo password_hash('${ADMIN_PASSWORD}', PASSWORD_BCRYPT);\"")

    echo "=== 初始化 Lsky Pro 数据库（创建管理员账号）==="
    docker exec -i ${MYSQL_CONTAINER} mysql -uroot -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} <<EOF
CREATE TABLE IF NOT EXISTS users (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  username varchar(255) NOT NULL,
  email varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  role varchar(50) NOT NULL DEFAULT 'admin',
  created_at timestamp NULL DEFAULT NULL,
  updated_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM users WHERE id=1;
INSERT INTO users (id, username, email, password, role, created_at, updated_at) VALUES
(1, 'admin', '${ADMIN_EMAIL}', '${HASH}', 'admin', NOW(), NOW());
EOF

    SERVER_IP=$(curl -s ifconfig.me)
    echo "=== 部署完成 ==="
    echo "访问地址: http://${SERVER_IP}:${LSKY_PORT}"
    echo "管理员邮箱: ${ADMIN_EMAIL}"
    echo "管理员密码: ${ADMIN_PASSWORD}"
    echo "=== 查看实时日志（按 Ctrl+C 退出）==="
    docker logs -f ${LSKY_CONTAINER}
}

update_lsky() {
    echo "=== 更新 Lsky Pro ==="
    docker compose pull lskypro
    docker compose up -d
    echo "=== Lsky Pro 更新完成，实时日志如下 ==="
    docker logs -f ${LSKY_CONTAINER}
}

view_logs() {
    echo "=== 请选择要查看的日志 ==="
    echo "1. Lsky Pro 日志"
    echo "2. MySQL 日志"
    read -p "输入选择 [1-2]: " log_choice
    case $log_choice in
        1) docker logs -f ${LSKY_CONTAINER} ;;
        2) docker logs -f ${MYSQL_CONTAINER} ;;
        *) echo "无效选择" ;;
    esac
}

uninstall_lsky() {
    echo "=== 卸载 Lsky Pro 和 MySQL 容器 ==="
    docker compose down -v
    rm -rf $WORK_DIR
    echo "卸载完成"
}

menu() {
    echo "=== Lsky Pro 管理脚本 ==="
    echo "1. 安装 Lsky Pro"
    echo "2. 更新 Lsky Pro"
    echo "3. 查看日志"
    echo "4. 卸载 Lsky Pro"
    read -p "请选择操作 [1-4]: " choice
    case $choice in
        1) install_lsky ;;
        2) update_lsky ;;
        3) view_logs ;;
        4) uninstall_lsky ;;
        *) echo "无效选择" ;;
    esac
}

menu
