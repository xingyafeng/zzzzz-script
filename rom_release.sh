#!/usr/bin/env bash

## if error then exit
set -e

#### --------------------------------------
# 1. 构建ROM类型
build_rom_type=
# 2. 重签名版本 版本号
build_rom_version=
build_version=
# 3. 待升级版本 版本号
build_rom_pre_version=
build_pre_version=
# 4. 签名类型
build_signature_type=
# 5. 构建假包
build_fake_ota=""
# 6. 升级lk
build_lk=""
# 7. 升级preloader
build_preloader=""

#当前Shell文件名
shellfs=$0

#init function
. "`dirname $0`/jenkins/yunovo_init.sh"

# --------------------------------------  common

# 待重签名版本存放路径
resign_rom_p=${tmpfs}/resign_rom

# 重签名后的target包
resign_target_after=${tmpfs}/resign_after

# 待升级版本存放路径
pre_ota_rom_p=${tmpfs}/pre_ota_rom
pre_ota_target_file=

# 客制化路径
custom_p=
pre_custom_p=

# 版本号 如：CARROBOT-A11D3_H3.1_V1.cm01.0.0
rom_ver=

# 准备阶段
function preparation() {

    local rom_f1_path=`ssh ${git_username}@${f1_server} find ${share_rom_p}/Debug -name ${build_rom_version}`

    show_vip "--> sync sign rom version ..."

    if [[ -n ${rom_f1_path} ]]; then
        # 拿到服务器待签名的版本
        rsync -av ${git_username}@${f1_server}:${rom_f1_path} ${resign_rom_p}
    else
        log error "The build_rom_version rom path no found ..."
    fi

    show_vip "--> sync rom pre version ..."

    if [[ -n "${build_rom_pre_version}" ]]; then
        rom_f1_path=`ssh ${git_username}@${f1_server} find ${share_rom_p}/Release -name ${build_rom_pre_version}`

        # 拿到服务器待升级的版本
        if [[ -n ${rom_f1_path} ]]; then
            rsync -av ${git_username}@${f1_server}:${rom_f1_path} ${pre_ota_rom_p}
        else
            log error "The build_rom_pre_version rom path no found ..."
        fi
    fi

    rom_ver=`find ${resign_rom_p}/${build_rom_version} -name system.img | awk -F/ '{print $(NF-1)}'`

    # 拿到工具包路径,并解压ota工具包
    otatools_p=`find ${resign_rom_p}/${build_rom_version} -name otatools.zip`
    if [[ -f ${otatools_p} ]]; then

        if [[ -d build/ ]]; then
            rm -rf build/
        fi

        if [[ -d out/ ]]; then
            rm -rf out/
        fi

        if [[ -d make_package/ ]]; then
            rm -rf make_package/
        fi

        if [[ -d device/ ]]; then
            rm -rf device/
        fi

        if [[ -d vendor/ ]]; then
            rm -rf vendor/
        fi

        # 修复错误的备份文件
        if [[ -f mt_ota_from_target_files.py ]]; then
            rm mt_ota_from_target_files.py
        fi

        unzip -q ${otatools_p} -d .
    fi
}

