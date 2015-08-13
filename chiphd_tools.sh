###########################################
#
#		commom tools by yafeng 2015-08-13
#
##########################################

#!/bin/bash

ssh_path=~/.ssh
ssh_aw_path=~/ssh_yafeng
ssh_yfk_path=~/ssh_yfk

function change_ssh
{
	if [ -L $ssh_path ];then	
		rm $ssh_path
	fi
	
	if [ $1 = "aw" ];then
		ln -s /home/abc/ssh_aw/ /home/abc/.ssh
	elif [ $1 = "yfk" ];then
		ln -s /home/abc/ssh_inphic/ /home/abc/.ssh
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

function mount_diyomate
{
	mount_project diyomate 11 123
}

diyomate_path=/mnt/diyomate

function cdiyomate
{
	cd $diyomate_path
}
