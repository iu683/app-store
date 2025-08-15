#!/bin/bash
# ========================================
# Sub-Store 一键管理脚本（增强版）
# 功能：安装/卸载/更新/日志/公网IP提示
# ========================================

# ===== 配置部分 =====
CONTAINER_NAME="sub-store"
IMAGE_NAME="xream/sub-store"
DATA_DIR="/root/sub-store-data"
PORT=3005
BACKEND_PATH="/QYVa9TxuMpyQ2ZOsZt96"
CRON="0 0 * * *"

# ===== 获取公网IP =====
get_public_ip() {
    local IP
    IP=$(curl -s ipv4.ip.sb || curl -s ifconfig.me || curl -s ipinfo.io/ip)
    echo "$IP"
}

# ===== 安装/启动函数 =====
install_substore() {
    echo -e "\033[32m[INFO] 开始安装/启动 Sub-Store...\033[0m"
    docker stop $CONTAINER_NAME >/dev/null 2>&1
    docker rm $CONTAINER_NAME >/dev/null 2>&1

    docker run -d \
        --name $CONTAINER_NAME \
        --restart=always \
        -e "SUB_STORE_BACKEND_SYNC_CRON=$CRON" \
        -e "SUB_STORE_FRONTEND_BACKEND_PATH=$BACKEND_PATH" \
        -p ${PORT}:3001 \
        -v ${DATA_DIR}:/opt/app/data \
        $IMAGE_NAME

    local PUBLIC_IP
    PUBLIC_IP=$(get_public_ip)
    echo -e "\033[32m[OK] Sub-Store 安装/启动完成！\033[0m"
    echo -e "访问地址：\033[36mhttp://${PUBLIC_IP}:${PORT}?api=http://${PUBLIC_IP}:${PORT}${BACKEND_PATH}\033[0m"
}

# ===== 卸载函数 =====
uninstall_substore() {
    echo -e "\033[33m[INFO] 正在卸载 Sub-Store...\033[0m"
    docker stop $CONTAINER_NAME >/dev/null 2>&1
    docker rm $CONTAINER_NAME >/dev/null 2>&1
    echo -e "\033[32m[OK] Sub-Store 已卸载。\033[0m"
}

# ===== 更新函数 =====
update_substore() {
    echo -e "\033[33m[INFO] 更新镜像并重启容器...\033[0m"
    docker pull $IMAGE_NAME
    install_substore
    echo -e "\033[32m[OK] 更新完成！\033[0m"
}

# ===== 日志查看 =====
view_logs() {
    echo -e "\033[34m[INFO] 查看 Sub-Store 日志，按 Ctrl+C 退出...\033[0m"
    docker logs -f $CONTAINER_NAME
}

# ===== 菜单 =====
while true; do
    echo -e "\n\033[34m=== Sub-Store 一键管理 ===\033[0m"
    echo "1. 安装 / 启动"
    echo "2. 卸载"
    echo "3. 更新"
    echo "4. 查看日志"
    echo "0. 退出"
    read -p "请输入选项: " choice

    case $choice in
        1) install_substore ;;
        2) uninstall_substore ;;
        3) update_substore ;;
        4) view_logs ;;
        0) exit 0 ;;
        *) echo -e "\033[31m[ERROR] 无效选项\033[0m" ;;
    esac
done
