#!/usr/bin/env bash

## 初始化公共的函数
. "`dirname $0`"/init_script.sh

case ${shellfs##*/} in

    build_sdk.sh)
        . "`dirname $0`"/jenkins/yunovo/yunovo_make_func.sh

        make_version=Android
        ;;

    make_android.sh|makefs.sh|replace_logo.sh|make_ota.sh|build_ota.sh|repo_diffmanifests.sh|make_so.sh)
        . "`dirname $0`"/jenkins/yunovo/yunovo_make_android.sh

        make_version=Android
        ;;

    mm.sh|rsync.sh|rdiff_backup.sh|build_app.sh|gerrit_cherry_pick.sh|demo.sh|notify.sh|apk_release.sh|rom_release.sh|apk_resign.sh)
        :
        ;;

    gitrepositories.sh|pref.sh|updatemanifest.sh|updatebranch.sh|check_app.sh)
        :
        ;;

    make_nxos.sh)
        . "`dirname $0`"/jenkins/nxos/yunovo_make_nxos.sh
        ;;

    mk_aliphone.sh|mk_aliphone4mt6737t.sh)
        . "`dirname $0`"/jenkins/yunos/yunovo_make_aliphone.sh

        make_version=Yunos
        ;;

    teleweb2zip.sh|download_mirror.sh)
        :
        ;;

    *)
        log error "执行脚本不匹配 ..."
        ;;
esac
