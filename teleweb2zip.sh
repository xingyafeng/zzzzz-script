#!/usr/bin/env bash

# if error;then exit
set -e

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

# 1.项目名
build_zip_project=
# 2.同步类型
build_zip_type=
# 3.同步版本
build_zip_version=
# 4.其他版本
build_zip_more=

# 处理公共变量
function handle_common_variable() {

    if [[ -n ${build_zip_more} ]]; then
        zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}/${build_zip_more}
        zip_name=${build_zip_version}_`echo ${build_zip_more} | sed s#/#_#g`
    else
        zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
        zip_name=${build_zip_version}
    fi
}

function handle_vairable() {

    # 1. 项目名
    build_zip_project=${zip_project:=}

    # 2. 同步类型
    build_zip_type=${zip_type:=}

    # 3. 同步版本
    build_zip_version=${zip_version:=}

    # 4. 其他信息
    build_zip_more=${zip_more:=}

    # 公共变量
    handle_common_variable
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_zip_project = " ${build_zip_project}
    echo "build_zip_type    = " ${build_zip_type}
    echo "build_zip_version = " ${build_zip_version}
    echo "build_zip_more   = " ${build_zip_more}
    echo '-----------------------------------------'
    echo
}

function init() {

    handle_vairable
    print_variable
}

function zip_rom() {

    if [[ -d ${zip_path} && -n ${zip_name} ]]; then

        #处理压缩包名称,后面增加Teleweb字眼
        zip_name=${zip_name}-Teleweb

        time enhance_zip
    else
        log error "It is the ${zip_path} or ${zip_name} has error."
    fi
}

# 邮件功能
function sendEmail() {

    local isSend=

    if [[ "$1" ]]; then
        isSend=$1
    else
        log error "参数错误."
    fi

    python ${script_p}/extend/sendemail.py ${build_zip_project} ${build_zip_type} ${build_zip_version} ${BUILD_USER_EMAIL} ${isSend}
}

function main() {

    local rom_p=/mfs_tablet/0_Shenzhen
    local zip_path  zip_name

    # 初始化
    init

    # 压缩ROM版本
    zip_rom

    # 备份zip文件
    backup_zip_to_teleweb

    if [[ $? -eq 0 ]]; then
        sendEmail true
    else
        sendEmail false
    fi
}

main "$@"