function handle_commom_vairable() {

    preparation

    # 1. 版型/客户/项目
    if [[ -n ${custom_p} ]]; then
        yunovo_board=`echo ${custom_p} | awk -F/  '{ print $1 }' | tr 'A-Z' 'a-z'`
        tmp=`echo ${custom_p} | awk -F/ '{ print $2 }'`
        yunovo_custom=`echo ${tmp}  | awk -F '-' '{ print $1 }' | tr 'A-Z' 'a-z'`
        yunovo_project=`echo ${tmp} | awk -F '-' '{ print $2 }' | tr 'A-Z' 'a-z'`

        # 拿到manifest分支名
        if [[ `is_zen_project` == "true" ]]; then
            get_manifest_branch_name_from_zen
        fi
    else
        log error "The custom_p is NULL ..."
    fi

    # 3. 拿到制作的target包
    target_file=`find ${resign_rom_p}/${build_rom_version} -name ${tmp}_*.zip | grep -v inc`
    if [[ -f "${target_file}" && -n "${target_file}" ]]; then
        target_file_name=`echo ${target_file} | awk -F/ '{ print $NF }'`
        if [[ -z ${target_file_name} ]]; then
            log error "The target_file_name is null ..."
        fi

        rom_version_p=${target_file_name%.*}
        if [[ -z "${rom_version_p}" ]]; then
            log error "The rom_version_p is null ..."
        fi
    else
        log error "The target_file file was no found ..."
    fi

    # 4. 拿到待升级的target包
    if [[ -n "${build_rom_pre_version}" ]]; then
        pre_ota_target_file=`find ${pre_ota_rom_p}/${build_rom_pre_version} -name ${tmp}_*.zip | grep -v inc`
        if [[ ! -f ${pre_ota_target_file} || -z "${pre_ota_target_file}" ]]; then
            log error "The pre_ota_target_file file was no found ..."
        fi
    else
        log debug "The build rom pre version is null ..."
    fi

    # 5. 差分包路径
    OTA_FILE=${resign_rom_p}/${build_rom_version}/${rom_version_p}_full_and_ota_inc/${build_version}_for_${build_pre_version}.zip
    if [[ -z "${OTA_FILE}" ]]; then
        log error "The OTA_FILE file was not found ..."
    fi

    # 6. mediatek 当ota_scatter.txt 未备份成功,据 *_Android_scatter.txt生成.
    if [[ "`is_sc_project`" == "false" && ! -f ${ota_scatter} ]]; then
        if [[ -f build/tools/releasetools/ota_scatter.pl ]]; then
            perl build/tools/releasetools/ota_scatter.pl `find ${resign_rom_p}/${build_rom_version} -name *_Android_scatter.txt` ${ota_scatter}
        fi
    fi
}

function handle_vairable() {

    # 1. ROM类型
    build_rom_type=${yunovo_rom_type:=Debug}

    # 2. 重签名ROM版本时间轴
    build_rom_version=${yunovo_rom_version:=}
    if [[ -n "${build_rom_version}" ]]; then
        build_version=`echo ${build_rom_version} | awk -F '_' '{ print $1 }'`
        if [[ -z "${build_version}" ]]; then
            log error "The build_version value is null ..."
        fi
    else
        log error "The build_rom_version has error. please check it ."
    fi

    if [[ -n "`echo ${build_rom_version} | sed -n '/^[S|V]/p'`" ]]; then
        custom_p=`ssh ${git_username}@${f1_server} find ${share_rom_p}/Debug -name ${build_rom_version} | awk -F/ '{ print $(NF-2) "/" $(NF-1) }'`
    else
        log error "The build_rom_version has error. please check it ."
    fi

    # 3. 待升级版本
    build_rom_pre_version=${yunovo_pre_version:=}
    if [[ -n "`echo ${build_rom_pre_version} | sed -n '/^[S|V]/p'`" ]]; then
        build_pre_version=`echo ${build_rom_pre_version} | awk -F '_' '{ print $1 }'`
        if [[ -z "${build_pre_version}" ]]; then
            log error "The build_pre_version value is null ..."
        fi

        pre_custom_p=`ssh ${git_username}@${f1_server} find ${share_rom_p}/Release -name ${build_rom_pre_version} | awk -F/ '{ print $(NF-2) "/" $(NF-1) }'`
        if [[ "${pre_custom_p}" != "${custom_p}" ]]; then
            echo
            log error "pre_version ${pre_custom_p}  does not match curr version ${custom_p} ..."
        fi
    else
        log warn "The build_rom_pre_version has error. please check it ."
    fi

    # 4. 签名类型 公版签名|私有起那么
    build_signature_type=${yunovo_signature_type=-false}

    # 5. 构建假包
    build_fake_ota=${yunovo_fake_ota:-false}

    # 6. 升级lk
    build_lk=${yunovo_lk:-false}

    # 7. 升级preloader
    build_preloader=${yunovo_preloader:-false}

    ## --------------------------

    handle_commom_vairable
    handle_common_variable_for_inc
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "builder = " ${build_builder}
    echo '-----------------------------------------'
    echo "build_pre_version     = "${build_pre_version}
    echo "build_version         = "${build_version}
    echo "build_rom_type        = "${build_rom_type}
    echo "build_rom_version     = "${build_rom_version}
    echo "build_rom_pre_version = "${build_rom_pre_version}
    echo "build_signature_type  = "${build_signature_type}
    echo "build_fake_ota        = "${build_fake_ota}
    echo "build_lk              = "${build_lk}
    echo "build_preloader       = "${build_preloader}
    echo '-----------------------------------------'
    echo "yunovo_board          = "${yunovo_board}
    echo "yunovo_custom         = "${yunovo_custom}
    echo "yunovo_project        = "${yunovo_project}
    echo '-----------------------------------------'
    echo "custom_p              = "${custom_p}
    echo "pre_custom_p          = "${pre_custom_p}
    echo "target_file           = "${target_file}
    echo "target_file_name      = "${target_file_name}
    echo "pre_ota_target_file   = "${pre_ota_target_file}
    echo "rom_version_p         = "${rom_version_p}
    echo "OTA_FILE              = "${OTA_FILE}
    echo "manifest branch       = "${manifest_branchN}
    echo '-----------------------------------------'
    echo "ota_core_py           = "${ota_core_py}
    echo "ota_extra_py          = "${ota_extra_py}
    echo "inc_args              = "${inc_args}
    echo "signature_type_p      = "${signature_type_p}
    echo '-----------------------------------------'
    echo
}

