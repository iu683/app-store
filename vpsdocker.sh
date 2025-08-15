#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

# ================== 脚本路径 ==================
SCRIPT_DIR="$HOME/vps-manager"
SCRIPT_NAME="vps_menu.sh"
FULL_PATH="$SCRIPT_DIR/$SCRIPT_NAME"

# ================== 更新脚本 ==================
update_script() {
    echo -e "${CYAN}正在更新脚本...${RESET}"
    mkdir -p "$SCRIPT_DIR"
    curl -fsSL -o "$FULL_PATH" \
        https://raw.githubusercontent.com/你的用户名/vps-manager/main/vps_menu.sh
    chmod +x "$FULL_PATH"
    echo -e "${GREEN}更新完成!${RESET}"
}

# ================== 卸载脚本 ==================
uninstall_script() {
    echo -e "${YELLOW}正在卸载脚本...${RESET}"
    rm -rf "$SCRIPT_DIR"
    echo -e "${GREEN}卸载完成!${RESET}"
    exit 0
}

# ================== 菜单函数 ==================
show_menu() {
    clear
    echo -e "${CYAN}====== VPS 一键安装管理菜单 ======${RESET}"
    echo
    # 双列显示
    printf "%-4s %-28s %-4s %-28s\n" "1." "安装管理 Docker" "2." "MySQL 数据管理"
    printf "%-4s %-28s %-4s %-28s\n" "3." "Wallos 订阅" "4." "Kuma-Mieru"
    printf "%-4s %-28s %-4s %-28s\n" "5." "彩虹聚合 DNS" "6." "XTrafficDash"
    printf "%-4s %-28s %-4s %-28s\n" "7." "Nexus Terminal" "8." "VPS 价值计算"
    printf "%-4s %-28s %-4s %-28s\n" "9." "密码管理 (Vaultwarden)" "10." "Sun-Panel"
    printf "%-4s %-28s %-4s %-28s\n" "11." "SPlayer 音乐" "12." "Vertex"
    printf "%-4s %-28s %-4s %-28s\n" "13." "AutoBangumi" "14." "MoviePilot"
    printf "%-4s %-28s %-4s %-28s\n" "15." "Foxel" "16." "STB 图床"
    printf "%-4s %-28s %-4s %-28s\n" "17." "OCI 抢机" "18." "y探长"
    printf "%-4s %-28s %-4s %-28s\n" "19." "Sub-store" "20." "Poste.io 邮局"
    printf "%-4s %-28s %-4s %-28s\n" "21." "WebSSH" "22." "Openlist"
    printf "%-4s %-28s %-4s %-28s\n" "23." "qBittorrent v4.6.3" "24." "音乐服务"
    printf "%-4s %-28s %-4s %-28s\n" "25." "兰空图床" "26." "兰空图床 (无 MySQL)"
    printf "%-4s %-28s %-4s %-28s\n" "88." "更新脚本" "99." "卸载脚本"
    printf "%-4s %-28s\n" "0." "退出"
    echo
    read -p "请输入数字选择操作: " choice
}

# ================== 安装/操作函数 ==================
install_service() {
    case $1 in
        1) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/Docker.sh) ;;
        2) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/mysql-manager.sh) ;;
        3) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/install_wallos.sh) ;;
        4) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/kuma-mieru-manager.sh) ;;
        5) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/dnss.sh) ;;
        6) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/xtrafficdash.sh) ;;
        7) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/nexus-terminal.sh) ;;
        8) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-value-manager.sh) ;;
        9) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/vaultwarden.sh) ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/sun-panel.sh) ;;
        11) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/splayer_manager.sh) ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/vertex_manage.sh) ;;
        13) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/autobangumi_manage.sh) ;;
        14) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/moviepilot_manage.sh) ;;
        15) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/foxel_manage.sh) ;;
        16) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/stb_manager.sh) ;;
        17) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/oci-docker.sh) ;;
        18) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/oci-helper_install.sh) ;;
        19) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/sub-store.sh) ;;
        20) curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh ;;
        21) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/webssh.sh) ;;
        22) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/Openlist.sh) ;;
        23) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/qbittorrent_manage.sh) ;;
        24) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/music_full_auto.sh) ;;
        25) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/lsky_menu.sh) ;;
        26) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/iuLsky.sh) ;;
        88) update_script ;;
        99) uninstall_script ;;
        0) echo -e "${YELLOW}退出脚本...${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选择，请重新输入!${RESET}" ;;
    esac
}

# ================== 主循环 ==================
while true; do
    show_menu
    install_service $choice
    echo -e "${GREEN}操作完成，按回车返回菜单...${RESET}"
    read
done
