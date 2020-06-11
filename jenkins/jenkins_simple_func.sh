#!/usr/bin/env bash

## 定义数组变量
declare -a _inlist

## 选择正确的值,并赋值给它
function select_choice()
{
    _target_arg=$1
    _arg_list=(${_inlist[@]})
    _outc=""

    select _c in ${_arg_list[@]}
    do
        if [[ -n "$_c" ]]; then
            _outc=${_c}
            break
        else
            for _i in ${_arg_list[@]}
            do
                _t=`echo ${_i} | grep -E "^$REPLY"`
                if [[ -n "$_t" ]]; then
                    _outc=${_i}
                    break
                fi
            done

            if [[ -n "$_outc" ]]; then
                break
            fi
        fi
    done

    echo

    if [[ -n "$_outc" ]]; then
        eval "${_target_arg}=${_outc}"
        export ${_target_arg}=${_outc}
    fi
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

## 检查远程分支是否有冲突,即是否存在 (local out of date) 问题.
function check_remote_branch() {

    local tags="`git remote show origin | grep ${GITRES_BRANCH} | grep pushes | egrep -w 'local out of date'  | awk -F'(' '{print $NF}' | awk -F')' '{print $1}'`"

    if [[ "${tags}" == "local out of date" ]]; then
        echo true
    else
        echo false
    fi
}

## 检查邮件的合法性
function is_check_email() {

    local regex="^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+$"
    local email=""

    if [[ "$1" ]]; then
        email="$1"
    else
        log error "无效参数 e.g ${FUNCNAME[0]} xingyf@yunovo.cn"
    fi

    if [[ "${email}" =~ ${regex} ]]; then
        echo true
    else
        echo false
    fi
}

# 检查邮件的合法性
function validator {

    local regex="^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+$"
    local email=

    if [[ "$1" ]]; then
        email="$1"
    else
        log error "无效参数 e.g ${FUNCNAME[0]} xingyf@yunovo.cn"
    fi

    if [[ "${email}" =~ ${regex} ]]; then
        printf "* %-48s \e[1;32m[pass]\e[m\n" "${email}"
    else
        printf "* %-48s \e[1;31m[fail]\e[m\n" "${email}"
    fi
}

# 分割字符串
function splitstring() {

    local source=
    local separator=
    declare -a string

    if [[ "$1" ]]; then
        source="$1"
    else
        log debug "无效参数1 ..."
    fi

    if [[ "$2" ]]; then
        separator=$2
    else
        log debug "无效参数2 ..."
    fi

    if [[ "$#" -ne 2 ]]; then
        log error "无效参数 e.g ${FUNCNAME[0]} \"ab;cd;ef;\" \";\" ..."
    fi

    OIFS=$IFS
    IFS="${separator}"
    for s in ${source} ; do
        string[${#string[@]}]=${s}
    done
    IFS=${OIFS}

    echo ${string[@]}
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
    mm=$[ (useT - hh * 3600) / 60 ]
    ss=$[ (useT - hh * 3600 - mm * 60) ]

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

#####################################################
##
##  函数: enhance_mkdir_folder
##  功能: 增强创建文件
##
##  描述: 此函数都使用绝对路径,无需参数
##
####################################################
function enhance_create_dir() {

    for p in ${pathfs[@]} ; do
        if [[ ! -d ${p} ]];then
            mkdir -p ${p}
        fi
    done
}

#####################################################
##
##  函数: enhance_copy_file
##  功能: 增强备份系统文件
##  参数: 1 src: 原有路径
##        2 dst: 目的路径
##
##  描述: 此函数必须有两个参数,否则按照错误来处理.
##
####################################################
function enhance_copy_file() {

    local src dst

    case "$#" in

        2)
            src="$1"
            dst="$2"

            if [[ ! -d ${dst} ]]; then
                mkdir -p ${dst}
            fi
            ;;
        *)
            log error "The ${FUNCNAME[0]} function must be hava two args ..."
        ;;
    esac

    for file in ${copyfs[@]} ; do
        if [[ -f ${src}/${file} ]]; then
            cp -vf ${src}/${file} ${dst}
        else
            ## 优化,有些版本没有此文件,需要忽略. 斟酌处理掉
            case ${file} in

                custom.img)
                    log warn  "It is ${file} that has not found ..."
                    ;;

                acp)
                    log warn  "It is ${file} that has not found ..."
                    ;;

                *)
                    __err "It is ${file} that has not found ..."
                ;;
            esac
        fi
    done
}

## 获取商标名称
function get_brand_name()
{
    var=$(grep "ro.product.brand=" "$OUT/system/build.prop")
    brand_name=${var##"ro.product.brand="}
    brand_name=${brand_name/ /}

    echo ${brand_name}
}

## 获取服务器路径
function ssh-get-rom-p() {

    local git_username=jenkins
    local rom_list=("Debug" "Release" "All" )
    local server_p=
    local time_p=

    if [[ -n "$1" ]]; then
        time_p=$1
    else
        __err "参数1为空 ..."
    fi

    if [[ "$#" -ne 1 ]]; then
        echo ""
        echo "ssh-get-rom-p \$@"
        echo
        echo "    参数1 : V1.0.3_2019.05.17_11.12.21 , 可以在f1服务器找到唯一的时间轴."
        echo
        echo "    e.g. ssh-get-rom-p V1.0.3_2019.05.17_11.12.21 "
        echo

        return 1
    fi

    _inlist=(${rom_list[@]})
    show_vir "select custom name : "
    select_choice keyN

    #show_vip "--> key name : $keyN"

    case ${keyN} in

        Debug)
            server_p=${rom_p}/share_nxos/ROM/Debug
        ;;

        Release)
            server_p=${rom_p}/share_nxos/ROM/Release
        ;;

        *)
            server_p="${rom_p}/share_nxos/ROM/Debug ${rom_p}/share_nxos/ROM/Release"
        ;;
    esac

    if [[ -n "${server_p}" && -n "${time_p}" ]]; then
        ssh ${git_username}@${f1_server} find ${server_p} -name ${time_p}
    fi
}

