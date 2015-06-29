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
