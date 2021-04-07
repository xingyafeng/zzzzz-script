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

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    local target=${1:-}

    for t in ${target[@]} ; do
       Command mma -$(nproc) ${t}
    done

    trap - ERR
}

main "$@"