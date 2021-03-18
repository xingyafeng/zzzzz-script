#!/usr/bin/env bash

####################################### 公共变量 (全局变量)
gettop_p=
# teleweb path
teleweb_p=/mfs_tablet/teleweb
# git username
username='Integration.tablet'
# build path
BUILDDIR=${WORKSPACE:-}
# gerrit path
gerrit_p=${tmpfs}/gerrit
# build list info
buildlist=${tmpfs}/buildlist.ini

# 源码更新
build_update_code='false'

# su enable
is_su_enable='no'

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

# 配置正确 manifest
function set_manifest_xml() {

    if [[ -n ${build_manifest} ]]; then
        if [[ ${build_manifest} =~ '.xml' ]]; then
            build_manifest=${build_manifest}
        else
            build_manifest=${build_manifest}.xml
        fi
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

function create_versioninfo(){
    #生成version.inc文件
    if [[ $(is_rom_prebuild) == 'false' ]]; then
        # 生成version info        
        #if [[ $(is_create_versioninfo) == 'true' ]]; then
        #    :
        if [[ ${VER_VARIANT} == "appli" ]] && [[ ${build_type} == "userdebug" ]]; then
            show_vip "no need to creat versioninfo and manifest"
        else
            show_vip "create version.inc start ..."
            tct::utils::create_version_info
            tct::utils::tct_check_version.inc
            show_vip "create version.inc end ..."
        fi
    fi
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
    #generate_manifest_list
    tct::utils::create_manifest
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

function tct::build_ap() {

    local para=

    case ${object} in

        ap)
            para=''
        ;;

        qssi)
            para='--qssi_only'
        ;;

        target)
            para='--target_only'
        ;;

        merge)
            para='--merge_only'
        ;;
    esac

    Command ${compile_para[@]} bash build.sh dist -j$(nproc) ${para}
    if [[ $? -eq 0 ]];then
        echo
        show_vip "--> make ${object} end ..."

#        imgbackup
    else
        log error "--> make android ${object} failed !"
    fi
}

function tct::build_cp() {

    # 记录变量WORKSPACE
    local tmpworkspace=${WORKSPACE}

    pushd amss_4350_spf1.0 > /dev/null

    # 置空WORKSPACE
    unset WORKSPACE

    Command bash linux_build.sh -a ${MODEMPROJECT} ${modem_type}
    if [[ $? -eq 0 ]];then
        echo
        show_vip "--> make moden end ..."
    else
        log error "--> make android moden failed !"
    fi

    popd > /dev/null

    export WORKSPACE=${tmpworkspace}
}

function make_droid() {

    if [[ $(is_rom_prebuild) == 'true' ]]; then
        source_init
        case ${JOB_NAME} in

            DelhiTF_Gerrit_Build|TransformerVZW_Gerrit_Build|Thor84gVZW-R_Gerrit_Build)
                show_vip '[tct]: --> make dist ...'
                Command ${compile_para[@]} bash build.sh dist -j$(nproc)
                ;;
            *)
                log warn 'no things build ...'
            ;;
        esac

        if [[ $? -eq 0 ]];then
            echo
            show_vip "--> make project end ..."
        else
            log error "--> make android failed !"
        fi
    else
        
        source_init
        case ${object} in
            
            ap|qssi|target|merge)
                tct::build_ap
                ;;

            cp|modem)
                tct::build_cp
                ;;

#            backup)
#                tct::utils::backup_image_version
#                ;;

            *)
                log debug 'no target build ...'
                ;;
        esac
    fi
}

