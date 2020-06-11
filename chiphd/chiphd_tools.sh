###########################################
#
#		commom tools by yafeng 2015-08-13
#
##########################################

#!/bin/bash

function flash-chip()
{
    local mtk_flash_tools=/home/yafeng/workspace/tools/Mtk_Tools/SP_Flash_Tool

    if [ -x $mtk_flash_tools/flash_tool ];then
        cd $mtk_flash_tools > /dev/null
        ./flash_tool &
    else
        show_vir "$mtk_flash_tools is not exist !!!"
    fi
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
		android_modify_file_path=`repo status | awk '$1=="project" && NF > 2 {prj=$2} $1 !~ "d" && NF==2 && $2 !~ "apps/*" && $2 !~ "mediatek/proprietary/scripts/*" {printf "android/%s%s\n",prj,$2 }'`

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

## rsync
function rsyncfs()
{
	local args=$1

    if [ "$args" ];then
        sync_dryrun_server
    else
        sync_dryrun_local
    fi

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

	if [ "$args" ];then
		show_vig "local path : ~/jenkins_firmware "
	else
		show_vig "server path : jenkins@s4.y:~/workspace/share/debug "
    fi

    if [ "$args" ];then
		sync_pull_server

	    show_vip "------------------------------------"
		show_vip "-          rsync pull end          -"
		show_vip "------------------------------------"
    else
		sync_push_server

		show_vip "------------------------------------"
		show_vip "-          rsync push end          -"
		show_vip "------------------------------------"
    fi
}

### 同步本地内容
sync_push_server()
{
    rsync -av --delete ~/jenkins_firmware jenkins@s4.y:~/workspace/share/debug
}

### 同步服务上的内容
sync_pull_server()
{
    rsync -av --delete jenkins@s4.y:~/workspace/share/debug ~/jenkins_firmware
}

### 判断文件是否真要删除 服务器的内容
sync_dryrun_local()
{
    rsync -av --delete ~/jenkins_firmware jenkins@s4.y:~/workspace/share/debug --dry-run
}

### 判断文件是否真要删除 本地内容
sync_dryrun_server()
{
    rsync -av --delete jenkins@s4.y:~/workspace/share/debug ~/jenkins_firmware --dry-run
}

#### mount server
function mount-server
{
    mount_box
}

function mount_box()
{
	mount_project boxbuilder 23 123456
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

function git-tag-for-app()
{
    local OLDP=`pwd`
    local app_file=$config_p/allapp.txt
    local commit_msg=$script_p/commit-msg
    local git_hook=.git/hooks
    local app_path=packages/apps
    local ssh_link=ssh://xingyafeng@gerrit2.y:29418
    local tag_version=$1
    local branch_name=$2

    if [ ! "`is_yunovo_project`" == "true" ];then
        return 1
    fi

    if [ $# != 2 ];then
        show_vir "---------------------------------------"
        show_vir " please eg: git-tag-for-app 1.00 master"
        show_vir "---------------------------------------"
        return 1
    fi

    cd $app_path > /dev/null

    while read app_name
    do
		#echo ${app_name}
		if [ -d $app_name ];then
			cd $app_name > /dev/null

            if [ ! -e $git_hook/commit-msg ];then
                cp $commit_msg $git_hook
                chmod +x $git_hook/commit-msg
            fi

            if [ $branch_name == "long" ];then
                if [ $app_name == "CarEngine" -o $app_name == "CarRecordDouble" ] ;then
                    if [ "`git branch -a | grep \* | cut -d ' ' -f2`" != "long"  ];then
                        git checkout long
                        git pull && echo "-------------- pull $app_name"
                        echo
                    else
                        git pull && echo "-------------- pull $app_name"
                        echo
                    fi

                    ### 新增加tag
                    if [ ! "`git tag | grep L$tag_version`" ];then
                        git tag -m "Release L$tag_version" L$tag_version
                        git push origin --tags
                    fi
                else
                    if [ "`git branch -a | grep \* | cut -d ' ' -f2`" != "master" ];then
                        git checkout master
                        git pull && echo "-------------- pull $app_name"
                        echo
                    else
                        git pull && echo "-------------- pull $app_name"
                        echo
                    fi

                    ### 新增加tag
                    if [ ! "`git tag | grep M$tag_version`" ];then
                        git tag -m "Release M$tag_version" M$tag_version
                        git push origin --tags
                    fi
                fi
            elif [ $branch_name == "master" ];then
                if [ "`git branch -a | grep \* | cut -d ' ' -f2`" != "master" ];then
                    git checkout master
                    git pull && echo "-------------- pull $app_name"
                    echo
                else
                    git pull && echo "-------------- pull $app_name"
                    echo
                fi

                ### 新增加tag
                if [ ! "`git tag | grep M$tag_version`" ];then
                    git tag -m "Release M$tag_version" M$tag_version
                    git push origin --tags
                fi
            fi

            if false;then
                if [ $branch_name == "master" ];then
                    if [ "`git tag | grep M$tag_version`" ];then
                        if [ "`git branch -a | grep \* | cut -d ' ' -f2`" == "master" ];then
                            git tag -d M$tag_version
                        fi
                    fi
                elif [ $branch_name == "long" ];then
                    if [ "`git tag | grep L$tag_version`" ];then
                        if [ "`git branch -a | grep \* | cut -d ' ' -f2`" == "long" ];then
                            git tag -d L$tag_version
                        elif [ "`git branch -a | grep \* | cut -d ' ' -f2`" == "master" ];then
                            git tag -d M$tag_version
                        fi
                    fi
                fi
            fi

            git tag -n
            show_vir '---------------------------------------------'

            cd .. > /dev/null
		else
			git clone $ssh_link/$app_name
			show_vig "-------------- sync_dryrun_localne $app_name"
            echo
        fi
    done < $app_file

    echo
    show_vig git-tag-for-app end ...
    echo
    cd $OLDP > /dev/null
}

function open-terminal()
{
    gnome-terminal --window --title=s5 --tab --title=s4 --tab --title=s3 --tab --title=s2 --tab --title=s1 --tab --title=happysongs --tab --title=p1 --tab --title=Test
}
