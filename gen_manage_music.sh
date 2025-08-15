#!/bin/bash
# 自动检测并运行 manage_music.sh
PROJECT_DIR=~/music_server
MANAGE_SCRIPT="$PROJECT_DIR/manage_music.sh"

# 检查 Docker 和 Docker Compose
for cmd in docker docker-compose; do
    if ! command -v $cmd &>/dev/null; then
        echo "❌ $cmd 未安装，请先安装 $cmd！"
        exit 1
    fi
done

# 创建项目目录
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit

# 下载 manage_music.sh（如果不存在）
if [ ! -f "$MANAGE_SCRIPT" ]; then
    echo "📥 下载 manage_music.sh..."
    curl -sL https://raw.githubusercontent.com/iu683/app-store/main/manage_music.sh -o manage_music.sh
    chmod +x manage_music.sh
fi

# 如果 docker-compose.yml 不存在 → 自动安装
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo "⚠️ 未检测到服务，开始自动安装..."
    bash manage_music.sh
else
    echo "✅ 服务已安装，直接打开管理菜单..."
    bash manage_music.sh
fi
