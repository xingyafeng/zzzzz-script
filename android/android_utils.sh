#!/usr/bin/env bash

### 打印系统环境变量
function print_env()
{
    echo "OUT    = ${OUT}"
    echo "ROOT   = $(gettop)"
    echo "DEVICE = ${DEVICE}"
    echo
}

## 编译android源码前,初始化环境变量
function source_init_yunovo()
{
    local DEVICE_P=""

    print-config

    ROOT=$(gettop)
    OUT=${OUT}
    DEVICE_PROJECT=`get_build_var TARGET_DEVICE`
    DEVICE=`get-device-path`
    print_env
}

function source_init()
{
    local DEVICE_P=""

    #print-config

    source build/envsetup.sh && show_vip "--> source end ..."

    if [[ $(is_rom_prebuild) == 'true' ]]; then

        resclean

        case ${job_name} in

            DelhiTF_Gerrit_Build)
                export SIGN_SECIMAGE_USEKEY=delhitf
                Command choosecombo 1 delhitf userdebug true 1 false true 2 && show_vip "--> lunch end ..."
            ;;

            TransformerVZW_Gerrit_Build)
                Command choosecombo 1 transformervzw userdebug transformervzw 1 false 0 0 && show_vip "--> lunch end ..."
            ;;

            Thor84gVZW-R_Gerrit_Build)
                Command choosecombo 1 thor84gvzw user thor84gvzw 1 false false && show_vip "--> lunch end ..."
            ;;

            DohaTMO-R_Gerrit_Build)
                Command choosecombo release full_Doha_TMO userdebug false 1 && show_vip "--> lunch end ..."
            ;;

            *)
                log error "The ${job_name} has no found ..."
            ;;
        esac
    else

        case ${job_name} in

            transformervzw)
                Command choosecombo 1 ${PROJECTNAME} ${build_type} ${PROJECTNAME} 1 $(is_mini_version) 0 ${build_anti_rollback} $(is_cert_version) && show_vip "--> lunch end ..."

                if [[ $(is_user_appli) == 'true' ]]; then
                    Command "choosesecimagekey ${PROJECTNAME} && choosesignapkkey ${PROJECTNAME}"
                else
                    unset SIGNAPK_USE_RELEASEKEY
                    Command choosesecimagekey transformervzw
                fi
            ;;

            dohatmo-r)
                show_vip "--> this is user build -->${VER_VARIANT} -- ${build_type}"

                if [[ $(is_user_appli) == 'true' ]]; then
                    Command "choosesecimagekey ${PROJECTNAME} && choosesignapkkey ${PROJECTNAME}"
                else
                    Command "choosesecimagekey ${PROJECTNAME}"
                fi
            ;;

            irvinevzw)
                Command choosecombo 1 ${PROJECTNAME} ${build_type} ${PROJECTNAME} 1 $(is_mini_version) 0 ${build_anti_rollback} $(is_cert_version) && show_vip "--> lunch end ..."
            ;;

            *)
                log error "The ${job_name} no found ..."
            ;;
        esac
    fi

    ROOT=$(gettop)
    OUT=${OUT}
    DEVICE_PROJECT=$(get_target_device)
    DEVICE=$(get-device-path)
    print_env
}

function source_init_tct()
{
    local DEVICE_P=""

    #print-config

    source build/envsetup.sh && show_vip "--> source end ..."
    choosecombo 1 portotmo userdebug portotmo 1 false false && show_vip "--> lunch end ..."

    ROOT=$(gettop)
    OUT=${OUT}
    DEVICE_PROJECT=`get_build_var TARGET_DEVICE`
    DEVICE=`get-device-path`
    print_env
}

## 更新文件时间轴
function update_all_type_file_time_stamp()
{
	local tttDir=$1
	if [[ -d "$tttDir" ]]; then
		find ${tttDir} -name "*" | xargs touch -c
		find ${tttDir} -name "*.*" | xargs touch -c
		echo "    TimeStamp $tttDir"
	fi
}

## 检查是否有lunch
function is_check_lunch()
{
    if [[ -n "${DEVICE}" ]];then
        echo "lunch path: ${DEVICE}"
    else
        echo "no lunch"
    fi
}

