#!/usr/bin/env bash

####################################### 公共变量 (全局变量)
gettop_p=
# teleweb path
teleweb_p=/mfs_tablet/teleweb
# git username
username='Integration.tablet'
# build path
BUILDDIR=${WORKSPACE}
# gerrit path
gerrit_p=${tmpfs}/gerrit

## manifest info
declare -A manifest_info
## module list
declare -A module_list

declare -A module_target

function gettop() {

    if [[ -n "${gettop_p}" ]]; then
        (cd ${gettop_p}; PWD= /bin/pwd)
    else
        log error "Don't get the gettop, please check it ..."
    fi
}

# 启用ccache缓存加速
function use_ccache() {

    export USE_CCACHE=1
    export CCACHE_DIR=~/.ccache
    export CCACHE_EXEC=/usr/bin/ccache
    export PATH=/usr/lib/ccache:$PATH

    if [[ -f /usr/bin/ccache ]] ; then
        /usr/bin/ccache -M 50G
        /usr/bin/ccache -s
    else
        log error 'The ccache no found!'
    fi
}

# 检查mirror服务器
function is_check_mirror() {

    local mirror_servre=(10.129.93.164 10.129.93.165 10.129.93.167 10.129.93.167)

    for mirror in ${mirror_servre[@]} ; do
        if [[ $(showmount -e ${mirror} 2> /dev/null) ]]; then
            continue
        else
            echo false && return 0
        fi
    done

    echo true
}

# 下载与更新Android源代码
function download_android_source_code()
{
    local manifest_git_p='.repo/manifests/.git'
    local reference_p='/home/android/mirror'

    if [[ -z "${build_manifest}" ]];then
        log error "The manifest branch name is null ..."
    fi

    if [[ "$(is_check_mirror)" == "false" ]]; then
        git --git-dir=${manifest_git_p} config --unset repo.reference
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        update_source_code
    else
        download_source_code
    fi

    # 生成manifest列表
    generate_manifest_list
}

## 更新源代码
function update_source_code()
{
    if [[ -f build/core/envsetup.mk && -f Makefile ]]; then

        if [[ "`is_android_project`" == "true" ]]; then
            recover_standard_android_project

            echo
            show_vip "--> 已恢复源代码至原始状态."
        else
            log error "未恢复源代码至原始状态 ..."
        fi

        ## 重新初始化，防止本地提交代码影响版本
        if [[ -n "${build_manifest}" ]];then
            if [[ "$(is_check_mirror)" == "true" ]]; then
                Command "repo init -m ${build_manifest} --reference=${reference_p}"
            else
                Command "repo init -m ${build_manifest}"
            fi
        fi

        ## 更新源代码
        repo_sync_for_code
    else
        download_source_code
    fi
}

## 下载源代码
function download_source_code()
{
    local manifest_project_p='gcs_sz/manifest.git'

    if [[ -n "${build_manifest}" ]];then

        # 1. 下载保证当前没有旧的.repo文件夹
        if [[ -d .repo ]]; then
            rm .repo/ -rf
        fi

        if [[ "$(is_check_mirror)" == "true" ]]; then
            Command "repo init -u ${default_gerrit}:${manifest_project_p} -m ${build_manifest} --reference=${reference_p}"
        else
            Command "repo init -u ${default_gerrit}:${manifest_project_p} -m ${build_manifest}"
        fi
    fi

    ## 更新源代码
    repo_sync_for_code

    ## 第一次下载完成后，需要初始化环境变量
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile && "`is_android_project`" == "true" ]];then
        if [[ "$(is_apk_prebuild)" == 'false' ]]; then
            source_init
        fi
    else
        log error "The (.repo) not found!"
    fi
}

function make_droid() {

    source_init
    Command "bash build.sh dist -j$(nproc)"
    if [[ $? -eq 0 ]];then
        echo
        show_vip "--> make project end ..."
    else
        log error "--> make android failed !"
    fi
}

function make_android()
{
    if [[ "${build_clean}" == "true" ]];then
        Command "make -j${JOBS} clean"
        if [[ $? -eq 0 ]];then
            echo
            show_vip "--> make clean end ..."
        else
            log error "--> make clean fail ..."
        fi
    else
        Command "make -j${JOBS} installclean"
        if [[ $? -eq 0 ]];then
            echo
            show_vip "--> make installclean end ..."
        else
            log error "--> make installclean fail ..."
        fi
    fi

    ## 编译android
    make_droid
}

function handle_tct_custom() {

    # 建立构建目标关系
    generate_module_target

    if [[ -d "out/target/common/jrdResAssetsCust/wimdata" ]];then
        rm -rf "out/target/common/jrdResAssetsCust/wimdata"
    fi

    if [[ -f vendor/tct/source/qcn/Android.mk ]]; then
        mv vendor/tct/source/qcn/Android.mk vendor/tct/source/qcn/Android.mk_bak
    fi
}