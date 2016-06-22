#!/bin/bash

# 发生错误就退出
set -e
######################################## 设置时间变量
MY_DAY=$(date '+%Y%02m%02d')
MY_TIME=$(date '+%02k%02M')
TIME_NAME=${MY_DAY}-${MY_TIME}

# show very important tip
function show_vit() {
#	echo "num=$#"
#	echo "$@"
	if [ "$1" ]; then
		for mytipid in "$@" ; do
			echo -e "\e[1;31m$mytipid\e[0m"
		done
	fi
}

# show very important tip with no line end
function show_vit_nle() {
	if [ "$1" ]; then
		for mytipid in "$@" ; do
			echo -e -n "\e[1;31m$mytipid\e[0m"
		done
	fi
}

#####获取ip
unset MY_IP_ADDR
function __get_ip_addr() {
	local arg
	arg=`ifconfig eth1 |grep "inet" | cut -f 2 -d ":" | cut -f 1 -d " "`
	MY_IP_ADDR=$arg
#	echo "my work ip : $MY_IP_ADDR"
}
__get_ip_addr


######################################## 设置目录变量 #########################
####脚本所在目录
SELF_PWD=`dirname "$0"`
cd ${SELF_PWD}
A_SELF_PWD=$(pwd)
#########################################################################
# 
#########################################################################
#echo $A_SELF_PWD
THIS_ALL_PAMA="$@"
#### 设定repo库目录
REPO_SERVER_IP=192.168.1.20
OUR_REPO=/git_repo
OUR_GIT_NAME=ssh://git@${REPO_SERVER_IP}/home/git
## 除了REPO_SERVER_IP, 其它ip用ssh协议下
#if [ ${MY_IP_ADDR} != ${REPO_SERVER_IP} ]; then  ####为了统一，还是用ssh协议下载
	OUR_REPO=${OUR_GIT_NAME}/git_repo
#fi

OUR_REPO_TOOL_GIT=${OUR_REPO}/repo.git
THIS_REPO_TOOL_GIT=${OUR_REPO}/repo.git
INIT_ALLWINNER=
if [ "`echo _$THIS_ALL_PAMA | grep 'allwinner'`" ]; then
	INIT_ALLWINNER=allwinner
	#OUR_REPO=${OUR_GIT_NAME}/git_repo/${INIT_ALLWINNER}
	THIS_REPO_TOOL_GIT=${OUR_GIT_NAME}/git_repo/${INIT_ALLWINNER}/repo.git
fi

OUR_REPO_GIT=${OUR_REPO}/manifest.git

INIT_SYNC=true
if [ "`echo _$THIS_ALL_PAMA | grep 'nosync'`" ]; then
	INIT_SYNC=false
fi
#echo "INIT_SYNC=$INIT_SYNC"

#echo $REPO_SERVER_IP
#echo $OUR_GIT_NAME
#echo $OUR_REPO
#echo $OUR_REPO_GIT

#### chiphd_script库目录
#CHIPHD_SCRIPT_SERVER_IP=192.168.1.22
#CHIPHD_SCRIPT_GIT_PATH=/home2/builder/release/chiphd_script/zzzzz-chiphd

# download box zzzzz-chiphd dir
CHIPHD_SCRIPT_SERVER_IP=192.168.1.20
CHIPHD_SCRIPT_GIT_PATH=/home/git/chiphd_devices/box/zzzzz-chiphd.git
CHIPHD_SCRIPT_GIT_NAME=${CHIPHD_SCRIPT_GIT_PATH}
if [ ${MY_IP_ADDR} != ${CHIPHD_SCRIPT_SERVER_IP} ]; then
	CHIPHD_SCRIPT_GIT_NAME=ssh://git@${CHIPHD_SCRIPT_SERVER_IP}${CHIPHD_SCRIPT_GIT_PATH}
fi

# download box chiphdDevices dir
CHIPHD_DEVICES_GIT_PATH=/home/git/chiphd_devices/h3-h8/4.4/chiphdDevices.git
CHIPHD_DEVICES_GIT_NAME=ssh://git@${CHIPHD_SCRIPT_SERVER_IP}${CHIPHD_DEVICES_GIT_PATH}

# download box chiphdLichee dir
CHIPHD_LICHEE_GIT_PATH=/home/git/chiphd_devices/h3-h8/4.4/chiphdLichee.git
CHIPHD_LICHEE_GIT_NAME=ssh://git@${CHIPHD_SCRIPT_SERVER_IP}${CHIPHD_LICHEE_GIT_PATH}

##  获取repo库的manifest-name集合
if [ ${MY_IP_ADDR} != ${REPO_SERVER_IP} ]; then
	OUR_REPO_MANIFEST_SET=$(ssh git@192.168.1.20 "cd /git_repo/manifest && ls *.xml")
