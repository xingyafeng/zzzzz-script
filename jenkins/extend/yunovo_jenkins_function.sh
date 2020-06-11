#!/usr/bin/env bash

function get_default_nodes() {

    cat ${jenkins_home}/jobs/${job}/config.xml | grep assignedNode | awk -F ">" '{ print $2 }' | awk -F "<" '{ print $1 }'
}

# 修改nxos应用的运行节点.
function replace_run_nodes() {

    local jenkins_home=~/.jenkins
    local default=
    local repalce=

    if [[ -n "$1" ]]; then
        repalce="$1"
    else
        __err "参数1为空 ..."
    fi

    if [[ $# -ne 1 ]]; then

        echo ""
        echo "replace_run_nodes default repalce"
        echo
        echo "    repalce : 替换后的节点名称"
        echo
        echo "    e.g. replace_run_nodes \"s1||s4||s5|s6||s7\" "
        echo

        return 0
    fi

    for prj in `ssh-gerrit gerrit ls-projects | grep ^nxos/nx`
    do
        for job in `ssh-jenkins list-jobs | grep ^nx` ; do
            if [[ `basename ${prj}` == ${job} ]]; then

                default="`get_default_nodes`"

                if [[  ${default} != ${repalce} ]]; then
                    echo "--> <${job}> repalce nodes : ${default} -> ${repalce} ... "

                    find ${jenkins_home}/jobs/${job} -type f -name config.xml -print0 | xargs -0 sed -i "s#<assignedNode>${default}</assignedNode>#<assignedNode>${repalce}</assignedNode>#g"
                fi
            fi
        done
    done
}