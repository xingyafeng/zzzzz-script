#!/bin/bash

## if error then exit
set -e

### YUNOVO_S: add by yunovo for jenkins
export LANGUAGE=en_US
export LC_ALL=en_US.UTF-8

################################## args

### 1. build_device
build_device=$1

### 2. build project name  e.g. : K86_H520
build_prj_name=$2
project_name=""
custom_version=""
yunovo_prj_name=""

### 3. build version e.g. system version, S1.00 S1.00.00 S1.00.eng
build_version=""
first_version=
second_version=

### 4. build type e.g. : eng|user|userdebug
build_type=""

### 5. xxx

### 6. build update-api e.g. cmd make update-api
build_update_api=""

### 7. build update code e.g. is update source code
build_update_code=""

### 8. build clean e.g. : make clean bofore make
build_clean=""

### 9. build make OTA e.g. : is make OTA or not
build_make_ota=""

### 11. build mode e.g : user which voice txz or unisound
build_mode=""
voice_mode=""
yunovo_version_no=""

################################# common variate
shellfs=$0
## make ota
is_test_version=

################################# yunos  variate

## 6735
YUNOS_PROJECT_NAME=""
## eng user userdebug
TARGET_BUILD_VARIANT=
## adb acb
export TERMINAL_MODE=adb
## remake new
export MAKE_TYPE=new

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

############################################# common function

