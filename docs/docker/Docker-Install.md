
# 安装步骤参考
https://docs.docker.com/engine/install/ubuntu # 官方步骤
https://blog.csdn.net/bobo184/article/details/88957636 # 博客步骤

## Ubuntu中安装Docker

#条件
1. 内核版本 （3.1版本以上，ubuntu14.04以上）
    $ uname -a
    
2. 检查Device Mapper（存储驱动）
    $ ls /sys/class/misc/device-mapper -l

安装方式：
    1. Ubuntu提供的源 apt-get，版本比较旧，更新不及时，建议不采用
    2. Docker官方安装步骤

####################################################################################################

安装Docker官方源

# Uninstall old versions (卸载旧版本)
    $ sudo apt-get remove docker docker-engine docker.io containerd runc

# Uninstall Docker Engine
    $ sudo apt-get purge docker-ce docker-ce-cli containerd.io
    $ sudo rm -rf /var/lib/docker
    $ sudo rm -rf /var/lib/containerd

# --------------------------------------------------------------------------------------------------
    
# Install using the repository    
    
# Set up the repository

## 1. Update the apt package index and install packages to allow apt to use a repository over HTTPS:
    
    $ sudo apt-get update
    $ sudo apt-get install \
          apt-transport-https \
          ca-certificates \
          curl \
          gnupg \
          lsb-release

## 2. Add Docker’s official GPG key
    
    $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

## 3. Use the following command to set up the stable repository

    $ echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null    


# Install Docker Engine

## 1. Update the apt package index, and install the latest version of Docker Engine and containerd, or go to the next step to install a specific version: 
    
    $ sudo apt-get update
    $ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8 # 当出现问题
    $ sudo apt-get install docker-ce docker-ce-cli containerd.io

## 2. To install a specific version of Docker Engine, list the available versions in the repo, then select and install:
    
    a. List the versions available in your repo:
        $ apt-cache madison docker-ce
    
    b. Install a specific version using the version string from the second column, for example, 5:18.09.1~3-0~ubuntu-xenial.
        $ sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io
    
    c. Verify that Docker Engine is installed correctly by running the hello-world image.
        $ sudo docker run hello-world
        

# --------------------------------------------------------------------------------------------------

Install using the convenience script

    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker <your-user>
   

# -------------------------------------------------------------------------------------------------- 个人安装步骤
                
第一步：设置包管理器仓库
在Ubuntu上设置Docker仓库。 lsb_release -cs 可以显示你的 Ubuntu 版本，比如 xenial 或者 trusty。
设置完成后，更新包管理器。

    1. Install https 检查HTTPS支持情况
    sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

第二步：安装Docker

    sudo apt-get update
    sudo apt-get install docker-ce -y

docker info warn       
解决：docker警告WARNING: No swap limit support　// https://www.k2zone.cn/?p=2356

第二步：Docker验证

    sudo docker run hello-world
    结果如下：
    Hello from Docker!
    This message shows that your installation appears to be working correctly.
    
    To generate this message, Docker took the following steps:
     1. The Docker client contacted the Docker daemon.
     2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
        (amd64)
     3. The Docker daemon created a new container from that image which runs the
        executable that produces the output you are currently reading.
     4. The Docker daemon streamed that output to the Docker client, which sent it
        to your terminal.
    
    To try something more ambitious, you can run an Ubuntu container with:
     $ docker run -it ubuntu bash
    
    Share images, automate workflows, and more with a free Docker ID:
     https://hub.docker.com/
    
    For more examples and ideas, visit:
     https://docs.docker.com/get-started/

第四部：取消sudo，执行Docker命令（非必要）

    # 增加组
    sudo groupadd docker 
    # 将当前户名加入组内
    sudo gpasswd -a ${USER} docker　
    # 重启服务器
    sudo service docker restart　
    
    ---------
    
    sudo usermod -aG docker ${USER}
    
    #　切换当前会话到新 group 或者重启 X 会话
    newgrp - docker　

到此完成。
    

# 查询社区版本：
$ apt-cache madison docker-ce

#安装指定版本：
apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io

#举栗子：
apt-get install docker-ce=5:20.10.0~3-0~ubuntu-xenial docker-ce-cli=5:20.10.0~3-0~ubuntu-xenial containerd.io
sudo yum install docker-ce-3:20.10.6-3.el7 docker-ce-cli-3:20.10.6-3.el7 containerd.io
    
# 一
docker run -d -p 80:80 httpd

# 登录
10.129.46.47:80
    
# 二、镜像加速器  ubuntu centos
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://8myihr0t.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

# 三、命令补全

# docker
$ apt install bash-completion     
$ source /etc/bash_completion

# docker-compose 命令补全
/etc/bash_completion.d/docker-compose.sh

sudo curl -L https://github.com/docker/compose/releases/download/1.20.1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

# 四、卸载
root@ubuntu1604:~# rm -rf /var/lib/docker
root@ubuntu1604:~# rm -rf /etc/docker

如果其他路径有docker相关配置文件或目录，一并删除。

# 五 配置文件

/etc/docker/daemon.json

{
  "registry-mirrors": ["https://8myihr0t.mirror.aliyuncs.com"], ## 镜像
  "insecure-registries":["happysongs:180", "127.0.0.1:180"]　## 私有仓库
}

说明：https://www.cnblogs.com/pzk7788/p/10180197.html　解释文件含义

# ------------------------------------------------------------------------------ 阿里云下载

# step 1: 安装必要的一些系统工具
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
# step 2: 安装GPG证书
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
# Step 3: 写入软件源信息
sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
# Step 4: 更新并安装Docker-CE
sudo apt-get -y update
sudo apt-get -y install docker-ce # --->>> 是否需要指定版本

# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# apt-cache madison docker-ce
#   docker-ce | 17.03.1~ce-0~ubuntu-xenial | https://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
#   docker-ce | 17.03.0~ce-0~ubuntu-xenial | https://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
# Step 2: 安装指定版本的Docker-CE: (VERSION例如上面的17.03.1~ce-0~ubuntu-xenial)
# sudo apt-get -y install docker-ce=[VERSION]