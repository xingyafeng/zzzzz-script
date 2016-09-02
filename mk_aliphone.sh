#!/bin/bash

#YUNOS_PROJECT add by BuildSystem

#variable initialize
#default value:see custom/default/config
YUNOS_PROJECT=true

BASE=`pwd`

echo "BASE=$BASE"

#lists
#
#i9500    SAMSUNG    S4
#i9508    SAMSUNG    S4(CMCC)
#hlte     SAMSUNG    NOTE3(CMCC)
#find7    OPPO       find7
#t6       HTC        One Max
#falcon   MOTO       Moto G
#bacon    OnePlus    bacon
#nexus4   LG         nexus4
#nexus5   LG         nexus5
#honami   Sony       Xperia Z1(C6902 China)
#nx403a   NUBIA      Z5S mini
#nx507j   NUBIA      Z7 mini
#klte     SAMSUNG    S5(SM-G900F:International WCDMA)
#kltezm   SAMSUNG    S5(SM-G9008V:CMCC TDD)
#cancro   xiaomi     mi3
#n7100    SAMSUNG    NOTE2

YUNOS_PROJECT_NAME_LIST=(
    "a800"
    "yk628"
    "6735m"
    "hyf9300"
    "6735m_64"
    "6735"
    "zopo9520"
    "nx"
    "nexus5"
    "nexus4"
    "i9300"
    "i9500"
    "i9508"
    "hlte"
    "find7"
    "t6"
    "falcon"
    "aries"
    "bacon"
    "honami"
    "nx403a"
    "nx507j"
    "klte"
    "kltezm"
    "cancro"
    "n7100"
    "aeon6735m_65c_s_l1"
    "aeon6735_65c_s_l1"
)
CODEBASE_VERSION="3.0"
TARGET_BUILD_VARIANT_LIST=("eng" "user" "userdebug")
TERMINAL_MODE_LIST=("adb" "acb")
MAKE_TYPE_LIST=("remake" "new" )
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
        if [ -n "$_c" ]; then
            _outc=$_c
            break
        else
            for _i in ${_arg_list[@]}
            do
                _t=`echo $_i | grep -E "^$REPLY"`
                if [ -n "$_t" ]; then
                    _outc=$_i
                    break
                fi
            done
            if [ -n "$_outc" ]; then
                break
            fi
        fi
    done
    if [ -n "$_outc" ]; then
        eval "$_target_arg=$_outc"
	export "$_target_arg=$_outc"
    fi
}

function check_choice()
{
    _target_arg=$1
    _arg_list=(${_inlist[@]})
    _input=$2
    for _i in ${_arg_list[@]}
    do
        if [ "$_i" = "$_input" ]; then
            eval "$_target_arg=$_i"
	    	export "$_target_arg=$_i"
            break
        fi
    done
}

function replace_config()
{
    eval "_value=\$$1"
    if [ -n "$_value" ]; then
        sed -i "s/^$1=[^=]*/$1=$_value/g" $OUT_CONFIG_FILE
    fi
}

function replace_auto_config()
{
    eval "_value=\$$1"
    if [ -n "$_value" ]; then
        sed -i "s/^#$1=[^=]*/$1=$_value/g" $OUT_CONFIG_FILE
    fi
}

