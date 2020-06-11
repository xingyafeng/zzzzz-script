#!/usr/bin/env bash

# if error then exit
set -e

# 错误信息
# 0 表示脚本运行成功
# 1 表示脚本运行失败
# 2 表示已发布成功

# 1. 发布APK名称
build_release_app=
# 2. 仓库分支 [build_branch_name]
build_branch_name=
# 3. 构建编号 [build_display_name]
build_display_name=
# 4. 构建渠道 [build_multi_channel]
build_multi_channel=
# 5. APK签名类型
build_resign_platform=
# 6. 支持覆盖功能
build_override_module=

#当前Shell文件名
shellfs=$0

#init function
. "`dirname $0`/jenkins/yunovo_init.sh"

## ------------------------------ common

# 发布apk
declare -a release_apk_name
# 匹配对应的渠道与ROM
declare -A matchup
# app 签名类型,是否需要系统签名
build_signature_type=

loglevel=0 #debug:0; info:1; warn:2; error:3

# 编写提交信息
function git_commit() {

    local ard=${WORKSPACE}/yunovo_apkreleasedescription.txt

    git add . -A

    if [[ -f ${ard} ]]; then
        git commit -m "`cat ${ard}`"
    else
        git commit -m "update: ${build_release_app}${build_display_name}  release apk ..."
    fi
}

# 提交服务器
function git_push_gerrit()
{
    local branchN=
    local HEAD="HEAD:refs/for"

    if [[ -d `git rev-parse --git-dir` ]];then

        if [[ $# -eq 1 ]];then
            branchN=$1
        else
            branchN="`git branch | grep \* | cut -d ' ' -f2`"
        fi

        echo
        echo "branchN = $branchN"
        echo

        if [[ -n "$branchN" ]];then
            git push `git remote | grep origin` ${HEAD}/${branchN}%submit
        fi
    else
        log error "The currect dir no found .git ..."
    fi
}

# 提交发布apk
function git_commit_message() {

    if [[ -n `git status -s` ]]; then

        # 编写提交信息
        git_commit || log error "提交代码失败 ..."

        # 上传服务器
        git_push_gerrit || log error "上传代码失败 ..."

        echo
        show_vip "${build_release_app}${build_display_name} 发布成功. "
    else
        echo
        show_vip "${build_release_app}${build_display_name} 发布成功. "
    fi
}

# 发布apk
function apk_release() {

    local OLDP=`pwd`
    local apk_release_path=${tmpfs}/NxCustomResource/nxos/app
    local apk_release_backup_p=${apk_release_p}/${build_release_app}/${build_display_name}

    if [[ ! -d ${apk_release_path} ]]; then
        mkdir -p ${apk_release_path}
    fi

    log debug "发布apk版本 ..."

    cd ${apk_release_path} > /dev/null

    if [[ ! -d ${build_release_app} ]]; then
        mkdir -p ${build_release_app}
    fi

    if [[ ! -d ${apk_release_backup_p} ]]; then
        mkdir -p ${apk_release_backup_p}
    fi

    # 1.发布多个渠道
    for app in `find ${f1_nxos_p}/${build_release_app}/${build_display_name} -name "*.apk" | sort` ; do

        while read line;
        do
            if [[ "${app}" =~ "${line}" ]]; then
                echo ${build_release_app} ${apk_release_backup_p} | xargs -n 1 cp -v ${app}

                # 修正发布文件名称
                repalce=`echo ${app##*/} | awk -F '_'  '{ print $(NF-2) "_" $(NF-1) "_" $(NF) }'` ## 相同的部分需要删除
                mv ${build_release_app}/${app##*/} ${build_release_app}/`echo ${app##*/} | sed s/_${repalce}//`.apk
            fi
        done < ${WORKSPACE}/yunovo_multi_channel.cfg
    done

    # 2. 生成编译android.mk文件
    cd ${build_release_app} > /dev/null

    cat << EOF > Android.mk
LOCAL_PATH := \$(call my-dir)

EOF

    for apk in `ls` ;do
        if [[ -f ${apk} ]] && [[ `basename ${apk}` != Android.mk ]] && [[ `basename ${apk##*.}` == apk ]];then
            touch_android_mk ${apk}
            release_apk_name[${#release_apk_name[@]}]=${apk}
        fi
    done

    cd - > /dev/null

    # 3. 提交本次发布记录
    git_commit_message

    cd ${OLDP} > /dev/null
}

function handle_commom_vairable() {

    ## 获取服务器发布版本apk
    rsync -av --delete jenkins@${f1_server}:${test_path}/NXOS/ ${f1_nxos_p} || log error "同步服务器发布版本失败 ..."

    ## 下载或更新 资源仓库[NxCustomResource]
    download_and_update_apk_repository yunovo/zenportal/NxCustomResource ${build_branch_name}
}

function handle_vairable() {

    # 1. 发布APK
    build_release_app=${yunovo_release_app:=}
    if [[ -z ${build_release_app} ]]; then
        log error "yunovo_release_app has error. please check it ."
    fi

    # 2. 构建分支名
    build_branch_name=${yunovo_branch_name:=master}
    if [[ -z ${build_branch_name} ]]; then
        log error "build_branch_name has error. please check it ."
    fi

    # 3. 构建编号
    build_display_name=${yunovo_display_name:=}
    if [[ -z ${build_display_name} ]]; then
        log error "build_display_name has error. please check it ."
    fi

    # 4. 构建渠道
    if [[ -f ${WORKSPACE}/yunovo_multi_channel.cfg ]]; then
        get_app_support_channel_no
        build_multi_channel=`echo ${!matchup[@]}`
    else
        log error "无法访问 ${WORKSPACE}/yunovo_multi_channel.cfg: 没有那个文件或目录"
    fi

    # 5. 构建APK签名类型
    build_resign_platform=${yunovo_resign_platform:=true}

    # 6. 支持覆盖功能
    build_override_module=${yunovo_override_module:-}

    # 是否需要平台签名?
    if [[ "${build_resign_platform}" == "true" ]]; then
        build_signature_type=platform
    else
        build_signature_type=PRESIGNED
    fi

    ## --------------------------

    handle_commom_vairable
}

function print_variable() {

    echo
    echo "JOBS = $JOBS"
    echo '-----------------------------------------'
    echo "build_release_app     = "${build_release_app}
    echo "build_display_name    = "${build_display_name}
    echo "build_branch_name     = "${build_branch_name}
    echo "build_multi_channel   = "${matchup[@]}
    echo "build_resign_platform = "${build_resign_platform}
    echo "build_override_module = "${build_override_module}
    echo '-----------------------------------------'
    echo
}

function init() {

    local rom_p=/public/share/ROM

    handle_vairable
    print_variable

    log debug "初始化完成 ..."
}

function apk_release_backup() {

    # 备份已发布的APK
    if [[ -d ${apk_release_p} ]];then
        rsync -av ${apk_release_p}/ jenkins@${f1_server}:${share_apk_p}/Release
    else
        log error "The ${apk_release_p} path do not exist ..."
    fi

    # 清理动作
    if [[ -d ${apk_release_p} ]]; then
        rm -rf ${apk_release_p}/*
    fi

    echo
    show_vip "--> sync apk release end ... "
}

function main() {

    local f1_nxos_p=${tmpfs}/NXOS

    log debug "发布脚本开始执行 ..."

    init

    apk_release

    apk_release_backup

    log debug "发布脚本执行结束 ..."
}

main "$@"
