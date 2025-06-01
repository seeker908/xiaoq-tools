#!/bin/bash
# 配置参数
PACKAGE="xiaoq-tools"
GITEE_REPO="https://gitee.com/seeker_ok/$PACKAGE"
PACKAGE_NAME="$PACKAGE"
TMP_DIR="/tmp/$PACKAGE-check"

# 创建临时目录
TMP_DIR=$(mktemp -d)
cd $TMP_DIR || exit 0  # 改为exit 0，使错误不终止脚本

# 克隆仓库或拉取更新
REPO_DIR="$TMP_DIR/repo"
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"
    git pull origin master >/dev/null 2>&1 || true
else
    git clone "$GITEE_REPO" "$REPO_DIR" --depth 1 >/dev/null 2>&1 || {
        echo -e "\033[33m提示：无法访问更新仓库，将使用当前版本\033[0m" >&2
        exit 0
    }
    cd "$REPO_DIR" || exit 0
fi

# 查找最新的 deb 文件
REPO_VER=$(ls *.deb 2>/dev/null | sort -V | tail -n 1)
if [ -z "$REPO_VER" ]; then
    echo -e "\033[33m提示：仓库中未找到任何 deb 文件，将使用当前版本\033[0m" >&2
    exit 0
fi

# 验证Deb文件存在
if [ ! -f "$REPO_VER" ]; then
    echo -e "\033[33m提示：无法访问找到的Deb文件，将使用当前版本\033[0m" >&2
    exit 0
fi

# 获取本地已安装版本
LOCAL_VER=$(dpkg-query -W --showformat='${Version}' "$PACKAGE_NAME" 2>/dev/null | head -n 1)
# 版本比对
if [ "$REPO_VER" != "$LOCAL_VER" ] || [ -z "$LOCAL_VER" ]; then
    # 使用参数扩展来提取版本号
    REPO_VERSION_ONLY=${REPO_VER#*_}  # 去除文件名中最后一个下划线之后的部分，包含版本号和后缀
    REPO_VERSION_ONLY=${REPO_VERSION_ONLY%_all.deb}  # 去除版本号中的后缀部分（.deb），只保留版本号
    echo  -e "\e[31m 发现新版本: $REPO_VERSION_ONLY (当前: ${LOCAL_VER:-未安装}) \e[0m"    
    read -p $'\e[34m 是否更新? [Yy/N] \033[0m' -n 1 -r    
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 停止服务（如果需要）
        # systemctl stop "$PACKAGE_NAME"

        # 安装新版本
        sudo -S  echo ""
        echo -e "\e[31m 正在安装中，请稍等。。。\e[0m"
        sudo dpkg -i "$REPO_VER"
        # 重启服务（如果需要）
        # systemctl restart "$PACKAGE_NAME"
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
        echo  -e "\e[31m $PACKAGE_NAME 已是最新版本 ($REPO_VERSION_ONLY),正在删除升级文件\e[0m"
        rm -rf  "$TARGET_DIR/update.sh"
        echo  -e "\e[31m 删除升级文件完成\e[0m"
        # 清理临时目录
        rm -rf $TMP_DIR
        echo  -e "\e[31m 清理安装文件临时目录完成\e[0m"
        echo  -e "\e[31m $PACKAGE_NAME 已安装，版本为 $REPO_VERSION_ONLY\e[0m"
    fi
else
    echo "$PACKAGE_NAME 已是最新版本 ($LOCAL_VER)"
fi


exit 0