function config_unsign()
{
	#For MTK platform only
	#So far only verified on 6735m and yk628 project
	sed -i '/MTK_SEC_BOOT[ =]*ATTR/c\MTK_SEC_BOOT = ATTR_SBOOT_ONLY_ENABLE_ON_SCHIP' device/alibaba/$YUNOS_PROJECT_NAME/ProjectConfig.mk
	sed -i '/MTK_SEC_USBDL[ =]*ATTR/c\MTK_SEC_USBDL = ATTR_SUSBDL_ONLY_ENABLE_ON_SCHIP' device/alibaba/$YUNOS_PROJECT_NAME/ProjectConfig.mk
	sed -i '/MTK_SEC_MODEM_AUTH[ =]*[yn]/c\MTK_SEC_MODEM_AUTH = no' device/alibaba/$YUNOS_PROJECT_NAME/ProjectConfig.mk
	sed -i '/MTK_SEC_MODEM_ENCODE[ =]*[yn]/c\MTK_SEC_MODEM_ENCODE = no' device/alibaba/$YUNOS_PROJECT_NAME/ProjectConfig.mk
	MTK_BASE_PROJECT=`awk -F '[ =]' '$1 == "MTK_BASE_PROJECT"' device/alibaba/$YUNOS_PROJECT_NAME/full_$YUNOS_PROJECT_NAME.mk | awk -F '=' '{print $2}' | awk '{print $1}'`
	PRELOADER_TARGET_PRODUCT=`awk -F '[ =]' '$1 == "PRELOADER_TARGET_PRODUCT"' device/alibaba/$YUNOS_PROJECT_NAME/full_$YUNOS_PROJECT_NAME.mk | awk -F '=' '{print $2}' | awk '{print $1}'`
	LK_PROJECT=`awk -F '[ =]' '$1 == "LK_PROJECT"' device/alibaba/$YUNOS_PROJECT_NAME/full_$YUNOS_PROJECT_NAME.mk | awk -F '=' '{print $2}' | awk '{print $1}'`
	sed -i '/MTK_SEC_BOOT[ =]*ATTR/c\MTK_SEC_BOOT=ATTR_SBOOT_ONLY_ENABLE_ON_SCHIP' bootable/bootloader/preloader/custom/$PRELOADER_TARGET_PRODUCT/${PRELOADER_TARGET_PRODUCT}.mk
	sed -i '/MTK_SEC_USBDL[ =]*ATTR/c\MTK_SEC_USBDL=ATTR_SUSBDL_ONLY_ENABLE_ON_SCHIP' bootable/bootloader/preloader/custom/$PRELOADER_TARGET_PRODUCT/${PRELOADER_TARGET_PRODUCT}.mk
	sed -i '/MTK_SEC_MODEM_AUTH[ =]*[yn]/c\MTK_SEC_MODEM_AUTH=no' bootable/bootloader/preloader/custom/$PRELOADER_TARGET_PRODUCT/${PRELOADER_TARGET_PRODUCT}.mk
}

moreArgs=
#process begin
_input_args=($*)
#find project name first
for _arg in ${_input_args[@]}
do
    p1=`echo "$_arg" | awk -F "=" '{print $1}'`
    p2=`echo "$_arg" | awk -F "=" '{print $2}'`

    if [ -z "$p2" ]; then
        _inlist=(${YUNOS_PROJECT_NAME_LIST[@]})
        check_choice YUNOS_PROJECT_NAME $p1
        case $p1 in
            a800|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            yk628|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;  
            6735m|aeon6735m_65c_s_l1|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            hyf9300|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
	    6735m_64|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;  
            6735|aeon6735_65c_s_l1|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            zopo9520|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            nx|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            nexus5|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            nexus4|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            i9300|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            i9500|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            i9508|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            hlte|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            find7|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            t6|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            falcon|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            aries|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            bacon|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            honami|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            nx403a|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            nx507j|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            klte|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            kltezm|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            cancro|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            n7100|eng|user|userdebug|adb|acb|remake|new|true|false)
            ;;
            webrt_check_api)
                echo "Start to check webrt api dependency"
                ./TGL/build/depends_api/auto_check_api.sh
                echo "End of api checking"
            ;;
            *)
                moreArgs="$moreArgs $p1"
            ;;
        esac
    elif [ "$p1" = "RELEASE_MODE" ]; then
        #RELEASE_MODE=[$project,]$release_mode
        release_mode=`echo "$p2" | awk -F "," '{print $2}'`
        if [ -z "$release_mode" ]; then
            release_mode=`echo "$p2" | awk -F "," '{print $1}'`
        else
            YUNOS_PROJECT_NAME=`echo "$p2" | awk -F "," '{print $1}'`
        fi
    elif [ "$p1" = "CODEBASE_VERSION" ]; then
        CODEBASE_VERSION=$p2
    elif [ "$p1" = "MI3_TYPE" ]; then
        MI3_TYPE=$p2
    fi
