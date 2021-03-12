#!/usr/bin/env bash

####################################### 公共变量 (全局变量)

# ------------------------------------- Jenkins

# Jenkins工作空间
workspace=""
# Jenkins项目名称
job_name=${JOB_NAME:-}
# CPU线程数
JOBS=`cat /proc/cpuinfo  | egrep 'processor' | wc -l`

f1_server=f1.y
hw_version=H3.1
version_p=~/.jenkins_make_version
time_for_version=`date +'%Y.%m.%d_%H.%M.%S'`
time_for_nxos_version=`date "+%s"`
rename_sdupdate=

# log输出等级
loglevel=0 #verbose:0; debug:1; info:2; warn:3; error:4
logfile=${tmpfs}/log/${shellfs##*/}".log"

# ------------------------------------- Jenkins build args

# 1. build_args <Zen平台构建者>
build_args=
build_builder=

# ------------------------------------- Jenkins common variable

## 临时文件
logfs=${tmpfs}/logfs
## 项目信息和manifest差异表
diff_table=${tmpfs}/diff.log
##版本存放路径
rom_p=/share/ROM
##rom信息存放路径
rom_path=${tmpfs}/rom
## lunch选择工程
lunch_project=""
## 客制化完整路径
prefect_name=""
## 项目版本号
yunovo_prj_name=""
## 系统版本号
system_version=""
## 基准包名称
ota_name=""
## OTA升级版本
fota_version=""

# ------------------------------------- Jenkins 邮件功能
## 邮件标题
titlefs=""
## 发件人地址
address=""
cc_address=""
## 发件人内容
contentfs=""

## make编译参数
declare -a compile_para
## V2.2主板参数
YUNOVO_HARDWARE_VERSION=""
## mode custom
CUSTOM_MODEM=""
## lcm config
CUSTOM_LK_LCM=""
## 音频等级
audio_level=""
LEV=""
## 开机LOGO名称
LOGO_N=""
## custom分区配置
MTK_CIP_SUPPORT=""
## tp参数配置
SPT_TP_TYPE=""
## lcm参数配置
SPT_LCM_TYP=""
## manifest
manifest_branchN=""
manifest_path=""
## 当前构建的版本为 Android or Yunos
make_version=""
## 当前构建版本输出路径
share_smb_p=""
## 应用构建版本输出路径
share_smb_app_p=""
## 应用构建版本输出路径
share_smb_ota_p=""
## 应用测试报告输出路径
share_test_report_p=""
## 新的系统版本号定义
yov_system_version=""
## 新的OTA升级版本
yov_fota_version=""
## 构建版本信息
VER=""
## 封板标签TAG
yov_release_tag=""
## 版本类型
yov_release_type=""
## 构建编号
yov_build_id=""
## 签名类型
yov_signature_type=""
## diffmanifest file name
DFN=
## 项目名称
declare -x YUNOVO_PRJ_NAME=""

################################ auto deploy
declare -a print_var_list
## 被依赖apk信息: 包名和SDK版本号
declare -A depends_info_from_apk
declare -A depends_info_from_the_machine
declare -A depends_channel_mode_from_the_machine

## 依赖关系是否正确? ([cn.yunovo.config]='true' [package_name]='is_correct_sdk_version')=
declare -A checking_apk_depends_on_from_the_machine
declare -A checking_apk_depends_on_from_the_server
declare -A checking_apk_depends_on_err
## 被依赖apk集合
declare -A depends_apk_list
## 可以安装被依赖apk集合
declare -A depends_apk_install_list
## 依赖关系是否正确
is_the_correct_deploy=""

############################### 钉钉机器人
# 机器人 webhook
robot="https://oapi.dingtalk.com/robot/send?access_token=79af021bdb51cd6ac596a572b4b6dee75ce52ae67ac6b9f204a7a3920a5ce3bc"
# 消息风格 test|link|markdown
T=

# ---------------------------- 消息组成部分
# 1. 标题
title="title"
# 2. 内容
content="这次一定要弄对."
# 3. 需要@谁?
phone=""
# 4. 链接 , link参数需要,而且不能为空.
url="https://open-doc.dingtalk.com/microapp/serverapi2/qf2nxq"

############################### 差分包
# 1. 核心脚本
ota_core_py=
# 2. 外部脚本
ota_extra_py=
# 3. 参数列表
inc_args=
# 4. 签名文件
signature_type_p=
# 5. 差分包文件
OTA_FILE=

############################### system env
DEVICE=""
ROOT=""
OUT=""

HOST_OUT=

## lunch
target_product=
target_build_variant=

## 调试开关,默认都执行,配置false不执行
DBG=true

if true; then
git_username="`git config --get user.name`"
gerrit_server="SZ.gerrit.tclcom.com"
gerrit_port="29418"
default_gerrit='git@shenzhen.gitweb.com'
else
git_username='git'
gerrit_server='shenzhen.gitweb.com'
gerrit_port='29418'

fi
############################### 服务器版本路径

# ----------------------------- 新版本路径,共享路径
# zen平台版本路径
zen_path=${rom_p}/share_nxos

# jenkins构建版本路径
jenkins_path=${rom_p}/share_jenkins

# ROM 路径
share_rom_p=
# OTA 路径
share_ota_p=
# APK 路径
share_apk_p=${zen_path}/APK

# ----------------------------- 旧版本路径,共享路径
test_path=${rom_p}/share_test
develop_path=${rom_p}/share_develop

# 备份文件
declare -a copyfs

# 临时文件创建
declare -a pathfs

# 版本号 V1.0.0 e.g : first version = v1; second version = 0.0 ; 时间轴
version_name=

############################### 仓库分支

# 云智根路径
YUNOVO_ROOT=yunovo

# 公共模块
YUNOVO_COMMON=device/common

# Zen计划仓库名
YUNOVO_CONFIG=NxCustomConfig
YUNOVO_BUILD=NxCustomBuild
YUNOVO_RES=NxCustomResource

nx_security=NxCustomSecurity

## 供阿里脚本使用相对于$(gettop)
BASE=`pwd`

################################ 临时路径
apk_release_p=${tmpfs}/APK/Release


################################ unbound variable
build_email=

################################ commom function

# 处理公共变量
function handle_common_variable() {

    # 1. build_builder
    build_args=${yunovo_args:=}
    if [[ -n ${build_args} ]]; then
        build_builder=`echo ${build_args} | awk -F, '{print $1}'`
        if [[ -z ${build_builder} ]]; then
            build_builder=${BUILD_USER}
        fi
    else
        build_builder=${BUILD_USER}
    fi

    # 2. 版本路径
    if [[ "`is_zen_project`" == "true" ]]; then
        if [[ "`is_zen_start`" == "true" ]]; then
            share_rom_p=${zen_path}/ROM
            share_ota_p=${zen_path}/OTA
        else
            share_rom_p=${jenkins_path}/ROM
            share_ota_p=${jenkins_path}/OTA
        fi
    else
        if [[ "`is_root_project`" == "true" ]];then
            if [[ "${is_test_version}" == "true" ]];then
                share_rom_p=${test_path}/test_root
            else
                share_rom_p=${develop_path}/test_develop
            fi
        else
            if [[ "${is_test_version}" == "true" ]];then
                share_rom_p=${test_path}/test
            else
                share_rom_p=${develop_path}/develop
            fi
        fi
    fi
}

## 处理公共参数
function handle_common_para()
{
    local separator=";"

    ## 1. 设置JAVA环境
    set_java_home_path

    ## 2. 获取cpu核数
    get_cpu_cores

    ## 3. 配置f1服务器smb共享路径
    get_smb_share_path

    ## 4. 处理lunch
    handle_lunch_project

    ## 5. 获取manifest分支名
    if [[ "`is_zen_project`" == "false" ]];then
        get_manifest_branch_name
    fi

    ## 6. 系统版本号与OTA
    handle_system_version

    ## 7. 定制sdupdate名称
    rename_sdupdate=sdupdate_"${build_prj_name}_${build_version}_${time_for_version}"

    ## --------------------------------- 全局变量赋值

    ## OTA基准包名称
    ota_name=${custom_version}\_${project_name}\_${first_version}.${second_version}

    if [[ -n "${build_prj_name}" ]]; then

        ## 构建版本信息
        VER="${build_prj_name}_${build_version}_${time_for_version}"

        ## diffmanifest file name
        DFN="${build_prj_name}"

        ## 项目名称
        yunovo_prj_name="YUNOVO_PRJ_NAME=${build_prj_name}"
    else
        log warn "The build_prj_name is null ...."
    fi

    if [[ "`is_zen_project`" == "true" ]];then

        ## ROM信息
        rom_info[${#rom_info[@]}]="${build_prj_name}${separator}${yov_system_version}${separator}${VER}"
    fi

    ## 封板标签属性
    yov_release_tag="YUNOVO_RELEASE_TAG=${VER}"

    ## 构建类型
    yov_release_type="YUNOVO_RELEASE_TYPE=${build_release_type}"

    ## 构建编号
    yov_build_id="YUNOVO_BUILD_ID=${BUILD_ID}"

    ## 签名类型
    yov_signature_type="YUNOVO_SIGNATURE_TYPE=${build_signature_type}"
}

## 处理编译app时的公共变量
function handle_common_variable_for_nxos()
{
    local serverN='\\f1.y'

    if [[ "common" == "${build_multi_channel}" ]]; then
        share_smb_app_p=${serverN}\\share_test\\NXOS\\${job_name}
    else
        share_smb_app_p=${serverN}\\share_test\\NXOS\\${job_name}\\${build_multi_channel[@]}
    fi
}

## 处理系统签名
function handle_system_security() {

    # 发布版本,使用云智签名
    if [[ -n "${build_release_tag}" ]];then
        if [[ -d ${tmpfs}/${nx_security} ]]; then
            cp -vf ${tmpfs}/${nx_security}/* ./build/target/product/security

            echo
            show_vip "--> 云智签名."
        fi
    fi
}

## 处理版本号与系统OTA
function handle_system_version()
{
    ## 系统版本号
    if [[ "`is_car_project`" == "true" || "`is_sc_project`" == "true" ]];then
        system_version=${custom_version}\_${project_name}\_${first_version}.${second_version}
    elif [[ "`is_public_project`" == "true" ]];then
        system_version=public_${hw_version}\_${first_version}.`get_project_real_name`.${second_version}
    else
        system_version=${custom_version}\_${hw_version}\_${first_version}.${project_name}.${second_version}
    fi

    ## OTA版本号, ro.build.display.id
    fota_version="SPT_VERSION_NO=${system_version}"
    is_public_version="IS_PUBLIC_VERSION=`is_public_project`"

    if [[ "`is_zen_project`" == "true" || "`is_car_project`" == "true" ]]; then

        ## 重新定义新系统版本号
        yov_system_version=`echo ${project_name} | tr 'a-z' 'A-Z' `_${build_version}_${custom_version}_${build_release_type}_${time_for_nxos_version}
        yov_fota_version="YUNOVO_SYSTEM_VERSION_FOTA=${yov_system_version}"
    fi
}

## 处理lunch选项项目
function handle_lunch_project()
{
    if [[ "$build_device" && "$build_type" ]];then

        if [[ "`is_sc_project`" == "true" ]];then
            lunch_project=${build_device}-${build_type}
        else
            lunch_project=full_${build_device}-${build_type}
        fi
    else
        log error "The lunch_project is null, please check it ."
    fi
}

## 处理开机Logo
function handle_boot_logo()
{
    local LOGO_P=""

    ## 当需要更新源码的时候，才去修改ProjectConfig.mk
    if [[ "$build_update_code" == "true" ]];then

        if [[ -f ${tmpfs}/.hw.config ]];then
            rm -rf ${tmpfs}/.hw.config
        fi
    fi

    case `get_android_version` in

        5.1)
            LOGO_P=bootable/bootloader/lk/dev/logo
            ;;

        6.0)
            LOGO_P=vendor/mediatek/proprietary/bootable/bootloader/lk/dev/logo
            ;;
        *)
            log warn "Curr android version: `get_android_version` ..."
            ;;
    esac

    if [[ -d ${LOGO_P} ]]; then
        ## 获取Logo文件名称
        LOGO_N=`find ${LOGO_P} -type d -name "yunovo_customs*"`
        LOGO_N=${LOGO_N##*/}
    fi

    if [[ -n "$LOGO_N" ]];then
        build_logo="BOOT_LOGO=${LOGO_N}"
    fi

    if [[ -n "$build_logo"  ]];then
        compile_para[${#compile_para[@]}]=${build_logo}
    fi

    echo "compile_para = ${compile_para[@]}"
}

## 解压 nxos theme
function unzip_nxos_theme() {

    local nxos_theme_zip=nxos_theme.zip

    local root_dir=${YUNOVO_ROOT}/${YUNOVO_CONFIG}/${prefect_name}

    local nxos_theme_dir=${root_dir}/yunovo/theme
    local nxos_theme_override_dir=${root_dir}/override/system/nxos

    if [[ ! -d ${nxos_theme_override_dir} ]]; then
        mkdir -p ${nxos_theme_override_dir}
    fi

    if [[ -f ${nxos_theme_dir}/${nxos_theme_zip} ]]; then

        # check file
        if [[ "`unzip -l ${nxos_theme_dir}/${nxos_theme_zip} | awk '{ print $NF }' | head -4 | tail -1 | awk -F '/' '{print $1}'`" != "theme" ]]; then
            log error "The nxos theme format error ..."
        fi

        if [[ -d ${nxos_theme_override_dir}/theme ]]; then
            rm -rf ${nxos_theme_override_dir}/theme/*
        fi

        unzip -q ${nxos_theme_dir}/${nxos_theme_zip} -d ${nxos_theme_override_dir}

    else
        __wrn "未发现主题包."
    fi
}

# 集成麦谷流量apk的配套配置,只有在zen平台上传system_override.zip文件后才会处理
function unzip_vst_config() {

    local vst_config_zip=system_override.zip

    local root_dir=${YUNOVO_ROOT}/${YUNOVO_CONFIG}/${prefect_name}

    local vst_config_dir=${root_dir}/yunovo
    local vst_config_override_dir=${root_dir}/override/system

    if [[ -f ${vst_config_dir}/${vst_config_zip} ]]; then

        # check file
        if [[ "`unzip -l ${vst_config_dir}/${vst_config_zip} | awk '{ print $NF }' | egrep -w init.*.rc | awk -F/ '{print $NF}'`" == "init.vst.firewall.rc" ]]; then

            if [[ -d ${tmpfs}/vst ]]; then
                rm -rf ${tmpfs}/vst/*
            fi

            unzip -q ${vst_config_dir}/${vst_config_zip} -d ${tmpfs}/vst

            cp -rf ${tmpfs}/vst/* ${vst_config_override_dir}
        else
            log error "未找到启动文件[init.vst.firewall.rc], 请检查压缩包 ..."
        fi
    else
        __wrn "未发现麦谷流量配置文件."
    fi
}

## 重新配置Java环境变量
function set_java_home_path()
{
    unset -v JAVA_HOME

    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    export JRE_HOME=${JAVA_HOME}/jre
    export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
    export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH

    if [[ "`is_mt6737t_project`" == "true" ]];then
        export ANDROID_JACK_EXTRA_ARGS="--verbose debug --sanity-checks on -D sched.runner=single-threaded"
    fi
}

# 拿到当前应用的中文名称
function get_app_chinese_name()
{
    case ${job_name} in

    nxCarService)
        build_app_name=${job_name}
        ;;

    nxTraffic)
        build_app_name=流量管理
        ;;

    *)
        build_app_name=${job_name}
        ;;
    esac
}

# 拿到当前应用支持的渠道号
function get_app_support_channel_no()
{
    local channel_no=""
    local rom_no=""

    if [[ -f ${WORKSPACE}/yunovo_multi_channel.cfg ]]; then
        while read line;
        do
            channel_no="`echo ${line} | cut -d '=' -f 1`"
            rom_no="`echo ${line} | cut -d '=' -f 2`"

            matchup[${channel_no}]=${rom_no}

        done < ${WORKSPACE}/yunovo_multi_channel.cfg

        #key=${!matchup[@]}
        #value=${matchup[@]}
        #print_ass_array "${key}" "$value"
    else
        log error "无法访问 ${WORKSPACE}/yunovo_multi_channel.cfg: 没有那个文件或目录"
    fi
}

# 打印并执行命令
function print_and_exec_cmd() {

    echo "cmd = ${cmd}"
    echo
    eval ${cmd}
}

## 拷贝客制化内容到$(gettop)目录下
function copy_customs_to_droid()
{
    local OLDP=`pwd`
    local select_project=${prefect_name}
    local gettop=$(gettop)
    local customs_path=
    local product_set_short=
    local configfs=

    # custom odm oem folder name
    local custom_p=""

    if [[ -d ${gettop}/yunovo/customs ]];then
        customs_path=${gettop}/yunovo/customs
    else
        customs_path=${gettop}/yunovo/NxCustomConfig
    fi

	if [[ -d "$customs_path" ]]; then
		customs_path=$(cd ${customs_path} && pwd)
	else
        if [[ "`is_zen_project`" == "true" ]]; then
            log warn "The $customs_path dir no found ..."
        fi

        return 0
	fi

	local product_set_top=${customs_path}

    if [[ "`is_zen_project`" == "true" ]];then
        configfs=project_config.xml

        if [[ -n "`echo ${customs_path} | grep NxCustomConfig`" ]];then
            product_set_short=`find ${product_set_top} -name ${configfs} | awk -F/ '{print $(NF-2) "/" $(NF-1)}' | sort`
        fi
    else
        configfs=proj_help.sh

        if [[ -n "`echo $customs_path`" ]];then
            product_set_short=`find ${product_set_top} -name ${configfs} | awk -F/ '{print $(NF-3) "/" $(NF-2) "/" $(NF-1)}' | sort`
        fi
    fi

    ##遍历所有客户方案配置
    local my_select=
    for custom_project in ${product_set_short}
    do
        if [[ "$select_project" == ${custom_project} ]];then
            my_select=${custom_project}
        fi
    done

	local product_select_path="$product_set_top/$my_select"
	if [[ -d "$product_select_path" && ! "$product_select_path" = "$product_set_top/" ]]; then

	    if [[ -f ${customs_path}/NowCustom.sh ]]; then
			old_product_select_path=$(sed -n '1p' ${customs_path}/NowCustom.sh)
			old_product_select_path=${old_product_select_path%/*}
			old_product_select_android=${old_product_select_path}/android
		fi

		## 新项目
		echo "${product_select_path}/$configfs" > ${customs_path}/NowCustom.sh

		#### 更新时间戳并拷贝到配置根目录
        if [[ "`is_zen_project`" == "true" ]];then
            project_select_android=${product_select_path}/override/android
        else
            project_select_android=${product_select_path}/android
        fi

        show_vig "select custom = $my_select"

        if [[ -d ${project_select_android} ]]; then

            if false;then
            ## 清除旧项目的修改
			echo "clean by $old_product_select_android" && chiphd_recover_standard_device_cfg ${old_product_select_android}

			## 确保新项目的修改纯净
			echo "clean by $project_select_android" && chiphd_recover_standard_device_cfg ${project_select_android}
            fi

			## 新项目代码拷贝
			update_all_type_file_time_stamp ${project_select_android}
			echo "copy source code : $project_select_android/*  " && cp -r ${project_select_android}/*  ${gettop}/ && show_vip "copy android custom done"
		else
            log warn "No config : $my_select"
		fi

        #  ## 处理[odm|oem]客制化分区
		if [[ -d ${product_select_path}/custom ]]; then

            if [[ "`is_odm_partition`" == "true" ]]; then
                custom_p=odm
            elif [[ "`is_oem_partition`" == "true" ]];then
                custom_p=oem
            else
                # 当检查到为custom分区时,无需处理直接返回
                return 0
            fi

            cd ${product_select_path} > /dev/null

            if [[ -d ${custom_p} ]]; then
                cp -vrf custom/. ${custom_p}
                echo
            else
                log print "The custom path:${custom_p} no exist ..."

                ln -s custom ${custom_p}
            fi

            cd ${OLDP} > /dev/null
        else
            log warn "The custom dir no found ..."
		fi
	fi
}

## 重命名开机logo名称
function copy_and_rename_logo()
{
    local JS_DIR=logo
    local LODO_DIR=yoc_logo_hd720
    local SRC_DIR=bootable/bootloader/lk/project
    local DEVMK=${DEVICE_PROJECT}.mk

    local SRC_LOGO=`echo BOOT_LOGO := cmcc_lte_hd720`
    local DEST_LOGO=`echo BOOT_LOGO := ${LODO_DIR}`

    ## 1. 修改正确的名称
    if [[ -d ${JS_DIR} ]];then

        ## 修改正确的路径
        mv ${JS_DIR} ${LODO_DIR}

        ## 修改正确的路径
        if [[ -f ${LODO_DIR}/${JS_DIR}1.bmp ]];then
            mv ${LODO_DIR}/${JS_DIR}1.bmp ${LODO_DIR}/${LODO_DIR}_uboot.bmp
        fi

        if [[ -f ${LODO_DIR}/${JS_DIR}2.bmp ]];then
            mv ${LODO_DIR}/${JS_DIR}2.bmp ${LODO_DIR}/${LODO_DIR}_kernel.bmp
        else
            cp ${LODO_DIR}/${LODO_DIR}_uboot.bmp ${LODO_DIR}/${LODO_DIR}_kernel.bmp
        fi
    fi

    ## 2. 拷贝至源码
    mv ${LODO_DIR} ${SRC_DIR}

    ## 3. 更新编译指定的logo
    sed -i "s/${SRC_LOGO}/${DEST_LOGO}/g" ${SRC_DIR}/${DEVMK}
    if [[ $? -eq 0 ]];then
        show_vig "sed ok ..."
    else
        __err "sed fail ..."
    fi
}

## 处理客制化驱动配置文件,1. HardWareConfig.mk 2.drive.mk
function handle_driver_mk()
{
    local HWMK=HardWareConfig.mk
    local DRMK=drive.mk
    local DPMK=ProjectConfig.mk
    local DRMK_P=yunovo/NxCustomConfig/${yunovo_custom}/${yunovo_project}

    if [[ -f ${DEVICE}/${HWMK} && -f ${DEVICE}/${DPMK} && ! -f ${tmpfs}/.hw.config ]];then

        cat ${DEVICE}/${HWMK} >> ${DEVICE}/${DPMK}
        if [[ $? -eq 0 ]];then
            rm -rf ${DEVICE}/${HWMK}
            touch ${tmpfs}/.hw.config
        else
            log error "cat fail ... "
        fi

        echo
        echo "--------------------------------"
        echo "-    modify hardware config    -"
        echo "--------------------------------"
        echo

    elif [[ -f ${DEVICE}/${DPMK} && -f ${DRMK_P}/${DRMK} && ! -f ${tmpfs}/.hw.config ]];then

        cat ${DRMK_P}/${DRMK} >> ${DEVICE}/${DPMK}
        if [[ $? -eq 0 ]];then
            touch ${tmpfs}/.hw.config
        else
            log error "cat fail ... "
        fi

        echo
        echo "-----------------------------"
        echo "-    modify drive config    -"
        echo "-----------------------------"
        echo
    fi
}

## 获取manifest分支名
function get_manifest_branch_name()
{
    local preN=
    local prj_name=`get_project_real_name`

    local projectN=${prj_name%%_*}
    local customN=${prj_name#*_} && customN=${customN%%_*}
    local modeN=${prj_name#*_} && modeN=${modeN#*_}

    if [[ "`is_car_project`" == "true" ]];then
        case `get_android_version` in
            5.1)
                preN=yunovo
                ;;

            7.0)
                preN=mt8321/nougat
                ;;

            *)
                :
                ;;
        esac
    elif [[ "`is_4g_project`" == "true" ]];then
        preN=mt6735/volte
    elif [[ "`is_yunos_project`" == "true" ]];then

        if [[ "$make_version" == "Yunos" ]];then
            preN=yunos
        fi
    elif [[ "`is_mt6737t_project`" == "true" ]];then
        preN=mt6737t
    elif [[ "`is_mt6735t_project`" == "true" ]];then
        preN=mtk6735t
    fi ### is_car_project end

    ## manifest分支名称
    if [[ -n "$preN" ]];then
        if [[ ${customN} == ${modeN}  ]];then
            manifest_branchN="$preN/$projectN/$customN"
        else
            manifest_branchN="$preN/$projectN/$customN/$modeN"
        fi
    else
        if [[ ${customN} == ${modeN} ]];then
            manifest_branchN="$projectN/$customN"
        else
            manifest_branchN="$projectN/$customN/$modeN"
        fi
    fi
}

## 从zen平台获取Manifest分支名
function get_manifest_branch_name_from_zen()
{
    local project_config_p=${tmpfs}/${YUNOVO_CONFIG}/${yunovo_custom}/${yunovo_project}
    local project_config_xml=project_config.xml

    ## 1. 下载客制化仓库
    download_and_update_apk_repository yunovo/zenportal/NxCustomConfig ${yunovo_board}
    download_and_update_apk_repository yunovo/zenportal/NxCustomSecurity yunovo/master

    ## 2. 解析project_config.xml 获取branch name
    if [[ -f ${project_config_p}/${project_config_xml} ]];then
        manifest_branchN="`cat ${project_config_p}/${project_config_xml} | grep branch | awk -F '"' '{ print $4 }' | sed -e 's#%#/#g' `"
        manifest_path="`cat ${project_config_p}/${project_config_xml} | grep branch | awk -F '"' '{ print $4 }' | sed -e 's#%#_#g' `"

        if [[ -z "$manifest_branchN" ]];then
            log error "The manifest branch is null."
        fi

        if [[ -z "$manifest_path" ]]; then
            log error "The manifest path is null."
        fi
    else
        ## 若Zen平台未配置文件，则通知构建者.
        log error "The project_config.xml file no found."
    fi
}

## 拷贝邮件内容到指定路径
function copy_email_content()
{
    local BASE_PATH=""
    local DEST_PATH=""
    local diffmanifest_p=${version_p}

    local custom_name=${project_name}\_${custom_version}

    if [[ "`is_public_project`" == "true" ]];then
        BASE_PATH=${diffmanifest_p}/`get_project_real_name`/${version_name}
    else
        BASE_PATH=${diffmanifest_p}/${project_name}/${custom_name}/${version_name}
    fi

    DEST_PATH=${BASE_PATH}

    if [[ ! -d ${DEST_PATH} ]];then
        mkdir -p ${DEST_PATH}
    fi

    # 备份邮件内容至服务器
    if [[ -f ${contentfs} ]];then
        cp -f ${contentfs} ${DEST_PATH}
    else
        __err "The ${contentfs} no exist ..."
    fi
}

## 备份邮件内容至f1服务器
function rsync_email_content_upload_server()
{
    local userN="`git config --get user.name`"
    local serverN=f1.y

    local jenkins_server="${userN}@${serverN}"
    local diffmanifest_p=${version_p}

    local share_diffmanifest_p=

    if [[ ! -d ${diffmanifest_p} ]];then
        mkdir -p ${diffmanifest_p}
    fi

    if [[ "`is_root_project`" == "true" ]];then
        if [[ "${is_test_version}" == "true" ]];then
            share_diffmanifest_p=${test_path}/diffmanifest_root
        else
            share_diffmanifest_p=${develop_path}/diffmanifest_root
        fi
    else
        if [[ "${is_test_version}" == "true" ]];then
            share_diffmanifest_p=${test_path}/diffmanifest
        else
            share_diffmanifest_p=${develop_path}/diffmanifest
        fi
    fi

    if [[ -n "${share_diffmanifest_p}" ]];then
        rsync -av ${diffmanifest_p}/ ${jenkins_server}:${share_diffmanifest_p}
    else
        log error "The share_diffmanifest_p variable is null ..."
    fi

    if [[ -d "${diffmanifest_p}" ]];then
        rm -rf "${diffmanifest_p}"/*
    fi

    echo
    show_vip "--> sync diffmanifest end ..."
}

## 发送邮件给jenkins管理员
function send_email_to_admin()
{
    address="notify@yunovo.cn"
    contentfs="build ${build_prj_name} project successful ..."
    titlefs="${build_prj_name} 项目编译成功啦!!!"

    if [[ "`is_root_project`" == "false" ]];then
        auto_send_email
    fi
}

## 发送邮件给整个研发部
function send_email_to_development()
{
    address="xingyf@yunovo.cn"
    cc_address="drive_dev@yunovo.cn"
    contentfs="$tmpfs/${DFN}.html"
    titlefs="${build_prj_name} project. [repo diffmanifest]"

    email_massage_to_development
    email_massage_has_colors

    if [[ "`is_root_project`" == "false" ]];then
        copy_email_content
        rsync_email_content_upload_server
        auto_send_email
    fi
}

## 发送邮件给app开发者
function send_email_to_nxos_app_developer()
{
    if [[ -n "$build_email" ]];then
        address=${build_email}
        cc_address="${build_cc_address}"
        titlefs="${build_app_name}: [${job_name}] 构建成功 ..."
        contentfs="$tmpfs/${DFN}.html"

        email_massage_to_apps
        email_massage_has_colors

        auto_send_email
    fi
}

## 发送邮件给app开发者
function send_email_to_ota_builder()
{
    if [[ -n "$build_email" ]];then
        address=${build_email}
        cc_address="${build_cc_address}"
        titlefs="${build_prj_name} OTA 构建成功 ..."
        contentfs="$tmpfs/${DFN}.html"

        email_massage_to_ota_builder
        email_massage_has_colors

        auto_send_email
    fi
}

## zen平台,在编译出错的时候,抄送邮件给指定开发人员
function send_email_when_build_failed()
{
    if [[ -n "$build_email" ]];then

        address=${build_email}
        cc_address="${build_cc_address}"

        case ${type_err} in

            1) ## 编译错误
                titlefs="${job_name} 编译失败. 构建编号:$BUILD_DISPLAY_NAME"
                contentfs="$tmpfs/${DFN}.html"  ## 文件 diff_table=$tmpfs/diff.log
                ;;

            2) ## 部署错误
                titlefs="${job_name} 部署失败. 构建编号:$BUILD_DISPLAY_NAME"
                contentfs="$tmpfs/${DFN}.html"
                ;;

            3) ## 测试错误
                titlefs="${job_name} 测试失败. 构建编号:$BUILD_DISPLAY_NAME"
                contentfs="$tmpfs/${DFN}.html"
                ;;

            4) ## 构建diffmanifest失败
                titlefs="${job_name} 构建失败. 构建编号:$BUILD_DISPLAY_NAME"
                contentfs="<${job_name}>: 构建失败, 请尽快与管理员协调解决!"
                ;;

            5) ## 构建OTA失败
                titlefs="${job_name} OTA构建失败. 构建编号:$BUILD_DISPLAY_NAME"
                contentfs="<${job_name}>: OTA构建失败, 请尽快与管理员协调解决!"
                ;;

            *) ## 默认配置
                if [[ "`is_app_project`" == "true" ]] ; then
                    titlefs="${build_app_name}: [${job_name}] 构建失败. 构建编号:$BUILD_DISPLAY_NAME"
                    contentfs="<${job_name}>应用: 构建失败, 请尽快与开发人员协调解决! "
                else
                    titlefs="${build_prj_name} 项目构建失败. job: ${job_name} 构建编号:$BUILD_DISPLAY_NAME"
                    contentfs="[${build_prj_name}] 项目编译失败啦,请尽快与开发人员协调解决."
                fi
                ;;
        esac

        case ${type_err} in

            1|2|3)
                ## 邮件发送给应用开发者
                email_massage_to_apps
                email_massage_has_colors
            ;;

            4)
                :
            ;;

            5)
                :
            ;;

            *)
                :
            ;;
        esac

        auto_send_email
    fi
}

## zen平台发送邮件给项目经理,并抄送开发人员
function send_email_to_project()
{
    if [[ -n "$build_email" ]];then

        address=${build_email}
        cc_address="${build_cc_address}"
        contentfs="$tmpfs/${DFN}.html"
        titlefs="${build_prj_name}项目编译成功了, 请尽快安排测试吧!"

        email_massage_to_project
        email_massage_has_colors

        auto_send_email
    fi
}

#####################################################
##
##  函数: auto_send_email
##  功能: 提供邮件发送功能,关键参数有三个, address cc_address contenfs
##　参数: 1. 收件人        address
##        2. 抄送人　　　　cc_address
##        3. 邮件内容      contenfs
##
####################################################
function auto_send_email()
{
    local user="notify@yunovo.cn"
    local key=n123456
    local email_sender="jenkins<$user>"
    local server_address="smtp.exmail.qq.com"
    local email_charset="message-charset=utf-8"
    local content_type="message-content-type=html"

    show_vig "@@ cc = $cc_address"

    ## 若内容是文件，则发送文件;若内容是非文件，则发送字符串.
    if [[ -f "$contentfs" ]];then

        ## 是否需要抄送邮件.
        if [[ -n "$cc_address" ]];then
            sendEmail -f ${email_sender} -s ${server_address} -u ${titlefs} -o ${email_charset} -o ${content_type} -xu ${user} -xp ${key} -t ${address} -cc ${cc_address} -o message-file=${contentfs}
        else
            sendEmail -f ${email_sender} -s ${server_address} -u ${titlefs} -o ${email_charset} -o ${content_type} -xu ${user} -xp ${key} -t ${address} -o message-file=${contentfs}
        fi

        ## 删除该文件
        rm -r ${contentfs}
    elif [[ -n "$contentfs" ]];then

        ## 是否需要抄送邮件.
        if [[ -n "$cc_address" ]];then
            sendEmail -f ${email_sender} -s ${server_address} -u ${titlefs} -o ${email_charset} -o ${content_type} -xu ${user} -xp ${key} -t ${address} -cc ${cc_address} -m ${contentfs}
        else
            sendEmail -f ${email_sender} -s ${server_address} -u ${titlefs} -o ${email_charset} -o ${content_type} -xu ${user} -xp ${key} -t ${address} -m ${contentfs}
        fi
    else
        contentfs="邮件内容为空."
        sendEmail -f ${email_sender} -s ${server_address} -u ${titlefs} -o ${email_charset} -o ${content_type} -xu ${user} -xp ${key} -t ${address} -m ${contentfs}
    fi
}

#####################################################
##
##  函数: handle_common_variable_for_inc
##  功能: 提供构建差分包基础变量
##  变量: 1. ota_core_py       - 核心脚本
##        2. ota_extra_py      - 外部脚本
##        3. inc_args          - 差分包参数
##        4. signature_type_p  - 签名文件
##
####################################################
function handle_common_variable_for_inc() {

    local lk_p=
    local preloader_p=

    show_vip "--> start init for inc variable ...."

    # 1. 核心脚本
    ota_core_py=./build/tools/releasetools/ota_from_target_files
    if [[ ! -f "${ota_core_py}" && -z ${ota_core_py} ]]; then
        log error "The ota_code_py file was not found ..."
    fi

    # 2. 外部脚本
    case `get_android_version` in

        6.0)
            if [[ "`is_sc_project`" == "true" ]]; then
                ota_extra_py=
            else
                ota_extra_py=./device/mediatek/build/releasetools/mt_ota_from_target_files.py
            fi
        ;;

        8.1)
            ota_extra_py=./vendor/mediatek/proprietary/scripts/releasetools/mt_ota_from_target_files.py
        ;;

        *)
            ota_extra_py=
        ;;
    esac

    if [[ ! -f ${ota_extra_py} ]]; then
        case `get_android_version` in

            5.1|9.0)
                log warn  "The ${ota_extra_py} file script not exist in android`get_android_version` ..."
                ;;

            *)
                if [[ "`is_sc_project`" == "true" ]]; then
                    log warn  "The ${ota_extra_py} file script not exist in android`get_android_version` ..."
                else
                    log error "The ${ota_extra_py} file script not exist in android`get_android_version` ..."
                fi
            ;;
        esac
    fi

    # 3. inc_args 差分包的参数列表
    if [[ "${build_clean_data}" == "true" ]];then
        inc_args="-w "
    fi

    if [[ "`is_ota_preloader`" == "true" ]];then

        if [[ "`is_android_project`" == "true" ]]; then
            lk_p=${OUT}/lk.bin
            preloader_p=${OUT}/preloader_`get_build_var TARGET_DEVICE`.bin
        elif [[ "`is_inc_project`" == "true" ]];then
            local preloader_bin=preloader_`get_build_var TARGET_DEVICE`.bin

            lk_p=${ota_path}/binfs/lk.bin
            preloader_p=${ota_path}/binfs/${preloader_bin}
        elif [[ "`is_rom_release`" == "true" ]];then
            lk_p=${resign_rom_p}/${build_rom_version}/${rom_version_p}/lk.bin
            preloader_p=`ls ${resign_rom_p}/${build_rom_version}/${rom_version_p}/preloader_*.bin`
        fi

        if [[ -n "${lk_p}" ]]; then
            echo "lk_p = " ${lk_p}
        else
            log error "The lk_p variable is null ..."
        fi

        if [[ -n "${preloader_p}" ]]; then
            echo "preloader_p = " ${preloader_p}
        else
            log error "The preloader_p variable is null ..."
        fi

        if [[ ${build_lk} == "true" && ${build_preloader} == "true" ]]; then
            inc_args=${inc_args}"-r ${preloader_p} -u ${lk_p}"
        elif [[ ${build_preloader} == "true" ]];then
            inc_args=${inc_args}"-r ${preloader_p}"
        elif [[ ${build_lk} == "true" ]];then
            inc_args=${inc_args}"-u ${lk_p}"
        fi

        if [[ -f "${lk_p}" ]]; then
            echo "md5:"
            md5sum ${lk_p}
        fi


        if [[ -f "${preloader_p}" ]]; then
            md5sum ${preloader_p}
            echo
        fi
    else
        echo "---- Android`get_android_version` for make inc ..."
        echo

        case `get_android_version` in

            5.1)
                inc_args=${inc_args}
                ;;

            6.0)
                if [[ "`is_sc_project`" == "true" ]]; then
                    inc_args=${inc_args}
                else
                    inc_args=${inc_args}"-v --block -s ${ota_extra_py}"
                fi
                ;;

            8.1)
                inc_args=${inc_args}"-v --block -s ${ota_extra_py}"
                ;;

            *)
                log error "It's not supported Upgrade on android`get_android_version` version ..."
                ;;
        esac
    fi

    # 4. 签名文件
    if [[ ${build_signature_type} == "true" && -d ${tmpfs}/${nx_security} ]]; then

        # 私有签名
        signature_type_p=./build/target/product/security/releasekey

        cp -vrf ${tmpfs}/${nx_security}/* `dirname ${signature_type_p}`
    else

        # 公版签名
        signature_type_p=./build/target/product/security/testkey
    fi
}

#####################################################
##
##  函数: handle_common_variable_for_target_file
##  功能: 提供制作基准包的基础变量
##  变量: 1. sign_target_files_py  - 重签脚本
##        2. extra_args            - 重签基准包参数
##
####################################################
function handle_common_variable_for_target_file() {

    # 1. 重签脚本
    sign_target_files_py="./build/tools/releasetools/sign_target_files_apks"
    if [[ ! -f ${sign_target_files_py} ]]; then
        log error "The ${sign_target_files_py} file has not found ..."
    fi

    # 2. 重签基准包参数
    case `get_cpu_type` in

        mt6580|mt8321)
            extra_args=${extra_args}" -r"
            ;;

        *)
            extra_args=${extra_args}
            ;;
    esac

    # 支持私有签名
    if [[ "${build_signature_type}" == "true" ]]; then
        extra_args=${extra_args}" -d `dirname ${signature_type_p}`"
    fi
}

### 同步版本到f1服务器
function rsync_image_upload_server()
{
    local userN="`git config --get user.name`"
    local serverN=f1.y

    local jenkins_server="${userN}@${serverN}"
    local firmware_path=${version_p}

    if [[ ! -d ${firmware_path} ]];then
        mkdir -p ${firmware_path}
    fi

    # 同步开始
    if [[ -n "${share_rom_p}" ]]; then
        rsync -av ${firmware_path}/ ${jenkins_server}:${share_rom_p}
    else
        log error "The share_rom_p variable is null ..."
    fi

    if [[ -d ${firmware_path} ]];then
        rm -rf ${firmware_path}/*
    fi

    if [[ -d ${tmpfs}/pre_rom ]]; then
        rm -rf ${tmpfs}/pre_rom/*
    fi

    if [[ -f ${tmpfs}/jenkins.ini ]]; then
        rm -f ${tmpfs}/jenkins.ini
    fi

    echo
    show_vip "--> sync end ..."
}


## 备份ROM版本
function copy_image_version()
{
    local BASE_PATH=""
    local custom_name=""
    local firmware_path=${version_p}

    if [[ "`is_public_project`" == "true" ]];then
        BASE_PATH=${firmware_path}/`get_project_real_name`/${version_name}
    elif [[ "`is_zen_project`" == "true" ]];then
        custom_name=${custom_version}
        BASE_PATH=${firmware_path}/${build_release_type}/`echo ${project_name} | tr 'a-z' 'A-Z'`/${custom_name}/${version_name}
    else
        custom_name=${project_name}\_${custom_version}
        BASE_PATH=${firmware_path}/${project_name}/${custom_name}/${version_name}
    fi

    echo
    show_vig "@@@ custom_name = $custom_name"

    local DEST_PATH=${BASE_PATH}/${system_version}
    local PAC_PATH=${BASE_PATH}/${system_version}_pac
    local BACKUP_PATH=${BASE_PATH}/${system_version}_backup
    local OTA_PATH=${BASE_PATH}/${system_version}_full_and_ota
    local OTA_INC=${BASE_PATH}/${system_version}_full_and_ota_inc
    local OTA_FAKE=${BASE_PATH}/${system_version}_full_and_ota_fake

    echo "BASE_PATH = $BASE_PATH"
    echo "DEST_PATH = $DEST_PATH"
    echo "OTA_PATH  = $OTA_PATH"
    echo

    # ################################################# 创建文件夹
    init_image_path
    enhance_create_dir

    # ################################################# 版本备份
    if [[ "`is_sc_project`" == "true" ]];then
        cp $(gettop)/release_images/`get_brand_name`/* ${DEST_PATH}

        if [[ -f ${DEST_PATH}/${build_device}-${build_type}-native_PacParam.pac ]]; then
            mv -vf ${DEST_PATH}/${build_device}-${build_type}-native_PacParam.pac ${PAC_PATH}/${system_version}.pac
        else
            log error "The pac file has not found ..."
        fi
    else
        # 备份IMG文件
        init_copy_image
        enhance_copy_file ${OUT} ${DEST_PATH}
        if [[ $? -eq 0 ]]; then
            show_vip "--> The file was copied successfully under the \${OUT} ... "
        fi

        # 备份MODEN FILE
        backup_moden_file

        echo
        show_vip "--> Copy image end in \${OUT} dir ..."
    fi

    if [[ "${build_make_ota}" == "true" ]];then
        backup_full_target_packages
    fi

    if [[ "`is_zen_project`" == "true" ]]; then
        copy_ota_tools
        backup_rom_json
    fi

    hanlde_copy_extra_transaction

    echo
    show_vip "--> copy out image finish ... in `hostname` server."
}

## 备份全量包和基准包
function backup_full_target_packages() {

    local personal_tailor_for_sdupdate=
    local sdupdate_for_car="${build_prj_name}${first_version}${second_version}${time_for_version}"

    # 1; 备份sdupdate.zip 即卡刷包
    if [[ -f "`ls ${OUT}/${target_product}-ota-*.zip`" ]];then
        cp -vf ${OUT}/${target_product}-ota-*.zip ${OTA_PATH}/sdupdate.zip

        echo
        show_vip "--> Copy sdupdate.zip successful ..."
    else
        log error "The sdupdate.zip file has not found ..."
    fi

    # 2; 备份基准包, 即用于制作差分包和重签名的目标包
    if [[ -f "`ls ${OUT}/obj/PACKAGING/target_files_intermediates/${target_product}-target_files*.zip`" ]];then
        cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/${target_product}-target_files*.zip ${OTA_PATH}/${system_version}.zip

        echo
        show_vip "--> Copy ${target_product}-target_files*.zip successful ..."
    else
        log error "The target files has not found ..."
    fi

    ## 3; 广深OTA, 主要用在威仕特项目,其他项目是不会生成该目标包
    if [[ -f "${OUT}/target_files-package.zip" ]];then
        cp -vf ${OUT}/target_files-package.zip ${OTA_PATH}
    fi

    ## 卡刷包名称定制
    if [[ -f "`ls ${OTA_PATH}/sdupdate.zip`" ]];then
        if [[ "`get_project_real_name`" == "k88c_jm01_cm01" ]];then
            personal_tailor_for_sdupdate=jmupdate
        elif [[ "`is_car_project`" == "true" ]];then
            sdupdate_for_car=`echo ${sdupdate_for_car} | sed 's/[\/_.-]//g'`
            personal_tailor_for_sdupdate= SdSystemUpdate_${sdupdate_name_for_car}
        else
            personal_tailor_for_sdupdate=${rename_sdupdate}
        fi

        mv ${OTA_PATH}/sdupdate.zip ${OTA_PATH}/${personal_tailor_for_sdupdate}.zip
    else
        log error "The sdupdate.zip file has not found ..."
    fi
}

## 备份MODEN FILE
function backup_moden_file() {

    ## 不同版本AP文件路径有不同,名称也有变化. 需要特别注意!

    # ./target/product/k80_bsp/obj/CGEN/APDB_MT6580_S01_alps-trunk-o1.bsp_W17.51
    # ./target/product/magc6580_we_l/obj/CGEN/APDB_MT6580_S01_L1.MP6_W15.27
    # ./target/product/along8321_emmc_706m/obj/CGEN/APDB_MT6580_S01_L1.MP6_W15.46
    if [[ -n `ls ${OUT}/obj/CGEN/APDB_*` ]]; then
        cp -vf ${OUT}/obj/CGEN/APDB_* ${DEST_PATH}/database/ap
    else
        log error "The AP files no found ... in ${OUT} ..."
    fi

    ## 不同版本BP文件路径有不同,名称也有变化. 需要特别注意!

    # mt8321
    # ./target/product/along8321_emmc_706m/system/etc/mddb/BPLGUInfoCustomAppSrcP_MT6580_S00_MOLY_WR8_W1449_MD_WG_MP_V6_P2_1_wg_n

    # mt6580
    # out/target/product/magc6580_we_l/system/etc/mddb/BPLGUInfoCustomAppSrcP_MT6580_S00_MOLY_WR8_W1449_MD_WG_MP_V6_1_2g_n
    # out/target/product/magc6580_we_l/system/etc/mddb/BPLGUInfoCustomAppSrcP_MT6580_S00_MOLY_WR8_W1449_MD_WG_MP_V6_1_wg_n
    if [[ -n `ls ${OUT}/*/etc/mddb/BPLGUInfoCustomAppSrcP_*` ]]; then
        cp -vf ${OUT}/*/etc/mddb/BPLGUInfoCustomAppSrcP_* ${DEST_PATH}/database/moden
    else

        # 当文件不存在的时候,部分项目本身就没有改文件,为了使编译通过,暂时忽略此错误.
        case `get_cpu_type` in

            mt6737m|mt6762)
                log warn  "The BP files has not found in ${OUT} ..."
            ;;

            *)
                log error "The BP files has not found in ${OUT} ..."
            ;;
        esac
    fi
}

##备份rom.json文件
function backup_rom_json()
{
    rsync -av ${rom_path}/ ${git_username}@${f1_server}:${rom_p}/share/rom

    # 清理动作
    if [[ -d ${rom_path} ]]; then
        rm -rf ${rom_path}/*
    fi

    echo
    show_vip "--> sync rom json file ..."
}

## 备份额外的事务
function hanlde_copy_extra_transaction()
{
    local readmefs=${tmpfs}/readme.txt
    local select_target_file=

    ## 1; 备份vmlinux, 用于调试
    if [[ -f `ls ${OUT}/obj/KERNEL*/vmlinux` ]];then
        cp -vf ${OUT}/obj/KERNEL*/vmlinux ${BACKUP_PATH}
    fi

    ## 2; 备份jenkins.ini
    if [[ -f ${tmpfs}/jenkins.ini ]]; then
        cp -vf ${tmpfs}/jenkins.ini ${BACKUP_PATH}
    else
        log warn "The jenkins.ini file has not found ..."
    fi

    ## 3; 备份留言板
    if [[ -f ${WORKSPACE}/yunovo_versiondescription ]];then
        cp -vf ${WORKSPACE}/yunovo_versiondescription ${BASE_PATH}/release_note.txt

        if [[ -f ${BASE_PATH}/release_note.txt ]]; then
            sed -i "1i 编译者:${build_builder}" ${BASE_PATH}/release_note.txt
        fi
    fi

    # 4; 检查版本的md5值, 只有车萝卜项目增加
    if [[ "`is_carrobot_project`" == "true" ]];then
        check_sum_ini

        if [[ -f "${OUT}/Checksum.ini" ]];then
            cp -vf "${OUT}/Checksum.ini" ${DEST_PATH}
        else
            log error "The Checksum.ini config file has not found ..."
        fi
    fi

    # 5; 备份Zen差分包和假包
    if [[ -d ${tmpfs}/ota ]]; then
        for z in `ls ${tmpfs}/ota`
        do
            if [[ ${z} == "fake_package.zip" ]]; then
                cp -vf ${tmpfs}/ota/${z} ${OTA_FAKE}/
            else
                cp -vf ${tmpfs}/ota/${z} ${OTA_INC}/
            fi
        done

        # 清理动作
        rm -rf ${tmpfs}/ota/*
    fi

    # 6; 拿到上个版本的基准包
    if [[ -n "`echo ${yunovo_pre_version} | sed -n '/^[S|V]/p'`" ]]; then
        if [[ -d ${tmpfs}/pre_rom ]]; then
            select_target_file=`find ${tmpfs}/pre_rom -name ${custom_version}_*.zip | grep -v inc`
        fi

        # 备份上个版本的基准包
        if [[ -f ${select_target_file} ]]; then
            cp -vf ${select_target_file} ${OTA_INC}/

            # 清理动作
            rm -rf ${select_target_file}
        fi

        # 备份假基准包
        if [[ -f ${tmpfs}/target_files-fake_package.zip ]]; then
            cp -vf ${tmpfs}/target_files-fake_package.zip ${OTA_FAKE}/

            # 清理动作
            rm -rf ${tmpfs}/target_files-fake_package.zip
        fi
    fi

    # 7; 备份说明文档,暂时未使用上, zen使用的时留言板
    if [[ -f ${readmefs} ]];then
        cp -vf ${readmefs} ${BASE_PATH}

        ## 拷贝完成后，删除
        rm -r ${readmefs}
    fi
}

# 打包 otatools文件夹
function zip_otatools() {

    cd ${otatools_p} > /dev/null

    zip -rq otatools.zip ./*

    if [[ -f otatools.zip ]]; then
        cp -vf otatools.zip ${OTA_PATH}
        rm -rf *
    else
        log error "The otatools.zip file has not found ..."
    fi

    cd - > /dev/null
}

#################################################################################################
# 拷贝OTA工具
#
# 据android版本的升级，每个版本需要解决OTA需要的工具也存在差异．需要做不同的适配，这里的代码可能
# 改动频繁，当然时在大版本升级的时候才会有改动，为做好兼容工作提供一下思路：
# 1. 系统版本,可以使用 get_android_version 拿到不同的版本, 单独拿到不同版本提供接口,如下:
#       is_60_android is_81_android is_90_android
# 2. 据平台差异 is_sc_project
# 3. 据特殊文件
#
# 由于时间有限,上述方案还未执行,待更新中...
function copy_ota_tools()
{
    # OTA工具包路径, 目的路径
    local otatools_p=${tmpfs}/otatools
    local host_tools_p=${otatools_p}/${HOST_OUT}

    local ota_scatter=${tmpfs}/otatools/`get_build_var PRODUCT_OUT`

    local release_tools_p=${otatools_p}/build/tools/releasetools
    local security_file=${otatools_p}/build/target/product/security

    local mt_ota_py_p=`test -f "${ota_extra_py}" && test -n "${ota_extra_py}" && dirname "${ota_extra_py}"`

    # ################################################# 创建文件夹
    init_system_path
    enhance_create_dir

    # ################################################# 备份文件

    # 1. out/host/linux-x86/bin
    init_copy_bin
    enhance_copy_file ${HOST_OUT}/bin ${otatools_p}/${HOST_OUT}/bin
    if [[ $? -eq 0 ]]; then
        show_vip "--> The file was copied successfully under the \${HOST_OUT}/bin ... "
    fi

    # MediaTek and Sprd Platform
    # 2. lib lib64库文件, 据平台和android版本不同使用有差异
    #   android版本: get_android_version
    #   平台项目   : is_sc_project is_mediatek_project

    show_vip "---- `get_android_version`"
    case `get_android_version` in

        5.1) # 5.1只有MediaTek平台,并且只有32位库文件
            if [[ -n "`ls ${HOST_OUT}/lib/libext2*.so`" ]]; then
                cp -vf ${HOST_OUT}/lib/libext2*.so ${host_tools_p}/lib
            else
                log warn "The ${HOST_OUT}/lib/libext2*.so files no found ..."
            fi
            ;;

        6.0) # 6.0 Sprd lib64, MediaTek lib

            # Sprd Platfrom
            if [[ "`is_sc_project`" == "true" ]]; then
                cp -vf ${HOST_OUT}/lib64/libext2*.so ${host_tools_p}/lib64
                cp -vf ${HOST_OUT}/lib64/libcutils.so ${host_tools_p}/lib64
                cp -vf ${HOST_OUT}/lib64/libc++.so ${host_tools_p}/lib64
                cp -vf ${HOST_OUT}/lib64/liblog.so ${host_tools_p}/lib64
                cp -vf ${HOST_OUT}/lib64/libselinux.so ${host_tools_p}/lib64
            else
                # MediaTek Android6.0版本没有支持64位系统,所以直接备份32位库,后续有待兼容
                if [[ -n "`ls ${HOST_OUT}/lib/libext2*.so`" ]]; then
                    cp -vf ${HOST_OUT}/lib/libext2*.so ${host_tools_p}/lib
                else
                    log warn "The ${HOST_OUT}/lib/libext2*.so files no found ..."
                fi
            fi
            ;;

        8.1) # 8.1 MediaTek lib64

            if [[ "`is_lib64_platfrom`" == "true" ]]; then

                init_copy_libxx
                enhance_copy_file ${HOST_OUT}/lib64 ${otatools_p}/${HOST_OUT}/lib64
                if [[ $? -eq 0 ]]; then
                    show_vip "--> The file was copied successfully under the \${HOST_OUT}/lib64 ... "
                fi
            else
                log warn "The platfrom no support lib32 ..."
            fi
            ;;
        *)
            log warn "The android version no found ..."
            ;;
    esac

    if [[ "`is_sc_project`" == "true" ]]; then

        # 备份Sprd pac script
        init_pac_script
        enhance_copy_file make_package ${otatools_p}/make_package
        if [[ $? -eq 0 ]]; then
            show_vip "--> The file was copied successfully under the make_package folder... "
        fi
    else ## MediaTek platform

        # 1. $(PRODUCT_OUT)/ota_scatter.txt
        if [[ -f ${OUT}/ota_scatter.txt ]]; then
            cp -vf ${OUT}/ota_scatter.txt ${host_tools_p}
        fi

        # 2. ota_scatter.pl
        if [[ -f device/mediatek/build/build/tools/ptgen/ota_scatter.pl ]]; then
            cp -vf device/mediatek/build/build/tools/ptgen/ota_scatter.pl ${release_tools_p}
        fi

        # 3. 备份 mt ota python
        if [[ -f ${mt_ota_py_p}/mt_ota_from_target_files.py ]]; then

            if [[ ! -d ${otatools_p}/${mt_ota_py_p} ]]; then
                mkdir -p ${otatools_p}/${mt_ota_py_p}
            fi

            cp -vf ${mt_ota_py_p}/mt_ota_from_target_files.py ${otatools_p}/${mt_ota_py_p}
        else
            case `get_cpu_type` in

                mt6580|mt8321)
                    log warn "The mt_ota_from_target_files.py no found ..."
                    ;;

                mt6762)
                    log warn "The mt_ota_from_target_files.py no found ..."
                ;;

                *)
                    if [[ "`is_sc_project`" == "true" ]]; then
                        log warn  "The mt_ota_from_target_files.py no found ..."
                    else
                        log error "The mt_ota_from_target_files.py no found ..."
                    fi
                ;;
            esac
        fi
    fi

    # ################################################# Sprd MediaTek公共部分

    # 1. out/host/linux-x86/framework
    init_copy_framework
    enhance_copy_file ${HOST_OUT}/framework ${host_tools_p}/framework
    if [[ $? -eq 0 ]]; then
        show_vip "--> The file was copied successfully under the \${HOST_OUT}/framework folder... "
    fi

    # 2. 公版签名文件
    if [[ -d build/target/product/security ]]; then
        cp -rvf build/target/product/security/* ${security_file}
    else
        log error "The build/target/product/security dir no found ..."
    fi

    # 3. python script
    if [[ -d build/tools/releasetools ]]; then
        cp -rvf build/tools/releasetools/* ${release_tools_p}
    else
        log error "The build/tools/releasetools dir no found ..."
    fi

    # ################################################# 打包otatools
    if [[ -d ${otatools_p} ]]; then
        zip_otatools
    else
        log error "The ${otatools_p} dir has not found ..."
    fi

    echo
    show_vip "--> copy otatools finish ... in `hostname` server."
}

## 容错处理
function __return__()
{
    local type_err=${1:-}

    send_email_when_build_failed

    case ${type_err} in

        1|2|3|4|5)
            return 1
        ;;

        *)
            if [[ -z ${type_err} ]]; then
                return 1
            fi
        ;;
    esac
}