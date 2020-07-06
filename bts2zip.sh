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
# 6. vendor
bts_vendor=

# 处理公共变量
function handle_common_variable() {

    # 打包前，需要确定两个参数，zip_name和zip_path
    if [[ -n ${bts_perso} ]]; then
        preso_ver=`echo ${bts_perso} | awk -F/ '{print $1}'`
        preso_num=`get_file_name ${bts_perso}` && preso_num=`get_perso_num ${preso_num}` # perso号 倒数第五位

        perso_p=${rom_p}/${build_bts_project}/perso/`echo ${build_bts_version} | sed s/v//`/${bts_perso}

        zip_name=bts_${build_bts_project}_${build_bts_version}_${preso_ver}_${preso_num}
        zip_path=${rom_p}/${build_bts_project}/${build_bts_type}/${build_bts_version}
    elif [[ -n ${build_bts_more} ]]; then
        zip_name=bts_${build_bts_project}_${build_bts_version}_`echo ${build_bts_more} | sed s#/#_#g`
        zip_path=${rom_p}/${build_bts_project}/${build_bts_type}/${build_bts_version}/${build_bts_more}
    else
        if [[ -n "${bts_vendor}" ]]; then
            perso_p=${rom_p}/${build_bts_project}/perso/`echo ${build_bts_version} | sed s/v//`/${bts_vendor}
        fi

        zip_name=bts_${build_bts_project}_${build_bts_version}
        zip_path=${rom_p}/${build_bts_project}/${build_bts_type}/${build_bts_version}
    fi
}

function handle_vairable() {

    # 1. 项目名
    build_bts_project=${bts_project:=}

    # 2. 同步类型
    build_bts_type=${bts_type:=}

    # 3. 同步版本
    build_bts_version=${bts_version:=}

    # 4. 其他信息
    case "`basename ${bts_more}`" in

        *simlock)
            build_bts_more=${bts_more:=}
            ;;

        2*.mbn)
            bts_vendor=${bts_more:=}
            ;;

        *)
            # person版本
            bts_perso=${bts_more:=}
            ;;
    esac

    handle_common_variable
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_bts_project = " ${build_bts_project}
    echo "build_bts_type    = " ${build_bts_type}
    echo "build_bts_version = " ${build_bts_version}

    if [[ -n ${bts_perso} ]]; then
        echo "build_bts_more    = " ${bts_perso}
    elif [[ -n ${build_bts_more} ]];then
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

    declare -a images

    pushd ${zip_path} > /dev/null

    images[${#images[@]}]=`check_if_oem_exists`
    images[${#images[@]}]=`check_if_boot_exists`

    # perso目录下不存在时，需要去寻找主版本下的system.img
    if [[ -z ${bts_perso} ]]; then
        images[${#images[@]}]=`check_if_system_exists`
        #处理 主目录下的vendor ^V.*D0.mbn
        images[${#images[@]}]=`check_if_vendor_exists`
    else
        #处理 主目录下的vendor ^v.*d0.mbn, 当存在多个时，取与perso num对于的img文件
        pushd `dirname ${perso_p}` > /dev/null
        images[${#images[@]}]=`check_if_vendor_exists`
        popd > /dev/null
    fi

    images[${#images[@]}]=`check_if_recovery_exists`
    images[${#images[@]}]=`check_if_userdata_exists`

    show_vig "images = ${images[@]} ${bts_perso}"

    if [[ -d ${zip_path} && -n ${zip_name} ]]; then
        time enhance_zip
    else
        log error "It is the ${zip_path} or ${zip_name} has error."
    fi

    popd > /dev/null
}

# 邮件功能
function sendEmail() {

    if [[ -n ${build_bts_more} ]]; then
        python ${script_p}/extend/sendemail2bts.py ${build_bts_project} ${build_bts_type} ${build_bts_version}/${build_bts_more}/${zip_name}.zip ${BUILD_USER_EMAIL} ${isSend}
    else
        python ${script_p}/extend/sendemail2bts.py ${build_bts_project} ${build_bts_type} ${build_bts_version}/${zip_name}.zip ${BUILD_USER_EMAIL} ${isSend}
    fi
}

function main() {

    local rom_p=/mfs_tablet/teleweb
    local zip_path  zip_name
    local perso_p=
    local isSend=

    case $# in

        # --------------------------------------- 自由风格
        0)
            # 初始化
            init

            # 压缩bts zip
            zip_bts

            # 备份bts zip
            backup_zip_to_teleweb
            if [[ $? -eq 0 ]]; then
                isSend=true
            else
                isSend=false
            fi

            sendEmail
        ;;

        # --------------------------------------- pipeline 风格
        1)
            # 初始化
            init

            case $@ in

                build)
                    zip_bts
                    ;;

                backup)
                    backup_zip_to_teleweb
                    ;;
            esac
        ;;

        *)
            log error "参数识别错误..."
        ;;
    esac
}

main $@