function init() {

    local otatools_p=
    local ota_scatter=out/target/product/magc6580_we_l/ota_scatter.txt

    if [[ ! -d ${resign_rom_p} ]]; then
        mkdir -p ${resign_rom_p}
    fi

    if [[ ! -d ${pre_ota_rom_p} ]]; then
        mkdir -p ${pre_ota_rom_p}
    fi

    if [[ ! -d ${resign_target_after} ]]; then
        mkdir -p ${resign_target_after}
    fi

    #清除临时文件
    rm -rf /tmp/targetfiles-* /tmp/custom-*.img /tmp/system-*.img /tmp/custom-*.map /tmp/system-*.map

    # 初始化公共变量,其不依赖各种环境因素
    handle_common_variable

    handle_vairable
    print_variable

    set_java_home_path
}

# 重签名target files
function resign_target_files() {

    local cmd=""
    local extra_args='-v -o'
    local sign_target_files_py=""

    # 处理重签基准包,关键参数
    handle_common_variable_for_target_file

    # 1. 重签名基准包
    cmd="${sign_target_files_py} ${extra_args} ${target_file} ${resign_target_after}/${target_file_name}"

    print_and_exec_cmd

    # 2. 备份重签名后的基准包
    if [[ $? -eq 0 ]]; then
        if [[ -f ${resign_target_after}/${target_file_name} ]]; then
            cp -vf ${resign_target_after}/${target_file_name} ${target_file}
        else
            log error "Resign ${target_file_name} file no found ..."
        fi

        echo
        show_vip "--> sign target files apks successful ..."
    else
        log error "--> Sign target files apks failed ..."
    fi
}

# 制作差分包
function make_inc() {

    local cmd=
    local inc_pack="-i ${ota_previous} ${ota_current} ${OTA_FILE}"

    echo
    __green__ "The ota previous version = ${ota_previous}"
    __green__ "The ota current  version = ${ota_current}"
    echo

    cmd="${ota_core_py} -k ${signature_type_p} ${inc_args} ${inc_pack}"

    print_and_exec_cmd

    if [[ $? -eq 0 ]]; then
        echo
        echo "md5:"
        md5sum ${ota_previous}
        md5sum ${ota_current}

        echo
        show_vip "--> make_inc successful ..."
    fi
}

