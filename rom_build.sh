#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# 1. 版本号
build_version=
build_baseversion=
# 2. 临时分支名
build_tmpbranch=
build_manifest=
# 3. 编译类型 如: [user|userdebug|eng]
build_type=
# 4. 编译服务器标签
build_server_x=
build_server_y=
# 5. anti rollback
build_anti_rollback=
# 6. rsu key
build_rsu_key=
# 7. 更新源代码
build_update_code=
# 8. 是否清除
build_clean=
# 9. efuse
build_efuse=
# 10. user to root
build_user2root=
# 11. ship
build_isship=
# 12. delivery bug
build_delivery_bug=

# ----
# driveronly|mini|cert|appli|daily
VER_VARIANT=

# 编译项目
BUILDPROJ=
# 项目名称
PROJECTNAME=
# modem项目
MODEMPROJECT=

# modem type
modem_type=
# sign apk
signapk=

getprojectinfo=

build_enduser=

# init function
. "$(dirname "$0")/tct/tct_init.sh"

function get_cpu_core() {

    case ${JOBS} in

        8)
            JOBS=${JOBS}
            ;;

        *)
            JOBS=$((JOBS/2))
            ;;
    esac
}

function handle_common() {

    unset BUILD_NUMBER
    unset BUILD_ID

    # 拿到JOBS
    get_cpu_core

    # 配置manifest.xml
    set_manifest_xml

    # 配置WORKSPACE
    gettop_p=$(pwd)
}

