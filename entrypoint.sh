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

    local jobs_p=/local/jobs

    sudo mkdir -p ${jobs_p}
    sudo chown -R android-bld:android-bld ${jobs_p}

    # config git
    setgitconfig Integration.tablet

    # start sshd
    sudo /etc/init.d/ssh start
}

function init() {

    local jobs_p=/local/jobs

    if [[ ! -d ${jobs_p} ]]; then
        sudo mkdir -p ${jobs_p}
        sudo chown -R android-bld:android-bld ${jobs_p}
        touch ~/init_ok.ini
    else
        touch ~/init_fail.ini
    fi
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    log debug 'start ...'

    pushd ${script_p} > /dev/null

    touch ~/init_START.ini
    init
    touch ~/init_END.ini
    doconfig

    popd > /dev/null

    log debug 'end ...'
    trap - ERR

    # 阻塞进程退出.
    sudo tail -F /var/log/dmesg
}

main "$@"