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
# 5.perso
build_zip_perso=
preso_ver=
preso_num=

function handle_vairable() {

    # 1. 项目名
    build_zip_project=${zip_project:=}

    # 2. 同步类型
    build_zip_type=${zip_type:=}

    # 3. 同步版本
    build_zip_version=${zip_version:=}

    # 4. 其他信息
    build_zip_other=${zip_other:=}

    # 5. person版本
    build_zip_perso=${zip_perso:=}
    if [[ -n ${build_zip_perso} ]]; then
        preso_ver=`echo ${build_zip_perso} | awk -F/ '{print $1}'`
        preso_num=`get_file_name ${build_zip_perso} | sed 's/.*\(..\)$/\1/' | sed 's/0//'`

        perso_p=${rom_p}/${build_zip_project}/perso/`echo ${build_zip_version} | sed s/v//`/${build_zip_perso}

        zip_name=bts_${build_zip_project}_${build_zip_version}_${preso_ver}_${preso_num}
    else
        zip_name=bts_${build_zip_project}_${build_zip_version}
    fi

    zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
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

    if [[ -n ${build_zip_perso} ]]; then
        echo "build_zip_perso   = " ${build_zip_perso}
        echo "preso_ver         = " ${preso_ver}
        echo "preso_num         = " ${preso_num}
        echo "perso_p           = " ${perso_p}
        echo '-----------------------------------------'
    fi

    echo
}

function init() {

    handle_vairable
    print_variable
}

function zip_bts() {

    declare -a image

    pushd ${zip_path} > /dev/null

    image[${#image[@]}]=`check_if_boot_exists`

    if [[ -z ${build_zip_perso} ]]; then
        image[${#image[@]}]=`check_if_system_exists`
    fi

    image[${#image[@]}]=`check_if_recovery_exists`
    image[${#image[@]}]=`check_if_userdata_exists`

    show_vig "image = ${image[@]}"

    if [[ -d ${zip_path} && -n ${zip_name} ]]; then
        time enhance_zip
    else
        log error "It is the ${zip_path} or ${zip_name} has error."
    fi

    popd > /dev/null
}

function main() {

    local rom_p=/mfs_tablet/teleweb
    local zip_path  zip_name
    local perso_p=

    # 初始化
    init

    # 压缩ROM版本
    zip_bts
}

main $@