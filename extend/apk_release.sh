#!/usr/bin/env bash

# if error then exit
set -e

# 错误信息
# 0 表示脚本运行成功
# 1 表示脚本运行失败
# 2 表示已发布成功

## ------------------------------ common
tmpfs=~/.tmpfs

# 发布apk
declare -a release_apk_name

git_username="`git config --get user.name`"
gerrit_server="gerrit.y"
gerrit_port="29419"

loglevel=0 #debug:0; info:1; warn:2; error:3
logfile=$0".log"

function log {

    local msg
    local logtype
    local datetime=`date +'%F %H:%M:%S'`

    if [[ "$1" ]]; then
        logtype=$1
    else
        echo "参数1为空 ..."
    fi

    if [[ "$2" ]]; then
        msg=$2
    else
        echo "参数2为空 ..."
    fi

    if [[ $# -ne 2 ]]; then
        echo "参数个数不正确 ..."
        return 1
    fi

    logformat="[${logtype}]\t${datetime}\tfuncname: ${FUNCNAME[@]/log/}\t[line:`caller 0 | awk '{print$1}'`]\t${msg}"

    {
        case ${logtype} in
            debug)
                [[ ${loglevel} -le 0 ]] && echo -e "\033[37m${logformat}\033[0m"
                ;;

            info)
                [[ ${loglevel} -le 1 ]] && echo -e "\033[32m${logformat}\033[0m"
                ;;

            warn)
                [[ ${loglevel} -le 2 ]] && echo -e "\033[33m${logformat}\033[0m"
                ;;

            error)
                [[ ${loglevel} -le 3 ]] && echo -e "\033[31m${logformat}\033[0m"
                ;;
        esac
    } | tee -a ${logfile}
}

## 恢复到干净工作区, 支持单个和多个项目仓库.
function recover_git_project()
{
    local tDir=$1
    local OPWD=$(pwd)

    if [[ ! "$tDir" ]]; then
        tDir=.
    fi

    if [[ -d ${tDir}/.git ]]; then

        cd ${tDir} > /dev/null

        if [[ -n "`git status -s`" ]];then
            echo "---- recover ${tDir}"
        else
            cd ${OPWD} > /dev/null
            return 0
        fi

        thisFiles=`git diff --cached --name-only`
        if [[ -n "$thisFiles" ]];then
            git reset HEAD . ###recovery for cached files
        fi

        thisFiles=`git clean -dn`
        if [[ -n "$thisFiles" ]]; then
            git clean -df
        fi

        thisFiles=`git diff --name-only`
        if [[ -n "$thisFiles" ]]; then
            git checkout HEAD ${thisFiles}
        fi

        cd ${OPWD} > /dev/null
    fi
}

