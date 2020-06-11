#!/usr/bin/env bash

# if error then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

declare -A apkcerts
declare -a print_var_list

# 打印关联数组
function print_ass_array()
{
    declare -a key
    declare -a value
    declare -A ass

    key+=($1)
    value+=($2)

    if [[ ${#key[@]} -ne ${#value[@]} ]]; then
        echo "key vaule no match ..."
        return
    fi

    for k in ${!key[@]} ; do
        for v in ${!value[@]} ; do
            if [[ ${k} == ${v} ]]; then
                #echo ${key[$k]}
                #echo ${value[$v]}
                #echo '-----'
                ass[${key[$k]}]=${value[$v]}
            fi
        done
    done

    for a in ${!ass[@]} ; do
        echo " $a --- ${ass[$a]} "
    done

    #echo ${ass[@]} -- ${!ass[@]}
}

# 单独签名APK
function signapk() {

    local signapk_jar=${target_dir}/otatools/linux-x86/framework/signapk.jar
    local type=${apkcerts[$app]}

    local app_p=`find ${target_p} -name ${app}`
    local apk_name=`basename ${app_p}`
    local apk_path=`dirname  ${app_p}`

    if false;then
    echo ${type}
    echo '---------'
    echo "1." ${app_p}
    echo "2." ${apk_name}
    echo "3." ${apk_path}
    echo "========="
    echo
    fi

    mv ${apk_path}/${apk_name} ${apk_path}/nosign_${apk_name}
    java -jar ${signapk_jar} ${signkey_dir}/${type}.x509.pem ${signkey_dir}/${type}.pk8 ${apk_path}/nosign_${apk_name} ${apk_path}/sign_${apk_name}
    mv ${apk_path}/sign_${apk_name} ${app_p} && rm -rf ${apk_path}/nosign_${apk_name}
}

# 重签名SYSTEM和CUSTOM下全部APK,并更新签名证书
function resigned() {

    local app_log=/tmp/app.log

    if [[ -f ${app_log} ]]; then
        rm ${app_log}
    fi

    touch ${app_log}

    for p in `find ${target_p} -name "*.apk"`; do
        echo ${p} | awk -F '/' '{ print $NF }' >> ${app_log}
    done

    while read line;
    do
        #echo ${line} | grep build/target/product/security
        key=`echo ${line} | grep -E 'build/target/product/security' | awk -F '"' '{ print $2 }'` # |PRESIGNED
        value=`echo ${line} | grep 'build/target/product/security' | awk -F '"' '{ print $4 }'` && value=${value##*/} && value=${value%%.*}

        if [[ -n ${key} && -n ${value} ]]; then
            #echo ">>>>> " ${key} "---" ${value}
            apkcerts[${key}]=${value}
        fi

    done < ${target_dir}/target_files/META/apkcerts.txt

    key=${!apkcerts[@]}
    val=${apkcerts[@]}

    #print_ass_array "$key" "$val"
    echo > /tmp/app.list.log

    while read app;
    do
        for k in ${!apkcerts[@]} ; do
            if [[ ${app} == ${k} ]]; then # && ${app} == "YOcOTA_1.01.023.apk" && ${app} == "framework-res.apk"
                echo "------ sign  $app"
                echo ${app} >> /tmp/app.list.log
                signapk
            fi
        done
    done < ${app_log}

    # 更新系统签名证书
    if [[ -f ${target_p}/etc/security/otacerts.zip ]]; then
        rm ${target_p}/etc/security/otacerts.zip

        zip -qj ${target_p}/etc/security/otacerts.zip ${signkey_dir}/testkey.x509.pem

        echo "cp otacerts.zip ok ..."
    fi
}

# 制作system.img
function create_system_img() {

    local target_p=${target_dir}/target_files/SYSTEM

    echo "start create system.img ..."
    echo

    # 重签名apk
    resigned

    # 重新打包
    ${target_dir}/otatools/releasetools/build_image.py ${target_p} ${target_dir}/target_files/META/system_image_info.txt ${target_dir}/system.img

    # 备份到target_files中,便于制作OTA
    if [[ -f ${target_dir}/system.img ]]; then
        cp -vf ${target_dir}/system.img ${target_dir}/target_files/IMAGES
    else
        echo "backup system.img fail ..."
        return 1
    fi
}

# 制作custom.img
function create_custom_img() {

    local target_p=${target_dir}/target_files/CUSTOM

    echo "start create custom.img ..."
    echo

    # 重签名apk
    resigned

    # 重新打包
    ${target_dir}/otatools/releasetools/build_image.py ${target_p} ${target_dir}/target_files/META/system_image_info.txt ${target_dir}/custom.img

    # 备份到target_files中,便于制作OTA
    if [[ -f ${target_dir}/custom.img ]]; then
        cp -vf ${target_dir}/custom.img ${target_dir}/target_files/IMAGES
    else
        echo "backup custom.img fail ..."
        return 1
    fi
}

function create_rom() {

    local target_dir=$1

    # 1. 配置环境变量
    export PATH=${target_dir}/otatools/linux-x86/bin:$PATH
    export LD_LIBRARY_PATH=${target_dir}/otatools/linux-x86/lib:${LD_LIBRARY_PATH}

    # 2. 更改system_image_info.txt文件中的ile_contexts的路径.
    if [[ -f ${target_dir}/target_files/META/system_image_info.txt ]]; then # 当target_files中存在
        sed -i "s#selinux_fc=.*file_contexts#selinux_fc=${target_dir}/target_files/BOOT/RAMDISK/file_contexts#" ${target_dir}/target_files/META/system_image_info.txt
    elif [[ -f system_image_info.txt ]]; then #当target_files中不存在,则从当前目录下寻找
        sed -i "s#selinux_fc=.*file_contexts#selinux_fc=${target_dir}/target_files/BOOT/RAMDISK/file_contexts#" system_image_info.txt
        cp -vf system_image_info.txt ${target_dir}/target_files/META/system_image_info.txt
    else
        echo "backup system_image_info.txt file err ..."
        return 1
    fi

    create_recovery_img
    create_custom_img
    create_system_img
}

function create_boot_img() {

    echo "start create boot.img ..."
    echo

    # 1. 生成:ramdisk.img
    mkbootfs ${target_dir}/target_files/BOOT/RAMDISK | minigzip > /tmp/ramdisk.img

    # 2. 生成boot.img
    mkbootimg --kernel ${target_dir}/target_files/BOOT/kernel \
        --ramdisk /tmp/ramdisk.img \
        --cmdline `cat ${target_dir}/target_files/BOOT/cmdline` \
        --base `cat ${target_dir}/target_files/BOOT/base` \
        --ramdisk_offset `cat ${target_dir}/target_files/BOOT/ramdisk_offset` \
        --kernel_offset `cat ${target_dir}/target_files/BOOT/kernel_offset` \
        --tags_offset `cat ${target_dir}/target_files/BOOT/tags_offset` \
        --board `cat ${target_dir}/target_files/BOOT/board` \
        --kernel_offset `cat ${target_dir}/target_files/BOOT/kernel_offset` \
        --ramdisk_offset `cat ${target_dir}/target_files/BOOT/ramdisk_offset` \
        --tags_offset `cat ${target_dir}/target_files/BOOT/tags_offset` \
        --output boot.img

    # 3. 清理动作
    if [[ -f /tmp/ramdisk.img ]]; then
        rm -rf /tmp/ramdisk.img
    fi
}

function create_recovery_img() {

    echo "start create recovery.img ..."
    echo

    # 更新签名证书秘钥 /res/keys
    if [[ -f ${target_dir}/otatools/linux-x86/framework/dumpkey.jar && -f ${signkey_dir}/testkey.x509.pem ]]; then
        java -jar ${target_dir}/otatools/linux-x86/framework/dumpkey.jar ${signkey_dir}/testkey.x509.pem > ${target_dir}/target_files/RECOVERY/RAMDISK/res/keys
    else
        echo "签名文件未找到 ..."
        return 1
    fi

    # 1. 生成:ramdisk-recovery.img
    mkbootfs ${target_dir}/target_files/RECOVERY/RAMDISK | minigzip > /tmp/ramdisk-recovery.img

    # 2. 生成recovery.img
    mkbootimg --kernel ${target_dir}/target_files/RECOVERY/kernel \
        --ramdisk /tmp/ramdisk-recovery.img \
        --cmdline `cat ${target_dir}/target_files/RECOVERY/cmdline` \
        --base `cat ${target_dir}/target_files/RECOVERY/base` \
        --ramdisk_offset `cat ${target_dir}/target_files/RECOVERY/ramdisk_offset` \
        --kernel_offset `cat ${target_dir}/target_files/RECOVERY/kernel_offset` \
        --tags_offset `cat ${target_dir}/target_files/RECOVERY/tags_offset` \
        --board `cat ${target_dir}/target_files/RECOVERY/board` \
        --kernel_offset `cat ${target_dir}/target_files/RECOVERY/kernel_offset` \
        --ramdisk_offset `cat ${target_dir}/target_files/RECOVERY/ramdisk_offset` \
        --tags_offset `cat ${target_dir}/target_files/RECOVERY/tags_offset` \
        --output ${target_dir}/recovery.img

    # 3. 清理动作
    if [[ -f /tmp/ramdisk-recovery.img ]]; then
        rm -rf /tmp/ramdisk-recovery.img
    fi

    # 4.备份到target_files中,便于制作OTA
    if [[ -f ${target_dir}/recovery.img ]]; then
        cp -vf ${target_dir}/recovery.img ${target_dir}/target_files/IMAGES
    else
        echo "backup recovery.img fail ..."
        return 1
    fi
}

# 签名完成后,重新制作target_files.zip 然后重名称成云智的zip包
function create_target_files() {

    if [[ -n "$1" ]]; then
        target_dir=$1
    fi

    # set selinux file_contexts path
    if [[ -f ${target_dir}/target_files/BOOT/RAMDISK/file_contexts ]]; then
        sed -i "s#^selinux_fc=.*file_contexts#selinux_fc=${target_dir}/target_files/BOOT/RAMDISK/file_contexts#" ${target_dir}/target_files/META/misc_info.txt
    fi

    echo "zipping target files"

    pushd ${target_dir}/target_files > /dev/null

    if [[ $? = 0 ]]; then
        zip -qry ../target_files.zip *
    fi

    popd > /dev/null
}

# 签名后的target_file.zip 制作新的差分包和全量包
function create_otapackage() {

    local target_dir=$1
    local build_prop=${target_dir}/target_files/SYSTEM/build.prop

    if [[ $# == 2 ]]; then
        local incremental_work_dir=$2
    fi

    local extra_args="-v"
    local otapackage_zip="ota.zip"

    if [[ -f ${target_dir}/target_files/META/boot.sig ]]; then
        export MTK_SECURITY_SW_SUPPORT=yes
    fi

    pushd ${target_dir} > /dev/null

    # for mtk ota_scatter.txt
    if [[ -f ${target_dir}/target_files/META/ota_scatter.txt ]]; then
        cust_dir=`cat ${target_dir}/target_files/SYSTEM/build.prop | grep ^ro.product.device= | awk -F '=' '{print $2}'`
        mkdir -p out/target/product/${cust_dir}
        cp -vf ${target_dir}/target_files/META/ota_scatter.txt out/target/product/${cust_dir}
    fi

    #${target_dir}/otatools/releasetools/add_img_to_target_files -p ${target_dir}/otatools/linux-x86 ${incremental_work_dir}/target_files.zip
    #${target_dir}/otatools/releasetools/add_img_to_target_files -p ${target_dir}/otatools/linux-x86 ${incremental_work_dir}/target_files.zip

    if [[ -n "${extra_args}" ]]; then
        if [[ ${create_incremental} == "true" ]]; then
            cmd="./otatools/releasetools/ota_from_target_files ${extra_args} -i ${incremental_work_dir}/target_files.zip -p otatools/linux-x86 -k ${signkey_dir}/testkey target_files.zip ${otapackage_zip}"
        else
            cmd="./otatools/releasetools/ota_from_target_files ${extra_args} -p otatools/linux-x86 -k ${signkey_dir}/testkey target_files.zip ${otapackage_zip}"
        fi

        echo ${cmd}
        eval ${cmd}
        ret=$?
    fi

    popd > /dev/null

if true;then
    if [[ ${ret} = 0 ]] && [[ -f ${target_dir}/${otapackage_zip} ]]; then
        echo "image build info:"
        cat ${build_prop} | grep ^ro.build.version.sdk
        cat ${build_prop} | grep ^ro.build.type
        cat ${build_prop} | grep ^ro.build.fingerprint
        cat ${build_prop} | grep ^ro.product.model
        cat ${build_prop} | grep ^ro.product.brand
        cat ${build_prop} | grep ^ro.product.name
        cat ${build_prop} | grep ^ro.product.device
        cat ${build_prop} | grep ^ro.build.display.id
        mv ${target_dir}/${otapackage_zip} ./
        echo "make ota package successful: ${otapackage_zip}"
    else
        echo "make ota package failed"
    fi

    return ${ret}
fi
}

# 备份ROM包
function backimg() {

    if [[ "${base_dir}" ]]; then
        target_dir=${base_dir}
    fi

    if [[ -f ${target_dir}/system.img ]]; then
        cp -vf ${target_dir}/system.img .
    fi

    if [[ -f ${target_dir}/custom.img ]]; then
        cp -vf ${target_dir}/custom.img .
    fi

    if [[ -f ${target_dir}/recovery.img ]]; then
        cp -vf ${target_dir}/recovery.img .
    fi
}

# clean
function cleanfs() {

    if [[ ${create_incremental} == "true" ]]; then

        # 清理中间文件
        if [[ -d ${base_dir} ]]; then
            rm -rf ${base_dir}
        fi

        if [[ -d ${new_dir} ]]; then
            rm -rf ${new_dir}
        fi
    else
        # 清理中间文件
        if [[ -d ${target_dir} ]]; then
            rm -rf ${target_dir}
        fi
    fi

    if [[ -d ${signkey_dir} ]]; then
        rm -rf ${signkey_dir}
    fi
}

## 打印基础变量
function __print()
{
    unset print_var_list
    print_var_list[${#print_var_list[@]}]=target_dir
    print_var_list[${#print_var_list[@]}]=signkey_dir
    print_var_list[${#print_var_list[@]}]=otatools_dir
    print_var_list[${#print_var_list[@]}]=time_for_ota
    print_var_list[${#print_var_list[@]}]=image_dir
    print_var_list[${#print_var_list[@]}]=incremental_images_dir

    echo "----------------------------- length = ${#print_var_list[@]}"
    for v in ${print_var_list[@]}
    do
        eval "echo ${v} = \$${v}"
    done
    echo "-----------------------------"
}

function usage()
{
    cat <<EOF
usage: $0 <images dir> <sign keys dir> [incremental from images dir]
e.g.
$0 <images dir> <keys dir>
$0 <images dir> <keys.zip> <incremental from images dir>
EOF
}

#1. 设置环境变量 otatools PATH=out/host/linux-x86/bin:$PATH
#2. 解压target.zip 和 otatools.zip
#3. 重新创建system.img custom.img boot.img recovery.img
#4. 重新制作刷机包

function main() {

    # strip xxx/ to xxx
    local image_dir=$(echo $1 | sed 's/\/$//g')
    local incremental_images_dir=$(echo $3 | sed 's/\/$//g')
    local time_for_ota=$(date +%s)

    local target_dir=/tmp/ota_${time_for_ota}
    local signkey_dir=/tmp/otakey_${time_for_ota}

    local create_incremental=false

    local base_dir=
    local new_dir=

    if [[ ! -d ${signkey_dir} ]]; then
        mkdir -p ${signkey_dir}
    fi

    if [[ -d "$2" && -n "$2" ]]; then
        cp -rf $2/* ${signkey_dir}/
    fi

    if [[ $# == 3 && -f $3/otatools.zip ]]; then
        create_incremental=true
    fi

    if [[ ${create_incremental} == "true" ]]; then

        base_dir=/tmp/otabase_$(date +%s)
        new_dir=/tmp/otanew_$(date +%s)

        if [[ ! -d ${base_dir} ]]; then
            mkdir -p ${base_dir}
        fi

        if [[ ! -d ${new_dir} ]]; then
            mkdir -p ${new_dir}
        fi

        # 1. 解压target.zip和otatools.zip
        unzip -q ${incremental_images_dir}/`find ${incremental_images_dir} -name "*.zip" | awk -F '/' '{ print $NF }' | grep '_H3.1_'` -d ${base_dir}/target_files
        unzip -q ${incremental_images_dir}/otatools.zip -d ${base_dir}

        unzip -q ${image_dir}/`find ${image_dir} -name "*.zip" | awk -F '/' '{ print $NF }' | grep '_H3.1_'` -d ${new_dir}/target_files
        unzip -q ${image_dir}/otatools.zip -d ${new_dir}

        # 制作ROM包
        create_rom ${base_dir}
        create_rom ${new_dir}

        # 制作基准包
        create_target_files ${base_dir}
        create_target_files ${new_dir}

        # 制作OTA差分包和全量包
        create_otapackage ${new_dir} ${base_dir}

    else
        if [[ ! -d ${target_dir} ]]; then
            mkdir -p ${target_dir}
        fi

        # 1. 解压target.zip和otatools.zip
        unzip -q ${image_dir}/`find ${image_dir} -name "*.zip" | awk -F '/' '{ print $NF }' | grep '_H3.1_'` -d ${target_dir}/target_files
        unzip -q ${image_dir}/otatools.zip -d ${target_dir}

        # 制作ROM包
        create_rom ${target_dir}

        # 制作基准包
        create_target_files ${target_dir}

        # 制作OTA差分包和全量包
        create_otapackage ${target_dir}
    fi

    __print

    backimg ${base_dir}

    #cleanfs
}

main "$@"
