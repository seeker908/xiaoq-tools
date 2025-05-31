#!/bin/bash
# 配置参数
PACKAGE="xiaoq-tools"
GITEE_REPO="https://gitee.com/seeker_ok/$PACKAGE"
PACKAGE_NAME="$PACKAGE"
TMP_DIR="/tmp/$PACKAGE-check"

# 创建临时目录
TMP_DIR=$(mktemp -d)
cd $TMP_DIR || exit 1

# 克隆仓库或拉取更新
REPO_DIR="$TMP_DIR/repo"
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git pull origin master >/dev/null 2>&1
else
    git clone "$GITEE_REPO" "$REPO_DIR" --depth 1 >/dev/null 2>&1
    cd "$REPO_DIR" || exit 1
fi

# 查找最新的 deb 文件
DEB_FILE=$(ls *.deb | sort -V | tail -n 1)
if [ -z "$DEB_FILE" ]; then
    echo "错误：仓库中未找到任何 deb 文件"
    exit 1
fi

# 验证Deb文件存在
if [ ! -f "$DEB_FILE" ]; then
    echo "错误：未找到Deb文件 $DEB_FILE"
    exit 1
fi

# 获取仓库 deb 版本
REPO_VER=$(dpkg-deb -f "$DEB_FILE" Version 2>/dev/null)
if [ -z "$REPO_VER" ]; then
    echo "错误：无法从 deb 文件中获取版本信息"
    exit 1
fi

# 获取本地已安装版本
LOCAL_VER=$(dpkg-query -W --showformat='${Version}' "$PACKAGE_NAME" 2>/dev/null | head -n 1)

# 版本比对
if [ "$REPO_VER" != "$LOCAL_VER" ] || [ -z "$LOCAL_VER" ]; then
    echo "发现新版本: $REPO_VER (当前: ${LOCAL_VER:-未安装})"
    read -p $'\e[34m 是否更新? [Yy/N] \033[0m' -n 1 -r    
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 停止服务（如果需要）
        # systemctl stop "$PACKAGE_NAME"

        # 备份旧版本（如果需要）
        # cp /path/to/old/executable /path/to/backup/

        # 安装新版本
        sudo -S  echo ""
        echo -e "\e[31m 正在安装中，请稍等。。。\e[0m"
        sudo dpkg -i "$DEB_FILE"
        # 重启服务（如果需要）
        # systemctl restart "$PACKAGE_NAME"

        echo "$DEB_FILE 已安装，版本为 $REPO_VER"
    fi
else
    echo "$PACKAGE_NAME 已是最新版本 ($LOCAL_VER)"
fi

# 清理临时目录
rm -rf  "$TMP_DIR"

#  确保桌面文件存在
LOGUSER=$(who | awk 'NR==1{print $1}')
[ -z "$LOGUSER" ] && LOGUSER="$SUDO_USER"
HOME="/home/$LOGUSER"

# 定义可能的桌面路径
DESKTOP_DIR1="$HOME/Desktop"
DESKTOP_DIR2="$HOME/桌面"

# 检查哪个桌面目录存在
if [ -d "$DESKTOP_DIR1" ]; then
    TARGET_DIR="$DESKTOP_DIR1"
elif [ -d "$DESKTOP_DIR2" ]; then
    TARGET_DIR="$DESKTOP_DIR2"
else
    # 如果都不存在，尝试创建默认的Desktop目录
    echo "Desktop目录不存在"
fi

rm -rf  "$TARGET_DIR/update.sh"
# 清理临时目录
rm -rf $TMP_DIR

exit 0
