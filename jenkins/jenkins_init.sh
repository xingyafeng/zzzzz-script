#!/usr/bin/env bash

# 初始化公共函数
. "`dirname $0`"/init_script.sh

# 初始化差异函数
case ${shellfs##*/} in

    build_sdk.sh) #编译Android
        . "`dirname $0`"/jenkins/yunovo/yunovo_make_func.sh

        make_version=Android
        ;;

    make_android.sh|makefs.sh) #编译Android
        . "`dirname $0`"/jenkins/yunovo/yunovo_make_android.sh

        make_version=Android
        ;;

    mk_aliphone.sh|mk_aliphone4mt6737t.sh) #编译阿里
        . "`dirname $0`"/jenkins/yunos/yunovo_make_aliphone.sh

        make_version=Yunos
        ;;

    make_nxos.sh) #编译应用
        . "`dirname $0`"/jenkins/nxos/yunovo_make_nxos.sh
        ;;

    make_ota.sh|build_ota.sh|make_so.sh) #编译OTA SO
        . "`dirname $0`"/jenkins/yunovo/yunovo_make_android.sh
        ;;

    repo_diffmanifests.sh|replace_logo.sh) #构建差异
        . "`dirname $0`"/jenkins/yunovo/yunovo_make_android.sh
        ;;

    apk_release.sh|rom_release.sh) #发布APK和ROM版本
        :
        ;;

    check_app.sh|build_app.sh|apk_resign.sh) #APK重签名
        ;;

    notify.sh|demo.sh|mm.sh|rsync.sh|rdiff_backup.sh|updatemanifest.sh) #misc
        :
        ;;

    gitrepositories.sh|pref.sh|updatebranch.sh|gerrit_cherry_pick.sh) #git
        :
        ;;

    get_manifest_info.sh)
        :
        ;;
    *)
        log error "执行脚本不匹配 ..."
        ;;
esac