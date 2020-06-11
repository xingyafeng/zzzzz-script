#!/usr/bin/env bash

#########################################################################

#1. release  包
#2. ota base 包
#3. 解压　ota base 包
#4. 挂载　release system.img
#5. 制作
    #a. 覆盖 SYSTEM
    #b. 修改 install-recovery.sh 中sha1sum值(boot.img recovery.img)
    #c. 替换 IMAGES 中的boot.img recovery.img system.img
    #d. 替换 OTA文件下的trustzone.bin
    #e. 替换 META 中的　recovery.sig
#6. 打包签名
    #a. zip -r xxx.zip xxx
    #b. java -Xmx2048m -jar signapk.jar -w testkey.x509.pem testkey.pk8 /tmp/tmp3khIEF full_aeon6735_65c_s_l1-ota-1499087511.zip
#
##########################################################################

### color red
function show_vir
{
    if [[ "$1" ]]
    then
        echo
        for ret in "$@"; do
            echo -e -n "\e[1;31m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color green
function show_vig
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;32m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color yellow
function show_viy
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;33m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color blue
function show_vib
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;34m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color purple
function show_vip
{
    if [[ "$1" ]]
    then
        echo
        for ret in "$@"; do
            echo -e -n "\e[1;35m$ret \e[0m"
        done

        echo
        echo
    fi
}

## 警告信息
function __wrn()
{
    local msg=$1

    if [[ $# -eq 1 ]];then
        :
    else
        __echo "e.g : __wrn xxx"
    fi

    if [[ "$msg" ]];then
        show_viy "$msg"
    else
        show_vir "msg is null, please check it !"
    fi
}

## 错误信息
function __err()
{
    local msg=$1

    if [[ $# -eq 1 ]];then
        :
    else
        __echo "e.g : __err xxx"
    fi

    if [[ "$msg" ]];then
        show_vir "$msg"
    else
        show_vir "msg is null, please check it !"
    fi
}

function unzip_base()
{
    if [[ -f ${base_zip} ]];then
        unzip -qn ${base_zip} -d ${base_p}

        show_vig "unzip end ."
    else
        __err "base.zip no found !"
        return 1
    fi
}

function mount_img()
{
    if [[ ! -d ${release_p}/system && -f ${release_p}/system.img ]];then
        mkdir -p ${release_p}/system
    fi

    if [[ ! -d ${release_p}/custom && -f ${release_p}/custom.img ]];then
        mkdir -p ${release_p}/custom
    fi

    ## 1. 挂载system.img
    if [[ -f ${release_p}/system.img ]];then

        if [[ ! -f ${release_p}/system.ext4.img ]];then
            ${script_p}/tools/simg2img ${release_p}/system.img ${release_p}/system.ext4.img
        fi

        if [[ -f ${release_p}/system.ext4.img ]];then
            sudo mount -t ext4 -o loop ${release_p}/system.ext4.img ${release_p}/system
        fi
    else
        __err "$release_p/system.img no found !"
        return 1
    fi

    ## 2. 挂载custom.img
    if [[ -f ${release_p}/custom.img ]];then
        if [[ ! -f ${release_p}/custom.ext4.img ]];then
            ${script_p}/tools/simg2img ${release_p}/custom.img ${release_p}/custom.ext4.img
        fi

        if [[ -f ${release_p}/custom.ext4.img ]];then
            sudo mount -t ext4 -o loop ${release_p}/custom.ext4.img ${release_p}/custom
        fi
    else
        __err "$release_p/custom.img no found !"
        return 1
    fi
}

function copy_files_to_base()
{
    local boot_sha1sum=""
    local boot_sha1sum_d=""
    local recovery_sha1sum=""
    local recovery_sha1sum_d=""

    local sh=install-recovery.sh

    # a. 覆盖SYSTEM
    if [[ -f ${release_p}/system/build.prop && -d ${base_p}/SYSTEM ]];then
        cp -r ${release_p}/system/* ${base_p}/SYSTEM 2>/dev/null
    else
        __err "$release_p/system or $base_p/SYSTEM no found !"
        return 1
    fi

    # b. 覆盖CUSTOM
    if [[ -f ${release_p}/custom/cip-build.prop && -d ${base_p}/CUSTOM ]];then
        cp -r ${release_p}/custom/* ${base_p}/CUSTOM
    else
        __err "$release_p/custom or $base_p/CUSTOM no found !"
    fi

    # c. 修改sha1sum for boot recovery
    boot_sha1sum="`sha1sum ${release_p}/boot.img | cut -d ' ' -f 1`"
    recovery_sha1sum="`sha1sum ${release_p}/recovery.img | cut -d ' ' -f 1`"

    boot_sha1sum_d="`cat ${base_p}/SYSTEM/bin/install-recovery.sh |grep EMMC:boot | cut -d ':' -f 4 | cut -d ' ' -f 1`"
    recovery_sha1sum_d="`cat ${base_p}/SYSTEM/bin/install-recovery.sh | grep EMMC:recovery | grep tony | cut -d ':' -f 4 | cut -d ';' -f 1`"

    echo
    echo "boot_sha1sum      = $boot_sha1sum"
    echo "boot_sha1sum_d    = $boot_sha1sum_d"
    echo "recovery_sha1sum  = $recovery_sha1sum"
    echo "recovery_sha1sum_d= $recovery_sha1sum_d"
    echo

    if [[ "$boot_sha1sum" != "$boot_sha1sum_d" ]];then
        sed -i "s/${boot_sha1sum_d}/${boot_sha1sum}/g" ${base_p}/SYSTEM/bin/${sh}

        if [[ $? -eq 0 ]];then
            show_vig "sed boot_sha1sum ok ."
        fi
    fi

    if [[ "$recovery_sha1sum" != "$recovery_sha1sum_d" ]];then
        sed -i "s/${recovery_sha1sum_d}/${recovery_sha1sum}/g" ${base_p}/SYSTEM/bin/${sh}

        if [[ $? -eq 0 ]];then
            show_vig "sed recovery_sha1sum ok ."
        fi
    fi

    # d. 覆盖 boot recovery system custom img
    if [[ -f ${release_p}/boot.img ]];then
        cp -vf ${release_p}/boot.img ${base_p}/IMAGES
    fi

    if [[ -f ${release_p}/recovery.img ]];then
        cp -vf ${release_p}/recovery.img ${base_p}/IMAGES
    fi

    if [[ -f ${release_p}/system.img ]];then
        cp -vf ${release_p}/system.img ${base_p}/IMAGES
    fi

    if [[ -f ${release_p}/custom.img ]];then
        cp -vf ${release_p}/custom.img ${base_p}/IMAGES
    fi

    # e. 覆盖 OTA文件下 trustzone.bin
    if [[ -f ${release_p}/trustzone.bin ]];then
        cp -vf ${release_p}/trustzone.bin ${base_p}/OTA
    fi

    # f. 替换 META 中的　recovery.sig
    if [[ -f ${release_p}/system/etc/recovery.sig ]];then
        cp -vf ${release_p}/system/etc/recovery.sig ${base_p}/META
    fi

    ## 拷贝结束后将卸载system.img
    if [[ -d ${release_p}/system ]];then
        sudo umount ${release_p}/system
    else
        __err "$release/system no found !"
    fi

    if [[ -d ${release_p}/custom ]];then
        sudo umount ${release_p}/custom
    else
        __err "$release/custom no found !"
    fi

    if [[ -d ${release_p}/system ]];then
        rm -rf ${release_p}/system
    fi

    if [[ -d ${release_p}/custom ]];then
        rm -rf ${release_p}/custom
    fi

    if [[ -f ${release_p}/system.ext4.img ]];then
        rm ${release_p}/system.ext4.img
    fi

    if [[ -f ${release_p}/custom.ext4.img ]];then
        rm ${release_p}/custom.ext4.img
    fi
}

function zip_base()
{
    local OLDP=`pwd`

    if [[ -d ${base_p} ]];then

        cd ${base_p} > /dev/null

        zip -qr tmp.zip ./*

        echo
        show_vig "zip end ."
        cd ${OLDP} > /dev/null
    fi

    if [[ -f ${base_p}/tmp.zip ]];then
        mv ${base_p}/tmp.zip base_ok.zip
    fi
}

function sign_base()
{
    if [[ -f base_ok.zip ]];then
        java -Xmx2048m -jar ${script_p}/tools/security/signapk.jar -w ${script_p}/tools/security/testkey.x509.pem ${script_p}/tools/security/testkey.pk8 base_ok.zip base_sign.zip

        show_vig "sign sucessful ..."
    fi
}

function main()
{
    if [[ $# -eq 1 ]];then
        show_vip "--- create base ota start ..."
    else
        __err "xargs error ... @@ usage: auto_create_base_ota.sh + 基准包  . 必须要刷机包,修改名称:release ..."
        return 1
    fi

    local script_p=~/workspace/script/zzzzz-script
    local release_p=release
    local base_p=base
    local base_zip=$1

    if [[ ! -d ${base_p} ]];then
        mkdir -p ${base_p}
    fi

    if [[ ! -d ${release_p} ]];then

        __err "$release_p no found !"
        return 0
    fi

    #1. 解压相近的基准包
    unzip_base

    #2. 挂载量产system.img custom.img
    mount_img

    #3. 拷贝文件
    copy_files_to_base

    #4. 打包基准包
    zip_base

    #5. 签名基准包
    sign_base

    if [[ $# -eq 1 ]];then

        rm ${base_p} -rf
        rm base_ok.zip -rf

        show_vip "--- create base ota end ..."
    else
        __err "xargs error ..."
        return 1
    fi
}

main $@
