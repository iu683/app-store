#!/bin/bash

COMPOSE_FILE="docker-compose.yml"

show_menu() {
    clear
    echo "==============================="
    echo "   音乐服务管理菜单"
    echo "==============================="
    # 显示容器状态
    echo "容器状态:"
    docker-compose -f $COMPOSE_FILE ps --services --filter "status=running" | awk '{print "  " $1 " : 运行中"}'
    docker-compose -f $COMPOSE_FILE ps --services --filter "status=exited" | awk '{print "  " $1 " : 停止"}'
    echo "-------------------------------"
    echo "1) 启动所有服务"
    echo "2) 停止所有服务"
    echo "3) 重启所有服务"
    echo "4) 查看 Navidrome 日志"
    echo "5) 查看 Miniserve 日志"
    echo "6) 查看 MusicTagWeb 日志"
    echo "7) 查看所有容器状态"
    echo "8) 更新所有服务镜像"
    echo "9) 卸载所有服务及容器"
    echo "0) 退出"
    echo "==============================="
    echo -n "请输入选项: "
}

start_services() {
    docker-compose -f $COMPOSE_FILE up -d
    echo "所有服务已启动"
    read -p "按回车返回菜单..."
}

stop_services() {
    docker-compose -f $COMPOSE_FILE down
    echo "所有服务已停止"
    read -p "按回车返回菜单..."
}

restart_services() {
    docker-compose -f $COMPOSE_FILE restart
    echo "所有服务已重启"
    read -p "按回车返回菜单..."
}

view_logs() {
    case $1 in
        navidrome)
            docker-compose -f $COMPOSE_FILE logs -f navidrome
            ;;
        miniserve)
            docker-compose -f $COMPOSE_FILE logs -f miniserve
            ;;
        music_tag_web)
            docker-compose -f $COMPOSE_FILE logs -f music_tag_web
            ;;
    esac
}

view_status() {
    docker-compose -f $COMPOSE_FILE ps
    read -p "按回车返回菜单..."
}

update_services() {
    echo "拉取最新镜像..."
    docker-compose -f $COMPOSE_FILE pull
    echo "重新启动服务..."
    docker-compose -f $COMPOSE_FILE up -d
    echo "更新完成"
    read -p "按回车返回菜单..."
}

uninstall_services() {
    echo "⚠️  警告：此操作将停止并删除所有容器及镜像！"
    read -p "你确定要继续吗？(y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "停止并删除所有容器..."
        docker-compose -f $COMPOSE_FILE down
        echo "删除所有镜像..."
        docker-compose -f $COMPOSE_FILE rm -f
        echo "操作完成，如需删除数据，请手动清理 ./data 文件夹"
    else
        echo "已取消卸载操作"
    fi
    read -p "按回车返回菜单..."
}

while true; do
    show_menu
    read choice
    case $choice in
        1) start_services ;;
        2) stop_services ;;
        3) restart_services ;;
        4) view_logs navidrome ;;
        5) view_logs miniserve ;;
        6) view_logs music_tag_web ;;
        7) view_status ;;
        8) update_services ;;
        9) uninstall_services ;;
        0) echo "退出"; exit 0 ;;
        *) echo "无效选项"; sleep 1 ;;
    esac
done
