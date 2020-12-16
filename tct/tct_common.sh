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
# build list info
buildlist=${tmpfs}/buildlist.ini

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
    show_vip '[tct]: --> make dist ...'
    Command "bash build.sh dist -j$(nproc)"
    if [[ $? -eq 0 ]];then
        echo
        show_vip "--> make project end ..."
    else
        log error "--> make android failed !"
    fi
}

# 清除OUT目录
function outclean() {

    if [[ "${build_clean}" == "true" ]];then
        show_vip '[tct]: --> make clean ...'
        Command "make -j${JOBS} clean"
        if [[ $? -eq 0 ]];then
            echo
            show_vip "--> make clean end ..."
        else
            log error "--> make clean fail ..."
        fi
    else
        show_vip '[tct]: --> make installclean ...'
        Command "make -j${JOBS} installclean"
        if [[ $? -eq 0 ]];then
            echo
            show_vip "--> make installclean end ..."
        else
            log error "--> make installclean fail ..."
        fi
    fi
}

function make_android()
{
    # 清除编译
    outclean

    ## 编译android
    make_droid
}

function init_copy_image_for_qssi() {

    unset copyfs

    copyfs[${#copyfs[@]}]=system.img
    copyfs[${#copyfs[@]}]=product.img
    copyfs[${#copyfs[@]}]=system_ext.img
    copyfs[${#copyfs[@]}]=vbmeta_system.img
}

# backup qssi image
function imgbackup() {

    local DEST_PATH=${tmpfs}/jenkins
    local OUT='out/target/product/qssi'

    for i in `ls ${tmpfs}/jenkins` ; do
        if [[ -f ${tmpfs}/jenkins/${i} ]]; then
            rm -rvf ${tmpfs}/jenkins/${i}
         fi
    done

    init_copy_image_for_qssi
    enhance_copy_file ${OUT} ${DEST_PATH}

    if [[ -n "`ls out/dist/qssi*-target_files-*.zip`" ]]; then
        cp -vf out/dist/qssi*-target_files-*.zip ${DEST_PATH}
    fi
}

# 备份qssi image
function cpimage() {

    local SRC_PATH=${tmpfs}/jenkins
    local OUT=$(get_product_out)

    log debug "The OUT is ${OUT}"

    init_copy_image_for_qssi
    enhance_copy_file ${SRC_PATH} ${OUT}

    if [[ -n "`ls ${SRC_PATH}/qssi*-target_files-*.zip`" ]]; then
        cp -vf ${SRC_PATH}/qssi*-target_files-*.zip out/dist
    fi
}

function make_android_tct() {

    case ${object} in

        qssi)
            Command TCT_EFUSE=false ANTI_ROLLBACK=2 SIGN_SECIMAGE_USEKEY=portotmo ./build.sh dist -j32 --qssi_only
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> make qssi end ..."

                imgbackup
            else
                log error "--> make android qssi failed !"
            fi

            ;;

        target)
            Command TCT_EFUSE=false ANTI_ROLLBACK=2 SIGN_SECIMAGE_USEKEY=portotmo ./build.sh dist -j32 --target_only
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> make target end ..."
            else
                log error "--> make android target failed !"
            fi
            ;;

        merge)
            cpimage
            Command TCT_EFUSE=false ANTI_ROLLBACK=2 SIGN_SECIMAGE_USEKEY=portotmo bash build.sh dist -j32 --merge_only
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> make merge end ..."
            else
                log error "--> make android merge failed !"
            fi
            ;;

        modem)
            # 记录变量WORKSPACE
            local tmpworkspace=${WORKSPACE}

            pushd amss_nicobar_la2.0.1 > /dev/null

            # 置空WORKSPACE
            unset WORKSPACE

            Command TCT_EFUSE=false ANTI_ROLLBACK=2 bash linux_build.sh -s -a portotmo tmo
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> make moden end ..."
            else
                log error "--> make android moden failed !"
            fi

            popd > /dev/null

            export WORKSPACE=${tmpworkspace}
            ;;

        *)
            log debug 'no target build ...'
            ;;
    esac
}

function handle_tct_custom() {

    # 更新module-info.json
#    update_module_target

    # 建立构建目标关系
    generate_module_target
}

function wimdataclean() {

    if [[ -d "out/target/common/jrdResAssetsCust/wimdata" ]];then
        rm -rf "out/target/common/jrdResAssetsCust/wimdata"
    fi
}

# 过滤不进行编译的项目或分支
function filter() {

    case ${project_name} in
        sm7250-r0-seattletmo-dint) # seattletmo R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common_mtk)
                            echo true
                        ;;

                        *)
                            echo false
                        ;;
                    esac
                ;;

                *)
                    echo false
                ;;
            esac
        ;;

        sm6125-r0-portotmo-dint) # portotmo R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common_mtk)
                            echo true
                        ;;

                        *)
                            echo false
                        ;;
                    esac
                ;;

                *)
                    echo false
                ;;
            esac
        ;;

        mt6762-tf-r0-v1.1-dint) # Tokyo Lite TMO R
            case ${GERRIT_PROJECT} in
                genericapp/gcs_HiddenMenu)
                    case ${GERRIT_BRANCH} in
                        Gcs_HiddenMenu_Common)
                            echo true
                        ;;

                        *)
                            echo false
                        ;;
                    esac
                ;;

                *)
                    echo false
                ;;
            esac
            ;;

        *)
            echo false
        ;;
    esac
}
