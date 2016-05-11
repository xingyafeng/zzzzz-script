#######################################
#
#
#	author: yafeng
#	date: 2015--7-20
#
#
######################################

#!/bin/bash

####################################################### commond

###commond
workspace=~/workspace
script_path=$workspace/script/zzzzz-script

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

da=$workspace/date
time_date=`date +%m%d`
td=$da/$time_date

if [ -d $script_path ];then
	source $script_path/vendorsetup.sh
fi

if [ ! -e "$da/$time_date" ];then
	mkdir -p $da/$time_date
fi

unset PS1
export PS1="$pwd_green$pwd_bold\u@\h$pwd_purple$pwd_bold $pwd_purple$pwd_bold\w $ $pwd_default"

hostname_jenkins=`hostname`
if [ $hostname_jenkins == "s1" -o $hostname_jenkins == "s2" -o $hostname_jenkins == "s3" -o $hostname_jenkins == "s4" ];then
    update-chiphd-script
fi

if false;then
	mount_share_path=`mount | grep share_workspace | cut -d ' ' -f 3`
	mount_share_path=${mount_share_path##*/}

	if [[ "$mount_share_path" != "share_workspace" ]]; then
		sudo mount -t vboxsf ubuntu /home/yafeng/share_workspace
	fi
fi