## 处理编译参数
function handle_compile_para()
{
    voice_mode="VR_MODE=$build_mode"
    yunovo_version_no="YUNOVO_VERSION_NO=$second_version"
    yunovo_prj_name="YUNOVO_PRJ_NAME=$build_prj_name"

    if [[ -n "$build_mode" ]];then
        # 1. 语音类型
        compile_para[${#compile_para[@]}]=${voice_mode}
    fi

    if [[ -n "$second_version" ]];then
        # 2. 版本号
        compile_para[${#compile_para[@]}]=${yunovo_version_no}
    fi

    if [[ -n "$build_prj_name" ]];then
        # 3. 项目名称
        compile_para[${#compile_para[@]}]=${yunovo_prj_name}
    fi

    export ${voice_mode}
    export ${yunovo_version_no}
    export ${yunovo_prj_name}
}

function handler_print()
{
    show_vip "--> make android start ..."

    echo "JOBS = $JOBS"
    echo '---------------------------------------------yunos'
    echo "YUNOS_PROJECT_NAME   = $YUNOS_PROJECT_NAME"
    echo "TARGET_BUILD_VARIANT = $TARGET_BUILD_VARIANT"
    echo "TERMINAL_MODE        = $TERMINAL_MODE"
    echo "MAKE_TYPE            = $MAKE_TYPE"
    echo '---------------------------------------------yunovo'
    echo "build_prj_name       = $build_prj_name"
    echo "project_name         = $project_name"
    echo "custom_version       = $custom_version"
    echo '---------------------------------------------'
    echo "build_version        = $build_version"
    echo "first_version        = $first_version"
    echo "second_version       = $second_version"
    echo '---------------------------------------------'
    echo "build_device         = $build_device"
    echo "build_type           = $build_type"
    echo "build_update_api     = $build_update_api"
    echo "build_update_code    = $build_update_code"
    echo "build_clean          = $build_clean"
    echo "build_make_ota       = $build_make_ota"
    echo "build_mode           = $build_mode"
    echo '---------------------------------------------'
    echo "is_test_version      = $is_test_version"
    echo "yunovo_prj_name      = $yunovo_prj_name"
    echo "voice_mode           = $voice_mode"
    echo "yunovo_version_no    = $yunovo_version_no"
    echo '---------------------------------------------'
    echo "compile_para = ${compile_para[@]}"
    echo '---------------------------------------------'
    echo
}

## 处理jenkins传过来的变量, 并检查其有效性.
function handle_vairable()
{
    ## 1. build device
    build_device=`remove_space_for_vairable "$build_device"`
    if [[ "`is_build_device`" == "false"  ]];then
        __err "build_device error. please check it ."
        return 1
    fi

    case ${build_device} in

        aeon6735_65c_s_l1)
            YUNOS_PROJECT_NAME=6735
            ;;

        magc6580_we_l|aeon6737t_66_m0|aeon6737m_65_m0)
            YUNOS_PROJECT_NAME=${build_device}
            ;;
        *)
            build_device=aeon6735_65c_s_l1
            YUNOS_PROJECT_NAME=6735
            ;;
    esac

    ## 2. build project name
    build_prj_name=`remove_space_for_vairable "$build_prj_name"`
    project_name=${build_prj_name%%_*}
    custom_version=${build_prj_name##*_}

    if [[ -z "$project_name" ||  -z "$custom_version" ]];then
        __err "project_name or custom_version is NULL. please check it ."
        return 1
    fi

    ## 3. build version
    if [[ "$yunovo_version" ]];then
        yunovo_version=`remove_space_for_vairable "$yunovo_version"`

        if [[ -n "`echo ${yunovo_version} | sed -n '/^S/p'`" ]];then
            build_version=${yunovo_version}

            first_version=${build_version%%.*}
            second_version=${build_version#*.}

            if [[ -z "$first_version" || -z "$second_version" ]];then
                __err "first_version or second_version is NULL. please check it ."
                return 1
            fi

            if [[ -n "`echo ${second_version} | sed -n '/\./p'`"  ]];then
                is_test_version=false
            else
                is_test_version=true
            fi
        else
            __err "build_version error, please check it ."
            return 1
        fi
    else
        __err "yunovo_version is null, please check it ."
        return 1
    fi

    ## 4. build type
    if [[ -n "$yunovo_type" ]];then
        build_type=`remove_space_for_vairable "$yunovo_type"`

        if [[ "`is_build_type`" == "false" ]];then
            ## 若jenkins填写不规范，默认为user
            build_type=user
        fi
    else
        ## 若jenkins不填写，默认为user
        build_type=user
    fi

    TARGET_BUILD_VARIANT=${build_type}

    ## 5. xxx

    ## 6. build update-api
    if [[ -n "$yunovo_update_api" ]];then
        build_update_api=${yunovo_update_api}
    else
        build_update_api=false
        yunovo_update_api=false
    fi

    ## 7. build update code
    if [[ "$yunovo_update_code" ]];then
        build_update_code=${yunovo_update_code}
    else
        build_update_code=true
        yunovo_update_code=true
    fi

    ## 8. build clean
    if [[ -n "$yunovo_clean" ]];then
        build_clean=${yunovo_clean}
    else
        build_clean=false
        yunovo_clean=false
    fi

    ## 9. build make ota
    if [[ -n "$yunovo_ota" ]];then
        build_make_ota=${yunovo_ota}
    else
        if [[ "`is_root_project`" == "true" ]];then
            build_make_ota=false
            yunovo_ota=false
        else
            build_make_ota=${is_test_version}
        fi
    fi

    ## 11. VR_MODE
    if [[ -n "$yunovo_vr_mode" ]];then
        yunovo_vr_mode=`remove_space_for_vairable "$yunovo_vr_mode"`
        build_mode=${yunovo_vr_mode}
    else
        __echo " yunovo_vr_mode is null, please check it !"
    fi

    #---------------------------------------------------------------------

    ##
}

function handler_download()
{
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        ### 初始化环境变量
        if [[ "`is_check_lunch`" == "no lunch" ]];then
            source_init
        else
            print_env
        fi
    fi

    if [[ "$build_update_code" == "true" ]];then

        recover_standard_android_project

        ##下载并更新源码
        down_load_yunos_source_code

    else
        __wrn "This time you don't exec update yunos source code ."
    fi
}

function init_mt6737t()
{
    platform=""
    ###project list begin
    # auto detect project name
    echo "choose $YUNOS_PROJECT_NAME"
    config_unsign
    config_cta_support

    if [[ -f ${BASE}/aliyunos/yunospick/overlay/overlay.sh ]];then
        source ${BASE}/aliyunos/yunospick/overlay/overlay.sh ${YUNOS_PROJECT_NAME} $(get_build_var TARGET_ARCH)
    fi

    #only build modem bins for project in overlay
    for pj in `test -d overlay && ls -l overlay | grep d | awk '{print $NF}' 2> /dev/null`
    do
        if [[ "$pj" = "$YUNOS_PROJECT_NAME" ]];then
            echo "build modem bins for project $YUNOS_PROJECT_NAME"
            mnm
            break
        fi
    done
    #

    #re-export the $OPTIONS, in case some value is changed
    #ignore -o in first arg , otherwise the first arg will export fail
    _config_args=`echo ${OPTIONS} | sed -e 's/^\-o\=//'`
    for _arg in `echo ${_config_args//,/ }`
    do
        p1=`echo "$_arg" | awk -F "=" '{print $1}'`
        p2=`echo "$_arg" | awk -F "=" '{print $2}'`
        if [[ -n "$p2" ]]; then
            export ${p1}=${p2}
        fi
    done

    if [[ "$TARGET_BUILD_VARIANT" == "user" ]];then
        echo "change the values"
        export ART_BUILD_TARGET_DEBUG=false
        export ART_BUILD_HOST_DEBUG=false
        export USE_DEX2OAT_DEBUG=false
    fi
    echo ART_BUILD_TARGET_DEBUG=${ART_BUILD_TARGET_DEBUG}
    echo ART_BUILD_HOST_DEBUG=${ART_BUILD_HOST_DEBUG}
    echo USE_DEX2OAT_DEBUG=${USE_DEX2OAT_DEBUG}
}

handle_vairable
handle_compile_para
get_manifest_branch_name
handler_print
handler_download

### YUNOVO_E: add by yunovo for jenkins

# ///////////////////////////////////////////////////////分界线 #
CODEBASE_VERSION="5.1.0"
TARGET_BUILD_VARIANT_LIST=("eng" "user" "userdebug")
TERMINAL_MODE_LIST=("adb" "acb")
###optimize for part build begin
MAKE_TYPE_LIST=("remake" "new" "update-api" "bootimage" "recoveryimage" "systemimage" "ptgen" "pl" "lk")
PART_PARAMETER_BUILD_LIST=("mmm" )
###optimize for part build end
WEB_RUNTIME_ENABLE_LIST=("true" "false" )
MI3_TYPE="3W"

#function declaring
declare -a _inlist
function select_choice()
{
    _target_arg=$1
    _arg_list=(${_inlist[@]})
    _outc=""
    select _c in ${_arg_list[@]}
    do
        if [[ -n "$_c" ]]; then
            _outc=${_c}
            break
        else
            for _i in ${_arg_list[@]}
            do
                _t=`echo ${_i} | grep -E "^$REPLY"`
                if [[ -n "$_t" ]]; then
                    _outc=${_i}
                    break
                fi
            done
            if [[ -n "$_outc" ]]; then
                break
            fi
        fi
    done
    if [[ -n "$_outc" ]]; then
        eval "${_target_arg}=${_outc}"
	export ${_target_arg}=${_outc}
    fi
}

function check_choice()
{
    _target_arg=$1
    _arg_list=(${_inlist[@]})
    _input=$2
    for _i in ${_arg_list[@]}
    do
        if [[ "$_i" = "$_input" ]]; then
            eval "${_target_arg}=${_i}"
	    	export ${_target_arg}=${_i}
            break
        fi
    done
}

###optimize for part build begin
function get_next_parameter()
{
    _target_arg=$1
    _arg_list=(${_inlist[@]})
    _input=$2
    flag=false;
    for _i in ${_arg_list[@]}
    do
        if [[ "$flag" = true ]]; then
            export ${_target_arg}=${_i}
            flag=false;
            break
        fi

        if [[ "$_i" = "$_input" ]]; then
            flag=true;
        fi
    done
}
###optimize for part build end

function replace_config()
{
    eval "_value=\$$1"
    if [[ -n "$_value" ]]; then
        sed -i "s/^$1=[^=]*/$1=$_value/g" ${OUT_CONFIG_FILE}
    fi
}

function replace_auto_config()
{
    eval "_value=\$$1"
    if [[ -n "$_value" ]]; then
        sed -i "s/^#$1=[^=]*/$1=$_value/g" ${OUT_CONFIG_FILE}
    fi
}

function config_cta_support()
{
    if [[ ${YUNOS_SUPPORT_CTA} = "yes" ]];then
        sed -i 's/MTK_CTA_SUPPORT = no/MTK_CTA_SUPPORT = yes/g' device/alibaba/${YUNOS_PROJECT_NAME}/ProjectConfig.mk
    else
        sed -i 's/MTK_CTA_SUPPORT = yes/MTK_CTA_SUPPORT = no/g' device/alibaba/${YUNOS_PROJECT_NAME}/ProjectConfig.mk
    fi
}

function config_unsign()
{
	#For MTK platform only
	#So far only verified on 6735m and yk628 project

#	sed -i '/MTK_SEC_BOOT[ =]*ATTR/c\MTK_SEC_BOOT = ATTR_SBOOT_ONLY_ENABLE_ON_SCHIP' device/alibaba/$YUNOS_PROJECT_NAME/ProjectConfig.mk
#	sed -i '/MTK_SEC_USBDL[ =]*ATTR/c\MTK_SEC_USBDL = ATTR_SUSBDL_ONLY_ENABLE_ON_SCHIP' device/alibaba/$YUNOS_PROJECT_NAME/ProjectConfig.mk
#	sed -i '/MTK_SEC_MODEM_AUTH[ =]*[yn]/c\MTK_SEC_MODEM_AUTH = no' device/alibaba/$YUNOS_PROJECT_NAME/ProjectConfig.mk
#	sed -i '/MTK_SEC_MODEM_ENCODE[ =]*[yn]/c\MTK_SEC_MODEM_ENCODE = no' device/alibaba/$YUNOS_PROJECT_NAME/ProjectConfig.mk
	MTK_BASE_PROJECT=`awk -F '[ =]' '$1 == "MTK_BASE_PROJECT"' device/alibaba/${YUNOS_PROJECT_NAME}/full_${YUNOS_PROJECT_NAME}.mk | awk -F '=' '{print $2}' | awk '{print $1}'`
	PRELOADER_TARGET_PRODUCT=`awk -F '[ =]' '$1 == "PRELOADER_TARGET_PRODUCT"' device/alibaba/${YUNOS_PROJECT_NAME}/full_${YUNOS_PROJECT_NAME}.mk | awk -F '=' '{print $2}' | awk '{print $1}'`
	LK_PROJECT=`awk -F '[ =]' '$1 == "LK_PROJECT"' device/alibaba/${YUNOS_PROJECT_NAME}/full_${YUNOS_PROJECT_NAME}.mk | awk -F '=' '{print $2}' | awk '{print $1}'`
	sed -i '/MTK_SEC_BOOT[ =]*ATTR/c\MTK_SEC_BOOT=ATTR_SBOOT_ONLY_ENABLE_ON_SCHIP' vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/${PRELOADER_TARGET_PRODUCT}/${PRELOADER_TARGET_PRODUCT}.mk
	sed -i '/MTK_SEC_USBDL[ =]*ATTR/c\MTK_SEC_USBDL=ATTR_SUSBDL_ONLY_ENABLE_ON_SCHIP' vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/${PRELOADER_TARGET_PRODUCT}/${PRELOADER_TARGET_PRODUCT}.mk
	sed -i '/MTK_SEC_MODEM_AUTH[ =]*[yn]/c\MTK_SEC_MODEM_AUTH=no' vendor/mediatek/proprietary/bootable/bootloader/preloader/custom/${PRELOADER_TARGET_PRODUCT}/${PRELOADER_TARGET_PRODUCT}.mk
	export SECURE_BOOT_ENABLE=off
}

moreArgs=
#process begin
_input_args=($*)
if false;then
#find project name first
for _arg in ${_input_args[@]}
do
    p1=`echo "$_arg" | awk -F "=" '{print $1}'`
    p2=`echo "$_arg" | awk -F "=" '{print $2}'`

    if [[ -z "$p2" ]]; then
        _inlist=(${YUNOS_PROJECT_NAME_LIST[@]})
        check_choice YUNOS_PROJECT_NAME ${p1}
        case ${p1} in
            eng|user|userdebug|adb|acb|remake|new|true|false)
            # auto detect project name
            ;;
            webrt_check_api)
                echo "Start to check webrt api dependency"
                ./TGL/build/depends_api/auto_check_api.sh
                echo "End of api checking"
            ;;
            *)
                ###project list begin
                # auto detect project name
                exsit_flag_second=false;
                for pj_exsit in ${YUNOS_PROJECT_NAME_LIST[@]}
                do
                    if [[  "$pj_exsit" = "$p1" ]];then
                       exsit_flag_second=true
                       break
                    fi
                done
                if [[  "$exsit_flag_second" = "false" ]];then
                    moreArgs="$moreArgs $p1"
                fi
                ###project list end
            ;;
        esac
    elif [[ "$p1" = "RELEASE_MODE" ]]; then
        #RELEASE_MODE=[$project,]$release_mode
        release_mode=`echo "$p2" | awk -F "," '{print $2}'`
        if [[ -z "$release_mode" ]]; then
            release_mode=`echo "$p2" | awk -F "," '{print $1}'`
        else
            YUNOS_PROJECT_NAME=`echo "$p2" | awk -F "," '{print $1}'`
        fi
    elif [[ "$p1" = "CODEBASE_VERSION" ]]; then
        CODEBASE_VERSION=${p2}
    elif [[ "$p1" = "MI3_TYPE" ]]; then
        MI3_TYPE=${p2}
    fi
done
fi
#if can not find project name, input it
if [[ "$YUNOS_PROJECT_NAME" == "" ]];then
    echo "target project name:"
    _inlist=(${YUNOS_PROJECT_NAME_LIST[@]})
    select_choice YUNOS_PROJECT_NAME
fi
#new phone can copy driver
#add for overlay driver code by chusheng.xcs
if [[ -e ${BASE}/overlay/overlay.sh ]];then
source ${BASE}/overlay/overlay.sh ${YUNOS_PROJECT_NAME}
fi
project=${YUNOS_PROJECT_NAME}
echo "get project name: $YUNOS_PROJECT_NAME"
if false;then
if [[ -n "$(echo $* | grep ' new')" ]];then
     make clean
fi
fi
#handle config file
DEFAULT_CONFIG_FILE=${BASE}/device/alibaba/common/device.mk
CUSTOM_CONFIG_FILE=${BASE}/device/alibaba/${YUNOS_PROJECT_NAME}/device.mk
OUT_CONFIG_FILE=${BASE}/out/YunOSConfig.mk
OUT_CFLAGS_FILE=${BASE}/out/YunOSCFlags.mk

mkdir -p ${BASE}/out

echo "reading config file: $DEFAULT_CONFIG_FILE"
if [[ -f ${DEFAULT_CONFIG_FILE} ]];then
cat ${DEFAULT_CONFIG_FILE} | grep " ?= " | grep -v "#" > ${OUT_CONFIG_FILE}
sed -i "s/ ?= /=/" ${OUT_CONFIG_FILE}
fi

if [[ -f ${CUSTOM_CONFIG_FILE} ]];then
## YUNOVO_S: modify by yafeng
cat ${CUSTOM_CONFIG_FILE} | grep -E " := (yes|no)" | grep -v "#" > ${OUT_CFLAGS_FILE}
## YUNOVO_E: modify by yafeng
sed -i "s/ := /=/" ${OUT_CFLAGS_FILE}
fi

echo "replacing with custom config file: $CUSTOM_CONFIG_FILE"
while read LINE
do
    p1=`echo "$LINE" | awk -F "=" '{print $1}' | sed -e 's/^\s+|\s+$//g'`
    p2=`echo "$LINE" | awk -F "=" '{print $2}' | sed -e 's/^\s+|\s+$//g'`
    #skip empty or comment line
    if [[ -z "$p1$p2" ]]; then
        continue
    fi
    if [[ -n "`echo ${p1} | grep -E '^\#'`" ]]; then
        continue
    fi

    #custom config overwrite default config
    sed -i "s/^$p1=[^=]*/$p1=$p2/g" ${OUT_CONFIG_FILE} 2> /dev/null
done < "$OUT_CFLAGS_FILE"

_input_args=($*)
if false;then
#process other input args
for _arg in ${_input_args[@]}
do
    p1=`echo "$_arg" | awk -F "=" '{print $1}'`
    p2=`echo "$_arg" | awk -F "=" '{print $2}'`

    if [[ -n "$p2" ]]; then
        eval "${p1}=${p2}"
        export ${p1}=${p2}
        #input args overwrite config items
        replace_config ${p1}
    else
        _inlist=(${TARGET_BUILD_VARIANT_LIST[@]})
        check_choice TARGET_BUILD_VARIANT ${p1}
        _inlist=(${TERMINAL_MODE_LIST[@]})
        check_choice TERMINAL_MODE ${p1}
        _inlist=(${MAKE_TYPE_LIST[@]})
        check_choice MAKE_TYPE ${p1}
        _inlist=(${WEB_RUNTIME_ENABLE_LIST[@]})
        check_choice WEB_RUNTIME_ENABLE ${p1}
###optimize for part build begin
        _inlist=(${PART_PARAMETER_BUILD_LIST[@]})
        check_choice PART_PARAMETER_BUILD_TYPE ${p1}
        if [[ -n "$PART_PARAMETER_BUILD_TYPE" ]]; then
            _inlist=(${_input_args[@]})
            get_next_parameter PART_PARAMETER ${p1}
            MAKE_TYPE=""
        fi
###optimize for part build end
    fi
done
fi
#release mode, need add signature, and turn off features like apr and debug
case ${release_mode} in
    release)
        #TODO: add signature
        APR_MODE="off"
        AMT_MODE="off"
        VM_DEBUG="off"
        TARGET_BUILD_VARIANT="user"
        TERMINAL_MODE="acb"
        MAKE_TYPE="new"
        WEB_RUNTIME_ENABLE="true"
    ;;

    *)
    ;;
