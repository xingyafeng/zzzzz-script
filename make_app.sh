#!/bin/bash

### 若某一个命令返回非零值就退出
set -e

#set java env
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$CLASSPATH:$JAVA_HOME/lib:$JRE_HOME/lib
export PATH=${JAVA_HOME}/bin:$JRE_HOME/bin:$PATH
export LANGUAGE=en_US
export LC_ALL=en_US.UTF-8

################################## args
build_device=$1
build_type=

### build custom
build_app_name=
build_app_refs=

################################# common variate
hw_versiom=H3.1
debug_path=~/debug
cur_time=`date +%m%d_%H%M`
zz_script_path=/home/jenkins/workspace/script/zzzzz-script
cpu_num=`cat /proc/cpuinfo  | egrep 'processor' | wc -l`
project_link="init -u ssh://jenkins@gerrit.y:29419/manifest"
tmp_file=$debug_path/tmp.txt
readme_file=$debug_path/readme.txt
lunch_project=
prefect_name=
system_version=
fota_version=

################################ system env
DEVICE=
ROOT=
OUT=

function __msg()
{
    local pwd=`pwd`

    if [ "$1" ];then
        _echo "---- dir is : $pwd $1"
    else
        _echo "---- dir is : $pwd"
    fi

}

function _echo()
{
    local msg=$1

    if [ $# -eq 1 ];then
        :
    else
        __echo "e.g : _echo xxx"
        return 1
    fi

    if [ "$msg" ];then
        echo "$msg"
        echo
    else
        echo "msg is null, please check it !"
        return 1
    fi
}

function __echo()
{
    local msg=$1

    if [ $# -eq 1 ];then
        :
    else
        echo
        echo "e.g : __echo xxx"
        echo
        return 1
    fi

    if [ "$msg" ];then
        echo
        echo "--> $msg"
        echo
    else
        _echo "msg is null, please check it !"
        return 1
    fi
}

### 检查是否有lunch
function is_check_lunch()
{
    if [ "$DEVICE" ];then
        echo "lunch : path $DEVICE"
    else
        echo "no lunch"
    fi
}

function is_yunovo_project
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    case $thisP in

        $mx1_teyes_t7_p)
            echo true

            ;;

        *)
            echo true

            ;;
    esac
}

function get_project_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    if [ "$thisP" ];then
        echo $thisP
    else
        echo "it do not get project name !"
        return 1
    fi
}

### 是否为master test develop分支
function is_yunovo_branch()
{
    local branch_name=$1
    local branchN=(master develop test)

    if [ $# -eq 1 ];then
        :
    else
        _echo "$# is error, please check args !"
        return 1
    fi

    for b in ${branchN[@]}
    do
        if [ $b == $branch_name ];then
            echo true
        fi
    done
}

### 是否为编译服务器
function is_yunovo_server()
{
    local hostN=`hostname`
    local serverN=(s1 s2 s3 s4 happysongs ww he-All-Series.)
    local isServer=false

    for n in ${serverN[@]}
    do
        if [ "$n" == "$hostN"  ];then
            isServer=true
            echo true
        fi
    done

    if [ $isServer == "false" ];then
        echo true
    fi
}

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

### handler vairable for jenkins
function handler_vairable()
{
    local sz_build_device=$build_device

    ## 1.app name
    if [ "$yunovo_app" ];then
        build_app_name=$yunovo_app
    else
        __echo "app name is null, please check it !"
        return 1
    fi

    ## 2. app refs
    if [ "$yunovo_refs" ];then
        build_app_refs=$yunovo_refs
    else
        __echo "app refs is null, please check it !"
        return 1
    fi

    if [ "$sz_build_device" ];then
        build_device=$sz_build_device
    else
        echo "build_device is null !"
        return 1
    fi

    if [ "$yunovo_type" ];then
        build_type=$yunovo_type
    else
        ## jenkins　不填写，默认为user
        build_type=userdebug
    fi

    if [ "$build_device" -a "$build_type" ];then
        lunch_project=full_${build_device}-${build_type}
    else
        echo "lunch_project is null !"
        return 1
    fi


}

## print variable
function print_variable()
{
    echo "cpu_num = $cpu_num"
    echo "-------------------------"
    echo "build_app_name = $build_app_name"
    echo "build_app_refs = $build_app_refs"
    echo "build_type = $build_type"
    echo "build_device = $build_device"
    echo "-------------------------"
    echo
}

## build android app
function make_yunovo_app()
{
	if [ "$DEVICE" ];then
        :
    else
        if [ -d .repo ];then
            source_init
        else
            _echo "The (.repo) not found ! please download android source code !"
            return 1
        fi
    fi

    local OLDP=`pwd`
    local app_path=packages/apps
    local link=ssh://xingyafeng@gerrit.y:29419/yunovo/packages/apps
    local link_old=ssh://xingyafeng@gerrit.y:29419/yunovo_packages

    if [ "$build_app_name" ];then

        cd $app_path > /dev/null

        if [ "$build_app_name" == "YOcScreenSaver" ];then
            git fetch $link/$build_app_name $build_app_refs
            git checkout FETCH_HEAD
        else
            git fetch $link_old/$build_app_name $build_app_refs
            git checkout FETCH_HEAD
        fi

        touch * && mm -B -j${cpu_num}

        cd $OLDP > /dev/null
    fi
}

### 打印系统环境变量
function print_env()
{
    echo "ROOT = $(gettop)"
    echo "OUT = $OUT"
    echo "DEVICE = $DEVICE"
    echo
}

function source_init()
{
    local magcomm_project=magc6580_we_l
    local eastaeon_project=aeon6735_65c_s_l1
    local eastaeon_project_m=aeon6735m_65c_s_l1

    source  build/envsetup.sh
    __echo "source end ..."

    lunch $lunch_project

    __echo "lunch end ..."

    ROOT=$(gettop)
    OUT=$OUT
    DEVICE_PROJECT=`get_build_var TARGET_DEVICE`

    if [ $DEVICE_PROJECT == $magcomm_project ];then
        DEVICE=device/magcomm/$DEVICE_PROJECT
    elif [ $DEVICE_PROJECT == $eastaeon_project -o $DEVICE_PROJECT == $eastaeon_project_m ];then
        DEVICE=device/eastaeon/$DEVICE_PROJECT
    else
        DEVICE=device/eastaeon/$DEVICE_PROJECT
        _echo "DEVICE do not match it ..."
    fi
    print_env
}

function main()
{
    local start_curr_time=`date +'%Y-%m-%d %H:%M:%S'`

    if [ "`is_yunovo_project`" == "true" ];then
        :
    else
        _echo "current directory is not android !"
        return 1
    fi

    if [ "`is_yunovo_server`" == "true" ];then

        __echo "make app start ."

        handler_vairable $build_device
        print_variable
    else
        _echo "server name is not s1 s2 s3 s4 happysongs ww !"
        return 1
    fi

    if [ -d .repo ];then
        ### 初始化环境变量
        if [ "`is_check_lunch`" == "no lunch" ];then
            source_init
        else
            print_env
        fi
    fi

    ### 编译app
    make_yunovo_app

    if [ "`is_yunovo_server`" == "true" ];then

        ### 打印编译所需要的时间
        print_make_completed_time "$start_curr_time"

        __echo "make android end ."
    else
        echo "server name is not s1 s2 s3 s4 happysongs ww !"
        return 1
    fi
}

main
