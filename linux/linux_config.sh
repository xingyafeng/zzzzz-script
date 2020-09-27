#!/usr/bin/env bash

#### define PS1 env color
BLACK='\[\e[30m\]'
RED='\[\e[31m\]'
GREEN='\[\e[32m\]'
YELLOW='\[\e[33m\]'
BLUE='\[\e[34m\]'
PURPLE='\[\e[35m\]'
CYAN='\[\e[36m\]'
WHITE='\[\e[37m\]'
EDN='\[\e[0m\]'
BOLD='\[\e[1m\]'

unset PS1
export PS1="$GREEN$BOLD\u@\h$PURPLE$BOLD $PURPLE$BOLD\w $ $EDN"

## 创建时间日期目录结构
function mkdir_data_folder()
{
    if [[ ! -d "$td"  ]];then
        mkdir -p "$td"
    fi
}

## 下载或更新zzzzz-script
function update_script()
{
    git_sync_repository gcs_sz/zzzzz-script master `dirname ${script_p}`
}

## 开机自动启动jenkins
function auto_start_jenkins
{
    local jenkins_war_p=${share_p}/tools/jenkins.war

    if [[ -f ${jenkins_war_p} ]];then
        if [[ "`ps aux | grep "jenkins.log" | grep ${jenkins_war_p} | grep -v grep`" != "" ]];then
            __green__ "jenkins is running ..."
        else
            java -Dfile.encoding=UTF-8 -jar ${share_p}/tools/jenkins.war --daemon --httpPort=8089 --logfile=${tmpfs}/jenkins.log --sessionTimeout=1440 --sessionEviction=43200 -DsessionTimeout=1440
        fi
    fi
}

#####################################################
##
##  函数: init_script_path
##  功能: 创建需要新建的路径
##
##  描述: 新建在脚本使用中需要的各种文件夹
##
####################################################
function init_script_path() {

    unset pathfs

    pathfs[${#pathfs[@]}]=${tmpfs}
    pathfs[${#pathfs[@]}]=${version_p}
    pathfs[${#pathfs[@]}]=${tmpfs}/log
    pathfs[${#pathfs[@]}]=${tmpfs}/ota
    pathfs[${#pathfs[@]}]=${tmpfs}/zip
    pathfs[${#pathfs[@]}]=${tmpfs}/gerrit
    pathfs[${#pathfs[@]}]=${apk_release_p}
}