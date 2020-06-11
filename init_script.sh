######################################
#
#
#	author: yafeng
#	date  : 2015-07-20
#
#
######################################

#!/bin/bash

###################################### commond
tmpfs=~/.tmpfs
workspace_p=~/workspace
script_p=${workspace_p}/script/zzzzz-script

if [[ ! -d ${tmpfs} ]];then
    mkdir -p ${tmpfs}
fi

if [[ ! -d ${script_p}/fs ]];then
    mkdir -p ${script_p}/fs
fi

### 初始化入口
if [[ -d ${script_p} ]];then
	source ${script_p}/vendorsetup.sh
fi

if [[ "`is_yunovo_server`" == "true" ]];then

    if [[ -f ${tmpfs}/yf.lock ]];then
        echo "fatal: ${tmpfs}/yf.lock': File exists."
    else
        update_script
    fi

    mkdir_data_folder
    set_alias
else
    :
    #__err "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    #return 0
fi

## set git coding
setgitencoding

if [[ "`hostname`" == "s2" ]];then
    auto_start_jenkins
fi

