#!/usr/bin/env bash

## 输出mirror路径
function get_repo_reference_info()
{
    if [[ -n "`get_cpu_type`" ]];then

        echo
        __green__ "----  mirror  ----"

        git --git-dir=${manifest_git_p} config --get repo.reference

        __green__ "----  mirror  ----"
        echo
    else
        log error "get cpu type is null ..."
    fi
}

function down_load_yunovo_source_code()
{
    local reference_p=""
    local mirror_p=~/jobs/mirror
    local manifest_git_p=.repo/manifests/.git

    if [[ -n "`get_cpu_type`" ]];then
        reference_p=${mirror_p}/`get_cpu_type`
    else
        log error "The reference path is null ..."
    fi

    if [[ -z "$manifest_branchN" ]];then
        log error "The manifest branch name is null ..."
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        update_source_code
    else
        download_source_code
    fi
}

## 更新源代码
function update_source_code()
{
    local groups_name="all,yunovo_adv"

    if [[ -f build/core/envsetup.mk && -f Makefile ]]; then

        if [[ "`is_android_project`" == "true" || "`is_inc_project`" == "true" ]]; then
            recover_standard_android_project

            echo
            show_vip "--> 已恢复源代码至原始状态."
        else
            log error "未恢复源代码至原始状态 ..."
        fi

        ## 重新初始化，防止本地提交代码影响版本
        if [[ -n "$manifest_branchN" ]];then

            if [[ "`is_mt6735t_project`" == "true" ]];then
                repo init -b ${manifest_branchN} -g ${groups_name} --reference=${reference_p}
            else
                ## 当封板分支不为空,则优先使用封板分支
                if [[ -n "${build_release_tag}"  ]]; then
                    repo init -b ${build_release_tag} --reference=${reference_p}
                else
                    repo init -b ${manifest_branchN} --reference=${reference_p}
                fi
            fi
        fi

        ## 获取 reference info
        get_repo_reference_info

        ## 更新源代码
        repo_sync_for_code
    else

        ## 下载中断处理,需要重新下载代码
        rm .repo/ -rf

        download_source_code
    fi
}

## 下载源代码
function download_source_code()
{
    local ssh_link="ssh://jenkins@gerrit.y:29419/manifest"
    local groups_name="all,yunovo_adv"

    if [[ ${manifest_branchN} ]];then

        if [[ "`is_mt6735t_project`" == "true" ]];then
            repo init -u ${ssh_link} -b ${manifest_branchN} -g ${groups_name} --reference=${reference_p}
        else
            ## 当封板分支不为空,则优先使用封板分支
            if [[ -n "${build_release_tag}" ]]; then
                repo init -u ${ssh_link} -b ${build_release_tag} --reference=${reference_p}
            else
                repo init -u ${ssh_link} -b ${manifest_branchN} --reference=${reference_p}
            fi
        fi
    fi

    ## 获取 reference info
    get_repo_reference_info

    ## 更新源代码
    repo_sync_for_code

    ## 第一次下载完成后，需要初始化环境变量
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile && "true" == "`is_android_project`" ]];then
        source_init
    else
        log error "The (.repo) not found!"
    fi
}

function make_ota()
{
    if [[ -n "$CUSTOM_MODEM" && -n "$CUSTOM_LK_LCM" ]];then

        if make -j${JOBS} ${compile_para[@]} CUSTOM_MODEM="$CUSTOM_MODEM" CUSTOM_LK_LCM="$CUSTOM_LK_LCM" CONFIG_CUSTOM_KERNEL_LCM="${CUSTOM_LK_LCM}"  otapackage;then

            echo
            show_vip "--> make otapackage end ..."
        else
            log error "--> make otapackage fail ..."
        fi

    elif [[ -n "$CUSTOM_MODEM" ]];then

        if make -j${JOBS} ${compile_para[@]} CUSTOM_MODEM="$CUSTOM_MODEM" otapackage;then

            echo
            show_vip "--> make otapackage end ..."
       else
            log error "--> make otapackage fail ..."
        fi

    elif [[ -n "$CUSTOM_LK_LCM" ]];then

        if make -j${JOBS} CUSTOM_LK_LCM="$CUSTOM_LK_LCM" CONFIG_CUSTOM_KERNEL_LCM="${CUSTOM_LK_LCM}" otapackage;then

            echo
            show_vip "--> make otapackage end ..."
       else
            log error "--> make otapackage fail ..."
        fi
    else
        echo
        echo "make -j${JOBS} ${compile_para[@]} otapackage"
        echo

        if make -j${JOBS} ${compile_para[@]} otapackage;then

            echo
            show_vip "--> make otapackage end ..."
        else
            log error "--> make otapackage fail ..."
        fi
    fi

    if [[ "$build_make_ota" == "false" ]];then
        send_email_to_admin
    fi
}

