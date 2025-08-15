#!/bin/bash
# 功能：音乐服务管理脚本（Navidrome + Miniserve + MusicTagWeb）
# 第一次运行：bash manage_music.sh install
# 再次运行：bash manage_music.sh

PROJECT_DIR=~/music_server
MUSIC_DIR=/data/music
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

# ---------- 安装函数 ----------
install_services() {
    echo "========== 开始安装三合一音乐服务 =========="

    # 创建目录
    mkdir -p "$PROJECT_DIR/data"
    mkdir -p "$MUSIC_DIR"
    cd "$PROJECT_DIR" || exit

    # 交互输入 API Key 和账号密码
    read -p "请输入 LastFM API Key: " ND_LASTFM_APIKEY
    read -p "请输入 LastFM Secret: " ND_LASTFM_SECRET
    read -p "请输入 Spotify ID: " ND_SPOTIFY_ID
    read -p "请输入 Spotify Secret: " ND_SPOTIFY_SECRET
    read -p "设置 Miniserve 用户名: " MINSERVE_USER
    read -s -p "设置 Miniserve 密码: " MINSERVE_PASS
    echo

    # 生成 .env
    cat > .env <<EOF
ND_LASTFM_ENABLED=true
ND_LASTFM_APIKEY=$ND_LASTFM_APIKEY
ND_LASTFM_SECRET=$ND_LASTFM_SECRET
ND_SPOTIFY_ID=$ND_SPOTIFY_ID
ND_SPOTIFY_SECRET=$ND_SPOTIFY_SECRET

MINSERVE_USER=$MINSERVE_USER
MINSERVE_PASS=$MINSERVE_PASS
EOF

    # 生成 docker-compose.yml
    cat > docker-compose.yml <<EOF
version: "3.9"

networks:
  music_net:
    driver: bridge

services:
  navidrome:
    image: deluan/navidrome:latest
    container_name: navidrome
    networks:
      - music_net
    ports:
      - "127.0.0.1:4533:4533"
    environment:
      ND_SCANSCHEDULE: 1m
      ND_LASTFM_ENABLED: \${ND_LASTFM_ENABLED}
      ND_LASTFM_APIKEY: \${ND_LASTFM_APIKEY}
      ND_LASTFM_SECRET: \${ND_LASTFM_SECRET}
      ND_SPOTIFY_ID: \${ND_SPOTIFY_ID}
      ND_SPOTIFY_SECRET: \${ND_SPOTIFY_SECRET}
      ND_LASTFM_LANGUAGE: zh
      ND_LOGLEVEL: info
      ND_SESSIONTIMEOUT: 24h
      ND_BASEURL: ""
      ND_ENABLETRANSCODINGCONFIG: "true"
      ND_TRANSCODINGCACHESIZE: "4000M"
      ND_IMAGECACHESIZE: "1000M"
    volumes:
      - ./data/navidrome:/data
      - $MUSIC_DIR:/music:ro
    restart: unless-stopped

  miniserve:
    image: svenstaro/miniserve:latest
    container_name: miniserve
    networks:
      - music_net
    depends_on:
      - navidrome
    ports:
      - "4534:8080"
    volumes:
      - $MUSIC_DIR:/downloads
    command: "-r -z -u -q -p 8080 -a \${MINSERVE_USER}:\${MINSERVE_PASS} /downloads"
    restart: unless-stopped

  music_tag_web:
    image: xhongc/music_tag_web:latest
    container_name: music_tag_web
    networks:
      - music_net
    depends_on:
      - navidrome
    ports:
      - "127.0.0.1:8002:8002"
    volumes:
      - $MUSIC_DIR:/app/media
      - ./data/music_tag_web:/app/data
    restart: unless-stopped
EOF

    # 启动服务
    docker-compose up -d

    echo "✅ 安装完成！访问地址："
    echo "Navidrome    : http://127.0.0.1:4533"
    echo "Miniserve     : http://127.0.0.1:4534 (账号: $MINSERVE_USER  密码: $MINSERVE_PASS)"
    echo "MusicTagWeb   : http://127.0.0.1:8002"
    echo "========================================="
}

# ---------- 菜单函数 ----------
show_menu() {
    clear
    echo "==============================="
    echo "   音乐服务管理菜单"
    echo "==============================="
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

start_services() { docker-compose -f $COMPOSE_FILE up -d; echo "所有服务已启动"; read -p "按回车返回菜单..."; }
stop_services() { docker-compose -f $COMPOSE_FILE down; echo "所有服务已停止"; read -p "按回车返回菜单..."; }
restart_services() { docker-compose -f $COMPOSE_FILE restart; echo "所有服务已重启"; read -p "按回车返回菜单..."; }

view_logs() {
    case $1 in
        navidrome) docker-compose -f $COMPOSE_FILE logs -f navidrome ;;
        miniserve) docker-compose -f $COMPOSE_FILE logs -f miniserve ;;
        music_tag_web) docker-compose -f $COMPOSE_FILE logs -f music_tag_web ;;
    esac
    read -p "按回车返回菜单..."
}

view_status() { docker-compose -f $COMPOSE_FILE ps; read -p "按回车返回菜单..."; }

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
        docker-compose -f $COMPOSE_FILE down
        docker-compose -f $COMPOSE_FILE rm -f
        echo "操作完成，如需删除数据，请手动清理 ./data 文件夹"
    else
        echo "已取消卸载操作"
    fi
    read -p "按回车返回菜单..."
}

# ---------- 主程序 ----------
cd "$PROJECT_DIR" || exit

if [[ "$1" == "install" ]]; then
    install_services
fi

# 检查 docker-compose.yml 是否存在
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ docker-compose.yml 不存在，请先运行 bash manage_music.sh install"
    exit 1
fi

# 打开管理菜单
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
