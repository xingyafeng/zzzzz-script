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

function loginjs()
{
	local jenkins_war_path=/home/work5/jenkins/jenkins.war
	local portN=

	if [[ -f $jenkins_war_path ]]; then
		#statements
		if [[ $portN ]]; then
			#statements   portN  != null
			java -jar $jenkins_war_path --httpPort=$portN --daemon
		else
			java -jar $jenkins_war_path --httpPort=8089 --daemon
		fi
	fi
}

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

function setvimconfig
{
	vim_path=~/.vim
	vimrc_path=~/.vimrc

	vim_flag=$1

	if [ -L $vim_path ]; then
		rm $vim_path
	fi

	if [ -L $vimrc_path ];then
		rm $vimrc_path
	fi

	if [ "$vim_flag" == "default" ];then
		ln -s ~/.vim.${vim_flag} $vim_path
		ln -s ~/.vimrc.${vim_flag} $vimrc_path
	elif [ "$vim_flag" == "vim" ];then
		ln -s /a/0ps/chiphd/install/vim $vim_path
		ln -s /a/0ps/vim/vimrc $vimrc_path
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

	git config --global  user.email xingyf@yunovo.cn
	git config --global  alias.st status
	git config --global  alias.br branch
	git config --global  alias.co checkout
	git config --global  alias.ci commit
	git config --global  alias.date iso
	git config --global  core.editor vim
	git config --global  color.ui true
#	git config --global  push.default simple
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
		android_modify_file_path=`repo status | awk '$1=="project" && NF > 2 {prj=$2} $1 !~ "d" && NF==2 && $2 !~ "apps/*" && $2 !~ "mediatek/proprietary/*" {printf "android/%s%s\n",prj,$2 }'`

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
	else
		show_vir "eg: get_package_name + apk_name"
	fi
}

function get_apk_info()
{
	local apk_name=$1

	if [ "$apk_name" ];then
		aapt dump badging $apk_name
	else
		show_vir "eg: get_package_name + apk_name"
	fi
}

function checkout_apk_4()
{
	local apk_name_before=$1
	local apk_name_after=${apk_name_before%.*}_after.apk

	#echo $apk_name_after

	if [ "$apk_name_before" -a "$apk_name_after" ]; then

		### 带参数 -v 显示内容
		if zipalign 4 $apk_name_before $apk_name_after;then
			zipalign -c -v 4 $apk_name_after | grep Verification
			show_vir ' $apk_name_after'
		fi
	else
		show_vir "eg:  checkout_apk_4 + apk ..."
	fi
}

#### checkout默认配置文件
function chiphd_recover_project()
{
	local tDir=$1
	if [ ! "$tDir" ]; then
		tDir=.
	fi
	if [ -d $tDir/.git ]; then
		local OldPWD=$(pwd)
		cd $tDir && echo "---- recover $tDir"

		git reset HEAD . ###recovery for cached files

		thisFiles=`git clean -dn`
		if [ "$thisFiles" ]; then
			git clean -df
		fi

#		thisFiles=`git diff --cached --name-only`
#		if [ "$thisFiles" ]; then
#			git checkout HEAD $thisFiles
#		fi

		thisFiles=`git diff --name-only`
		if [ "$thisFiles" ]; then
			git checkout HEAD $thisFiles
		fi
		cd $OldPWD
	fi
}

