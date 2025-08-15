#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

CONTAINER_NAME="webssh"
IMAGE_NAME="cmliu/webssh:latest"
PORT=8888

# ================== iptables 检查函数 ==================
check_iptables() {
    MODE=$(sudo update-alternatives --query iptables | grep 'Value: ' | awk '{print $2}')
    if [[ "$MODE" == *"nft"* ]]; then
        echo -e "${YELLOW}检测到 iptables 使用 nft 模式，正在切换到 legacy 模式...${RESET}"
        sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
        sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
        sudo systemctl restart docker
        echo -e "${GREEN}已切换 iptables 为 legacy 并重启 Docker${RESET}"
    fi
}

# ================== 端口检查函数 ==================
check_port() {
    while lsof -i:$PORT &>/dev/null; do
        echo -e "${RED}端口 $PORT 已被占用！${RESET}"
        read -p "请输入新的端口号: " PORT
    done
}

# ================== 菜单函数 ==================
show_menu() {
    clear
    echo -e "${CYAN}================== WebSSH Docker 管理 ==================${RESET}"
    echo -e "${GREEN}01.${RESET} 安装并运行 WebSSH"
    echo -e "${GREEN}02.${RESET} 停止 WebSSH 容器"
    echo -e "${GREEN}03.${RESET} 启动 WebSSH 容器"
    echo -e "${GREEN}04.${RESET} 重启 WebSSH 容器"
    echo -e "${GREEN}05.${RESET} 查看 WebSSH 容器状态"
    echo -e "${GREEN}06.${RESET} 查看 WebSSH 日志"
    echo -e "${GREEN}07.${RESET} 更新 WebSSH 镜像并重启"
    echo -e "${GREEN}08.${RESET} 删除 WebSSH 容器"
    echo -e "${GREEN}09.${RESET} 卸载 WebSSH（保留 Docker）"
    echo -e "${GREEN}10.${RESET} 设置菜单开机自启"
    echo -e "${GREEN}11.${RESET} 显示 WebSSH 访问地址"
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
        9) uninstall_webssh ;;
        10) enable_autostart ;;
        11) show_access_url ;;
        0) exit 0 ;;
        *) echo -e "${RED}输入错误，请重新选择！${RESET}"; sleep 2; show_menu ;;
    esac
}

# ================== 功能函数 ==================
install_run() {
    check_iptables
    check_port

    # 安装 Docker（如果未安装）
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}检测到 Docker 未安装，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker
        systemctl start docker
    fi

    # 开放端口（适用于 firewalld）
    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-port=$PORT/tcp
        firewall-cmd --reload
    fi

    # 拉取镜像并运行
    docker pull $IMAGE_NAME
    docker run -d --name $CONTAINER_NAME --restart always -p $PORT:8888 $IMAGE_NAME

    # 获取 VPS IP 并显示访问地址
    VPS_IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}WebSSH 已启动，访问: http://$VPS_IP:$PORT${RESET}"

    read -p "按回车返回菜单..." 
    show_menu
}

stop_container() {
    docker stop $CONTAINER_NAME
    echo -e "${GREEN}WebSSH 已停止${RESET}"
    read -p "按回车返回菜单..." 
    show_menu
}

start_container() {
    docker start $CONTAINER_NAME
    echo -e "${GREEN}WebSSH 已启动${RESET}"
    read -p "按回车返回菜单..." 
    show_menu
}

restart_container() {
    docker restart $CONTAINER_NAME
    echo -e "${GREEN}WebSSH 已重启${RESET}"
    read -p "按回车返回菜单..." 
    show_menu
}

status_container() {
    docker ps -a | grep $CONTAINER_NAME
    read -p "按回车返回菜单..." 
    show_menu
}

logs_container() {
    docker logs -f $CONTAINER_NAME
    read -p "按回车返回菜单..." 
    show_menu
}

update_container() {
    check_iptables
    check_port
    echo -e "${YELLOW}正在拉取最新镜像...${RESET}"
    docker pull $IMAGE_NAME
    if docker ps -a | grep -q $CONTAINER_NAME; then
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
    docker run -d --name $CONTAINER_NAME --restart always -p $PORT:8888 $IMAGE_NAME

    VPS_IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}WebSSH 已更新并重新启动，访问: http://$VPS_IP:$PORT${RESET}"

    read -p "按回车返回菜单..." 
    show_menu
}

remove_container() {
    docker rm -f $CONTAINER_NAME
    echo -e "${GREEN}WebSSH 容器已删除${RESET}"
    read -p "按回车返回菜单..." 
    show_menu
}

uninstall_webssh() {
    read -p "确定要卸载 WebSSH 容器和镜像吗？(y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker rm -f $CONTAINER_NAME 2>/dev/null
        docker rmi $IMAGE_NAME 2>/dev/null
        echo -e "${GREEN}WebSSH 容器和镜像已删除${RESET}"
    fi
    read -p "按回车返回菜单..." 
    show_menu
}

enable_autostart() {
    SCRIPT_PATH="$(readlink -f "$0")"
    SERVICE_FILE="/etc/systemd/system/webssh_menu.service"

    echo -e "${YELLOW}正在创建 systemd 服务文件...${RESET}"
    sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=WebSSH Docker 菜单管理器
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=$SCRIPT_PATH
Restart=always
User=$(whoami)
WorkingDirectory=$(pwd)

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable webssh_menu.service
    sudo systemctl start webssh_menu.service

    echo -e "${GREEN}菜单已设置开机自启${RESET}"
    read -p "按回车返回菜单..." 
    show_menu
}

show_access_url() {
    VPS_IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}WebSSH 访问地址: http://$VPS_IP:$PORT${RESET}"
    read -p "按回车返回菜单..." 
    show_menu
}

# ================== 脚本入口 ==================
while true
do
    show_menu
done