else
	OUR_REPO_MANIFEST_SET=`cd /git_repo/manifest && ls *.xml`
fi
#echo $OUR_REPO_MANIFEST_SET

#########################################################################
# 创建目录及下载SDK
#########################################################################
##定义工作目录变量
MY_LICHEE_DIR=lichee
MY_ANDROID_DIR=android4.0
##定义repo manifest分支相关参数变量
MY_ANDROID_xml=a10_android.xml
MY_LICHEE_xml=a10_lichee.xml


###############################获取chiphd脚本,要在Android根目录使用
function  down_chiphd_script() {
	if [ "$INIT_ALLWINNER"_test = "allwinner"_test ]; then
		return 0
	fi

  local this_script_path=device/softwinner/zzzzz-chiphd
  if [ ! -d $this_script_path ]; then
  	git clone ${CHIPHD_SCRIPT_GIT_NAME} $this_script_path && show_vit "done : zzzzz-chiphd"
  fi
	#cd device/softwinner && if [ ! -d zzzzz-chiphd ]; then git clone ${CHIPHD_SCRIPT_GIT_NAME}; fi && show_vit "done : zzzzz-chiphd" && cd -
}

###############################下载allwinner版本
function  down_allwinner_check_and_try() {
	if [ "$INIT_ALLWINNER"_test != "allwinner"_test ]; then
		return 0
	fi

	##获取库跟目录
	local RepoTopDir=`grep fetch .repo/manifest.xml | awk -F\" '{print $2}'`
	if [ "$RepoTopDir" ]; then
		local WinnerHEAD=$RepoTopDir   ## flag head file
		if [ "`grep 'frameworks/base' .repo/manifest.xml`" ]; then
			#android
			WinnerHEAD=${WinnerHEAD}/platform/frameworks/base.git/HEAD
		else
			#lichee
			WinnerHEAD=${WinnerHEAD}/tools.git/HEAD
		fi
		AllwinnerBranch=`ssh git@${REPO_SERVER_IP} "cat $WinnerHEAD | sed 's%^.*/%%'"`
		if [ "$AllwinnerBranch" ]; then
			local Mfile=.repo/"`readlink .repo/manifest.xml`"
			#替换分支名
			sed -i "s/revision=\"develop\"/revision=\"${AllwinnerBranch}\"/" $Mfile
			#标记只下载revision指定的分支
			sed -i 's/sync-j/sync-c="true" sync-j/' $Mfile
			echo "down allwinner branch ${AllwinnerBranch} onldy"
		else
			echo "get AllwinnerBranch error"
		fi
	else
		echo 'get RepoTopDir error'
	fi
}

###############################删除chiphd tags,要在Android根目录使用
function  del_chiphd_tag_check_try() {
	if [ "$INIT_ALLWINNER"_test != "allwinner"_test ]; then
		return 0
	fi

	local NowPWD=$(pwd)
	local OldPWD=$(cd - > /dev/null && pwd)
	local TopDir=$NowPWD

set +e
	local ChiphdTags=
	if [ -d ${TopDir}/frameworks/base ]; then
		cd ${TopDir}/frameworks/base
		ChiphdTags=`git tag --list chiphd*`
	else
		if [ -d ${TopDir}/tools ]; then
			cd ${TopDir}/tools
			ChiphdTags=`git tag --list chiphd*`
		fi
	fi

	cd $TopDir
	if [ "$ChiphdTags" ]; then
		for ii in $ChiphdTags
		do
			echo "delete tag : $ii"
			repo forall -c git tag -d "$ii"
		done
	else
		echo "not found chiphd tags"
	fi

set -e
	cd $OldPWD
	cd $NowPWD
}

