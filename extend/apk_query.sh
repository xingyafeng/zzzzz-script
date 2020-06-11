#!/usr/bin/env bash

git_username="`git config --get user.name`"
gerrit_server="gerrit.y"
gerrit_port="29419"

## NxCustomResource仓库信息
GITRES=yunovo/zenportal/NxCustomResource
GITRES_BRANCH=yunovo/master
RESGIT_DIR=/media/yunovo/bcache0/repositories/git/projects/${GITRES}.git

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

## 更新NxCustomResource仓库
function update_apk_repositories()
{
    local OPWD=$(pwd)

    if [[ -d ${tmpfs}/${GITRES##*/}/.git ]];then
        recover_git_project "${tmpfs}/${GITRES##*/}"

        cd ${tmpfs}/${GITRES##*/} > /dev/null


        if [[ "${GITRES_BRANCH}" == "`git branch | grep \* | cut -d ' ' -f2`" ]]; then
            git pull || log error "git pull <${OPWD}> fail ..."
        else
            git checkout ${GITRES_BRANCH} && git pull || log error "git pull <${OPWD}> fail ..."
        fi

        cd ${OPWD} > /dev/null
    else
        git clone -b ${GITRES_BRANCH} ssh://${git_username}@${gerrit_server}:${gerrit_port}/${GITRES} ${tmpfs}/${GITRES##*/} || log error "git clone <${OPWD}> fail ..."
    fi
}

## 获取apk列表
function get_apk_list()
{
    ssh -t -p 22 jenkins@c2.y git --git-dir=${RESGIT_DIR} ls-tree --name-only -r ${GITRES_BRANCH} | grep '\.apk' | grep -v -e AdupsFota | awk -F '/' '{ print $(NF) }'
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        log error "获取APK列表失败 ..."
    fi
}

## 获取apk列表
function get_apk_path()
{
    local OPWD=$(pwd)
    local apk_name=$1

    find ${tmpfs}/${GITRES##*/} -name ${apk_name} || log error "get apk path fail ..."
}

function main()
{
    local tmpfs=~/.tmpfs

    if [[ ! -d ${tmpfs} ]]; then
        mkdir -p ${tmpfs}
    fi

    if [[ "$#" -gt 2 || "$#" -eq 0 ]]; then
        echo ""
        echo "$0 options [files name]"
        echo
        echo "    options : "
        echo "      $0 -l | --list           列出所有apk."
        echo "      $0 -u | --update         更新${GITRES##*/}仓库"
        echo "      $0 -p | --path apk_name  拿到指定apk路径."
        echo
        echo "    e.g. $0 -l "
        echo "    e.g. $0 -u "
        echo "    e.g. $0 -p YOcLauncher.apk"
        echo
        return 1
    fi

    for cmd in $@ ; do

        case ${cmd} in

            -l | --list)

                if [[ -n "$2" ]]; then
                    GITRES_BRANCH=$2
                fi

                get_apk_list
            ;;

            -p | --path)

                if [[ "$2" ]]; then
                    get_apk_path $2
                else
                    echo "args2 no found !"
                fi
            ;;

            -u | --update)

                if [[ -n "$2" ]]; then
                    GITRES_BRANCH=$2
                fi

                update_apk_repositories
            ;;

            *)
                if [[ "$#" -eq 0 ]]; then
                    echo "Invalid parameter ..."
                fi
            ;;
        esac
    done
}

main "$@"
