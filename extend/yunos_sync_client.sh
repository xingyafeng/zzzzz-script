#!/usr/bin/env bash

### color red
function show_vir
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;31m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color green
function show_vig
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;32m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color yellow
function show_viy
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;33m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color blue
function show_vib
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;34m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color purple
function show_vip
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;35m$ret \e[0m"
        done

        echo
        echo
    fi
}

function main()
{
    local tmpfs=/tmp/s.fifo
    local cmd=sync

    if [[ -e ${tmpfs} ]];then

        if [[ -n ${cmd} ]];then
            echo ${cmd} > ${tmpfs}
        fi

        if false;then
            while read p;do
                if [[ -n "$p" ]];then
                    echo ${p}
                fi
            done < ${tmpfs}
        fi

        while true;do
            cat ${tmpfs}

            if [[ "`cat $tmpfs`" == "--done--" ]];then
                show_vip "--done--"
                return
            fi
        done
    else
        show_vir "$tmpfs: 没有那个文件或目录"
    fi
}

echo "client PID:$$"
echo "-------------------"
main $@
