#!/bin/bash

####################################################### define
### project name
eagle44=eagle44-h8
dolphin44=dolphin44-h3
debug44=debug44-h8
yunos=/mnt/diyomate/yunos2.1.2

test44=test
### common use  a
swork_path=$ps/swork
script_path=$ps/zzzzz-script

### project path for a
eagle_path=$ps/eagle44-h8
dolphin_path=$ps/dolphin44-h3

### common use  c
sbox_path=$me/box
sworkspace_path=$me/workspace

### other important path
sdate=$td

################################################### function
### shortcut for cd

#h3
function ceagle
{
	cd $eagle_path
}

#h8
function cdolphin
{
	cd $dolphin_path
}

######for commont path
function cscript
{
	cd $script_path
}

function cswork
{
	cd  $swork_path
}

function cbox
{
	cd $sbox_path
}

function cworkspace
{
	cd $sworkspace_path
}

function cproject
{
	cd $ps
}

function cdate
{
	cd $sdate
}

function cyunos
{
	cd $yunos
}

### login ssh server 
function box
{
	ssh boxbuilder@192.168.1.23
}

function gittt
{
	ssh git@192.168.1.20
}

function droid05
{
	ssh droid05@192.168.1.23
}

function hbc
{
	ssh hbc@192.168.1.20
}

function diyomate
{
	ssh diyomate@192.168.1.11
}

#### mount server
mount_box()
{
	mount_project boxbuilder 23 123456
}

mount_droid05()
{
	mount_project droid05 23 123456
}

mount_hbc()
{
	mount_project hbc 20 hbc
}

mount_yj()
{
	mount_project yj 22 123456
}

function mount-chiphd
{
	mount_box
	mount_droid05
	mount_hbc
	mount_yj
}

### mount base function
function mount_project
{
	local server_name=$1
	local server_no=$2
	local server_key=$3
	
	if [ $# -lt 3 ];then
		show_vir "please input three arsg."
		show_vir "eg : mount_project droid05 23 123456"
		show_vir "please eg: mount_project  服务器名称 + 服务器地址 + 密码"
		return 1;
	fi
	
	if [ ! -d /mnt/$server_name ];then
		sudo mkdir /mnt/$server_name
		if [ $? -eq 0 ];then
			sudo mount -t cifs -o username=$server_name,password=$server_key,rw,uid=abc,gid=abc //192.168.1.$server_no/$server_name /mnt/$server_name
		fi	
	else
		sudo mount -t cifs -o username=$server_name,password=$server_key,rw,uid=abc,gid=abc //192.168.1.$server_no/$server_name /mnt/$server_name
	fi
}

umount_box()
{
	umount_project boxbuilder/
}

umount_droid05()
{
	umount_project droid05/
}

umount_hbc()
{
	umount_project hbc/
}

umount_yj()
{
	umount_project yj/	
}

function umount-chiphd
{
	if	umount_box;then
		if umount_droid05;then
			if umount_hbc;then
				if umount_yj;then
					show_vig "safe exit..."		
				fi
			fi
		fi		
	fi
}

###### umount base function
function umount_project
{
	unset server_name
	server_name=$1

	if [ -d  /mnt/$server_name ];then
		if sudo umount /mnt/$server_name;then
			sudo rm $server_name -r		
		fi
	fi
}


### open file
open-file()
{
	if [ $# -eq 0 ];then		
		nautilus .			
	else
		nautilus $1
	fi

	if [ "$1" = "--help" ];then
		show_vip "----------hlep---------------"	
	fi
}

### find and grep
find-file()
{
	if [ $1 ];then
		find . -name \\$1
	else
		show_vip "====================================================="	
		show_vip "=   please add only one arg,eg:find-file + string   ="
		show_vip "====================================================="	
	fi
}

grep-file()
{
	if [ $1 ];then
		grep $1 ./ -rni
	else
		show_vip "====================================================="	
		show_vip "please add only one arg,eg:grep-file + string"
		show_vip "====================================================="	
	fi
}
