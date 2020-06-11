#!/bin/bash

### 若某一个命令返回非零值就退出
set -e

#set java env
unset -v JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH
export LANGUAGE=en_US
export LC_ALL=en_US.UTF-8
export ANDROID_HOME=~/workspace/android-sdk-linux
export PATH=${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:$PATH

################################## args

### 1. build device
build_device=$1
### 2. build project name  e.g. : K86_H520
build_prj_name=$2
## project name for system k26 k86 k86A k86m k88
project_name=""
### custom version H520
custom_version=""
### 3. build file path e.g. : k86l_yunovo_zx
build_file=$3
### 4. xx
### 5.build version e.g. system version, S1.00 S1.00.00 S1.00.eng
build_version=""
### S1.00 S1.01 ...
first_version=""
second_version=""
### 6. build type e.g. : eng|user|userdebug
build_type=""
### 7. build update-api e.g. cmd make update-api
build_update_api=""
### 8. build update code e.g. is update source code
build_update_code=""
### 9. build clean e.g. : make clean bofore make
build_clean=""
### 10. build make OTA e.g. : is make OTA or not
build_make_ota=""
### 12. build branch e.g. : user test、master、develop branch
build_branch=""
### 13. build voice type e.g. : voice type TXZ AIOS
build_voice_type=""
### 14. build apps switch e.g. : is compile apps
build_apps_switch=""
### 15. lcm config
build_lcm_type=""
### 16. build logo
build_logo=""
### 17. build para
build_para=""
### 18. build debug
build_debug=""
### 19. build release type [ Daily/Debug/Release ]
build_release_type=""

##-------------------------------- Abandoned
### readme.txt
build_readme=""

####--------------------------------------- common variate

## 当前Shell文件名
shellfs=$0
## 是否为测试版本,测试版本默认编译OTA
is_test_version=

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

################################ commmon function

## 处理jenkins传过来的变量, 并检查其有效性.
function handle_vairable()
{
    local readme_file=${tmpfs}/readme.txt

    ## 1. build device
    build_device=`remove_space_for_vairable "$build_device"`

    if [[ "`is_build_device`" == "false" ]];then
        log error "The build_device error. please check it ."
    fi

    ## 2. build project name
    build_prj_name=`remove_space_for_vairable "$build_prj_name"`
    project_name=${build_prj_name%%_*}
    custom_version=${build_prj_name##*_}

    if [[ -z "$project_name" ||  -z "$custom_version" ]];then
        log error "The project_name or custom_version is null, please check it ."
    fi

    ## 3. build file
    build_file=`remove_space_for_vairable "$build_file"`

    if [[ "`echo ${build_file} | egrep /`" ]];then
        prefect_name=${build_file}
    else
        log error "The build_file has error, please check it ."
    fi

    ## 4. xxx

    ## 5. build version
    if [[ "$yunovo_version" ]];then
        yunovo_version=`remove_space_for_vairable "$yunovo_version"`

        if [[ -n "`echo ${yunovo_version} | sed -n '/^S/p'`" ]];then
            build_version=${yunovo_version}

            first_version=${build_version%%.*}
            second_version=${build_version#*.}

            if [[ -z "$first_version" || -z "$second_version" ]];then
                log error "The first_version or The second_version is null, please check it ."
            fi

            if [[ -n "`echo ${second_version} | sed -n '/\./p'`"  ]];then
                is_test_version=false
            else
                is_test_version=true
            fi
        else
            log error "The build_version has error, please check it ."
        fi
    else
        log error "The yunovo_version is null, please check it ."
    fi

    ## 6. build type
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

    ## 7. build update-api
    if [[ -n "$yunovo_update_api" ]];then
        build_update_api=${yunovo_update_api}
    else
        build_update_api=false
        yunovo_update_api=false
    fi

    ## 8. build update code
    if [[ "$yunovo_update_code" ]];then
        build_update_code=${yunovo_update_code}
    else
        build_update_code=true
        yunovo_update_code=true
    fi

    ## 9. build clean
    if [[ -n "$yunovo_clean" ]];then
        build_clean=${yunovo_clean}
    else
        build_clean=false
        yunovo_clean=false
    fi

    ## 10. build make ota
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

    ## 12. build branch
    if [[ "$yunovo_branch" ]];then
        if [[ "`is_yunovo_branch "$yunovo_branch"`" == "true" ]];then
            build_branch=${yunovo_branch}
        else
            log error "The yunovo_branch has error, please check it ."
        fi
    else
        build_branch=develop
        yunovo_branch=develop
    fi

    ## 13. build voice type
    if [[ "$yunovo_voice_type" ]];then
        build_voice_type=`remove_space_for_vairable "$yunovo_voice_type"`
        build_voice_type="YUNOVO_DROIDCAR_VOICE_TYPE=$build_voice_type"
        export ${build_voice_type}
    fi

    ## 14. build compile switch for app
    if [[ -n "$yunovo_apps_switch" ]];then
        build_apps_switch=`remove_space_for_vairable "$yunovo_apps_switch"`
        build_apps_switch="YUNOVO_APPS_COMPILE_SIWTCH=$build_apps_switch"
    else
        build_apps_switch="YUNOVO_APPS_COMPILE_SIWTCH=yes"
    fi
    export ${apps_switch}

    ## 15. build lcm config
    if [[ -n "$yunovo_lcm_type" ]];then
        build_lcm_type=`remove_space_for_vairable "$yunovo_lcm_type"`
        build_lcm_type="SPT_LCM_TYPE=$build_lcm_type"
    fi

    ## 16. build para
    if [[ -n "$yunovo_para" ]];then
        build_para=${yunovo_para}
    fi

    ## build debug
    if [[ -n "$yunovo_debug" ]];then
        if [[ "true" == ${yunovo_debug} ]] ;then
            build_debug=false
        else
            build_debug=true
        fi
    else
        build_debug=true
    fi

    ## build release type
    if [[ -n "$yunovo_release_type" ]];then
        build_release_type=`remove_space_for_vairable "$yunovo_release_type"`
    else
        build_release_type=Debug
    fi

    ############################################

    ## build readme.txt
    if [[ -n "$yunovo_readme" ]];then
        build_readme="$yunovo_readme"

        if [[ "$build_readme" ]];then
            echo -e "$build_prj_name ${build_version} 修改点:" > ${readme_file}
            echo >> ${readme_file}

            for r in ${yunovo_readme[@]}
            do
                echo -e "$r" >> "$readme_file"
            done
        fi
    else
        echo -e "$build_prj_name ${build_version} 修改点:" > ${readme_file}
        echo >> ${readme_file}

        build_readme="未填写，请与出版本的同学联系，并让其补全修改点."
        echo "$build_readme" >> ${readme_file}
    fi

    handle_common_para
    handle_compile_para
}

## 处理编译参数
function handle_compile_para()
{
    ## 获取音频功放等级
    get_audio_level

    if [[ -n "$system_version" ]];then
        # 1. 系统版本号FOTA
        compile_para[${#compile_para[@]}]=${fota_version}
    fi

    if [[ -n "$yunovo_prj_name" ]];then
        # 2. 项目名称
        compile_para[${#compile_para[@]}]=${yunovo_prj_name}
    fi

    if [[ "`is_main_branch`" == "true" ]];then

        if [[ -n "`echo ${audio_level} | grep level`" ]];then
            ## 3. 音频功放等级
            compile_para[${#compile_para[@]}]=${audio_level}
        fi

    elif [[ "`is_car_project`" == "true" ]];then

        if [[ -n "$build_voice_type" ]];then
            ## 3. 语音类型
            compile_para[${#compile_para[@]}]=${build_voice_type}
        fi

        if [[ -n "$build_apps_switch" ]];then
            ## 4. 应用切换
            compile_para[${#compile_para[@]}]=${build_apps_switch}
        fi

        if [[ -n "$build_lcm_type" ]];then
            ## 5. 屏驱动配置
            compile_para[${#compile_para[@]}]=${build_lcm_type}
        fi

        if [[ -n "$build_para" ]];then
            ## 6. 定制编译参数
            compile_para[${#compile_para[@]}]=${build_para}
        fi

        if [[ -n "$yov_system_version" ]];then
            ## 7. 定义新的版本号
            compile_para[${#compile_para[@]}]=${yov_fota_version}
        fi
    fi
}

function print_variable()
{
    echo "JOBS = $JOBS"
    echo '-----------------------------------------'
    echo "build_prj_name = $build_prj_name"
    echo "project_name   = $project_name"
    echo "custom_version = $custom_version"
    echo '-----------------------------------------'
    echo "prefect_name   = $prefect_name"
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
    echo "build_release_type= $build_release_type"
    echo '-----------------------------------------'
    echo "build_para        = $build_para"
    echo "build_debug       = $build_debug"
    echo "build_lcm_type    = $build_lcm_type"
    echo "build_voice_type  = $build_voice_type"
    echo "build_apps_switch = $build_apps_switch"
    echo "yunovo_prj_name   = $yunovo_prj_name"
    echo "audio_level       = $audio_level"
    echo '-----------------------------------------'
    echo "yunovo_clean      = $yunovo_clean"
    echo "yunovo_branch     = $yunovo_branch"
    echo "yunovo_update_api = $yunovo_update_api"
    echo "yunovo_voice_type = $yunovo_voice_type"
    echo "yunovo_apps_switch= $yunovo_apps_switch"
    echo '-----------------------------------------'
    echo "is_test_version = $is_test_version"
    echo "lunch_project   = $lunch_project"
    echo "fota_version    = $fota_version"
    echo "yov_fota_version= $yov_fota_version"
    echo '-----------------------------------------'
    echo "compile_para = ${compile_para[@]}"
    echo '-----------------------------------------'
    echo "\$1 = $1"
    echo "\$2 = $2"
    echo "\$3 = $3"
    echo "\$4 = $4"
    echo "\$5 = $5"
    echo "\$6 = $6"
    echo "\$# = $#"
    echo '-----------------------------------------'
    echo
}

function main()
{
    local startT=`date +'%Y-%m-%d %H:%M:%S'`

    if [[ "`is_yunovo_project`" == "true" ]];then

        if [[ "`is_car_project`" == "true" ]];then
            version_p=~/.jenkins_version_for_car
        else
            version_p=~/.jenkins_version_for_android
        fi

        if [[ ! -d ${version_p} ]];then
            mkdir -p ${version_p}
        fi

        if [[ ! -d ${tmpfs} ]];then
            mkdir ${tmpfs} -p
        fi
    else
        log error "The current directory has not found android Root ."
    fi

    if [[ "`is_yunovo_server`" == "true" ]];then
        echo
        show_vip "--> make android start ."
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi

    if [[ "$build_prj_name" && "$build_device" && "$build_file" ]];then
        handle_vairable
        print_variable ${build_prj_name} ${build_version} ${build_device} ${build_type} ${build_file}
    else
        log error "Xargs is valid? Please check it."
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile  ]];then

        if [[ "`is_check_lunch`" == "no lunch" ]];then
            source_init
        else
            print_env
        fi
    fi

    if [[ "$build_update_code" == "true" ]];then

        download_mirror

        ## 自动下载更新云智源代码
        auto_download_yunovo_source_code

        ## 自动下载更新云智APP
        if [[ "`is_car_project`" == "true" ]];then

            ##自动编译k10x 系统APP
            auto_build_system_app

            send_email_to_development

        else

            if [[ "`is_main_branch`" == "true" ]];then

                ##更新下载APP APK
                auto_checkout_branch
            else

                ## 自动更新客制化方案
                auto_update_yunovo_customs

                ##更新下载APP APK
                down_load_apk_for_yunovo
                down_load_app_for_yunovo
            fi

            copy_customs_to_droid
            send_email_to_development
            handle_boot_logo
            handle_driver_mk
        fi

    else
        __wrn "This time you don't update the source code."

        if ${build_debug};then
        if [[ "`is_car_project`" == "true" ]];then

            ##自动编译k10x 系统APP
            auto_build_system_app
        else
            copy_customs_to_droid
            send_email_to_development
            handle_boot_logo
            handle_driver_mk
        fi
        fi
    fi

    ## 编译系统源码
    make_yunovo_android

    if [[ "`is_yunovo_server`" == "true" ]];then

        print_make_completed_time

        echo
        show_vip "--> make android end ."

    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi
}

main
