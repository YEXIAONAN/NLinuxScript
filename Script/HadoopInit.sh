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
欢迎使用 yexiaonan 快速搭建集群脚本，该脚本尽在你对搭建很熟练才需
使用，如不熟悉搭建，请勿使用！

脚本已在GitHub开源,链接 https://github.com/YEXIAONAN/NLinuxScript
----------------------------------------------------------------
EOF

sleep 2

cat <<EOF
即将开始安装集群；
- 安装 JDK 环境
- 安装 Hadoop 环境
（集群组件安装位置 “/opt/module” 下）

EOF

# 添加延迟，暂停 3 秒
sleep 2

echo "正在检查防火墙状态..."
firewall_status=$(systemctl is-active firewalld)

if [ "$firewall_status" == "active" ]; then
    echo "防火墙当前已启用，正在尝试关闭..."
    systemctl stop firewalld
    systemctl disable firewalld
    echo "防火墙已关闭并禁用。"
else
    echo "防火墙当前未启用，无需操作。"
fi

# 提示用户操作结束
echo "防火墙配置检查完成。"
echo "------------------------------"
echo " "





# 函数：配置 /etc/hosts
configure_hosts() {
    echo "开始配置 /etc/hosts 文件，为免密登录做好准备。"

    # 提示用户输入 IP 地址和主机名
    read -p "请输入当前 Master 主机的 IP 地址： " master_ip
    read -p "请输入当前 Slave1 主机的 IP 地址： " slave1_ip
    read -p "请输入当前 Slave2 主机的 IP 地址： " slave2_ip

    # 定义主机名
    master_host="master"
    slave1_host="slave1"
    slave2_host="slave2"

    # 待写入内容
    hosts_entries="
$master_ip    $master_host
$slave1_ip    $slave1_host
$slave2_ip    $slave2_host
"

    # 检查重复条目
    echo "即将写入以下内容到 /etc/hosts 文件："
    echo "$hosts_entries"
    read -p "确认写入吗？(y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "操作已取消。"
        exit 1
    fi

    # 写入 /etc/hosts 文件
    for entry in "$master_ip" "$slave1_ip" "$slave2_ip"; do
        if grep -q "$entry" /etc/hosts; then
            echo "警告：检测到 $entry 已存在于 /etc/hosts，跳过写入。"
        else
            echo "$hosts_entries" >> /etc/hosts
            echo "$entry 已成功写入 /etc/hosts 文件。"
            break
        fi
    done

    echo "以下是 /etc/hosts 文件的最新内容："
    cat /etc/hosts
    echo "配置完成，进行下一步操作。"
    echo "------------------------------"
}

# 函数：配置免密登录
configure_ssh_keys() {
    echo "开始配置免密登录..."

    # 检查 SSH 密钥是否已存在
    SSH_KEY="$HOME/.ssh/id_rsa"
    if [ -f "$SSH_KEY" ]; then
        echo "SSH 密钥已存在：$SSH_KEY"
    else
        echo "未检测到 SSH 密钥，正在生成..."
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -q
        if [ $? -eq 0 ]; then
            echo "SSH 密钥生成成功：$SSH_KEY"
        else
            echo "SSH 密钥生成失败，请检查环境后重试。"
            exit 1
        fi
    fi

    # 定义主机列表
    declare -A hosts
    hosts=( 
        ["master"]=$master_ip
        ["slave1"]=$slave1_ip
        ["slave2"]=$slave2_ip
    )

    # 遍历主机列表，执行 ssh-copy-id
    for hostname in "${!hosts[@]}"; do
        ip="${hosts[$hostname]}"
        echo "正在配置 $hostname ($ip) 的免密登录..."
        ssh-copy-id -i "$SSH_KEY.pub" "root@$ip"
        if [ $? -eq 0 ]; then
            echo "$hostname ($ip) 配置成功！"
        else
            echo "$hostname ($ip) 配置失败，请检查主机名、IP 地址或密码是否正确。"
        fi
    done

    echo "所有主机免密配置完成！可以通过 ssh root@主机IP 或 ssh 主机名 直接登录。"
}

