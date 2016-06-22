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
hostN=`hostname`

if [ -d $script_path ];then
	source $script_path/vendorsetup.sh
fi

### update zzzzz-script
source $script_path/chiphd_script_update.sh

### misc
source $script_path/chiphd_misc.sh

if [ $hostN == "s1" -o $hostN == "s2" -o $hostN == "s3" -o $hostN == "s4" -o $hostN == "happysongs" -o $hostN == "siawen" ];then
    update-chiphd-script
    mkdir_data_folder
fi

if [ $hostN == "s3" ];then
    auto_running_jenkins
fi
