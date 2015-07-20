#######################################
#
#
#	author: yafeng
#	date: 2015--7-20
#
#
######################################


#!/bin/bash

script_path=/a/0ps/zzzzz-script

time_date=`date +%m%d`
td=$da/$time_date

if [ -d $script_path ];then
	source $script_path/vendorsetup.sh
fi

if [ ! -e "$da/$time_date" ];then
	mkdir $da/$time_date
fi
