#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "`dirname $0`/yunovo_init.sh"


function main() {

    local the_projects=(demo1 demo2 demo3)
    local the_parent=All-Projects

    for the_project in ${the_projects[@]}; do
        ssh-gerrit-set-project-parent ${the_project} ${the_parent}
    done
}

main $@