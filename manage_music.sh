#!/bin/bash
# 功能: 一键部署三合一音乐服务（Navidrome + Miniserve + MusicTagWeb）并生成管理菜单

PROJECT_DIR=~/music_server
MUSIC_DIR=/data/music

echo "========== 三合一音乐服务 一键部署 =========="

# 1️⃣ 环境检测
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker！"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose！"
    exit 1
fi

PORTS=(4533 4534 8002)
for PORT in "${PORTS[@]}"; do
    if lsof -i:$PORT &> /dev/null; then
        echo "❌ 端口 $PORT 已被占用，请先释放该端口！"
        exit 1
    fi
done

echo "✅ 环境检查通过，Docker 和端口可用"

# 2️⃣ 创建目录
mkdir -p $PROJECT_DIR
mkdir -p $MUSIC_DIR
mkdir -p $PROJECT_DIR/data
cd $PROJECT_DIR || exit

# 3️⃣ 生成 .env
read -p "请输入 LastFM API Key: " ND_LASTFM_APIKEY
read -p "请输入 LastFM Secret: " ND_LASTFM_SECRET
read -p "请输入 Spotify ID: " ND_SPOTIFY_ID
read -p "请输入 Spotify Secret: " ND_SPOTIFY_SECRET
read -p "设置 Miniserve 用户名: " MINSERVE_USER
read -s -p "设置 Miniserve 密码: " MINSERVE_PASS
echo

cat > .env <<EOF
ND_LASTFM_ENABLED=true
ND_LASTFM_APIKEY=$ND_LASTFM_APIKEY
ND_LASTFM_SECRET=$ND_LASTFM_SECRET
ND_SPOTIFY_ID=$ND_SPOTIFY_ID
ND_SPOTIFY_SECRET=$ND_SPOTIFY_SECRET

MINSERVE_USER=$MINSERVE_USER
MINSERVE_PASS=$MINSERVE_PASS
EOF

# 4️⃣ 生成 docker-compose.yml
cat > docker-compose.yml <<'EOF'
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
      ND_LASTFM_ENABLED: ${ND_LASTFM_ENABLED}
      ND_LASTFM_APIKEY: ${ND_LASTFM_APIKEY}
      ND_LASTFM_SECRET: ${ND_LASTFM_SECRET}
      ND_SPOTIFY_ID: ${ND_SPOTIFY_ID}
      ND_SPOTIFY_SECRET: ${ND_SPOTIFY_SECRET}
      ND_LASTFM_LANGUAGE: zh
      ND_LOGLEVEL: info
      ND_SESSIONTIMEOUT: 24h
      ND_BASEURL: ""
      ND_ENABLETRANSCODINGCONFIG: "true"
      ND_TRANSCODINGCACHESIZE: "4000M"
      ND_IMAGECACHESIZE: "1000M"
    volumes:
      - ./data/navidrome:/data
      - /data/music:/music:ro
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
      - /data/music:/downloads
    command: "-r -z -u -q -p 8080 -a ${MINSERVE_USER}:${MINSERVE_PASS} /downloads"
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
      - /data/music:/app/media
      - ./data/music_tag_web:/app/data
    restart: unless-stopped
EOF

# 5️⃣ 生成管理脚本
cat > manage_music.sh <<'EOF'
#!/bin/bash

COMPOSE_FILE="docker-compose.yml"

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
EOF

chmod +x manage_music.sh

# 6️⃣ 启动服务
docker-compose up -d

# 7️⃣ 输出访问地址
echo "==============================="
echo "🎵 三合一音乐服务已启动完成 🎵"
echo "访问地址："
echo "Navidrome        : http://127.0.0.1:4533"
echo "Miniserve         : http://127.0.0.1:4534 （账号: $MINSERVE_USER  密码: $MINSERVE_PASS）"
echo "MusicTagWeb       : http://127.0.0.1:8002"
echo "==============================="
echo "管理菜单将自动启动..."
sleep 2

# 8️⃣ 启动管理菜单
./manage_music.sh
