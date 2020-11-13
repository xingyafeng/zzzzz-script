#!/bin/bash

# if error;then exit
set -e

# 1. manifest
build_manifest=
# 2. 项目名称
build_project=
# 3. 更新源码
build_update_code=
# 4. 是否清除编译
build_clean=

# 调试开关
build_debug=

## --------------------------------

declare -a build_path
declare -a build_module_list
declare -a change_number_list

# 本次触发PATCHSET
gerrit_patchset_revision=

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

function handle_common_vairable() {

    # 1. 配置java环境
    set_java_home_path

    # 2. 配置ccache
    use_ccache
}

function handle_vairable() {

    # 1. manifest
    build_manifest=${VerManifest:-}

    # 2. 项目名称
    build_project=${local_project:-}

    # 3. 更新源码
    build_update_code=${tct_update_code:-false}

    # 4. 清除编译
    build_clean=${tct_clean:=false}

    # --------------------------------

    build_debug=${tct_debug:-true}
    if [[ "${tct_debug}" == "true" ]]; then
        build_debug=false
    else
        build_debug=true
    fi

    handle_common_vairable
}

function print_variable() {

    echo
    echo '-------------------------------------'
    echo 'JOBS = ' ${JOBS}
    echo '-------------------------------------'
    echo 'build_debug        = ' ${build_debug}
    echo 'build_clean        = ' ${build_clean}
    echo 'build_project      = ' ${build_project}
    echo 'build_manifest     = ' ${build_manifest}
    echo 'build_update_code  = ' ${build_update_code}
    echo '-------------------------------------'
    echo 'WORKSPACE          = ' ${WORKSPACE}
    echo 'GERRIT_TOPIC       = ' ${GERRIT_TOPIC}
    echo '-------------------------------------'
    echo 'GERRIT_PROJECT            = ' ${GERRIT_PROJECT}
    echo 'GERRIT_BRANCH             = ' ${GERRIT_BRANCH}
    echo 'GERRIT_CHANGE_URL         = ' ${GERRIT_CHANGE_URL}
    echo 'GERRIT_REFSPEC            = ' ${GERRIT_REFSPEC}
    echo 'GERRIT_CHANGE_NUMBER      = ' ${GERRIT_CHANGE_NUMBER}
    echo 'GERRIT_PATCHSET_NUMBER    = ' ${GERRIT_PATCHSET_NUMBER}
    echo 'GERRIT_PATCHSET_REVISION  = ' ${GERRIT_PATCHSET_REVISION}
    echo '-------------------------------------'
    echo 'gerrit_patchset_revision  = ' ${gerrit_patchset_revision}
    echo '-------------------------------------'
    echo
}

function prepare() {

    local workspace=${WORKSPACE}/${JOB_NAME}

    if [[ ! -d ${workspace} && -n ${workspace} ]]; then
        mkdir -p ${workspace}
    fi

    pushd ${workspace} > /dev/null

    if [[ -f aborted_flag ]]; then
        rm -vf aborted_flag
    fi

    if [[ -d ${gerrit_p} ]]; then
        rm -rvf ${gerrit_p}/*
    fi

    # 配置根路径
    gettop_p=$(pwd)

    # 记录 current patchset
    gerrit_patchset_revision=${GERRIT_PATCHSET_REVISION}
}

function init() {

    prepare

    handle_vairable
    print_variable
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    ## 记录编译开始时间
    local startT=`date +'%Y-%m-%d %H:%M:%S'`

    if [[ "$(is_build_server)" == "true" ]];then
        init
    else
        log error "The server is not running on build server."
    fi

    echo
    show_vip "--> make android start ." && log debug "--> make android start ."

    if [[ "$(is_gerrit_trigger)" == "false" ]];then
        if [[ "${build_update_code}" == "true" ]];then
            download_android_source_code
        else
            log warn "This time you don't update the source code."
        fi
    else
        # 生成manifest列表
        generate_manifest_list
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        ### 初始化环境变量
        if [[ "`is_check_lunch`" == "no lunch" ]];then
            source_init
        else
            print_env
        fi

        handle_tct_custom
    fi

    if [[ "$(is_gerrit_trigger)" == "true" ]];then
        parse_all_patchset
        check_patchset_status
        download_all_patchset
        gerrit_build
    else
        if ${build_debug} ; then
            # 编译android
            make_android
        fi
    fi

    if [[ "$(is_build_server)" == "true" ]];then

        ### 打印编译所需要的时间
        print_make_completed_time

        echo
        show_vip "--> make android end ." && log debug "--> make android end ."
    else
        log error "The server is not running on build server."
    fi

    popd > /dev/null

    trap - ERR
}

main "$@"