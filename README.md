# VPS Docker 应用管理菜单

一个基于 Bash 的交互式脚本，用于管理 Docker 应用和 VPS 常用服务。

---

## 功能概览

- 安装/管理 Docker  
- MySQL 数据管理  
- 各类应用安装（Wallos、Kuma-Mieru、qBittorrent、音乐服务、图床等）  
- 脚本自更新与卸载  

---

## 安装

```bash
bash <(curl -sL https://raw.githubusercontent.com/iu683/app-store/main/vpsdocker.sh)
使用
运行脚本后，输入编号执行对应功能

输入 0 退出脚本

输入 88 更新脚本

输入 99 卸载脚本

注意事项
需要已安装 curl

网络需能访问 GitHub

卸载脚本会删除 vpsdocker.sh 文件
