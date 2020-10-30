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

function make_app() {

    Command "source build/envsetup.sh"

    case ${project_name} in

        sm7250-r0-seattletmo-dint)
            Command "choosecombo 1 seattletmo userdebug false false 1"
            ;;

        sm6125-r0-portotmo-dint)
            Command "choosecombo 1 portotmo userdebug portotmo 1 false false"
            ;;

        mt6762-tf-r0-v1.1-dint)
            Command "choosecombo 1 full_Tokyo_Lite_TMO userdebug 2 1"
            ;;
    esac

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
    esac
}

function verified+1() {

    ssh-gerrit review -m '"Build Log_URL:'${BUILD_URL}'"' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}

    if [[ "$(check_verified ${GERRIT_CHANGE_NUMBER})" == "false" ]]; then
        ssh-gerrit review -m '"this patchset gerrit trigger build successful; --verified +1"' --verified 1 ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
        if [[ $? -eq 0 ]];then
            echo "this patchset build successfully, --verified +1"
        else
            ssh-gerrit review -m '"jenkins --verified +1 failed ..."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
            log error "jenkins --verified +1 failed ..."
        fi
    fi

    if [[ "$(check_code-review ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
        set +e
        ssh-gerrit review -m '"this patchset gerrit trigger build successful; --submit"' --submit ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER} 2>&1 | tee ${tmpfs}/submit.log
        set -e
    else
        ssh-gerrit review -m '"can only verify now, need some people to review +2."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
        log warn "can only verify now, need some people to review +2"
    fi
}

function verified-1() {

    ssh-gerrit review -m '"Build Error_Log_URL:"'${BUILD_URL}'"/console"' --verified -1 ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
    if [[ $? -eq 0 ]];then
        echo "this patchset gerrit trigger build failed.\nError_Log_URL:${BUILD_URL}/console."
    else
        echo "verify_submit_patchset failed,please check."
    fi
}

function download_patchset() {

    local project_path=

    if [[ -n "$(get_project_path)" ]]; then
        project_path=$(get_project_path)
    else
        log error 'get project path is null ...'
    fi

    show_vig 'project path : ' ${project_path}

    # 恢复现场
    checkout_standard_android_project
    # 同步更新源代码
    Command "repo sync -c -d --no-tags -j$(nproc)"

    pushd ${project_path} > /dev/null
    Command "git fetch ssh://${username}@${GERRIT_HOST}:29418/${GERRIT_PROJECT} ${GERRIT_REFSPEC} && git checkout FETCH_HEAD"
    popd > /dev/null
}

function handle_common() {

    # 拿到JOBS
    get_cpu_core

    # 配置manifest.xml
    set_manifest_xml

    # 生成manifest列表
    generate_manifest_list
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
    echo 'GERRIT_PROJECT          = ' ${GERRIT_PROJECT}
    echo 'GERRIT_HOST             = ' ${GERRIT_HOST}
    echo 'GERRIT_REFSPEC          = ' ${GERRIT_REFSPEC}
    echo 'GERRIT_CHANGE_NUMBER    = ' ${GERRIT_CHANGE_NUMBER}
    echo 'GERRIT_PATCHSET_NUMBER  = ' ${GERRIT_PATCHSET_NUMBER}
    echo '-----------------------------------------'
}

function init() {

    handle_variable
    print_variable
}

function filter() {

    case ${project_name} in
        sm7250-r0-seattletmo-dint)
            case ${GERRIT_PROJECT} in
                genericapp/JrdSetupWizard)
                    echo false
                ;;

                *)
                    echo false
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
                    verified+1
                ;;

                verified-1)
                    verified-1
                    ;;

                *)
                    local root_p=~/jobs/apk_prebuild/${project_name}

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