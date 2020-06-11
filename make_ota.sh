#!/bin/bash

## if error then exit
set -e

# 1. 如: [aeon6735_65c_s_l1|magc6580_we_l|yunovo| **]
build_device=$1
# 2. 编译类型 如: [user|userdebug|eng]
build_type=""
# 3. 签名类型 [非公版签名|公版签名]
build_signature_type=""
# 4. 清除data分区
build_clean_data=""

## ota from to version
ota_from_version=$2
ota_to_version=$3

################################# common variate
shellfs=$0

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

# 处理公共版本号
function handle_common_version() {

    # 1.解析版本号
    if [[ ${ota_current} =~ ${hw_version} ]];then

        if [[ ${ota_current} =~ "S1" ]]; then
            software_version=${ota_to_version} && software_version=${software_version##*_} && software_version=${software_version%%.*}
            custom_project=${ota_previous} && custom_project=${custom_project%.*} && custom_project=${custom_project%.*} && custom_project=${custom_project##*.}
            custom_version=${ota_previous} && custom_version=${custom_version%%_*}
            firmware_prev_version=${ota_previous} && firmware_prev_version=${firmware_prev_version%.*} && firmware_prev_version=${firmware_prev_version##*.}
            firmware_curr_version=${ota_current} && firmware_curr_version=${firmware_curr_version%.*} && firmware_curr_version=${firmware_curr_version##*.}

        elif [[ ${ota_current} =~ "V1" ]]; then
            local previous=${ota_previous%.*}
            local current=${ota_current%.*}

            software_version=`echo ${ota_from_version} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $1 }'`
            firmware_prev_version=`echo ${previous}| awk -F '_' '{ print $3 }' | awk -F '.' '{ print $(NF-1) "." $(NF) }'`
            firmware_curr_version=`echo ${current} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $(NF-1) "." $(NF) }'`
            custom_project=`echo ${ota_to_version} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $2 }'`
            custom_version=`echo ${ota_to_version} | awk -F '_' '{ print $1 }'`
        fi
    else
        local previous=${ota_previous%.*}
        local current=${ota_current%.*}

        software_version=`echo ${ota_from_version} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $1 }'`
        firmware_prev_version=`echo ${previous}| awk -F '_' '{ print $3 }' | awk -F '.' '{ print $(NF-1) "." $(NF) }'`
        firmware_curr_version=`echo ${current} | awk -F '_' '{ print $3 }' | awk -F '.' '{ print $(NF-1) "." $(NF) }'`
        custom_project=`echo ${ota_to_version} | awk -F '_' '{ print $2 }'`
        custom_version=`echo ${ota_to_version} | awk -F '_' '{ print $1 }'`
    fi

    # 2.OTA版本目录结构
    ota_version_path=${ota_local_path}/${custom_project}/${custom_project}\_${custom_version}/${software_version}.${firmware_curr_version}\_for\_${software_version}.${firmware_prev_version}

    # 3.OTA文件名
    OTA_FILE=${custom_project}\_${custom_version}\_${hw_version}\_${software_version}.${firmware_curr_version}\_for\_${software_version}.${firmware_prev_version}.zip

    # 4. 更新签名
    if [[ "${build_signature_type}" == "true" ]]; then

        testkey=${tmpfs}/NxCustomSecurity/testkey

        # 下载云智签名
        download_and_update_apk_repository yunovo/zenportal/NxCustomSecurity yunovo/master
    fi

    # lunch project
    handle_lunch_project
}

function handler_variable()
{
    # 1. build_device
    if [[ "`is_build_device`" == "false" || -z ${build_device} ]];then
        __err "build_device has error. please check it ."
        return 1
    fi

    # 2. build_type
    build_type=${yunovo_type:-user}

    # 3. 签名类型
    build_signature_type=${yunovo_signature_type:-false}

    # 4. 是否清除data分区
    build_clean_data=${yunovo_clean_data:-false}

    # -----------------------------------------------------------

    handle_common_version
}

function print_variable() {

    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_type            = " ${build_type}
    echo "build_device          = " ${build_device}
    echo "build_clean_data      = " ${build_clean_data}
    echo "build_signature_type  = " ${build_signature_type}
    echo '-----------------------------------------'
    echo "ota_from_version      = " ${ota_from_version}
    echo "ota_to_version        = " ${ota_to_version}
    echo '-----------------------------------------'
    echo "custom_project        = " ${custom_project}
    echo "custom_version        = " ${custom_version}
    echo "software_version      = " ${software_version}
    echo "firmware_prev_version = " ${firmware_prev_version}
    echo "firmware_curr_version = " ${firmware_curr_version}
    echo "OTA_FILE              = " ${OTA_FILE}
    echo '-----------------------------------------'
    echo "testkey               = " ${testkey}
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
            rm ${ota_path}/* -r
        else
            __err "sync_ota_server fail !"
            return 1
        fi
    fi
}

function scpfs()
{
    if [[ $# -lt 1 ]]; then
        __err "参数不正确 ..."
    fi

    if [[ ! -d ${ota_path} ]];then
        mkdir -p ${ota_path}
    fi

    for ota in "$@" ; do

        # 从f1服务器获取正确的OTA包
        scp -r ${git_username}@${f1_server}:${rom_p}/otafs/${ota} ${ota_path}

        if [[ $? -eq 0 ]];then
            __green__ "--> scp ${ota} successful ..."
        else
            __err "--> scp fail ..."
            return 1
        fi
    done

    echo
}

# 构建差分包
function make_inc {

    local preloader_bin=preloader_along8321_emmc_706m.bin
    local cmd=""

    ### 1.从f1服务器复制文件到　编译服务器上
    if [[ -n ${ota_previous} && -n ${ota_current} ]];then
        scpfs ${ota_previous} ${ota_current}
    else
        __err "ota_previous or ota_current is NULL !"
        return 1
    fi

    if [[ "`is_car_project`" == "true" || "`is_ota_preloader`" == "true" ]];then
        scpfs binfs
    fi

    ### 2.编译OTA包存放指定路径
    if [[ -e ${ota_py} && "`is_yunovo_project`" == "true" && -f ${ota_path}/${ota_previous} && -f ${ota_path}/${ota_current} ]];then

        local inc_pack="${ota_path}/${ota_previous} ${ota_path}/${ota_current} ${ota_version_path}/${OTA_FILE}"
        local extra_args=""

        if [[ "${build_clean_data}" == "true" ]];then
            extra_args="-w -i"
        else
            extra_args="-i"
        fi

        if [[ "`is_car_project`" == "true" || "`is_ota_preloader`" == "true" ]];then

            if [[ -e ${ota_path}/binfs/lk.bin && -e ${ota_path}/binfs/${preloader_bin}  ]];then
                cmd="${ota_py} -r ${ota_path}/binfs/${preloader_bin} -u ${ota_path}/binfs/lk.bin -k ${testkey} ${extra_args} ${inc_pack}"
            else
                cmd="${ota_py} -k ${testkey} ${extra_args} ${inc_pack}"
            fi
        else
            echo "------`get_android_version` "
            echo

            case `get_android_version` in

                5.1)
                    cmd="${ota_py} -k ${testkey} ${extra_args} ${inc_pack}"
                    ;;

                6.0)
                    cmd="${ota_py} -v --block -k ${testkey} -s ${mt_ota_py} ${extra_args} ${inc_pack}"
                    ;;

                *)
                    ;;
            esac

        fi

        echo ${cmd}
        echo
        eval ${cmd}

        if [[ $? -eq 0 ]]; then
            echo
            show_vip "--> make_inc successful ..."
        fi

        if [[ -d ${ota_version_path} ]];then
            cp -vf ${ota_path}/${ota_previous} ${ota_version_path}
            cp -vf ${ota_path}/${ota_current} ${ota_version_path}
            echo

            echo "md5:"
            md5sum ${ota_path}/${ota_previous}
            md5sum ${ota_path}/${ota_current}
            echo
        fi
    fi

    ### 3.将生产的OTA包和targer包备份至f1服务器上
    sync_ota_server

    echo
    show_vip "--> make inc end ..."
}

# 初始化
function init() {

    if [[ -n "${ota_from_version}" && -n "${ota_to_version}" ]];then
        handler_variable
        print_variable
    else
        __err "xargs error, please check it."
        return 1
    fi

    if [[ ! -d ${ota_local_path} ]];then
        mkdir -p ${ota_local_path}
    fi

    if [[ ! -d ${ota_version_path} ]];then
        mkdir -p ${ota_version_path}
    fi


    # source
    source_init
}

function main()
{
    local OTA_FILE=""
    local ota_local_path=~/OTA
    local ota_version_path=""

    local software_version=""
    local custom_project=""
    local custom_version=""
    local firmware_prev_version=""
    local firmware_curr_version=""

    local ota_path=${tmpfs}/otafs
    local ota_previous=${ota_from_version}
    local ota_current=${ota_to_version}

    local ota_py=./build/tools/releasetools/ota_from_target_files
    local mt_ota_py=./device/mediatek/build/releasetools/mt_ota_from_target_files
    local testkey=./build/target/product/security/testkey

    if [[ "`is_yunovo_server`" == "true" ]];then
        echo
        show_vip "--> make inc start ..."
    else
        __err "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
        return 1
    fi

    init

    if [[ "`is_yunovo_project`" == "true" ]];then
        make_inc
    else
        __err "current directory is not android !"
        return 1
    fi
}

main
