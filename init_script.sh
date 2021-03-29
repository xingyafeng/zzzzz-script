#!/usr/bin/env bash
###########################################################
###
###				init functions
###
###
### date 	: 2015-05-20 10:12
### author  : yafeng
###
###########################################################

########################################################### commond var
# 临时路径
tmpfs=~/.tmpfs
#个人工作空间
workspace_p=~/workspace
#脚本路径
script_p=${workspace_p}/script/zzzzz-script

#------------------------------------------------------------------------------ 导入环境

if [[ -f ${script_p}/vendorsetup.sh ]];then
	source ${script_p}/vendorsetup.sh
fi

#------------------------------------------------------------------------------ 准备环境

if [[ "$(is_build_server)" == "true" ]];then
    if [[ -f ${tmpfs}/yf.lock ]];then
#        echo "fatal: ${tmpfs}/yf.lock': File exists."
    :
    else
        #　下载或更新zzzzz-script脚本仓库
        if [[ $(is_connect_netwrok 'http://sz.gerrit.tclcom.com:8080') == "true" ]];then
            update_script
        fi
    fi

    #创建time目录
    mkdir_data_folder

    #配置别名
    set_alias

    #配置编码
    #setgitencoding

    #创建文件夹
    init_script_path
    enhance_create_dir
else
    log error "The server is not running on build server."
fi