#!/usr/bin/env bash

# 初始化公共的函数
. "`dirname $0`"/init_script.sh

case ${shellfs##*/} in

    ssh-gerrit-review.sh)
        :
        ;;
    *)
        log error "执行脚本文件不匹配 ..."
        ;;
esac