esac

if true;then
if [[ "$TARGET_BUILD_VARIANT" == "" ]];then
    echo "target build variant:"
    _inlist=(${TARGET_BUILD_VARIANT_LIST[@]})
    select_choice TARGET_BUILD_VARIANT
fi
if [[ "$TERMINAL_MODE" == "" ]];then
    echo "terminal mode:"
    _inlist=(${TERMINAL_MODE_LIST[@]})
    select_choice TERMINAL_MODE
fi

###optimize for part build begin
if [[ "$MAKE_TYPE" == "" ]] && [[ "$PART_PARAMETER_BUILD_TYPE" == "" ]];then
    echo "make type:"
    _inlist=(${MAKE_TYPE_LIST[@]} "${PART_PARAMETER_BUILD_LIST[@]}")
    select_choice MAKE_TYPE
    if [[ "$MAKE_TYPE" == "new" ]] || [[ "$MAKE_TYPE" == "remake" ]];then
        echo "MAKE_TYPE = $MAKE_TYPE"
    else
        moreArgs=${MAKE_TYPE};
    fi

    for _type in ${PART_PARAMETER_BUILD_LIST[@]}
    do
        if  [[ "$MAKE_TYPE" = ${_type} ]];then
            moreArgs=""
            PART_PARAMETER_BUILD_TYPE=${MAKE_TYPE}
            echo -n "Pls input module path: "
            read -a PART_PARAMETER
            if [[ ! -n "$PART_PARAMETER" ]]; then
                echo "error:module path is null"
                exit
            fi
        fi
    done
