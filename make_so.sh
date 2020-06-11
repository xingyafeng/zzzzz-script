#!/usr/bin/env bash

# if error;then exit
set -e

## 0.1 build board
build_board=""

## 1. 项目名称,包含[版型|客户|项目]格式
build_prj_name=$1
## 项目名
project_name=""
## 客户名
custom_version=""
## 2. 客制化路径
build_file=$2
## 3. 如: [ aeon6735_65c_s_l1|magc6580_we_l|yunovo| ** ]
build_device=
## 4. 编译类型 如: [user|userdebug|eng]
build_type=""

# exec shell
shellfs=$0
# debug switch
DEBUG=false

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

function prepare() {

    ## 0.1 build board [版型]
    if [[ -n "$yunovo_board" ]];then
        build_board=`remove_space_for_vairable "$yunovo_board"`
    else
        log error "The yunovo_board has error, please check it ."
    fi

    ## 0.2 yunovo custom [客户]
    if [[ -z "$yunovo_custom" ]];then
        log error "The yunovo_custom has error, please check it ."
    fi

    ## 0.3 yunovo project [项目]
    if [[ -z "$yunovo_project" ]];then
        log error "The yunovo_project has error, please check it ."
    fi

    cd_to_gettop

    ## 0.4 build_device [设备]
    build_device=`get_device_type`
}

function handle_vairable() {

    ## ------------------------------------------------------------------------ 对变量进行校验

    ## 1. build project name
    build_prj_name=`remove_space_for_vairable "${build_prj_name}"`
    project_name=${build_prj_name%%_*}
    custom_version=`echo ${build_prj_name##*_} | tr 'a-z' 'A-Z'`
    build_prj_name=${project_name}_${custom_version}

    if [[ -z "$project_name" ||  -z "$custom_version" ]];then
        log error "The project_name or custom_version is null, please check it."
    fi

    ## 2. build file
    build_file=`remove_space_for_vairable "$build_file"`
    if [[ "`echo ${build_file} | egrep /`" ]];then
        prefect_name=${build_file}
    else
        log error "The build_file has error, please check it ."
    fi

    ## 3. build device
    if [[ "`is_build_device`" == "false" || -z ${build_device} ]];then
        log error "The build_device has error, please check it."
    fi

    ## 4. build type
    build_type=${yunovo_type:=user}

    # 检查编译类型是否符合要求
    if [[ "`is_build_type`" == "false" ]];then
        ## 若jenkins填写不规范，默认为user
        build_type=user
    fi

    # 展讯项目,支持eng版本. 当选择了eng,默认赋值userdebug
    if [[ "`is_sc_project`" == "true" ]]; then
        case ${build_type} in
            eng)
                build_type=userdebug
                ;;
            *)
                :
                ;;
        esac
    fi

    handle_common_para
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_prj_name     = " ${build_prj_name}
    echo "project_name       = " ${project_name}
    echo "custom_version     = " ${custom_version}
    echo '-----------------------------------------'
    echo "prefect_name       = " ${prefect_name}
    echo '-----------------------------------------'
    echo "build_device       = " ${build_device}
    echo "build_type         = " ${build_type}
    echo '-----------------------------------------'
    echo "lunch_project      = " ${lunch_project}
    echo '-----------------------------------------'
    echo "manifest branch    = " ${manifest_branchN}
    echo "manifest path      = " ${manifest_path}
    echo '-----------------------------------------'
    echo "\$1 = $1"
    echo "\$2 = $2"
    echo '-----------------------------------------'
    echo
}

## 初始化 Jenkins参数
function init()
{
    prepare

    if [[ -n ${build_prj_name} && -n ${build_device} && -n ${build_file} ]];then
        handle_vairable
        print_variable ${build_prj_name} ${build_version} ${build_device} ${build_type} ${build_file}
    else
        log error "参数不正确，请检查传入参数 ..."
    fi
}

function sync_so_to_f1() {

    local DEST_PATH=""
    local custom_name=""
    local service_p=${rom_p}/share_nxos/SO

    if [[ "`is_zen_project`" == "true" ]];then
        BASE_PATH=${version_p}/`echo ${project_name} | tr 'a-z' 'A-Z'`/${custom_version}
    else
        custom_name=${project_name}\_${custom_version}
        BASE_PATH=${version_p}/${project_name}/${custom_name}
    fi

    DEST_PATH=${BASE_PATH}/${time_for_version}

    #show_vir "dest path = "${DEST_PATH}
    #show_vir "so   path = "${so_path}

    if [[ ! -d ${DEST_PATH} ]]; then
        mkdir -p ${DEST_PATH}
    fi

    if [[ -d ${so_path} ]]; then
        mv -v ${so_path} ${DEST_PATH}
        show_vip "Backup so end ..."
    else
        log error "The audio_para dir no found."
    fi

    if [[ -d ${version_p} ]]; then
        echo "rsync -av ${version_p}/ ${git_username}@${f1_server}:${service_p}"
        rsync -av ${version_p}/ ${git_username}@${f1_server}:${service_p}
    fi

    if [[ -d ${so_path} ]]; then
        rm -rf ${so_path}/*
    fi

    if [[ -d ${version_p} ]]; then
        rm -rf ${version_p}/*
    fi

    show_vip "sync end ..."
}

function make_so() {

    local audio_para_p=`get_build_var MTK_PATH_SOURCE`/external/nvram/libcustom_nvram
    local so_file=system/lib/libcustom_nvram.so

    # 1. 从仓库或者指定地方 拿到最新的音频参数文件

    # 2. 编译so文件
    if [[ -f ${OUT}/${so_file} ]]; then
        rm -rf ${OUT}/${so_file} ${OUT}/obj/SHARED_LIBRARIES/libcustom_nvram_intermediates
    else
        __err "此版本未完整编译，请完整编译后再构建."
        return 1
    fi

    show_vip "mmm audio para start ..."

    mmm -j28 ${audio_para_p}

    show_vip "mmm audio para end ..."

    # 3. 备份so文件
    if [[ -f ${OUT}/${so_file} ]]; then
        cp -f ${OUT}/${so_file} ${so_path}/
    fi

    sync_so_to_f1
}

function main() {

    local so_path=${tmpfs}/audio_para

    init

    if [[ "`is_yunovo_server`" == "true" ]];then

        version_p=~/.jenkins_version_make_os

        if [[ ! -d ${version_p} ]]; then
            mkdir -p ${version_p}
        fi

        if [[ ! -d ${so_path} ]]; then
            mkdir -p ${so_path}
        fi

        show_vip "--> make audio para start ." && log debug "--> make audio para start ."
    else
         log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        ### 初始化环境变量
        if [[ "`is_check_lunch`" == "no lunch" ]];then
            source_init
        else
            print_env
        fi
    fi

    make_so

    if [[ "`is_yunovo_server`" == "true" ]];then
        show_vip "--> make audio para end ." && log debug "--> make audio para end ."
    else
         log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi
}

main $@