done
#if can not find project name, input it
if [ "$YUNOS_PROJECT_NAME" = "" ];then
    echo "target project name:"
    _inlist=(${YUNOS_PROJECT_NAME_LIST[@]})
    select_choice YUNOS_PROJECT_NAME
fi

project=$YUNOS_PROJECT_NAME
echo "get project name: $YUNOS_PROJECT_NAME"

if [ -n "$(echo $* | grep ' new')" ];then
     make clean
fi

#handle config file
DEFAULT_CONFIG_FILE=$BASE/device/alibaba/common/device.mk
CUSTOM_CONFIG_FILE=$BASE/device/alibaba/common/device.mk
OUT_CONFIG_FILE=$BASE/out/YunOSConfig.mk
OUT_CFLAGS_FILE=$BASE/out/YunOSCFlags.mk

mkdir -p $BASE/out

echo "reading config file: $DEFAULT_CONFIG_FILE"
cat $DEFAULT_CONFIG_FILE | grep " ?= " | grep -v "#" > $OUT_CONFIG_FILE
sed -i "s/ ?= /=/" $OUT_CONFIG_FILE
cat $CUSTOM_CONFIG_FILE | grep " := " | grep -v "#" > $OUT_CFLAGS_FILE
sed -i "s/ := /=/" $OUT_CFLAGS_FILE

echo "replacing with custom config file: $CUSTOM_CONFIG_FILE"
while read LINE 
do
    p1=`echo "$LINE" | awk -F "=" '{print $1}' | sed -e 's/^\s+|\s+$//g'`
    p2=`echo "$LINE" | awk -F "=" '{print $2}' | sed -e 's/^\s+|\s+$//g'`
    #skip empty or comment line
    if [ -z "$p1$p2" ]; then
        continue
    fi  
    if [ -n "`echo $p1 | grep -E '^\#'`" ]; then
        continue
    fi  
    #custom config overwrite default config
    sed -i "s/^$p1=[^=]*/$p1=$p2/g" $OUT_CONFIG_FILE
done < "$OUT_CFLAGS_FILE"

_input_args=($*)
#process other input args
for _arg in ${_input_args[@]}
do
    p1=`echo "$_arg" | awk -F "=" '{print $1}'`
    p2=`echo "$_arg" | awk -F "=" '{print $2}'`

    if [ -n "$p2" ]; then
        eval "$p1=$p2"
        export "$p1=$p2"
        #input args overwrite config items
        replace_config $p1
    else
        _inlist=(${TARGET_BUILD_VARIANT_LIST[@]})
        check_choice TARGET_BUILD_VARIANT $p1
        _inlist=(${TERMINAL_MODE_LIST[@]})
        check_choice TERMINAL_MODE $p1
        _inlist=(${MAKE_TYPE_LIST[@]})
        check_choice MAKE_TYPE $p1
        _inlist=(${WEB_RUNTIME_ENABLE_LIST[@]})
        check_choice WEB_RUNTIME_ENABLE $p1
    fi
done

#release mode, need add signature, and turn off features like apr and debug
case $release_mode in
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

if [ "$TARGET_BUILD_VARIANT" = "" ];then
    echo "target build variant:"
    _inlist=(${TARGET_BUILD_VARIANT_LIST[@]})
    select_choice TARGET_BUILD_VARIANT
fi
if [ "$TERMINAL_MODE" = "" ];then
    echo "terminal mode:"
    _inlist=(${TERMINAL_MODE_LIST[@]})
    select_choice TERMINAL_MODE
fi
if [ "$MAKE_TYPE" = "" ];then
    echo "make type:"
    _inlist=(${MAKE_TYPE_LIST[@]})
    select_choice MAKE_TYPE
fi

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

YUNOS_CARRIER_CUSTOMIZED=true
YUNOS_CARRIER_COMMON=true
YUNOS_CARRIER_CUCC=false
YUNOS_CARRIER_CTCC=false
YUNOS_CARRIER_CMCC=false
case $YUNOS_CARRIER_CUSTOM in
    CUCC)
        YUNOS_CARRIER_CODE="U"
        YUNOS_CARRIER_CUCC=true
    ;;
    CTCC)
        YUNOS_CARRIER_CODE="T"
        YUNOS_CARRIER_CTCC=true
    ;;
    CMCC)
        YUNOS_CARRIER_CODE="C"
        YUNOS_CARRIER_CMCC=true
    ;;
    *)
        YUNOS_CARRIER_COMMON=false
        YUNOS_CARRIER_CUSTOMIZED=false
        YUNOS_CARRIER_CODE=""
    ;;
