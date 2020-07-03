#!/usr/bin/env bash

## 初始化公共的函数
. "`dirname $0`"/init_script.sh

case ${shellfs##*/} in

    *)
        log error "执行脚本不匹配 ..."
        ;;
esac