## check lunch type is ok ?
function check_build_variant() {

    case ${default_target_build_variant} in

        user|userdebug|eng)
            echo true
        ;;

        *)
            echo false
        ;;
    esac
}

## 删除编译的log信息
function delete_log()
{
	find . -maxdepth 1 -name "build*.log" -print0 | xargs -0 rm
}

## 输出编译使用时间,及结束时间
function print_make_completed_time()
{
    local endT=`date +'%Y-%m-%d %H:%M:%S'`
    local useT=
    local hh=
    local mm=
    local ss=

    useT=$(($(date +%s -d "$endT") - $(date +%s -d "$startT")))
    hh=$((useT / 3600))
    mm=$((useT - hh * 3600)) && mm=$((mm  / 60))
    ss=$((useT - hh * 3600 - mm * 60))

    __red__ "#### make completed successfully ($hh:$mm:$ss (hh:mm:ss)) ($endT) ###"
}

## 检查版本类型
function check_rom_type() {

    case ${build_rom_type} in
        Release|Debug)
            echo true
            ;;
        *)
            echo false
            ;;
    esac
}

## 获取商标名称
function get_brand_name()
{
    var=$(grep "ro.product.brand=" "$OUT/system/build.prop")
    brand_name=${var##"ro.product.brand="}
    brand_name=${brand_name/ /}

    echo ${brand_name}
}

## 获取cpu线程数
function get_cpu_cores()
{
    case "$JOBS" in

        56)
            JOBS=$((JOBS/2))
            ;;

        *)
            :
            ;;
    esac
}

# 获取版本路径
function get_version_path() {

    local ver=
    local rom_type=
    local filter="inc|fake|target_files-package.zip|otatools.zip"

    if [[ -n "$1" ]]; then
        ver=$1
    else
        echo ""
        echo "${FUNCNAME[0]} args1 [args2 ...]"
        echo
        echo "    args1 : 版本时间轴"
        echo "    args2 : 版本类型, 可选 [Debug|Release]"
        echo
        echo "    e.g."
        echo "        1. ${FUNCNAME[0]} V1.0.0_2019.09.03_11.18.30"
        echo "        2. ${FUNCNAME[0]} V1.0.0_2019.09.03_11.18.30 Debug"
        echo "        3. ${FUNCNAME[0]} V1.0.0_2019.09.03_11.18.30 Release"
        echo
        return 0
    fi

    if [[ -n "$2" ]]; then
        rom_type=$2
    fi

    ssh jenkins@${f1_server} find ${rom_p}/share_nxos/ROM/${rom_type} -name "*.zip" | egrep -w ${ver} | egrep -vE ${filter}  | egrep -v "sdupdate_.*.zip" | cut -d '/' -f -10
}

## 更新 mirror
function repo_sync_for_mirror()
{
    if repo sync;then
        echo
        show_vip "---- repo sync the mirror successful ..."
    else
        log error "---- repo sync the mirror failed ..."
    fi
}

## 更新 code
function repo_sync_for_code()
{
    ## 更新repo仓库
    time repo selfupdate

    if time repo sync -c -d --prune --no-tags --force-sync -j$(nproc);then
        echo
        show_vip "---- repo sync code successful ..."
    else
        log error "---- repo sync code failed ..."
    fi
}

## 下载mirror
function download_mirror()
{
    local OLDP=`pwd`
    local mirror_p=""

    if [[ -n "`get_cpu_type`" ]];then
        mirror_p=~/jobs/mirror/`get_cpu_type`
    else
        log error "Do not get cpu type ..."
    fi

    if [[ ! -d ${mirror_p} ]];then
        mkdir -p ${mirror_p}
    fi

    show_vig "mirror_p = $mirror_p"

    cd ${mirror_p} > /dev/null

    if [[ ! -d .repo && ! -d git-repo.git ]];then
        repo init -u ssh://${git_username}@${gerrit_server}:${gerrit_port}/manifest -m `get_cpu_type`.xml --mirror
        repo_sync_for_mirror
    else
        repo_sync_for_mirror
    fi

    cd ${OLDP} > /dev/null
}
