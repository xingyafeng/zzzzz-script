#!/usr/bin/env bash

##------------------------------------------- 仓库信息

# 仓库路径
GITRES=""
# 仓库分支
GITRES_BRANCH=""

## ------------------------------------------- 公共

##临时目录
tmpfs=~/.tmpfs

git_username="`git config --get user.name`"
gerrit_server="gerrit.y"
gerrit_port="29419"

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
            git pull -q
        else
            git checkout ${GITRES_BRANCH} && git pull -q
        fi

        cd ${OPWD} > /dev/null
    else
        git clone -b ${GITRES_BRANCH} ssh://${git_username}@${gerrit_server}:${gerrit_port}/${GITRES} ${GITRES_PATH}/${GITRES##*/}
    fi
}

function main()
{
    if [[ ! -d ${tmpfs} ]]; then
        mkdir -p ${tmpfs}
    fi

    if [[ "$1" ]]; then
        GITRES=$1
    else
        echo "参数1为空."
    fi

    if [[ "$2" ]]; then
        GITRES_BRANCH=$2
    else
        echo "参数2为空."
    fi

    if [[ "$#" -ne 2 ]]; then
        echo ""
        echo "$0 options [ string ] "
        echo
        echo "    options : "
        echo "      $0 git_path git_branch  更新代码仓库."
        echo
        echo "    e.g. $0 nxos/nxTraffic yunovo/nxos/nxTraffic/master"
        echo
        return 1
    fi

    ## 下载构建工具gradle
    download_and_update_repository ReglinkDroidCar/config yunovo/reglink/droidcar/develop

    ## 下载测试脚本
    download_and_update_repository nxos/nxTestSuite yunovo/nxos/nxTestSuite/master

    ## 下载构建项目的仓库
    download_and_update_repository ${GITRES} ${GITRES_BRANCH}
}

main "$@"