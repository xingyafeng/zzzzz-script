#!/usr/bin/env bash

################################# 公共变量 (全局变量)
workspace_p=~/workspace
script_p=${workspace_p}/script/zzzzz-script

# script path
nxos_p=nxos
yunos_p=yunos
droid_p=android

jenkins_p=jenkins
gerrit_p=gerrit

yunovo_p=yunovo

shellfs=${shellfs##*/}

# 初始化公共的函数
. "${script_p}/${jenkins_p}/yunovo_show.sh"
. "${script_p}/${jenkins_p}/yunovo_log.sh"
. "${script_p}/${jenkins_p}/yunovo_common.sh"
. "${script_p}/${jenkins_p}/yunovo_tools.sh"
. "${script_p}/${jenkins_p}/yunovo_git_func.sh"
. "${script_p}/${jenkins_p}/yunovo_simple_func.sh"

. "${script_p}/${yunovo_p}/yunovo_git_misc.sh"
. "${script_p}/${yunovo_p}/yunovo_misc.sh"

. "${script_p}/${gerrit_p}/yunovo_ssh_gerrit.sh"

case ${shellfs} in

    build_sdk.sh)
        . "${script_p}/${jenkins_p}/${droid_p}/yunovo_handle_old_branch.sh"
        . "${script_p}/${jenkins_p}/${droid_p}/yunovo_handle_branch.sh"
        . "${script_p}/${jenkins_p}/${droid_p}/yunovo_make_func.sh"

        make_version=Android
        ;;

    make_android.sh|makefs.sh|replace_logo.sh|make_ota.sh|build_ota.sh|repo_diffmanifests.sh)
        . "${script_p}/${jenkins_p}/${droid_p}/yunovo_make_android.sh"

        make_version=Android
        ;;

    make_nxos.sh)
        . "${script_p}/${jenkins_p}/${nxos_p}/yunovo_make_nxos.sh"
        ;;

    mk_aliphone.sh|mk_aliphone4mt6737t.sh)
        . "${script_p}/${jenkins_p}/${yunos_p}/yunovo_make_aliphone.sh"

        make_version=Yunos
        ;;

    demo.sh|ssh_gerrit_set_project_parent_eg.sh|set_project_readonly.sh|test_download_code.sh)
        :
        ;;

    ssh-gerrit-review.sh)
        :
        ;;
    *)
        log error "执行脚本文件不匹配 ..."
        ;;
esac