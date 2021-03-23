
### 本地构建镜像

* 保存对容器的修改
* 自定义容器的能力
* 以软件的形式打包并分发服务及其运行环境

当我们从 docker 镜像仓库中下载的镜像不能满足我们的需求时，我们可以通过以下两种方式对镜像进行更改。

    1、从已经创建的容器中更新镜像，并且提交这个镜像
        $ docker commit 通过容器构建镜像
        
    2、使用 Dockerfile 指令来创建一个新的镜像
        $ docker build  通过Dockerfile构建镜像


在运行的容器内使用 apt-get update 命令进行更新。
在完成操作之后，输入 exit 命令来退出这个容器。

此时 ID 为 e218edb10161 的容器，是按我们的需求更改的容器。我们可以通过命令 docker commit 来提交容器副本。

    runoob@runoob:~$ docker commit -m="has update" -a="runoob" e218edb10161 runoob/ubuntu:v2
    sha256:70bf1840fd7c0d2d8ef0a42a817eb29f854c1af8f7c59fc03ac7bdee9545aff8

各个参数说明：

    -m: 提交的描述信息
    -a: 指定镜像作者
    e218edb10161：容器 ID
    runoob/ubuntu:v2: 指定要创建的目标镜像名

我们可以使用 docker images 命令来查看我们的新镜像 runoob/ubuntu:v2： 

    runoob@runoob:~$ docker images
    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    runoob/ubuntu       v2                  70bf1840fd7c        15 seconds ago      158.5 MB
    ubuntu              14.04               90d5884b1ee0        5 days ago          188 MB
    php                 5.6                 f40e9e0f10c8        9 days ago          444.8 MB
    nginx               latest              6f8d099c3adc        12 days ago         182.7 MB
    mysql               5.6                 f2e8d6c772c0        3 weeks ago         324.6 MB
    httpd               latest              02ef73cf1bc0        3 weeks ago         194.4 MB
    ubuntu              15.10               4e3b13c8a266        4 weeks ago         136.3 MB
    hello-world         latest              690ed74de00f        6 months ago        960 B
    training/webapp     latest              6fae60ef3446        12 months ago       348.8 MB    

使用我们的新镜像 runoob/ubuntu 来启动一个容器

    runoob@runoob:~$ docker run -t -i runoob/ubuntu:v2 /bin/bash                            
    root@1a9fbdeb5da3:/#    

--------------------------------------------------------

# Dockerfile 构建镜像

$ touch Dockerfile

# first Dockerfile for test
FROM ubuntu:14.04
MAINTAINER xxx "xxx"
RUN apt-get update
RUN apt-get install -y nginx
EXPOSE 80

# 创建镜像
sudo docker build -t='xx/xxx' .
# 查看镜像
sudo docker images 
# 提交镜像

#------------------------------------ Dockerfile 基础命令介绍

#注释和指令

# 基本格式

FROM ubuntu:14.04
MAINTAINER happysongs "yafeng.xing@tcl.com"
RUN apt-get update
RUN apt-get install -y ping
EXPOSE 80

# 1. FROM　(必须存在的镜像) 
FROM <image>
FROM <image>:<tag>
FROM <image>:<digest> 
三种写法，其中<tag>和<digest> 是可选项，如果没有选择，那么默认值为latest

# 2. MAINTAINER
MAINTAINER <name>
指定镜像的作者信息，包含镜像所有者和联系信息

# 3. RUN <容器构建时运行的指令>
RUN <command> (shell 模式)
    /bin/sh -c command
    
RUN ["executable", "param1" "param2" ] (exec 模式)
RUN ["/bin/bash" "-c" "echo hello" ]    

指定镜像中运行的命令

# 4. EXPOSE
EXPOSE <port> [<port>...]
    $ docker run -p 80 -d happysongs/ubuntu_test1 ngnix -g "daemon off;"

# 5. CMD <镜像运行时运行的指令> 默认行为会被RUN指令覆盖
CMD [ "execuatable" "param1" "param2" ] (exec 模式)
CMD command param1 param2 (shell 模式)

# 6. ENTEYPOINT 与CMD相似，但是不会被RUN覆盖掉，若需要覆盖掉，需要在docker run --enteypoint覆盖
ENTRYPOINT [ "execuatable" "param1" "param2" ] (exec 模式)
ENTRYPOINT command param1 param2 (shell 模式)

# 7. ADD
ADD <src> ... <dest>
ADD [ "<src>" ... "<dest>" ] (适用于文件路径中有空格的情况)

# 8. COPY　单纯拷贝docker推荐COPY
COPY <src> ... <dest> 镜像中的绝对路径
COPY [ "<src>" ... "<dest>" ] (适用于文件路径中有空格的情况)

# 9. VOLUME 添加卷　共享数据和对数据持久化功能
VOLUME [ "/data" ]

#10. WORKDIR 指定工作路径，会传递下去
WORKDIR /path/to/workdir

    e.g 
    WORKDIR /a
    WORKDIR b
    WORKDIR c
    WORKDIR d
    RUN pwd
    /a/b/c/d

#11. ENV 用来设置环境变量 作用与构建和运行阶段
ENV <key><value>
ENV <key>=<value>...

#12. USER


# 环境设置
CMD　<会被覆盖>
ENTERYPONIT
ADD 
COPY
VOLUME
WORKSPACE
ENV　<设置环境变量>

USER　<设置用户>

    USER user           USER uid
    USER user:group     USER uid:gid
    USER user:gid       USER uid:group

ONBUILD 在编译时

