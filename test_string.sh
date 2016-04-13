#!/bin/bash

test-string()
{
	local var=chiphd

	# get string length
	local length=${#var}	

	show_vir $length
}


test-reboot()
{
	###
	echo reboot
}

test-jenkins()
{
	share_path=~/workspace/share_jenkins
	cur_time=`date +%m%d_%H%M`
	app_name=CarBack
	app_version=`cat $app_name/AndroidManifest.xml | grep android:versionName= | awk -F '"' '{print $2}'`

	if [[ ! -d $share_path/CarBack ]]; then
		#statements
		mkdir -p $jenkins_path/CarBack/
		if [[ $? -eq 0 ]]; then
			#statements
			cp output/CarBack.apk  $jenkins_path/CarBack/CarBack_$cur_time_$app_version.apk
		fi
	fi
}

