
# docker

什么是容器？
一种虚拟化方案，操作系统级别的虚拟化，只能运行相同或相似内核的操作系统，依赖与内核特性：Namespace和Cgroups(Control Group)

优点：
磁盘空间更少
低内存　低cpu 轻量级别

什么是docker？
将应用程序自动部署到容器的开元引擎　go语言开发
2013年初　dotCloud
基于apache2.0开源授权协议发行

Docker的目标？
提供简单　轻量的建模方式
职责的逻辑分离
快速高效的开发生命周期　使用一致的开发测试部署环境
鼓励使用面向服务的架构

Docker的应用场景？
1 使用Docker 容器开发　测试　部署服务．
2 创建隔离的运行环境
3 搭建测试平台
4 构建多用户平台及服务（PaaS）基础设施
5 提供软件及服务（PaaS）应用程序
6 高性能 超大规模的宿主机部署

OPENstack
Docker 基本组成
c/s架构
联合加载技术

特性：
只能运行相同内核的系统

Docker 的目标
提供简单轻量的建模方式

查看镜像和列出镜像

1/ 列出镜像
2/ 镜像的标签和仓库
3/ 查看镜像
    
    docker images # 已安装的镜像
    
    yafeng.xing@u-yafeng ~ $ sudo docker images -a
    
    仓库　　　　　　　标签　　　唯一id                          大小
    REPOSITORY        TAG       IMAGE ID       CREATED          SIZE
    happysongs/test   latest    c15c2c68958e   25 minutes ago   197MB
    httpd             latest    dd85cdbb9987   13 days ago      138MB
    ubuntu            latest    f643c72bc252   4 weeks ago      72.9MB
    ubuntu            14.04     df043b4f0cf1   3 months ago     197MB
    hello-world       latest    bf756fb1ae65   11 months ago    13.3kB
     
    REPOSITORY　仓库
    TAG         标签

    REPOSITORY/TAG    -> ID
    REPOSITORY/latest -> ID
    
    docker images --no-trunc # 完整的id
    docker images -a # 空的　表示中间层的镜像
    sudo docker images ubuntu
    
    sudo docker inspect ubuntu:14.04 # 查看详细信息
    sudo docker inspect id
    
4/ 删除镜像

    sudo docker rmi ubuntu:14.04 # 当有多个时　会提示
    sudo docker rmi id id id
    sudo docker rmi $(docker image -q ubuntu) # 删除所有的镜像


-------------------------

1. sudo docker pull ubuntu


镜像加速

https://www.daocloud.io/

启动配置文件
vi /etc/default/docker

DOCKER_OPTS = "-registry-mirror=xxxx"


2. sudo docker push xxx/xxx


# 远程访问
-H 
环境变量