# 函数：将 /etc/hosts 文件传送到 slave1 和 slave2
transfer_hosts_file() {
    # 定义主机列表
    hosts=( "$slave1_ip" "$slave2_ip" )

    # 使用 scp 传送 /etc/hosts 文件
    for host_ip in "${hosts[@]}"; do
        echo "正在将 /etc/hosts 文件传送到 $host_ip ..."
        scp /etc/hosts root@$host_ip:/etc/hosts
        if [ $? -eq 0 ]; then
            echo "/etc/hosts 文件已成功传送到 $host_ip"
        else
            echo "/etc/hosts 文件传送到 $host_ip 失败，请检查连接。"
        fi
    done
    echo "文件传送完成！"
}

# 主程序
configure_hosts
transfer_hosts_file
configure_ssh_keys

echo ""
echo ""

clear

sleep 2




# 修改后的脚本段

# 提示用户输入 JDK 和 Hadoop 软件包的路径
echo "请输入 JDK 软件包的完整路径 (例如：/path/to/jdk-8u212-linux-x64.tar.gz)："
read -p "JDK 路径：" JDK_PATH
echo "请输入 Hadoop 软件包的完整路径 (例如：/path/to/hadoop-3.1.3.tar.gz)："
read -p "Hadoop 路径：" HADOOP_PATH

# 检查路径是否存在
if [ ! -f "$JDK_PATH" ]; then
    echo "错误: JDK 软件包路径不存在，请检查路径。"
    exit 1
fi

if [ ! -f "$HADOOP_PATH" ]; then
    echo "错误: Hadoop 软件包路径不存在，请检查路径。"
    exit 1
fi

echo "已确认 JDK 和 Hadoop 软件包路径。开始解压..."

# 定义目标路径
TARGET_DIR="/opt/module"

# 创建目标目录
mkdir -p "$TARGET_DIR"

# 解压并重命名的函数
extract_and_rename() {
    local package_path=$1
    local target_dir=$2
    local new_name=$3

    # 获取解压后的目录名称
    extracted_dir=$(tar -tf "$package_path" | head -n 1 | cut -d'/' -f1)

    echo "正在解压 $package_path 到 $target_dir..."
    tar -zxvf "$package_path" -C "$target_dir" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "解压失败，请检查软件包 $package_path 是否有效。"
        return 1
    fi

    if [ -d "$target_dir/$extracted_dir" ]; then
        mv "$target_dir/$extracted_dir" "$target_dir/$new_name"
        echo "软件包解压完毕，并已重命名为 $new_name"
    else
        echo "未找到解压后的目录，请检查解压是否成功。"
        return 1
    fi

    echo "------------------------------"
    return 0
}

# 解压 JDK 和 Hadoop
extract_and_rename "$JDK_PATH" "$TARGET_DIR" "jdk"
extract_and_rename "$HADOOP_PATH" "$TARGET_DIR" "hadoop"

echo "所有软件包已成功处理完毕。"







echo ""
echo ""
sleep 3
# 添加环境变量到 /etc/profile


# 配置环境变量
echo "export JAVA_HOME=/opt/module/jdk" >> /etc/profile
echo "export HADOOP_HOME=/opt/module/hadoop" >> /etc/profile
echo "export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> /etc/profile
source /etc/profile
echo "环境变量配置完成"
sleep 1  # 等待环境变量更新


clear

echo ""
echo ""

sleep 2
# 更新 Hadoop 的 workers 文件
update_hadoop_workers() {
    local hadoop_conf_dir="/opt/module/hadoop/etc/hadoop"
    local workers_file="${hadoop_conf_dir}/workers"

    echo "正在修改 Hadoop 的 workers 文件..."

    # 写入节点名称
    cat <<EOF > "$workers_file"
master
slave1
slave2
EOF

    echo "workers 文件已更新"
    echo "------------------------------"
    echo ""
}

