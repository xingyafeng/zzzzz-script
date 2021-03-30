#!/usr/bin/env bash

# 清除 Dockerfile构建相同名称时,产生的无名镜像文件 <none>:<none>
function docker-clean-image() {

    docker rmi $(docker images -f "dangling=true" -q)
}

# 清除已经退出的容器
function docker-clean-container() {

    docker rm $(docker ps -qf status=exited)
}