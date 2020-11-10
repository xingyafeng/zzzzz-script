#!/usr/bin/env bash

# 生成manifest中name对于的path列表
function generate_manifest_list() {

    local manifest_list_p=${tmpfs}/manifest_list.txt

    if [[ -f .repo/manifest.xml ]]; then
        xmlstarlet sel -T -t -m /manifest/project -v "concat(@name,':',@path,'')" -n .repo/manifest.xml > ${manifest_list_p}
    else
        log error ".repo/manifest.xml has no found ..."
    fi

    while IFS=":" read -r _name _path _;do
        #echo ${_name} '---' ${_path}
        if [[ -z ${_path} ]]; then
            _path=${_name}
        fi

        manifest_info[${_name}]=${_path}
    done < ${manifest_list_p}
}

# 生成manifest中name对于的path列表
function generate_module_list() {

    local result_installed=result_installed.txt

    if [[ ! -f ${result_installed} ]]; then
        generate_buildlist_file
    fi

    while IFS=":" read -r _path _target _;do
        #echo ${_path} '---' ${_target}
        if [[ -n ${_target} ]]; then
            moudule_list[${_path}]=${_target}
        fi
    done < ${result_installed}
}

# 拿到项目路径
function get_project_path() {

    if [[ -n ${project} ]]; then
        echo ${manifest_info[${project}]}
    elif [[ -n ${GERRIT_PROJECT} ]] ; then
        echo ${manifest_info[${GERRIT_PROJECT}]}
    else
        log error "get project path failed ..."
    fi
}

# 拿到目标模块名
function get_project_module() {

    if [[ -n ${project} ]]; then
        echo ${moudule_list[${project}]}
    elif [[ -n ${GERRIT_PROJECT} ]] ; then
        echo ${moudule_list[${GERRIT_PROJECT}]}
    else
        log error "get project path failed ..."
    fi
}

# 生成result_installed.txt
function generate_buildlist_file() {

    local path_py=${script_p}/tools/pathJson.py

    if [[ -f ${path_py} && -f out/target/product/qssi/module-info.json ]]; then
        Command "python ${path_py} out/target/product/qssi/module-info.json build/make/tools/buildlist"
    else
        log warn "${path_py} or out/target/product/qssi/module-info.json has no found!"
    fi
}

function verified+1() {

    ssh-gerrit review -m '"Build Log_URL:'${BUILD_URL}'"' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
    if [[ "$(check-gerrit 'verified+1' ${GERRIT_CHANGE_NUMBER})" == "false" ]]; then
        ssh-gerrit review -m '"this patchset gerrit trigger build successful; --verified +1"' --verified 1 ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
        if [[ $? -eq 0 ]];then
            show_vip "This patchset build successfully, --verified +1"
        else
            ssh-gerrit review -m '"jenkins --verified +1 failed ..."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
            log error "Jenkins --verified +1 failed ..."
        fi
    fi

    if [[ "$(check-gerrit 'code-review+2' ${GERRIT_CHANGE_NUMBER})" == "true" ]]; then
        set +e
        ssh-gerrit review -m '"this patchset gerrit trigger build successful; --submit"' --submit ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER} 2>&1 | tee ${tmpfs}/submit.log
        set -e
    else
        ssh-gerrit review -m '"can only verify now, need some people to review +2."' ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
        log warn "can only verify now, need some people to review +2"
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

# 区分由时间触发
function is_gerrit_trigger() {

    case ${GERRIT_VERSION} in

        '2.15.7')
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

# 是否为QSSI编译
function is_qssi_product() {

    local path=
    local count=0
    local result_installed=result_installed.txt

    declare -A moudule_info

    case $# in
        1)
            path=${1-}
            ;;
        *)
            retrun 1
            ;;
    esac

    if [[ ! -f result_installed.txt ]]; then
        generate_buildlist_file
    fi

    while IFS=":" read -r _path _target _;do
        #echo ${_path} '---' ${_target}
        moudule_info[${_path}]=${_target}
    done < ${result_installed}

    for tgt in ${moudule_info[${path}]} ; do

        case ${tgt} in

            out/target/product/qssi/system/*)
                let count++
                ;;

            out/target/product/qssi/system_ext/*)
                let count++
                ;;

            out/target/product/qssi/product/*)
                let count++
                ;;
        esac
    done

    if [[ ${count} -gt 0 ]]; then
        echo true
    else
        echo false
    fi
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