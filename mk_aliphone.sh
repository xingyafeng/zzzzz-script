#!/bin/bash

### add by yunovo for jenkins
export LANGUAGE=en_US
export LC_ALL=en_US.UTF-8

### common
build_project=
build_version=
build_clean=
build_refs=
build_update_code=
build_mode=

## 6735
YUNOS_PROJECT_NAME=$1
## eng user userdebug
TARGET_BUILD_VARIANT=
## adb acb
TERMINAL_MODE=adb
## remake new
MAKE_TYPE=remake

## tmp variable
t_project_name=
t_custom_verion=

voice_mode=
CPUCORES=`cat /proc/cpuinfo | grep processor | wc -l`

## yunos project name
mx1_kkxl_v9_p=mx1_kkxl_v9
mx1_kkxl_v9_ts_p=mx1_kkxl_v9_ts
mx1_teyes_t7_p=mx1_teyes_t7
mx1_teyes_t8_p=mx1_teyes_t8
mx1_teyes_t8_new_p=mx1_teyes_t8_new
mx1_anytek_m960_p=mx1_anytek_m960

mx2_teyes_t8_p=mx2_teyes_t8
mx2_teyes_t8_new_p=mx2_teyes_t8_new

k88c_lufeng_f100_p=k88c_lufeng_f100
k88c_cocolife_v6_p=k88c_cocolife_v6

k26s_vst_i7_p=k26s_vst_i7
k26s_vst_i7s_p=k26s_vst_i7s
k26s_renwoyou_cs86_p=k26s_renwoyou_cs86

################

function __echo()
{
    local msg=$1

    if [ "$msg" ];then
        echo
        echo "--> $msg"
        echo
    else
        echo "msg is null! please check it."
    fi
}

function _echo()
{
    local msg=$1

    if [ "$msg" ];then
        echo "$msg"
        echo
    else
        echo "msg is null! please check it."
    fi
}

function __msg()
{
    local dir=`pwd`

    echo "---- dir: $dir"
    echo
}

function handler_print()
{
    __echo "make android start ..."

    echo "CPUCORES = $CPUCORES"
    echo "---------------yunos---------------"
    echo "YUNOS_PROJECT_NAME = $YUNOS_PROJECT_NAME"
    echo "TARGET_BUILD_VARIANT = $TARGET_BUILD_VARIANT"
    echo "TERMINAL_MODE = $TERMINAL_MODE"
    echo "MAKE_TYPE = $MAKE_TYPE"
    echo "--------------yunovo---------------"
    echo "build_project = $build_project"
    echo "build_version = $build_version"
    echo "build_clean = $build_clean"
    echo "build_refs = $build_refs"
    echo "build_update_code = $build_update_code"
    echo "build_mode = $build_mode"

    echo "-----------------------------------"
    echo "build_project = $build_project"
    echo "t_project_name = $t_project_name"
    echo "t_custom_verion = $t_custom_verion"
    echo "-----------------------------------"
    echo "voice_mode = $voice_mode"
    echo "-----------------------------------"
    echo
}

function handler_vairable()
{
    ## 1. project name
    if [ "$yunovo_project" ];then
        build_project=$yunovo_project

        t_project_name=${build_project%%_*}
        t_custom_verion=${build_project##*_}
    else
        _echo "yunovo_project_name is null, please check it !"
        exit 1
    fi

    ## 2. build version
    if [ "$yunovo_version" ];then
        build_version=$yunovo_version
    else
        _echo "yunovo_version is null, please check it !"
        exit 1
    fi

    ## 3. build type
    if [ "$yunovo_type" ];then
        TARGET_BUILD_VARIANT=$yunovo_type
    else
        TARGET_BUILD_VARIANT=user
    fi

    ## 4. build clean
    if [ "$yunovo_clean" ];then
        build_clean=$yunovo_clean
    else
        build_clean=false
    fi

    ## 5. build refs
    if [ "$yunovo_refs" ];then
        build_refs=$yunovo_refs
    else
        build_refs=false
    fi

    ## 6. build update code
    if [ "$yunovo_update_code" ];then
        build_update_code=$yunovo_update_code
    else
        build_update_code=true
    fi

    ## 7. YUNOS_PROJECT_NAME
    if [ "$YUNOS_PROJECT_NAME" ];then

        if [ "$YUNOS_PROJECT_NAME" == "magc6580_we_l" ];then
            :
        else
            echo "YUNOS_PROJECT_NAME do not match, please check it !"
            exit 1
        fi
    else
        YUNOS_PROJECT_NAME=6735
    fi

    ## 8 VR_MODE
    if [ "$yunovo_vr_mode" ];then
        build_mode=$yunovo_vr_mode
    else
        __echo " yunovo_vr_mode is null, please check it !"
    fi

    voice_mode="VR_MODE=$build_mode"
}

### 是否为阿里的项目
function is_yunos_project
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    case $thisP in

        $mx1_kkxl_v9_p | $mx1_kkxl_v9_ts_p | $mx1_teyes_t8_p | $mx1_teyes_t8_new_p | $mx1_anytek_m960_p | $mx1_teyes_t7_p)
            echo true

            ;;

        $mx2_teyes_t8_p | $mx2_teyes_t8_new_p)
            echo true

            ;;

        $k88c_lufeng_f100_p | "${k88c_cocolife_v6_p}-k")
            echo true

            ;;

        $k26s_vst_i7_p | $k26s_vst_i7s_p | $k26s_renwoyou_cs86_p)
            echo true

            ;;

        *)
            echo false

            ;;
    esac
}

