###########################################################
###
###				tools functions
###
###
### date 	: 2013-12-05 19:55
### author  : yafeng
###
###########################################################
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

### color dark green
function show_vidg
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;36m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color white
function show_viw
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;37m$ret \e[0m"
        done

        echo
        echo
    fi
}

## 输出路径
function __msg()
{
    local pwd=`pwd`

    if [[ "$1" ]]
    then
        _echo "---- dir is : $pwd $1"
    else
        _echo "---- dir is : $pwd"
    fi
}

## 调试信息
function __debug()
{
    local msg=$1

    if [[ $# -eq 1 ]];then
        :
    else
        __echo "e.g : __wrn xxx"
    fi

    if [[ "$msg" ]];then
        show_vidg "$msg"
    else
        show_vir "msg is null, please check it !"
    fi
}

## 警告信息
function __wrn()
{
    local msg=$1

    if [[ $# -eq 1 ]];then
        :
    else
        __echo "e.g : __wrn xxx"
    fi

    if [[ "$msg" ]];then
        show_viy "$msg"
    else
        show_vir "msg is null, please check it !"
    fi
}

## 错误信息
function __err()
{
    local msg=$1

    if [[ $# -eq 1 ]];then
        :
    else
        __echo "e.g : __err xxx"
    fi

    if [[ "$msg" ]];then
        show_vir "$msg"
    else
        show_vir "msg is null, please check it !"
    fi
}

## 调试
function _echo()
{
    local msg=$1

    if [[ $# -eq 1 ]];then
        :
    else
        __echo "e.g : _echo xxx"
    fi

    if [[ "$msg" ]];then
        echo "$msg"
        echo
    else
        echo "msg is null, please check it !"
    fi
}

## 调试
function __echo()
{
    local msg=$1

    if [[ $# -eq 1 ]];then
        :
    else
        echo
        echo "e.g : __echo xxx"
        echo
    fi

    if [[ "$msg" ]];then
        echo
        echo "--> $msg"
        echo
    else
        _echo "msg is null, please check it !"
    fi
}

## debug
function __debug__
{
    [[ "$__dbg" == "on" ]] && $@ || :
}

########### 新增颜色输出，没有自带回车. 按照顺序 30~37

function __black__
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;30m$ret \e[0m"
        done
        echo
    fi
}

function __red__
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;31m$ret \e[0m"
        done
        echo
    fi
}

function __green__
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;32m$ret \e[0m"
        done
        echo
    fi
}

function __yellow__
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;33m$ret \e[0m"
        done
        echo
    fi
}

function __blue__
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;34m$ret \e[0m"
        done
        echo
    fi
}

function __pruple__
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;35m$ret \e[0m"
        done
        echo
    fi
}

function __dark_green__
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;36m$ret \e[0m"
        done
        echo
    fi
}

function __white__
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;37m$ret \e[0m"
        done
        echo
    fi
}

#######################
###    file EOF    ###
######################
