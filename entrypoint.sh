#!/usr/bin/env bash

# Common utilities, variables and checks for all build scripts.
set -o errexit
set -o nounset
set -o pipefail

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "$(dirname $0)/tct/tct_init.sh"

# config to ubunut in docker
function doconfig() {

    # config git
    setgitconfig Integration.tablet

    # start sshd
    sudo /etc/init.d/ssh start
}

function init() {

    local jobs_p=/local/jobs
    local tmp_p=/local/.tmpfs

    # 1. /local/jobs
    if [[ ! -d ${jobs_p} ]]; then
        sudo mkdir -p ${jobs_p}
        sudo chown -R android-bld:android-bld ${jobs_p}

        log debug "mkdir new jobs ..."
    else
        __red__ "the jobs is exist ..."
    fi

    # 2. /local/.tmpfs
    if [[ ! -d ${tmp_p} ]]; then
        sudo mkdir -p ${tmp_p}
        sudo chown -R android-bld:android-bld ${tmp_p}

        log debug "mkdir new tmp ..."
    else
        __red__ "the tmp is exist ..."
    fi

    if [[ -d ${tmpfs} ]]; then
        rm -rf ${tmpfs}
        ln -s ${tmp_p} ${tmpfs}
    fi
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    log debug 'start ...'

    pushd ${script_p} > /dev/null

    init
    doconfig

    popd > /dev/null

    log debug 'end ...'
    trap - ERR

    # 阻塞进程退出.
    sudo tail -F /var/log/dmesg
}

main "$@"