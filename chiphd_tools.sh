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

function change_ssh
{
	local ssh_path=~/.ssh
	local project_name=$1

	if [ -L $ssh_path ];then
		rm $ssh_path
	fi
	
	if [ $project_name = "aw" ];then
		ln -s ~/ssh_${project_name} $ssh_path
	elif [ $1 = "yfk" ];then
		ln -s /home/abc/ssh_${project_name} $ssh_path
	elif [ $1 = "dymt" ];then
		ln -s /home/abc/ssh_${project_name} $ssh_path
	else
		show_vir "please input args[0] ..."
		show_vir "change_ssh_ (aw, yfk, dymt )"
	fi
}

function change_repo
{
	local repo_path=$pr/repo
	local project_name=$1
	
	if [ -L $repo_path/repo ]; then
		rm $repo_path/repo
	fi

	if [ $project_name = "aw" ];then
		ln -s $repo_path/repo_${project_name} $repo_path/repo
	elif [ $project_name = "yfk" ];then
		ln -s $repo_path/repo.aliyunos.${project_name} $repo_path/repo
	elif [ $project_name = "dymt" ];then
		ln -s $repo_path/repo.aliyunos.${project_name} $repo_path/repo
	else
		show_vir "please input args[0] ..."
		show_vir "change_repo_ (aw, yfk, dymt )"
	fi
}

function change_ps
{
	if [ "$1" ];then
		change_ssh $1
		change_repo $1
	else
		show_vir "please input args[0] ..."
		show_vir "change_ps_ (aw, yfk, dymt )"
	fi
}

function setgitconfig
{
	local your_name=$1

	if [ "$your_name" ];then
		git config --global  user.name $your_name
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

function get_android_and_lichee__modify_file
{
	local hold_project=$2
	local now_date=`date +%y%m%d`

	show_vip $date_tar
	cd ..
	tar zcf $td/modify.tar.gz $1

	if [ -f $td/modify.tar.gz ];then

		if [ $hold_project == "android" ];then
			if [ -d $td/android ];then
				rm $td/android -rf
			fi

			tar zxf $td/modify.tar.gz -C $td
			mv $td/modify.tar.gz $td/modify_${hold_project}_20${now_date}.tar.gz
		elif [ $hold_project == "lichee" ];then
			if [ -d $td/lichee ];then
				rm $td/lichee -rf
			fi

			tar zxf $td/modify.tar.gz -C $td
			mv $td/modify.tar.gz $td/modify_${hold_project}_20${now_date}.tar.gz
		fi
	fi
}

function get_modify_file
{
	local this_sdk_path=`pwd`
	local android_modify_file_path=
	local lichee_modify_file_path=

	if [ "$this_sdk_path" ];then
		this_sdk_path=${this_sdk_path##*/}
	#	show_vig $this_sdk_path
	else
		show_vig "this path do not eaxit, please checkout input args ..."
	fi

	if [ $this_sdk_path == "android" ];then
		android_modify_file_path=`repo status | awk '$1=="project" && NF > 2 {prj=$2} $1 !~ "d" && NF==2 && $2 !~ "preApk/system/app-lib" {printf "android/%s%s\n",prj,$2 }'`

		if [ "$android_modify_file_path" ];then
			get_android_and_lichee__modify_file "$android_modify_file_path" $this_sdk_path
		fi
	elif [ $this_sdk_path == "lichee" ];then
		lichee_modify_file_path=`repo status | awk '$1=="project" && NF >2 {prj=$2} NF==2 && $1 !~ "d" && $2 !~ ".bin" && $2 !~ "cur.log" {printf "lichee/%s%s\n", prj, $2}'`

		if [ "$lichee_modify_file_path" ] ;then
			get_android_and_lichee__modify_file "$lichee_modify_file_path" $this_sdk_path
		fi
	fi
	cd $this_sdk_path
}

### edit file
function geditfs
{
	local tmp=$1

	if [ "$tmp" ];then
		gedit $1 &
	fi
}

### get app package name
function get_package_name()
{
	local apk_name=$1

	if [ "$apk_name" ];then
		aapt dump badging $apk_name | grep name= | sed 's%.*name=%%'  | sed 's% .*%%'
	fi
}

#### 恢复默认配置文件 android
function recover_standard_android_project()
{
	local tOldPwd=$OLDPWD
	local tNowPwd=$PWD
	cd $(gettop)
	#echo "now get all project from repo..."

	local AllRepoProj=`chiphd_get_repo_git_path_from_xml`
    #show_vip $AllRepoProj
	if [ "$AllRepoProj" ]; then
		for ProjPath in $AllRepoProj
		do
            if [ -d $(gettop)/$ProjPath ];then
			    chiphd_recover_project $ProjPath
            fi
		done
	fi
	cd $tOldPwd
	cd $tNowPwd
}

#### 恢复默认配置文件 lichee
function recover_standard_lichee_project()
{
	local tOldPwd=$OLDPWD
	local tNowPwd=$PWD
    local licheePwd=$(gettop)/../lichee
	cd $(gettop)
	#echo "now get all project from repo..."
	local AllRepoProj=`chiphd_get_repo_git_path_from_xml_lichee`
    echo $AllRepoProj
	if [ "$AllRepoProj" ]; then
		for ProjPath in $AllRepoProj
		do
			if [ -d "$licheePwd/$ProjPath" ]; then
				chiphd_recover_project_lichee $ProjPath
			fi
		done
	fi
	cd $tOldPwd
	cd $tNowPwd
}


function recover_sdk()
{
    if [ "`is_make_project`" = "true" ];then
        recover_standard_android_project
        show_vir "-------------------------------------------------------------------------------------"
	    recover_standard_lichee_project
    fi
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
