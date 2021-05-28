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
declare -a build_modem
declare -a build_module_list
declare -a change_number_list

# 统计项目
declare -a project_paths

# 无效的模块
declare -a invalid_module

# 强耦合项目
declare -a tct_projects

# 本次触发PATCHSET
gerrit_patchset_revision=

# build modem 类型
build_modem_type=

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

function handle_common_vairable() {

    # 1. 配置java环境
    set_java_home_path

    # 2. 配置ccache
    use_ccache

    # 3. 配置manifest
    set_manifest_xml

    # 4. 拿到modem类型
    get_modem_type
}

function handle_compile_para() {

    # compile_para 编译参数
    case ${JOB_NAME} in

        Thor84gVZW-R_Gerrit_Build)
            compile_para[${#compile_para[@]}]='TCT_EFUSE=true'
            compile_para[${#compile_para[@]}]='ANTI_ROLLBACK=0'
        ;;

        DohaTMO-R_Gerrit_Build)
            compile_para[${#compile_para[@]}]='TARGET_BUILD_VARIANT=user,TARGET_BUILD_MODEM=true,ANTI_ROLLBACK=1,TCT_EFUSE=true,TARGET_BUILD_MMITEST=false'
        ;;

    esac
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

    buildlist=${buildlist_p}/buildlist.${job_name}.ini

    handle_common_vairable
    handle_compile_para
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
    echo 'build_modem_type   = ' ${build_modem_type}
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
    echo '${invalid_module[@]}      = ' ${invalid_module[@]}
    echo "compile_para  = " ${compile_para[@]}
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
    set_invalid_module
}

function init() {

    prepare

    handle_vairable
    print_variable
}

##########################################################
#
#                   关键的文件
#
#   1. buildlist.ini 项目路径:编译目标
#   2. manifest_list_for_xxx.txt  gerrit-path:android-path
#   3. env.ini      Topic存在时，当前触发gerrit环境变量
#   4. noenv.in     Topic不存在时，当前触发gerrit环境变量
#   5. bpath.txt    实际android.* 的路径
#   6. bproject.txt 实际项目路径.s
#   7. gerrit
#       a. 324299 次数触发的关键信息
#       b. changeid.json
#       c. change_number_list.txt
#   8.
#
##########################################################
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