esac
replace_auto_config YUNOS_CARRIER_CODE
replace_auto_config YUNOS_CARRIER_CUSTOMIZED
replace_auto_config YUNOS_CARRIER_COMMON
replace_auto_config YUNOS_CARRIER_CUCC
replace_auto_config YUNOS_CARRIER_CTCC
replace_auto_config YUNOS_CARRIER_CMCC

#process platform macro
YUNOS_PLATFORM_MTK=false
YUNOS_PLATFORM_QUALCOMM=false
YUNOS_PLATFORM_SPREADTRUM=false
case $YUNOS_PLATFORM in
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

export "YUNOS_PROJECT=$YUNOS_PROJECT"
export "TARGET_BUILD_VARIANT=$TARGET_BUILD_VARIANT"
export "YUNOS_PROJECT_NAME=$YUNOS_PROJECT_NAME" 
OPTIONS="-o=YUNOS_PROJECT=$YUNOS_PROJECT"
OPTIONS="$OPTIONS,TARGET_BUILD_VARIANT=$TARGET_BUILD_VARIANT"
OPTIONS="$OPTIONS,YUNOS_PROJECT_NAME=$YUNOS_PROJECT_NAME" 
if [ "$MAKEJOBS" != "" ];then
    OPTIONS="$OPTIONS,MAKEJOBS=$MAKEJOBS"
fi

#auto gen cflag file and OPTIONS by the way
echo "#YUNOS_AUTO_GEN: YunOSCFlags.mk" > $OUT_CFLAGS_FILE
while read LINE 
do
    p1=`echo "$LINE" | awk -F "=" '{print $1}' | sed -e 's/^\s+|\s+$//g'`
    p2=`echo "$LINE" | awk -F "=" '{print $2}' | sed -e 's/^\s+|\s+$//g'`
    #skip empty or comment line
    if [ -z "$p1$p2" ]; then
        continue
    fi
    if [ -n "`echo $p1 | grep -E '^\#'`" ]; then
        continue
    fi
    case $p2 in
        no|false|off)
        ;;
        yes|true|on)
            echo "COMMON_GLOBAL_CFLAGS += -D$p1" >> $OUT_CFLAGS_FILE
        ;;
        *)
            echo "COMMON_GLOBAL_CFLAGS += -D$p1=$p2" >> $OUT_CFLAGS_FILE
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
echo "Flag[YUNOS_SUPPORT_CTA]     for cta feature:           [$YUNOS_SUPPORT_CTA]"

