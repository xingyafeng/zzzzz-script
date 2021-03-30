#!/usr/bin/env bash

# 清除 Dockerfile构建相同名称时,产生的无名镜像文件 <none>:<none>
function docker-clean-image() {

    if [[ -n "$(docker images -f "dangling=true" -q)" ]]; then
        docker rmi $(docker images -f "dangling=true" -q)
    else
        echo
        show_vip "It has no found none images ..."
    fi
}

# 清除已经退出的容器
function docker-clean-container() {

    if [[ -n "$(docker ps -qf status=exited)" ]]; then
        docker rm $(docker ps -qf status=exited)
    else
        echo
        show_vip "It has no found exited container ..."
    fi
}