# 制作差分包
function make_yunovo_inc() {

    ota_previous=${pre_ota_target_file}
    ota_current=${target_file}

    # 制作差分包
    make_inc

    # 备份差分包
    if [[ -d ${resign_rom_p}/${build_rom_version}/${rom_version_p}_full_and_ota_inc ]]; then
        cp -vf ${ota_previous} ${resign_rom_p}/${build_rom_version}/${rom_version_p}_full_and_ota_inc
    else
        log error "The ota_previous file was not found ..."
    fi

    echo
    show_vip "--> make yunovo inc package end ..."
}

# 制作假包
function make_fake_package() {

    local cmd=""
    local extra_args='-v -o'
    local sign_target_files_py=""

    ota_previous=${target_file}
    ota_current=${tmpfs}/target_files-fake_package.zip

    OTA_FILE=${resign_rom_p}/${build_rom_version}/${rom_version_p}_full_and_ota_fake/fake_package.zip
    if [[ -z "${OTA_FILE}" ]]; then
        log error "The OTA_FILE file was not found ..."
    fi

    # 处理重签基准包,关键参数
    handle_common_variable_for_target_file

    # 支持假包标识符
    if [[ "`is_support_fake`" == "true" ]]; then
        extra_args=${extra_args}" -f"
    fi

    # 1. 制作假基准包
    cmd="${sign_target_files_py} ${extra_args} ${ota_previous} ${ota_current}"

    print_and_exec_cmd

    if [[ $? -eq 0 ]]; then
        echo
        show_vip "--> sign target file apks  successful for target fake package ..."
    fi

    # 2. 制作假包
    make_inc

    # 3. 备份假包
    if [[ -f ${ota_current} ]]; then
        cp -vf ${ota_current} ${resign_rom_p}/${build_rom_version}/${rom_version_p}_full_and_ota_fake
    fi

    echo
    show_vip "--> make fake package end ..."
}

# 重签名full files
function resign_full_files() {

    local cmd=
    local extra_args=

    local PRODUCT_OUT=

    echo "---- `get_cpu_type`"
    echo

    case `get_cpu_type` in

        mt6580)
            extra_args="-v"
        ;;

        mt6580-oreo)
            extra_args="-v -n --block -s ${ota_extra_py}"
        ;;

        mt8321)
            PRODUCT_OUT=${resign_rom_p}/${build_rom_version}/${rom_version_p}

            extra_args="-v --block -l ${PRODUCT_OUT}/logo.bin -u ${PRODUCT_OUT}/lk.bin -r ${PRODUCT_OUT}/preloader_along8321_emmc_706m.bin"
        ;;

        # SPRD: remove --block for board dones't support dm_verity @{
        #          --block \
        # @}
        sc9832a)
            extra_args="-v -n"
        ;;

        *)
            extra_args="-v"
        ;;
    esac

    cmd="./build/tools/releasetools/ota_from_target_files ${extra_args} -k ${signature_type_p} ${resign_target_after}/${target_file_name} ${resign_target_after}/sdupdate.zip"

    print_and_exec_cmd

    if [[ $? -eq 0 ]]; then

        if [[ -f ${resign_target_after}/sdupdate.zip ]]; then
            cp -vf ${resign_target_after}/sdupdate.zip `find ${resign_rom_p}/${build_rom_version} -name "sdupdate*.zip"`
        else
            log error "The sdupdate.zip is no found ..."
        fi

        echo
        show_vip "--> resign full files successful ..."
    else
        log error "--> cmd exec failed ..."
    fi
}

