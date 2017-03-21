#!/usr/bin/env bash

##############################################
##
##                  git
##
##############################################

function git-push-gerrit()
{
    if [ $# -eq 1 ];then
        :
    else
        show_vir "args[] error, please check it !"
    fi

    if [ "$1" ];then
        local branchN=$1
        local HEAD="HEAD:refs/for"
        local remoteN="origin"

        if [ -d .git ];then
            git push $remoteN $HEAD/$branchN
        fi
    else
        show_vir "args[] is null, ag: git-push-gerrit branchN"
    fi
}
