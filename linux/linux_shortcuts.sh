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

## login ssh server shortcuts
function jenkins
{
	ssh jenkins@happysongs
}

function jsystem
{
	ssh jenkins@10.0.0.250
}

function jenkins1
{
	ssh jenkins@s1.y
}

function jenkins2
{
	ssh jenkins@s2.y
}

function jenkins3
{
	ssh jenkins@s3.y
}

function jenkins4
{
	ssh jenkins@s4.y
}

function jenkins5
{
    ssh jenkins@s5.y
}

function jenkins6
{
    ssh jenkins@s6.y
}

function jenkins7
{
    ssh jenkins@s7.y
}

function jenkinsf1
{
    ssh jenkins@f1.y
}

function jenkinsc1
{
    ssh jenkins@c1.y
}

function jenkinsc2
{
    ssh jenkins@c2.y
}

function jenkinsd1
{
    ssh jenkins@d1.y
}

function yafengs5
{
    ssh yafeng@s5.y
}

function zenportal() {

    ssh zenportal@10.0.3.50
}

function droid20() {
    ssh android@10.129.46.20
}

function droid34() {
    ssh 'android-bld@10.129.93.34' -p 8089
}

function droid109() {
    ssh -l android-bld 10.129.93.109 -p 8089
}

function droid186() {
    ssh -l android-bld 10.128.180.186
}

function droidyafeng() {
    ssh -l yafeng WS186
}