## 拿到PAC版本号
function get_pac_version()
{
    V=`date +%V`
    V=`expr ${V} + 1`

    if [[ ${V} -lt 10  ]];then
        V=`echo "0$V"`
    fi

    if [[ -z "${yunovo_board}"  ]];then
        PACVER=MorcorDroid_`date +W%g.${V}.%u-%H%M%S`
    else
        PACVER=${yunovo_board}_`date +W%g.${V}.%u-%H%M%S`
    fi

    #echo "PACVER = $PACVER"
}

function get_pac_command()
{
    local command=
    local pac_ini=

    if [[ -d ${resign_rom_p}/${build_rom_version}/${rom_version_p} ]]; then
        pac_ini=`find ${resign_rom_p}/${build_rom_version}/${rom_version_p} -name pac.ini`
    fi

    if [[ -d ${TARGET_PAC_OUT} ]]; then
        cp -f ${resign_rom_p}/${build_rom_version}/${rom_version_p}/* ${TARGET_PAC_OUT}
    fi

    command="/usr/bin/perl ${PAC_ENV_SCRIPT}/pac_via_conf.pl ${TARGET_PAC_OUT}/${BUILD_PROJECT}-native_${PROJ_TYPE}.pac ${PACVER} ${pac_ini} ${PROJ_TYPE}"

    PAC_COMMAND=${command}
}

## 配置路径
function setpacpaths()
{
     local T=$(pwd)

     if [[ ! "$T"  ]]; then
         echo "Couldn't locate the top of the tree. Try setting TOP."
         return
     fi

     # PAC制作成品路径
     TARGET_PAC_OUT=${T}/release_images/YUNOVO

     # 编译项目名称
     BUILD_PROJECT=yunovo

     # PAC脚本路径
     PAC_ENV_SCRIPT=${T}/make_package

     if [[ ! -d ${TARGET_PAC_OUT} ]]; then
         mkdir -p ${TARGET_PAC_OUT}
     fi
}

## 设置环境变量,为制作pac包
function set_pac_for_environment()
{
    setpacpaths

    echo
    echo "----------------------------------------"
    echo "PAC_ENV_SCRIPT = "${PAC_ENV_SCRIPT}
    echo "TARGET_PAC_OUT = "${TARGET_PAC_OUT}
    echo "BUILD_PROJECT  = "${BUILD_PROJECT}
    echo "PROJ_TYPE      = "${PROJ_TYPE}
}

# 展讯项目需要重新打重签名后的pac包
function makepac()
{
    local start_time=$(date +"%s")
    local end_time=$(date +"%s")
    local tdiff=$(($end_time-$start_time))
    local hours=$(($tdiff / 3600 ))
    local mins=$[ (($tdiff % 3600) / 60) ]
    local secs=$(($tdiff % 60))
    local ncolors=$(tput colors 2>/dev/null)
    local ret=""

    set_pac_for_environment
    get_pac_version
    get_pac_command

    echo "${PAC_COMMAND}"
    eval ${PAC_COMMAND}
    ret=$?

    if [[ -n "$ncolors"  ]] && [[ ${ncolors} -ge 4  ]]; then
        color_failed=$'\E'"[0;31m"
        color_success=$'\E'"[0;32m"
        color_reset=$'\E'"[00m"
    else
        color_failed=""
        color_success=""
        color_reset=""
    fi

    if [[ ${ret} -eq 0  ]] ; then
        local pac_package=`ls ${resign_rom_p}/${build_rom_version}/${rom_version_p}_pac/*.pac`

        if [[ -f ${pac_package} ]]; then
            cp ${TARGET_PAC_OUT}/${BUILD_PROJECT}-native_${PROJ_TYPE}.pac ${pac_package}
            md5sum ${pac_package}
        fi

        echo -n "${color_success}#### make pac completed successfully "
    else
        echo -n "${color_failed}#### make pac failed to package some targets "
    fi

    if [[ ${hours} -gt 0  ]] ; then
        printf "(%02g:%02g:%02g (hh:mm:ss))" ${hours} ${mins} ${secs}
    elif [[ ${mins} -gt 0  ]] ; then
        printf "(%02g:%02g (mm:ss))" ${mins} ${secs}
    elif [[ ${secs} -gt 0  ]] ; then
        printf "(%s seconds)" ${secs}
    fi

    echo " ####${color_reset}"
    echo

    return ${ret}
}

# 重签名刷机包
function resign_rom() {

    if [[ -f ${resign_target_after}/${target_file_name} ]]; then

        if [[ -d ${resign_target_after}/IMAGES ]]; then
            rm -rf ${resign_target_after}/IMAGES
        fi

        unzip ${resign_target_after}/${target_file_name} IMAGES/*.img -d ${resign_target_after}
    fi

    cp -vf ${resign_target_after}/IMAGES/* ${resign_rom_p}/${build_rom_version}/${rom_version_p}

    if [[ "`is_sc_project`" == "true" ]]; then
        makepac
    fi

    if [[ $? -eq 0 ]]; then
        echo
        show_vip "--> backup resign rom successful ..."
    else
        log error "--> Backup resign rom failed ..."
    fi
}

# 同步发布版本到f1服务器
function rsync_release_image_upload_server() {

    local jenkins_ini=`find ${resign_rom_p}/${build_rom_version}/${rom_version_p}_backup -name jenkins.ini`

    local release_rom_p=${share_rom_p}/Release
    local firmware_path=${version_p}

    # 备份发布编号
    if [[ -f ${jenkins_ini} && -z "`cat ${jenkins_ini} | grep 12.发布编号:`" ]]; then
        sed -i -e "/11.构建编号/a\12.发布编号: ${BUILD_DISPLAY_NAME}" ${jenkins_ini}
    fi

    if [[ ! -d ${firmware_path}/${custom_p} ]]; then
        mkdir -p ${firmware_path}/${custom_p}
    fi

    if [[ -d ${resign_rom_p}/${build_rom_version} ]]; then
        mv ${resign_rom_p}/${build_rom_version} ${firmware_path}/${custom_p}
    fi

    #同步发布版本
    rsync -av ${firmware_path}/ ${git_username}@${f1_server}:${release_rom_p}

    if [[ -d ${firmware_path} ]];then
        rm -rf ${firmware_path}/*
    fi

    if [[ -d ${resign_target_after} ]]; then
        rm -rf ${resign_target_after}/*
    fi

    if [[ -d ${TARGET_PAC_OUT} ]]; then
        rm -rf ${TARGET_PAC_OUT}
    fi

    #清除临时文件
    rm -rf /tmp/targetfiles-* /tmp/custom-*.img /tmp/system-*.img /tmp/custom-*.map /tmp/system-*.map

    echo
    show_vip "--> sync release rom end ..."
}

function main() {

    local target_file=
    local target_file_name=

    local ota_previous=
    local ota_current=

    # ---------------------------- pac
    local TARGET_PAC_OUT=""
    local PAC_ENV_SCRIPT=""
    local BUILD_PROJECT=""
    local PROJ_TYPE="PacParam"

    ## pac版本
    local PACVER=""

    ## pac 打包命令行
    local PAC_COMMAND=""

    if [[ "`is_yunovo_server`" == "true" ]];then
        echo
        log print "--> rom release start."
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi

    # 初始化
    init

    # 重签名target包
    resign_target_files

    # 制作差分包
    if [[ -n "`echo ${yunovo_pre_version} | sed -n '/^[S|V]/p'`" ]]; then
        make_yunovo_inc
    fi

    # 制作假包
    if [[ ${build_fake_ota} == "true" ]]; then
        make_fake_package
    fi

    # 重签名全量包
    resign_full_files

    # 生成重签名后的刷机包
    resign_rom

    # 同步发布版本到f1服务器
    rsync_release_image_upload_server

    if [[ "`is_yunovo_server`" == "true" ]];then
        echo
        log print "--> rom release end."
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi
}

main $@
