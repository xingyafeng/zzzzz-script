#!/usr/bin/env bash

### 若某一个命令返回非零值就退出
set -e

export ANDROID_SET_JAVA_HOME=true
################################## args

### 1. build device
build_device=$1

### 2. build version e.g. system version, S1.00 S1.00.00 S1.00.eng
build_version=""
### S1.00 S1.01 ...
first_version=""
second_version=""

### 3. build type e.g. : eng|user|userdebug
build_type=

### 4. build update-api e.g. cmd make update-api
build_update_api=""

### 5. build update code e.g. is update source code
build_update_code=""

### 6. build clean e.g. : make clean bofore make
build_clean=""

### 7. build make OTA e.g. : is make OTA or not
build_make_ota=""

### 9. build branch e.g. : user test、master、develop branch
build_branch=""

## 11. build_debug
build_debug=""

# 项目项目名称
build_prj_name=

##--------------------------------------- Abandoned

### readme.txt
build_readme=

################################# common variate
shellfs=$0
## make ota
is_test_version=

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

############################################# common function

## 处理jenkins传过来的变量, 并检查其有效性.
function handle_vairable()
{
    local tmp_file=${tmpfs}/tmp.txt
    local readme_file=${tmpfs}/readme.txt

    ## 1. build device
    build_device=`remove_space_for_vairable "$build_device"`
    if [[ "`is_build_device $build_device`" == "false"  ]];then
        __err "build_device error. please check it ."
        return 1
    fi

    ## 2. build version
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

    ## 3. build type
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

    ## 4. build update-api
    if [[ -n "$yunovo_update_api" ]];then
        build_update_api=${yunovo_update_api}
    else
        build_update_api=false
        yunovo_update_api=false
    fi

    ## 5. build update code
    if [[ "$yunovo_update_code" ]];then
        build_update_code=${yunovo_update_code}
    else
        build_update_code=true
        yunovo_update_code=true
    fi

    ## 6. build clean
    if [[ -n "$yunovo_clean" ]];then
        build_clean=${yunovo_clean}
    else
        build_clean=false
        yunovo_clean=false
    fi

    ## 7. build make ota
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

    ## 9. build branch
    if [[ "$yunovo_branch" ]];then
        if [[ "`is_yunovo_branch "$yunovo_branch"`" == "true" ]];then
            build_branch=${yunovo_branch}
        else
            __err "yunovo_branch error, please check it ."
            return 1
        fi
    else
        build_branch=develop
        yunovo_branch=develop
    fi

    ## 11. build debug
    build_debug=${yunovo_debug:-true}
    if [[ "true" == ${yunovo_debug} ]]; then
        build_debug=false
    else
        build_debug=true
    fi

    ############################################

    handler_init_other
    handle_common_variable
    handle_common_para
    handle_compile_para
}

function handler_init_other()
{
    if [[ -z "$build_prj_name" ]];then
        build_prj_name=`get_project_real_name`
    fi
}

## 处理编译参数
function handle_compile_para()
{

    ## 获取触摸配置参数
    get_tp_config

    ## 获取屏配置参数
    get_lcm_config

    ## 获取是否为HardWare2.2
    get_hardware_v2.2

    ## 获取custom mode 配置
    get_custom_mode

    if [[ -n "$system_version"  ]];then
        # 1. 系统版本号FOTA
        compile_para[${#compile_para[@]}]=${fota_version}
    fi

    if [[ -n "$build_prj_name"  ]];then
        # 2. 项目名称
        compile_para[${#compile_para[@]}]=${yunovo_prj_name}
    fi

    if [[ -n "$SPT_TP_TYPE" ]];then
        # 3. TP参数
        compile_para[${#compile_para[@]}]="SPT_TP_TYPE=$SPT_TP_TYPE"
    fi

    if [[ -n "$SPT_LCM_TYPE" ]];then
        # 4 LCM参数
        compile_para[${#compile_para[@]}]="SPT_LCM_TYPE=$SPT_LCM_TYPE"
    fi

    if [[ -n "$YUNOVO_HARDWARE_VERSION" ]];then
        # 5. HardWare v2.2
        compile_para[${#compile_para[@]}]="YUNOVO_HARDWARE_VERSION=$YUNOVO_HARDWARE_VERSION"
    fi
}

function print_variable()
{
    echo "JOBS = $JOBS"
    echo '-----------------------------------------'
    echo "build_version  = $build_version"
    echo "first_version  = $first_version"
    echo "second_version = $second_version"
    echo '-----------------------------------------'
    echo "build_device      = $build_device"
    echo "build_type        = $build_type"
    echo "build_update_api  = $build_update_api"
    echo "build_update_code = $build_update_code"
    echo "build_clean       = $build_clean"
    echo "build_make_ota    = $build_make_ota"
    echo "build_branch      = $build_branch"
    echo "build_debug       = "${build_debug}
    echo '-----------------------------------------'
    echo "yunovo_clean      = $yunovo_clean"
    echo "yunovo_branch     = $yunovo_branch"
    echo "yunovo_update_api = $yunovo_update_api"
    echo "yunovo_update_code= $yunovo_update_code"
    echo '-----------------------------------------'
    echo "is_test_version   = $is_test_version"
    echo "lunch_project     = $lunch_project"
    echo "fota_version      = $fota_version"
    echo "VER               = $VER"
    echo "share rom path    = " ${share_rom_p}

    if [[ -n "${build_prj_name}" ]]; then
        echo "build_prj_name    = ${build_prj_name}"
    fi

    if [[ -n "${CUSTOM_MODEM}" ]]; then
        echo "CUSTOM_MODEM      = $CUSTOM_MODEM"
    fi

    echo '-----------------------------------------'
    echo "compile_para = ${compile_para[@]}"
    echo '-----------------------------------------'
    echo "\$1 = $1"
    echo "\$2 = $2"
    echo "\$3 = $3"
    echo "\$# = $#"
    echo '-----------------------------------------'
    echo
}

function main()
{
    local startT=`date +'%Y-%m-%d %H:%M:%S'`

    if [[ "`is_main_branch`" == "true" || "`is_cta_project`" == "true" ]];then

        if [[ ! -d ${version_p} ]];then
            mkdir -p ${version_p}
        fi
    else
        __err "主分支才支持编译公版软件."
        return 1
    fi

    if [[ "`is_yunovo_server`" == "true" ]];then

        echo
        show_vip "--> make android start ."

        if [[ "$build_device" ]];then

            handle_vairable

            ### 输出完整参数
            print_variable ${build_version} ${build_device} ${build_type}

        else
            __err "参数不正确，请检查传入参数 ..."
            return 1
        fi

    else
        __err "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
        return 1
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        ### 初始化环境变量
        if [[ "`is_check_lunch`" == "no lunch" ]];then
            source_init
        else
            print_env
        fi
    fi

    if [[ "$build_update_code" == "true" ]];then

        download_mirror

        ## 下载，更新源码
        down_load_yunovo_source_code
    else
        __wrn "This time you don't update the source code."
    fi

    ### 编译系统源码
    make_yunovo_android

    if [[ "`is_yunovo_server`" == "true" ]];then

        ### 打印编译所需要的时间
        print_make_completed_time

        echo
        show_vip "--> make android end ."
    else
        __err "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
        return 1
    fi
}

main
