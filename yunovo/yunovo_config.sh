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

## 更新zzzzz-script脚本
function update_script()
{
    local nowPwd=$(pwd)
    local git_project_name=xyf/zzzzz-script

    if [[ -d ${script_p}/.git ]]; then
        recover_standard_git_project "${script_p}"

        cd ${script_p} > /dev/null

        if [[ "master" == "`git branch | grep \* | cut -d ' ' -f2`" ]]; then
            git pull
         else
             git checkout master && git pull
         fi
     else
         git clone -b master ssh://${git_username}@${gerrit_server}:${gerrit_port}/${git_project_name}
     fi

     cd ${nowPwd} > /dev/null
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

## 设置命令别名
function set_alias()
{
    ### grep
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    # some more ls aliases
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
}

