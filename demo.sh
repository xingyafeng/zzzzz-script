#!/usr/bin/env bash

# Common utilities, variables and checks for all build scripts.
set -o errexit
set -o nounset
set -o pipefail

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "$(dirname "$0")/jenkins/jenkins_init.sh"

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    pushd ~/workspace/date/0310 > /dev/null

    local dir1=/mfs_tablet/teleweb/transformervzw/daily_version/v2C32-A
    local dir2=src
    local dir3=tgt
    local ret=

    ret=$(check_folder_the_name ${dir1} ${dir2})
    if [[ ${ret} == 'false' ]]; then
        cp -vf ${dir1}/*.mbn ${dir2}/
    else
        log debug 'is the same ...'
    fi

    ret=$(check_folder_the_name ${dir1} ${dir3})
    if [[ ${ret} == 'false' ]]; then
        cp -vf ${dir1}/*.mbn ${dir3}/
    else
        log debug 'is the same ...'
    fi


    popd > /dev/null

    trap - ERR
}

main "$@"