# 调用函数进行更新
update_hadoop_workers
echo ""
echo ""

sleep 2

# 更新 hadoop-env.sh 配置
update_hadoop_env() {
    local hadoop_env_file="/opt/module/hadoop/etc/hadoop/hadoop-env.sh"
    local java_home="/opt/module/jdk"  # 修改为实际的 JDK 安装路径

    echo "正在修改 Hadoop 的  ${hadoop_env_file} 文件..."

    # 备份 hadoop-env.sh 文件
    cp "$hadoop_env_file" "${hadoop_env_file}.bak"

    # 写入配置到 hadoop-env.sh 文件
    cat <<EOF > "$hadoop_env_file"
# Hadoop environment configuration

# Java installation path
export JAVA_HOME=$java_home

# Hadoop user configurations
export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root
export YARN_RESOURCEMANAGER_USER=root
export YARN_NODEMANAGER_USER=root
EOF

    echo "hadoop-env.sh 配置更新完成"
    echo "------------------------------"
    echo ""
}


# 调用函数
update_hadoop_env

echo ""
echo ""
sleep 1
# 更新 core-site.xml 配置
update_core_site() {
    local core_site_file="/opt/module/hadoop/etc/hadoop/core-site.xml"
    local hadoop_tmp_dir="/root/hadoopdir/tmp"
    local fs_default_name="hdfs://master:9000"

    echo "正在修改 Hadoop 的 ${core_site_file} 文件..."

    # 备份 core-site.xml 文件
    cp "$core_site_file" "${core_site_file}.bak"

    # 写入配置到 core-site.xml 文件
    cat <<EOF > "$core_site_file"
<configuration>
    <!-- HDFS 的地址名称 -->
    <property>
        <name>fs.defaultFS</name>
        <value>${fs_default_name}</value>
    </property>

    <!-- HDFS 的基础路径，被其他属性所依赖的一个基础路径 -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>${hadoop_tmp_dir}</value>
    </property>
</configuration>
EOF

    echo "core-site.xml 配置更新完成"
    echo "------------------------------"
    echo ""
}

# 调用函数
update_core_site

echo ""
echo ""

sleep 2
# 更新 hdfs-site.xml 配置
update_hdfs_site() {
    local hdfs_site_file="/opt/module/hadoop/etc/hadoop/hdfs-site.xml"
    local namenode_dir="/root/hadoopdir/dfs/name"
    local datanode_dir="/root/hadoopdir/dfs/data"
    local replication_factor=3
    local block_size=134217728
    local secondary_http_address="master:9868"
    local namenode_http_address="master:9870"

    echo "正在修改 Hadoop 的 ${hdfs_site_file} 文件..."

    # 备份 hdfs-site.xml 文件
    cp "$hdfs_site_file" "${hdfs_site_file}.bak"

    # 写入配置到 hdfs-site.xml 文件
    cat <<EOF > "$hdfs_site_file"
<configuration>
    <!-- namenode守护进程管理的元数据文件fsimage存储的位置 -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>${namenode_dir}</value>
    </property>

    <!-- 确定DFS数据节点应该将其块存储在本地文件系统的何处 -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>${datanode_dir}</value>
    </property>

    <!-- 块的副本数 -->
    <property>
        <name>dfs.replication</name>
        <value>${replication_factor}</value>
    </property>

    <!-- 块的大小 (128M), 单位是字节 -->
    <property>
        <name>dfs.blocksize</name>
        <value>${block_size}</value>
    </property>

    <!-- secondarynamenode守护进程的http地址 -->
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>${secondary_http_address}</value>
    </property>

    <!-- namenode守护进程的http地址 -->
    <property>
        <name>dfs.namenode.http-address</name>
        <value>${namenode_http_address}</value>
    </property>

    <!-- 是否开通HDFS的Web接口，3.0版本后默认端口是9870 -->
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
</configuration>
EOF

    echo "hdfs-site.xml 配置更新完成"
    echo "------------------------------"
    echo ""
}

