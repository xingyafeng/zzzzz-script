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

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

function verify_patchset_submit() {

    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local is_build_success=${1-}

    if [[ ${is_build_success} -eq 0 ]]; then
        check_patchset_status
    fi

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
        case ${is_build_success} in
            0)
                verified+1
                ;;

            1)
                verified-1
                ;;
        esac
    done < ${tmpfs}/env.ini

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
}

function check_patchset_status()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local latest_patchset=
    local check_status=true

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do

        # 检查PATCH状态， closed|merged|abandoned|amend
        if [[ "$(check-gerrit 'closed' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
           ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been Abandoned or Merged now, so no need to build this time."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
           log warn "${GERRIT_CHANGE_URL} The patch status is closed now, no need to build this time."

           check_status=false
        fi

        if [[ "$(check-gerrit 'merged' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
           ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch had been merged now, so no need to build this time."'  ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
           log warn "${GERRIT_CHANGE_URL} The patch status is merged now, no need to build this time."

           check_status=false
        fi

        if [[ "$(check-gerrit 'abandoned' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
           ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch had been abandoned now, please check this patchset,thanks."'  ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
           log warn "${GERRIT_CHANGE_URL} The patch status is abandoned now, no need to build this time."

           check_status=false
        fi

        if [[ "$(check-gerrit 'amend' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
           ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console This patchset is not the latest, it was rebased or committed again, so no need to build this time."'  ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
           log warn "${GERRIT_CHANGE_URL} This patchset is not the latest,the current patchset num is ${GERRIT_PATCHSET_NUMBER} and the latest is ${latest_patchset}, it was rebased or committed again, so no need to build this time."

           check_status=false
        fi

        # 检查 verified+1|code-review<0
        if [[ "$(check-gerrit 'verified+1' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
           ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been verified +1 by auto compile or somebody, so no need to build this time."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
           log warn "${GERRIT_CHANGE_URL} The patch status has been verified+1 by auto compile, no need to build this time."

           check_status=false
        fi

        if [[ "$(check-gerrit 'code-review<0' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
           ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been code-reviewed -1 or -2 by somebody, please check this patchset."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
           log warn "${GERRIT_CHANGE_URL} The patch status has been code-reviewed -1 or -2 by somebody, and so no need to build this time."

           check_status=false
        fi

    done < ${tmpfs}/env.ini

    if [[ "${check_status}" == "false" ]];then
        while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
            ssh-gerrit review -m '"The patchset relation for check failed on the same pr number, please check this patchset for verified -1 or reviewed <0."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
        done < ${tmpfs}/env.ini

        log quit "check status failed, please check this patchset for verified -1 or reviewed <0  or closed|merged|abandoned|amend ..."
    fi

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

####################################################
#
#  解析PATCHSET, 系统变量对应关系表
#
#    url=${GERRIT_CHANGE_URL}
#    project=${GERRIT_PROJECT}
#    refspec=${GERRIT_REFSPEC}
#    patchset=${GERRIT_PATCHSET_NUMBER}
#    revision=${GERRIT_PATCHSET_REVISION}
#    changenumber=${GERRIT_CHANGE_NUMBER}
#
######################################################
function parse_all_patchset() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local branchs="development_dint@jrdapp-android-r-dint@qct-sm4250-tf-r-v1.0-dint@TCT-ROM-4.0-AOSP-GCS-OP@TCTROM-R-QCT-V4.1-dev_gcs@TCTROM-R-QTI-OP@TCTROM-R-V4.0-dev_gcs"

    if [[ -n "${GERRIT_TOPIC}" ]]; then

        # 查询所以的TOPIC信息，保存至changeid.json中
        ssh-gerrit query \
            --current-patch-set "intopic:^.*${GERRIT_TOPIC}.* status:open NOT label:code-review-1" \
            --format json > ${gerrit_p}/changeid.json

        if [[ "$?" -eq 0 ]]; then
            pushd ${gerrit_p} > /dev/null

            python ${script_p}/tools/parse_change_infos.py changeid.json "${branchs}"
            if [[ $? -ne 0 ]]; then
                log error "Parse the topic : ${GERRIT_TOPIC} info failed."
            fi

            popd > /dev/null
        else
            log error "Error occured when link ${GERRIT_HOST}."
        fi

        if [[ -s "${gerrit_p}/change_number_list.txt" ]]; then
            change_number_list=($(cat ${gerrit_p}/change_number_list.txt | sort -n))
        else
            show_vir "THe parse Topic: ${GERRIT_TOPIC} change number list null. And the patchset has been Abandoned or Merged."
            ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patchset has been Abandoned or Merged or already verified +1 by gerrit trigger auto compile, so no need to build this time."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}

            # 正常退出
            log quit "${GERRIT_CHANGE_URL} The patch status is Abandoned or Merged or already verified +1 by gerrit trrigger auto compile, no need to build this time."
        fi
    else
        change_number_list=${GERRIT_CHANGE_NUMBER}
    fi

    show_vig "[tct] change_number_list = " ${change_number_list[@]}

    :> ${tmpfs}/env.ini
    for item in ${change_number_list[@]} ; do
        if [[ -z "${GERRIT_TOPIC}" ]]; then
#            show_vip ${GERRIT_CHANGE_URL}@${GERRIT_PROJECT}@${GERRIT_REFSPEC}@${GERRIT_PATCHSET_NUMBER}@${GERRIT_PATCHSET_REVISION}@${GERRIT_CHANGE_NUMBER}@${GERRIT_BRANCH}
            echo ${GERRIT_CHANGE_URL}@${GERRIT_PROJECT}@${GERRIT_REFSPEC}@${GERRIT_PATCHSET_NUMBER}@${GERRIT_PATCHSET_REVISION}@${GERRIT_CHANGE_NUMBER}@${GERRIT_BRANCH} >> ${tmpfs}/env.ini
        else
            if [[ -f "${gerrit_p}/${item}" ]]; then
                source ${gerrit_p}/${item}
#                show_vip ${url}@${project}@${refspec}@${patchset}@${revision}@${changenumber}@${branch}
                echo ${url}@${project}@${refspec}@${patchset}@${revision}@${changenumber}@${branch} >> ${tmpfs}/env.ini
            else
                log error "The topic item ${item} information dropout."
            fi
        fi
    done

    #　重置变量
    unset url project refspec patchset revision changenumber branch

    # 输出环境参数
    pint_env_ini

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function pint_env_ini() {

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
        __blue__ 'GERRIT_CHANGE_URL         = ' ${GERRIT_CHANGE_URL}
        __blue__ 'GERRIT_PROJECT            = ' ${GERRIT_PROJECT}
        __blue__ 'GERRIT_REFSPEC            = ' ${GERRIT_REFSPEC}
        __blue__ 'GERRIT_PATCHSET_NUMBER    = ' ${GERRIT_PATCHSET_NUMBER}
        __blue__ 'GERRIT_PATCHSET_REVISION  = ' ${GERRIT_PATCHSET_REVISION}
        __blue__ 'GERRIT_CHANGE_NUMBER      = ' ${GERRIT_CHANGE_NUMBER}
        __blue__ 'GERRIT_BRANCH             = ' ${GERRIT_BRANCH}
        echo
    done < ${tmpfs}/env.ini
}

function download_all_patchset()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local project_path=

    checkout_standard_android_project
    Command "repo sync -c -d --no-tags -j$(nproc)"

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do

        project_path=$(get_project_path)
        show_vig "@@@ project path: " ${project_path}

        pushd ${project_path} > /dev/null

        # download patchset
        Command "git fetch ssh://${username}@${GERRIT_HOST}:29418/${GERRIT_PROJECT} ${GERRIT_REFSPEC} && git checkout FETCH_HEAD"
        if [[ $? -eq 0 ]] ; then
            show_vig "${project_path} download patchset refs/changes/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER} sucessful."
        else
            # git仓库恢复至干净状态
            recover_standard_git_project
            ssh-gerrit review -m '""'${BUILD_URL}'"\t"'${project_path}'"\t merge the patchset conflict refs/changes/"'${GERRIT_CHANGE_NUMBER}'"/"'${GERRIT_PATCHSET_NUMBER}'" failed,please resubmit code!!!"' --verified -1  ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}

            log error "Download patchset refs/changes/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER} failed."
        fi

        popd > /dev/null
    done < ${tmpfs}/env.ini

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function gerrit_build() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip  "INFO: Enter ${FUNCNAME[0]}()"

    local project_path=
    declare -a build_case

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do

        project_path=$(get_project_path)

        show_vig '@@@ project_path = ' ${project_path}
        case "${project_path}" in

            amss_4250_spf1.0)
                build_case[${#build_case[@]}]=build_moden
            ;;

            kernel/msm-4.19)
                build_case[${#build_case[@]}]=build_kernel
            ;;

            *)
                local tmpath
                # 查询提交文件
                listfs=(`git --git-dir=${project_path}/.git log --name-only --pretty=format: ${GERRIT_PATCHSET_REVISION} -1 | grep -v "^$" | sort -u`)
                for fs in ${listfs[@]} ; do
                    tmpath=$(getdir ${project_path}/${fs})
                    if [[ -n ${tmpath} ]]; then
                        case ${tmpath} in
                           amss_4250_spf1.0/TZ.APPS.2.0/qtee_tas) # 过滤错误选项
                                continue;
                            ;;

                            *)
                                build_path[${#build_path[@]}]=${tmpath}
                            ;;
                        esac
                    fi
                done

                # 判断当前的提交是否需要全编译
                if [[ ${#build_path[@]} -eq 0 ]]; then
                    unset build_path
                    break;
                else
                    for bp in ${build_path[@]} ; do
                        case ${bp} in
                            device/qcom/*|device/sample/*|device/google/*|device/linaro/*)
                                export TARGET_PRODUCT=qssi
                                unset build_path
                                break;
                            ;;

                            build/soong/*|build/make/*)
                                export TARGET_PRODUCT=qssi
                                unset build_path
                                break;
                            ;;
                        esac
                    done

                    __green__ '[tct]: The build path list count : ' ${#build_path[@]}
                    show_vig "The once, build path : " ${build_path[@]}
                    break;
                fi
            ;;
        esac
    done < ${tmpfs}/env.ini

    # 去重
    if [[ -n ${build_path[@]} ]]; then
        build_path=($(awk -vRS=' ' '!a[$1]++' <<< ${build_path[@]}))
    fi

    __green__ "[tct]: build path = ${build_path[@]}"

    # check qssi project
    if [[ -n "${build_path}" ]]; then
        for build in ${build_path[@]} ; do
            if [[ "$(is_qssi_product ${build})" == "true" ]]; then
                export TARGET_PRODUCT=qssi
                log warn "This module is qssi project."
                break;
            fi
        done
    fi

    __green__ "[tct]: build case = ${build_case[@]}"

    # build case
    if [[ -n "${build_case[@]}" ]]; then
        for bcase in ${build_case[@]} ; do

            case ${bcase} in
                'exclude')
                    Command ${bcase}
                    if [[ $? -eq 0 ]]; then
                        if [[ ${#change_number_list[@]} -eq 1 ]]; then
                            verify_patchset_submit 0
                        fi
                    else
                        if [[ ${#change_number_list[@]} -eq 1 ]]; then
                            verify_patchset_submit 1
                        fi
                    fi

                    return 0
                ;;

                *)
                    Command ${bcase}
                    if [[ $? -eq 0 ]]; then
                        if [[ ${#change_number_list[@]} -eq 1 ]]; then
                            verify_patchset_submit 0
                        fi
                    else
                        if [[ ${#change_number_list[@]} -eq 1 ]]; then
                            verify_patchset_submit 1
                        fi
                    fi
                ;;
            esac
        done
    fi

    # rom prebuild
    if [[ ${#build_path[@]} -ne 0 ]]; then
        for bp in ${build_path[@]} ; do
            if [[ -n ${module_target[${bp}]} ]]; then
                build_module_list[${#build_module_list[@]}]=${module_target[${bp}]}
            fi
        done

        if [[ ${#build_module_list[@]} -ne 0 ]];then
            show_vip "[tct]: mma -j${JOBS} ${build_module_list[@]}"
            if ${build_debug};then
                mma -j${JOBS} ${build_module_list[@]}
                if [[ ${PIPESTATUS[0]} -eq 0 ]] ; then
                    verify_patchset_submit 0
                else
                    verify_patchset_submit 1
                    log error "mma -j${JOBS} ${build_module_list[@]} failed ..."
                fi
            fi
        fi
    else
        export WITHOUT_CHECK_API=false

        show_vip '[tct]: --> make android start ...'
        if ${build_debug};then
            if [[ "${TARGET_PRODUCT}" == "qssi" ]]; then
                Command "bash build.sh --qssi_only -j${JOBS}"
            else
                Command "bash build.sh --target_only -j${JOBS}"
            fi

            if [[ $? -eq 0 ]] ; then
                verify_patchset_submit 0
            else
                verify_patchset_submit 1
            fi
        fi
    fi

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

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
    echo 'WORKSPACE      = ' ${WORKSPACE}
    echo 'GERRIT_BRANCH  = ' ${GERRIT_BRANCH}
    echo 'GERRIT_TOPIC   = ' ${GERRIT_TOPIC}
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