## 获取smb共享路径
function get_smb_share_path()
{
    local verN=""
    local share_path=""
    local serverN='\\f1.y'

    if [[ "$is_test_version" == "true" ]];then
        share_path=share_test
    else
        share_path=share_develop
    fi

    if [[ "`is_zen_project`" == "true" ]]; then
        share_path=share_nxos/ROM/${build_release_type}
    else
        if [[ "`is_root_project`" == "true" ]];then
            if [[ "$is_test_version" == "true" ]];then
                share_path=${share_path}/test_root
            else
                share_path=${share_path}/develop_root
            fi
        else
            if [[ "$is_test_version" == "true" ]];then
                share_path=${share_path}/test
            else
                share_path=${share_path}/develop
            fi
        fi
    fi

    if [[ "`is_root_project`" == "true"  ]];then
        verN=${first_version}.${second_version}
    else
        verN=${first_version}.${second_version}.${time_for_version}
    fi

    ## 共享路径
    if [[ "`is_zen_project`" == "true" ]]; then
        share_smb_p=${serverN}/${share_path}/`echo ${project_name} | tr 'a-z' 'A-Z'`/${custom_version}/${verN}
    else
        share_smb_p=${serverN}/${share_path}/${project_name}/${project_name}\_${custom_version}/${verN}
    fi

    ## replace '/' to '\'
    share_smb_p=`echo ${share_smb_p} | sed 's#\/#\\\#g'`
}

## 获取cpu线程数
function get_cpu_cores()
{
    case "$JOBS" in

        56)
            JOBS=$[JOBS/2]
            ;;

        *)
            :
            ;;
    esac
}

## 支持custom分区参数配置
function get_custom_config()
{
    case `get_project_real_name` in
        k68c_hs_c1debug)
            MTK_CIP_SUPPORT=yes
            ;;
    esac
}

## 支持tp参数配置
function get_tp_config()
{
    case `get_project_real_name` in
        k26_master|k26s_master|k27_master|k28s_master)
            :
            ;;
        k88c_master|k89_master)
            :
            ;;
        mx1_master)
            SPT_TP_TYPE=alibaba_gt911
            ;;
    esac
}

## 支持lcm参数配置
function get_lcm_config()
{
    case `get_project_real_name` in

        k21_s9_zxlmt)
            SPT_LCM_TYPE=use_935_lcm
            ;;

        k26_master|k26s_master|k27_master|k28s_master)
            :
            ;;

        k88c_master|mx1_master)
            :
            ;;

        k89_master)
            SPT_LCM_TYPE=use_hp686lcm0305
            ;;

        k68c_cta)
            SPT_LCM_TYPE=use_686_lcm
            ;;

        *)
            :
            ;;
    esac
}

## 支持v2.2主板参数配置
function get_hardware_v2.2()
{
    case `get_project_real_name` in
        k21_s9_zxlmt)
            YUNOVO_HARDWARE_VERSION=k26s_hardware_2.2
            ;;
        *)
            :
            ;;
    esac
}

## 支持mode参数配置
function get_custom_mode()
{
    case `get_project_real_name` in
        k68d_master)
            CUSTOM_MODEM="aeon6737m_65_m0_lwg_dsds aeon6737m_65_m0_ltg_dsds"
            ;;
        k88c_dhxl_xl-d40)
            CUSTOM_MODEM="aeon6735_65c_l1_lttg_dsds_cmcc_airoha_pa aeon6735_65c_l1_lwg_dsds_cmcc_airoha_pa"
            ;;
        *)
            :
            ;;
    esac
}

## 支持lk下的lcm参数配置
function get_custom_lk_lcm()
{
    case `get_project_real_name` in

        k88c_dhxl_xl-d40)
            CUSTOM_LK_LCM="st7701_hd480_dsi_vdo gc9503v_hd480_dsi_vdo"
            ;;
        *)
            :
            ;;
    esac
}

## 配置音频等级
# k26/master    4
# k26s/master   2
# k27/master    4
# k28s/master   no
# k88c/master   no
# k89/master    no
# mx1/master    no
# k26/vst/gps   3
# k27/vst/gps   4

## 获取音频功放等级
function get_audio_level()
{
    case ${build_prj_name} in

        k26s_MB-M30|k26e_QC-X18|k26s_QC-YX88|k26s_ZX-T6|k26s_LJ-D800|k26s_LJ-D880|k26s_DWT-T02|k26s_KKXL-K8|k26s_JM-CRF02|k21_s9_zxlmt)
            LEV=3
            ;;

       　k26s_VST-H8)
            LEV=4
            ;;

        *)
            case `get_project_real_name` in

                k20_master|k21_master|k26s_master)
                    LEV=2
                    ;;

                k26_master|k27_master)
                    LEV=4
                    ;;
                *)
                    :
                    ;;
            esac
            ;;
    esac

    set_audio_level
}

