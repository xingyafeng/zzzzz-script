#!/bin/bash

# if error;then exit
set -e

unset BUILD_ID
export PS4="+ [\t] "

SCRIPTS_DIR=$(dirname $(readlink -f $BASH_SOURCE))
repo_arry=(manifests manifests.git manifest.xml project.list project-objects projects repo)
buildlist_in_list='development/apps'
username='Integration.tablet'
MANIFEST_PROJECT='gcs_sz/manifest.git'
REPO_MIRROR_PATH='/home/android/mirror'
GERRIT_SERVER='shenzhen.gitweb.com'

# 编译路径
BUILDDIR=${WORKSPACE}

# 1. manifest
build_manifest=
# 2. 项目名称
build_project=
# 3. 更新源码
build_update_code=
# 4. 是否清除编译
build_clean=

## manifest info
declare -A manifest_info

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

customize_mk_list()
{
    #find $@ -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -iregex '.*android.\(mk\|bp\)' \
    find $@ \( -ipath '*/out/*' -o  -ipath '*/out_modem/*' -o -ipath '*/temp_modem/*'  -o  -ipath '*test*' -o -ipath '*sdk*' -o -ipath '*pdk*' -o -ipath '*developers*' -o -ipath '*/cts/*' -o -ipath '*support*' -o  -ipath '*.repo' -o -path '*/.git' \)  -a -prune -o -type f -iregex '.*android.\(mk\|bp\)' -print
}

function android_mk_path() {

    pushd ${BUILDDIR}/${project_path} 1>/dev/null
    local find_androidmk_path_list=""

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

    echo "find_androidmk_path_list: $find_androidmk_path_list"
    build_path=(`echo ${find_androidmk_path_list} | tr ' ' '\n' |  sort -u | uniq | xargs echo`)

    echo "android_mk_path: ${build_path}"

    popd > /dev/null
}

