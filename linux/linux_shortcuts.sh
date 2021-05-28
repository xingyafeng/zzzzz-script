#!/usr/bin/env bash

####################################################### define

# ---------------------------------------- env


# ---------------------------------------- common variable


################################################### function

# -------------------------------- shortcut for \cd

function cworkspace
{
    check_if_dir_exists ${workspace_p}
    if [[ $? -eq 0 ]]; then
        \cd ${workspace_p} > /dev/null
    fi
}

function cjobs
{
    local jobs_p=~/jobs

    check_if_dir_exists ${jobs_p}
    if [[ $? -eq 0 ]]; then
        \cd ${jobs_p} > /dev/null
    fi
}

function capp
{
    local app_p=${workspace_p}/app

    check_if_dir_exists ${app_p}
    if [[ $? -eq 0 ]]; then
        \cd ${app_p} > /dev/null
    fi
}

function cmanifest
{
    local manifest_p=${workspace_p}/app/manifest

    check_if_dir_exists ${manifest_p}
    if [[ $? -eq 0 ]]; then
        \cd ${manifest_p} > /dev/null
    fi
}

function cshare
{
    local hostN=`hostname`
    local share_p=${workspace_p}/share

    case ${hostN} in

        *)
            check_if_dir_exists ${share_p}
            if [[ $? -eq 0 ]]; then
                \cd ${share_p} > /dev/null
            fi
            ;;
    esac
}

function cscript
{
    check_if_dir_exists ${script_p}
    if [[ $? -eq 0 ]]; then
        \cd ${script_p} > /dev/null
    fi
}

function cdate
{
    check_if_dir_exists ${td}
    if [[ $? -eq 0 ]]; then
        \cd ${td} > /dev/null
    fi
}

function crom
{
    check_if_dir_exists ${teleweb_p}
    if [[ $? -eq 0 ]]; then
        \cd ${teleweb_p} > /dev/null
    fi
}

function zzzzzz() {

    local lock=${tmpfs}/yf.lock
    local unlock=${lock}.bak

    if [[ -f ${lock} ]]; then
        mv ${lock}{,.bak}
    elif [[ -f ${unlock} ]]; then
        mv ${unlock} ${lock}
    fi

    echo
    show_vip "--> lock file : `basename $(ls ${lock}*)`"
}

## 打开文件
function openfs()
{
    case $# in
        0)
            nautilus . &
        ;;

        1)
            case $1 in
                -h|--help)
                    echo ""
                    echo "${FUNCNAME[0]} [\$@] ..."
                    echo
                    echo "   \$@ : 当前文件夹或文件夹..."
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}           " # 输出帮助文档
                    echo "        2. ${FUNCNAME[0]} -h|--help " # 输出帮助文档
                    echo "        3. ${FUNCNAME[0]} test.txt"   # 打开文件
                    echo "        4. ${FUNCNAME[0]} folder"     # 打开文件夹
                    echo
                    return 0
                ;;

                *)
                    if [[ -f $1 && -n $1 ]]; then
                        nautilus $1 &
                    else
                        echo ""
                        echo "${FUNCNAME[0]} [\$@] ..."
                        echo
                        echo "   \$@ : 当前文件夹或文件夹..."
                        echo
                        echo "    e.g."
                        echo "        1. ${FUNCNAME[0]}           " # 输出帮助文档
                        echo "        2. ${FUNCNAME[0]} -h|--help " # 输出帮助文档
                        echo "        3. ${FUNCNAME[0]} test.txt"   # 打开文件
                        echo "        4. ${FUNCNAME[0]} folder"     # 打开文件夹
                        echo
                        return 0
                    fi
            esac
            ;;

        *)
            echo ""
            echo "${FUNCNAME[0]} [\$@] ..."
            echo
            echo "   \$@ : 当前文件夹或文件夹..."
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]}           " # 输出帮助文档
            echo "        2. ${FUNCNAME[0]} -h|--help " # 输出帮助文档
            echo "        3. ${FUNCNAME[0]} test.txt"   # 打开文件
            echo "        4. ${FUNCNAME[0]} folder"     # 打开文件夹
            echo
            return 0
        ;;
    esac
}

