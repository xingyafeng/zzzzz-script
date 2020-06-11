#!/usr/bin/env bash

##############################################
##
##                  git
##
##############################################

function git-push-gerrit()
{
    local branchN=
    local HEAD="HEAD:refs/for"

    local is_force=false

    if [[ -d `git rev-parse --git-dir` ]];then

        if [[ $# -eq 1 ]];then

            if [[ "$1" == "-f" ]]; then
                is_force=true
                branchN="`git branch | grep \* | cut -d ' ' -f2`"
            else
                branchN=$1
            fi
        else
            branchN="`git branch | grep \* | cut -d ' ' -f2`"
        fi

        echo
        show_viy "branchN = $branchN"
        echo

        if [[ ${is_force} == "true" ]];then
            if [[ -n ${branchN} ]]; then
                git push `git remote | grep origin` ${HEAD}/${branchN}%submit
            else
                __err "currect branch not found ..."
                return 1
            fi
        else
            if [[ -n ${branchN} ]]; then
                git push `git remote | grep origin` ${HEAD}/${branchN}
            else
                __err "currect branch not found ..."
                return 1
            fi
        fi
    else
        __err "currect dir not in .git folder ..."
        return 1
    fi
}

function gitamend()
{
    local branchN=

    if [[ "$1" ]]; then
        branchN="$1"
    fi

    if [[ -d `git rev-parse --git-dir` ]];then

        if [[ -n "`git status -s`" ]];then
            git add . -A
        fi

        thisFiles=`git diff --name-only`
        if [[ -n "${thisFiles}" ]]; then
            git add ${thisFiles}
        fi

        thisFiles=`git diff --cached --name-only`
        if [[ -n "${thisFiles}" ]]; then
            git commit  --amend --no-edit
        fi

        git-push-gerrit ${branchN}
    fi
}

##自动创建隐藏分支
function auto_create_refs_branch()
{
    local branchN=
    local default_remote_name=origin
    local heads_branch_hash_value_log=~/.log/
    local username=`git config --get user.name`

    if [[ "$1" ]];then
        branchN=$1

        echo
        show_vig "---> start create refs branch ..."
    else
        show_vir "branchN is null !!!"
    fi

    if [[ ! -d ${heads_branch_hash_value_log} ]];then
        mkdir ${heads_branch_hash_value_log}
    fi

    if [[ "$2" ]];then
        default_remote_name=$2
    fi

    show_viy "---| $branchN"
    echo

    if [[ -d .repo ]];then
        repo forall -c git push ${default_remote_name} HEAD:refs/build/${username}/${branchN}
    else
        show_vir "current directory is not android !"
    fi

    if [[ "$branchN" ]];then
        branchN=`echo ${branchN} | sed 's/\//_/g'`
    fi

    if [[ -d .repo ]];then
        repo forall -c git log --pretty=oneline -1 > ${heads_branch_hash_value_log}/${branchN}_create_refs.log
    else
        show_vir "current directory is not android !"
    fi

    echo
    show_viy "---| $branchN"
    show_vig "---> end create refs branch ..."
    echo
}

##自动创建隐藏分支
function auto_delete_refs_branch()
{
    local branchN=
    local default_remote_name=origin
    local heads_branch_hash_value_log=~/.log/
    local username=`git config --get user.name`

    if [[ "$1" ]];then
        branchN=$1

        echo
        show_vig "---> start create refs branch ..."
    else
        show_vir "branchN is null !!!"
    fi

    if [[ "$2" ]];then
        default_remote_name=$2
    fi

    if [[ ! -d ${heads_branch_hash_value_log} ]];then
        mkdir ${heads_branch_hash_value_log}
    fi

    show_viy "---| $branchN"
    echo

    if [[ -d .repo ]];then
        repo forall -c git push ${default_remote_name} :refs/build/${username}/${branchN}
    else
        show_vir "current directory is not android !"
    fi

    if [[ "$branchN" ]];then
        branchN=`echo ${branchN} | sed 's/\//_/g'`
    fi

    if [[ -d .repo ]];then
        repo forall -c git log --pretty=oneline -1 > ${heads_branch_hash_value_log}/${branchN}_delete_refs.log
    else
        show_vir "current directory is not android !"
    fi

    echo
    show_viy "---| $branchN"
    show_vig "---> end create refs branch ..."
    echo
}

## 自动创建显示分支
function auto_create_heads_branch()
{
    local branchN=
    local default_remote_name=origin
    local heads_branch_hash_value_log=~/.log/

    if [[ "$1" ]];then
        branchN=$1

        echo
        show_vig "---> start create heads branch ..."
    else
        show_vir "branchN is null !!!"
    fi

    if [[ "$2" ]];then
        default_remote_name=$2
    fi

    if [[ ! -d ${heads_branch_hash_value_log} ]];then
        mkdir ${heads_branch_hash_value_log}
    fi

    show_viy "---| $branchN"
    echo

    if [[ -d .repo ]];then
        repo forall -c git push ${default_remote_name} HEAD:refs/heads/${branchN}
    else
        show_vir "current directory is not android !"
    fi

    if [[ "$branchN" ]];then
        branchN=`echo ${branchN} | sed 's/\//_/g'`
    fi

    if [[ -d .repo ]];then
        repo forall -c git log --pretty=oneline -1 > ${heads_branch_hash_value_log}/${branchN}_create_heads.log
    else
        show_vir "current directory is not android !"
    fi

    echo
    show_viy "---| $branchN"
    show_vig "---> end create heads branch ..."
    echo
}

## 自动删除显示分支
function auto_delete_heads_branch()
{
    local branchN=
    local default_remote_name=origin
    local heads_branch_hash_value_log=~/.log/

    if [[ "$1" ]];then
        branchN=$1

        echo
        show_vig "---> start delete heads branch ..."
    else
        show_vir "branchN is null !!!"
    fi

    if [[ "$2" ]];then
        default_remote_name=$2
    fi

    if [[ ! -d ${heads_branch_hash_value_log} ]];then
        mkdir ${heads_branch_hash_value_log}
    fi

    show_viy "---| $branchN"
    echo

    if [[ -d .repo ]];then
        repo forall -c git push ${default_remote_name} :refs/heads/${branchN}
    else
        show_vir "current directory is not android !"
    fi

    if [[ "$branchN" ]];then
        branchN=`echo ${branchN} | sed 's/\//_/g'`
    fi

    if [[ -d .repo ]];then
        repo forall -c git log --pretty=oneline -1 > ${heads_branch_hash_value_log}/${branchN}_delete_heads.log
    else
        show_vir "current directory is not android !"
    fi

    echo
    show_viy "---| $branchN"
    show_vig "---> end delete heads branch ..."
    echo
}

function remove_refs_for_app()
{
    local OLDP=`pwd`
    local app_file=${config_p}/allapp.txt
    local tmpfs=${script_p}/fs
    local app_path=packages/apps

    cd ${app_path} > /dev/null

    while read app_name;do
        if [[ -d ${app_name} ]];then
            cd ${app_name} > /dev/null

            git ls-remote | grep -E "eng_|userdebug_" | awk '{ print $2 }' | sort > ${tmpfs}/refs.log

            while read refs;do
                if [[ -n "refs" ]];then
                    if [[ "$1" ]];then
                        echo ${refs}
                        echo "---"
                    else
                        git push origin :${refs}
                    fi
                fi
            done < ${tmpfs}/refs.log

            cd ..
        else
            show_vir "---> $app_name do not exist !"
        fi
    done < ${app_file}

    cd ${OLDP} > /dev/null
}

function auto_relpace_all_branch()
{
    if [[ $# -eq 2 ]];then
        branchS=$1
        branchD=$2
    else
        show_vir " xargs is error, please check it !"
    fi

    RMT=origin
    MSG="移动${branchS}分支到${branchD}"
    REFS="refs/remotes/$RMT" #只过滤远程分支，不处理本地分支
    PAT="\"[\b]*${branchS}[\b]*\""
    REP_TO=""

    branchN="`git branch | grep \* | cut -d ' ' -f2`"
    default_remote_branch=`git for-each-ref --format "%(refname)" ${REFS} | grep "$RMT/$branchN"`

    echo "-- $MSG -- $default_remote_branch --"

    for B in `git for-each-ref --format "%(refname)" ${REFS}`
    do
        STR=`git grep -c1 -n -P "$PAT" ${B}`
        #echo "@@@@ $B   $STR "

        if [[ -z "$STR" ]]; then
            continue;
        fi

        if [[ ${B} ]];then
            git reset --hard ${B}
            git clean -fxd
        fi

        #去掉前缀 refs/ 方便提交到 refs/for
        B=${B:${#REFS}+1}

        if [[ "HEAD" == "$B" ]]; then
            continue
        fi

        LINE=""

        echo "$STR" | while read -r LINE || [[ -n "$line" ]];
        do
            LINE=${LINE#*:} # 第一个:之前为分支名，去掉
            #echo " line = $LINE"

            FNM="${LINE%%:*}" #去掉第一个:后的，为文件名(原字符串第二个:)
            echo " fum = $FNM"

            LINE=${LINE:${#FNM}+1} #去掉文件名之后就只有文件所在行和正文了
            #echo " line = $LINE"

            NUM="${LINE%%:*}" #去掉正文就是所在行数
            #echo " num = $NUM "

            STR=${LINE:${#NUM}+1}  #正文
            #echo " str = $STR"

            echo " -- $FNM -- $NUM -- $STR -- "

            #echo " -- ${STR/\breview/rv=\"http:\/\/gerrit.y\"} --  "
            #echo " -- $FNM -- $NUM -- "
            #echo '$NUM s/\(review="\)[^"]*/\1tt:\/\/t\.t/g q'
            #sed -i -e "$NUM s/\(review=\"\)[^\"]*/\1http:\/\/gerrit\.y/g" $FNM

            if [[ -f ${FNM} ]];then
                sed -i -e "s$\"[:space:]*${branchS}[:space:]*\"\$\"${branchD}\"$" ${FNM}
            fi
        done

        if true; then
            git diff ${FNM}
            git add -A
            git commit -m " $MSG "
            git cat-file -p HEAD
            git push ${RMT} HEAD:refs/for/${B}
        else
            :
            #break
        fi
        echo
    done

    git reset --hard ${default_remote_branch}
}

function get_repo_reference()
{
    local manifests_git_p=.repo/manifests.git

    if [[ -d ${manifests_git_p} ]];then
        git --git-dir=${manifests_git_p} config --get repo.reference
    fi
}

# 本地代码上传至Gerrit服务器, 只能首次执行,再次则无效
function git_to_gerrit() {

    local branch_name=
    local msg=

    if [[ "$#" -eq 2 ]]; then
        branch_name="$1"
        msg="$2"
    else
        echo ""
        echo "${FUNCNAME[0]} [args1] [args2] ..."
        echo
        echo "    args1 : refs 分支名称"
        echo "    args2 : 提交信息"
        echo
        echo "    e.g."
        echo "        1. ${FUNCNAME[0]} alps-mp-p0.mp1 'init mt6762 for pie'"
        echo
        echo "    注意,在根路径下执行."
        return 0
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        repo forall -c git add -A -f .
        repo forall -c git commit -m "${msg}"
        repo forall -c git push origin HEAD:refs/build/xingyafeng/"${branch_name}"
    else
        echo "branch name : " ${branch_name}
        echo "msg         : " ${msg}

        __err "当前路径不正确,确认是否切换值ANDROID_ROOT路径下. [${FUNCNAME[0]}] 查询其帮助文档." && return 1
    fi
}
