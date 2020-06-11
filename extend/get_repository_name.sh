#!/usr/bin/env bash

function ssh-gerrit()
{
    ssh -p 29419 zenportal@gerrit.y $@
}

## 获取仓库名
function get_repository_name()
{
    ssh-gerrit gerrit ls-projects | grep ^nxos | grep \/
}

function main()
{
    get_repository_name
}

main $@