## 编译文件
function geditfs()
{
    case $# in
        1)
            case $1 in
                -h|--help)
                    echo ""
                    echo "${FUNCNAME[0]} [\$@] ..."
                    echo
                    echo "   \$@ : 当前文件夹或文件夹..."
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}           " # 输出帮助文档
                    echo "        2. ${FUNCNAME[0]} -h|--help " # 输出帮助文档
                    echo "        3. ${FUNCNAME[0]} test.txt"   # 打开文件
                    echo
                    return 0
                ;;

                *)
                    if [[ -f $1 && -n $1 ]]; then
                        gedit $1 &
                    else
                        echo ""
                        echo "${FUNCNAME[0]} [\$@] ..."
                        echo
                        echo "   \$@ : 当前文件夹或文件夹..."
                        echo
                        echo "    e.g."
                        echo "        1. ${FUNCNAME[0]}           " # 输出帮助文档
                        echo "        2. ${FUNCNAME[0]} -h|--help " # 输出帮助文档
                        echo "        3. ${FUNCNAME[0]} test.txt"   # 打开文件
                        echo
                        return 0
                    fi
                ;;
             esac
        ;;

        *)
            echo ""
            echo "${FUNCNAME[0]} [\$@] ..."
            echo
            echo "   \$@ : 当前文件..."
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]}           " # 输出帮助文档
            echo "        2. ${FUNCNAME[0]} -h|--help " # 输出帮助文档
            echo "        3. ${FUNCNAME[0]} test.txt"   # 打开文件
            echo
            return 0
        ;;
    esac
}

## 查找不同文件
function gfind()
{
    local files=$1

	if [[ "$files" ]];then
	    types=${files}
    else
		show_vip "please add only one arg, eg:gfind + string"
	fi

    case ${types} in

        c | cc | cpp | java | xml | sh | mk | rc | cfg | makefile | prop)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        bmp | jpg | png)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        txt | pdf | doc | xls)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        zip | rar | tar | gz | img)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        xml | html)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        wav | mp3 | acc | flac | wma | wav)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        *)
            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "$files" -print
            ;;
    esac
}

### 收索文件内容，区分不同文件
function grepfs()
{
    local files=$1
    local types=$2

    if [[ "$files" ]];then
        :
    else
        show_vip "what do you want to grep file ?"
    fi

    case ${types} in

        c)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.c' -print0 | xargs -0 grep --color -n "$1"
            ;;

        cc)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.cc' -print0 | xargs -0 grep --color -n "$1"

            ;;

        cpp)

           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.cpp' -print0 | xargs -0 grep --color -n "$1"
            ;;

        java)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.java' -print0 | xargs -0 grep --color -n "$1"

            ;;

        xml)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.xml' -print0 | xargs -0 grep --color -n "$1"

            ;;

        sh)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.sh' -print0 | xargs -0 grep --color -n "$1"

            ;;

        mk)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.mk' -print0 | xargs -0 grep --color -n "$1"

            ;;

        rc)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.rc' -print0 | xargs -0 grep --color -n "$1"

            ;;

        cfg)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.cfg' -print0 | xargs -0 grep --color -n "$1"

            ;;

        makefile)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name 'Makefile' -print0 | xargs -0 grep --color -n "$1"

            ;;

        prop)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.prop' -print0 | xargs -0 grep --color -n "$1"

            ;;
        *)
            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.java' -o -name '*.xml' -o -name '*.sh' -o -name '*.mk' -o -name '*.rc' -o -name '*.cfg' -o -name 'Makefile' -o -name 'Kconfig' -o -name '*.sh' -o -name '*.prop' \) -print0 | xargs -0 grep --color -n $@

            ;;
    esac
}

function ggrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "*\.gradle" \
        -exec grep --color -n "$@" {} +
}

function jgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "*\.java" \
        -exec grep --color -n "$@" {} +
}

function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) \
        -exec grep --color -n "$@" {} +
}

function resgrep()
{
    for dir in `find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -name res -type d`; do
        find ${dir} -type f -name '*\.xml' -exec grep --color -n "$@" {} +
    done
}

function mangrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -type f -name 'AndroidManifest.xml' \
        -exec grep --color -n "$@" {} +
}

function sepgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -name sepolicy -type d \
        -exec grep --color -n -r --exclude-dir=\.git "$@" {} +
}

function rcgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "*\.rc*" \
        -exec grep --color -n "$@" {} +
}

function mgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -regextype posix-egrep -iregex '(.*\/Makefile|.*\/Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -type f \
        -exec grep --color -n "$@" {} +
}

function treegrep()
{
    find . -name .repo -prune -o -name .git -prune -o -regextype posix-egrep -iregex '.*\.(c|h|cpp|S|java|xml)' -type f \
        -exec grep --color -n -i "$@" {} +
}

# 利用shell自动展开特性.
function copy_to_bak() {

    local file=${1-}

    if [[ -n ${file} && -f ${file}  ]]; then
        cp ${file}{,.bak}
    else
        log error "copy_to_bak: cannot find '${file}': No such file or directory"
    fi
}