fi

if [[ "$MAKE_TYPE" == "new" ]] || [[ "$MAKE_TYPE" == "remake" ]] || [[ "$MAKE_TYPE" == "systemimage" ]];then
    NEED_UPDATE_API=true
fi
fi
###optimize for part build end

#variable reltionship process

replace_auto_config YUNOS_PROJECT_NAME
replace_config YUNOS_PROJECT_NAME
replace_config TARGET_BUILD_VARIANT
#make sure set terminal mode
replace_auto_config TERMINAL_MODE
replace_config TERMINAL_MODE
replace_config MAKE_TYPE
replace_config CODEBASE_VERSION
replace_config MI3_TYPE
replace_config APR_MODE
replace_config AMT_MODE
replace_config VM_DEBUG
replace_config WEB_RUNTIME_ENABLE

#process carrier custom macro

case ${YUNOS_CARRIER_CUSTOM} in
    CUCC)
        YUNOS_CARRIER_CODE="U"
    ;;
    CTCC)
        YUNOS_CARRIER_CODE="T"
    ;;
    CMCC)
        YUNOS_CARRIER_CODE="C"
        if [[  "$YUNOS_CARRIER_FAKE" == "" ]]; then
            YUNOS_CARRIER_FAKE=true
        fi
        if [[  "$YUNOS_CMCC_NEWREQ" == "" ]]; then
            YUNOS_CMCC_NEWREQ=true
            export YUNOS_CMCC_NEWREQ=${YUNOS_CMCC_NEWREQ}
        fi
    ;;
    *)
        YUNOS_CARRIER_CODE="NONE"
        YUNOS_CARRIER_FAKE=false
    ;;
