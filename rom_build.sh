#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# 1. manifest分支
build_manifest=
# 2. 更新代码
build_update_code=

# init function
. "$(dirname "$0")/tct/tct_init.sh"

declare -a app_info
declare -a prj_info

function get_cpu_core() {

    case ${JOBS} in

        8)
            JOBS=${JOBS}
            ;;

        *)
            JOBS=${JOBS}
            ;;
    esac
}

function set_manifest_xml() {

    if [[ -n ${build_manifest} ]]; then
        if [[ ${build_manifest} =~ '.xml' ]]; then
            build_manifest=${build_manifest}
        else
            build_manifest=${build_manifest}.xml
        fi
    fi
}

function source_init_project() {

    Command "source build/envsetup.sh"

    case ${project_name} in

        sm7250-r0-seattletmo-dint) # seattletmo R
            Command "choosecombo 1 seattletmo userdebug false false 1"
            ;;

        sm6125-r0-portotmo-dint) # portotmo R
            Command "choosecombo 1 portotmo userdebug portotmo 1 false false"
            ;;

        mt6762-tf-r0-v1.1-dint) # Tokyo Lite TMO R
            Command "choosecombo 1 full_Tokyo_Lite_TMO userdebug 2 1"
            ;;
    esac
}

function make_app() {

    source_init_project
    handle_tct_custom

    case ${GERRIT_PROJECT} in

        genericapp/gcs_Settings)
            Command "mma -j${JOBS} Settings"
            ;;

        genericapp/gcs_SystemUI)
            Command "mma -j${JOBS} SystemUI"
            ;;

        genericapp/gcs_Launcher3)
            Command "mma -j${JOBS} Launcher3QuickStep"
            ;;

        genericapp/JrdSetupWizard)
            Command "mma -j${JOBS} TctSetupWizard"
            ;;

        genericapp/gcs_HiddenMenu)
            Command "mma -j${JOBS} HiddenMenu"
            ;;

    esac
}

function handle_common() {

    # 拿到JOBS
    get_cpu_core

    # 配置manifest.xml
    set_manifest_xml

    # 配置WORKSPACE
    gettop_p=$(pwd)
}

function handle_variable() {

    # 1. manifest
    build_manifest=${tct_manifest:-}

    # 2. 更新代码
    build_update_code=${tct_update_code:-false}

    handle_common
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "project_name            = " ${project_name}
    echo "build_manifest          = " ${build_manifest}
    echo "build_update_code       = " ${build_update_code}
    echo '-----------------------------------------'

    if [[ "$(is_gerrit_trigger)" == "true" ]];then
        echo 'GERRIT_PROJECT          = ' ${GERRIT_PROJECT}
        echo 'GERRIT_BRANCH           = ' ${GERRIT_BRANCH}
        echo 'GERRIT_REFSPEC          = ' ${GERRIT_REFSPEC}
        echo 'GERRIT_CHANGE_NUMBER    = ' ${GERRIT_CHANGE_NUMBER}
        echo 'GERRIT_PATCHSET_NUMBER  = ' ${GERRIT_PATCHSET_NUMBER}
        echo 'GERRIT_HOST             = ' ${GERRIT_HOST}
        echo 'GERRIT_CHANGE_URL       = ' ${GERRIT_CHANGE_URL}
        echo '-----------------------------------------'
    fi

    echo
}

function init() {

    handle_variable
    print_variable
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    local root_p=~/jobs

    case $# in
        1)
            case ${1:-} in

                qssi)
                    local build_p=${root_p}/${job_name}X/${tct_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${root_p} > /dev/null

                    init

                    if [[ "${build_update_code}" == "true" ]];then
                        # 下载，更新源代码
                        download_android_source_code
                    else
                        log warn "This time you don't update the source code."
                    fi

                    popd > /dev/null
                    ;;

                target|merge|moden)
                    local build_p=${root_p}/${job_name}Y/${tct_manifest}

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

                *)
                    :
                ;;
            esac
            :
        ;;

        *)
            log error '识别错误...'
        ;;
    esac

    trap - ERR
}

main "$@"