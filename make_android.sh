#!/bin/bash

## 若某一个命令返回非零值就退出
set -e

## 设置JAVA环境变量
unset -v JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH
export LANGUAGE=en_US
export LC_ALL=en_US.UTF-8

export ANDROID_SET_JAVA_HOME=true
################################## args

## 0.0 build email
build_email=""
## 0.1 build cc address
build_cc_address=""
## 0.2 build board
build_board=""

#### --------------------------------------

## 1. 如: [ aeon6735_65c_s_l1|magc6580_we_l|yunovo| ** ]
build_device=$1
## 2. 项目名称,包含[版型|客户|项目]格式
build_prj_name=$2
## 项目名
project_name=""
## 客户名
custom_version=""
## 3. 客制化路径
build_file=$3
## 4. 编译版本号
build_version=""
first_version=""
second_version=""
## 5. 编译类型 如: [user|userdebug|eng]
build_type=""
## 6. 更新系统的API
build_update_api=""
## 7. 更新源代码
build_update_code=""
## 8. 是否清除
build_clean=""
## 9. 是否编译OTA
build_make_ota=""
## 10. 构建参数
build_para=""
## 11. build_debug
build_debug=""
## 12. build release type [ Daily/Debug/Release ]
build_release_type=""
## 13. build release tag
build_release_tag=""
## 14. build release type
build_signature_type=""
## 15. build fake ota
build_fake_ota=""
## 16. build lk
build_lk=""
## 17. build preloader
build_preloader=""

####--------------------------------------- common variate

# 执行脚本名称
shellfs=$0

## 是否为测试版本
is_test_version=""
## 是否编译原生版本
is_public_version=""

## rom info
declare -a rom_info

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

############################################# common function

## 处理变量, 并检查其有效性.
function handle_vairable()
{
    local readme_file=${tmpfs}/readme.txt

    ## ------------------------------------------------------------------------ 对变量进行校验

    ## 1. build device
    if [[ "`is_build_device`" == "false" || -z ${build_device} ]];then
        log error "build_device has error. please check it ."
    fi

    ## 2. build project name
    build_prj_name=`remove_space_for_vairable "${build_prj_name}"`
    project_name=${build_prj_name%%_*}
    custom_version=`echo ${build_prj_name##*_} | tr 'a-z' 'A-Z'`
    build_prj_name=${project_name}_${custom_version}

    if [[ -z "$project_name" ||  -z "$custom_version" ]];then
        log error "project_name or custom_version is NULL. please check it ."
    fi

    ## 3. build file
    build_file=`remove_space_for_vairable "$build_file"`
    if [[ "`echo ${build_file} | egrep /`" ]];then
        prefect_name=${build_file}
    else
        log error "build_file has error, please check it ."
    fi

    ## 4. build version
    if [[ "$yunovo_version" ]];then
        yunovo_version=`remove_space_for_vairable "$yunovo_version" | tr 'a-z' 'A-Z'`

        if [[ -n "`echo ${yunovo_version} | sed -n '/^[S|V]/p'`" ]];then
            split_system_version
        else
            log error "build_version has error, please check it ."
        fi
    else
        log error "yunovo_version is null, please check it ."
    fi

    ## 5. build type
    build_type=${yunovo_type:=user}

    # 检查编译类型是否符合要求
    if [[ "`is_build_type`" == "false" ]];then
        ## 若jenkins填写不规范，默认为user
        build_type=user
    fi

    # 展讯项目,支持eng版本. 当选择了eng,默认赋值userdebug
    if [[ "`is_sc_project`" == "true" ]]; then
        case ${build_type} in
            eng)
                build_type=userdebug
                ;;
            *)
                :
                ;;
        esac
    fi

    ## 6. build update-api
    build_update_api=${yunovo_update_api:=false}

    ## 7. build update code
    build_update_code=${yunovo_update_code:=true}

    ## 8. build clean
    build_clean=${yunovo_clean:=false}

    ## 9. build make ota
    build_make_ota=${yunovo_ota:-true}

    ## 10. build para
    build_para=${yunovo_para:=}

    ## 11. build debug
    build_debug=${yunovo_debug:-true}
    if [[ "true" == ${yunovo_debug} ]]; then
        build_debug=false
    else
        build_debug=true
    fi

    ## 12.  build release type
    build_release_type=${yunovo_release_type:=Debug}

    ## 13. build release key
    if [[ -n ${yunovo_release_tag}  ]]; then
        build_release_tag="refs/build/${git_username}/${yunovo_release_tag}"
    else
        build_release_tag=${yunovo_release_tag:=}
    fi

    ## 14. build release type
    build_signature_type=${yunovo_signature_type:-false}

    ## 15. build fake ota
    build_fake_ota=${yunovo_fake_ota:-false}

    ## 16. build lk
    build_lk=${yunovo_lk:-false}

    ## 17. build preloader
    build_preloader=${yunovo_preloader:-false}

    ## ------------------------------------------------------------------------

    handle_common_variable
    handle_common_para
    handle_compile_para
    handle_extra_transactions
}

