#!/bin/bash

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

function f_sleep()
{
    sleep 2
}

function reposync()
{
    script -f -c "repo sync -d --no-tags" > ${tmpfs}
}

function main()
{
    local tmpfs=~/.tmpfs/ss

    if [[ ! -p ${tmpfs} ]];then
        mkfifo ${tmpfs}
    fi

    while true;do

        if read cmd < ${tmpfs};then
            if [[ -n "$cmd" ]];then
                show_vig "recv : $cmd"
                case ${cmd} in

                    sync)
                        reposync
                        ;;
                    *)
                        echo -e " $cmd, Do not match it ...\n" > ${tmpfs}
                        show_vir "$cmd, Do not match it ..."
                        ;;
                esac

                echo "--done--" > ${tmpfs}

                if false;then
                for ((i=0;i<6;i++))
                do
                    f_sleep
                    echo $$,${i},`date` > ${tmpfs}
                    echo 1...
                    sleep 5
                    echo $$,${i},`date` > ${tmpfs}
                    echo 2...
                done
                fi
            else
                show_vir "cmd is NULL ..."
            fi
        fi

        show_vip "--done--"
    done
}

echo "server PID:$$"
echo "-------------------"
main
