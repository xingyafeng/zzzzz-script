#!/usr/bin/env bash

# if error;then exit
set -e

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

# 1.项目名
build_bts_project=
# 2.同步类型
build_bts_type=
# 3.同步版本
build_bts_version=
# 4.更多版本
build_bts_more=
# 5.perso
bts_perso=
preso_ver=
preso_num=

function handle_vairable() {

    # 1. 项目名
    build_bts_project=${bts_project:=}

    # 2. 同步类型
    build_bts_type=${bts_type:=}

    # 3. 同步版本
    build_bts_version=${bts_version:=}

    # 4. 其他信息
    if [[ "${bts_more}" =~ "simlock" ]]; then
        build_bts_more=${bts_more:=}
    else
        build_bts_more=${bts_more:=}

        # person版本
        bts_perso=${bts_more:=}
    fi

    # 打包前，需要确定两个参数，zip_name和zip_path
    if [[ -n ${bts_perso} ]]; then
        preso_ver=`echo ${bts_perso} | awk -F/ '{print $1}'`
        preso_num=`get_file_name ${bts_perso} | sed 's/.*\(..\)$/\1/' | sed 's/0//'`

        perso_p=${rom_p}/${build_bts_project}/perso/`echo ${build_bts_version} | sed s/v//`/${bts_perso}

        zip_name=bts_${build_bts_project}_${build_bts_version}_${preso_ver}_${preso_num}
        zip_path=${rom_p}/${build_bts_project}/${build_bts_type}/${build_bts_version}
    elif [[ -n ${build_bts_more} ]]; then
        zip_name=bts_${build_bts_project}_${build_bts_version}_`echo ${build_bts_more} | sed s#/#_#g`
        zip_path=${rom_p}/${build_bts_project}/${build_bts_type}/${build_bts_version}/${build_bts_more}
    else
        zip_name=bts_${build_bts_project}_${build_bts_version}
        zip_path=${rom_p}/${build_bts_project}/${build_bts_type}/${build_bts_version}
    fi
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_bts_project = " ${build_bts_project}
    echo "build_bts_type    = " ${build_bts_type}
    echo "build_bts_version = " ${build_bts_version}

    if [[ -n ${build_bts_more} ]]; then
        echo "build_bts_more    = " ${build_bts_more}
    fi

    echo '-----------------------------------------'

    if [[ -n ${bts_perso} ]]; then
        echo "bts_perso         = " ${bts_perso}
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

    # perso目录下不存在时，需要去寻找主版本下的system.img
    if [[ -z ${bts_perso} ]]; then
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