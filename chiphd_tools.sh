###########################################
#
#		commom tools by yafeng 2015-08-13
#
##########################################

#!/bin/bash

function DEBUG()
{
	[ "$_DEBUG" == "on" ] && $@ || :
}

ssh_path=~/.ssh

function change_ssh
{
	if [ -L $ssh_path ];then	
		rm $ssh_path
	fi
	
	if [ $1 = "aw" ];then
		ln -s /home/abc/ssh_aw/ /home/abc/.ssh
	elif [ $1 = "yfk" ];then
		ln -s /home/abc/ssh_inphic/ /home/abc/.ssh
	elif [ $1 = "dymt" ];then
		ln -s /home/abc/ssh_diyomate/ /home/abc/.ssh
	else
		show_vir "please input args[0] ..."
	fi
}

function change_repo
{
	if [ -L /a/3pr/repo/repo ]; then
		rm /a/3pr/repo/repo
	fi
	
	if [ $1 = "aw" ];then
		ln -s /a/3pr/repo/repo_allwinner /a/3pr/repo/repo
	elif [ $1 = "yfk" ];then
		ln -s /a/3pr/repo/repo.aliyunos.yfk /a/3pr/repo/repo
	elif [ $1 = "dymt" ];then
		ln -s /a/3pr/repo/repo.aliyunos.diyomate /a/3pr/repo/repo
	fi
}

function change_ps
{
	change_ssh $1
	change_repo $1
}

function switch_usb_mode
{
	if [ $1 = "d" ];then
		adb shell cat sys/bus/platform/devices/sunxi_usb_udc/usb_device
	elif [ $1 = "h" ];then
		adb shell cat /sys/bus/platform/devices/sunxi_usb_udc/usb_host
	fi

}

function setgitconfig
{
	if [ "$1" ];then
		git config --global  user.name $1
	else
		git config --global  user.name yafeng
	fi

	git config --global  user.email box@chiphd.com
	git config --global  alias.st status
	git config --global  alias.br branch
	git config --global  alias.co checkout
	git config --global  alias.ci commit
	git config --global  alias.date iso
	git config --global  core.editor vim
	git config --global alias.lg "log --date=short --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %C(green)%s %C(reset)(%cd) %C(bold blue)<%an>%Creset' --abbrev-commit"
}

function get_modify_file
{
	local this_android_path=$(gettop)
	local modify_file_path=

	modify_file_path=`repo status | awk '$1=="project" && NF > 2 {prj=$2} $1 !~ "d" && NF==2 && $2 !~ "preApk/system/app-lib" {printf "android/%s%s\n",prj,$2 }'`

	if [ "$modify_file_path" ];then

		cd ..
		tar zcf $td/modify.tar.gz $modify_file_path

		if [ -f $td/modify.tar.gz ];then

			if [ -d $td/android ];then
				rm $td/android -rf
			fi

			tar zxf $td/modify.tar.gz -C $td

			if [ $? -eq 0 ];then
				rm $td/modify.tar.gz
			fi
		fi
	fi
	cd $this_android_path
}

function mount_diyomate
{
	mount_project diyomate 11 123
}

diyomate_path=/mnt/diyomate

function cdiyomate
{
	cd $diyomate_path
}
