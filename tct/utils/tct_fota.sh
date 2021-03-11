#!/usr/bin/env bash

function update_base_version() {

    local char=${1:-}
    local baseversion=TCL_9048S_8.1.0_8.2.3

    if [[ -z ${char} ]]; then
        log error "The ${char} is null ..."
    fi

    sed -i s/${baseversion}/${baseversion}_${char}/g ${prexml}
}

function update_from_version() {

    local version=${1:-}
    local from_version=8.2.3

    if [[ -z ${version} ]]; then
        log error "The ${version} is null ..."
    fi

    sed -i s/${from_version}/${version}/g ${prexml}
}

function update_to_version() {

    local version=${1:-}
    local to_version=8.1.0

    if [[ -z ${version} ]]; then
        log error "The ${version} is null ..."
    fi

    sed -i s/${to_version}/${version}/g ${prexml}
}

function update_size() {

    local file=${1:-}
    local size=2862528

    if [[ -z ${version} || ! -f ${file} ]]; then
        log error "The ${version} is null ..."
    fi

    sed -i s/${size}/$(get_file_size ${file})/g ${prexml}
}

function update_time() {

    local time=2018-05-23

    sed -i s/${time}/$(date +"%Y-%m-%d")/g ${prexml}
}

function update_device_name() {

    local devname=9048S

    sed -i s/${devname}/${device_name}/g ${prexml}
}

# 初始化备份的文件名
function init_copy_fota() {

    copyfs=()

    copyfs[${#copyfs[@]}]=update_rkey.zip
    copyfs[${#copyfs[@]}]=update_tkey.zip
    copyfs[${#copyfs[@]}]=downgrade_rkey.zip
    copyfs[${#copyfs[@]}]=$(ls TCL_${device_name}_${build_from_version}_${build_to_version}_*.xml)
    copyfs[${#copyfs[@]}]=$(ls TCL_${device_name}_${build_to_version}_${build_from_version}_*.xml)
}

# 备份FOTA版本
function copy_fota_version() {

    local ota_path=${mfs_p}/${build_project}/fota
    local DEST_PATH=

    if ${userdebug}; then
        local prj_path=${build_from_version}_${build_to_version}_userdebug_fota_`date +"%Y-%m-%d_%H-%M-%S"`
    else
        local prj_path=${build_from_version}_${build_to_version}_fota_`date +"%Y-%m-%d_%H-%M-%S"`
    fi

    DEST_PATH=${ota_path}/${prj_path}

    init_copy_fota
    enhance_copy_file '.' ${DEST_PATH}

    echo
    show_vip "--> copy fota image finish ..."
}

# 拿到tools/JrdDiffTool仓库的分支名
function get_tools_branch() {

    case ${build_project} in

        thor84gvzw)
            tools_branch_name='thor84g_vzw_1.0'
            ;;

        transformervzw)
            tools_branch_name='TransformerVZW'
        ;;

        *)
            tools_branch_name=''
        ;;
    esac
}

function get_device_name() {

    project_name_src=$(dirname ${build_from_more})
    project_name_tgt=$(dirname ${build_to_more})

    if [[ ${project_name_src} != ${project_name_tgt} ]]; then
        log error "project don't matchup ..."
    fi

    case ${project_name_src} in

        KIDS)
            device_name="9049L"
            ;;
        *)
            device_name="9048S"
            ;;
    esac
}

function get_custom_flag() {

    local image=${1:-}

    if [[ -n ${image} ]]; then
        cat P* | egrep -w ${image} | sed 's%.*rename_prefix="%%'| sed 's%".*%%' | head -1
    fi
}