###
###
###

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
		ln -s /home/abc/ssh_yafeng/ /home/abc/.ssh
	elif [ $1 = "yfk" ];then
		ln -s /home/abc/ssh_yfk/ /home/abc/.ssh
	else
		show_vir "please input args[0] ..."
	fi
}

function switch_usb_mode
{
	if [ $1 = "d" ];then
		adb shell cat sys/bus/platform/devices/sunxi_usb_udc/usb_device
	elif [ $1 = "h" ];then
		adb shell cat /sys/bus/platform/devices/sunxi_usb_udc/usb_host
	fi

}
