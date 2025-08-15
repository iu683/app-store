#!/bin/bash

WORK_DIR="/var/dnsmgr"
LOG_FILE="${WORK_DIR}/dnsmgr_deploy.log"
CONTAINER_NAME="dnsmgr"
IMAGE_NAME="netcccyun/dnsmgr"
HOST_PORT="8081"
CONTAINER_PORT="80"

# 颜色
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 创建日志目录
mkdir -p "$WORK_DIR"
touch "$LOG_FILE"

# 日志函数
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# 自动检测端口
check_port() {
    local port=$1
    while lsof -i:$port &>/dev/null; do
        log "[✘] 端口 $port 已被占用"
        echo -e "${YELLOW}请输入新的端口号: ${RESET}"
        read -r port
        HOST_PORT=$port
    done
    log "[✔] 使用端口: $HOST_PORT"
}

# 部署容器
deploy_dnsmgr() {
    check_port $HOST_PORT

    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log "[!] 容器 ${CONTAINER_NAME} 已存在，正在启动..."
        docker start ${CONTAINER_NAME}
    else
        log "[...] 正在创建并启动 ${CONTAINER_NAME} 容器"
        docker run --name ${CONTAINER_NAME} -dit -p ${HOST_PORT}:${CONTAINER_PORT} -v ${WORK_DIR}:/app/www ${IMAGE_NAME}
    fi
    IP_ADDR=$(hostname -I | awk '{print $1}')
    log "[✔] 彩虹聚合 DNS 已部署！访问：http://${IP_ADDR}:${HOST_PORT}"
}

# 更新容器
update_dnsmgr() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker pull ${IMAGE_NAME}
        docker stop ${CONTAINER_NAME}
        docker rm ${CONTAINER_NAME}
        docker run --name ${CONTAINER_NAME} -dit -p ${HOST_PORT}:${CONTAINER_PORT} -v ${WORK_DIR}:/app/www ${IMAGE_NAME}
        log "[✔] 彩虹聚合 DNS 已更新"
    else
        log "[✘] 容器 ${CONTAINER_NAME} 不存在，无法更新"
    fi
}

# 卸载容器
uninstall_dnsmgr() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker stop ${CONTAINER_NAME}
        docker rm ${CONTAINER_NAME}
        log "[✔] 彩虹聚合 DNS 已卸载"
    else
        log "[!] 容器 ${CONTAINER_NAME} 不存在"
    fi
    echo -e "${YELLOW}是否删除数据目录 ${WORK_DIR}？[y/N]${RESET}"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf ${WORK_DIR}
        log "[✔] 数据目录已删除"
    fi
}

# 查看日志
view_log() {
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${YELLOW}====== 彩虹聚合 DNS 部署日志 ======${RESET}"
        cat "$LOG_FILE"
    else
        echo -e "${RED}日志文件不存在${RESET}"
    fi
}

# 显示访问地址
show_config() {
    echo -e "${YELLOW}====== 彩虹聚合 DNS 访问地址 ======${RESET}"
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo "访问地址: http://${IP_ADDR}:${HOST_PORT}"
}

# 菜单
while true; do
    echo -e "${GREEN}====== 彩虹聚合 DNS 管理菜单 ======${RESET}"
    echo "1. 部署"
    echo "2. 更新"
    echo "3. 卸载"
    echo "4. 查看日志"
    echo "5. 显示访问地址"
    echo "0. 退出"
    read -p "请输入选项: " choice
    case $choice in
        1) deploy_dnsmgr ;;
        2) update_dnsmgr ;;
        3) uninstall_dnsmgr ;;
        4) view_log ;;
        5) show_config ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
done