## 配置项目音频功放等级
function set_audio_level()
{
    local varN=YUNOVO_SPEAKER_LEVEL

    local levL1=level_one
    local levL2=level_two
    local levL3=level_three
    local levL4=level_four

    case ${LEV} in

        1)
            audio_level="${varN}=${levL1}"
            ;;

        2)
            audio_level="${varN}=${levL2}"
            ;;

        3)
            audio_level="${varN}=${levL3}"
            ;;

        4)
            audio_level="${varN}=${levL4}"
            ;;

        *)
            :
            ;;
    esac
}

## 获取文件类型
function get_file_type() {

    local file=

    if [[ $# -eq 1 ]]; then
        file=$1
    else
        echo ""
        echo "${FUNCNAME[0]} [args1] ..."
        echo
        echo "    args1 : 文件名称，可以包含路径。 [ 注: 必须带后缀 如: .txt .log etc ]"
        echo
        echo "    e.g."
        echo "        1. ${FUNCNAME[0]} yunovohelp.sh"
        echo "        2. ${FUNCNAME[0]} script/zzzzz-script/yunovo/yunovohelp.sh"
        echo
        return 0
    fi

    if [[ -n "${file}" && "${file}" =~ '.' ]]; then
        basename ${file} | awk -F. '{ print $NF }'
    else
        __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
    fi
}

## 获取文件名
function get_file_name() {

    local file=

    if [[ "$#" -eq 1 ]]; then
        file="$1"
    else
        echo ""
        echo "${FUNCNAME[0]} [args1] ..."
        echo
        echo "    args1 : 文件名称，可以包含路径。 [ 注: 必须带后缀 如: .txt .log etc ]"
        echo
        echo "    e.g."
        echo "        1. ${FUNCNAME[0]} yunovohelp.sh"
        echo "        2. ${FUNCNAME[0]} script/zzzzz-script/yunovo/yunovohelp.sh"
        echo
        return 0
    fi

    if [[ -n "${file}" && "${file}" =~ '.' ]]; then
        basename ${file} | sed s/`get_file_type ${file}`// | sed "s/.$//"
    else
        __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
    fi
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

## 钉钉通知
function dingding_robot_send_message() {

    local type=$1
    local robot=""
    local file_type=""

    local url=""

    # 机器人类型
    case ${type} in

        # 听风小分队 #用户吐槽信息通知
        1)
            robot="https://oapi.dingtalk.com/robot/send?access_token=9d36ccaf568faed3ba2dd3f0b5cdba1863c6fa567422ea36d0f3bf35eb8bd18e"
            ;;

        2)
            robot="https://oapi.dingtalk.com/robot/send?access_token=97b8ddbac6cbb5441084c3bf35d74577f0727e3593a7eb934d5643bd1baa8e7d"
            ;;

        *)
            robot="https://oapi.dingtalk.com/robot/send?access_token=79af021bdb51cd6ac596a572b4b6dee75ce52ae67ac6b9f204a7a3920a5ce3bc"
            ;;
    esac

    # 文件类型
    if [[ -n "$2" ]]; then
        file_type=$2
    fi

    # 发送消息
    if [[ -n "$3" ]]; then
        url=$3
    fi

    if [[ "$#" -ne 3 ]]; then
        log error "参数不正确 ..."
    fi

    case ${file_type} in

        txt)
            ## link
            curl "${robot}" -H 'Content-Type: application/json' -d "
            { \"msgtype\": \"text\",
                \"text\": {
                    \"content\": \"${url}\"
                }
            }"
            ;;

        3gp)
            ## link
            curl "${robot}" -H 'Content-Type: application/json' -d "
            {
                \"msgtype\": \"link\",
                \"link\": {
                    \"text\":\"${content}\",
                    \"title\": \"${title}\",
                    \"picUrl\": \"\",
                    \"messageUrl\": \"${url}\"
                }
            }"
            ;;
    esac

    #sleep 2
}

#################
# 函数： send_message
# 参数：
#   1. text类型     -- 发送文字消息
#   2. link类型     -- 发送链接  , url必须存存在,否则不运行发送.
#   3. markdown类型 -- 发送文字消息
#
################
function send_message() {

    case ${T} in

        test)
            curl "${robot}" -H 'Content-Type: application/json' -d "
            {
                \"msgtype\": \"text\",
                \"text\": {
                    \"content\": \"${content}\"
                },
                \"at\": {
                    \"atMobiles\": [
                        \"${phone}\"
                    ],
                    \"isAtAll\": false
                }
            }"
            ;;

        link)
            curl "${robot}" -H 'Content-Type: application/json' -d "
            {
                \"msgtype\": \"link\",
                \"link\": {
                    \"title\": \"${title}\",
                    \"text\":\"${content}\",
                    \"picUrl\": \"\",
                    \"messageUrl\": \"${url}\"
                },
                \"at\": {
                    \"atMobiles\": [
                        \"${phone}\"
                    ],
                    \"isAtAll\": false
                }
            }"
            ;;

        markdown)
            curl "${robot}" -H 'Content-Type: application/json' -d "
            {
                \"msgtype\": \"markdown\",
                \"markdown\": {
                 \"title\":\"${title}\",
                 \"text\": \"${content}\"
                },
                \"at\": {
                    \"atMobiles\": [
                        \"${phone}\"
                    ],
                    \"isAtAll\": false
                }
            }"
            ;;

        *)
            log error "未知的类型 ..."
        ;;
    esac
}