# 调用函数
update_hdfs_site

echo ""
echo ""

sleep 1
# 更新 mapred-site.xml 配置
update_mapred_site() {
    local mapred_site_file="/opt/module/hadoop/etc/hadoop/mapred-site.xml"

    echo "正在修改 Hadoop 的 ${mapred_site_file} 文件..."

    # 备份 mapred-site.xml 文件
    cp "$mapred_site_file" "${mapred_site_file}.bak"

    # 写入配置到 mapred-site.xml 文件
    cat <<EOF > "$mapred_site_file"
<configuration>
    <!-- 指定mapreduce使用yarn资源管理器 -->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>

    <!-- 配置作业历史服务器的地址 -->
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>master:10020</value>
    </property>

    <!-- 配置作业历史服务器的http地址 -->
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>master:19888</value>
    </property>
</configuration>
EOF

    echo "mapred-site.xml 配置更新完成"
    echo "------------------------------"
    echo ""
}

# 调用函数
update_mapred_site

echo ""
echo ""

sleep 1
# 更新 yarn-site.xml 配置
update_yarn_site() {
    local yarn_site_file="/opt/module/hadoop/etc/hadoop/yarn-site.xml"

    echo "正在修改 Hadoop 的 ${yarn_site_file} 文件..."

    # 备份 yarn-site.xml 文件
    cp "$yarn_site_file" "${yarn_site_file}.bak"

    # 写入配置到 yarn-site.xml 文件
    cat <<EOF > "$yarn_site_file"
<configuration>
    <!-- NodeManager获取数据的方式shuffle -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>

    <!-- 指定YARN的ResourceManager的地址 -->
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master</value>
    </property>

    <!-- yarn的web访问地址 -->
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>master:8088</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.https.address</name>
        <value>master:8090</value>
    </property>

    <!-- 开启日志聚合功能，方便我们查看任务执行完成之后的日志记录 -->
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>

    <!-- 设置聚合日志在hdfs上的保存时间 -->
    <property>
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>604800</value>
    </property>
</configuration>
EOF

    echo "yarn-site.xml 配置更新完成"
    echo "------------------------------"
    echo ""
}

# 调用函数
update_yarn_site


echo ""
echo ""

# 定义目标主机和文件路径
TARGET_HOSTS=("slave1" "slave2")
SOURCE_JDK="/opt/module/jdk"                 # JDK 软件包目录
SOURCE_HADOOP="/opt/module/hadoop"           # Hadoop 软件包目录
SOURCE_PROFILE="/etc/profile"                # 环境变量配置文件

# 定义目标路径
TARGET_DIR="/opt/module"
TARGET_PROFILE="/etc/profile"

# 进度条函数
show_progress_bar() {
    local total=$1
    local delay=$2
    local current=0
    local bar_width=50

    while [ $current -le $total ]; do
        local completed=$((current * bar_width / total))
        local remaining=$((bar_width - completed))
        local progress_bar=$(printf "%0.s█" $(seq 1 $completed))$(printf "%0.s " $(seq 1 $remaining))
        echo -ne "\r[${progress_bar}] $((current * 100 / total))%"
        sleep "$delay"
        current=$((current + 1))
    done
    echo ""
}


clear

sleep 2
echo ""
echo "请注意！在接下来的传输部分有点久，请耐心等待"
echo ""
echo ""
sleep 2

