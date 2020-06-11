#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

function main() {

    local OLDP=`pwd`
    local git_dir_p=${tmpfs}/git

    if [[ -d ${git_dir_p} ]]; then

        cd ${git_dir_p} > /dev/null

        for git in `ls` ; do

            show_vip "--> dir : ${git}"

            cd ${git} > /dev/null

            git gc

            cd - > /dev/null
        done

        cd ${OLDP} > /dev/null
    fi
}

main $@