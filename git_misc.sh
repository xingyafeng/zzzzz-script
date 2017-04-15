#!/usr/bin/env bash

##############################################
##
##                  git
##
##############################################

function auto_git_push_gerrit()
{
    local branchN=
    local HEAD="HEAD:refs/for"
    local remoteN="origin"

    if [ $# -eq 1 ];then
        branchN=$1
    else
        branchN="`git branch | grep \* | cut -d ' ' -f2`"
    fi

    echo
    show_viy "branchN = $branchN"
    echo

    if [ "$branchN" ];then
        if [ -d .git ];then
            git push $remoteN $HEAD/$branchN
        fi
    fi
}