## 处理编译参数
function handle_compile_para()
{
    ## 获取音频功放等级
    get_audio_level

    ## 是否不支持custom分区
    get_custom_config

    ## 获取lk lcm config
    get_custom_lk_lcm

    ## 获取modem config
    get_custom_mode

    if [[ -n "$system_version" ]];then
        # 1. 系统版本号FOTA
        compile_para[${#compile_para[@]}]=${fota_version}
    fi

    if [[ -n "$yunovo_prj_name" ]];then
        # 2. 项目名称
        compile_para[${#compile_para[@]}]=${yunovo_prj_name}
    fi

    if [[ -n "`echo ${audio_level} | grep level`" ]];then
        ## 3. 音频功放等级
        compile_para[${#compile_para[@]}]=${audio_level}
    fi

    if [[ -n "$build_para" ]];then
        ## 4. 定制编译参数
        compile_para[${#compile_para[@]}]=${build_para}
    fi

    if [[ -n "$MTK_CIP_SUPPORT" ]];then
        ## 5. 设置不支持custom分区
        compile_para[${#compile_para[@]}]="MTK_CIP_SUPPORT=$MTK_CIP_SUPPORT"
    fi

    if [[ -n "$yunovo_board" ]];then
        ## 硬件板型
        compile_para[${#compile_para[@]}]="YOV_BOARD=$yunovo_board"
    fi

    if [[ -n "$yunovo_custom" ]];then
        ## 客户名称
        compile_para[${#compile_para[@]}]="YOV_CUSTOM=$yunovo_custom"
    fi

    if [[ -n "$yunovo_project" ]];then
        ## 客户项目
        compile_para[${#compile_para[@]}]="YOV_PROJECT=$yunovo_project"
    fi

    if [[ -n "$yov_fota_version" ]];then
        ## nxos系统版本号
        compile_para[${#compile_para[@]}]=${yov_fota_version}
    fi

    if [[ -n "$yov_release_tag" ]];then
        ## 封板标签
        compile_para[${#compile_para[@]}]=${yov_release_tag}
    fi

    if [[ -n "${build_release_type}" ]]; then
        ## 版本类型
        compile_para[${#compile_para[@]}]=${yov_release_type}
    fi

    if [[ -n "${BUILD_ID}" ]]; then
        ## 构建编号 jenkins
        compile_para[${#compile_para[@]}]=${yov_build_id}
    fi

    if [[ -n "${build_signature_type}" ]]; then
        ## 签名类型
        compile_para[${#compile_para[@]}]=${yov_signature_type}
    fi

    if [[ -n "`is_public_project`" ]]; then
        ## 是否编译公版软件
        compile_para[${#compile_para[@]}]=${is_public_version}
    fi
}

# 处理额外的事务，专注特殊事项
function handle_extra_transactions() {

    if [[ -n ${yunovo_pre_version} ]]; then

        if [[ -z "`echo ${yunovo_pre_version} | sed -n '/^[S|V]/p'`" ]]; then
            log error "yunovo_pre_version has error, please check it ."
        fi
    fi

    if [[ "`is_zen_project`" == "true" ]]; then
        touch_rom_json
    fi
}

function print_variable()
{
    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "builder = " ${build_builder}
    echo '-----------------------------------------'
    echo "build_prj_name = " ${build_prj_name}
    echo "project_name   = " ${project_name}
    echo "custom_version = " ${custom_version}
    echo '-----------------------------------------'
    echo "prefect_name   = " ${prefect_name}
    echo '-----------------------------------------'
    echo "build_version  = " ${build_version}
    echo "first_version  = " ${first_version}
    echo "second_version = " ${second_version}
    echo '-----------------------------------------'
    echo "build_device      = " ${build_device}
    echo "build_type        = " ${build_type}
    echo "build_update_api  = " ${build_update_api}
    echo "build_update_code = " ${build_update_code}
    echo "build_clean       = " ${build_clean}
    echo "build_fake_ota    = " ${build_fake_ota}
    echo "build_make_ota    = " ${build_make_ota}
    echo "build_lk          = " ${build_lk}
    echo "build_preloader   = " ${build_preloader}
    echo "build_debug       = " ${build_debug}
    echo "build_board       = " ${build_board}
    echo "build_email       = " ${build_email}
    echo "build_cc_address  = " ${build_cc_address}

    if [[ -n ${build_release_tag} ]]; then
        echo "build_release_tag    = " ${build_release_tag}
    fi

    echo "build_release_type   = " ${build_release_type}
    echo "build_signature_type = " ${build_signature_type}
    echo '-----------------------------------------'
    echo "is_test_version      = " ${is_test_version}
    echo "is_public_version    = " ${is_public_version}
    echo "lunch_project        = " ${lunch_project}
    echo "fota_version         = " ${fota_version}
    echo "yunovo_prj_name      = " ${yunovo_prj_name}
    echo "rename_sdupdate      = " ${rename_sdupdate}
    echo '-----------------------------------------'
    echo "manifest  branch     = " ${manifest_branchN}
    echo "manifest  path       = " ${manifest_path}
    echo "share rom path       = " ${share_rom_p}

    echo '-----------------------------------------'
    echo "compile_para  = " ${compile_para[@]}
    echo
    echo "rom_info      = " ${rom_info[@]}

    if [[ -n ${CUSTOM_MODEM} ]]; then
        echo "CUSTOM_MODEM  = " ${CUSTOM_MODEM}
    fi

    if [[ -n ${CUSTOM_LK_LCM} ]]; then
        echo "CUSTOM_LK_LCM = " ${CUSTOM_LK_LCM}
    fi
    echo '-----------------------------------------'
    echo "\$1 = $1"
    echo "\$2 = $2"
    echo "\$3 = $3"
    echo "\$4 = $4"
    echo "\$5 = $5"
    echo "\$# = $#"
    echo '-----------------------------------------'
}

function prepare() {

    ## ------------------------------------------------------------------------ zen平台参数

    if [[ "`is_zen_project`" == "true" ]]; then

        ## 0.0 发件人邮箱
        build_email=${yunovo_email:="notify@yunovo.cn"}
        for e in $(splitstring "${build_email}" ";") ; do
            if [[ "`is_check_email ${e}`" == "false" ]]; then
                log error "${e} 邮箱格式有误 ..."
            fi
        done

        ## 0.1 抄送邮件人邮箱
        build_cc_address=${yunovo_carboncopy:-}
        if [[ ! "${build_cc_address}" =~ "281220263@qq.com" ]]; then
            for e in $(splitstring "${build_cc_address}" ";") ; do
                if [[ "`is_check_email ${e}`" == "false" ]]; then
                    log error "${e} 邮箱格式有误 ..."
                fi
            done
        fi

        ## 0.2 build board [版型]
        if [[ -n "$yunovo_board" ]];then
            build_board=`remove_space_for_vairable "$yunovo_board"`
        else
            log error "yunovo_board has error. please check it ."
        fi

        ## 0.3 yunovo custom [客户]
        if [[ -z "$yunovo_custom" ]];then
            log error "yunovo_custom has error. please check it ."
        fi

        ## 0.4 yunovo project [项目]
        if [[ -z "$yunovo_project" ]];then
            log error "yunovo_project has error. please check it ."
        fi

        cd_to_gettop

        ## 0.5 build_device [设备]
        build_device=`get_device_type`

        echo
        show_vip "This project is a Zen platform project."
    else
        gettop_p=$(pwd)

        show_viy "This project is not a Zen platform project."
    fi
}

## 初始化 Jenkins参数
function init()
{
    prepare

    if [[ -n ${build_prj_name} && -n ${build_device} && -n ${build_file} ]];then
        handle_vairable
        print_variable ${build_prj_name} ${build_version} ${build_device} ${build_type} ${build_file}
    else
        log error "参数不正确，请检查传入参数 ..."
    fi
}

function main()
{
    ## 记录编译开始时间
    local startT=`date +'%Y-%m-%d %H:%M:%S'`

    if [[ "`is_yunovo_server`" == "true" ]];then
        init
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi

    if [[ "`is_yunovo_project`" == "true" ]];then
        echo
        show_vip "--> make android start ." && log debug "--> make android start ."

        if [[ "${build_update_code}" == "true" ]];then
            download_mirror
            down_load_yunovo_source_code
        else
            log warn "This time you don't update the source code."
        fi
    else
        log error "It is not android top at the current directory."
    fi


    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        ### 初始化环境变量
        if [[ "`is_check_lunch`" == "no lunch" ]];then
            source_init
        else
            print_env
        fi
    fi

    make_yunovo_android

    if [[ "`is_yunovo_server`" == "true" ]];then

        ### 打印编译所需要的时间
        print_make_completed_time

        echo
        show_vip "--> make android end ." && log debug "--> make android end ."
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi
}

main
