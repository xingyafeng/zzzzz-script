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

    show_vig "find_androidmk_path_list: $find_androidmk_path_list"
    build_path=(`echo ${find_androidmk_path_list} | tr ' ' '\n' |  sort -u | uniq | xargs echo`)
    __green__ "android_mk_path: ${build_path}"

    popd > /dev/null

    #check qssi project
    for build in ${build_path[@]} ; do
        if [[ "$(is_qssi_product ${build})" == "true" ]]; then
            export TARGET_PRODUCT=qssi

            log warn "This module is qssi project."
        fi
    done
}

verify_submit_patchset()
{
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    for args in "${localbuildprj[@]}" ; do
        project="${args%%:*}"
        tmp="${args#*:}"
        project_path="${tmp%%:*}"
        tmp="${args#*:*:}"
        changenumber=${tmp%%:*}
        tmp="${args#*:*:*:}"
        patchset=${tmp%%:*}
        revision=${tmp##*:}

        echo 'patchset         = ' ${patchset}
        echo 'BUILD_URL        = ' ${BUILD_URL}
        echo 'changenumber     = ' ${changenumber}
        echo 'is_build_success = ' ${is_build_success}

        if [[ x"${is_build_success}" == x"1" ]];then
            ssh-gerrit review -m '"Build Log_URL:'${BUILD_URL}'"' ${changenumber},${patchset}

            if [[ "$(check_verified ${changenumber})" == "false" ]]; then
                ssh-gerrit review -m '"this patchset gerrit trigger build successful; --verified +1"' --verified 1 ${changenumber},${patchset}
                if [[ $? -eq 0 ]];then
                    echo "this patchset build successfully, --verified +1"
                else
                    ssh-gerrit review -m '"jenkins --verified +1 failed ..."' ${changenumber},${patchset}
                    log error "jenkins --verified +1 failed ..."
                fi
            fi

            if [[ "$(check_code-review ${changenumber})" == "true" ]]; then
                set +e
                ssh-gerrit review -m '"this patchset gerrit trigger build successful; --submit"' --submit ${changenumber},${patchset} 2>&1 | tee ${tmpfs}/submit.log
                set -e
            else
                ssh-gerrit review -m '"can only verify now, need some people to review +2."' ${changenumber},${patchset}
                log warn "can only verify now, need some people to review +2"
            fi
        else
            ssh-gerrit review -m '"Build Error_Log_URL:"'${BUILD_URL}'"/console"' --verified -1 ${changenumber},${patchset}
            if [[ $? -eq 0 ]];then
                echo "this patchset gerrit trigger build failed.\nError_Log_URL:${BUILD_URL}/console."
            else
                echo "verify_submit_patchset failed,please check."
            fi
        fi
    done

    echo "INFO: Exit ${FUNCNAME[0]}()"
}

check_patchset_status()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local Is_check_status=true

    for item in ${change_number_list[@]} ; do
        if [[ -z "${GERRIT_TOPIC}" ]] ; then
            project=${GERRIT_PROJECT}
            changenumber=${GERRIT_CHANGE_NUMBER}
            patchset=${GERRIT_PATCHSET_NUMBER}
            refspec=${GERRIT_REFSPEC}
            url=${GERRIT_CHANGE_URL}

            ssh_cmd=$(ssh-gerrit query "--patch-sets=${changenumber} status:closed")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               touch aborted_flag
               echo "${url} The patch status is Abandoned or Merged now, no need to build this time."
               ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been Abandoned or Merged now, so no need to build this time."' ${changenumber},${patchset}
               exit 0
            fi

            ssh_cmd=$(ssh-gerrit query "--patch-sets=$changenumber label:Verified+1")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               touch aborted_flag
               echo "${url} The patch status has been verified by auto compile, no need to build this time."
               ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been verified +1 by auto compile or somebody, so no need to build this time."' ${changenumber},${patchset}
               exit 0
            fi

            ssh_cmd=$(ssh-gerrit query "--patch-sets=${changenumber} label:code-review<0")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               touch aborted_flag
               echo "${url} The patch status has been code-reviewed -1 or -2 by somebody, and so no need to build this time."
               ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been code-reviewed -1 or -2 by somebody, please check this patchset."' ${changenumber},${patchset}
               exit 0
            fi

            patchset_n=$(echo $(ssh-gerrit query --current-patch-set "change:$changenumber" | grep "   number:" | cut -d":" -f2))
            if [[  ${patchset_n} -ne ${GERRIT_PATCHSET_NUMBER} ]];then
               touch aborted_flag
               echo "$url This patchset is not the latest, it was rebased or committed again, so no need to build this time."
               ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console This patchset is not the latest, it was rebased or committed again, so no need to build this time."'  ${changenumber},${patchset}
               exit 0
            fi
        else
            if [[ -f "${tmpfs}/gerrit/$item" ]]; then
                source "${tmpfs}/gerrit/${item}"
            else
                echo "Topic item $item information dropout"
                exit 1
            fi

            ssh_cmd=$(ssh-gerrit query "--patch-sets=$changenumber branch:msm7250-q0-seattletmo-dint status:merged")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               echo "$url The patch status is merged now, no need to build this time."
               ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch had been merged now, so no need to build this time."'  ${changenumber},${patchset}
               sed -i -e '/'"$changenumber"'/d' ${tmpfs}/gerrit/change_number_list.txt  && rm -fv ${changenumber}
               continue
            fi

            ssh_cmd=$(ssh-gerrit query "--patch-sets=$changenumber branch:msm7250-q0-seattletmo-dint status:abandoned")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               echo "$url The patch status is abandoned now, no need to build this time."
               ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch had been abandoned now, please check this patchset,thanks."'  ${changenumber},${patchset}
               Is_check_status=false
               continue
            fi

            ssh_cmd=$(ssh-gerrit query "--patch-sets=$changenumber branch:msm7250-q0-seattletmo-dint label:code-review<0")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               echo "$url The patch status has been code-reviewed -1 or -2 by somebody, and so no need to build this time."
               ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been code-reviewed -1 or -2 by somebody, please check this patchset,thanks."'  ${changenumber},${patchset}
               Is_check_status=false
               continue
            fi

            patchset_n=$(echo $(ssh-gerrit query --current-patch-set "change:$changenumber" | grep "   number:" | cut -d":" -f2))
            if [[  ${patchset_n} -ne ${patchset} ]];then
               echo "$url This patchset is not the latest,the current patchset num is $patchset and the latest is $patchset_n, it was rebased or committed again, so no need to build this time."
               ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console This patchset is not the latest, it was rebased or committed again, so no need to build this time."'  ${changenumber},${patchset}
               sed -i -e  's/^\(patchset=\).*$/\1'"$patchset_n"'/' ${tmpfs}/gerrit/${changenumber}
               continue
            fi
        fi
    done

    if [[ x"$Is_check_status" == "xfalse" ]];then
        for item in ${change_number_list[@]} ; do
            if [[ -f "${tmpfs}/gerrit/$item" ]]; then
                source "${tmpfs}/gerrit/$item"
            else
                echo "Topic item $item information dropout"
                exit 1
            fi

            ssh-gerrit review -m '"The patchset relation for check failed on the same pr number, please check this patchset for verified -1 or reviewed <0."' ${changenumber},${patchset}
        done

        touch aborted_flag
        exit 1
    fi

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

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

# 解析 patch-set
parse_all_patchset()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local GERRIT_TOPIC_TR=
    local branchs="development_dint@jrdapp-android-r-dint@qct-sm4250-tf-r-v1.0-dint@TCT-ROM-4.0-AOSP-GCS-OP@TCTROM-R-QCT-V4.1-dev_gcs@TCTROM-R-QTI-OP@TCTROM-R-V4.0-dev_gcs"

    if [[ -n "${GERRIT_TOPIC}" ]]; then
        GERRIT_TOPIC_TR=$(echo ${GERRIT_TOPIC} | tr ';' '.')

        ssh-gerrit query \
            --current-patch-set "intopic:^.*${GERRIT_TOPIC_TR}.* status:open NOT label:code-review-1" \
            --format json > ${tmpfs}/gerrit/changeid.json

        if [[ "$?" -eq 0 ]]; then
            pushd ${tmpfs}/gerrit > /dev/null

            python ${script_p}/tools/parse_change_infos.py changeid.json "${branchs}"
            if [[ $? -ne 0 ]]; then
                log error "parse Topic: ${GERRIT_TOPIC} infomation failed"
            fi

            popd > /dev/null
        else
            log error "Error occured when link ${GERRIT_HOST}."
        fi
    fi

    if [[ -n "${GERRIT_TOPIC}" ]]; then
        if [[ -s "${tmpfs}/gerrit/change_number_list.txt" ]]; then
            change_number_list=($(cat ${tmpfs}/gerrit/change_number_list.txt | sort -n))
        else
            show_vir "THe parse Topic: ${GERRIT_TOPIC} change number list null ..."
            ssh-gerrit review -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patchset has been Abandoned or Merged or already verified +1 by gerrit trigger auto compile, so no need to build this time."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
            log quit "${GERRIT_CHANGE_URL} The patch status is Abandoned or Merged or already verified +1 by gerrit trrigger auto compile, no need to build this time."
        fi
    else
        change_number_list=${GERRIT_CHANGE_NUMBER}
    fi

    __green__ "change_number_list = " ${change_number_list[@]}

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function download_all_patchset()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    local project_path=

    # 恢复当前干净状态
    checkout_standard_android_project
    Command "repo sync -c -d --no-tags -j$(nproc)"

    for item in ${change_number_list[@]} ; do
        if [[ -z "${GERRIT_TOPIC}" ]]; then
            url=${GERRIT_CHANGE_URL}
            project=${GERRIT_PROJECT}
            refspec=${GERRIT_REFSPEC}
            revision=${GERRIT_PATCHSET_REVISION}
            patchset=${GERRIT_PATCHSET_NUMBER}
            changenumber=${GERRIT_CHANGE_NUMBER}

            log debug "${GERRIT_TOPIC} is null ..."
        else
            if [[ -f "${tmpfs}/gerrit/$item" ]]; then
                source ${tmpfs}/gerrit/${item}
            else
                log error "Topic item $item information dropout"
            fi
        fi

        echo
        echo '-------------------------------------'
        echo 'url          = ' ${url}
        echo 'project      = ' ${project}
        echo 'refspec      = ' ${refspec}
        echo 'revision     = ' ${revision}
        echo 'patchset     = ' ${patchset}
        echo 'changenumber = ' ${changenumber}
        echo '-------------------------------------'
        echo

        project_path=$(get_project_path)
        show_vig "current path: $project_path"

        pushd ${project_path} > /dev/null

        Command "git fetch ssh://${username}@${GERRIT_HOST}:29418/${project} ${refspec}"
        Command "git checkout FETCH_HEAD"

        if [[ $? -eq 0 ]] ; then
            show_vig "${project_path} download patchset refs/changes/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER} sucessful."
            if [[ -z "${localbuildprj}" ]];then
                  localbuildprj=("$project:$project_path:$changenumber:$patchset:$revision")
            else
                  localbuildprj=(${localbuildprj[*]} "$project:$project_path:$changenumber:$patchset:$revision")
            fi
        else
            ssh-gerrit review -m '""'${BUILD_URL}'"\t"'${project_path}'"\t merge the patchset conflict refs/changes/"'${GERRIT_CHANGE_NUMBER}'"/"'${GERRIT_PATCHSET_NUMBER}'" failed,please resubmit code!!!"' --verified -1  ${changenumber},${patchset}
            git reset --hard
            touch aborted_flag
            exit 1
        fi

        if [[ ${project_path} =~ "development" ]];then
            if [[ -d "version" ]];then
                if [[ ! -d "development/version/include" ]];then
                    mkdir -p development/version/include
                fi

                cp -fv version/version.inc development/version/include/version.inc
            fi
        fi

        unset project changenumber patchset refspec url

        popd > /dev/null
    done

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function gerrit_build() {

    show_vip  "INFO: Enter ${FUNCNAME[0]}()"

    local is_build_success=0
    local build_path_list=""
    local build_module_list=""
    local build_project_array=()

    echo "localbuildprj: ${localbuildprj}"

    for args in "${localbuildprj[@]}" ; do
        project="${args%%:*}"
        echo "project: $project"
        tmp="${args#*:}"
        project_path="${tmp%%:*}"
        echo "project_path: $project_path"
        tmp="${args#*:*:}"
        changenum=${tmp%%:*}
        tmp="${args#*:*:*:}"
        patchset=${tmp%%:*}
        revision=${tmp##*:}

        show_vig '@@@ project_path = ' ${project_path}

        case "${project_path}" in

            amss_4250_spf1.0)
                is_build_mma=true
                if [[ ${#build_project_array[@]} -eq 0 ]];then
                     build_project_array=("\"cd@amss_4250_spf1.0@&&@./linux_build.sh@-a@delhitf@tf\"")
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
                echo 'list = ' ${list}
                android_mk_path
                show_vip 'android_mk_path --------------- end ...'

                if [[ ${#build_path[@]} -eq 0 ]]; then
                   is_build_mma=false
                   break
                else
                    show_vig 'yafeng:build path list = ' ${build_path[@]}
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
    done
    
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
                echo 'yafeng:'
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
                verify_submit_patchset
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
            verify_submit_patchset
        fi
    else
        export WITHOUT_CHECK_API=false

        echo 'yafeng:'
        if [[ "${TARGET_PRODUCT}" == "qssi" ]]; then
            Command "bash build.sh --qssi_only -j${JOBS}"
        else
            Command "bash build.sh --target_only -j${JOBS}"
        fi

        if [[ $? -ne 0 ]] ; then
            is_build_success=0
            verify_submit_patchset
            exit 1
        else
            is_build_success=1
            verify_submit_patchset
        fi
    fi

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
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

    handle_common_vairable
}

function print_variable() {

    echo
    echo '-------------------------------------'
    echo 'JOBS = ' ${JOBS}
    echo '-------------------------------------'
    echo 'build_clean        = ' ${build_clean}
    echo 'build_project      = ' ${build_project}
    echo 'build_manifest     = ' ${build_manifest}
    echo 'build_update_code  = ' ${build_update_code}
    echo '-------------------------------------'
    echo 'WORKSPACE      = ' ${WORKSPACE}
    echo 'GERRIT_BRANCH  = ' ${GERRIT_BRANCH}
    echo 'GERRIT_TOPIC   = ' ${GERRIT_TOPIC}
    echo '-------------------------------------'
    echo 'localbuildprj  = ' ${localbuildprj}
    echo '-------------------------------------'
    echo
}

function prepare() {

    pushd ${WORKSPACE} > /dev/null

    if [[ -f aborted_flag ]]; then
        rm -fv aborted_flag
    fi

    if [[ -d ${tmpfs}/gerrit ]]; then
        rm -rvf ${tmpfs}/gerrit/*
    fi
}

function init() {

    prepare

    handle_vairable
    print_variable
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    show_vip "INFO: Enter ${FUNCNAME[0]}()"

    ## 记录编译开始时间
    local startT=`date +'%Y-%m-%d %H:%M:%S'`
    local localbuildprj=()

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

        show_vip '---- gerrit build start ... '
        gerrit_build
        show_vip '---- gerrit build end ... '
    else

        # 编译android
        make_android
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

    show_vip "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

main "$@"