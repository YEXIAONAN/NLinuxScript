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
欢迎使用 yexiaonan 一键优化系统。
本脚本仅适用于 CentOS 7.0 及以上版本。

脚本已在GitHub开源,链接 https://github.com/YEXIAONAN/NLinuxScript
----------------------------------------------------------------
EOF

sleep 2

cat <<EOF
脚本功能：

系统更新与基础工具安装

SSH安全强化（端口修改、禁用root登录）

防火墙配置优化

内核网络参数调优

文件描述符限制调整

日志管理优化

禁用非必要系统服务

时间同步配置

DNS优化

自动清理任务配置

注意事项：

执行前请确认已保存好当前SSH连接方式

修改SSH端口后需确保防火墙放行

部分优化需要重启才能完全生效

DNS设置可能被网络管理工具覆盖

生产环境建议逐步验证每个优化项

恢复方法：
所有修改过的配置文件都备份在/tmp/centos_optimize_backup_YYYYMMDD目录，可以手动恢复。
EOF

# 检查root权限
if [[ $EUID -ne 0 ]]; then
    echo -e "\033[31m错误：此脚本需要以root权限运行\033[0m"
    exit 1
fi

# 定义颜色变量
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# 创建备份目录
backup_dir="/tmp/centos_optimize_backup_$(date +%Y%m%d)"
mkdir -p ${backup_dir}

# 函数：带确认提示的命令执行
function confirm_cmd() {
    local prompt=$1
    local cmd=$2
    read -p "${prompt} [y/N] " answer
    if [[ $answer =~ ^[Yy]$ ]]; then
        eval $cmd
    else
        echo -e "${YELLOW}已跳过该操作${RESET}"
    fi
}

echo -e "${BLUE}[1/10] 系统更新与基础工具安装${RESET}"
yum makecache fast
yum update -y
yum install -y epel-release
yum install -y curl wget htop iftop iotop net-tools telnet tree vim jq

echo -e "${BLUE}[2/10] SSH安全优化${RESET}"
cp /etc/ssh/sshd_config ${backup_dir}/sshd_config.bak
read -p "请输入新的SSH端口（建议1024-65535）：" ssh_port
sed -i "s/#Port 22/Port ${ssh_port}/g" /etc/ssh/sshd_config
sed -i 's/#LoginGraceTime 2m/LoginGraceTime 1m/g' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd

echo -e "${GREEN}SSH配置已更新，新端口：${ssh_port}${RESET}"

echo -e "${BLUE}[3/10] 防火墙配置${RESET}"
systemctl start firewalld
firewall-cmd --permanent --add-port=${ssh_port}/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

echo -e "${BLUE}[4/10] 内核参数优化${RESET}"
cp /etc/sysctl.conf ${backup_dir}/sysctl.conf.bak
cat >> /etc/sysctl.conf << EOF
# 优化内核参数
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 2097152
EOF
sysctl -p

echo -e "${BLUE}[5/10] 文件描述符限制调整${RESET}"
cp /etc/security/limits.conf ${backup_dir}/limits.conf.bak
echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf

echo -e "${BLUE}[6/10] 日志管理优化${RESET}"
# 日志文件限制
cp /etc/logrotate.conf ${backup_dir}/logrotate.conf.bak
sed -i 's/^#compress/compress/g' /etc/logrotate.conf
sed -i 's/rotate 4/rotate 12/g' /etc/logrotate.conf

echo -e "${BLUE}[7/10] 无用服务禁用${RESET}"
services_disable=("postfix" "avahi-daemon" "dhcpd")
for service in "${services_disable[@]}"; do
    systemctl stop ${service}
    systemctl disable ${service}
done

echo -e "${BLUE}[8/10] 时间同步配置${RESET}"
yum install -y chrony
systemctl enable chronyd
systemctl start chronyd
chronyc sources

echo -e "${BLUE}[9/10] DNS优化${RESET}"
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

echo -e "${BLUE}[10/10] 自动清理配置${RESET}"
echo "0 3 * * * /usr/bin/yum clean all" >> /var/spool/cron/root
echo "0 4 * * 0 /usr/sbin/tmpwatch 168 /tmp" >> /var/spool/cron/root

echo -e "${GREEN}
===============================================
优化完成！请执行以下操作：
1. 检查SSH连接：当前连接仍有效，但新连接需要使用端口 ${ssh_port}
2. 建议重启系统使部分配置生效
3. 备份文件保存在：${backup_dir}
===============================================${RESET}"