# 清除OUT目录
function outclean() {

    local outdir=$(mktemp -d -p ${tmpfs})

    if [[ "${build_clean}" == "true" ]];then
        show_vip '[tct]: --> make clean ...'

        if [[ -d out/ ]]; then
            Command mv out ${outdir}
        fi

        if [[ -d ${outdir} ]]; then
            Command "rm -rf ${outdir} &"
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> make clean end ..."
            else
                log error "--> make clean fail ..."
            fi
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

#备份out目录
function outbackup()
{
    local appli_number=
    local build_number=
    local outdir_string=
    if [[ "${build_clean}" == "true" ]];then
        show_vip '[tct]: --> out backup ...'
        if [[ -f version/version.inc ]];then
            #当version.inc文件存在时，获取上一个版本的版本号
            appli_number=`awk '/ANDROID_SYS_VER/ {print substr($NF, 9,1)}' version/version.inc`
            if [[ ${appli_number} == 0 ]];then
                build_number=`awk '/ANDROID_SYS_VER/ {print substr($NF, 3,4)}' version/version.inc`
            else
                build_number=`awk '/ANDROID_SYS_VER/ {print substr($NF, 3,4)"-"substr($NF, 9,1)}' version/version.inc`
            fi
        else
            show_vip "--> version.inc is file does not exist ..."
        fi
        

        if [[ -n "${build_number}" ]]; then
            outdir_string="${build_number}_"`date +"%Y%m%d%H%M%S"`
            if [[ ! -d ${tmpfs}/${job_name}/${outdir_string} ]]; then
            
                Command "mkdir -p ${tmpfs}/${job_name}/${outdir_string}"
            fi
            Command "mv out ${tmpfs}/${job_name}/${outdir_string}"
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> out backup end ..."
            else
                log error "--> out bakcup fail ..."
            fi
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
    local OUT='out/target/product/qssi'

    init_copy_image_for_qssi

    if [[ $(is_thesame_server) == 'false' ]]; then
        rsync -e 'ssh -p8089' -av --delete android-bld@$(get_server_ip):${SRC_PATH}/ ${SRC_PATH}
    fi

    enhance_copy_file ${SRC_PATH} ${OUT}

    if [[ -n "`ls ${SRC_PATH}/qssi*-target_files-*.zip`" ]]; then
        cp -vf ${SRC_PATH}/qssi*-target_files-*.zip out/dist
    fi
}

function make_android_tct() {

    case ${object} in

        qssi)
            Command TCT_EFUSE=false ANTI_ROLLBACK=2 SIGN_SECIMAGE_USEKEY=portotmo bash build.sh dist -j$(nproc) --qssi_only
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> make qssi end ..."

                imgbackup
            else
                log error "--> make android qssi failed !"
            fi

            ;;

        target)
            Command TCT_EFUSE=false ANTI_ROLLBACK=2 SIGN_SECIMAGE_USEKEY=portotmo bash build.sh dist -j$(nproc) --target_only
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> make target end ..."
            else
                log error "--> make android target failed !"
            fi
            ;;

        merge)
            cpimage
            Command TCT_EFUSE=false ANTI_ROLLBACK=2 SIGN_SECIMAGE_USEKEY=portotmo bash build.sh dist -j$(nproc) --merge_only
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

# 映射ip
function get_server_ip() {

    case ${build_server_x} in

        s0|WS8SZ14-8089)
            echo '10.129.93.14'
        ;;

        s1|WS74930-8089)
            echo '10.129.93.30'
        ;;

        s2|WS73J31-8089)
            echo '10.129.93.31'
        ;;

        s3|WS92434-8089)
            echo '10.129.93.34'
        ;;

        s4|WS104)
            echo '10.129.93.104'
        ;;

        s5|WS105)
            echo '10.129.93.105'
        ;;

        s6|WS106)
            echo '10.129.93.106'
        ;;

        s7|WS107)
            echo '10.129.93.107'
        ;;

        s8|WS108)
            echo '10.129.93.108'
        ;;

        s9|WS109)
            echo '10.129.93.109'
        ;;

        s10|WS110)
            echo '10.129.93.110'
        ;;

        s11|WS111)
            echo '10.129.93.111'
        ;;
    esac
}

# 拿到perso号
function get_perso_num() {

    local mbn=${1-}

    echo ${mbn: -5:1}
}

#拷贝img到teleweb
function copyimgtoteleweb(){
    tct::utils::backup_image_version
}