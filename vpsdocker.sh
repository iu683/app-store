#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"
BOLD="\033[1m"

# ================== 菜单函数 ==================
show_menu() {
    clear
    # 标题边框和文字都用绿色
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}          Docker 应用管理菜单${RESET}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${RESET}\n"

    # 菜单项全部改为绿色
    echo -e "${GREEN}[01] 安装/管理 Docker${RESET}"
    echo -e "${GREEN}[02] MySQL 数据管理${RESET}"
    echo -e "${GREEN}[03] Wallos 订阅${RESET}"
    echo -e "${GREEN}[04] Kuma-Mieru${RESET}"
    echo -e "${GREEN}[05] 彩虹聚合 DNS${RESET}"
    echo -e "${GREEN}[06] XTrafficDash${RESET}"
    echo -e "${GREEN}[07] Nexus Terminal${RESET}"
    echo -e "${GREEN}[08] VPS 价值计算${RESET}"
    echo -e "${GREEN}[09] 密码管理 (Vaultwarden)${RESET}"
    echo -e "${GREEN}[10] Sun-Panel${RESET}"
    echo -e "${GREEN}[11] SPlayer 音乐${RESET}"
    echo -e "${GREEN}[12] Vertex${RESET}"
    echo -e "${GREEN}[13] AutoBangumi${RESET}"
    echo -e "${GREEN}[14] MoviePilot${RESET}"
    echo -e "${GREEN}[15] Foxel${RESET}"
    echo -e "${GREEN}[16] STB 图床${RESET}"
    echo -e "${GREEN}[17] OCI 抢机${RESET}"
    echo -e "${GREEN}[18] y探长${RESET}"
    echo -e "${GREEN}[19] Sub-store${RESET}"
    echo -e "${GREEN}[20] Poste.io 邮局${RESET}"
    echo -e "${GREEN}[21] WebSSH${RESET}"
    echo -e "${GREEN}[22] Openlist${RESET}"
    echo -e "${GREEN}[23] qBittorrent v4.6.3${RESET}"
    echo -e "${GREEN}[24] 音乐服务${RESET}"
    echo -e "${GREEN}[25] 兰空图床${RESET}"
    echo -e "${GREEN}[26] 兰空图床 (无 MySQL)${RESET}\n"

    echo -e "${GREEN}[88] 更新菜单脚本${RESET}"
    echo -e "${GREEN}[99] 卸载菜单脚本${RESET}"
    echo -e "${GREEN}[0] 退出${RESET}\n"
}

# ================== 功能函数 ==================
install_service() {
    case "$1" in
        1|01) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/Docker.sh) ;;
        2|02) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/mysql-manager.sh) ;;
        3|03) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/install_wallos.sh) ;;
        4|04) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/kuma-mieru-manager.sh) ;;
        5|05) bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/dnss.sh) ;;
        6|06) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/xtrafficdash.sh) ;;
        7|07) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/nexus-terminal.sh) ;;
        8|08) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/vps-value-manager.sh) ;;
        9|09) bash <(curl -sL https://raw.githubusercontent.com/iu683/vps-tools/main/vaultwarden.sh) ;;
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
        88) echo -e "${GREEN}正在更新脚本...${RESET}"
            tmp_file=$(mktemp)
            curl -fsSL -o "$tmp_file" https://raw.githubusercontent.com/iu683/app-store/main/vpsdocker.sh
            chmod +x "$tmp_file"
            mv "$tmp_file" "$0"
            echo -e "${GREEN}更新完成!${RESET}" ;;
        99) echo -e "${GREEN}正在卸载脚本...${RESET}"
            rm -rf "$HOME/vps-manager"
            echo -e "${GREEN}卸载完成!${RESET}"; exit 0 ;;
        0) echo -e "${GREEN}退出脚本...${RESET}"; exit 0 ;;
        *) echo -e "${GREEN}无效选择，请重新输入!${RESET}" ;;
    esac
}

# ================== 主循环 ==================
while true; do
    show_menu
    read -p "请输入编号: " choice
    install_service $choice
    echo -e "\n按 Enter 返回菜单..."
    read
done
