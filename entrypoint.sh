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

function init() {

    local jobs_p=~/jobs
    local tmpfs=~/.tmpfs

    sudo mkdir -p /local/jobs /local/.tmpfs
    sudo chown -R ${USER}:${USER} /local/jobs /local/.tmpfs

    if [[ -d ${jobs_p}  ]]; then
        sudo rm ${jobs_p}
    fi

    if [[ -d ${tmpfs}  ]]; then
        sudo rm ${tmpfs}
    fi

    sudo ln -s /local/jobs ~/jobs
    sudo ln -s /local/.tmpfs ~/.tmpfs
}

# config to ubunut in docker
function doconfig() {

    # config git
    setgitconfig Integration.tablet

    # start sshd
    sudo /etc/init.d/ssh start
    sudo tail -F /var/log/dmesg
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR
    log debug 'start ...'

    pushd ${script_p} > /dev/null

#    init

    doconfig

    popd > /dev/null

    log debug 'end ...'
    trap - ERR
}

main "$@"