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
build_zip_other=


function handle_vairable() {

    # 1. 项目名
    build_zip_project=${zip_project:=}

    # 2. 同步类型
    build_zip_type=${zip_type:=}

    # 3. 同步版本
    build_zip_version=${zip_version:=}

    # 4. 其他信息
    build_zip_other=${zip_other:=}
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_zip_project = " ${build_zip_project}
    echo "build_zip_type    = " ${build_zip_type}
    echo "build_zip_version = " ${build_zip_version}
    echo "build_zip_other   = " ${build_zip_other}
    echo '-----------------------------------------'
    echo
}

function init() {

    handle_vairable
    print_variable
}

function zip_rom() {

    local zip_path  zip_name

    if [[ -n ${build_zip_other} ]]; then
        zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}/${build_zip_other}
        zip_name=${build_zip_version}_`echo ${build_zip_other} | sed s#/#_#g`
    else
        zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
        zip_name=${build_zip_version}
    fi

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

    # 初始化
    init

    # 压缩ROM版本
    zip_rom

    if [[ $? -eq 0 ]]; then
        sendEmail true
    else
        sendEmail false
    fi
}

main "$@"