echo "OPTIONS:"
echo "$OPTIONS"
main(){
    export DATE=`date +%Y-%m-%d-%H%M`
    #get platform by project name
    echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
    echo "WEB_RUNTIME_ENABLE $WEB_RUNTIME_ENABLE"

    source ./aliyunos/prebuilts/apps/prebuilt_mk.sh $YUNOS_PROJECT_NAME $OPTIONS

    platform=""
    case $YUNOS_PROJECT_NAME in
        a800)
            echo "choose a800"
            source build/envsetup.sh
            choosecombo release full_a800 $TARGET_BUILD_VARIANT
        ;;
        yk628)
            echo "choose yk628"
            config_unsign
            source build/envsetup.sh
            choosecombo release full_yk628 $TARGET_BUILD_VARIANT
        ;;
        6735m|aeon6735m_65c_s_l1)
            echo "choose 6735m"
            config_unsign
            source build/envsetup.sh
            lunch full_aeon6735m_65c_s_l1-$TARGET_BUILD_VARIANT
        ;;
        hyf9300)
            echo "choose hyf9300"
            config_unsign
            source build/envsetup.sh
            choosecombo release full_hyf9300 $TARGET_BUILD_VARIANT
        ;;
        6735m_64)
            echo "choose 6735m_64"
            config_unsign
            source build/envsetup.sh
            choosecombo release full_6735m_64 $TARGET_BUILD_VARIANT
        ;;
        6735|aeon6735_65c_s_l1)
            echo "choose 6735"
            source build/envsetup.sh
            lunch full_aeon6735_65c_s_l1-$TARGET_BUILD_VARIANT
        ;;
        nexus5)
            echo "choose nexus5"
            source build/envsetup.sh
            choosecombo release cm_hammerhead $TARGET_BUILD_VARIANT
        ;;
        nexus4)
            echo "choose nexus4"
            source build/envsetup.sh
            choosecombo release cm_mako $TARGET_BUILD_VARIANT
        ;;
        i9300)
            echo "choose i9300"
            source build/envsetup.sh
            choosecombo release cm_i9300 $TARGET_BUILD_VARIANT
        ;;
        i9500)
            echo "choose i9500"
            source build/envsetup.sh
            choosecombo release cm_i9500 $TARGET_BUILD_VARIANT
        ;;
        i9508)
            echo "choose i9508"
            source build/envsetup.sh
            choosecombo release cm_jflte $TARGET_BUILD_VARIANT
        ;;
        hlte)
            echo "choose hlte"
            source build/envsetup.sh
            choosecombo release cm_hlte $TARGET_BUILD_VARIANT
        ;;
        find7)
            echo "choose find7"
            source build/envsetup.sh
            choosecombo release cm_find7 $TARGET_BUILD_VARIANT
        ;;
        t6)
            echo "choose t6"
            source build/envsetup.sh
            choosecombo release cm_t6 $TARGET_BUILD_VARIANT
        ;;
        falcon)
            echo "choose falcon"
            source build/envsetup.sh
            choosecombo release cm_falcon $TARGET_BUILD_VARIANT
        ;;
        aries)
            echo "choose aries"
            source build/envsetup.sh
            choosecombo release cm_aries $TARGET_BUILD_VARIANT
        ;;
        bacon)
            echo "choose bacon"
            source build/envsetup.sh
            choosecombo release cm_bacon $TARGET_BUILD_VARIANT
        ;;
        honami)
            echo "choose honami"
            source build/envsetup.sh
            choosecombo release cm_honami $TARGET_BUILD_VARIANT
        ;;
        nx403a)
            echo "choose nx403a"
            source build/envsetup.sh
            choosecombo release cm_nx403a $TARGET_BUILD_VARIANT
        ;;
        nx507j)
            echo "choose nx507j"
            source build/envsetup.sh
            choosecombo release cm_nx507j $TARGET_BUILD_VARIANT
        ;;
        klte)
            echo "choose klte"
            source build/envsetup.sh
            choosecombo release cm_klte $TARGET_BUILD_VARIANT
        ;;
        kltezm)
            echo "choose kltezm"
            source build/envsetup.sh
            choosecombo release cm_kltezm $TARGET_BUILD_VARIANT
        ;;
        cancro)
            echo "chose cancro"
            source build/envsetup.sh
            choosecombo release cm_cancro $TARGET_BUILD_VARIANT
        ;;
        n7100)
            echo "chose n7100"
            source build/envsetup.sh
            choosecombo release cm_n7100 $TARGET_BUILD_VARIANT
        ;;
        *)
            echo "DON'T KNOW HOW TO MAKE!!!!!!!!!!!!!"
        ;;
    esac
echo "$YUNOS_PROJECT_NAME" >out/projectName.txt
echo "$TARGET_BUILD_VARIANT" >out/options.txt
echo "MTK_BASE_PROJECT $MTK_BASE_PROJECT"

env
CPUCORES=`cat /proc/cpuinfo | grep processor | wc -l`
echo "CPU CORES = $CPUCORES"
echo "DEFAULT_CONFIG_FILE $DEFAULT_CONFIG_FILE"
echo "BASE $BASE"

#make -j${CPUCORES} bootimage
#make -j${CPUCORES} systemimage >make.log 2>&1
make update-api
#make -j${CPUCORES} otapackage
make otapackage -j${CPUCORES} -k $moreArgs 2>&1
#make -j${CPUCORES}
}
main
