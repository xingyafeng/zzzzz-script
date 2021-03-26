#!/usr/bin/env bash

# 生成manifest中name对于的path列表
function generate_manifest_list() {

    local manifest_list_p=${tmpfs}/manifest_list_for_${VerManifest}.txt

    if [[ -f .repo/manifest.xml ]]; then
        xmlstarlet sel -T -t -m /manifest/project -v "concat(@name,':',@path,'')" -n .repo/manifest.xml > ${manifest_list_p}
    else
        log error ".repo/manifest.xml has no found ..."
    fi

    while IFS=":" read -r _name _path _;do
        if [[ -z ${_path} ]]; then
            _path=${_name}
        fi

        manifest_info[${_name}]=${_path}
    done < ${manifest_list_p}
}


# 更新目标列表
function update_module_target() {

    local target_product=TARGET_PRODUCT

    export TARGET_PRODUCT=qssi
    make -j$(nproc) out/target/product/qssi/module-info.json
    export TARGET_PRODUCT=${target_product}
}

# 生成目标列表
function generate_module_target() {

    generate_buildlist_file

    if [[ -f ${buildlist} ]]; then
        while IFS=":" read -r _path _target _;do
            if [[ -n ${_target} ]]; then
                module_target[${_path}]=${_target}
            fi
        done < ${buildlist}
    else
        log warn "The ${buildlist} has no found!"
    fi
}

# 拿到项目路径
function get_project_path() {

    if [[ -n ${GERRIT_PROJECT} ]] ; then
        echo ${manifest_info[${GERRIT_PROJECT}]}
    else
        log error "get project path failed ..."
    fi
}

# 拿到目标模块名
function get_project_module() {

    if [[ -n ${GERRIT_PROJECT} ]] ; then
        echo ${moudule_list[${GERRIT_PROJECT}]}
    else
        log error "Get project path failed ..."
    fi
}

function modify_buildlist() {

    # 1. frameworks/base 只单编译 framework
    sed -i "s#^frameworks/base:.*#frameworks/base:framework#" ${buildlist}

    # 2. packages/apps/Launcher3 单独编译 Launcher3QuickStep
    sed -i "s#^packages/apps/Launcher3:.*#packages/apps/Launcher3:Launcher3QuickStep#" ${buildlist}
}

# 生成result_installed.txt
function generate_buildlist_file() {

    local path_py=${script_p}/tools/pathJson.py

    if [[ -f ${path_py} && -f out/target/product/qssi/module-info.json ]]; then
        python ${path_py} out/target/product/qssi/module-info.json ${buildlist}
    else
        log warn "${path_py} or out/target/product/qssi/module-info.json has no found!"
    fi

    if [[ -f ${buildlist} ]]; then
        modify_buildlist
    fi
}

