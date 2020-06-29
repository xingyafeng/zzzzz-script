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
    if [[ "$@" ]];then
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
    if [[ "$@" ]];then
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
    if [[ "$@" ]];then
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
    if [[ "$@" ]];then
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
    if [[ "$@" ]];then
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
    if [[ "$@" ]];then
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
    if [[ "$@" ]];then
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
    if [[ "$@" ]];then
        for ret in "$@"; do
            echo -e -n "\e[1;37m$ret \e[0m"
        done

        echo
        echo
    fi
}

#----------------------------------------------------------- 调试信息

## 警告信息
function __wrn()
{
    case $# in

        *)
            show_viy "--> $@"
            ;;
    esac
}

## 错误信息
function __err()
{
    case $# in

        *)
            show_vir "--> $@"
            ;;
    esac
}

## 输出路径
function __msg()
{
    case $# in

        *)
            _echo "dir is : `pwd` $@"
            ;;
    esac
}

## 调试信息
function __debug()
{
    case $# in

        *)
            show_vib "--> $@"
            ;;
    esac
}

## 调试
function _echo()
{
    case $# in

        *)
            echo "--> $@"
            echo
            ;;
    esac
}

## 调试
function __echo()
{
    case $# in

        *)
            echo
            echo "--> $@"
            echo
            ;;
    esac
}



########### 新增颜色输出，没有自带回车. 按照顺序 30~37

function __black__
{
    if [[ "$@" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;30m$ret \e[0m"
        done
        echo
    fi
}

function __red__
{
    if [[ "$@" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;31m$ret \e[0m"
        done
        echo
    fi
}

function __green__
{
    if [[ "$@" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;32m$ret \e[0m"
        done
        echo
    fi
}

function __yellow__
{
    if [[ "$@" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;33m$ret \e[0m"
        done
        echo
    fi
}

function __blue__
{
    if [[ "$@" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;34m$ret \e[0m"
        done
        echo
    fi
}

function __pruple__
{
    if [[ "$@" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;35m$ret \e[0m"
        done
        echo
    fi
}

function __dark_green__
{
    if [[ "$@" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;36m$ret \e[0m"
        done
        echo
    fi
}

function __white__
{
    if [[ "$@" ]]
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