## 打印基础变量
function __print()
{
    unset print_var_list
    print_var_list[${#print_var_list[@]}]=preinstall_apk_name
    print_var_list[${#print_var_list[@]}]=preinstall_apk_package_name
    print_var_list[${#print_var_list[@]}]=preinstall_apk_version_code
    print_var_list[${#print_var_list[@]}]=preinstall_apk_version_name
    print_var_list[${#print_var_list[@]}]=preinstall_apk_channel_name
    print_var_list[${#print_var_list[@]}]=installed_apk_version_name
    print_var_list[${#print_var_list[@]}]=installed_apk_version_code

    echo "----------------------------- lenths = ${#print_var_list[@]}"
    for v in ${print_var_list[@]}
    do
        eval "echo ${v} = \$${v}"
    done
    echo "-----------------------------"
}

## 获取APK的基本信息
function get_apk_info()
{
	if [[ -n "${apk_path}" ]];then
		aapt dump badging ${apk_path}
	fi
}

## 从应用apk中获取信息:packageName versionCode versionName
function get_info_from_apk()
{
    local apk_path=
    local key=

    if [[ "$1" ]]; then
	    apk_path=$1
    else
        log error "The args1 is error !"
    fi

    if [[ "$2" ]]; then
	    key=$2
    else
        log error "args2 is error !"
    fi

    case ${key} in
        package)
            get_apk_info ${apk_path} | grep ${key} | awk '{ print $2 }' | awk -F "'" '{ print $2 }'
        ;;

        versionCode)
            get_apk_info ${apk_path} | grep ${key} | awk '{ print $3 }' | awk -F "'" '{ print $2 }'
        ;;

        versionName)
            get_apk_info ${apk_path} | grep ${key} | awk '{ print $4 }' | awk -F "'" '{ print $2 }'
        ;;

        channel_mode)
            if [[ "${key}" == "channel_mode" ]]; then
                key=versionName
            fi

            get_apk_info ${apk_path} | grep ${key} | awk '{ print $4 }' | awk -F "'" '{ print $2 }' | cut -d '_' -f 2
        ;;
    esac
}

## 从真机中获取信息: versionCode versionName
function get_info_from_the_machine()
{
    local package_name=
    local key=

    if [[ "$1" ]]; then
	    package_name=$1
    else
        log error "The args1 is error !"
    fi

    if [[ "$2" ]]; then
	    key=$2
    else
        log error "The args2 is error !"
    fi

    case ${key} in
        versionCode)
            adb shell dumpsys package ${package_name} | grep ${key} | awk '{ print $1} ' | awk -F "=" '{print $2}'
            ;;

        versionName)
            adb shell dumpsys package ${package_name} | grep ${key} | awk -F "=" '{print $2}'
            ;;
    esac
}

## 拿到安装应用的被依赖应用的版本,名称,及SDK信息
## e.g : nxSettingsProvider=cn.yunovo.config_1.0.1_s1
## depends_info_from_apk
## e.g : #depends_info_from_apk=([cn.yunovo.config]='s1' [package_name]='sdk_version')
function get_depends_apk_info()
{
    local value=
    local apk_path="$preinstall_apk_path/$preinstall_apk_name"

    while read line;do
        value=${line##*=}
        depends_apk_list[${value%%_*}]=${line%=*}
        depends_info_from_apk[${value%%_*}]=${value##*_}
    done < <(unzip -p -l "${apk_path}" assets/dependon.cfg)

    __green__ "---- depend on apk ----"

    __yellow__ "apk list:"
    for i in ${!depends_apk_list[@]}
    do
        echo "$i - ${depends_apk_list[$i]}"
    done
    show_vip "---- end."

    __yellow__ "apk sdk version:"
    for i in ${!depends_info_from_apk[@]}
    do
        echo "${i} - ${depends_info_from_apk[$i]}"
    done
    show_vip "---- end."
    #echo "depends_apk_list      : ${depends_apk_list[@]}"
    #echo "depends_info_from_apk : ${depends_info_from_apk[@]}"
}

function get_depends_apk_info_from_the_machine()
{
    local value=

    for d in ${!depends_info_from_apk[@]}
    do
        #echo "---d list : $d"
        if [[ "$d" ]]; then
            value="`adb shell dumpsys package "$d" | grep versionName | sed -n '1p'`" && value=${value##*=} && value=${value%_*}
            #echo "vaule = $value"

            ## 拿到sdk版本号
            if [[ "$value" ]]; then
                depends_info_from_the_machine[${d}]=${value##*_}
            fi

            ## 拿到被依赖应用的渠道号
            if [[ `echo ${value} |grep -o _ | wc -l` -gt 2 ]]; then
                depends_channel_mode_from_the_machine[${d}]="`echo ${value} | cut -d '_' -f 2`"
            else
                depends_channel_mode_from_the_machine[${d}]=""
            fi
        fi
    done

    __green__ "---- the_machine ----"
    __yellow__ "apk sdk version:"
    for i in ${!depends_info_from_the_machine[@]}
    do
        echo "$i - ${depends_info_from_the_machine[$i]}"
    done
    __yellow__ "apk channel mode:"
    for i in ${!depends_channel_mode_from_the_machine[@]}
    do
        echo "$i - ${depends_channel_mode_from_the_machine[$i]}"
    done
    show_vip "---- end."
    #echo "depends_info_from_the_machine         = ${depends_info_from_the_machine[@]}"
    #echo "depends_channel_mode_from_the_machine = ${depends_channel_mode_from_the_machine[@]}"
}

function get_depends_apk_info_from_the_server()
{
    local server_f1=/public/share/ROM/share_test/NXOS
    local new_depends_apk_name=""

    ## 1. 据什么条件判断是最新的?
    if [[ -n "$depends_channel_mode_from_the_machine" ]]; then
        new_depends_apk_name="`ssh -tt -p 22 ${git_username}@f1.y "ls ${server_f1}/${depends_apk_name}/${depends_apk_name}_*_${depends_channel_mode_from_the_machine}_*.apk | awk 'END {print}'"`"
    else
        new_depends_apk_name="`ssh -tt -p 22 ${git_username}@f1.y "ls ${server_f1}/${depends_apk_name}/${depends_apk_name}_*.apk | awk 'END {print}'"`"
    fi

    new_depends_apk_name="${new_depends_apk_name//[$'\t\r\n ']}"


    ## 2. 下载最新的
    if [[ -n "${new_depends_apk_name}" ]]; then
        scp -r ${git_username}@f1.y:${new_depends_apk_name} ${f1_nxos_p}
    fi

    ## 3. 从服务器上检索到,则表示匹配成功,否则定为失败.
    if [[ -n "${new_depends_apk_name##*/}" ]]; then
        depends_apk_install_list[${j}]=${new_depends_apk_name##*/}
        checking_apk_depends_on_from_the_server[${j}]=true
    else
        checking_apk_depends_on_from_the_server[${j}]=false
    fi

    echo "new_dependon_apk_name     = ${new_depends_apk_name}"
    __green__ "---- the_server ----"
    __yellow__ "apk list:"
    for i in ${!checking_apk_depends_on_from_the_server[@]}
    do
        echo "$i - ${checking_apk_depends_on_from_the_server[$i]}"
    done
    show_vip "---- end."
    __yellow__ "new dependon apk list:"
    for i in ${!depends_apk_install_list[@]}
    do
        echo "$i - ${depends_apk_install_list[$i]}"
    done
    show_vip "---- end."
}

## 检查依赖关系
function checking_depends_on()
{
    local depends_apk_name=""

    local sdk_version_from_apk=
    local sdk_version_from_the_machine=

    ## 拿到依赖应用信息
    get_depends_apk_info

    ## 拿到机器中依赖应用信息
    get_depends_apk_info_from_the_machine

    ## 若机器中找不到依赖的应用,则报错处理;若机器中存且依赖的应用格个数大于0表示找到被依赖的应用
    if [[ ${#depends_info_from_the_machine[*]} -gt 0 ]]; then

        ## 检查被依赖的应用与机器安装的被依赖应用是否匹配
        ## 若依赖关系正确则checking_apk_depends_on=true,否则checking_apk_depends_on=false
        for i in ${!depends_info_from_apk[@]}
        do
            for j in ${!depends_info_from_the_machine[@]}
            do
                if [[ ${i} == ${j} ]];then
                    echo "start : $i == $j ${depends_info_from_apk[$i]} --- ${depends_info_from_the_machine[$j]} "

                    sdk_version_from_apk=${depends_info_from_apk[$i]}
                    sdk_version_from_the_machine=${depends_info_from_the_machine[$j]}

                    sdk_version_from_apk=${sdk_version_from_apk:1}
                    sdk_version_from_the_machine=${sdk_version_from_the_machine:1}

                    sdk_version_from_apk="${sdk_version_from_apk//[$'\t\r\n ']}"
                    sdk_version_from_the_machine="${sdk_version_from_the_machine//[$'\t\r\n ']}"

                    if [[ "$sdk_version_from_apk" -le "$sdk_version_from_the_machine" ]];then
                        checking_apk_depends_on_from_the_machine[${j}]=true
                    else
                        checking_apk_depends_on_from_the_machine[${j}]=false
                        if false;then
                        for l in ${!depends_apk_list[@]}
                        do
                            if [[ ${j} == ${l} ]];then
                                depends_apk_name=${depends_apk_list[$l]}

                                ## 拿到服务器最新的被依赖应用
                                get_depends_apk_info_from_the_server
                            fi
                        done
                        fi
                    fi
                fi
            done
        done

        ## 遍历被依赖应用的关系. 当检查到一个false,表示依赖不正确, 当且仅当都为true表示被依赖关系正确.
        for k in ${!checking_apk_depends_on_from_the_machine[@]}
        do
            if [[ "false" == "checking_apk_depends_on_from_the_machine[${k}]" ]]; then
                is_the_correct_deploy=false
                return 0
            fi
        done

        if false;then
        ## 遍历被依赖应用的关系. 当检查到一个false,表示依赖不正确, 当且仅当都为true表示被依赖关系正确.
        for k in ${!checking_apk_depends_on_from_the_server[@]}
        do
            if [[ "false" == "checking_apk_depends_on_from_the_server[${k}]" ]]; then
                is_the_correct_deploy=false
                return 0
            fi
        done
        fi

        is_the_correct_deploy=true
    else
        is_the_correct_deploy=false
    fi
    __err "checking depends_on - $is_the_correct_deploy"

    __green__ "checking_apk_depends_on_from_the_machine :"
    for i in ${!checking_apk_depends_on_from_the_machine[@]}
    do
        echo "checking_apk_depends_on_from_the_machine : $i - ${checking_apk_depends_on_from_the_machine[$i]}"
    done
    show_vip "---- end."

    if false;then
    __green__ "checking_apk_depends_on_from_the_server :"
    for i in ${!checking_apk_depends_on_from_the_server[@]}
    do
        echo " $i - ${checking_apk_depends_on_from_the_server[$i]}"
    done
    show_vip "---- end."
    fi
}

function auto_deploy()
{
    local ret=$1

    ## 预安装应用的路径
    local preinstall_apk_path=${ret%/*}
    ## 预安装应用的名称
    local preinstall_apk_name=${ret##*/}
    ## 预安装应用的包名
    local preinstall_apk_package_name=
    ## 预安装应用versionCode
    local preinstall_apk_version_code=
    ## 预安装应用的版本号
    local preinstall_apk_version_name=
    ## 预安装应用的渠道号
    local preinstall_apk_channel_name=

    ## 已安装到机器中的版本号
    local installed_apk_version_name=
    ## 已安装到机器中的versioncode
    local installed_apk_version_code=

    ## 拿到预安装应用的版本号和包名  版本号栗子: 1.0.19_mk21_5_s1
    preinstall_apk_version_name="`get_info_from_apk "${preinstall_apk_path}/${preinstall_apk_name}" versionName`"
    preinstall_apk_version_code="`get_info_from_apk "${preinstall_apk_path}/${preinstall_apk_name}" versionCode`"
    preinstall_apk_package_name="`get_info_from_apk "${preinstall_apk_path}/${preinstall_apk_name}" package`"
    preinstall_apk_channel_name="`get_info_from_apk "${preinstall_apk_path}/${preinstall_apk_name}" channel_mode`"

    ## 拿到机器中的应用版本号
    installed_apk_version_name=`get_info_from_the_machine ${preinstall_apk_package_name} versionName | awk -F "_" '{ print $1 }'`
    installed_apk_version_code=`get_info_from_the_machine ${preinstall_apk_package_name} versionCode | awk -F "_" '{ print $1 }'`

    echo
    show_vip "--> start auto deploy ."

    ## 输出关键信息
    __print

    ## 检查依赖关系
    checking_depends_on

    ## 当依赖关系正确
    if [[ "true" == "${is_the_correct_deploy}" ]]; then

        if false;then ## 依赖关系正确无需安装依赖的应用.

        # 1. 安装被依赖的应用
        for c in ${checking_apk_depends_on_from_the_server[@]}
        do
            for d in ${depends_apk_install_list[@]}
            do
                if [[ "true" == "${checking_apk_depends_on_from_the_server[$c]}" ]]; then
                    if [[ ${c} == ${d} ]]; then
                        __green__ "install depends apk list :: ${depends_apk_install_list[$d]}"
                        echo "install ok ==> $?"
                    fi
                fi
            done
        done
        fi

        # 2. 安装预安装应用
        echo "${is_the_correct_deploy} || preinstall apk :: ${preinstall_apk_path}/${preinstall_apk_name}"

        # 检查设备是否在线
        if [[ "false" == "`check_device_on_line`" ]]; then
            auto_connect_device
        fi

        adb -s ${device_ip} install -r "${preinstall_apk_path}/${preinstall_apk_name}"
    else ## 当依赖关系不正确

        ## 1. 机器中安装的依赖应用不正确
        for f in ${!checking_apk_depends_on_from_the_machine[@]}
        do
            if [[ "false" == "checking_apk_depends_on_from_the_machine[${f}]" ]]; then
                checking_apk_depends_on_err[${#checking_apk_depends_on_err[@]}]=${f}
            fi
        done

        if false;then
        ## 2. 服务器上依赖应用不正确
        for f in ${!checking_apk_depends_on_from_the_server[@]}
        do
            if [[ "false" == "checking_apk_depends_on_from_the_server[${f}]" ]]; then
                checking_apk_depends_on_err[${#checking_apk_depends_on_err[@]}]=${f}
            fi
        done
        fi

        ## 增加邮件内容, 1. 不正确的被依赖应用名称 2. 正确的SDK版本
        echo "${is_the_correct_deploy} || checking_apk_depends_on_err :: ${checking_apk_depends_on[@]}"
    fi

    if [[ "false" == "${is_the_correct_deploy}" ]]; then
        __return__ 2
    fi

    echo
    show_vip "--> auto deploy end ."
}

## 检查设备是否在线
function check_device_on_line()
{
    if [[ -z "${device_ip}" ]]; then
        log error "设备未找到 ..."
    fi

    if [[ -n "`adb devices -l | grep ^${device_ip}`" ]]; then
        echo true
    else
        echo false
    fi
}

## 自动连接设备
function auto_connect_device()
{
    adb kill-server
    adb connect ${device_ip}
}

## 创建json文件
function touch_json()
{
    local json=${tmpfs}/report.json
    local DEST_PATH="${nxos_path}/${BUILD_DISPLAY_NAME}"

    if [[ ! -d ${DEST_PATH} ]]; then
        mkdir -p ${DEST_PATH}
    fi

    printf "{\n" > ${json}
    printf '\t"report":[\n' >> ${json}
    printf '\t\t{\n' >> ${json}

    if [[ ${#test_report[@]} -ne 0 ]]; then
        for ((i=0; i<${#test_report[@]}; i++))
        do
            if [[ ${i} == $[${#test_report[@]}-1] ]]; then
                printf "\t\t\t`echo "${test_report[$i]}" | sed 's/|//g' | sed 's/^;//' | sed -r 's/^(.*);(.*);(.*);(.*);(.*);(.*);(.*)$/"commit_id":"\1","channel":"\2","rom":"\3","version":"\4","result":"\5","md5":"\6"/'`\n\t\t}\n" >> ${json}
            else
                printf "\t\t\t`echo "${test_report[$i]}" | sed 's/|//g' | sed 's/^;//' | sed -r 's/^(.*);(.*);(.*);(.*);(.*);(.*);(.*)$/"commit_id":"\1","channel":"\2","rom":"\3","version":"\4","result":"\5","md5":"\6",/'`\n" >> ${json}
            fi
        done
    else
        printf "\t\t}\n" >> ${json}
    fi

    printf "\t]\n" >> ${json}
    printf "}\n" >> ${json}

    ## 备份测试报告文件 report.json
    if [[ -f ${json} ]]; then
        cp -vf ${json} ${DEST_PATH}
    else
        log error "未找到生成测试报告文件 ..."
    fi
}

## 创建rom info json文件
function touch_rom_json()
{
    local json=${tmpfs}/rom.json
    local DEST_PATH=${rom_path}/${job_name}/${BUILD_DISPLAY_NAME}

    if [[ ! -d ${DEST_PATH} ]]; then
        mkdir -p ${DEST_PATH}
    fi

    printf "{\n" > ${json}
    printf '\t"rom":[\n' >> ${json}
    printf '\t\t{\n' >> ${json}

    if [[ ${#rom_info[@]} -ne 0 ]]; then
        for ((i=0; i<${#rom_info[@]}; i++))
        do
            if [[ ${i} == $[${#rom_info[@]}-1] ]]; then
                printf "\t\t\t`echo "${rom_info[$i]}" | sed -r 's/^(.*);(.*);(.*)$/"prj_name":"\1","system_version":"\2","VER":"\3"/'`\n\t\t}\n" >> ${json}
            else
                printf "\t\t\t`echo "${rom_info[$i]}" | sed -r 's/^(.*);(.*);(.*)$/"prj_name":"\1","system_version":"\2","VER":"\3",/'`\n\t\t}\n" >> ${json}
            fi
        done
    else
        printf "\t\t}\n" >> ${json}
    fi

    printf "\t]\n" >> ${json}
    printf "}\n" >> ${json}

    ## 备份测试报告文件 report.json
    if [[ -f ${json} ]]; then
        cp -f ${json} ${DEST_PATH}

        if [[ $? -eq 0 ]]; then
            rm -rf ${json}
        fi
    else
        log error "未找到生成测试报告文件 ..."
    fi
}

## 编译k10x项目的系统APP
function auto_build_system_app()
{
    local OldPWD=`pwd`
    local buildfs_dir_r=reglink/package/apps
    local buildfs_dir_y=yunovo/package/apps
    local compile_sh=compile.sh

    if [[ -f ${buildfs_dir_r}/${compile_sh} ]];then

        cd ${buildfs_dir_r} > /dev/null

        chmod +x ${compile_sh}
        ./${compile_sh}

        cd ${OldPWD} > /dev/null

    elif [[ -f ${buildfs_dir_y}/${compile_sh} ]];then

        cd ${buildfs_dir_y} > /dev/null

        chmod +x ${compile_sh}
        ./${compile_sh}

        cd ${OldPWD} > /dev/null

    else
        log error "The $compile_sh no found ."
    fi
}

## 输出当前项目使用的APP, 主要包含云智开发与第三方的APP
function print_system_app()
{
    local OLDP=`pwd`
    local appfs=${script_p}/config/yunovo_app.txt
    local apkfs=${script_p}/config/yunovo_apk.txt

    local tmp=${tmpfs}/apps.ini
    local allappsfs=${tmpfs}/allapps.ini
    local project_apps=${tmpfs}/${build_prj_name}.ini

    local findfs=out/target/product/${DEVICE_PROJECT}/system/
    local apps_path=packages/apps

    ## 每次构建都更新一次
    if [[ -f ${project_apps} ]];then
        rm -r ${project_apps}
    fi

    if [[ "`is_yunovo_project`" ]];then

        find ${findfs} -name "*.apk" | grep app | sed 's/.*app\/\([^\/]*\).*/\1/g' | sort > ${tmp}
        find ${findfs} -name "*.apk" | grep preinstall | sed 's/.*all\/\([^.]*\).*/\1/g' >> ${tmp}

        ## 由于YOcLauncherRes该apk不参与编译，单独增加进去.
        echo "YOcLauncherRes" >> ${tmp}

        cat ${tmp} | sort > ${allappsfs}
        if [[ $? -eq 0 ]];then
            rm -r ${tmp}
        fi

    else
        log error "Is the product in yunovo ?"
    fi

    echo
    show_vig "-----------------------"
    while read p;do
        while read apk;do
            if [[ ${p} == ${apk} ]];then
                echo "$apk"
                echo "$apk" >> ${project_apps}
            fi
        done < ${apkfs}
    done < ${allappsfs}

    echo

    while read p;do
        while read app;do
            if [[ ${p} == ${app} ]];then
                echo "$app"
                echo "$app" >> ${project_apps}
            fi
        done < ${appfs}
    done < ${allappsfs}
    echo
    show_vig "-----------------------"

if [[ "`is_root_project`" == "false" ]];then

    cd ${apps_path} > /dev/null

    while read p;do
        while read apk;do
            if [[ ${p} == ${apk} ]];then
                cd ${apk} > /dev/null

                auto_create_refs_branch_for_app

                cd .. > /dev/null
            fi
        done < ${apkfs}
    done < ${allappsfs}

    while read p;do
        while read app;do
            if [[ ${p} == ${app} ]];then
                cd ${app} > /dev/null

                auto_create_refs_branch_for_app

                cd .. > /dev/null
            fi
        done < ${appfs}
    done < ${allappsfs}
    echo

    cd ${OLDP} > /dev/null
fi

    # 清理动作
    for ini in `ls ${tmpfs}/*.ini`; do
        rm -rf ${ini}
    done
}

## 去掉变量中的所有空格
function remove_space_for_vairable()
{
    ## 去掉空格后的变量
    local new_v=
    local old_v=$1

    if [[ $# -eq 1 ]];then
        :
    else
        log error "args is error, please check args !"
    fi

    new_v=(`echo ${old_v} | sed 's/[  ]\+//g'`)
    if [[ "$new_v" != "$old_v" ]];then
        echo ${new_v}
    else
        echo ${old_v}
    fi
}

## 拆分系统版本号
function split_system_version()
{
    build_version=${yunovo_version}

    if [[ -n "`echo ${build_version} | sed -n '/\./p'`" ]];then

        first_version=${build_version%%.*}
        second_version=${build_version#*.}

        if [[ -z "$first_version" || -z "$second_version" ]];then
            log error "The first_version or the second_version is null, please check it ."
        fi
    else
        first_version=${build_version}
        second_version=""
    fi

    ## 主版本号为测试版本,小版本号为开发调试版本
    if [[ -n "`echo ${second_version} | sed -n '/\./p'`"  ]];then
        is_test_version=false
    else
        is_test_version=true
    fi
}

## 处理编译后的系统app
function handle_system_app()
{
    local app_name=$1
    local outputP=output
    local apk_path=~/android/packages/apps

    if [[ "$app_name" ]];then
        :
    else
        log error "app name is null, please check it!"
    fi

    if [[ ! -d ${apk_path}/${app_name} ]];then
        mkdir -p ${apk_path}/${app_name}
    fi

    ## 1. 复制app 到指定目录下
    if [[ -f ${outputP}/${app_name}.apk ]];then
        cp -vf ${outputP}/${app_name}.apk ${apk_path}/${app_name}
    fi

    ## 2. 自动生成自己的android.mk文件
    if [[ -f ${apk_path}/${app_name}/${app_name}.apk ]];then

        cd ${apk_path}/${app_name} > /dev/null

        auto_create_android_mk ${app_name}

        cd - > /dev/null
    else
        log error "The app name not found, please check it !"
    fi
}

### 自动拷贝系统app
function auto_copy_app_to_android()
{
    local apk_path=~/android
    local prj_name=`get_project_real_name`

    if [[ "prj_name" ]];then
        local prj_path=~/jobs/${prj_name}/android/
    else
        log error "The prj_name is null, please check it ..."
    fi

    if [[ -d ${apk_path} && -d ${prj_path} ]];then
        cp -r ${apk_path}/* ${prj_path} && _echo "cp done: $prj_path ."
    else
        log error "The apk_path or prj_path not found, please check it ..."
    fi
}

## ant source code app for project
function ant_app()
{
    local OLDP=`pwd`
    local app_path=~/yunovo_app/packages/apps
    local apk_path=~/android/packages/apps
    local yunovo_ant_app_file=${script_p}/config/yunovo_ant_app.txt
    local branch_file=${script_p}/fs/branch.txt
    local is_same_project=false
    local is_same_branch=false
    local branch_name=""

    cd ${app_path} > /dev/null

    if [[ -f ${branch_file} ]];then
        branch_name=`cat ${branch_file}`
    fi

    ## 删除旧的版本apk
    if [[ -d ${apk_path} ]];then
        rm ${apk_path} -r

        _echo "---- remove $apk_path successful ..."
    fi

    ## 1,若为同个分支不进行clean bin/ 目录，2,若为不同分支则会rm bin/ -r
    if [[ "$branch_name" ]];then
        if [[ "$branch_name" == "$build_branch" ]];then
            is_same_branch=true
        else
            is_same_branch=false
            echo ${build_branch} > ${branch_file}
        fi
    else
        is_same_branch=false
        echo ${build_branch} > ${branch_file}
    fi

    _echo "is same branch  = $is_same_branch "

    while read appN
    do
        echo ${appN}
        cd ${appN} > /dev/null

        ###编译之前是否进行清理 bin/
        if [[ ${is_same_project} == "true" ]];then

            if [[ ${is_same_branch} == "true" ]];then
                :
            else
                if [[ -d /bin ]];then
                    rm bin/ -rf
                fi
            fi
        else
            if [[ -d bin/ ]];then
                rm bin/ -rf
            fi
        fi

        (
            if (ant -q > /dev/null);then
                handle_system_app ${appN}
            else
                log error "make $appN failed ..."
            fi
        )

        cd .. > /dev/null

    done < ${yunovo_ant_app_file}

    cd ${OLDP} > /dev/null

    __echo "ant app end ..."
}