#!/usr/bin/env bash

# if error;then exit
set -e

declare -a _inlist

function show_vip
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;35m$ret \e[0m"
        done

        echo
        echo
    fi
}

function show_vig
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;32m$ret \e[0m"
        done

        echo
        echo
    fi
}

function show_vib
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;34m$ret \e[0m"
        done

        echo
    fi
}

function show_vir
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;31m$ret \e[0m"
        done

        echo
        echo
    fi
}

## 错误信息
function __err()
{
    local msg=$1

    if [[ $# -eq 1 ]];then
        :
    else
        __echo "e.g : __err xxx"
    fi

    if [[ "$msg" ]];then
        show_vir "$msg"
    else
        show_vir "msg is null, please check it !"
    fi
}

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

# 同步代码
function repo_sync()
{
    repo selfupdate

    if repo sync -c -d --prune --no-tags --force-sync;then
        echo
        show_vip "---- repo sync code successful ..."
    else
        __err " --- repo sync code fail ..."
        return 1
    fi
}

# 清除 repo
function repo_clean() {

    if [[ -d .repo ]]; then
        rm -rf .repo
    fi
}

## 更新源代码
function update_source_code()
{
    if [[ -f build/core/envsetup.mk && -f Makefile ]]; then

        recover_standard_android_project

        ## 重新初始化，防止本地提交代码影响版本
        if [[ -n "${args}" ]];then
            repo init ${args}
        else
            __err "args is null ..."
            return 1
        fi

        if [[ -d .repo ]]; then
            repo_sync
        else
            __err "repo init fail ..."
            return 1
        fi
    else

        ## 下载中断处理,需要重新下载代码
        repo_clean

        download_source_code
    fi
}

# 下载源代码
function download_source_code() {

    local ssh_url="ssh://${git_username}@gerrit.y:29419/manifest"

    ## 下载中断处理,需要重新下载代码
    repo_clean

    if [[ -n "${args}" ]];then
        repo init -u ${ssh_url} ${args}
    fi

    if [[ -d .repo ]]; then
        repo_sync
    fi
}

function download_code() {

    local args=

    if [[ ! -d ${code_p} ]]; then
        mkdir -p ${code_p}
    fi

    cd ${code_p} > /dev/null

    if [[ -n ${branch} && -n ${xml} ]]; then
        args="-b ${branch} -m ${xml}"
    elif [[ -n ${branch} ]];then
        args="-b ${branch}"
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        update_source_code
    else
        download_source_code
    fi

    cd - > /dev/null
}

function main() {

    local jenkins_url='http://jenkins.y'

    local git_username="`git config --get user.name`"
    local branch=
    local board=

    local jobs=("`java -jar ~/jenkins-cli.jar -remoting -s ${jenkins_url} get-view ZenRom | grep '<string>' | awk -F '>' '{print $2}' | awk -F '<' '{print $1}'`")

    _inlist=(${jobs} other)
    show_vib "Choose Which yunovo board ?"
    select_choice board

    local tmp=
    local strcmp=
    case ${board} in
        other)
            for job in ${jobs[@]} ; do
                tmp="^${board}/master$|^${board}/stable$|^${board}/master[0-9][0-9]$|^${board}/stable[0-9][0-9]$"
                strcmp="${strcmp}""${tmp}"
            done

            _inlist=(`ssh -p 29419 ${git_username}@gerrit.y gerrit ls-user-refs -p manifest -u ${git_username} --only-refs-heads | sed s#refs/heads/## | egrep -v "${strcmp}"`)
        ;;

        *)
            _inlist=(`ssh -p 29419 ${git_username}@gerrit.y gerrit ls-user-refs -p manifest -u ${git_username} --only-refs-heads | sed s#refs/heads/## | egrep "^${board}/master$|^${board}/stable$|^${board}/master[0-9][0-9]$|^${board}/stable[0-9][0-9]$"`)
        ;;
    esac

    show_vib "Choose Which manifest branch?"
    select_choice branch

    code_p=`echo ${branch} | sed s#/#_#`

    #echo "branch = $branch ; code_p = $code_p"
    case ${branch} in
        master)
            continue;
        ;;

        spt)
            continue;
        ;;

        yunovo/empty)
            continue;
        ;;

        *)
            download_code
        ;;
    esac
}

main "$@"