#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# --------------------
project_name=$1

# 更新代码
build_update_code=

# init function
. "`dirname $0`/tct/tct_init.sh"

declare -a app_info
declare -a prj_info

# manifest分支
build_manifest=

# 配置app信息
function set_app_info() {

    app_info[${#app_info[@]}]=genericapp/gcs_Settings
    app_info[${#app_info[@]}]=genericapp/gcs_SystemUI
    app_info[${#app_info[@]}]=genericapp/gcs_Launcher3
    app_info[${#app_info[@]}]=genericapp/JrdSetupWizard
}

# 配置app信息
function set_project_info() {

    prj_info[${#prj_info[@]}]=sm7250-r0-seattletmo-dint
    prj_info[${#prj_info[@]}]=sm6125-r0-portotmo-dint
    prj_info[${#prj_info[@]}]=mt6762-tf-r0-v1.1-dint
}

function get_cpu_core() {

    case ${JOBS} in

        8)
            JOBS=${JOBS}
            ;;

        *)
            JOBS=$((JOBS/3))
            ;;
    esac
}

function set_manifest_xml() {

    if [[ -n ${project_name} ]]; then
        if [[ ${project_name} =~ '.xml' ]]; then
            build_manifest=${project_name}
        else
            build_manifest=${project_name}.xml
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

function is_clean_project() {

    case ${JOB_NAME} in

        SystemUI)
            echo false
            ;;

        *)
            echo false
            ;;
    esac
}

function is_apk_prebuild() {

    case ${JOB_NAME} in

        JrdSetupWizard|Launcher3|Settings|SystemUI|ApkPrebuild|HiddenMenu)
            echo true
            ;;

        *)
            echo false
        ;;
    esac
}

function download_patchset() {

    local project_path=

    # 生成manifest列表
    generate_manifest_list

    if [[ -n "$(get_project_path)" ]]; then
        project_path=$(get_project_path)
    else
        log error 'get project path is null ...'
    fi

    show_vig 'project path : ' ${project_path}

    if [[ "$(is_clean_project)" == 'false' ]]; then
        # 恢复现场
        recover_standard_git_project ${project_path}
        # 同步更新源代码
        Command "repo sync ${project_path} -c -d --no-tags -j$(nproc)"
    else
        # 恢复现场
        checkout_standard_android_project
        # 同步更新源代码
        Command "repo sync -c -d --no-tags -j$(nproc)"
    fi

    pushd ${project_path} > /dev/null
    Command "git fetch ssh://${username}@${GERRIT_HOST}:29418/${GERRIT_PROJECT} ${GERRIT_REFSPEC} && git checkout FETCH_HEAD"
    popd > /dev/null
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

    # 1. 更新代码
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
        echo 'GERRIT_HOST             = ' ${GERRIT_HOST}
        echo 'GERRIT_REFSPEC          = ' ${GERRIT_REFSPEC}
        echo 'GERRIT_CHANGE_NUMBER    = ' ${GERRIT_CHANGE_NUMBER}
        echo 'GERRIT_PATCHSET_NUMBER  = ' ${GERRIT_PATCHSET_NUMBER}
        echo '-----------------------------------------'
    fi

    echo
}

function init() {

    handle_variable
    print_variable
}

function filter() {

    case ${project_name} in
        sm7250-r0-seattletmo-dint) # seattletmo R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common_mtk)
                            echo true
                        ;;
                    esac
                ;;

                *)
                    echo false
                    ;;
            esac
            ;;

        sm6125-r0-portotmo-dint) # portotmo R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common_mtk)
                            echo true
                        ;;
                    esac
                ;;
            esac
            ;;

        mt6762-tf-r0-v1.1-dint) # Tokyo Lite TMO R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common)
                            echo true
                        ;;
                    esac
                    ;;
            esac
            ;;

        *)
            echo false
            ;;
    esac
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    case $# in
        1)
            case $1 in
                verified+1)
                    if [[ "${tct_update_code}" == "false" ]];then
                        verified+1
                    fi
                ;;

                verified-1)
                    if [[ "${tct_update_code}" == "false" ]];then
                        verified-1
                    fi
                    ;;

                *)
                    local root_p=~/jobs/apk_prebuild/${project_name}

                    if [[ ! -d ${root_p} ]]; then
                        mkdir -p ${root_p}
                    fi

                    pushd ${root_p} > /dev/null

                    if [[ $(filter) == "true" ]]; then
                        return 0
                    fi

                    init

                    if [[ "$(is_gerrit_trigger)" == "true" ]];then
                        download_patchset
                        make_app
                    else
                        if [[ "${build_update_code}" == "true" ]];then
                            # 下载，更新源代码
                            download_android_source_code
                        else
                            log warn "This time you don't update the source code."
                        fi

                        log warn "Manual trigger ..."
                    fi

                    popd > /dev/null
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