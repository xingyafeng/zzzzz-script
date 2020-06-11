#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# 当前Shell文件名
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

function main() {
    log debug "start ..."

    #ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest a36/master   yunovo/empty
    #ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest d1402/master yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest K26/master   yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest k1402/master yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest k18/master   yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest k570e/master yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest k86/master   yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest k66/master   yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest k6806/master yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest k86a/master  yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest xt273/master yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest m170m/master yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest m66/master   yunovo/empty
    ssh -p 29419 xingyafeng@gerrit.y gerrit create-branch manifest s802/master  yunovo/empty

    log debug "end ..."
}

main $@