esac
replace_config YUNOS_CARRIER_CODE
replace_config YUNOS_CARRIER_CUSTOM
replace_config YUNOS_CARRIER_FAKE
replace_config YUNOS_CMCC_NEWREQ

#process platform macro
YUNOS_PLATFORM_MTK=false
YUNOS_PLATFORM_QUALCOMM=false
YUNOS_PLATFORM_SPREADTRUM=false
case ${YUNOS_PLATFORM} in
    MTK)
        YUNOS_PLATFORM_MTK=true
    ;;
    QUALCOMM)
        YUNOS_PLATFORM_QUALCOMM=true
    ;;
    SPREADTRUM)
        YUNOS_PLATFORM_SPREADTRUM=true
    ;;
    *)
    ;;
esac
replace_auto_config YUNOS_PLATFORM_MTK
replace_auto_config YUNOS_PLATFORM_QUALCOMM
replace_auto_config YUNOS_PLATFORM_SPREADTRUM

echo "$OUT_CONFIG_FILE gen!"

export YUNOS_PROJECT=${YUNOS_PROJECT}
export TARGET_BUILD_VARIANT=${TARGET_BUILD_VARIANT}
export YUNOS_PROJECT_NAME=${YUNOS_PROJECT_NAME}
export YUNOS_CARRIER_CODE=${YUNOS_CARRIER_CODE}
OPTIONS="-o=YUNOS_PROJECT=$YUNOS_PROJECT"
OPTIONS="$OPTIONS,TARGET_BUILD_VARIANT=$TARGET_BUILD_VARIANT"
OPTIONS="$OPTIONS,YUNOS_PROJECT_NAME=$YUNOS_PROJECT_NAME"
OPTIONS="$OPTIONS,YUNOS_CARRIER_CODE=$YUNOS_CARRIER_CODE"
if [[ "$MAKEJOBS" != "" ]];then
    OPTIONS="$OPTIONS,MAKEJOBS=$MAKEJOBS"
