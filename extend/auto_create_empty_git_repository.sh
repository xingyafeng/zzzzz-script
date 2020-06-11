#!/usr/bin/env bash

### color black
function show_vibk
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;30m$ret \e[0m"
        done

        echo
        echo
    fi
}

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
    local tmpfs=""
    local OPWD=`pwd`

    if [[ "$1" ]];then
        tmpfs=$1
    else
        echo "args is NULL."
        return 1
    fi

    echo
    show_vip "===> start create bare repository ..."
    echo

    if [[ -e ${tmpfs} ]];then

        cat ${tmpfs} | grep name | awk '{ print $3}' | awk -F '"' '{print $2}' | while read line;
        do
            tmp=${line##*/}

            if [[ ! -d ${tmp}/.git ]];then

                if [[ ${tmp} == "apn" ]];then
                git clone ssh://xingyafeng@gerrit.y:29419/${line} && scp -p -P 29419 xingyafeng@gerrit.y:hooks/commit-msg ${tmp}/.git/hooks/

                cd ${tmp} > /dev/null

                git log

                if [[ $? -ne 0 ]];then
                    git commit -m "Create empty project" --allow-empty
                    git push origin HEAD:refs/heads/yunovo/empty
                fi

                cd ${OPWD} > /dev/null
                fi

            else
                echo "$tmp exist ..."
            fi

        done
    fi

    echo
    show_vip "===> end create bare repository ..."
}

main $@