## 下载更新APK仓库
function download_and_update_repository()
{
    local OPWD=$(pwd)
    local GITRES=""
    local GITRES_BRANCH=""
    local GITRES_PATH=""

    if [[ ! -d ${tmpfs} ]]; then
        mkdir -p ${tmpfs}
    fi

    if [[ "$1" ]]; then
        GITRES=$1
    else
        echo "参数1为空.-"
    fi

    if [[ "$2" ]]; then
        GITRES_BRANCH=$2
    else
        echo "参数2为空.-"
    fi

    if [[ "$3" ]]; then
        GITRES_PATH=$3
    else
        GITRES_PATH=${tmpfs}
    fi

    if [[ "$#" -gt 3 || "$#" -lt 2 ]]; then
        echo ""
        echo "download_and_update_repository options [ string ] "
        echo
        echo "    options : "
        echo "      download_and_update_repository git_path git_branch  更新代码仓库."
        echo
        echo "    e.g. download_and_update_repository nxos/nxTraffic yunovo/nxos/nxTraffic/master"
        echo
        return 1
    fi

    echo "update [ repository|branch|path ] ==> [ ${GITRES##*/}|${GITRES_BRANCH}|${GITRES_PATH}/${GITRES##*/}] ..."

    if [[ -d ${GITRES_PATH}/${GITRES##*/}/.git ]];then

        ## 恢复本来面目
        recover_git_project "${GITRES_PATH}/${GITRES##*/}"

        cd ${GITRES_PATH}/${GITRES##*/} > /dev/null

        if [[ "${GITRES_BRANCH}" == "`git branch | grep \* | cut -d ' ' -f2`" ]]; then
            git pull -q || log error "更新失败, 仓库名[${GITRES_PATH}] 分支名[${GITRES_BRANCH}]..."
        else
            git checkout ${GITRES_BRANCH} && git pull -q || log error "更新失败, 仓库名[${GITRES_PATH}] 分支名[${GITRES_BRANCH}]..."
        fi

        cd ${OPWD} > /dev/null
    else
        git clone -b ${GITRES_BRANCH} ssh://${git_username}@${gerrit_server}:${gerrit_port}/${GITRES} ${GITRES_PATH}/${GITRES##*/} || log error "下载失败, 仓库名[${GITRES_PATH}] 分支名[${GITRES_BRANCH}]..."

        cd ${GITRES_PATH}/${GITRES##*/} > /dev/null

        gitdir=$(git rev-parse --git-dir); scp -p -P 29419 ${git_username}@${gerrit_server}:hooks/commit-msg ${gitdir}/hooks/

        cd ${OPWD} > /dev/null
    fi
}


# 使用说明
usage() {
    #me=`basename "$0"`

    echo >&2 "Usage: auto_create_android_mk apk文件名 ..."
    echo
    echo >&2 "   eg: auto_create_android_mk Launcher3.apk"
    return 1
}

#　创建android.mk
function auto_create_android_mk()
{
    local APK_NAME=""

    local LIBS='LOCAL_PREBUILT_JNI_LIBS := \'
    local BUILDS='include $(BUILD_PREBUILT)'

    test $# -gt 0 || usage

    if [[ -n "$1" && $# -eq 1 ]]; then
        APK_NAME=$1
    fi

    if [[ $# -eq 1 ]];then
        echo
        echo "auto create android.mk start ..."
        echo
        echo "APK_NAME = $APK_NAME"
        echo
    else
        echo
        echo "Please e.g auto_create_android_mk  xxx.apk ..."
        return 1
    fi

    if [[ "${APK_NAME}" ]];then
        APK_NAME="${APK_NAME/%.apk/}"
    else
        return 1
    fi

    cat << EOF >> Android.mk
###################################################### ${APK_NAME}

include \$(CLEAR_VARS)
LOCAL_MODULE := ${APK_NAME}
LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := platform
LOCAL_MODULE_CLASS := APPS
LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)

ifeq (\$(strip \$(TARGET_ARCH)), arm64)
LOCAL_MULTILIB := 64
else ifeq (\$(strip \$(TARGET_ARCH)), arm)
LOCAL_MULTILIB := 32
endif

EOF

    if [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/arm64-v8a\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/arm64-v8a\/.*.so$/ { print $(NF) }' > ${tmpfs}/arm64_v8a.txt
    fi

    if [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ { print $(NF) }' > ${tmpfs}/armeabi-v7a.txt
    elif [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ { print $(NF) }' > ${tmpfs}/armeabi.txt
    fi

    if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then
        echo 'ifeq ($(strip $(TARGET_ARCH)), arm64)' >> Android.mk
        echo >> Android.mk
        echo ${LIBS} >> Android.mk
    fi

    if [[ -f ${tmpfs}/arm64_v8a.txt ]];then
        while read lib_path;do
            echo "    @${lib_path} \\" >> Android.mk
            # 打印下
            echo "${lib_path}"
        done < ${tmpfs}/arm64_v8a.txt
        echo >> Android.mk
        echo 'endif' >> Android.mk

        rm ${tmpfs}/arm64_v8a.txt
    fi

    if [[ -f ${tmpfs}/armeabi-v7a.txt || -f ${tmpfs}/armeabi.txt ]]; then
        echo >> Android.mk
        echo 'ifeq ($(strip $(TARGET_ARCH)), arm)' >> Android.mk
        echo >> Android.mk
        echo ${LIBS} >> Android.mk
    fi

    if [[ -f ${tmpfs}/armeabi-v7a.txt ]];then
        while read lib_path;do
            echo "    @${lib_path} \\" >> Android.mk
            # 打印下
            echo "${lib_path}"
        done < ${tmpfs}/armeabi-v7a.txt
        echo >> Android.mk
        echo 'endif' >> Android.mk
        echo >> Android.mk

        rm ${tmpfs}/armeabi-v7a.txt
    elif [[ -f ${tmpfs}/armeabi.txt ]];then
        while read lib_path;do
            echo "    @${lib_path} \\" >> Android.mk
            # 打印下
            echo "${lib_path}"
        done < ${tmpfs}/armeabi.txt
        echo >> Android.mk
        echo 'endif' >> Android.mk
        echo >> Android.mk

        rm ${tmpfs}/armeabi.txt
    fi

    echo ${BUILDS} >> Android.mk
    echo >> Android.mk

    echo
    echo "auto create android.mk end ..."
    echo
}

# 编写提交信息
function git_commit() {

    local des_p=~/jenkins/apkreleasedescription.txt

    git add . -A

    if [[ -f ${des_p} ]]; then
        git commit -m "update: ${JOB_NAME}${DISPLAY_NAME}  release apk ...

        `cat ${des_p}`"
    else
        git commit -m "update: ${JOB_NAME}${DISPLAY_NAME}  release apk ..."
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
        echo "currect dir no .git path ..."
    fi
}

# 提交发布apk
function git_commit_message() {

    if [[ -n `git status -s` ]]; then

        # 编写提交信息
        git_commit || log error "提交代码失败 ..."

        # 上传服务器
        git_push_gerrit || log error "上传代码失败 ..."
    else
        echo "${JOB_NAME}${DISPLAY_NAME} release apk 发布成功!"
        return 2
    fi
}

# 发布apk
function release_apk() {

    local OLDP=`pwd`
    local release_apk_path=${tmpfs}/NxCustomResource/nxos/app

    if [[ ! -d ${release_apk_path} ]]; then
        mkdir -p ${release_apk_path}
    fi

    log debug "发布apk版本 ..."

    cd ${release_apk_path} > /dev/null

    if [[ ! -d ${JOB_NAME} ]]; then
        mkdir -p ${JOB_NAME}
    fi

    # 1.发布多个渠道
    for app in `find ${f1_nxos_p}/${JOB_NAME}/${DISPLAY_NAME} -name "*.apk" | sort` ; do

        while read line;
        do
            if [[ "${app}" =~ "${line}" ]]; then
                cp -vf ${app} ${JOB_NAME}

                # 修正发布文件名称
                repalce=`echo ${app##*/} | awk -F '_'  '{ print $(NF-2) "_" $(NF-1) "_" $(NF) }'` ## 相同的部分需要删除
                mv ${JOB_NAME}/${app##*/} ${JOB_NAME}/`echo ${app##*/} | sed s/_${repalce}//`.apk
            fi
        done < ${CHANNEL_PATH}
    done

    # 2. 生成编译android.mk文件
    cd ${JOB_NAME} > /dev/null

    cat << EOF > Android.mk
LOCAL_PATH := \$(call my-dir)

EOF

    for apk in `ls` ;do
        if [[ -f ${apk} ]] && [[ `basename ${apk}` != Android.mk ]] && [[ `basename ${apk##*.}` == apk ]];then
            auto_create_android_mk ${apk}
            release_apk_name[${#release_apk_name[@]}]=${apk}
        fi
    done

    cd - > /dev/null

    # 3. 提交本次发布记录
    git_commit_message

    cd ${OLDP} > /dev/null
}

function init() {

    local rom_p=/public/share/ROM

    if [[ ! -d ${tmpfs} ]]; then
        mkdir -p ${tmpfs}
    fi

    ## 获取服务器发布版本apk
    rsync -av --delete jenkins@f1.y:${test_path}/NXOS/ ${f1_nxos_p} || log error "同步服务器发布版本失败 ..."

    ## 下载或更新 资源仓库[NxCustomResource]
    download_and_update_repository yunovo/zenportal/NxCustomResource ${GITRES_BRANCH}

    log debug "初始化完成 ..."
}

function main() {

    local JOB_NAME=
    local DISPLAY_NAME=
    local CHANNEL_PATH=
    local GITRES_BRANCH=yunovo/master

    local f1_nxos_p=${tmpfs}/NXOS

    log debug "发布脚本开始执行 ..."

    if [[ "$1" ]]; then
        JOB_NAME=$1
    else
        echo "参数1为空."
    fi

    if [[ "$2" ]]; then
        if [[ -n "`echo $2 | grep '"'`" ]];then
            DISPLAY_NAME=`echo $2 | awk -F '"' '{ print $2 }'`
        else
            DISPLAY_NAME=$2
        fi
    else
        echo "参数2为空."
    fi

    if [[ "$3" && -f $3 ]]; then
        CHANNEL_PATH=$3
    else
        echo "参数3为空或不为文件."
        return 1
    fi

    if [[ "$4" ]]; then
        GITRES_BRANCH=$4
    fi

    echo "JOB_NAME      = $JOB_NAME" && log debug "JOB_NAME     = $JOB_NAME"
    echo "DISPLAY_NAME  = $DISPLAY_NAME" && log debug "DISPLAY_NAME = $DISPLAY_NAME"
    echo "CHANNEL_PATH  = $CHANNEL_PATH" && log debug "CHANNEL_PATH = $CHANNEL_PATH"
    echo "GITRES_BRANCH = $GITRES_BRANCH" && log debug "GITRES_BRANCH = $GITRES_BRANCH"
    echo "参数个数      = $#" && log debug "参数个数      = $#"

    if [[ $# -lt 3 || $# -gt 4 ]];then
        log debug "参数不正确 ..."

        echo ""
        echo "$0 options [files name]"
        echo
        echo "    options : "
        echo "      $0　JOB_NAME DISPLAY_NAME CHANNEL_PATH"
        echo
        echo "    e.g. $0 nxCarService #1  /path "
        echo
        return 1
    fi

    init

    release_apk

    log debug "发布脚本执行结束 ..."
}

main "$@"