function auto_create_manifest()
{
    local remotename=
    local username=`whoami`
    local datetime=`date +'%Y.%m.%d_%H.%M.%S'`
    local refsname=${build_project}_${build_version}_${datetime}
    local prj_name=`get_project_name`

    local manifest_path=.repo/manifests
    local manifest_default=default.xml
    local manifest_name=tmp.xml
    local manifest_branch=

    local projectN=${prj_name%%_*}
    local customN=${prj_name#*_} && customN=${customN%%_*}
    local modeN=${prj_name##*_}

    if [ $customN == "kkxl" ];then
        customN=cocolife
    fi

    if [ "$modeN" == "new" ];then
        modeN=t8_new
    fi

    if [ "$modeN" == "ts" ];then
        modeN=v9-ts
    fi

    manifest_branch="yunos/$projectN/$customN/$modeN"

    _echo "manifest_branch = $manifest_branch"

    if [ "`is_yunos_project`" == "true" ];then

        ## create tmp.xml
        repo manifest -r -o $manifest_path/$manifest_name

        cd $manifest_path > /dev/null

        remotename=`git remote`

        if [ -f $manifest_name ];then
            mv $manifest_name $manifest_default
            if [ "`git status -s`" ];then
                git add $manifest_default
                git commit -m "add manifest for $refsname"
                git push $remotename HEAD:refs/build/$username/$refsname
            else
                _echo "$manifest_default is not change ."
                exit 1
            fi
        else
            _echo "$manifest_name is not exist ."
            exit 1
        fi

        cd - > /dev/null

        repo init -b $manifest_branch
    else
        _echo "current directory is not android !"
        exit 1
    fi
}

function auto_create_branch_refs()
{
    local username=`whoami`
    local remotename=yunos
    local datetime=`date +'%Y.%m.%d_%H.%M.%S'`
    local refsname=${build_project}_${build_version}_${datetime}
    local ls_remote_p=frameworks/base
    local is_create_refs=

    if [ "`is_yunos_project`" == "true" ];then

        cd $ls_remote_p > /dev/null

        if [ "`git ls-remote --refs $remotename | grep $refsname`" ];then
            is_create_refs=true
        else
            is_create_refs=false
        fi

        cd - > /dev/null

        if [ "$is_create_refs" == "true" ];then
            _echo "--> $refsname is exist ..."
        else
            repo forall -c git push yunos HEAD:refs/build/$username/$refsname

            __echo "create branch refs successful ..."
        fi
    else
        _echo "current directory is not android !"
        return 1
    fi
}

function get_project_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    if [ "$thisP" ];then
        echo $thisP
    else
        return 1
    fi
}

function repo_sync_for_source_code()
{
    if repo sync -c -d --prune --no-tags -j8;then
        __echo "repo sync successful ..."
    else
        if repo sync -c -d --prune --no-tags -j8;then
            __echo "repo sync successful 2 ..."
        else
            repo sync -c -d --prune --no-tags -j8 && __echo "repo sync successful 3 ..."
        fi
    fi
}

function chiphd_get_repo_git_path_from_xml()
{
    local default_xml=.repo/manifest.xml
    if [ -f $default_xml ]; then
        grep '<project' $default_xml | sed 's%.*path="%%' | sed 's%".*%%'
    fi
}

function chiphd_recover_project()
{
    local tDir=$1
    if [ ! "$tDir" ]; then
        tDir=.
    fi

    if [ -d $tDir/.git ]; then
        local OldPWD=$(pwd)
        cd $tDir > /dev/null
        if [ "`git status -s`" ];then
            echo "---- recover $tDir"
        else
            cd $OLDPWD
            return 0
        fi

        thisFiles=`git diff --cached --name-only`
        if [ "$thisFiles" ];then
            git reset HEAD . ###recovery for cached files
        fi

        thisFiles=`git clean -dn`
        if [ "$thisFiles" ]; then
            git clean -df
        fi

        #thisFiles=`git diff --cached --name-only`
        #if [ "$thisFiles" ]; then
        #git checkout HEAD $thisFiles
        #fi

        thisFiles=`git diff --name-only`
        if [ "$thisFiles" ]; then
            git checkout HEAD $thisFiles
        fi
        cd $OldPWD
    fi
}

function recover_standard_android_project()
{
    local tOldPwd=$OLDPWD
    local tNowPwd=$PWD

    cd $BASE > /dev/null
    #echo "now get all project from repo..."

    local AllRepoProj=`chiphd_get_repo_git_path_from_xml`
    #echo $AllRepoProj
    if [ "$AllRepoProj" ]; then
        for ProjPath in $AllRepoProj
        do
            if [ -d $BASE/$ProjPath ];then
                chiphd_recover_project $ProjPath
            fi
        done
    fi

    cd $tOldPwd
    cd $tNowPwd
}

function download_yunos_code()
{
    local prj_name=`get_project_name`
    local link_name="init -u ssh://jenkins@gerrit.y:29419/manifest"
    local branchN=

    local projectN=${prj_name%%_*}
    local customN=${prj_name#*_} && customN=${customN%%_*}
    local modeN=${prj_name##*_}

    if [ $customN == "kkxl" ];then
        customN=cocolife
    fi

    if [ "$modeN" == "new" ];then
        modeN=t8_new
    fi

    if [ "$modeN" == "ts" ];then
        modeN=v9-ts
    fi

    branchN="yunos/$projectN/$customN/$modeN"

    _echo "branchN = $branchN"

    if [ ! -d .repo  ];then
        repo $link_name -b $branchN

        repo_sync_for_source_code
    else
        repo init -b $branchN
        repo_sync_for_source_code
    fi
}

## 复制版本到阿里版本下 ~/yunos
function copy_image_to_folder()
{
    local firmware_path=~/.yunos
    local server_name=`hostname`
    local default_version_name=""
    local BASE_PATH=$firmware_path/$t_project_name/${t_project_name}_${t_custom_verion}/$build_version

    if [ ! -d $firmware_path ];then
        mkdir -p $firmware_path
    fi

    if [ ! -d $BASE_PATH ];then
        mkdir -p $BASE_PATH
    fi

    if [ $YUNOS_PROJECT_NAME == "6735" ];then
        YUNOS_PROJECT_NAME=aeon6735_65c_s_l1
    fi

    default_version_name=release-${YUNOS_PROJECT_NAME}

    if [ -d $default_version_name ];then
        mv $default_version_name/* $BASE_PATH
    fi

    if [ "`ls ${OUT}/full_${YUNOS_PROJECT_NAME}-ota*.zip`" ];then
        cp ${OUT}/full_${YUNOS_PROJECT_NAME}-ota*.zip $BASE_PATH/../${build_version}_sdupdate.zip
        _echo "--> copy sdupdate.zip sucessful ..."
    fi
}

## 同步阿里版本到f1服务器上
function rsync_version_to_f1_server()
{
    local firmware_path=~/.yunos
    local share_path=/public/jenkins/jenkins_share_20T
    local jenkins_f1_server=jenkins@f1.y

    if [ -d $firmware_path ];then
        rsync -av $firmware_path/ $jenkins_f1_server:$share_path/yunos
    fi

    if [ -d $firmware_path  ];then
        rm $firmware_path/* -rf
    else
        _echo "$firmware_path not found !"
    fi

    _echo "--> sync end ..."
}

handler_vairable
handler_print
### add by yunovo

# ///////////////////////////////////////////////////////分界线 #

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
	"magc6580_we_l"
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
if false;then
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
fi

if false;then
#if can not find project name, input it
if [ "$YUNOS_PROJECT_NAME" = "" ];then
    echo "target project name:"
    _inlist=(${YUNOS_PROJECT_NAME_LIST[@]})
    select_choice YUNOS_PROJECT_NAME
fi
fi

project=$YUNOS_PROJECT_NAME
echo "get project name: $YUNOS_PROJECT_NAME"

if false;then
if [ -n "$(echo $* | grep ' new')" ];then
     make clean
fi
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
    sed -i "s/^$p1=[^=]*/$p1=$p2/g" $OUT_CONFIG_FILE 2> /dev/null
done < "$OUT_CFLAGS_FILE"

_input_args=($*)
if false;then
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

function print_make_completed_time()
{
    local startT=$1
    local endT=`date +'%Y-%m-%d %H:%M:%S'`
    local useT=

    local hh=
    local mm=
    local ss=

    useT=$(($(date +%s -d "$endT") - $(date +%s -d "$startT")))

    hh=$((useT / 3600))
    mm=$(((useT - hh * 3600) / 60))
    ss=$((useT - hh * 3600 - mm * 60))

    echo "#### make completed successfully ($hh:$mm:$ss (hh:mm:ss)) ###"
}

function main()
{
    export DATE=`date +%Y-%m-%d-%H%M`
    local start_curr_time=`date +'%Y-%m-%d %H:%M:%S'`
    local end_curr_time=
    #get platform by project name
    echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
    echo "WEB_RUNTIME_ENABLE $WEB_RUNTIME_ENABLE"
    echo

    if [ "`is_yunos_project`" == "true" ];then
        :
    else
        _echo "current directory is not android !"
        exit 1
    fi

    if [ "$build_update_code" == "true" ];then

        ##恢复源码到干净状态
        recover_standard_android_project

        ##下载并更新源码
        download_yunos_code

    else
        _echo "build_update_code = false"
    fi
    ## 阿里脚本处理
    source aliyunos/prebuilts/apps/prebuilt_mk.sh $YUNOS_PROJECT_NAME $OPTIONS
    echo

    platform=""
    case $YUNOS_PROJECT_NAME in
        6735m|aeon6735m_65c_s_l1)
            echo "choose 6735m"
            config_unsign
            source build/envsetup.sh
            lunch full_aeon6735m_65c_s_l1-$TARGET_BUILD_VARIANT
        ;;
        6735|aeon6735_65c_s_l1)
            echo "choose 6735"
            source build/envsetup.sh
            lunch full_aeon6735_65c_s_l1-$TARGET_BUILD_VARIANT
        ;;
        magc6580_we_l)
            echo "choose magc6580_we_l"
            source build/envsetup.sh
            lunch full_magc6580_we_l-$TARGET_BUILD_VARIANT
        ;;
        *)
            echo "DON'T KNOW HOW TO MAKE!!!!!!!!!!!!!"
        ;;
    esac

    __echo "source end ..."

    if [ "$build_clean" == "true" ];then
        make clean
        _echo "--> make clean end."
    else
        make installclean
        _echo "--> make installclean end."
    fi

    echo "$YUNOS_PROJECT_NAME" > out/projectName.txt
    echo "$TARGET_BUILD_VARIANT" > out/options.txt
    echo "MTK_BASE_PROJECT $MTK_BASE_PROJECT"

    echo "CPU CORES = $CPUCORES"
    echo "DEFAULT_CONFIG_FILE $DEFAULT_CONFIG_FILE"
    echo "BASE $BASE"
    echo

    if [ "$yunovo_update_api" == "true" ];then
        make update-api -j${CPUCORES}
    fi

    if make otapackage $voice_mode -j${CPUCORES} -k $moreArgs;then
        __echo " make project successful ..."
    else
        __echo " make project fail ..."
        exit 1
    fi

    auto_create_manifest

    ## create branch refs
    if [ $build_refs == "true" ];then
        auto_create_branch_refs
    else
        _echo "build refs is $build_refs ."
    fi

    if [ -f imgout -a -x imgout ];then
        ~/workspace/script/zzzzz-script/tools/imgout
    fi

    ## copye image to folder
    if copy_image_to_folder;then

        ## upolad f1.y server
        rsync_version_to_f1_server
    fi

    if [ "`is_yunos_project`" == "true" ];then

        print_make_completed_time "$start_curr_time"

        __echo "make android end ..."
    else
        _echo "current directory is not android !"
        exit 1
    fi
}

main
