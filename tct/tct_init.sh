#!/usr/bin/env bash

## 初始化公共的函数
. "`dirname $0`"/init_script.sh

case ${shellfs##*/} in

    teleweb2zip.sh)
        ;;

    download_mirror.sh)
        ;;

    bts2zip.sh)
        ;;

    jrdfota.sh)
        ;;

    build_release.sh)
        ;;

    # 预编译
    prebuild.sh|apk_prebuild.sh)
        ;;

    demo.sh)
        :
        ;;
    *)
        log error "执行脚本不匹配 ..."
        ;;
esac