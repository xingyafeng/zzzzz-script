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

# perso
build_zip_perso=
perso_ver=
perso_num=

# teleweb路径
teleweb_p=/mfs_tablet/zip/rom

# 处理公共变量
function handle_common_variable() {

    if [[ -n ${build_zip_more} ]]; then

        if [[ "`is_perso_project`" == "true" ]]; then
            # 处理不同perso,识别项目那些分区存在perso
            preso_ver=`echo ${zip_perso} | awk -F/ '{print $1}'`
            preso_num=`get_file_name ${zip_perso}` && preso_num=`get_perso_num ${preso_num}` # perso号 倒数第五位
            perso_p=${rom_p}/${build_zip_project}/perso/`echo ${build_zip_version} | sed s/v//`/${zip_perso}

            # 此版本需要更换路径.
            zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
            zip_name=${build_zip_version}

            teleweb_p=${teleweb_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
        else
            zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}/${build_zip_more}
            zip_name=${build_zip_version}_`echo ${build_zip_more} | sed s%/%_%g`

            teleweb_p=${teleweb_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}/${build_zip_more}
        fi
    else
        zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
        zip_name=${build_zip_project}_MainSW_${build_zip_version}_V01

        teleweb_p=${teleweb_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
    fi

    zip_p=${tmpfs}/HZNPI/HDT/product/${build_zip_project}/data


    # 压缩指定路径
    if [[ ! -d ${zip_p}  ]]; then
        mkdir -p ${zip_p}
    fi

    if [[ ! -d ${teleweb_p} ]]; then
        sudo mkdir -p ${teleweb_p}
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
    if [[ -n ${build_zip_more}  ]]; then
        case "`basename ${build_zip_more}`" in

            *)
                # person版本
                zip_perso=${build_zip_more:=}
                ;;
        esac
    fi

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

    if [[ -n ${build_zip_more} ]]; then
        echo '-----------------------------------------'
        echo "build_zip_more    = " ${build_zip_more}
    fi

    if [[ "`is_perso_project`" == "true" ]]; then
        echo "zip_perso         = " ${zip_perso}
        echo "preso_ver         = " ${preso_ver}
        echo "preso_num         = " ${preso_num}
        echo "perso_p           = " ${perso_p}
    fi

    echo '-----------------------------------------'
    echo
}

function init() {

    handle_vairable
    print_variable
}

function zip_perso() {

    declare -a images

    pushd `dirname ${perso_p}` > /dev/null

    images[${#images[@]}]=`check_if_system_exists`
    images[${#images[@]}]=`check_if_vendor_exists`

    show_vig "images = ${images[@]}"

    popd > /dev/null
}

function zip_rom() {

    local tmpzip=${tmpfs}/zip

    if [[ -d ${zip_path} && -n ${zip_name} ]]; then

        pushd ${zip_path} > /dev/null

        #处理压缩包名称,后面增加Teleweb字眼
        zip_name=${zip_name}-Teleweb

        cp -vf *.mbn ${zip_p}

        pushd ${tmpfs} > /dev/null
        zip -1vr ${tmpzip}/${zip_name}.zip HZNPI/

        if [[ -d HZNPI ]]; then
            rm -rf HZNPI/ &
        fi

        popd > /dev/null

        popd > /dev/null
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

    local rom_p=/mfs_tablet/teleweb
    local zip_path=
    local zip_name=
    local zip_p=

    local perso_p=

    # 初始化
    init

    if [[ "`is_perso_project`" == "true" ]]; then

        # 压缩perso版本
        zip_perso
    fi

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
