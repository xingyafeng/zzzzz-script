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

### open file
openfs()
{
    local file_path=$1    

	if [ $# -eq 0 ];then		
		nautilus . &
	else
        if [ "$file_path" ];then
            nautilus $file_path &
        fi
	fi

	if [ "file_path" == "--help" ];then
		show_vip "----------help---------------"	
	fi
}

### find and grep
gfind()
{
    local files=$1

	if [ "$files" ];then
		find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "$files" -print
	else
		show_vip "please add only one arg, eg:gfind + string"
	fi
}

grepfs() 
{
    local files=$1

	if [ "$files" ];then
		find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.java' -o -name '*.xml' -o -name '*.sh' -o -name '*.mk' -o -name '*.rc' -o -name '*.cfg' -o -name 'Makefile' -o -name 'Kconfig' -o -name '*.sh' \) -print0 | xargs -0 grep --color -n $@
	else
		show_vip "what do you want to grep ?"
	fi
}

## rsync
function rsyncfs()
{
    sync_dryrun

    echo -n "Want to sync ? "
    read -p "Please Enter (Y/N):" sure

    if [ "x$sure" = "xy" ]; then
        show_vig "continue..."
    elif [ "x$sure" = "xyes" ]; then
        show_vig "continue..."
    elif [ "x$sure" = "xY" ]; then
        show_vig "continue..."
    elif [ "x$sure" = "xYES" ]; then
        show_vig "continue..."
    else
        show_vir "please enter Y or YES ..."
        return
    fi

    sync_server

    show_vip "-------------------------------"
    show_vip "-          rsync end          -"
    show_vip "-------------------------------"
}

sync_server()
{
    rsync -av --delete $da/yafeng/rsync-service/  boxbuilder@192.168.1.23:/home2/boxbuilder/0box_share/rsync-service/
}


sync_dryrun()
{
    rsync -av --delete $da/yafeng/rsync-service/  boxbuilder@192.168.1.23:/home2/boxbuilder/0box_share/rsync-service/ --dry-run
}

#### mount server
function mount-server
{
	mount_box
	mount_droid05
	mount_hbc
	mount_yj
}

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

function mount_diyomate
{
	mount_project diyomate 11 123
}

diyomate_path=/mnt/diyomate

function cdiyomate
{
	cd $diyomate_path
}
