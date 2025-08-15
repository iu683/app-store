#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ================== 菜单函数 ==================
show_menu() {
    clear
    echo -e "${GREEN}====== VPS 一键安装管理菜单 ======${RESET}\n"

    # 菜单项数组：编号|名称
    menu_items=(
        "01|安装管理 Docker" "02|MySQL 数据管理"
        "03|Wallos 订阅" "04|Kuma-Mieru"
        "05|彩虹聚合 DNS" "06|XTrafficDash"
        "07|Nexus Terminal" "08|VPS 价值计算"
        "09|密码管理 (Vaultwarden)" "10|Sun-Panel"
        "11|SPlayer 音乐" "12|Vertex"
        "13|AutoBangumi" "14|MoviePilot"
        "15|Foxel" "16|STB 图床"
        "17|OCI 抢机" "18|y探长"
        "19|Sub-store" "20|Poste.io 邮局"
        "21|WebSSH" "22|Openlist"
        "23|qBittorrent v4.6.3" "24|音乐服务"
        "25|兰空图床" "26|兰空图床 (无 MySQL)"
        "88|更新脚本" "99|卸载脚本"
    )

    # 左列最大宽度，根据最长文字调整
    left_width=32
    space_between=4

    for ((i=0; i<${#menu_items[@]}; i+=2)); do
        left="${menu_items[i]}"
        right="${menu_items[i+1]}"

        left_no=${left%%|*}
        left_name=${left#*|}
        right_no=${right%%|*}
        right_name=${right#*|}

        # 输出左列+固定空格+右列
        printf "${GREEN}%-3s %-*s%*s%-3s %s${RESET}\n" \
            "$left_no." "$left_width" "$left_name" "$space_between" "" "$right_no." "$right_name"
    done

    printf "${GREEN}0. 退出${RESET}\n\n"
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
             curl -fsSL -o "$0" https://raw.githubusercontent.com/iu683/app-store/main/vpsdocker.sh
             chmod +x "$0"
             echo -e "${GREEN}更新完成!${RESET}" ;;
        99) echo -e "${YELLOW}正在卸载脚本...${RESET}"
             rm -rf "$HOME/vps-manager"
             echo -e "${GREEN}卸载完成!${RESET}"; exit 0 ;;
        0) echo -e "${YELLOW}退出脚本...${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选择，请重新输入!${RESET}" ;;
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