verify_submit_patchset()
{
    show_vip "INFO: Enter ${FUNCNAME[0]}()"
    pushd ${BUILDDIR}/${project_path} > /dev/null
    cd ${BUILDDIR}

    for args in "${localbuildprj[@]}" ; do
        project="${args%%:*}"
        tmp="${args#*:}"
        project_path="${tmp%%:*}"
        tmp="${args#*:*:}"
        changenumber=${tmp%%:*}
        tmp="${args#*:*:*:}"
        patchset=${tmp%%:*}
        revision=${tmp##*:}

        echo 'is_build_success = ' ${is_build_success}
        echo 'BUILD_URL = ' ${BUILD_URL}
        echo 'changenumber = ' ${changenumber}
        echo 'patchset = ' ${patchset}

        if [[ x"${is_build_success}" == x"1" ]];then
            ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review -m '"Build Log_URL:'${BUILD_URL}'"' ${changenumber},${patchset}

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
                echo "ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review -m '"this patchset gerrit trigger build successful; --submit"' --submit ${changenumber},${patchset}"
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

    popd > /dev/null
    echo "INFO: Exit ${FUNCNAME[0]}()"
}

check_patchset_status()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"

    cd ${BUILDDIR}
    Is_check_status=true
    for item in ${change_number_list[@]}
    do
        if [[ -z "$GERRIT_TOPIC" ]]; then
            project=${GERRIT_PROJECT}
            changenumber=${GERRIT_CHANGE_NUMBER}
            patchset=${GERRIT_PATCHSET_NUMBER}
            refspec=${GERRIT_REFSPEC}
            url=${GERRIT_CHANGE_URL}

            ssh_cmd=$(ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit query "--patch-sets=$changenumber status:closed")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               touch aborted_flag
               echo "$url The patch status is Abandoned or Merged now, no need to build this time."
               ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been Abandoned or Merged now, so no need to build this time."'  ${changenumber},${patchset}
               exit 0
            fi

            ssh_cmd=$(ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit query "--patch-sets=$changenumber label:Verified+1")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               touch aborted_flag
               echo "$url The patch status has been verified by auto compile, no need to build this time."
               ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been verified +1 by auto compile or somebody, so no need to build this time."'  ${changenumber},${patchset}
               exit 0
            fi
            #ssh_cmd=$(ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit query "--patch-sets=$changenumber label:Verified-1 NOT label:code-review+2")
            #if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
            #     touch aborted_flag
            #     echo "$url The patch status has been verified -1 by auto compile and so The patch status must be code-reviewed +2, no need to build this time."
            #     ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patchset has been verified -1 by auto compile, and so The patch status must be code-reviewed +2 to start compile again,no need to build this time."'  $changenumber,$patchset
            #     exit 0
            #fi
            ssh_cmd=$(ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit query "--patch-sets=$changenumber label:code-review<0")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               touch aborted_flag
               echo "$url The patch status has been code-reviewed -1 or -2 by somebody, and so no need to build this time."
               ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been code-reviewed -1 or -2 by somebody, please check this patchset."'  ${changenumber},${patchset}
               exit 0
            fi

            patchset_n=$(echo $(ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit query --current-patch-set "change:$changenumber" | grep "   number:" | cut -d":" -f2))
            if [[  ${patchset_n} -ne ${GERRIT_PATCHSET_NUMBER} ]];then
               touch aborted_flag
               echo "$url This patchset is not the latest, it was rebased or committed again, so no need to build this time."
               ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console This patchset is not the latest, it was rebased or committed again, so no need to build this time."'  ${changenumber},${patchset}
               exit 0
            fi
        else
            if [[ -f "${BUILDDIR}/tmp_dir/$item" ]]; then
                source ${BUILDDIR}/tmp_dir/${item}
            else
                echo "Topic item $item information dropout"
                exit 1
            fi

            ssh_cmd=$(ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit query "--patch-sets=$changenumber branch:msm7250-q0-seattletmo-dint status:merged")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               echo "$url The patch status is merged now, no need to build this time."
               ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch had been merged now, so no need to build this time."'  ${changenumber},${patchset}
               sed -i -e '/'"$changenumber"'/d' ${BUILDDIR}/tmp_dir/change_number_list.txt  && rm -fv ${changenumber}
               continue
            fi

            ssh_cmd=$(ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit query "--patch-sets=$changenumber branch:msm7250-q0-seattletmo-dint status:abandoned")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               echo "$url The patch status is abandoned now, no need to build this time."
               ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch had been abandoned now, please check this patchset,thanks."'  ${changenumber},${patchset}
               Is_check_status=false
               continue
            fi
            #ssh_cmd=$(ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit query "--patch-sets=$changenumber label:Verified-1 NOT label:code-review+2")
            #if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
            #     echo "$url The patch status has been verified -1 by auto compile and so The patch status must be code-reviewed +2, no need to build this time."
            #     ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patchset has been verified -1 by auto compile, and so The patch status must be code-reviewed +2 to start compile again,no need to build this time."'  $changenumber,$patchset
            #     Is_check_status=false
            #     continue
            #fi
            ssh_cmd=$(ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit query "--patch-sets=$changenumber branch:msm7250-q0-seattletmo-dint label:code-review<0")
            if echo ${ssh_cmd} | grep "commitMessage" &>/dev/null; then
               echo "$url The patch status has been code-reviewed -1 or -2 by somebody, and so no need to build this time."
               ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patch has been code-reviewed -1 or -2 by somebody, please check this patchset,thanks."'  ${changenumber},${patchset}
               Is_check_status=false
               continue
            fi

            patchset_n=$(echo $(ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit query --current-patch-set "change:$changenumber" | grep "   number:" | cut -d":" -f2))
            if [[  ${patchset_n} -ne ${patchset} ]];then
               echo "$url This patchset is not the latest,the current patchset num is $patchset and the latest is $patchset_n, it was rebased or committed again, so no need to build this time."
               ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console This patchset is not the latest, it was rebased or committed again, so no need to build this time."'  ${changenumber},${patchset}
               sed -i -e  's/^\(patchset=\).*$/\1'"$patchset_n"'/' ${BUILDDIR}/tmp_dir/${changenumber}
               continue
            fi
        fi
    done

    if [[ x"$Is_check_status" == "xfalse" ]];then
        for item in ${change_number_list[@]}
        do
            if [[ -f "${BUILDDIR}/tmp_dir/$item" ]]; then
                source "${BUILDDIR}/tmp_dir/$item"
            else
                echo "Topic item $item information dropout"
                exit 1
            fi

            ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"The patchset relation for check failed on the same pr number, please check this patchset for verified -1 or reviewed <0."'  ${changenumber},${patchset}
        done

        touch aborted_flag
        exit 1
    fi
 
    echo "INFO: Exit ${FUNCNAME[0]}()"
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
            ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review --verified -1 -m '"check SDMID definition in the plf files failed, please correct it! Error_Log_URL:"'${BUILD_URL}'"/console"' ${changenum},${patchset}
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
            ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review --verified -1 -m '"check SDMID definition in the plf files failed, please correct it! Error_Log_URL:"'${BUILD_URL}'"/console"' ${changenum},${patchset}
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
	if [[ -d "${BUILDDIR}/device/jrdcsz" ]];then
        merge_plf=${BUILDDIR}/device/jrdcsz/common/jrd_update_plf.py
        merge_sys_plf=${BUILDDIR}/device/jrdcsz/common/jrd_merge_sys_plf.sh
	else
		merge_plf=${BUILDDIR}/device/jrdcom/common/jrd_update_plf.py
        merge_sys_plf=${BUILDDIR}/device/jrdcom/common/jrd_merge_sys_plf.sh
	fi
    arct_tool_path=${BUILDDIR}/vendor/jrdcom/tool/arct/prebuilt/arct
    jrd_res_dir=${BUILDDIR}/out/target/common/jrdResAssetsCust
    plf_common_dir=${BUILDDIR}/${pre_wimdata_path}/wprocedures/plf
    plf_project_dir=${BUILDDIR}/${pre_wimdata_path}/wprocedures/${build_project}/plf
   
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
           ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review --verified -1 -m '"merge plf file between common and project failed, please correct it! Error_Log_URL:"'${BUILD_URL}'"/console"' ${changenum},${patchset}
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
    ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit query --files --patch-sets=${changenum} | grep "file:" > PLFfile.txt
    PLFnum=$(cat PLFfile.txt | grep "plf" | wc -l)
    if [[ ${PLFnum} -eq 0 ]]; then
        echo "no PLF file in the commit..."
    else
        echo "PLF files num: $PLFnum"
        PLF_PATH=${BUILDDIR}/${project_path}
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
           PLF_PARSE_TOOL=${BUILDDIR}/vendor/jrdcom/tool/prd2xml
           PLF_MERGE_PATH="${BUILDDIR}/out/target/common/jrdResAssetsCust/wimdata/plf"
           PLF_TARGET_XML_FOLDER="${BUILDDIR}/tmp_plf"
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
                ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review --verified -1 -m '"check SDMID definition in the plf files failed, please correct it! Error_Log_URL:"'${BUILD_URL}'"/console"' ${changenum},${patchset}
                exit 1
        fi
    fi
    echo "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

check_apkdebugable()
{
#    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"
    local changenum=$1
    local patchset=$2
    local project_path=$3
    local codebuild=true
    ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit query --files --patch-sets=${changenum} | grep -E -o "file: .*.apk" > checkapk.txt
    while read -r item
    do
        filename=${item#file: }
        #echo "file name is \"$filename\""
        echo ${filename} | grep ' '
        if [[ "$?" -eq 0 ]]; then
            echo "Abandon delivery for \"$filename\" contains blank space"
            ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review --verified -1 -m '"Apk '${filename}' contains blank space"' ${changenum},${patchset}
            codebuild=false
        else
            debugstatu=$(prebuilts/sdk/tools/linux/bin/aapt d xmltree ${BUILDDIR}/${project_path}/${filename} AndroidManifest.xml | grep debuggable | grep -E -o "[^@]0xffffffff")
            if [[ -n "$debugstatu" && "$debugstatu" != "0x0" ]]; then
                echo "Abandon delivery for \"$filename\" is Debuggable"
                ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review --verified -1 -m '"Apk '${filename}' is Debuggable"' ${changenum},${patchset}
                codebuild=false
            fi
        fi
        fbasenam=$(basename ${filename})
        if [[ "${#fbasenam}" -gt 98 ]]; then
            echo "String \"$fbasenam\" contains more than 98 character, Please rename apk with a short name."
            ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review --verified -1 -m '"String '${fbasenam}' contains more than 98 character, pls rename the apk with a short name."' ${changenum},${patchset}
            codebuild=false
        fi
    done < checkapk.txt
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    if [[ "$codebuild" == "false" ]]; then
        #ssh -o ConnectTimeout=32 -p 29418 ${username}@${GERRIT_HOST} gerrit review --abandon ${changenum},${patchset}
        exit 1
    fi
    echo "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

parse_all_patchset()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"

    pushd ${BUILDDIR} 1>/dev/null

    if [[ -n "$GERRIT_TOPIC" ]]; then
        if [[ -f "${BUILDDIR}/tmp_dir/changeid.json" ]]; then
            rm -vf "${BUILDDIR}/tmp_dir/changeid.json"
        fi
        GERRIT_TOPIC_TR=$(echo ${GERRIT_TOPIC} | tr ';' '.')
        ssh-gerrit query \
            --current-patch-set "intopic:^.*${GERRIT_TOPIC_TR}.* branch:${GERRIT_BRANCH} status:open NOT label:code-review-1" \
            --format json > ${BUILDDIR}/tmp_dir/changeid.json
        if [[ "$?" -eq 0 ]]; then
            cd ${BUILDDIR}/tmp_dir && python ${SCRIPTS_DIR}/parse_change_infos.py ${BUILDDIR}/tmp_dir/changeid.json
            if [[ "$?" -ne 0 ]]; then
                echo "parse Topic: $GERRIT_TOPIC infomation failed"
                exit 1
            fi
        else
            echo "Error occured when link ${GERRIT_HOST}."
            exit 1
        fi
    fi

    if [[ -n "$GERRIT_TOPIC" ]]; then
        if [[ -s "${BUILDDIR}/tmp_dir/change_number_list.txt" ]]; then
            change_number_list=($(cat ${BUILDDIR}/tmp_dir/change_number_list.txt | sort -n))
        else
            echo "parse Topic: $GERRIT_TOPIC change number list null"
            echo "${GERRIT_CHANGE_URL} The patch status is Abandoned or Merged or already verified +1 by gerrit trrigger auto compile, no need to build this time."
            ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patchset has been Abandoned or Merged or already verified +1 by gerrit trigger auto compile, so no need to build this time."'  ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
            exit 0
        fi
    else
        change_number_list=${GERRIT_CHANGE_NUMBER}
    fi

    popd > /dev/null
    echo "change_number_list = " ${change_number_list[@]}
    echo "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function download_all_patchset()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"

    local project_path=

    pushd ${BUILDDIR} > /dev/null

    for item in ${change_number_list[@]}
    do
        if [[ -z "$GERRIT_TOPIC" ]]; then
            echo 'yafeng: topic is null ...'
            project=${GERRIT_PROJECT}
            changenumber=${GERRIT_CHANGE_NUMBER}
            revision=${GERRIT_PATCHSET_REVISION}
            patchset=${GERRIT_PATCHSET_NUMBER}
            refspec=${GERRIT_REFSPEC}
            url=${GERRIT_CHANGE_URL}
        else
            if [[ -f "${BUILDDIR}/tmp_dir/$item" ]]; then
                source ${BUILDDIR}/tmp_dir/${item}
            else
                echo "Topic item $item information dropout"
                exit 1
            fi
        fi

        show_vig 'yafeng: project = ' ${project}

        project_path=$(get_project_path)
        show_vig "current path: $project_path"
        recover_standard_git_project ${project_path}

        pushd ${BUILDDIR}/${project_path} > /dev/null
        repo sync . --no-tags -j$(nproc)

        # 为什么要重名，是解决不编译此模块吗？
        if [[ -f ${BUILDDIR}/vendor/tct/source/qcn/Android.mk  ]]; then
            mv ${BUILDDIR}/vendor/tct/source/qcn/Android.mk ${BUILDDIR}/vendor/tct/source/qcn/Android.mk_bak
        fi

        Command "git fetch ssh://${username}@${GERRIT_HOST}:29418/${project} ${refspec}"
        Command "git cherry-pick FETCH_HEAD"

        if [[ "$?" -eq 0 ]] ; then
            echo "$project_path download patchset refs/changes/$GERRIT_CHANGE_NUMBER/$GERRIT_PATCHSET_NUMBER sucessful."
            if [[ -z "$localbuildprj" ]];then
                  localbuildprj=("$project:$project_path:$changenumber:$patchset:$revision")
            else
                  localbuildprj=(${localbuildprj[*]} "$project:$project_path:$changenumber:$patchset:$revision")
            fi
        else
            ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review -m '""'${BUILD_URL}'"\t"'${project_path}'"\t merge the patchset conflict refs/changes/"'${GERRIT_CHANGE_NUMBER}'"/"'${GERRIT_PATCHSET_NUMBER}'" failed,please resubmit code!!!"' --verified -1  ${changenumber},${patchset}
            git reset --hard
            touch aborted_flag
            exit 1
        fi

        if [[ ${project_path} =~ "development" ]];then
            if [[ -d "${BUILDDIR}/version" ]];then
                if [[ ! -d "${BUILDDIR}/development/version/include" ]];then
                    mkdir -p ${BUILDDIR}/development/version/include
                fi

                cp -fv ${BUILDDIR}/version/version.inc ${BUILDDIR}/development/version/include/version.inc
            fi
        fi

        project=
        changenumber=
        patchset=
        refspec=
        url=
        popd > /dev/null
    done

    popd > /dev/null
    echo "INFO: Exit ${FUNCNAME[0]}()"
    trap - ERR
}

function gerrit_build() {

    #trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    echo "INFO: Enter ${FUNCNAME[0]}()"
    local is_build_success=0
    local build_path_list=""
    local build_module_list=""
    local build_project_array=()
    #localbuildprj=("mtk8735a/frameworks:frameworks:222740:1:d1a7aafea09810fd50d2d7a09d1071810ebd77dc" "mtk8735a/frameworks:frameworks:222789:1:01a6ebc80a2484047652a852fb55eba09ea04820" "mtk8735a/vendor/mediatek:vendor/mediatek:2211222:1:c00a31c24fb0c90fbc6c84ff84ec8eef4c798484" "mtk8735a/vendor/mediatek:vendor/mediatek:2211222:1:a69fe425636ba1b37a9b80ba28370cd9a2f54ab1")
    #BUILDDIR=$(dirname $(readlink -f $BASH_SOURCE))

    cd ${BUILDDIR}
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

        echo '@@@@@'
        echo 'project_path = ' ${project_path}

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
                     build_project_array=("\"m@-j${JOBS}@out/target/product/${build_project}/boot.img\"")
                else
                     build_project_array=(${build_project_array[*]} "\"m@-j${JOBS}@out/target/product/${build_project}/boot.img\"")
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
                #list=(`customize_mk_list $(cat buildlist | awk -F: '{print $1}' | xargs echo | sort -u)`)
                list=(`cat ${BUILDDIR}/build/make/tools/buildlist | awk -F: '{print $1}' | sort -u`)
                echo 'list = ' ${list}
                android_mk_path
                echo 'android_mk_path --------------- end ...'

                #if [ -z "${#array[@]}" ];then
                if [[ ${#build_path[@]} -eq 0 ]]; then
                   is_build_mma=false
                   break
                else
                    show_vig '${build_path[@]} = ' ${build_path[@]}

                    for i in ${build_path[@]}
                    do
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
                            for j in ${list[@]}
                            do
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
                build_module_name=$(cat ${BUILDDIR}/build/make/tools/buildlist | grep "^$prjitem:" | awk -F: '{print $2}' | tr ',' ' ')
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
                cd ${BUILDDIR}
                if echo "${prjitem}" | grep -E ':' &>/dev/null; then
                    changenum=`echo "${prjitem}" | tr -d '"' | awk -F: '{print $1}'`
                    patchset=`echo "${prjitem}" | tr -d '"' |  awk -F: '{print $2}'`
                    project_path=`echo "${prjitem}" | tr -d '"' | awk -F: '{print $3}'`
                    prjitem="$(echo "${prjitem}" | tr -d '"' | awk -F: '{print $4}') ${changenum} ${patchset} ${project_path}"
                else
                    prjitem=$(echo "${prjitem}" | tr -d '"' | tr "@" ' ')
                fi

                ## 增加编译QSSI
#                if [[ $(is_qssi_product $s) ]]; then
#                    :
#                fi

                echo '@@@  prjitem = ' ${prjitem}
                eval ${prjitem}

                if [[ "$?" -ne "0" ]] ; then
                    is_build_success=0 || false
                    break
                else
                    is_build_success=1 || true
                fi
            done

            if [[ x"$is_build_success" == x"0" ]];then
                verify_submit_patchset
                exit 1
            fi
        fi

        time_stamp=`date +"%Y%m%d_%H%M%S"`
        prebuild_log=${time_stamp}"_mma.log"

        if [[ -n "$build_module_list" ]];then
            cd ${BUILDDIR}

            if [[ -f "${BUILDDIR}/${prebuild_log}" ]]; then
                rm -fv ${BUILDDIR}/${prebuild_log}
            fi

            echo "mma -j${JOBS} checkapi $build_module_list"
            mma -j${JOBS} checkapi ${build_module_list} 2>&1 | tee ${prebuild_log}

            if [[ ${PIPESTATUS[0]} -ne 0 ]] ; then
                :
#                if (tail -n 1000 ${prebuild_log} |  grep -q -E "^ninja:[[:space:]]+error:[[:space:]]+unknown[[:space:]]+target.*$|^ninja:[[:space:]]+error:.*needed[[:space:]]+by[[:space:]]+.*[[:space:]]+missing[[:space:]]+and[[:space:]]+no[[:space:]]+known[[:space:]]+rule[[:space:]]+to[[:space:]]+make[[:space:]]+it");then
#                    make -j${JOBS} 2>&1
#                    if [[ "$?" -ne "0" ]] ; then
#                        is_build_success=0 || false
#                        verify_submit_patchset
#                        exit 1
#                    else
#                        is_build_success=1 || true
#                    fi
#                else
#                    if (tail -n 1000 ${prebuild_log} |  grep -r "FAILED: ninja: unknown target");then
#                        echo "aaaaaaaaaaaaaaaaaaaaaaaaaaa  $? bbbbbbbbbbbbbbbbbbbbbbbbbbb "
#                        make -j${JOBS} 2>&1
#                        if [[ "$?" -ne "0" ]];then
#                            is_build_success=0 || false
#                            verify_submit_patchset
#                            exit 1
#                        else
#                            is_build_success=1 || true
#                        fi
#                    else
#                        is_build_success=0 || false
#                        verify_submit_patchset
#                        exit 1
#                    fi
#                fi
            else
                is_build_success=1 || true
            fi
        fi

        if [[ x"$is_build_success" == x"1" ]];then
            verify_submit_patchset
        fi
    else
        cd ${BUILDDIR}
        Command "make -j${JOBS} 2>&1"
        if [[ "$?" -ne "0" ]] ; then
            is_build_success=0 || false
            verify_submit_patchset
            exit 1
        else
            is_build_success=1 || true
            verify_submit_patchset
        fi
    fi

    echo "INFO: Exit ${FUNCNAME[0]}()"
    #trap - ERR
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
    echo 'GERRIT_SERVER  = ' ${GERRIT_SERVER}
    echo 'GERRIT_BRANCH  = ' ${GERRIT_BRANCH}
    echo 'GERRIT_TOPIC   = ' ${GERRIT_TOPIC}
    echo '-------------------------------------'
    echo 'localbuildprj  = ' ${localbuildprj}
    echo '-------------------------------------'
    echo
}

function prepare() {

    pushd ${WORKSPACE} > /dev/null
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

    if [[ -f "$BUILDDIR/aborted_flag" ]]; then
        rm -fv ${BUILDDIR}/aborted_flag
    fi

    if [[ -d "${BUILDDIR}/tmp_dir" ]]; then
        rm -rvf "${BUILDDIR}/tmp_dir"
        mkdir -p "${BUILDDIR}/tmp_dir"
    else
        mkdir -p "${BUILDDIR}/tmp_dir"
    fi

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

        if [[ -f "${BUILDDIR}/modem/mcu/Android.mk" ]]; then
            rm -vf "${BUILDDIR}/modem/mcu/Android.mk"
        fi

        if [[ -d "${BUILDDIR}/out/target/common/jrdResAssetsCust/wimdata" ]];then
            rm -rvf "${BUILDDIR}/out/target/common/jrdResAssetsCust/wimdata"
        fi

        # 解析gerrit提交
        parse_all_patchset
        check_patchset_status
        download_all_patchset

        echo '---- gerrit build start ... '

        # 单独编译模块
        gerrit_build

        echo '---- gerrit build end ... '
    else

        # 编译android
        make_android
    fi

    if [[ "$(is_build_server)" == "true" ]];then

        ### 打印编译所需要的时间
        print_make_completed_time

        echo
        show_vip "--> make android end ." && log debug "--> make android end ."

        show_vip "INFO: Exit ${FUNCNAME[0]}()"
    else
        log error "The server is not running on build server."
    fi

    popd > /dev/null

    trap - ERR
}

main "$@"