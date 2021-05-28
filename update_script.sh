#!/usr/bin/env bash

# Common utilities, variables and checks for all build scripts.
set -o errexit
set -o nounset
set -o pipefail

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "$(dirname $0)/jenkins/jenkins_init.sh"

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    if [[ -f ${tmpfs}/yf.lock ]];then
        :
    else
        #　下载或更新zzzzz-script脚本仓库
        if [[ $(is_connect_netwrok 'http://sz.gerrit.tclcom.com:8080') == "true" ]];then
            update_script
        fi
    fi

    trap - ERR
}

main "$@"