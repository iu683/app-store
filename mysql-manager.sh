#!/bin/bash
# MySQL Docker 管理菜单

CONTAINER_NAME="mysql8"
MYSQL_ROOT_PASSWORD="123456"
MYSQL_DATABASE="mydb"
MYSQL_USER="myuser"
MYSQL_PASSWORD="mypassword"
MYSQL_VERSION="8.0"
DATA_DIR="/opt/mysql/data"
CONF_DIR="/opt/mysql/conf"

function install_mysql() {
    mkdir -p "$DATA_DIR" "$CONF_DIR"

    # 创建 utf8mb4 配置文件
    cat > "$CONF_DIR/my.cnf" <<'EOF'
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_general_ci

[client]
default-character-set=utf8mb4

[mysql]
default-character-set=utf8mb4
EOF

    docker run --name $CONTAINER_NAME \
        -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
        -e MYSQL_DATABASE=$MYSQL_DATABASE \
        -e MYSQL_USER=$MYSQL_USER \
        -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
        -p 3306:3306 \
        -v $DATA_DIR:/var/lib/mysql \
        -v $CONF_DIR:/etc/mysql/conf.d \
        --restart unless-stopped \
        -d mysql:$MYSQL_VERSION

    echo "✅ MySQL 容器已启动，root 密码: $MYSQL_ROOT_PASSWORD"
}

function start_mysql() {
    docker start $CONTAINER_NAME
}

function stop_mysql() {
    docker stop $CONTAINER_NAME
}

function restart_mysql() {
    docker restart $CONTAINER_NAME
}

function logs_mysql() {
    docker logs -f $CONTAINER_NAME
}

function remove_mysql_keep_data() {
    docker rm -f $CONTAINER_NAME
    echo "✅ 容器已删除，数据保留在 $DATA_DIR"
}

function remove_mysql_and_data() {
    docker rm -f $CONTAINER_NAME
    rm -rf "$DATA_DIR" "$CONF_DIR"
    echo "✅ 容器和数据已删除"
}

while true; do
    clear
    echo "=== MySQL Docker 管理菜单 ==="
    echo "1. 安装并启动 MySQL (持久化 & UTF8MB4)"
    echo "2. 启动 MySQL"
    echo "3. 停止 MySQL"
    echo "4. 重启 MySQL"
    echo "5. 查看 MySQL 日志"
    echo "6. 删除容器 (保留数据)"
    echo "7. 删除容器和数据"
    echo "0. 退出"
    echo "==========================="
    read -p "请输入选项: " choice

    case $choice in
        1) install_mysql ;;
        2) start_mysql ;;
        3) stop_mysql ;;
        4) restart_mysql ;;
        5) logs_mysql ;;
        6) remove_mysql_keep_data ;;
        7) remove_mysql_and_data ;;
        0) exit 0 ;;
        *) echo "❌ 无效选项" ;;
    esac

    read -p "按回车继续..."
done
