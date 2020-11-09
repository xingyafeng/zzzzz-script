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

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

function android_mk_path() {

    local find_androidmk_path_list=""

    pushd ${project_path} > /dev/null

    m=(`git log --name-only --pretty=format: ${revision} -1 | grep -v "^$" | sort -u`)
    for i in ${m[@]} ; do
        x=${i%/*}
        if [[ -f ${x}/Android.mk || -f ${x}/Android.bp ]];then
            if [[ -z "$find_androidmk_path_list" ]];then
                find_androidmk_path_list="$project_path/$x"
            else
                find_androidmk_path_list="$find_androidmk_path_list $project_path/$x"
            fi
            continue
        fi

        if [[ -f ${i} ]] ; then
            y=${project_path}/${i}
            z=${y%/*}

            if [[ n"$project_path" = n"${z}" ]] ; then
                if [[ -z "$find_androidmk_path_list" ]];then
                    find_androidmk_path_list="$project_path"
                else
                    find_androidmk_path_list="$find_androidmk_path_list $project_path"
                fi
                continue
            else
                x=${i%/*}
                j=${i%%/*}

                while [[ z"$x" != z"$j" ]]
                do
                    if [[ -f ${x}/Android.mk || -f ${x}/Android.bp ]] ; then
                        if [[ -z "$find_androidmk_path_list" ]];then
                            find_androidmk_path_list="$project_path/$x"
                        else
                            find_androidmk_path_list="$find_androidmk_path_list $project_path/$x"
                        fi
                        break
                    else
                        x=${x%/*}
                    fi
                done

                if [[ -f ${x}/Android.mk || -f ${x}/Android.bp ]] ; then
                     if [[ -z "$find_androidmk_path_list" ]];then
                        find_androidmk_path_list="$project_path/$x"
                     else
                        find_androidmk_path_list="$find_androidmk_path_list $project_path/$x"
                     fi
                     continue
                fi

                if [[ -f Android.mk || -f Android.bp ]] ; then
                     if [[ -z "$find_androidmk_path_list" ]];then
                        find_androidmk_path_list="$project_path"
                     else
                        find_androidmk_path_list="$find_androidmk_path_list $project_path"
                     fi
                     continue
                fi
            fi
        fi
    done

    build_path=(`echo ${find_androidmk_path_list} | tr ' ' '\n' |  sort -u | uniq | xargs echo`)
    __green__ "android mk path : ${build_path}"

    popd > /dev/null

    #check qssi project
    for build in ${build_path[@]} ; do
        if [[ "$(is_qssi_product ${build})" == "true" ]]; then
            export TARGET_PRODUCT=qssi

            log warn "This module is qssi project."
        fi
    done
}

function verify_patchset_submit() {

    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    check_patchset_status

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER _;do
        echo ${GERRIT_CHANGE_URL}:${GERRIT_PROJECT}:${GERRIT_REFSPEC}:${GERRIT_PATCHSET_NUMBER}:${GERRIT_PATCHSET_REVISION}:{GERRIT_CHANGE_NUMBER} >> ${tmpfs}/env.ini

        case ${is_build_success} in
            0)
                verified-1
                ;;

            1)
                verified+1
                ;;
        esac
    done < ${tmpfs}/env.ini

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
}

function check_patchset_status()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local check_status=true
    local latest_patchset=

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER _;do

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
        while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER _;do
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

    __green__ "[tct] change_number_list = " ${change_number_list[@]}

    :> ${tmpfs}/env.ini
    for item in ${change_number_list[@]} ; do
        if [[ -z "${GERRIT_TOPIC}" ]]; then
            echo ${GERRIT_CHANGE_URL}@${GERRIT_PROJECT}@${GERRIT_REFSPEC}@${GERRIT_PATCHSET_NUMBER}@${GERRIT_PATCHSET_REVISION}@{GERRIT_CHANGE_NUMBER} >> ${tmpfs}/env.ini
        else
            if [[ -f "${gerrit_p}/${item}" ]]; then
                source ${gerrit_p}/${item}
                echo ${url}@${project}@${refspec}@${patchset}@${revision}@${changenumber}
                echo ${url}@${project}@${refspec}@${patchset}@${revision}@${changenumber} >> ${tmpfs}/env.ini
            else
                log error "The topic item ${item} information dropout."
            fi
        fi
    done

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function pint_env_ini() {

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER _;do
        echo ${GERRIT_CHANGE_URL} "==" ${GERRIT_PROJECT} "==" ${GERRIT_REFSPEC} "==" ${GERRIT_PATCHSET_NUMBER} "==" ${GERRIT_PATCHSET_REVISION} "==" ${GERRIT_CHANGE_NUMBER}
    done < ${tmpfs}/env.ini
}

function download_all_patchset()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local project_path=

    checkout_standard_android_project
    Command "repo sync -c -d --no-tags -j$(nproc)"

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER _;do

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

    local is_build_success=0
    local build_path_list=""
    local build_module_list=""
    local build_project_array=()

    local project_path=

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER _;do
        project=${GERRIT_PROJECT}
        project_path=$(get_project_path)
        changenum=${GERRIT_CHANGE_NUMBER}
        patchset=${GERRIT_PATCHSET_NUMBER}
        revision=${GERRIT_PATCHSET_REVISION}

        echo "project: $project"
        show_vig '@@@ project_path = ' ${project_path}

        case "${project_path}" in

            amss_4250_spf1.0)
                is_build_mma=true
                if [[ ${#build_project_array[@]} -eq 0 ]];then
                     build_project_array=("\"unset@WORKSPACE@&&@cd@amss_4250_spf1.0@&&@./linux_build.sh@-a@delhitf@tf\"")
                else
                     build_project_array=(${build_project_array[*]} "\"cd@amss_4250_spf1.0@&&@./linux_build.sh@-a@delhitf@tf\"")
                fi
            ;;

            kernel/msm-4.19)
                is_build_mma=true
                if [[ ${#build_project_array[@]} -eq 0 ]];then
                     build_project_array=("\"make@-j${JOBS}@kernel\"")
                else
                     build_project_array=(${build_project_array[*]} "\"make@-j${JOBS}@kernel\"")
                fi
            ;;

            bootable/bootloader/edk2)
                is_build_mma=true
                if [[ ${#build_project_array[@]} -eq 0 ]];then
                     build_project_array=("\"m@-j${JOBS}@out/target/product/${build_project}/abl.elf\"")
                else
                     build_project_array=(${build_project_array[*]} "\"m@-j${JOBS}@out/target/product/${build_project}/abl.elf\"")
                fi
            ;;

            vendor/mediatek/proprietary/bootable/bootloader/lk)
                is_build_mma=true
                if [[ ${#build_project_array[@]} -eq 0 ]];then
                     build_project_array=("\"m@-j${JOBS}@out/target/product/${build_project}/lk.img\"")
                else
                     build_project_array=(${build_project_array[*]} "\"m@-j${JOBS}@out/target/product/${build_project}/lk.img\"")
                fi
            ;;

            cust_wimdata_ng/liv)
                is_build_mma=true
            ;;

            cust_wimdata_ng/wprocedures)
                is_build_mma=true
                if [[ ${#build_project_array[@]} -eq 0 ]];then
                     build_project_array=("\"${changenum}:${patchset}:${project_path}:check_PLFfile\"")
                else
                     build_project_array=(${build_project_array[*]} "\"${changenum}:${patchset}:${project_path}:check_PLFfile\"")
                fi
            ;;

            cust_wimdata_ng/wlanguage)
                is_build_mma=true
            ;;

            cust_wimdata_ng/wcustores)
                is_build_mma=true
                if [[ ${#build_project_array[@]} -eq 0 ]];then
                     build_project_array=("\"${changenum}:${patchset}:${project_path}:check_apkdebugable\"")
                else
                     build_project_array=(${build_project_array[*]} "\"${changenum}:${patchset}:${project_path}:check_apkdebugable\"")
                fi
            ;;

            *)
                list=(`cat build/make/tools/buildlist | awk -F: '{print $1}' | sort -u`)
                android_mk_path

                if [[ ${#build_path[@]} -eq 0 ]]; then
                   is_build_mma=false
                   break
                else
                    show_vig 'build path list :' ${build_path[@]}
                    for i in ${build_path[@]} ; do
                        if [[ ${i} =~ "lk" ]]; then
                            is_build_mma=true
                            if [[ ${#build_project_array[@]} -eq 0 ]];then
                                build_project_array=("\"m@-j${JOBS}@out/target/product/${build_project}/lk.img\"")
                            else
                                build_project_array=(${build_project_array[*]} "\"m@-j${JOBS}@out/target/product/${build_project}/lk.img\"")
                            fi
                        elif [[ ${i} =~ "preloader" ]]; then
                            is_build_mma=true
                            if [[ ${#build_project_array[@]} -eq 0 ]];then
                                build_project_array=("\"m@-j${JOBS}@out/target/product/${build_project}/preloader_${build_project}.bin\"")
                            else
                                build_project_array=(${build_project_array[*]} "\"m@-j${JOBS}@out/target/product/${build_project}/preloader_${build_project}.bin\"")
                            fi
                        else
                            is_mk_found=false
                            for j in ${list[@]} ; do
                                #dir=${j%/*}
                                if [[ x"$j" == x"$i" ]];then
                                    is_mk_found=true
                                    if [[ -z "$build_path_list" ]];then
                                       build_path_list="$j"
                                    else
                                       build_path_list="$build_path_list $j"
                                       build_path_list=`echo ${build_path_list} | tr ' ' '\n' |  sort -u | uniq | xargs echo`
                                    fi
                                    break
                                fi
                            done

                            if [[ x"$is_mk_found" != x"true" ]];then
                                is_build_mma=false
                                break
                            else
                                is_build_mma=true
                            fi
                        fi
                    done
                fi
                ;;
        esac

        if [[ x"$is_build_mma" != x"true" ]];then
            break
        fi
    done < ${tmpfs}/env.ini

    if [[ x"$is_build_mma" == "xtrue" ]];then
        if [[ x"$build_path_list" != x ]];then
            for prjitem in ${build_path_list}; do
                build_module_name=$(cat build/make/tools/buildlist | grep "^$prjitem:" | awk -F: '{print $2}' | tr ',' ' ')
                if [[ -z "$build_module_name" ]];then
                    build_path_list=""
                    build_module_list=""
                    is_build_mma=false
                    break
                fi

                if [[ -z "$build_module_list" ]];then
                    build_module_list=${build_module_name}
                else
                    build_module_list="$build_module_list $build_module_name"
                fi
            done
        fi
    else 
        build_path_list=""  
        build_module_list=""
        build_project_array=()
    fi

    if [[ x"true" == x"$is_build_mma" ]];then
        if [[ ${#build_project_array[@]} -ne 0 ]];then
            for prjitem in "${build_project_array[@]}" ; do
                if echo "${prjitem}" | grep -E ':' &>/dev/null; then
                    changenum=`echo "${prjitem}" | tr -d '"' | awk -F: '{print $1}'`
                    patchset=`echo "${prjitem}" | tr -d '"' |  awk -F: '{print $2}'`
                    project_path=`echo "${prjitem}" | tr -d '"' | awk -F: '{print $3}'`
                    prjitem="$(echo "${prjitem}" | tr -d '"' | awk -F: '{print $4}') ${changenum} ${patchset} ${project_path}"
                else
                    prjitem=$(echo "${prjitem}" | tr -d '"' | tr "@" ' ')
                fi

                set +e
                echo '[tct]: build other'
                echo '@@@  prjitem = ' ${prjitem}
                eval ${prjitem}

                if [[ "$?" -ne "0" ]] ; then
                    is_build_success=0 || false
                    break
                else
                    is_build_success=1 || true
                fi
                set -e
            done

            if [[ x"$is_build_success" == x"0" ]];then
                verify_patchset_submit
                exit 1
            fi
        fi

        if [[ -n "$build_module_list" ]];then
            show_vip "mma -j${JOBS} ${build_module_list}"
            mma -j${JOBS} ${build_module_list} 2>&1 | tee $(date +"%Y%m%d_%H%M%S")_mma.log
            if [[ ${PIPESTATUS[0]} -eq 0 ]] ; then
                is_build_success=1
            else
                log error "mma -j${JOBS} ${build_module_list} failed ..."
            fi
        fi

        if [[ x"$is_build_success" == x"1" ]];then
            verify_patchset_submit
        fi
    else
        export WITHOUT_CHECK_API=false

        echo '[tct]: build target or qssi ...'
        if [[ "${TARGET_PRODUCT}" == "qssi" ]]; then
            Command "bash build.sh --qssi_only -j${JOBS}"
        else
            Command "bash build.sh --target_only -j${JOBS}"
        fi

        if [[ $? -ne 0 ]] ; then
            is_build_success=0
            verify_patchset_submit
            exit 1
        else
            is_build_success=1
            verify_patchset_submit
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
        pint_env_ini
        check_patchset_status
        download_all_patchset

        if ${build_debug} ; then
            gerrit_build
        fi
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