function make_droid()
{
    if [[ -n "$CUSTOM_MODEM" && -n "$CUSTOM_LK_LCM" ]];then

        if make -j${JOBS} ${compile_para[@]} CUSTOM_MODEM="$CUSTOM_MODEM" CUSTOM_LK_LCM="$CUSTOM_LK_LCM" CONFIG_CUSTOM_KERNEL_LCM="${CUSTOM_LK_LCM}" ;then

            echo
            show_vip "--> make project end ..."
       else
            log error "--> make android failed !"
        fi

    elif [[ -n "$CUSTOM_MODEM" ]];then

        if make -j${JOBS} ${compile_para[@]} CUSTOM_MODEM="$CUSTOM_MODEM";then

            echo
            show_vip "--> make project end ..."
       else
            log error "--> make android failed !"
        fi

    elif [[ -n "$CUSTOM_LK_LCM" ]];then

        if make -j${JOBS} CUSTOM_LK_LCM="$CUSTOM_LK_LCM" CONFIG_CUSTOM_KERNEL_LCM="${CUSTOM_LK_LCM}";then

            echo
            show_vip "--> make project end ..."
       else
            log error "--> make android failed !"
        fi

    else
        echo
        echo "make -j${JOBS} ${compile_para[@]}"
        echo

        if make -j${JOBS} ${compile_para[@]};then

            echo
            show_vip "--> make project end ..."
        else
            log error "--> make android failed !"
        fi
    fi

    if [[ "$build_make_ota" == "false" ]];then
        send_email_to_admin
    fi
}

## 编译系统源代码
function make_yunovo_android()
{
    # 编译开始前,先处理云智客制化
    handle_yunovo_custom

if ${build_debug};then
    if [[ ${build_clean} == "true" ]];then
        echo
        echo "make -j${JOBS} clean"
        echo

        if make -j${JOBS} clean;then

            echo
            show_vip "--> make clean end ..."
        else
            log error "--> make clean fail ..."
        fi
    else
        echo
        echo "make -j${JOBS} installclean ${compile_para[@]}"
        echo

        if make -j${JOBS} installclean ${compile_para[@]};then

            echo
            show_vip "--> make installclean end ..."
        else
            log error "--> make installclean fail ..."
        fi
    fi

    if [[ "$build_update_api" == "true" ]];then
        echo
        echo "make update-api -j${JOBS}"
        echo

        if make update-api -j${JOBS};then
            echo
            show_vip "--> make update-api end !"
        else
            log error "make update-api fail ... "
        fi
    else
        log warn "This time you don't exec make update-api."
    fi

    ## 编译android
    make_droid

    if [[ "$build_make_ota" == "true" ]];then

        ## 编译OTA包
        make_ota

        ## 编译差分包
        if [[ -n "`echo ${yunovo_pre_version} | sed -n '/^[S|V]/p'`" ]]; then
            make_yunovo_inc
        fi

        ## 编译假包
        if [[ ${build_fake_ota} == "true" ]]; then
            make_fake_package
        fi
    else
        echo
        show_viy "build_make_ota = $build_make_ota"
    fi

    auto_create_manifest
fi

    ## 备份版本
    copy_image_version

    ## 版本上传至服务器
    rsync_image_upload_server

    ## 发送有给项目部
    send_email_to_project
}

