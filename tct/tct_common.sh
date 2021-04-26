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
# 是否需要repo同步
is_repo_sync='true'

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

    local PojectName=`tr '[A-Z]' '[a-z]' <<<${PROJECTNAME}`

    if [[ -n ${build_manifest} ]]; then
        if [[ $(is_build_debug) == 'true' ]]; then
            build_manifest=int/${PojectName}/v${build_version}.xml
        else
            if [[ ${build_manifest} =~ '.xml' ]]; then
                build_manifest=${build_manifest}
            else
                build_manifest=${build_manifest}.xml
            fi
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
            is_repo_sync='false'
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

    is_enduser_apk

    show_vip "${compile_para[@]} bash build.sh dist -j$(nproc) ${para}"
    Command ${compile_para[@]} bash build.sh dist -j$(nproc) ${para} 2>&1 | tee build_ap.log
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

    if [ -d Mannar.LA.1.0.1/common/sectools/ext/six ]; then
        rm -rvf Mannar.LA.1.0.1/common/sectools/ext/six
    fi

    if [ -d RPM.BF.1.11/rpm_proc/tools/build/scons/sectools/ext/six ]; then
        rm -rvf RPM.BF.1.11/rpm_proc/tools/build/scons/sectools/ext/six
    fi

    show_vip "${compile_para[@]} bash linux_build.sh -a ${MODEMPROJECT} ${modem_type}"
    Command ${compile_para[@]} bash linux_build.sh -a ${MODEMPROJECT} ${modem_type} 2>&1 | tee build_cp.log
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

            DohaTMO-R_Gerrit_Build)
                if [[ "${build_clean}" == "true" ]];then
                    Command ./tclMake -o=${compile_para[@]} ${build_project} new
                else
                    Command ./tclMake -o=${compile_para[@]} ${build_project} remake
                fi
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

        case ${object} in

            ap|qssi|target|merge)
                tct::build_ap
            ;;

            cp|modem)
                tct::build_cp
            ;;

            mtk)
                tct::build_mtk
            ;;

            backup)
                tct::utils::backup_image_version

                if [[ $(is_build_debug) == 'true' || ${build_version:2:1} == "O" ]];then
                    echo "no need releasemail"
                else
                    echo "need releasemail"
                    tct::utils::releasemail
                fi
            ;;

            *)
                log debug 'no target build ...'
            ;;
        esac

        log debug "build ${object} ..."
    fi
}

# 清除OUT目录
function outclean() {

    local outdir='out_bak'

    if [[ "${build_clean}" == "true" ]];then

        show_vip '[tct]: --> make clean ...'

        if [[ $(is_rom_prebuild) == 'true' ]]; then
            dirclean out
        else
            if [[ -d ${outdir} ]]; then
                dirclean ${outdir}
            fi

            if [[ ! -d ${outdir} ]]; then
                Command mkdir -p ${outdir}
            fi

            if [[ -d out ]]; then
                Command mv out ${outdir}
            fi

            if [[ -d out_sys ]]; then
                Command mv out_sys ${outdir}
            fi
        fi
    else
        show_vip '[tct]: --> make installclean ...'
        source_init
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
    if [[ $(is_rom_prebuild) == 'true' ]]; then
        # 清除编译
        outclean
    fi

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

function tct::build_mtk(){

    Command "./tclMake -o=`echo ${compile_para[@]} | sed s/[[:space:]]//g` ${PROJECTNAME} new"
    if [[ $? -eq 0 ]];then
        echo
        show_vip "--> make mtk end ..."

    else
        log error "--> make android mtk failed !"
    fi
}

function is_appli_debug(){
    if [[ $(is_build_debug) == 'true' ]]; then
        show_vip "no need to creat manifest and version"
    else
        local versioninfo=$(tct::utils::get_version_info)
        local version_path=`basename ${versioninfo}`
        local perso_num=$(tct::utils::get_perso_num)
        local custo_name_platform=$(tct::utils::custo_name_platform)

        show_vip "creat manifest and version"
        tct::utils::create_versioninfo
        tct::utils::create_manifest

    fi

    if [[ ${VER_VARIANT} == "appli" ]] &&[[ "${build_userdebug}" == "true" ]]; then
        show_vip "build_userdebug ..."

        local debug_compile_para=$(tct::utils::handle_debug_compile_para)
        local debug_variable=`echo ${debug_compile_para%?} | sed s/[[:space:]]//g`
        tct::utils::build_userdebug
    fi
}

# 是否需要移除enduser.apk
function is_enduser_apk() {

    case ${JOB_NAME} in

        transformervzw)
            if [[ "${build_enduser}" == "true" ]];then
                show_vip "need usersupport apk..."
            else
                show_vip "no need usersupport apk, remove android.mk"
                Command "mv vendor/tct/apps/UserSupport/Android.mk vendor/tct/apps/UserSupport/Android.mk_bak"
            fi
        ;;

        *)
            :
        ;;
    esac

}

#判断是否更新gapp
function update_gapp() {
    local is_update_gapp=$(tct::utils::is_update_gapp)

    if [[ ${VER_VARIANT} == "daily" ]] && [[ "${is_update_gapp}" == "true" ]];then
        show_vip "update Gapp begin !"
        show_vip "${tmpfs}/tools_int/bin/AutoUpdateGApp/${PROJECTNAME}/DuliApp_sync.sh ${build_manifest%.*}"

        ${tmpfs}/tools_int/bin/AutoUpdateGApp/${PROJECTNAME}/DuliApp_sync.sh ${build_manifest%.*}
        local result=$?
        if [ "$result" != "0" ]; then
            log error "update Gapp error"
        fi
        show_vip "update Gapp end !"
    else
        show_vip "no need update gapp ..."
    fi

}