fi

#auto gen cflag file and OPTIONS by the way
echo "#YUNOS_AUTO_GEN: YunOSCFlags.mk" > ${OUT_CFLAGS_FILE}
while read LINE
do
    p1=`echo "$LINE" | awk -F "=" '{print $1}' | sed -e 's/^\s+|\s+$//g'`
    p2=`echo "$LINE" | awk -F "=" '{print $2}' | sed -e 's/^\s+|\s+$//g'`
    #skip empty or comment line
    if [[ -z "$p1$p2" ]]; then
        continue
    fi
    if [[ -n "`echo ${p1} | grep -E '^\#'`" ]]; then
        continue
    fi
    case ${p2} in
        no|false|off)
        ;;
        yes|true|on)
            echo "COMMON_GLOBAL_CFLAGS += -D$p1" >> ${OUT_CFLAGS_FILE}
        ;;
        *)
            echo "COMMON_GLOBAL_CFLAGS += -D$p1=$p2" >> ${OUT_CFLAGS_FILE}
        ;;
    esac
    #gen OPTIONS by the way
    OPTIONS="$OPTIONS,$p1=$p2"
done < "$OUT_CONFIG_FILE"

echo "$OUT_CFLAGS_FILE gen!"

#vobose
echo "$0 $YUNOS_PROJECT_NAME $CODEBASE_VERSION $TARGET_BUILD_VARIANT $TERMINAL_MODE $MAKE_TYPE $MI3_TYPE"