function download_chiphd_devices
{
	local this_android_path=chiphdDevices
	this_sdk_path=$(pwd) && this_sdk_path=${this_sdk_path##*/}
	
	if [ ! -d $this_android_path ]; then
		if [ "`echo $this_sdk_path | grep "[Hh][3,8]"`" ];then
 			git clone ${CHIPHD_DEVICES_GIT_NAME} $this_android_path 
			show_vit "done : chiphdDevices"
		else
			show_vit "err ...."
		fi	
 	fi
}

function download_chiphd_lichee
{	
	local this_lichee_path=chiphdLichee
	this_sdk_path=$(pwd) && this_sdk_path=${this_sdk_path##*/}

 	if [ ! -d $this_lichee_path ]; then
		if [ "`echo $this_sdk_path | grep "[Hh][3,8]"`" ];then
			git clone ${CHIPHD_LICHEE_GIT_NAME} $this_lichee_path 
			show_vit "done : chiphdLichee"
		else
			show_vit "err ...."
		fi
 	fi
}

###############################下载android
function  down_android() {

#记录当前目录
BF_CALL_PWD=$(pwd)

#获取 chiphdDevices
download_chiphd_devices

#获取 chiphdLichee
download_chiphd_lichee

#创建android目录
mkdir $MY_ANDROID_DIR
cd $MY_ANDROID_DIR

#获取公共内核脚本
down_chiphd_script

#初始化库
echo -e -n "Get source by " && show_vit "repo init -u ${OUR_REPO_GIT} -m ${MY_ANDROID_xml}"
repo init -u ${OUR_REPO_GIT} -m ${MY_ANDROID_xml} <<EOF
y
y
y
EOF

## 试试是否只下载allwinner版本
down_allwinner_check_and_try

if [ "$INIT_SYNC" = "true" ]; then
	## 同步前换掉repo工具
	if [ "$OUR_REPO_TOOL_GIT" != "$THIS_REPO_TOOL_GIT" ]; then
		rm -rf .repo/repo && git clone $THIS_REPO_TOOL_GIT .repo/repo
	fi

	#同步
	repo sync
	#show_vit "done : repo sync"

	## 同步后换回repo工具
	if [ "$OUR_REPO_TOOL_GIT" != "$THIS_REPO_TOOL_GIT" ]; then
		rm -rf .repo/repo && git clone $OUR_REPO_TOOL_GIT .repo/repo
	fi

	## 可能要删除 chiphd tags(含同步后换回repo工具)
	del_chiphd_tag_check_try

	#创建分支
	DefBranchName=`grep 'default revision='  .repo/manifest.xml | sed 's/.*="//' | sed 's/".*//'`
	if [ ! "$DefBranchName" ]; then
		DefBranchName=develop
	fi
	repo start $DefBranchName --all
	show_vit "done : repo start $DefBranchName --all"

fi

#返回之前的目录
cd $BF_CALL_PWD
show_vit_nle "End " && echo -e -n "get source from " && show_vit "${OUR_REPO_GIT} -m ${MY_ANDROID_xml}"
}

###############################下载lichee
function  down_lichee() {

#记录当前目录
BF_CALL_PWD=$(pwd)

#创建lichee目录
mkdir $MY_LICHEE_DIR
cd $MY_LICHEE_DIR

#初始化库
echo -e -n "Get source by " && show_vit "repo init -u ${OUR_REPO_GIT} -m ${MY_LICHEE_xml}"
repo init -u ${OUR_REPO_GIT} -m ${MY_LICHEE_xml} <<EOF
y
y
y
EOF

## 试试是否只下载allwinner版本
down_allwinner_check_and_try

if [ "$INIT_SYNC" = "true" ]; then
	## 同步前换掉repo工具
	if [ "$OUR_REPO_TOOL_GIT" != "$THIS_REPO_TOOL_GIT" ]; then
		rm -rf .repo/repo && git clone $THIS_REPO_TOOL_GIT .repo/repo
	fi
	#同步
	repo sync
	#show_vit "done : repo sync"

	## 同步后换回repo工具
	if [ "$OUR_REPO_TOOL_GIT" != "$THIS_REPO_TOOL_GIT" ]; then
		rm -rf .repo/repo && git clone $OUR_REPO_TOOL_GIT .repo/repo
	fi

	## 可能要删除 chiphd tags(含同步后换回repo工具)
	del_chiphd_tag_check_try

	#创建分支
	DefBranchName=`grep 'default revision='  .repo/manifest.xml | sed 's/.*="//' | sed 's/".*//'`
	if [ ! "$DefBranchName" ]; then
		DefBranchName=develop
	fi
	repo start $DefBranchName --all
	show_vit "done : repo start $DefBranchName --all"

fi

#返回之前的目录
cd $BF_CALL_PWD
show_vit_nle "End " && echo -e -n "get source from " && show_vit "${OUR_REPO_GIT} -m ${MY_LICHEE_xml}"
}

####定义sdk版本型号集合
ALL_SDK_SET="$OUR_REPO_MANIFEST_SET	select_to_exit"

####按需选择下载代码
(echo "****************************************************")
echo "    select a sdk to download (enter number):"
(echo "****************************************************")
select SEL_SDK in $ALL_SDK_SET; do
show_vit "   selected $SEL_SDK"
case $SEL_SDK  in
*android*)
	MY_ANDROID_DIR=android
	MY_ANDROID_xml=$SEL_SDK
	down_android
	break;
	;;
*lichee*)
	MY_LICHEE_xml=$SEL_SDK
	down_lichee
	break;
	;;
"select_to_exit")
	break;
	;;
esac ####end case

done


#end
(echo "****************************************************")
(show_vit "              done!!!!!!!!!                     ")
(echo "****************************************************")
# ##############################end of file

