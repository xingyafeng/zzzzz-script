#!/usr/bin/env bash

#### define PS1 env color
export pwd_black='\[\e[30m\]'
export pwd_red='\[\e[31m\]'
export pwd_green='\[\e[32m\]'
export pwd_yellow='\[\e[33m\]'
export pwd_blue='\[\e[34m\]'
export pwd_purple='\[\e[35m\]'
export pwd_cyan='\[\e[36m\]'
export pwd_white='\[\e[37m\]'
export pwd_default='\[\e[0m\]'
export pwd_bold='\[\e[1m\]'

unset PS1
export PS1="$pwd_green$pwd_bold\u@\h$pwd_purple$pwd_bold $pwd_purple$pwd_bold\w $ $pwd_default"

function mkdir_data_folder()
{
    local da=$workspace/date
    local time_date=`date +%m%d`
    local td=$da/$time_date

    if [ ! -e "$da/$time_date"  ];then
        mkdir -p $da/$time_date
    fi
}

function auto_running_jenkins()
{
    local jenkins_war_path=/home/work5/jenkins/jenkins.war
    local jenkins_war=jenkins.war

    if [ -f $jenkins_war_path ];then

        if [ "`ps aux | grep jenkins.war | grep -v "color=auto" | awk '{print $13}'`" != "$jenkins_war" ];then
            java -jar $jenkins_war_path --httpPort=8089 --daemon
        fi
    else
        echo " $jenkins_war_path is no found ..."
    fi

}

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
