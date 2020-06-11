#!/bin/bash

function usge()
{
    echo ""
    echo "$0 args1 args2"
    echo
    echo "    args1 : 查找manifest文件名."
    echo "    args2 : 查找该文件中的字符串."
    echo
    echo "    e.g. $0 yunovo_packages.xml CarRecordUsb"
    echo
}

function main()
{
    if [[ $# -eq 2 ]];then
        :
    else
        usge
        return 0
    fi

    if [[ "$1" ]];then
        fs=$1
    fi

    if [[ "$2" ]];then
        str=$2
    fi

    for r in `git show-ref | awk '{ print $NF }' | egrep refs/users`
    do
        git lg ${r} -p | grep jenkins@erich2 && git lg ${r}  &&echo ${r} && echo '--------'
    done
}

main $@