echo "Flag[LEMUR_PROJECT]         for use lemur/dalvik vm:   [$LEMUR_PROJECT]"
echo "Flag[APR_MODE]              for open apr service:      [$APR_MODE]"
echo "Flag[VM_DEBUG]              for support vm debug mode: [$VM_DEBUG]"
echo "Flag[YUNOS_CARRIER_CUSTOM]  for carrier custom:        [$YUNOS_CARRIER_CUSTOM]"
echo "Flag[YUNOS_CARRIER_FAKE]    for carrier fake:          [$YUNOS_CARRIER_FAKE]"
echo "Flag[YUNOS_CMCC_NEWREQ]     for CMCC newreq:           [$YUNOS_CMCC_NEWREQ]"
echo "Flag[YUNOS_SUPPORT_CTA]     for cta feature:           [$YUNOS_SUPPORT_CTA]"
echo "Flag[YUNOS_SUPPORT_PICK]    for pick feature:          [$YUNOS_SUPPORT_PICK]"

echo "OPTIONS:"
echo "$OPTIONS"
main(){
    export DATE=`date +%Y-%m-%d-%H%M`
    local startT=`date +'%Y-%m-%d %H:%M:%S'`

    #get platform by project name
    echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
    echo "WEB_RUNTIME_ENABLE $WEB_RUNTIME_ENABLE"

    if [[ "`is_yunos_project`" == "true" ]];then

        version_p=~/.jenkins_version_yunos

        if [[ ! -d ${version_p} ]];then
            mkdir -p ${version_p}
        fi
    else
        __err "current directory is not android !"
        exit 1
    fi

    ## 阿里脚本处理
    source ./aliyunos/prebuilts/apps/prebuilt_mk.sh ${YUNOS_PROJECT_NAME} ${OPTIONS}
    echo

    init_mt6737t

    ## 编译阿里系统源码
    make_yunos_android

    if [[ "`is_yunos_project`" == "true" ]];then

        print_make_completed_time

        show_vip "--> make android end ..."
    else
        __err "current directory is not android !"
        return 1
    fi
}
main
