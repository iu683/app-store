#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

CONTAINER_NAME="openlist"
IMAGE_NAME="openlistteam/openlist:latest"
PORT=5244
DATA_DIR="/etc/openlist"

# ================== 获取公网 IP ==================
get_ip() {
    IP=$(curl -s https://api.ip.sb/ip)
    if [[ ! "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        IP=$(curl -s https://api.ipify.org)
    fi
    if [[ ! "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        IP=$(hostname -I | awk '{print $1}')
    fi
    echo "$IP"
}

# ================== 暂停并返回菜单 ==================
pause() {
    read -p "按回车返回菜单..." 
    show_menu
}

# ================== 端口检查函数 ==================
check_port() {
    while true; do
        if lsof -i:$PORT &>/dev/null; then
            echo -e "${RED}端口 $PORT 已被占用！${RESET}"
        elif ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then
            echo -e "${RED}端口号不合法，请输入 1024-65535 的数字${RESET}"
        else
            break
        fi
        read -p "请输入新的端口号: " PORT
    done
}

# ================== 菜单函数 ==================
show_menu() {
    clear
    echo -e "${CYAN}================== Openlist Docker 管理 ==================${RESET}"
    echo -e "${GREEN}01.${RESET} 安装并运行 Openlist"
    echo -e "${GREEN}02.${RESET} 停止 Openlist 容器"
    echo -e "${GREEN}03.${RESET} 启动 Openlist 容器"
    echo -e "${GREEN}04.${RESET} 重启 Openlist 容器"
    echo -e "${GREEN}05.${RESET} 查看 Openlist 容器状态"
    echo -e "${GREEN}06.${RESET} 查看 Openlist 日志"
    echo -e "${GREEN}07.${RESET} 更新 Openlist 镜像并重启"
    echo -e "${GREEN}08.${RESET} 删除 Openlist 容器"
    echo -e "${GREEN}0.${RESET} 退出"
    echo -e "${CYAN}=======================================================${RESET}"
    read -p "请输入操作编号: " choice
    case "$choice" in
        1) install_run ;;
        2) stop_container ;;
        3) start_container ;;
        4) restart_container ;;
        5) status_container ;;
        6) logs_container ;;
        7) update_container ;;
        8) remove_container ;;
        0) exit 0 ;;
        *) echo -e "${RED}输入错误，请重新选择！${RESET}"; sleep 2; show_menu ;;
    esac
}

# ================== 功能函数 ==================
install_run() {
    check_port

    # 安装 Docker（如果未安装）
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}检测到 Docker 未安装，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker
        systemctl start docker
    fi

    # 创建数据目录
    mkdir -p $DATA_DIR

    # 开放端口（firewalld）
    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-port=$PORT/tcp
        firewall-cmd --reload
    fi

    # 删除已有容器
    if docker ps -a | grep -q $CONTAINER_NAME; then
        docker rm -f $CONTAINER_NAME
    fi

    # 拉取镜像并运行
    docker pull $IMAGE_NAME
    docker run --user $(id -u):$(id -g) -d --restart=unless-stopped \
        -v $DATA_DIR:/opt/openlist/data -p $PORT:$PORT -e UMASK=022 \
        --name $CONTAINER_NAME $IMAGE_NAME

    IP=$(get_ip)
    echo -e "${GREEN}Openlist 已启动，访问: http://$IP:$PORT${RESET}"
    pause
}

stop_container() {
    docker stop $CONTAINER_NAME
    echo -e "${GREEN}Openlist 已停止${RESET}"
    pause
}

start_container() {
    docker start $CONTAINER_NAME
    echo -e "${GREEN}Openlist 已启动${RESET}"
    pause
}

restart_container() {
    docker restart $CONTAINER_NAME
    echo -e "${GREEN}Openlist 已重启${RESET}"
    pause
}

status_container() {
    docker ps -a | grep $CONTAINER_NAME
    pause
}

logs_container() {
    docker logs -f $CONTAINER_NAME
    pause
}

update_container() {
    check_port
    echo -e "${YELLOW}正在拉取最新镜像...${RESET}"
    docker pull $IMAGE_NAME

    if docker ps -a | grep -q $CONTAINER_NAME; then
        docker rm -f $CONTAINER_NAME
    fi

    docker run --user $(id -u):$(id -g) -d --restart=unless-stopped \
        -v $DATA_DIR:/opt/openlist/data -p $PORT:$PORT -e UMASK=022 \
        --name $CONTAINER_NAME $IMAGE_NAME

    IP=$(get_ip)
    echo -e "${GREEN}Openlist 已更新并重新启动，访问: http://$IP:$PORT${RESET}"
    pause
}

remove_container() {
    docker rm -f $CONTAINER_NAME
    echo -e "${GREEN}Openlist 容器已删除${RESET}"
    pause
}

# ================== 脚本入口 ==================
while true
do
    show_menu
done