#### 获取所以git库路径,在android目录下调用
function chiphd_get_repo_git_path_from_xml()
{
	local default_xml=.repo/manifest.xml
	if [ -f $default_xml ]; then
		grep '<project' $default_xml | sed 's%.*path="%%' | sed 's%".*%%'
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
    if [ "`is_make_project`" == "true" ];then
        recover_standard_android_project
        show_vir "-------------------------------------------------------------------------------------"
	    #recover_standard_lichee_project
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

function cpfs()
{
    local sz_file=$1
    local sz_hostname=$2
    local sz_base_path=`echo $td | awk -F '/' '{ printf "%s/%s/%s\n", $4, $5, $6 }'`
    local sz_server_path=/home/jenkins/$sz_base_path
    local sz_yafeng_path=/home/yafeng/$sz_base_path

    #echo "sz_base_path = $sz_base_path"
    #echo "sz_server_path = $sz_server_path"

    if [ $sz_hostname == "s1" -o $sz_hostname == "s2" -o $sz_hostname == "s3" -o $sz_hostname == "s4" ];then
        scp -r jenkins@${sz_hostname}.y:$sz_server_path/$sz_file .
    elif [ $sz_hostname == "happysongs" ];then
        sz_hostname=10.0.0.18
        scp -r yafeng@${sz_hostname}:$sz_yafeng_path/$sz_file .
    else
        echo "checkout your server at s1.y s2.y s3.y s4.y ..."
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

## rename photo modify bootanimation.zip
function renamefs
{
	local count=1

	for old_photo_name in `find . -iname "*.png" -o -iname "*.jpg" -type f | sort`; do
		#statements
        if [ $count -lt 10 ];then
		    new_photo_name=000$count.${old_photo_name##*.}
        elif [ $count -lt 100 ];then
		    new_photo_name=00$count.${old_photo_name##*.}
        elif [ $count -lt 1000 ];then
		    new_photo_name=0$count.${old_photo_name##*.}
        fi

        #show_vir "renamephoto $old_photo_name to $new_photo_name"
		mv "$old_photo_name" "$new_photo_name"

		let count++
	done
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

obase()
{
	local dest_type=$1
	local src_tpye=$2
	local number=$3

	echo "obase=$dest_type; ibase=$src_tpye; $number" | bc

}

## 十六进制 转 十进制
function H-to-D()
{
	local number=$1
	local cpaString=

	if [[ ""$number"" ]]; then
		cpaString=`echo $number | tr [a-z] [A-Z]`

		obase 10 16 $cpaString
	else
		show_vir "please input args ... eg: H-to-D ff"
	fi
}

## 十进制  转 十六进制
function D-to-H()
{
	local number=$1

	if [[ ""$number"" ]]; then
		obase 16 10 $number
	else
		show_vir "please input args ... eg: D-to-H 9"
	fi
}

## 十进制  转 二进制
function D-to-B()
{
	local number=$1

	if [[ ""$number"" ]]; then
		obase 2 10 $number
	else
		show_vir "please input args ... eg: H-to-B 9"
	fi
}

## 二进制  转 十进制
function B-to-D()
{
	local number=$1

	if [[ ""$number"" ]]; then
		obase 10 2 $number
	else
		show_vir "please input args ... eg: H-to-D 1010101000"
	fi
}

function get_week()
{
	local month_name=( [1]='Jan' [2]='Feb' [3]='Mar' [4]='Apr' [5]='May' [6]='Jun' [7]='Jul' [8]='Aug' [9]='Sep' [10]='Oct' [11]='Nov' [12]='Dec' )
	local month=${month_name[$1]}
	local date=$2
	local year=$3

	if [ "$month" -o "$date" -o "$year" ];then
		date --date "$month $date $year" +%A
	else
		show_vir "eg : date --date month date year ..."
	fi

	if false;then
		for m in ${month[@]}
		do
			#echo $m
			date --date "$m 1 2015" +%A
		done
	fi
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

### sshfs server
function sshfs-server()
{
    if [ `hostname` == "happysongs" -o `hostname` == "s1" -o `hostname` == "s2" -o `hostname` == "s3" -o `hostname` == "s4" ];then
        s1.y
        s2.y
        s3.y
        s4.y
        share_s4
    fi
}

function fusermount-server()
{
    if [ `hostname` == "happysongs" ];then
        for server_no in s1.y s2.y s3.y s4.y share_s4
        do
            fusermount -u ~/$server_no
        done
    fi
}

function s1.y()
{
    local slave_jar=slave.jar
    local server_name=s1.y
    local jobs_path=/home/jenkins/jobs
    local local_path=~/$server_name

    if [ ! -d $local_path ];then
        mkdir -p $local_path
    fi

    if [ ! -d $local_path/k26 -o ! -f $local_path/$slave_jar ];then
        sshfs jenkins@$server_name://$jobs_path $local_path
    fi
}

function s2.y()
{
    local slave_jar=slave.jar
    local server_name=s2.y
    local jobs_path=/home/jenkins/jobs
    local local_path=~/$server_name

    if [ ! -d $local_path ];then
        mkdir -p $local_path
    fi

    if [ ! -d $local_path/k26 -o ! -f $local_path/$slave_jar ];then
        sshfs jenkins@$server_name://$jobs_path $local_path
    fi
}

function s3.y()
{
    local slave_jar=slave.jar
    local server_name=s3.y
    local jobs_path=home/work5/jenkins/jobs
    local local_path=~/$server_name

    if [ ! -d $local_path ];then
        mkdir -p $local_path
    fi

    if [ ! -d $local_path/k26 ];then
        sshfs jenkins@$server_name://$jobs_path $local_path
    fi
}

function s4.y()
{
    local slave_jar=slave.jar
    local server_name=s4.y
    local jobs_path=/home/jenkins/jobs
    local local_path=~/$server_name

    if [ ! -d local_path ];then
        mkdir -p $local_path
    fi

    if [ ! -d $local_path/k26 -o ! -f $local_path/$slave_jar ];then
        sshfs jenkins@$server_name://$jobs_path $local_path
    fi
}

function share_s4()
{
    local server_name=s4.y
    local share_path=/home/jenkins/workspace/share
    local local_path=~/share_s4

    if [ ! -d $local_path ];then
        mkdir -p $local_path
    fi

    if [ `hostname` == "happysongs" ];then
        sshfs jenkins@$server_name://$share_path $local_path
    fi
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
function jenkins
{
    local jenkins_ip=10.0.0.18

	ssh jenkins@$jenkins_ip
}

function jenkins1
{
	ssh jenkins@s1.y
}

function jenkins2
{
	ssh jenkins@s2.y
}

function jenkins3
{
	ssh jenkins@s3.y
}

function jenkins4
{
	ssh jenkins@s4.y
}

function yunovo
{
	ssh yunovo@s4.y
}

function git-tag-for-app()
{
    local OLDP=`pwd`
    local app_file=~/workspace/script/zzzzz-script/allapp.txt
    local commit_msg=~/workspace/script/zzzzz-script/commit-msg
    local git_hook=.git/hooks
    local app_path=packages/apps
    local ssh_link=ssh://xingyafeng@gerrit2.y:29418
    local tag_version=$1
    local branch_name=$2

    if [ ! "`is_make_project`" == "true" ];then
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

function rmappfs()
{
    local OLDP=`pwd`
    local app_file=~/workspace/script/zzzzz-script/allapp.txt
    local app_path=packages/apps

    if [ ! "`is_make_project`" == "true" ];then
        return 1
    fi

    cd $app_path > /dev/null

    while read app_name;do
        rm  $app_name -r && echo "---> rm $app_name ..."
    done < $app_file

    cd $OLDP > /dev/null
}

function ssh-update-script()
{
    local server_ip=`echo s1.y s2.y s3.y s4.y happysongs`
    local portN=22
    local server_name=jenkins
    local init_script=/home/jenkins/workspace/script/zzzzz-script/init_script.sh

    for ip in $server_ip;do

        if [ "$ip" == "happysongs" ];then
            ip=10.0.0.18
        fi

        ssh -t -p $portN $server_name@$ip "
            source $init_script && echo "server: $ip" && \
            echo
        "

        if false;then
            ssh -t -p $portN $server_name@$ip '
                cd ~/workspace && touch ssh_test && mkdir test && \
                cd ~ && touch xxx
            '
        fi
    done
}

## 批量复制文件到制定路径
function cplogofs()
{
    ### e.g: magc6580_we_l.mk
    local findfs_name=$1

    ### e.g: yunovo_customs_logo_hd720
    local content_name=$2

    local boot_logo_mk=$findfs_name

    local boot_logo_file=boot_logo.mk
    local boot_logo_file_path=$script_path/$boot_logo_file

    local findfs_file=$script_path/findfs.txt

    if [ $# -eq 2 ];then
        echo
        show_vig "cp files start ..."
        echo
    else
        show_vir "e.g: cplogofs file_name content_name"
    fi

    ### 获取项目路径
    if [ "$findfs_name" ];then
        find . -name $findfs_name -print0 | xargs -0 grep $content_name | cut -d ":" -f1 > $findfs_file
    fi

    #echo "boot_logo_file = $boot_logo_file"

    ## 拷贝到指定项目中
    while read findfs
    do
        findfs=${findfs%/*}

        ### 生成boot_logo.mk
        if [ -f $findfs/$boot_logo_mk ];then
            cat $findfs/$boot_logo_mk | grep BOOT_LOGO > $boot_logo_file_path
        else
            echo "1. $findfs/$boot_logo_mk not found !"
            return 1
        fi

        if [ -f $boot_logo_file_path -a "$findfs" ];then
            cp -vf $boot_logo_file_path $findfs
        else
            echo "2. $boot_logo_file_path not found !"
            return 1
        fi

        if [ -f $findfs/$boot_logo_mk ];then
            rm $findfs/$boot_logo_mk
            #echo "1---> $findfs/$boot_logo_mk"
        else
            echo "2. $findfs/$boot_logo_mk not found !"
            return 1
        fi
    done < $findfs_file

    ### del tmp file
    if [ -f $findfs_file ];then
        rm $findfs_file
        #echo "2---> $findfs_file"
    fi

    ### del tmp file
    if [ -f $boot_logo_file_path ];then
        rm $boot_logo_file_path
        #echo "3---> $boot_logo_file_path"
    fi

    echo
    show_vig "cp files end ..."
    echo
}

function cphardwarefs()
{
    local findfs_name=$1
    local project_name=$2
    local findfs_file=$script_path/findfs.txt
    local hardware_file=HardWareConfig.mk
    local hardware_file_path=$script_path/$hardware_file

    local start_line=
    local end_line=

    if [ $# -eq 2 ];then
        echo
        show_vig "cphardwarefs start ..."
        echo
    else
        show_vir "please e.g: cphardwarefs ProjectConfig.mk k26"
        return 1
    fi

    if [ "$findfs_name" ];then
        find . -name $findfs_name > $findfs_file
    else
        show_vir "$findfs_name not found !"
        return 1
    fi

    while read findfs
    do
        ### get project path
        findfs=${findfs%/*}

        if [ "$findfs/$findfs_name" ];then
            if [ $project_name == "k26" ];then
                start_line=$(sed -n '/^AUTO_ADD_GLOBAL_DEFINE_BY_VALUE/=' $findfs/$findfs_name)
                end_line=$(sed -n '/^BOOT_LOGO/=' $findfs/$findfs_name)

                if [ "$start_line" ];then
                    start_line=`expr $start_line + 1`
                fi

                if [ "$end_line" ];then
                    end_line=`expr $end_line - 1`
                fi
            else
                start_line=$(sed -n '/yafeng/=' $findfs/$findfs_name)
                end_line=$(sed -n '/^BOOT_LOGO/=' $findfs/$findfs_name)

                if [ "$start_line" ];then
                    start_line=`expr $start_line - 1`
                fi

                if [ "$end_line" ];then
                    end_line=`expr $end_line - 1`
                fi
            fi

        fi

        if [ $start_line -a $end_line -a -f $findfs/$findfs_name ];then

            echo "start_line = $start_line"
            echo "end_line = $end_line"
            echo "### hardware info for yunovo cumstoms" > $hardware_file_path
            sed -n "$start_line,$end_line"p $findfs/$findfs_name >> $hardware_file_path

            ### del tmp file
            if [ -f $hardware_file_path ];then
                cp -vf  $hardware_file_path $findfs
                if [ $? -eq 0 -a "$hardware_file_path" ];then
                    rm $hardware_file_path
                else
                    show_vir "$hardware_file_path not found !"
                    return 1
                fi
            fi

            ### del ProjectConfig.mk
            if [ "$findfs/$findfs_name" ];then
                rm $findfs/$findfs_name
            else
                show_vir "$findfs/$findfs_name not found !"
                return 1
            fi
        fi

    done < $findfs_file

    if [ -f $findfs_file ];then
        rm $findfs_file
    else
        show_vir "$findfs_file not fount ! "
        return 1
    fi

    echo
    show_vig "cp files end ..."
    echo
}

### 批量删除文件夹
function deletefolder()
{
    local deletefs=$1
    local findfs_file=$script_path/findfs.txt

    if [ $deletefs ];then
        gfind $deletefs > $findfs_file
    fi

    while read findfs
    do
        findfs=${findfs%/*}
        #echo "fs = $findfs"

        if [ "$findfs" ];then
            rm $findfs -rf
        else
            show_vir "$findfs not found !"
            return 1
        fi

    done < $findfs_file

    if [ -f $findfs_file ];then
        rm $findfs_file -rf
    else
        echo "$findfs_file not found !"
        return 1
    fi
}

##　批量删除指定文件
function deletefs()
{
    local deletefs=$1

    if [ "$deletefs" ];then
        gfind $deletefs | xargs rm -r
    else
        echo "$deletefs not found !"
        return 1
    fi
}
