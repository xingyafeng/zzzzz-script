#!/usr/bin/env bash

## script path
nxos_p=nxos
yunos_p=yunos
droid_p=android

jenkins_p=jenkins
gerrit_p=gerrit

yunovo_p=yunovo

shellfs=${shellfs##*/}

## 初始化公共的函数
. "`dirname $0`/$jenkins_p/yunovo_show.sh"
. "`dirname $0`/$jenkins_p/yunovo_log.sh"
. "`dirname $0`/$jenkins_p/yunovo_build.sh"
. "`dirname $0`/$jenkins_p/yunovo_common.sh"
. "`dirname $0`/$jenkins_p/yunovo_tools.sh"
. "`dirname $0`/$jenkins_p/yunovo_git_func.sh"
. "`dirname $0`/$jenkins_p/yunovo_simple_func.sh"

. "`dirname $0`/$yunovo_p/yunovo_git_misc.sh"
. "`dirname $0`/$yunovo_p/yunovo_misc.sh"

. "`dirname $0`/$gerrit_p/yunovo_ssh_gerrit.sh"

case ${shellfs} in

    build_sdk.sh)
        . "`dirname $0`/$jenkins_p/$droid_p/yunovo_handle_old_branch.sh"
        . "`dirname $0`/$jenkins_p/$droid_p/yunovo_handle_branch.sh"
        . "`dirname $0`/$jenkins_p/$droid_p/yunovo_make_func.sh"

        make_version=Android
        ;;

    make_android.sh|makefs.sh|replace_logo.sh|make_ota.sh|build_ota.sh|repo_diffmanifests.sh|make_so.sh)
        . "`dirname $0`/$jenkins_p/$droid_p/yunovo_make_android.sh"

        make_version=Android
        ;;

    mm.sh|rsync.sh|rdiff_backup.sh|build_app.sh|gerrit_cherry_pick.sh|demo.sh|notify.sh|apk_release.sh|rom_release.sh|apk_resign.sh)
        :
        ;;

    gitrepositories.sh|pref.sh|updatemanifest.sh|updatebranch.sh|check_app.sh)
        :
        ;;

    make_nxos.sh)
        . "`dirname $0`/$jenkins_p/$nxos_p/yunovo_make_nxos.sh"
        ;;

    mk_aliphone.sh|mk_aliphone4mt6737t.sh)
        . "`dirname $0`/$jenkins_p/$yunos_p/yunovo_make_aliphone.sh"

        make_version=Yunos
        ;;

    teleweb2zip.sh|download_mirror.sh)
        :
        ;;

    *)
        log error "执行脚本不匹配 ..."
        ;;
esac
