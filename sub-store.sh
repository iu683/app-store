#!/bin/bash
# Sub-Store 一键管理脚本
# 作者: ChatGPT
# 说明: 支持安装、启动、停止、重启、日志、更新、卸载

DATA_DIR="/root/sub-store-data"
CONTAINER_NAME="sub-store"
IMAGE_NAME="xream/sub-store"
PORT="3001"

# 生成随机路径
generate_path() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20
}

install_substore() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "⚠️  容器已存在，请先卸载或重启。"
        return
    fi

    RANDOM_PATH="/$(generate_path)"
    echo "✅  启动路径: ${RANDOM_PATH}"

    mkdir -p "$DATA_DIR"
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart=always \
        -e "SUB_STORE_CRON=0 0 * * *" \
        -e "SUB_STORE_FRONTEND_BACKEND_PATH=${RANDOM_PATH}" \
        -p ${PORT}:${PORT} \
        -v ${DATA_DIR}:/opt/app/data \
        ${IMAGE_NAME}

    echo "🚀 Sub-Store 已启动，请访问: http://<服务器IP>:${PORT}${RANDOM_PATH}"
}

stop_substore() {
    docker stop "$CONTAINER_NAME" 2>/dev/null && echo "✅ 已停止" || echo "⚠️ 容器未运行"
}

start_substore() {
    docker start "$CONTAINER_NAME" 2>/dev/null && echo "✅ 已启动" || echo "⚠️ 容器不存在"
}

restart_substore() {
    docker restart "$CONTAINER_NAME" 2>/dev/null && echo "✅ 已重启" || echo "⚠️ 容器不存在"
}

logs_substore() {
    docker logs -f "$CONTAINER_NAME"
}

update_substore() {
    echo "⬇️ 拉取最新镜像..."
    docker pull ${IMAGE_NAME}
    echo "♻️ 重启容器..."
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"
    install_substore
}

uninstall_substore() {
    docker stop "$CONTAINER_NAME" 2>/dev/null
    docker rm "$CONTAINER_NAME" 2>/dev/null
    read -p "❗ 是否删除数据目录 ${DATA_DIR} ? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$DATA_DIR"
        echo "🗑️ 已删除数据目录"
    fi
    echo "✅ 已卸载 Sub-Store"
}

menu() {
    clear
    echo "===== Sub-Store 一键管理脚本 ====="
    echo "1. 安装 / 启动"
    echo "2. 停止"
    echo "3. 启动"
    echo "4. 重启"
    echo "5. 查看日志"
    echo "6. 更新"
    echo "7. 卸载"
    echo "0. 退出"
    echo "================================"
    read -p "请输入选项: " choice
    case "$choice" in
        1) install_substore ;;
        2) stop_substore ;;
        3) start_substore ;;
        4) restart_substore ;;
        5) logs_substore ;;
        6) update_substore ;;
        7) uninstall_substore ;;
        0) exit 0 ;;
        *) echo "❌ 无效选项" ;;
    esac
}

while true; do
    menu
    read -p "按回车键返回菜单..." dummy
done