function handle_compile_para() {

    # compile_para 编译参数
    case ${JOB_NAME} in

        transformervzw)
            if [[ -n "${build_efuse}" ]]; then
                compile_para[${#compile_para[@]}]="TCT_EFUSE=${build_efuse}"
            fi

            if [[ -n "${build_anti_rollback}" ]]; then
                compile_para[${#compile_para[@]}]="ANTI_ROLLBACK=${build_anti_rollback}"
            fi
        ;;

        dohatmo-r)
            compile_para[${#compile_para[@]}]="TARGET_BUILD_VARIANT=${build_type},"
            compile_para[${#compile_para[@]}]="TARGET_BUILD_MODEM=true,"

            if [[ -n "${build_anti_rollback}" ]]; then
                compile_para[${#compile_para[@]}]="ANTI_ROLLBACK=${build_anti_rollback},"
            fi

            if [[ -n "${build_efuse}" ]]; then
                compile_para[${#compile_para[@]}]="TCT_EFUSE=${build_efuse},"
            fi

            compile_para[${#compile_para[@]}]="TARGET_BUILD_MMITEST=$(is_mini_version)"
        ;;
    esac
}

function handle_variable() {

    # 3. 编译类型
    build_type=${tct_type:=user}
    if [[ "`is_build_type`" == "false" ]];then
        ## 若jenkins填写不规范，默认为user
        build_type=user
    fi

    # 4. 编译服务器
    build_server_x=${tct_server_x:-s3}
    build_server_y=${tct_server_y:-s0}

    # 5. anti rollback
    build_anti_rollback=${tct_anti_rollback:-0}

    # 6. rsu key
    build_rsu_key=${tct_rsu_key:-0}

    # 7. 更新代码
    build_update_code=${tct_update_code:-false}

    # 8. 清除编译
    build_clean=${tct_clean:-false}

    # 9. efuse
    build_efuse=${tct_efuse-:false}

    # 10. user to root
    build_user2root=${tct_user2root:-false}

    # 11. ship
    build_isship=${tct_isship:-false}

    # 12. delivery bug
    build_delivery_bug=${tct_delivery_bug:-false}

    # 13. userdebug
    build_userdebug=${tct_userdebug:-false}

    # 14 .enduser
    build_enduser=${tct_enduser-:false}
    # ---------------------------------------------

    handle_common
    handle_compile_para
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_version           = " ${build_version}
    echo "build_baseversion       = " ${build_baseversion}
    echo "build_tmpbranch         = " ${build_tmpbranch}
    echo "build_manifest          = " ${build_manifest}
    echo "build_type              = " ${build_type}
    echo "build_server_x          = " ${build_server_x}
    echo "build_server_y          = " ${build_server_y}
    echo "build_anti_rollback     = " ${build_anti_rollback}
    echo "build_rsu_key           = " ${build_rsu_key}
    echo "build_update_code       = " ${build_update_code}
    echo "build_clean             = " ${build_clean}
    echo "build_efuse             = " ${build_efuse}
    echo "build_user2root         = " ${build_user2root}
    echo "build_isship            = " ${build_isship}
    echo "build_delivery_bug      = " ${build_delivery_bug}
    echo "build_userdebug         = " ${build_userdebug}
    echo "build_enduser           = " ${build_enduser}
    echo '-----------------------------------------'
    echo "VER_VARIANT             = " ${VER_VARIANT}
    echo "BUILDPROJ               = " ${BUILDPROJ}
    echo "PROJECTNAME             = " ${PROJECTNAME}
    echo "MODEMPROJECT            = " ${MODEMPROJECT}
    echo "modem_type              = " ${modem_type}
    echo "signapk                 = " ${signapk}
    echo "getprojectinfo          = " ${getprojectinfo}

    echo '-----------------------------------------'
    echo "gettop_p                = " ${gettop_p}
    echo '-----------------------------------------'
    echo "compile_para  = " ${compile_para[@]}

    echo '-----------------------------------------'
    echo
}

function perpare() {

    local PLATFORM=

    tct::utils::get_platform_info

    # 1. 版本号
    build_version=${tct_version:-}
    if [[ -z ${build_version} ]]; then
        log error "The build version is null ..."
    fi

    build_baseversion=${tct_baseversion:-}

    VER_VARIANT=$(tct::utils::get_version_variant)

    # 下载编译使用的工具仓库
    tct::utils::downlolad_tools

    tct::utils::get_moden_type
    tct::utils::get_signapk_para
    tct::utils::get_project_info

    # 2. 临时分支
    build_tmpbranch=${tct_tmpbranch:-}

    if [[ -z ${build_tmpbranch} ]]; then
        build_manifest=$(tct::utils::get_manifest_branch)
    else
        build_manifest=${build_tmpbranch}
    fi

    if [[ -z ${build_manifest} ]]; then
        log error 'The manifest is null ...'
    fi


    # 编译项目
    BUILDPROJ=$(tct::utils::get_build_project)

    # 项目名称
    PROJECTNAME=$(tct::utils::get_project_name)

    # modem项目
    MODEMPROJECT=$(tct::utils::get_modem_project)

    # -------------------------------------------------------

}

function init() {

    handle_variable
    print_variable
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    local root_p=~/jobs
    local object=${1:-}
    local stime=150

    perpare

    case $# in
        1)
            case ${object} in

                qssi_download)
                    local build_p=${root_p}/${job_name}X/${build_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${build_p} > /dev/null

                    init

                    if [[ "${build_update_code}" == "true" ]];then
                        # 下载，更新源代码
                        download_android_source_code
                    else
                        log warn "This time you don't update the source code."
                    fi

                    popd > /dev/null
                    ;;

                target_download|download)
                    log debug 'download code ...'

                    #检查磁盘空间大小
                    tct::utils::check_dist_space

                    local build_p=${root_p}/${job_name}Y/${build_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${build_p} > /dev/null

                    init

                    update_gapp

                    if [[ "${build_update_code}" == "true" ]];then
                        # 下载，更新源代码
                        download_android_source_code
                    else
                        log warn "This time you don't update the source code."
                    fi

                    # 如果是appli和debug版本时创建version和manifest
                    is_appli_debug

                    popd > /dev/null
                    ;;

                qssi_clean)
                    local build_p=${root_p}/${job_name}X/${build_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${build_p} > /dev/null

                    init
                    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
                        outclean
                    else
                        log warn "The (.repo) not found ! please download android source code !"
                    fi

                    popd > /dev/null
                    ;;

                target_clean|clean)
                    log debug  "outclean ..."

                    local build_p=${root_p}/${job_name}Y/${build_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${build_p} > /dev/null

                    init
                    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
                        outclean
                    else
                        log warn "The (.repo) not found ! please download android source code !"
                    fi

                    popd > /dev/null
                    ;;

                qssi)
                    local build_p=${root_p}/${job_name}X/${build_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${build_p} > /dev/null

                    init

                    source_init
                    make_android

                    popd > /dev/null
                    ;;

                target|merge|modem|ap|cp|mtk|backup)
                    local build_p=${root_p}/${job_name}Y/${build_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${build_p} > /dev/null

                    init

                    if [[ ${object} == 'ap' ]]; then
                        sleep ${stime}
                    fi

                    source_init
                    make_android

                    popd > /dev/null
                    ;;

                *)
                    log warn '无法识别 ...'
                ;;
            esac
            :
        ;;

        *)
            log error '参数错误 ...'
        ;;
    esac

    trap - ERR
}

main "$@"
