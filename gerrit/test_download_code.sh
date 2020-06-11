#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "`dirname $0`/yunovo_init.sh"

DEBUG=true

# 清除 repo
function repo_clean() {

    if [[ -d .repo ]]; then
        rm -rf .repo
    fi
}

function download_code() {

    local cmd=

    if ${DEBUG}; then

        case ${branch} in

            a36/master|k1402/master|k21/s9/zxlmt|k26s/vst/a1)
                show_vip "--> manifest branch = ${branch}; xml = ${xml} >> continue."
                continue;
            ;;

            master|spt)
                case ${xml} in
                    A36.xml)
                        show_vip "--> manifest branch = ${branch}; xml = ${xml} >> continue."
                        continue;
                    ;;

                    *)
                        show_vip "--> manifest branch = ${branch};xml = ${xml}"
                    ;;
                esac
            ;;

            *)
                show_vip "--> manifest branch = ${branch};xml = ${xml}"
            ;;
        esac
    else
        case ${branch} in

            mk26/stable)
                show_vip "--> manifest branch = ${branch}; xml = ${xml} ."
            ;;

            master|spt)
                case ${xml} in
                    K26.xml)
                        show_vip "--> manifest branch = ${branch}; xml = ${xml} ."
                    ;;

                    *)
                        show_vip "--> manifest branch = ${branch};xml = ${xml} >> continue ."
                        continue;
                    ;;
                esac
            ;;

            *)
                show_vip "--> manifest branch = ${branch};xml = ${xml} >> continue ."
                continue;
            ;;
        esac
    fi

    if [[ ! -d ${code_p} ]]; then
        mkdir -p ${code_p}
    fi

    cd ${code_p} > /dev/null

    if [[ -n ${branch} && -n ${xml} ]]; then
        if ${DEBUG};then
            cmd="repo init -u ssh://${git_username}@${gerrit_server}:${gerrit_port}/manifest -b ${branch} -m ${xml} --mirror"

            if [[ -f build/core/envsetup.mk && -f Makefile ]]; then
                echo ${cmd}
                echo
                eval ${cmd}
            else
                ## 下载中断处理,需要重新下载代码
                repo_clean

                echo ${cmd}
                echo
                eval ${cmd}
            fi
        else
            show_vig "--> branch = ${branch}; xml = ${xml}"
        fi
    elif [[ -n ${branch} ]];then
        if ${DEBUG};then
            cmd="repo init -u ssh://${git_username}@${gerrit_server}:${gerrit_port}/manifest -b ${branch} --mirror"

            if [[ -f build/core/envsetup.mk && -f Makefile ]]; then
                echo ${cmd}
                echo
                eval ${cmd}
            else
                ## 下载中断处理,需要重新下载代码
                repo_clean

                echo ${cmd}
                echo
                eval ${cmd}
            fi
        else
            show_vig "branch = ${branch}"
        fi
    fi

    if ${DEBUG}; then
        repo sync -c -d --no-tags --force-sync
    else
        echo "repo sync -c -d --no-tags --force-sync"
    fi

    cd - > /dev/null
}

function main() {

    local code_p=""

    show_vip '--> branch.txt ...'
    while read branch;do
        code_p=`echo ${branch} | sed s#/#_#g`

        download_code
    done < ${script_p}/config/branch.txt

    branch=master
    show_vip "--> branch = ${branch}"
    while read xml;do
        code_p=`echo ${xml} | sed s#.xml##g`

        download_code
    done < ${script_p}/config/master.txt

    branch=spt
    show_vip "--> branch = ${branch}"
    while read xml;do
        code_p=`echo ${xml} | sed s#.xml##`

        download_code
    done < ${script_p}/config/spt.txt
}

main "$@"