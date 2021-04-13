#!/usr/bin/env bash

# ---------------------------------------- env


# ---------------------------------------- common variable

# 时间文件夹
td=${workspace_p}/date/`date +%m%d`

# ----------------------------------------

function obase()
{
	local dest_type=$1
	local src_tpye=$2
	local number=$3

	echo "obase=$dest_type; ibase=$src_tpye; $number" | bc

}

## 十六进制 转 十进制
function H-to-D()
{
	local number=$1
	local cpaString=

	if [[ ""${number}"" ]]; then
		cpaString=`echo ${number} | tr [a-z] [A-Z]`

		obase 10 16 ${cpaString}
	else
		show_vir "please input args ... eg: H-to-D ff"
	fi
}

## 十进制  转 十六进制
function D-to-H()
{
	local number=$1

	if [[ ""${number}"" ]]; then
		obase 16 10 ${number}
	else
		show_vir "please input args ... eg: D-to-H 9"
	fi
}

## 十进制  转 二进制
function D-to-B()
{
	local number=$1

	if [[ ""${number}"" ]]; then
		obase 2 10 ${number}
	else
		show_vir "please input args ... eg: H-to-B 9"
	fi
}

## 二进制  转 十进制
function B-to-D()
{
	local number=$1

	if [[ ""${number}"" ]]; then
		obase 10 2 ${number}
	else
		show_vir "please input args ... eg: H-to-D 1010101000"
	fi
}

## 获取那天是星期几
function get_week()
{
	local month_name=( [1]='Jan' [2]='Feb' [3]='Mar' [4]='Apr' [5]='May' [6]='Jun' [7]='Jul' [8]='Aug' [9]='Sep' [10]='Oct' [11]='Nov' [12]='Dec' )

	local year=$1
	local month=${month_name[$2]}
	local date=$3

	if [[ $# -eq 3 ]];then

        if [[ -n $1 ]]; then
            year="$1"
        else
            __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
        fi

        if [[ -n $2 ]]; then
            month=${month_name["$2"]}
        else
            __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
        fi

        if [[ -n $3 ]]; then
            date="$3"
        else
            __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
        fi

        if [[ -n ${month} && -n ${date} && -n ${year} ]]; then
		    date --date "${month} ${date} ${year}" +%A
		else
		    __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
        fi
	else
        echo ""
        echo "${FUNCNAME[0]} [args1] [args2] [args3] ..."
        echo
        echo "    args1 : 年"
        echo "    args2 : 月"
        echo "    args3 : 日"
        echo
        echo "    e.g."
        echo "        1. ${FUNCNAME[0]} 2018 3 7"
        echo
        return 0
	fi

	if false;then
		for m in ${month[@]}
		do
			date --date "$m 1 2015" +%A
		done
	fi
}

## 远程拷贝
function cpfs()
{
    local filefs=$1
    local hostN=$2

    local base_p=""
    local yafeng_p=""
    local server_p=""

    if [[ "$#" -eq 2 ]];then
        :
    else
        __err "参数不正确..."
    fi

    if [[ "`hostname`" == "happysongs" ]];then
        ## 本机拷贝服务器
        base_p=`echo ${td} | awk -F '/' '{ printf "%s/%s/%s\n", $4, $5, $6 }'`
    else
        ## 服务拷贝服务器或本机
        base_p=`echo ${td} | awk -F '/' '{ printf "%s/%s/%s\n", $5, $6, $7 }'`
    fi

    yafeng_p=/home/yafeng/${base_p}
    server_p=/work/home/jenkins/${base_p}

    if [[ -n "$filefs" && -n "$hostN" ]];then

        if [[ "$hostN" == "happysongs" ]];then
            scp -r yafeng@${hostN}:${yafeng_p}/${filefs} .
        else
            scp -r jenkins@${hostN}.y:${server_p}/${filefs} .
        fi

    else
        echo "e.g cpfs file_name hostname"
    fi
}

# download ssh file
function download_ssh_file() {

    local path=${1:-}
    local ssh_p='/local/workspace/android-bld/ssh-jenkins.zip'

    if [[ -z ${path} ]]; then
        log error 'The path is null ...'
    fi

    scp -P 8089 android-bld@10.129.93.30:${ssh_p} ${path}
}