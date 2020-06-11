#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "`dirname $0`/yunovo_init.sh"

function main() {

    log debug "start ..."

    echo "main"

    log debug "end ..."
}

main $@