# AutomaticScript

> 帮助您解放双手
> <br>

## 这是什么❓

-  一个快速执行生成Hadoop集群的脚本，它可以方便你的Hadoop集群搭建工作，节省时间。
-  请注意！该脚本可能在执行的时候有点漫长，请耐心等待
-  脚本执行需要什么？

```bash
三台Linux主机系统，分别将其命名为 Master，Slave1，Slave2 然后确保三台机器处于同一个网段下，可以互相访问到彼此
```

- 该脚本在执行的时候将会安装Jdk环境（jdk-8u212-linux-x64）与Hadoop环境（hadoop-3.1.3）

 <br>

## 如何使用🚀

-  将软件包[下载](https://github.com/YEXIAONAN/HadoopScript/releases/download/v1.0/HadoopScript.tar.gz)并上传至您的Hadoop集群中的Master（主机点中）将其解压
-  `tar -zxvf HadoopScript.tar.gz -C 您的目录`
-  进入解压完毕后的目录，赋予脚本执行权限

```bash
# 进入目录
cd hadoopScript

# 赋予脚本权限
chmod +x init.sh

# 启动脚本
sudo ./init.sh

# 安静等待
```