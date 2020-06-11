#!/usr/bin/env bash

## if error; then exit
set -e

################################## args

### 1.
mm=$1

################################# common variate
shellfs=$0
script_p=~/workspace/script/zzzzz-script

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

############################################# common function

## 处理jenkins传过来的变量, 并检查其有效性.
function handle_vairable()
{
    echo
}

function print_variable()
{
    echo "JOBS = $JOBS"
    echo '-----------------------------------------'
    echo
}

function auto_create_custom_img()
{
    local JS_CUSTOM_IMG=custom.img
    local JS_BOOTANIMATION_ZIP=bootanimation.zip

    local TMP_IMG=custom.ext4.img
    local OUT_IMG=m_custom.img

    if [[ ! -d custom ]];then
        mkdir -p custom
    fi

    ## 1. 解压提供的custom.img
    if [[ -f ${script_p}/tools/simg2img ]];then
        ${script_p}/tools/simg2img ${JS_CUSTOM_IMG} ${TMP_IMG}
    fi

    ## 2. 挂载，并修改内容
    if [[ -f ${TMP_IMG} ]];then
        sudo mount -t ext4 -o loop ${TMP_IMG} custom
    else
        __err "$TMP_IMG no found ..."
        return 1
    fi

    ## 更新动画.
    if [[ -d custom/media ]];then
        sudo cp -vf ${JS_BOOTANIMATION_ZIP} custom/media
        echo
    fi

    ## 3. 打包新的custom.img
    if [[ -f ${script_p}/tools/make_ext4fs && -d custom ]];then
        sudo ${script_p}/tools/make_ext4fs -s -l 55M -a custom ${OUT_IMG} custom
        echo
    else
        __err " make_ext4fs no found ..."
        return 1
    fi

    ## 4. 输出指定文件

    ## 5. 扫尾工作

    # a. 卸载custom
    if [[ -f custom/media/${JS_BOOTANIMATION_ZIP} ]];then
        sudo umount custom/
    else
        echo "更新$JS_CUSTOM_IMG FAIL ..."
        return 1
    fi

    # b. 删除中间文件 $TMP_IMG
    if [[ -f ${TMP_IMG} ]];then
        rm -rf ${TMP_IMG}
    fi

    # c. 删除 custom目录
    if [[ -d custom ]];then
        rm -rf custom
    fi
}

function auto_create_logo_bin()
{
    local LOGO_B=logo.bin
    local LOGO_R=repalce_logo.bin

    local UBOOT=logo_u.bmp
    local KERKEL=logo_k.bmp

    if [[ -f ${LOGO_B} ]];then
        cp -vf ${LOGO_B} ${LOGO_R}
    fi

    if [[ -f ${script_p}/tools/MtkLogo.jar ]];then

        if [[ -f ${UBOOT} && -f ${KERKEL} ]];then
            show_vig "UBOOT KERKEL are not the same !"
        elif [[ -f ${UBOOT} ]];then
            cp -vf ${UBOOT} ${KERKEL}
            echo
            show_vig "UBOOT KERKEL are the same !"
        elif [[ -f ${KERKEL} ]];then
            cp -vf ${KERKEL} ${UBOOT}
            echo
            show_vig "UBOOT KERKEL are the same !"
        else
            __err "请选择要替换的开机LOGO !"
            return 1
        fi

        ## 制作logo.bin
        java -jar ${script_p}/tools/MtkLogo.jar -o ${LOGO_B} ${LOGO_R} ${UBOOT} ${KERKEL}
        echo
    fi

    if [[ -f ${UBOOT} ]];then
        rm ${UBOOT}
    fi

    if [[ -f ${KERKEL} ]];then
        rm ${KERKEL}
    fi

    if [[ -f ${LOGO_B} ]];then
        rm ${LOGO_B}
    fi
}

function main()
{
    local startT=`date +'%Y-%m-%d %H:%M:%S'`

    if [[ "`is_yunovo_server`" == "true" ]];then

        echo
        show_vip "--> create start ."

        #handle_vairable

        ### 输出完整参数
        #print_variable
    else
        __err "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
        return 1
    fi

    case ${mm} in
        logo.bin)
            auto_create_logo_bin
            ;;

        bootanimation.zip)
            auto_create_custom_img
            ;;
        *)
            :
            ;;
    esac

    if [[ "`is_yunovo_server`" == "true" ]];then

        ### 打印编译所需要的时间
        print_make_completed_time

        echo
        show_vip "--> create end ."
    else
        __err "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
        return 1
    fi
}

main $@
