#!/usr/bin/env bash

# if error;then exit
set -e

# exec shell
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

function main() {

    local git_dir=${tmpfs}/git

    local OLDP=`pwd`

    cd ${git_dir} > /dev/null

    for p in `ls` ; do
        case `get_file_name ${p}` in

            art|bionic|bootable|build|cts|dalvik|development|device|external|frameworks|hardware|kernel-3.10|libcore|packages|system|vendor)
                show_vip "  err -> `get_file_name ${p}` "
                continue;
                ;;

            *)
                if true;then
                    show_vip "ok -> `get_file_name ${p}` "

                    cd ${p} > /dev/null

                    if [[ -f HEAD ]]; then
                        : #git gc
                    else
                        __err "HEAD not exist ..."
                        return 0
                    fi

                    if [[ -n `git show-ref | grep refs/meta/config | awk '{ print $NF }'` ]]; then
                        git update-ref -d refs/meta/config
                    fi

                    if [[ -n `git show-ref | grep refs/heads/master | awk '{ print $NF }'` ]]; then
                        git update-ref -d refs/heads/master
                    fi

                    if [[ -z `git remote` ]]; then
                        git remote add yunovo ssh://xingyafeng@gerrit-in.yunovo.cn:29419/yunovo_packages/platform/`get_file_name ${p}`
                    fi

                    git push yunovo refs/*:refs/*

                    cd - > /dev/null
                fi
            ;;
        esac
    done

    cd ${OLDP} > /dev/null
}

main $@