## login ssh server shortcuts patrol/Aa123456
function jenkins
{
    ssh patrol@jenkins
}

function jenkins0
{
    if [[ -n ${1:-} ]]; then
        ssh android-bld@10.129.93.14
    else
        ssh android-bld@10.129.93.14 -p 8089
    fi
}

function jenkins1
{
    if [[ -n ${1:-} ]]; then
        ssh android-bld@10.129.93.30
    else
        ssh android-bld@10.129.93.30 -p 8089
    fi
}

function jenkins2
{
    if [[ -n ${1:-} ]]; then
        ssh android-bld@10.129.93.31
    else
        ssh android-bld@10.129.93.31 -p 8089
    fi
}

function jenkins3
{
    if [[ -n ${1:-} ]]; then
        ssh android-bld@10.129.93.34
    else
        ssh android-bld@10.129.93.34 -p 8089
    fi
}

function jenkins4
{
	ssh android@10.129.93.104
}

function jenkins5
{
    ssh android@10.129.93.105
}

function jenkins6
{
    ssh android@10.129.93.106
}

function jenkins7
{
    ssh android-bld@10.129.93.107 -p 8089
}

function jenkins8
{
    ssh android-bld@10.129.93.108 -p 8089
}

function jenkins9
{
    ssh android-bld@10.129.93.109 -p 8089
}

function jenkins10
{
    ssh android-bld@10.129.93.110 -p 8089
}

function jenkins11
{
    ssh android-bld@10.129.93.111 -p 8089
}

function jenkinscd
{
    ssh jenkins@10.89.32.110 -p 8087
}

# 编译服务器，密码mobile#3
function yafeng.xing() {
    ssh yafeng.xing@10.129.93.102
}

function jenkins20() {
    ssh android@10.129.46.20
}

function jenkins21() {
    ssh android@10.129.46.21
}

function jenkins22 {

    build186
}

function jenkins23 {

    build241
}

function jenkins24 {

    local username=
    local hostname='s26'

    if [[ -n ${1:-} ]]; then
        username=ttk
    else
        username=android-bld
    fi

    case ${username} in

        ttk)
            ssh ${username}@${hostname}
        ;;

        android-bld)
            ssh ${username}@${hostname} -p 8082
        ;;
    esac
}

function jenkins25 {

    local username=
    local hostname='s25'

    if [[ -n ${1:-} ]]; then
        username=ttk
    else
        username=android-bld
    fi

    case ${username} in

        ttk)
            ssh ${username}@${hostname}
        ;;

        android-bld)
            ssh ${username}@${hostname} -p 8089
        ;;
    esac
}

function jenkins26 {

    local username=
    local hostname='s26'

    if [[ -n ${1:-} ]]; then
        username=ttk
    else
        username=android-bld
    fi

    case ${username} in

        ttk)
            ssh ${username}@${hostname}
        ;;

        android-bld)
            ssh ${username}@${hostname} -p 8089
        ;;
    esac
}

function jenkins27 {

    build227
}

function jenkins28 {

    build228
}

function build186() {
    ssh -l android-bld 10.128.180.186
}

function build227() {
    ssh -l android-bld 10.128.180.227
}

function build228() {
    ssh -l android-bld 10.128.180.228
}

function build241() {
    ssh android-bld@10.128.180.241
}

function mirror1() {
    ssh android@10.128.180.22
}

# sysadmin/Tablet@123
function mirror2() {
    ssh android@10.128.180.36
}

function mirror3() {
    ssh android@10.129.93.128
}

function mirror4() {
    ssh android@10.129.93.129
}

function mirror5() {
    ssh android@10.129.93.130
}

function mirror6() {
    ssh android@10.129.93.131
}

function mirror10() {
    ssh android@10.129.93.164
}

function mirror11() {
    ssh android@10.129.93.165
}

function mirror12() {
    ssh android@10.129.93.166
}

function mirror13() {
    ssh android@10.129.93.167
}

function mirror20() {
    ssh android@10.129.94.13
}

function mirror21() {
    ssh android@10.129.94.14
}

function mirror22() {
    ssh android@10.129.94.15
}

function droidyafeng() {
    ssh -l yafeng WS186
}

function docker0() {
    ssh -l jenkins 10.129.47.112
}

function docker1() {
    ssh -l jenkins 10.129.46.104
}

function docker2() {
    ssh -l jenkins 10.129.46.54
}

function docker3() {
    ssh -l jenkins 10.129.47.111
}


