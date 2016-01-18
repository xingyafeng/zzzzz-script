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
### a
abox=/a
unset ps
unset pr
unset da

ps=$abox/0ps
pr=$abox/3pr
da=$abox/5da

### b
bbox=/b

### c
cbox=/c
code=/c/code

####
script_path=/a/0ps/zzzzz-script

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

time_date=`date +%m%d`
td=$da/$time_date

if [ -d $script_path ];then
	source $script_path/vendorsetup.sh
fi

if [ ! -e "$da/$time_date" ];then
	mkdir $da/$time_date
fi
unset PS1
export PS1="\[\e[35m\]\[\e[1m\]\w $ \[\e[0m\]"