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

    # 获取 VPS IP
    VPS_IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}WebSSH 已启动，访问: http://$VPS_IP:$PORT${RESET}"

    read -p "按回车返回菜单..." 
    show_menu
}

show_access_url() {
    VPS_IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}WebSSH 访问地址: http://$VPS_IP:$PORT${RESET}"
    read -p "按回车返回菜单..." 
    show_menu
}
