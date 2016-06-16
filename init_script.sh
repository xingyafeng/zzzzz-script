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
hostname_jenkins=`hostname`

if [ -d $script_path ];then
	source $script_path/vendorsetup.sh
fi

### update zzzzz-script
source $script_path/chiphd_script_update.sh

### misc
source $script_path/chiphd_misc.sh

if [ $hostname_jenkins == "s1" -o $hostname_jenkins == "s2" -o $hostname_jenkins == "s3" -o $hostname_jenkins == "s4" -o $hostname_jenkins == "happysongs" ];then
    update-chiphd-script
    mkdir_data_folder
fi

if [ $hostname_jenkins == "s3" ];then
    auto_running_jenkins
fi
