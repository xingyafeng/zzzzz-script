#!/bin/bash

## if error then exit
set -e

# 0. 构建OTA版本的类型
build_rom_type=
# 1. 如: [aeon6735_65c_s_l1|magc6580_we_l|yunovo| **]
build_device=
# 2. 编译类型 如: [user|userdebug|eng]
build_type=""
# 3. 签名类型 [非公版签名|公版签名]
build_signature_type=""
# 4. 清除data分区
build_clean_data=""
# 5. 是否差分lk.bin
build_lk=""
# 6. 是否差分preloader.bin
build_preloader=""
# 7. 收件人邮箱
build_email=""
# 8. 抄送人邮箱
build_cc_address=""
# 9. 是否更新源代码
build_update_code=""

###############################################################
# ota pre-version from to cur-version
ota_previous=
ota_current=

# 项目名称
build_prj_name=

# 客制化路径名 e.g : yz/zx
custom_p=

################################# common variate
shellfs=$0

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

# 预差分版本
declare -a pre_ver

# 处理版本号
function handle_common_version() {

    local serverN='\\f1.y'

    # 1.解析版本号
    if [[ ${ota_current} =~ ${hw_version} ]];then

        if [[ ${ota_current} =~ S[1-9] ]]; then
            software_prev_version=${ota_previous} && software_prev_version=${software_prev_version##*_} && software_prev_version=${software_prev_version%%.*}
            software_curr_version=${ota_current}  && software_curr_version=${software_curr_version##*_} && software_curr_version=${software_curr_version%%.*}
            firmware_prev_version=${ota_previous} && firmware_prev_version=${firmware_prev_version%.*} && firmware_prev_version=${firmware_prev_version##*.}
            firmware_curr_version=${ota_current} && firmware_curr_version=${firmware_curr_version%.*} && firmware_curr_version=${firmware_curr_version##*.}
            custom_prev_project=${ota_previous} && custom_prev_project=${custom_prev_project%.*} && custom_prev_project=${custom_prev_project%.*} && custom_prev_project=${custom_prev_project##*.}
            custom_project=${ota_current} && custom_project=${custom_project%.*} && custom_project=${custom_project%.*} && custom_project=${custom_project##*.}
            custom_version=${ota_current} && custom_version=${custom_version%%_*}

        elif [[ ${ota_current} =~ V[1-9] ]]; then
            local previous=${ota_previous%.*}
            local current=${ota_current%.*}

            software_prev_version=`echo ${ota_previous} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $1 }'`
            software_curr_version=`echo ${ota_current}  | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $1 }'`
            firmware_prev_version=`echo ${previous}| awk -F '_' '{ print $3 }' | awk -F '.' '{ print $(NF-1) "." $(NF) }'`
            firmware_curr_version=`echo ${current} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $(NF-1) "." $(NF) }'`
            custom_prev_project=`echo ${ota_previous} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $2 }'`
            custom_project=`echo ${ota_current} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $2 }'`
            custom_version=`echo ${ota_current} | awk -F '_' '{ print $1 }'`
        fi
    else
        local previous=${ota_previous%.*}
        local current=${ota_current%.*}

        software_prev_version=`echo ${ota_previous} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $1 }'`
        software_curr_version=`echo ${ota_current} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $1 }'`
        firmware_prev_version=`echo ${previous}| awk -F '_' '{ print $3 }' | awk -F '.' '{ print $(NF-1) "." $(NF) }'`
        firmware_curr_version=`echo ${current} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $(NF-1) "." $(NF) }'`
        custom_prev_project=`echo ${ota_previous} | awk -F '_' '{ print $2 }'`
        custom_project=`echo ${ota_current} | awk -F '_' '{ print $2 }'`
        custom_version=`echo ${ota_current} | awk -F '_' '{ print $1 }'`
    fi

    if [[ ${custom_prev_project} != ${custom_project} ]]; then
        log error "不允许跨项目升级 ..."
    fi

    # 2.OTA版本目录结构
    ota_version_path=${ota_local_path}/${custom_project}/${custom_project}\_${custom_version}/${software_curr_version}.${firmware_curr_version}\_for\_${software_prev_version}.${firmware_prev_version}

    # 3.OTA文件名
    OTA_FILE=${custom_project}\_${custom_version}\_${hw_version}\_${software_curr_version}.${firmware_curr_version}\_for\_${software_prev_version}.${firmware_prev_version}.zip

    # 5. build_prj_name
    build_prj_name=${custom_project}_${custom_version}

    # 6. share_smb_ota_p
    share_smb_ota_p=${serverN}\\share_nxos\\NXOS\\OTA\\${custom_project}\\${build_prj_name}
}

function handler_variable()
{
    local tmp=

    # 0. 构建OTA版本的类型
    build_rom_type=${yunovo_rom_type:-}
    if [[ -z "${build_rom_type}" ]];then
        log error "The build_rom_type has errors, please check it."
    else
        if [[ `check_rom_type` == false ]]; then
            log error "The build_rom_type has errors, please check it ."
        fi

        # 拿到客制化目录,反推客制化 版型/客户/项目
        if [[ -n ${yunovo_form_version} ]]; then
            custom_p=`ssh ${git_username}@${f1_server} find ${share_rom_p}/${build_rom_type} -name ${yunovo_form_version} | awk -F/ '{ print $(NF-2) "/" $(NF-1) }'`
            if [[ -z ${custom_p} ]]; then
                log error "服务器未发现版本: ${yunovo_form_version}, 请确认服务器是否存在?"
            fi
        else
            log error "服务器未发现版本: yunovo_form_version, 请确认服务器是否存在?"
        fi

        # 版型/客户/项目
        yunovo_board=`echo ${custom_p} | awk -F/  '{ print $1 }' | tr 'A-Z' 'a-z'`
        if [[ -z ${yunovo_board} ]]; then
            log error "版型为空."
        fi

        tmp=`echo ${custom_p} | awk -F/ '{ print $2 }' | tr 'A-Z' 'a-z'`

        yunovo_custom=`echo ${tmp}  | awk -F '-' '{ print $1 }'`
        if [[ -z ${yunovo_custom} ]]; then
            log error "客户名为空."
        fi

        yunovo_project=`echo ${tmp} | awk -F '-' '{ print $2 }'`
        if [[ -z ${yunovo_project} ]]; then
            log error "项目名为空."
        fi

        cd_to_gettop
    fi

    # 1. build_device
    build_device=`get_device_type`
    if [[ "`is_build_device`" == "false" || -z ${build_device} ]];then
        log error "The build_device has errors, please check it ."
    fi

    # 2. build_type
    build_type=${yunovo_type:-user}

    # 3. 签名类型
    build_signature_type=${yunovo_signature_type:-false}

    # 4. 是否清除data分区
    build_clean_data=${yunovo_clean_data:-false}

    # 5. 是否差分lk.bin
    build_lk=${yunovo_lk:-false}

    # 6. 是否差分preloader.bin
    build_preloader=${yunovo_preloader:-false}

    # 7. 发件人邮箱
    build_email=${yunovo_email:="notify@yunovo.cn"}

    # 8. 抄送邮件人邮箱
    build_cc_address=${yunovo_carboncopy:-}

    # 9. 是否更新源代码
    build_update_code=${yunovo_update_code:-false}

    if [[ -n "${yunovo_form_version}" && -n "${yunovo_to_version}" ]];then
        pre_ver=(`ssh jenkins@f1.y enhance_cpotafs.sh ${build_rom_type} "${yunovo_form_version} ${yunovo_to_version}"`)

        if [[ "${pre_ver}" == "null" ]]; then
            log error "cpotafs.sh fail ..."
        fi

        if [[ ${#pre_ver[*]} -ne 2 ]]; then
            log error "The parameter format is incorrect ..."
        fi

        ota_previous=${pre_ver[0]}
        ota_current=${pre_ver[1]}
    else
        log error "The yunovo_to_version has errors. please check it ."
    fi

    # -----------------------------------------------------------

    handle_common_version

}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "builder = " ${build_builder}
    echo '-----------------------------------------'
    echo "yunovo_board          = " ${yunovo_board}
    echo "yunovo_custom         = " ${yunovo_custom}
    echo "yunovo_project        = " ${yunovo_project}
    echo "custom_p              = " ${custom_p}
    echo "yunovo_form_version   = " ${custom_project}/${custom_version}/${yunovo_form_version}
    echo "yunovo_to_version     = " ${custom_project}/${custom_version}/${yunovo_to_version}
    echo '-----------------------------------------'
    echo "build_type            = " ${build_type}
    echo "build_device          = " ${build_device}
    echo "build_clean_data      = " ${build_clean_data}
    echo "build_update_code     = " ${build_update_code}
    echo "build_signature_type  = " ${build_signature_type}
    echo "build_lk              = " ${build_lk}
    echo "build_preloader       = " ${build_preloader}
    echo "build_rom_type        = " ${build_rom_type}
    echo '-----------------------------------------'
    echo "ota_previous          = " ${ota_previous}
    echo "ota_current           = " ${ota_current}
    echo '-----------------------------------------'
    echo "build_prj_name        = " ${build_prj_name}
    echo "custom_project        = " ${custom_project}
    echo "custom_version        = " ${custom_version}
    echo "software_prev_version = " ${software_prev_version}
    echo "software_curr_version = " ${software_curr_version}
    echo "firmware_prev_version = " ${firmware_prev_version}
    echo "firmware_curr_version = " ${firmware_curr_version}
    echo "share_rom_p           = " ${share_rom_p}
    echo '-----------------------------------------'
    echo "manifest branch       = ${manifest_branchN}"
    echo "manifest path         = ${manifest_path}"
    echo '-----------------------------------------'
    echo "OTA_FILE              = " ${OTA_FILE}
    echo '-----------------------------------------'
    echo
}

# 同步OTA至服务器
function sync_ota_server()
{
    if [[ -d ${ota_local_path} ]];then
        rsync -av ${ota_local_path} ${git_username}@${f1_server}:${test_path}

        if [[ $? -eq 0 ]];then
            rm ${ota_local_path}/* -r

            if [[ -f ${tmpfs}/jenkins.ini ]]; then
                rm ${tmpfs}/jenkins.ini
            fi
        else
            log error "sync ota file failed."
        fi
    fi
}

# 构建差分包
function make_inc {

    local cmd=
    local OTA_FILE=${ota_version_path}/${OTA_FILE}

    local ota_previous=${ota_path}/${yunovo_form_version}/${ota_previous}
    local ota_current=${ota_path}/${yunovo_to_version}/${ota_current}

    local inc_pack="-i ${ota_previous} ${ota_current} ${OTA_FILE}"

    # 1. 将OTA基准包同步到编译服务器上
    rsync -av ${git_username}@${f1_server}:${rom_p}/otafs/${yunovo_board}/${yunovo_custom}-${yunovo_project}/ ${ota_path}
    if [[ ! -f "${ota_previous}" ]]; then
        log error "The ${ota_previous} file was not found ..."
    fi

    if [[ ! -f "${ota_current}" ]]; then
        log error "The ${ota_current} file was not found ..."
    fi

    # 2. 将lk.bin和preloader.bin文件同步到编译服务器上
    if [[ "`is_ota_preloader`" == "true" ]];then
        rsync -av ${git_username}@${f1_server}:${rom_p}/otafs/binfs ${ota_path}

        echo
        echo "md5:"
        md5sum ${ota_path}/binfs/lk.bin
        md5sum ${ota_path}/binfs/preloader_`get-target-device`.bin
        echo
    fi

    echo
    __green__ "The ota previous version = ${ota_previous}"
    __green__ "The ota current  version = ${ota_current}"
    echo

    cmd="${ota_core_py} -k ${signature_type_p} ${inc_args} ${inc_pack}"

    print_and_exec_cmd

    if [[ $? -eq 0 ]]; then
        echo
        echo "md5:"
        md5sum ${ota_previous}
        md5sum ${ota_current}

        echo
        show_vip "--> make_inc successful ..."
    fi
}

function prepare() {

    # 初始化公共变量,其不依赖各种环境因素
    handle_common_variable
}

# 初始化
function init() {

    prepare
    handler_variable
    print_variable

    if [[ ! -d ${ota_local_path} ]];then
        mkdir -p ${ota_local_path}
    fi

    if [[ ! -d ${ota_version_path} ]];then
        mkdir -p ${ota_version_path}
    fi
}

function main()
{
    local ota_local_path=~/OTA
    local ota_version_path=""

    local software_prev_version=""
    local software_curr_version=""
    local custom_project=""
    local custom_version=""
    local firmware_prev_version=""
    local firmware_curr_version=""

    local ota_path=${tmpfs}/otafs

    init

    if [[ "`is_yunovo_server`" == "true" ]];then
        echo
        show_vip "--> make inc start ..."

        if [[ ${build_update_code} == "true" ]]; then
            download_mirror
            down_load_yunovo_source_code
        fi
    else
        log error "The server is not running on the s1 s3 s4 s5 s6 s7 happysongs."
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        ### 初始化环境变量
        if [[ "`is_check_lunch`" == "no lunch" ]];then
            handle_lunch_project
            source_init
            handle_common_variable_for_inc
        else
            print_env
        fi
    fi

    if [[ "`is_yunovo_project`" == "true" ]];then
        make_inc

        if [[ $? -eq 0 ]]; then
            send_email_to_ota_builder
        fi
    else
        log error "The current directory is not in the android root directory."
    fi

    # 同步OTA差分包至文件服务器
    if sync_ota_server; then
        echo
        show_vip "--> make inc end ..."
    else
        log error "同步OTA失败 ..."
    fi
}

main