function verified+1() {

    if [[ "$(check-gerrit 'verified+1' ${GERRIT_CHANGE_NUMBER})" == "false" ]]; then
        ssh-gerrit review -m '"This patchset gerrit trigger build successful ..."' --verified 1 ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
        if [[ $? -eq 0 ]];then
            show_vip "This patchset build successfully, --verified +1"

            if [[ "$(check-gerrit 'code-review+2' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
                ssh-gerrit review -m '"This patchset gerrit trigger build successful; --submit"' --submit ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER} 2>&1 | tee ${tmpfs}/submit.log
                if [[ $? -eq 0 ]]; then
                    show_vip "This patchset build successfully, --submit"
                fi
            else
                ssh-gerrit review -m '"Unable to submit, can only Verified+1 now, need some people to Code-Revire+2 ..."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
                show_vir "Unable to submit, can only Verified+1 now, need some people to Code-Revire+2 ..."
            fi
        else
            ssh-gerrit review -m '"jenkins --verified +1 failed ..."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
            log error "Jenkins --verified +1 failed ..."
        fi
    else
        show_vir "Unable to Verified+1, because of it hava been Verified+1 ..."
    fi
}

function verified-1() {

    ssh-gerrit review -m '"Build Error_Log_URL:"'${BUILD_URL}'"/console; --verified -1"' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
    if [[ $? -eq 0 ]];then
        show_vip "This patchset gerrit trigger build failed.\nError_Log_URL:${BUILD_URL}/console."
    else
        log error "Exec verified -1 failed, please check it."
    fi
}

function restore_git_repository() {

    if [[ -s ${tmpfs}/${job_name}.env.ini ]]; then
        while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
            log debug "The project path is :  $(get_project_path)"
            recover_standard_git_project $(get_project_path)
        done < ${tmpfs}/${job_name}.env.ini

        if [[ $? -eq 0 ]]; then
            log print "--> 已恢上次下载的仓库至最新状态."
        else
            log error "--> 已恢上次下载的仓库失败."
        fi
    fi
}

function print_env_ini() {

    log print 'print env ini ...'
    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
        __blue__ 'GERRIT_CHANGE_URL         = ' ${GERRIT_CHANGE_URL}
        __blue__ 'GERRIT_PROJECT            = ' ${GERRIT_PROJECT}
        __blue__ 'GERRIT_REFSPEC            = ' ${GERRIT_REFSPEC}
        __blue__ 'GERRIT_PATCHSET_NUMBER    = ' ${GERRIT_PATCHSET_NUMBER}
        __blue__ 'GERRIT_PATCHSET_REVISION  = ' ${GERRIT_PATCHSET_REVISION}
        __blue__ 'GERRIT_CHANGE_NUMBER      = ' ${GERRIT_CHANGE_NUMBER}
        __blue__ 'GERRIT_BRANCH             = ' ${GERRIT_BRANCH}
        echo
    done < ${tmpfs}/${job_name}.env.ini
}

# 拿到预编译的全部分支
function get_project_branch() {

    local tmpbranchs=
    local tmpbranch=($(xmlstarlet sel -T -t -m '//*' -v "concat(@revision,'')" -n .repo/manifest.xml | sort | uniq))

    for branch in ${tmpbranch[@]} ; do

        if [[ ${branch} == 'master' ]]; then
            continue
        fi

        if [[ -n ${branch} ]]; then
            tmpbranchs=${tmpbranchs}${branch}@
        fi
    done

    echo ${tmpbranchs/%@/}
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

    local branchs=$(get_project_branch)

    log debug "branchs = ${branchs}"

    :> ${tmpfs}/${job_name}.noenv.ini
    if [[ -z ${GERRIT_TOPIC} ]]; then
        echo ${GERRIT_CHANGE_URL}@${GERRIT_PROJECT}@${GERRIT_REFSPEC}@${GERRIT_PATCHSET_NUMBER}@${GERRIT_PATCHSET_REVISION}@${GERRIT_CHANGE_NUMBER}@${GERRIT_BRANCH} >> ${tmpfs}/${job_name}.noenv.ini
    fi

    # 恢复上次构建下载的PATCH
    restore_git_repository

    show_vir 'GERRIT_TOPIC = ' ${GERRIT_TOPIC}
    if [[ -n "${GERRIT_TOPIC}" ]]; then

        # 查询所以的TOPIC信息，保存至changeid.json中
        ssh-gerrit query \
            --current-patch-set "intopic:^.*${GERRIT_TOPIC}.* status:open NOT label:code-review-1" \
            --format json > ${gerrit_p}/changeid.json

        if [[ "$?" -eq 0 ]]; then
            pushd ${gerrit_p} > /dev/null

            python ${script_p}/tools/parse_change_infos.py changeid.json "${branchs[@]}"
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
            show_vir "The parse Topic: ${GERRIT_TOPIC} change number list null. And the patchset has been Abandoned or Merged."

            if [[ -n ${GERRIT_PATCHSET_NUMBER} && -n ${GERRIT_CHANGE_NUMBER} ]]; then
                ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patchset has been Abandoned or Merged or already verified +1 by gerrit trigger auto compile, so no need to build this time."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
            fi

            # 正常退出
            log quit "${GERRIT_CHANGE_URL} The patch status is Abandoned or Merged or already verified +1 by gerrit trrigger auto compile, no need to build this time."
        fi
    else
        while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
            change_number_list=(${GERRIT_CHANGE_NUMBER})
        done < ${tmpfs}/${job_name}.noenv.ini
    fi

    show_vig "[tct] change_number_list = " ${change_number_list[@]}

    :> ${tmpfs}/${job_name}.env.ini
    for item in ${change_number_list[@]} ; do
        if [[ -z "${GERRIT_TOPIC}" ]]; then
            while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
                echo ${GERRIT_CHANGE_URL}@${GERRIT_PROJECT}@${GERRIT_REFSPEC}@${GERRIT_PATCHSET_NUMBER}@${GERRIT_PATCHSET_REVISION}@${GERRIT_CHANGE_NUMBER}@${GERRIT_BRANCH} >> ${tmpfs}/${job_name}.env.ini
            done < ${tmpfs}/${job_name}.noenv.ini
        else
            if [[ -f "${gerrit_p}/${item}" ]]; then
                source ${gerrit_p}/${item}
                echo ${url}@${project}@${refspec}@${patchset}@${revision}@${changenumber}@${branch} >> ${tmpfs}/${job_name}.env.ini
            else
                log error "The topic item ${item} information dropout."
            fi
        fi
    done

    #　重置变量
    unset url project refspec patchset revision changenumber branch

    # 输出环境参数
    print_env_ini

#    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function check_patchset_status()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
#    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local latest_patchset=
    local check_status=true

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do

        # 检查PATCH状态， closed|merged|abandoned|amend
        if [[ "$(check-gerrit 'closed' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
            log warn "${GERRIT_CHANGE_URL} The patch status is closed now, no need to build this time."

            check_status=false
        fi

        if [[ "$(check-gerrit 'merged' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
            log warn "${GERRIT_CHANGE_URL} The patch status is merged now, no need to build this time."

            check_status=false
        fi

        if [[ "$(check-gerrit 'abandoned' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
            log warn "${GERRIT_CHANGE_URL} The patch status is abandoned now, no need to build this time."

            check_status=false
        fi

        if [[ "$(check-gerrit 'amend' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
            latest_patchset=$(ssh-gerrit query --current-patch-set "status:open project:${GERRIT_PROJECT} branch:${GERRIT_BRANCH} change:${GERRIT_CHANGE_NUMBER}" | grep "    number:" | awk -F: '{print $NF}')
            log warn "${GERRIT_CHANGE_URL} This patchset is not the latest,the current patchset num is ${GERRIT_PATCHSET_NUMBER} and the latest is ${latest_patchset}, it was rebased or committed again, so no need to build this time."

            check_status=false
        fi

        # 检查 verified-1|code-review<0
        if [[ "$(check-gerrit 'verified-1' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
            log warn "${GERRIT_CHANGE_URL} The patch status has been verified-1 by auto compile, no need to build this time."

            check_status=false
        fi

        if [[ "$(check-gerrit 'code-review<0' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
            log warn "${GERRIT_CHANGE_URL} The patch status has been code-reviewed -1 or -2 by somebody, and so no need to build this time."

            check_status=false
        fi
    done < ${tmpfs}/${job_name}.env.ini

    if [[ "${check_status}" == "false" ]];then
        while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
            ssh-gerrit review -m '"The patchset relation for check failed on the same pr number, please check this patchset for verified -1 or reviewed <0."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
        done < ${tmpfs}/${job_name}.env.ini

        log quit "check status failed, please check this patchset for verified -1 or reviewed <0  or closed|merged|abandoned|amend ..."
    fi

#    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function download_all_patchset()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
#    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local project_path=

    log print "--> download patchset start ..."

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do

        project_path=$(get_project_path)

        if [[ -d ${project_path} ]]; then
            __green__ "@@@ project path: " ${project_path}
        else
            log error "${project_path}::The project path is not exist in the manifest."
        fi

        pushd ${project_path} > /dev/null

        # 恢复当前干净状态
        recover_standard_git_project

        # download patchset
        Command "git fetch ssh://${username}@${GERRIT_HOST}:29418/${GERRIT_PROJECT} ${GERRIT_REFSPEC} && git checkout FETCH_HEAD"
        if [[ $? -eq 0 ]] ; then
            log print "--> download patchset sucessful ..."
        else
            # git仓库恢复至干净状态
            recover_standard_git_project
            ssh-gerrit review -m '""'${BUILD_URL}'"\t"'${project_path}'"\t merge the patchset conflict refs/changes/"'${GERRIT_CHANGE_NUMBER}'"/"'${GERRIT_PATCHSET_NUMBER}'" failed,please resubmit code!!!"' --verified -1  ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}

            log error "Download patchset refs/changes/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER} failed."
        fi

        popd > /dev/null
    done < ${tmpfs}/${job_name}.env.ini

#    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function verify_patchset_submit() {

#    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local is_build_success=${1-}

    if [[ "$(is_gerrit_trigger)" == 'false' ]];then
        return 0
    fi

    if [[ ${is_build_success} -eq 0 ]]; then
        statistical_compilation_project
        check_patchset_status
    fi

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
        if [[ "${gerrit_patchset_revision}" == "${GERRIT_PATCHSET_REVISION}" ]]; then
            case ${is_build_success} in
                0)
                    verified+1
                    ;;

                1)
                    verified-1
                    ;;
            esac
        else
            log debug "--> ${gerrit_patchset_revision} == ${GERRIT_PATCHSET_REVISION} ???"
        fi
    done < ${tmpfs}/${job_name}.env.ini

#    show_vip "INFO: Exit ${FUNCNAME[0]}()"
}

function gerrit_build() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
#    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local project_path=
    local moden_path=
    local count=0
    local index=$(cat ${tmpfs}/${job_name}.env.ini | wc -l)
    local is_full_build=false # 默认不是增加构建
    declare -a build_case

    log print "--> gerrit build start ..."
    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do

        let count+=1
        project_path=$(get_project_path)

        if [[ -n ${project_path} ]]; then
            show_vig "@@@ <${count}> : project_path = " ${project_path}
        else
            log error 'Get project path failed ...'
        fi

        case "${project_path}" in

            amss_4250_spf1.0|amss_4350_spf1.0)
                moden_path=${project_path}
                build_case[${#build_case[@]}]=build_moden
            ;;

            kernel/msm-4.19|kernel/msm-5.4)
                build_case[${#build_case[@]}]=build_kernel
            ;;

            *)
                local tmpath

                # 记录编译的工程
                project_paths[${#project_paths[@]}]=${project_path}

                # 查询提交文件
                listfs=(`git --git-dir=${project_path}/.git log --name-only --pretty=format: ${GERRIT_PATCHSET_REVISION} -1 | grep -v "^$" | sort -u`)
                if [[ ${#listfs[@]} -gt 120 ]]; then
                    is_full_build=true
                    break;
                fi

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
                    is_full_build=true
                    log print '[1] 本次构建设置为增量构建...'

                    if [[ ${index} -eq 1 ]]; then
                        break;
                    fi
                else
                    if [[ $(is_full_build_project) == "true" ]]; then
                        is_full_build=true
                    fi

                    show_vig '[build]: The build path list count : ' ${#build_path[@]} '; build path : ' $(awk -vRS=' ' '!a[$1]++' <<< ${build_path[@]})

                    if [[ ${is_full_build} == "true" ]]; then
                        export TARGET_PRODUCT=qssi

                        log print '[2] 本次构建设置为增量构建...'

                        if [[ ${index} -eq 1 ]]; then
                            break;
                        fi
                    else
                        log print '[0] 本次构建设置为单编构建...'
                    fi
                fi
            ;;
        esac
    done < ${tmpfs}/${job_name}.env.ini

    # 1. 去重
    if [[ -n ${build_path[@]} ]]; then
        build_path=($(awk -vRS=' ' '!a[$1]++' <<< ${build_path[@]}))
        show_vir "[tct]: build path = ${build_path[@]}"
    fi

    # 2. 检查是否需要整编
    if [[ ${is_full_build} == "true" ]]; then
        unset build_path
    fi

    # ----------------------------------------------------------------- 编译规则

    ### 初始化环境变量
    source_init

    # check qssi project
    if [[ -n "${build_path}" ]]; then
        for build in ${build_path[@]} ; do
            if [[ "$(is_qssi_product ${build})" == "true" ]]; then
                export TARGET_PRODUCT=qssi
                log debug "This module is qssi project."
                break;
            fi
        done
    fi

    # 一、特殊处理 build case, e.g. 1、moden 2、kernel etc
    make_android_for_case

    # 二、正常构建 1. mma/mmma 单编译　2. 增量编译,其实整编译
    if [[ ${#build_path[@]} -ne 0 ]]; then
        __pruple__ '[tct]: --> mma modules start ...'

        make_android_for_single
    else
        if [[ ${is_full_build} == "true" ]]; then
            __pruple__ '[tct]: --> make android start ...'

            make_android_for_whole
        fi
    fi

#    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

# -------------------------------------------------------------------------------------------------- 待重构代码

check_sdmid_duplicate()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"
    grep "<SDMID>.*</SDMID>" $1 | sed "s/.*<SDMID>\(.*\)<\/SDMID>.*/\1/g" >> sdmid_name.txt
    tmp=`awk 'a[$1]++' sdmid_name.txt`
    if [[ -n "$tmp" ]]; then
            echo -e "${PRTRED} Error: duplicate SDMID definition in `echo $1 |awk -F 'wprocedures' '{print $2}'`! ${PRTOVER}"
            for item in ${tmp};do
                    IS_plf_error='true'
                    echo -e "${PRTGREEN}`grep -irn --exclude-dir=.git "<SDMID> *$item *<\/SDMID>" $1`${PRTOVER}"
    done
    rm sdmid_name.txt
    else
    rm sdmid_name.txt
    fi
    if [[ x"$IS_plf_error" != x"true" ]];then
            echo -e "${PRTGREEN} the define of SDM is OK!! ${PRTOVER}"
    else
            ssh-gerrit review --verified -1 -m '"check SDMID definition in the plf files failed, please correct it! Error_Log_URL:"'${BUILD_URL}'"/console"' ${changenum},${patchset}
            exit 1
    fi
    #SDMS_IN_ROOT=`grep "<SDMID>.*</SDMID>" $ROOTPLF | sed "s/.*<SDMID>\(.*\)<\/SDMID>.*/\1/g"`
    #temp=`echo $SDMS_IN_PLF | awk 'a[$1]++'`
    #echo $temp
    echo "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

check_sdmid_root_and_project()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"
    ROOTPLF="$PLF_PATH/plf/`basename $1`"
    if [[ ! -f ${ROOTPLF} ]];then
         ROOTPLF="$PLF_PATH/`basename $1`"
    fi
    #echo $ROOTPLF
    SDMS_IN_PROJECT=`grep "<SDMID>.*</SDMID>" $1 | sed "s/.*<SDMID>\(.*\)<\/SDMID>.*/\1/g"`
    SDMS_IN_ROOT=`grep "<SDMID>.*</SDMID>" ${ROOTPLF} | sed "s/.*<SDMID>\(.*\)<\/SDMID>.*/\1/g"`
    for SDM in ${SDMS_IN_PROJECT};do
            if [[ ! "$SDMS_IN_ROOT" =~ "$SDM" ]];then
                    IS_plf_error='true'
                    echo -e "${PRTRED} Error: the $SDM define in `echo $1 |awk -F 'wprocedures' '{print $2}'` is not define in `echo ${ROOTPLF} |awk -F 'wimdata_ng' '{print $2}'`  ${PRTOVER}"
            fi
    done
    if [[ x"$IS_plf_error" != x"true" ]];then
            echo -e "${PRTGREEN} the define of SDM is OK!! ${PRTOVER}"
    else
            ssh-gerrit review --verified -1 -m '"check SDMID definition in the plf files failed, please correct it! Error_Log_URL:"'${BUILD_URL}'"/console"' ${changenum},${patchset}
            exit 1
    fi
    echo "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

mergeplf()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"
    build_project=$1
    pre_wimdata_path=$2
	if [[ -d "device/jrdcsz" ]];then
        merge_plf=device/jrdcsz/common/jrd_update_plf.py
        merge_sys_plf=device/jrdcsz/common/jrd_merge_sys_plf.sh
	else
		merge_plf=device/jrdcom/common/jrd_update_plf.py
        merge_sys_plf=device/jrdcom/common/jrd_merge_sys_plf.sh
	fi
    arct_tool_path=vendor/jrdcom/tool/arct/prebuilt/arct
    jrd_res_dir=out/target/common/jrdResAssetsCust
    plf_common_dir=${pre_wimdata_path}/wprocedures/plf
    plf_project_dir=${pre_wimdata_path}/wprocedures/${build_project}/plf

    if [[ ! -d "$jrd_res_dir/wimdata/wprocedures/plf" ]];then
        mkdir -p "$jrd_res_dir/wimdata/wprocedures/plf"
    fi

    PLF_FILE_ALL=`find ${plf_common_dir} -type f -name '*.plf'`
    PLF_FILE_PROJECT=`find ${plf_project_dir} -type f -name '*.plf'`

    for sourceplffile in ${PLF_FILE_ALL}; do
            filename=$(echo ${sourceplffile}|awk -F "/" '{print $NF}')
            found=false
            for destplffile in ${PLF_FILE_PROJECT}; do
                    destfilename=$(echo ${destplffile}|awk -F "/" '{print $NF}')
                    if [[ -e ${destplffile} ]] && [[ ! -e ${plf_common_dir}/${destfilename} ]]; then
                            echo "$destplffile not exist in $plf_common_dir, exit"
                            IS_plf_error='true'
                            break
                    fi
                    if [[ "x"${filename} == "x"${destfilename} ]]; then
                            found=true
                            echo "Merge $destplffile -> $sourceplffile"
                            python ${merge_plf} ${destplffile} ${sourceplffile} ${jrd_res_dir}/wimdata/wprocedures/plf/${destfilename}
                            if [[ "$?" -ne "0" ]];then
                               IS_plf_error='true'
                               break
                            fi
                    fi

            done
            if [[ ${found} == false ]]; then
                    if [[ -e ${sourceplffile} ]] && [[ ! -e ${plf_project_dir}/${filename} ]]; then
                            echo "$filename is not found in $plf_project_dir,copy from $plf_common_dir/$filename"
                            cp -f ${sourceplffile} ${jrd_res_dir}/wimdata/wprocedures/plf/
                    fi
            fi
    done

    if [[ x"$IS_plf_error" != x"true" ]];then
       ${merge_plf} ${build_project} ${jrd_res_dir} ${pre_wimdata_path} ${arct_tool_path} 1>/dev/null
       if [[ "$?" -eq "1" ]]; then
           ssh-gerrit review --verified -1 -m '"merge plf file between common and project failed, please correct it! Error_Log_URL:"'${BUILD_URL}'"/console"' ${changenum},${patchset}
           exit 1
       fi
    fi

    echo "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

check_PLFfile()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"
    local changenum=$1
    local patchset=$2
    local project_path=$3
    local IS_plf_error='false'
    PRTOVER="\\033[0m"
    PRTGREEN="\\033[01;32m"
    PRTRED="\\033[01;31m"
    echo "check PLF files"
    ssh-gerrit query --files --patch-sets=${changenum} | grep "file:" > PLFfile.txt
    PLFnum=$(cat PLFfile.txt | grep "plf" | wc -l)
    if [[ ${PLFnum} -eq 0 ]]; then
        echo "no PLF file in the commit..."
    else
        echo "PLF files num: $PLFnum"
        PLF_PATH=${project_path}
        if [[ -d "$PLF_PATH/${build_project}" ]];then
                SUBPLF=`find ${PLF_PATH}/${build_project}/plf -name '*.plf'`
                SUBPLF=${SUBPLF}" $PLF_PATH/${build_project}/isdm_sys_makefile.plf $PLF_PATH/${build_project}/isdm_sys_properties.plf"
                #echo $SUBPLF
                for PLF in ${SUBPLF};do
                        check_sdmid_duplicate ${PLF}
                        check_sdmid_root_and_project ${PLF}
                done
                merge_sys_plf ${build_project} wimdata_ng
        fi
        if [[ x"IS_plf_error" != x"true" ]];then
           PLF_PARSE_TOOL=vendor/jrdcom/tool/prd2xml
           PLF_MERGE_PATH="out/target/common/jrdResAssetsCust/wimdata/plf"
           PLF_TARGET_XML_FOLDER="tmp_plf"
           if [[ -d "$PLF_TARGET_XML_FOLDER" ]];then
                rm -rfv "$PLF_TARGET_XML_FOLDER"
                mkdir -p ${PLF_TARGET_XML_FOLDER}
           else
                mkdir -p ${PLF_TARGET_XML_FOLDER}
           fi
           if [[ -d "${PLF_MERGE_PATH}" ]] ; then
               PLF_FILES=($(find ${PLF_MERGE_PATH} -type f -name *.plf))
           fi
           for plf in ${PLF_FILES[@]}
           do
               LD_LIBRARY_PATH=${PLF_PARSE_TOOL} ${PLF_PARSE_TOOL}/prd2h --def ${PLF_PARSE_TOOL}/prd2h_def.xml --dest ${PLF_TARGET_XML_FOLDER} ${plf}
               ret=$?
               if [[ ${ret} -ne 0 && ${ret} -ne 139 ]] ; then # ignore error #139
                   echo "Parse PLF files error, exiting now ... "
                   IS_plf_error='true'
                   break
               fi
           done
           if [[ -d "$PLF_TARGET_XML_FOLDER" ]];then
               rm -rfv "$PLF_TARGET_XML_FOLDER"
           fi
       fi

        if [[ x"$IS_plf_error" != x"true" ]];then
                echo -e "${PRTGREEN} the define of SDM is OK!! ${PRTOVER}"
        else
                ssh-gerrit review --verified -1 -m '"check SDMID definition in the plf files failed, please correct it! Error_Log_URL:"'${BUILD_URL}'"/console"' ${changenum},${patchset}
                exit 1
        fi
    fi
    echo "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

check_apkdebugable()
{
    echo "INFO: Enter ${FUNCNAME[0]}()"

    local changenum=$1
    local patchset=$2
    local project_path=$3
    local codebuild=true
    ssh-gerrit query --files --patch-sets=${changenum} | grep -E -o "file: .*.apk" > checkapk.txt
    while read -r item
    do
        filename=${item#file: }
        #echo "file name is \"$filename\""
        echo ${filename} | grep ' '
        if [[ "$?" -eq 0 ]]; then
            echo "Abandon delivery for \"$filename\" contains blank space"
            ssh-gerrit review --verified -1 -m '"Apk '${filename}' contains blank space"' ${changenum},${patchset}
            codebuild=false
        else
            debugstatu=$(prebuilts/sdk/tools/linux/bin/aapt d xmltree ${project_path}/${filename} AndroidManifest.xml | grep debuggable | grep -E -o "[^@]0xffffffff")
            if [[ -n "$debugstatu" && "$debugstatu" != "0x0" ]]; then
                echo "Abandon delivery for \"$filename\" is Debuggable"
                ssh-gerrit review --verified -1 -m '"Apk '${filename}' is Debuggable"' ${changenum},${patchset}
                codebuild=false
            fi
        fi
        fbasenam=$(basename ${filename})
        if [[ "${#fbasenam}" -gt 98 ]]; then
            echo "String \"$fbasenam\" contains more than 98 character, Please rename apk with a short name."
            ssh-gerrit review --verified -1 -m '"String '${fbasenam}' contains more than 98 character, pls rename the apk with a short name."' ${changenum},${patchset}
            codebuild=false
        fi
    done < checkapk.txt
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    if [[ "$codebuild" == "false" ]]; then
        #ssh-gerrit review --abandon ${changenum},${patchset}
        exit 1
    fi

    echo "INFO: Exit ${FUNCNAME[0]}()"
}