# 制作差分包
function make_inc() {

    local cmd=
    local OTA_FILE=${tmpfs}/ota/${OTA_FILE}

    local inc_pack="-i ${ota_previous} ${ota_current} ${OTA_FILE}"

    cmd="${ota_core_py} -k ${signature_type_p} ${inc_args} ${inc_pack}"

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

# 制作差分包,真的指定版本
function make_yunovo_inc() {

    local ota_previous=
    local ota_current=`ls ${OUT}/obj/PACKAGING/target_files_intermediates/*${build_device}-target_files*.zip`

    local pre_version=`echo ${yunovo_pre_version} | awk -F '_' '{ print $1 }'`
    local curr_version=${build_version}

    local pre_version_p=${tmpfs}/pre_rom
    local rom_version_on_service_p=`ssh ${git_username}@${f1_server} find ${share_rom_p}/Debug ${share_rom_p}/Release -name ${yunovo_pre_version}`

    if [[ ! -d ${pre_version_p}  ]]; then
        mkdir -p ${pre_version_p}
    fi

    if [[ -n ${pre_version} && -n ${curr_version} ]]; then
        OTA_FILE=${curr_version}\_for\_${pre_version}.zip
    else
        log error "The pre_version curr_version is null ..."
    fi

    # 1.获取服务器待升级的版本
    if [[ -n "${rom_version_on_service_p}" ]]; then
        echo "rsync -av ${git_username}@${f1_server}:${rom_version_on_service_p} ${pre_version_p}"
        echo '--------'
        rsync -av ${git_username}@${f1_server}:${rom_version_on_service_p} ${pre_version_p}
    else
        log error "The rom_version_on_service_p is null ..."
    fi

    echo "find ${pre_version_p} -name ${custom_version}_*.zip | grep -v inc"
    echo '--------'
    ota_previous=`find ${pre_version_p} -name ${custom_version}_*.zip | grep -v inc`
    if [[ -z "${ota_previous}" ]]; then
        log error "The ota_previous is null ..."
    fi

    echo "ota_previous  = "${ota_previous}
    echo "ota_current   = "${ota_current}
    echo "pre_version   = "${pre_version}
    echo "curr_version  = "${curr_version}
    echo "pre_version_p = "${pre_version_p}
    echo "OTA_FILE      = "${OTA_FILE}

    ### 2.编译OTA包存放指定路径
    if [[ "`is_yunovo_project`" == "true" && -f ${ota_previous} && -f ${ota_current} ]];then
        make_inc
    fi

    echo
    show_vip "--> make yunovo inc package end ..."
}

function make_fake_package() {

    local cmd=""
    local extra_args='-v -o'
    local sign_target_files_py=""

    local ota_previous=`ls ${OUT}/obj/PACKAGING/target_files_intermediates/*${build_device}-target_files*.zip`
    local ota_current=${tmpfs}/target_files-fake_package.zip

    local pre_version_p=${tmpfs}/pre_rom

    if [[ ! -d ${pre_version_p}  ]]; then
        mkdir -p ${pre_version_p}
    fi

    OTA_FILE=fake_package.zip

    if [[ -z "${ota_previous}" || ! -f ${ota_previous}  ]]; then
        log error "The ota previous has null or it don't exist ..."
    fi

    if [[ -z "${ota_current}" ]]; then
        log error "The ota current has null or don't exist ..."
    fi

    # 处理重签基准包,关键参数
    handle_common_variable_for_target_file

    if [[ "`is_support_fake`" == "true" ]]; then
        extra_args=${extra_args}" -f"
    fi

    # 1. 生成假基准包
    cmd="${sign_target_files_py} ${extra_args} ${ota_previous} ${ota_current}"

    print_and_exec_cmd

    # 2. 与假基准包差分升级假包
    if [[ "`is_yunovo_project`" == "true" ]];then
        make_inc
    fi

    echo
    show_vip "--> make fake package end ..."
}

#####################################################
##
##  函数: init_system_path
##  功能: 创建需要新建的路径结构
#
##  描述: 1 据版型 `get_board_type`
##        2 据版本 <android不同版本> `get_android_version`
##        3.据单独版本 ①. `is_51_android` ②. `is_60_android` ③. `is_81_android`
##
####################################################
function init_system_path() {

    unset pathfs

    pathfs[${#pathfs[@]}]=${host_tools_p}/bin

    if [[ "`is_lib64_platfrom`" == "true" ]]; then
        pathfs[${#pathfs[@]}]=${host_tools_p}/lib64
    elif [[ "`is_lib32_platfrom`" == "true" ]]; then
        if [[ "`is_sc_project`" == "true" ]]; then
            pathfs[${#pathfs[@]}]=${host_tools_p}/lib64
        else
            pathfs[${#pathfs[@]}]=${host_tools_p}/lib
        fi
    else
        pathfs[${#pathfs[@]}]=${host_tools_p}/lib
    fi

    pathfs[${#pathfs[@]}]=${security_file}
    pathfs[${#pathfs[@]}]=${release_tools_p}
}

#####################################################
##
##  函数: init_image_path
##  功能: 创建需要新建的路径结构
#
##  描述: 1 据版型 `get_board_type`
##        2 据版本 <android不同版本> `get_android_version`
##        3.据单独版本 ①. `is_51_android` ②. `is_60_android` ③. `is_81_android`
##
####################################################
function init_image_path() {

    unset pathfs

    pathfs[${#pathfs[@]}]=${DEST_PATH}
    pathfs[${#pathfs[@]}]=${PAC_PATH}
    pathfs[${#pathfs[@]}]=${BACKUP_PATH}
    pathfs[${#pathfs[@]}]=${OTA_PATH}
    pathfs[${#pathfs[@]}]=${OTA_INC}
    pathfs[${#pathfs[@]}]=${OTA_FAKE}

    if [[ "`is_sc_project`" != "true" ]];then
        pathfs[${#pathfs[@]}]=${DEST_PATH}/database/ap
        pathfs[${#pathfs[@]}]=${DEST_PATH}/database/moden
    fi
}

#####################################################
##
##  函数: init_copy_framework
##  功能: 备份展现平台 out/host/linux-x86/framework 路径下的文件
#
##  描述: 1 据版型 `get_board_type`
##        2 据版本 <android不同版本> `get_android_version`
##        3.据单独版本 ①. `is_51_android` ②. `is_60_android` ③. `is_81_android`
##
####################################################
function init_copy_framework() {

    unset copyfs

    copyfs[${#copyfs[@]}]=signapk.jar
    copyfs[${#copyfs[@]}]=dumpkey.jar
    copyfs[${#copyfs[@]}]=BootSignature.jar
}

#####################################################
##
##  函数: init_pac_script
##  功能: 备份展现平台脚本文件
#
##  描述: 1 据版型 `get_board_type`
##        2 据版本 <android不同版本> `get_android_version`
##        3.据单独版本 ①. `is_51_android` ②. `is_60_android` ③. `is_81_android`
##
####################################################
function init_pac_script() {

    unset copyfs

    copyfs[${#copyfs[@]}]=pac_via_conf.pl
    copyfs[${#copyfs[@]}]=UpdatedPacCRC_Linux
}

#####################################################
##
##  函数: init_copy_libxx
##  功能: 备份 system/libxx 目录下的文件
#
##  描述: 1 据版型 `get_board_type`
##        2 据版本 <android不同版本> `get_android_version`
##        3.据单独版本 ①. `is_51_android` ②. `is_60_android` ③. `is_81_android`
##
####################################################
function init_copy_libxx() {

    unset copyfs

    copyfs[${#copyfs[@]}]=libc++.so
    copyfs[${#copyfs[@]}]=liblog.so
    copyfs[${#copyfs[@]}]=libpcre2.so
    copyfs[${#copyfs[@]}]=libcutils.so
    copyfs[${#copyfs[@]}]=libopenjdkjvm.so
    copyfs[${#copyfs[@]}]=libopenjdkjvmti.so
    copyfs[${#copyfs[@]}]=libopenjdk.so
    copyfs[${#copyfs[@]}]=libconscrypt_openjdk_jni.so
    copyfs[${#copyfs[@]}]=libselinux.so
    copyfs[${#copyfs[@]}]=libext2fs-host.so
    copyfs[${#copyfs[@]}]=libext2_blkid-host.so
    copyfs[${#copyfs[@]}]=libext2_com_err-host.so
    copyfs[${#copyfs[@]}]=libext2_e2p-host.so
    copyfs[${#copyfs[@]}]=libext2fs-host.so
    copyfs[${#copyfs[@]}]=libext2_misc.so
    copyfs[${#copyfs[@]}]=libext2_quota-host.so
    copyfs[${#copyfs[@]}]=libext2_uuid-host.so
    copyfs[${#copyfs[@]}]=libsparse-host.so
    copyfs[${#copyfs[@]}]=libz-host.so
    copyfs[${#copyfs[@]}]=libbase.so

    if [[ "${build_make_ota}" == "true" ]]; then
        copyfs[${#copyfs[@]}]=libbrotli.so
    fi
}

#####################################################
##
##  函数: init_copy_bin
##  功能: 备份 system/bin 目录下的文件
#
##  描述: 1 据版型 `get_board_type`
##        2 据版本 <android不同版本> `get_android_version`
##        3.据单独版本 ①. `is_51_android` ②. `is_60_android` ③. `is_81_android`
##
####################################################
function init_copy_bin() {

    unset copyfs

    copyfs[${#copyfs[@]}]=acp
    copyfs[${#copyfs[@]}]=aapt
    copyfs[${#copyfs[@]}]=bsdiff
    copyfs[${#copyfs[@]}]=e2fsck
    copyfs[${#copyfs[@]}]=imgdiff
    copyfs[${#copyfs[@]}]=make_ext4fs
    copyfs[${#copyfs[@]}]=minigzip
    copyfs[${#copyfs[@]}]=mkbootfs
    copyfs[${#copyfs[@]}]=mkbootimg
    copyfs[${#copyfs[@]}]=simg2img
    copyfs[${#copyfs[@]}]=zipalign
    copyfs[${#copyfs[@]}]=mkuserimg.sh
    copyfs[${#copyfs[@]}]=bro
    copyfs[${#copyfs[@]}]=boot_signer
}


#####################################################
##
##  函数: init_copy_image
##  功能: 备份 1' 公共的IMG文件, 2' 版本特有的IMG文件
#
##  描述: 1 据版型 `get_cpu_type`
##        2 据版本 <android不同版本> `get_android_version`
##        3.据单独版本 ①. `is_51_android` ②. `is_60_android` ③. `is_81_android`
##
####################################################
function init_copy_image() {

    unset copyfs

    # 1. 公共IMG文件
    copyfs[${#copyfs[@]}]=boot.img
    copyfs[${#copyfs[@]}]=system.img
    copyfs[${#copyfs[@]}]=recovery.img
    copyfs[${#copyfs[@]}]=cache.img

    if [[ "`is_81_android`" == "true" ]]; then
        copyfs[${#copyfs[@]}]=vendor.img
        copyfs[${#copyfs[@]}]=odmdtbo.img
    fi

    copyfs[${#copyfs[@]}]=userdata.img

    if [[ "`is_odm_partition`" == "true" ]]; then
        copyfs[${#copyfs[@]}]=odm.img
    else
        copyfs[${#copyfs[@]}]=custom.img
    fi

    copyfs[${#copyfs[@]}]=secro.img

    copyfs[${#copyfs[@]}]=logo.bin

    ## Y_wilber,temp, #{
    copyfs[${#copyfs[@]}]=tee.img
    ## Y_wilber #}

    if [[ "`get_cpu_type`" == "mt6735" ]]; then
        copyfs[${#copyfs[@]}]=tee.img
        copyfs[${#copyfs[@]}]=trustzone.bin
    fi

    copyfs[${#copyfs[@]}]=preloader_${build_device}.bin

    if [[ -f "`ls ${OUT}/MT*_Android_scatter.txt`" ]]; then
        copyfs[${#copyfs[@]}]=`basename $(ls ${OUT}/MT*_Android_scatter.txt)`
    else
        log error "The MT\*_Android_scatter.txt file has not found ..."
    fi

    if [[ -f "`ls ${OUT}/lk.*`" ]]; then
        copyfs[${#copyfs[@]}]=`basename $(ls ${OUT}/lk.*)`
    else
        __err "The lk.\* file has not found ..."
    fi

    # 2. 差异化版本IMAG文件
    case `get_cpu_type` in

        mt6762)
            copyfs[${#copyfs[@]}]=vbmeta.img
            copyfs[${#copyfs[@]}]=dtbo-verified.img
            copyfs[${#copyfs[@]}]=boot-verified.img
            copyfs[${#copyfs[@]}]=sspm-verified.img
            copyfs[${#copyfs[@]}]=spmfw-verified.img
            copyfs[${#copyfs[@]}]=md1dsp-verified.img
            copyfs[${#copyfs[@]}]=md1arm7-verified.img
            copyfs[${#copyfs[@]}]=md1img-verified.img
            copyfs[${#copyfs[@]}]=md3img-verified.img
            copyfs[${#copyfs[@]}]=odmdtbo-verified.img
            copyfs[${#copyfs[@]}]=recovery-verified.img
            copyfs[${#copyfs[@]}]=tee-verified.img

            ## Y_wilber,temp, #{
            copyfs[${#copyfs[@]}]=dtbo.img
            copyfs[${#copyfs[@]}]=sspm.img
            copyfs[${#copyfs[@]}]=spmfw.img
            copyfs[${#copyfs[@]}]=md1dsp.img
            copyfs[${#copyfs[@]}]=md1arm7.img
            copyfs[${#copyfs[@]}]=md1img.img
            copyfs[${#copyfs[@]}]=md3img.img
            copyfs[${#copyfs[@]}]=odmdtbo.img
            ## Y_wilber #}
        ;;

        *)
            if [[ "`is_90_android`" == "true" || "`is_81_android`" == "true" ]]; then
                copyfs[${#copyfs[@]}]=lk-verified.img
                copyfs[${#copyfs[@]}]=logo-verified.bin
            fi
        ;;
    esac
}

function init_droid_env() {

    HOST_OUT=`get_host_out`

}

# 初始化版本
function init_version_name() {

    if [[ "`is_root_project`" == "true" ]];then
        if [[ "`is_cta_project`" == "true" ]]; then
            if [[ -n "${second_version}" ]];then
                version_name=${first_version}.${second_version}_${time_for_version}
            else
                version_name=${first_version}_${time_for_version}
            fi
        else
            if [[ -n "${second_version}" ]];then
                version_name=${first_version}.${second_version}
            else
                version_name=${first_version}
            fi
        fi
    else
        if [[ -n "${second_version}" ]];then
            version_name=${first_version}.${second_version}_${time_for_version}
        else
            version_name=${first_version}_${time_for_version}
        fi
    fi
}

# 编译开始前, 先处理云智客制化
function handle_yunovo_custom() {

    # 0. 初始化
    init_droid_env
    init_version_name

    # 1. 客制化内容的覆盖
    if [[ "$build_update_code" == "true" ]];then

        # 旧车机项目不需要此步骤
        if [[ "`is_car_project`" == "false" ]];then
            copy_customs_to_droid
        fi
    fi

    if [[ "`is_zen_project`" == "true" ]];then

        # 主题包
        unzip_nxos_theme

        if [[ "${yunovo_board}" == "ck02" ]]; then

            # 集成麦谷流量
            unzip_vst_config
        fi

        if [[ "${build_signature_type}" == "true" ]]; then

            # 签名文件
            handle_system_security
        else
            echo
            show_vip "--> 公版签名."
        fi
    fi

    send_email_to_development
    handle_boot_logo
    handle_driver_mk

    if [[ "${build_make_ota}" == "true" || "${build_fake_ota}" == "true" ]];then
        handle_common_variable_for_inc
    fi
}