# 遍历目标主机并传输文件
for host in "${TARGET_HOSTS[@]}"; do
    echo "正在处理目标主机：${host}..."
    
    
    # 确保目标路径存在
    echo "检查并创建目标路径 ${TARGET_DIR}..."
    ssh root@$host "mkdir -p ${TARGET_DIR}"
    if [ $? -eq 0 ]; then
        echo "目标路径 ${TARGET_DIR} 确认完成。"
        echo ""
    else
        echo "无法在 ${host} 上创建路径，请检查网络连接。"
        exit 1
    fi

    # 传输 JDK 目录
    echo "传输 JDK 软件包到 ${host}..."
    (
        scp -r "$SOURCE_JDK" "root@${host}:${TARGET_DIR}" >/dev/null 2>&1 &
        pid=$!
        show_progress_bar 50 0.1
        wait "$pid"
    )
    if [ $? -eq 0 ]; then
        echo "JDK 软件包传输到 ${host} 成功！"
        echo ""
    else
        echo "JDK 软件包传输到 ${host} 失败！"
        exit 1
    fi

    # 传输 Hadoop 目录
    echo "传输 Hadoop 软件包到 ${host}..."
    (
        scp -r "$SOURCE_HADOOP" "root@${host}:${TARGET_DIR}" >/dev/null 2>&1 &
        pid=$!
        show_progress_bar 50 0.1
        wait "$pid"
    )
    if [ $? -eq 0 ]; then
        echo "Hadoop 软件包传输到 ${host} 成功！"
        echo ""
    else
        echo "Hadoop 软件包传输到 ${host} 失败！"
        exit 1
    fi

    # 传输 /etc/profile
    echo "传输 /etc/profile 配置文件到 ${host}..."
    (
        scp "$SOURCE_PROFILE" "root@${host}:${TARGET_PROFILE}" >/dev/null 2>&1 &
        pid=$!
        show_progress_bar 20 0.1
        wait "$pid"
    )
    if [ $? -eq 0 ]; then
        echo "/etc/profile 配置文件传输到 ${host} 成功！"
    else
        echo "/etc/profile 配置文件传输到 ${host} 失败！"
        exit 1
    fi

    # 刷新环境变量
    echo "在 ${host} 上刷新环境变量..."
    ssh root@$host "source /etc/profile"
    if [ $? -eq 0 ]; then
        echo "环境变量刷新成功！"
    else
        echo "刷新环境变量失败！"
        exit 1
    fi

    # 提示完成
    echo "${host} 文件传输和环境变量刷新完成！"
    echo "------------------------------"
    echo ""
done

# 提示传输完成
echo "所有节点文件传输和环境变量刷新完成！"

sleep 2
clear

# 格式化 HDFS 文件系统
echo "正在格式化 HDFS 文件系统..."
hdfs namenode -format
if [ $? -eq 0 ]; then
    echo "HDFS 格式化成功！"
else
    echo "HDFS 格式化失败，请检查日志。"
    exit 1
fi

# 启动 Hadoop 集群
echo "正在启动 Hadoop 集群..."
start-all.sh
if [ $? -eq 0 ]; then
    echo "Hadoop 集群启动成功！"
else
    echo "Hadoop 集群启动失败，请检查日志。"
    exit 1
fi

# 查看 JPS 状态
echo "检查 Hadoop 集群组件状态..."
jps

echo "Hadoop 集群初始化和启动完成！"


sleep 2



cat << EOF
脚本执行完毕！现在清理缓存文件
EOF

# 设置颜色
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# 清理缓存文件的命令
echo -e "${GREEN}开始清理缓存文件...${RESET}"

total_steps=20  
bar_length=30  
for i in $(seq 1 $total_steps); do
    sleep 0.5  # 每个步骤间隔 0.5 秒
    # 计算当前进度
    progress=$((i * 100 / total_steps))
    completed=$((i * bar_length / total_steps))
    remaining=$((bar_length - completed))

    # 打印进度条
    printf "${YELLOW}清理进度: [${RESET}"
    printf "%-${completed}s" "#" | tr " " "#"  # 已完成部分
    printf "%-${remaining}s" " "  # 未完成部分
    printf "] ${GREEN}%3d%%${RESET}\r" $progress  # 显示百分比，确保数字对齐
done

# 换行
echo -e "\n"

clear
# 延迟 1 秒
sleep 2

cat << EOF
----------------------------------------------------------------
缓存文件清除完毕！现在退出脚本操作。
如果有遇到任何问题，可以在GitHub上提出Issues！
----------------------------------------------------------------
EOF
