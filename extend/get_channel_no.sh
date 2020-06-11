#!/usr/bin/env bash

# if error;then exit
set -e

##------------------------------------------- 仓库信息

# 仓库路径
GITRES=""
# 仓库分支
GITRES_BRANCH=""

# 渠道号
declare -a channel_no

## 设置JAVA环境变量
unset -v JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH
export LANGUAGE=en_US
export LC_ALL=en_US.UTF-8

## ------------------------------------------- 公共

##临时目录
tmpfs=~/.tmpfs

git_username="`git config --get user.name`"
gerrit_server="gerrit.y"
gerrit_port="29419"

## 获取文本中字符串所在的行号
function get_line_from_file()
{
    local file_name=$1
    local string=$2

    if [[ $# -ne 2 ]];then
        log error "$# is error, please check args!"
    fi

    sed -n "/^${string}/=" ${file_name}
}

## 拿到产品版本号信息存到文件中
function get_product_version()
{
    local start_line=
    local end_line=

    ${tmpfs}/config/tools/gradle/gradle-4.1/bin/gradle -q productInfoTask > ${tmpfs}/tmp_product_version.txt
    #cat $tmpfs/tmp_product_version.txt

    if [[ -f ${tmpfs}/tmp_product_version.txt ]];then

        start_line=$(get_line_from_file ${tmpfs}/tmp_product_version.txt "product info parse start")
        end_line=$(get_line_from_file ${tmpfs}/tmp_product_version.txt "product info parse end")

        #echo " --- from $start_line to $end_line ----"
        if [[ -n "${start_line}" && -n "${end_line}" ]]; then
            sed -n "$((start_line+1)),$((end_line-1))"p ${tmpfs}/tmp_product_version.txt  > ${tmpfs}/current_product_version.txt
        else
            echo > ${tmpfs}/current_product_version.txt
        fi

        ## 清除临时文件
        rm -rf ${tmpfs}/tmp_product_version.txt
    fi
}

## 获取渠道号
function get_channel_no()
{
    local OPWD=$(pwd)
    unset channel_no

    cd ${tmpfs}/${GITRES##*/} > /dev/null

    get_product_version

    while read no;do
        channel_no[${#channel_no[@]}]=${no%:*}
    done < ${tmpfs}/current_product_version.txt

    if [[ ${#channel_no} -eq 0 ]]; then
        channel_no[${#channel_no[@]}]="common"
    fi

    echo ${channel_no[@]}

    cd ${OPWD} > /dev/null
}

function main()
{
    if [[ -n "$1" ]]; then
        GITRES=$1
    else
        echo "参数1为空."
    fi

    if [[ "$#" -ne 1 ]]; then
        echo ""
        echo "$0 options [ string ] "
        echo
        echo "    options : "
        echo "      $0 git_path ## 获取当前apk的渠道号."
        echo
        echo "    e.g. $0 nxos/nxTraffic "
        echo
        return 1
    fi

    ## 获取对应项目的渠道号
    get_channel_no
}

main "$@"