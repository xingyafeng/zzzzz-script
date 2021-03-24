
### 容器的基本操作

# 交互式容器

1. 启动容器:

    * $ docker run IMAGE [COMMAND] [ARGS...]
        run 在新容器中执行命令 

    e.g.
        $ docker run ubuntu echo 'hello world ...'
    

2. 启动交互式容器

    * $ docker run -i -t IMAGE /bin/bash
        -i --interactive=[true|false] default:false
        -t --tty = [true|false] default:false

    e.g 
        $ docker run -i -t ubuntu /bin/bash
        $ exit
        
3. 查看容器

    ＊ $ docker ps [-a] [-l]
        -a : 查看所以的容器
        -l : 查看本地
        无参数：查看运行中的容器

4. 查看容器运行的信息

    ＊　$ docker inspect IMAGE [ID]

5. 自定义容器名称

    ＊ docker run --name=自定义名称 -i -t IMAGE /bin/bash

6. 重新启动已经停止的容器

    * docker start [-i] 容器名

7. 删除已经停止的容器
    
    * docker rm [容器名称]
    
    批量删除退出的容器
    docker rm $(docker ps -a | grep Exited | awk '{print $1}')
    批量删除所有容器
    docker rm $(docker ps -aq)

# 守护式容器

1. 以守护形式运行容器

    * $ docker run -i -t IMAGE /bin/bash
    Ctrl+P Ctrl+Q 退出容器，进入守护状态，即后台运行

2. 进入守护式容器

    * $ docker attach [容器名]　<id or image>

3. 启动守式容器

    * $ docker run --name=名称 -d 镜像名 [COMMAND] [ARGS...] # 后台启动容器
        
        ip:hostPort:containerPort
        
        # 端口映射 
        docker run -p 80              -i -t ubuntu /bin/bash
        docker run -p 8080:80         -i -t ubuntu /bin/bash
        docker run -p 0.0.0.0:80      -i -t ubuntu /bin/bash
        docker run -p 0.0.0.0:8080:80 -i -t ubuntu /bin/bash

4. 查看容器运行的日志

    ＊　$ docker logs [-f][-t][--tail] 容器名
            -f : --follow=[true|false] default:false
            -t : --timestamps[true|false] default:false
            --tail : 'all'

        $ docker logs -tf --tail [0|10] dc1
        $ docker ps dc1

5. 在运行的容器内启动新进程

    * $ docker exec [-d][-i][-t] 容器名 [COMMAND] [ARGS...]

6. 停止守护式容器

    * docker stop 容器名　# 发送信号
    * docker kill 容器名　# kill 
    
    停止容器　容器的ip地址和端口都发生变化

    docker port web
    docker top  web
        

# 查看和删除镜像

1. 列出镜像
    
    ＊ docker image [OPTSIONS] [REPOSITORY]
        -a: --all=false
        -f: --filter=[]
        --no-trunc=false
        -q, -quiet=false
    
2. 镜像标签和仓库
    
        
3. 查看镜像
    
    * docker inspect [OPTSIONS] CONTAINER|IMAGE|[CONTAINER|IMAGE...]
        -f: --format="" 

4. 删除镜像

    * docker rmi [OPTSIONS] IMAGE [IMAGE...]
        -f: force=false Force removal of the image
        --no-prune=false Do not delete untagged parents
        
        e.g
            docker rmi $(docker images -q) # 删除所有的镜像
            docker rmi (id...)

# 推送和获取镜像

1. 查找镜像
    
    * docker search 
    
2. 拉取镜像
    
    * docker pull 
    
    加速下载速度
        
3. 推送镜像

    * docker push 


# 本地构建镜像Create DockerCreate.md