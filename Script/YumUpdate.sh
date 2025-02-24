#!/bin/bash

clear

sleep 3

echo "----------------------------------------------------------------"

cat <<EOF
__   __  __  ___             _   _             
\ \ / /__\ \/ (_) __ _  ___ | \ | | __ _ _ __  
 \ V / _ \\  /| |/ _` |/ _ \|  \| |/ _` | '_ \ 
  | |  __//  \| | (_| | (_) | |\  | (_| | | | |
  |_|\___/_/\_\_|\__,_|\___/|_| \_|\__,_|_| |_|
                                               
                                                               
----------------------------------------------------------------
欢迎使用 yexiaonan 一键部署环境。
本脚本仅适用于 CentOS 7.0 及以上版本。

脚本已在GitHub开源,链接 https://github.com/YEXIAONAN/NLinuxScript
----------------------------------------------------------------
EOF

sleep 2

cat <<EOF
本脚本将会自动安装以下环境：

1.将会替换 Yum 源为阿里云源。
2.将会安装 Vim 编辑器。
3.将会安装 Bash 补全。
4.将会安装 Curl 工具。
5.将会安装 Wget 工具。

EOF

echo "----------------------------------------------------------------"


echo "NLinuxScript |  Chage Yum Source"

# 替换 Yum 源为阿里云源

mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup

# 注释掉 /etc/yum.repos.d 目录下所有以 CentOS- 开头的文件中的 mirrorlist 配置
# 因为使用阿里云源时，通常不需要原有的 mirrorlist 配置
sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*

# 将 /etc/yum.repos.d 目录下所有以 CentOS- 开头的文件中以 #baseurl=http://mirror.centos.org 开头的行
# 替换为 baseurl=http://mirrors.aliyun.com，从而将 Yum 源替换为阿里云源
sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://mirrors.aliyun.com|g' /etc/yum.repos.d/CentOS-*

# 使用 curl 命令从阿里云镜像源下载 Centos-7 的仓库配置文件
# -O 选项表示将下载的文件保存到指定的路径，这里指定保存为 /etc/yum.repos.d/epel.repo
# 注意：原命令中保存路径可能有误，这里将从 http://mirrors.aliyun.com/repo/Centos-7.repo 下载的文件保存到 epel.repo
# 实际使用时请根据需求调整保存的文件名
curl -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/Centos-7.repo

# 提示用户 Yum 源替换和仓库文件下载完成
echo "NLinuxScript | Yum source has been changed to Alibaba Cloud source and Centos-7 repo file has been downloaded."

# 安装 Vim 编辑器

yum install -y vim

clear

sleep 3

echo "NLinuxScript | Vim has been installed."

# 安装 Bash 补全

yum install -y bash-completion

clear

sleep 3

echo "NLinuxScript | Bash completion has been installed."
# 安装 Curl 工具

yum install -y curl

clear

sleep 3

echo "NLinuxScript | Curl has been installed."
# 安装 Wget 工具

yum install -y wget

clear

sleep 3

echo "NLinuxScript | Wget has been installed."


echo "----------------------------------------------------------------"

echo "所有软件包已经安装完毕。"
echo "NLinuxScript |  All done."
echo "NLinuxScript |  By Yexiaonan."

echo "----------------------------------------------------------------




