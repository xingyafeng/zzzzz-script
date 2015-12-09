#!/bin/bash

####################################################### define
### project name
eagle44=eagle44-h8
dolphin44=dolphin44-h3
debug44=debug44-h8
qin244=qin244-h38
qin244_d=q2442g_v1.0_d
yunos21=yunos2.1.2
yunos=/mnt/diyomate/yunos2.1.2

test44=test

### common use  a
swork_path=$ps/swork
script_path=$ps/zzzzz-script

sbox_path=$mh/box
sworkspace_path=$mh/workspace
qin2_path=$sbox_path/qin244-h38
yunos_path=$sbox_path/yunos2.1.4
yafeng_path=$td/../yafeng
qn_path=/a/0ps/qn_sync_folder

### project path for b
eagle_path=$ps/eagle44-h8
dolphin_path=$ps/dolphin44-h3

### common use c
scode_path=/c/code/
yunos2_1_2_path=$scode_path/yunos2.1.2
yunos2_2_0_path=$scode_path/yunos2.2.0
qin2_sdk_path=$scode_path/q2442g_v1.0_d
### other important path
sdate=$td


### args
pro_name=
pro_type=
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

#h38
function cqin2
{
	cd $qin2_sdk_path
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
	cd $yunos_path
}

function cyafeng
{
	cd $yafeng_path
}

function ccode
{
	cd $scode_path
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





