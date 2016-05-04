#!/bin/bash

#set java env
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$CLASSPATH:$JAVA_HOME/lib:$JRE_HOME/lib
export PATH=${JAVA_HOME}/bin:$JRE_HOME/bin:$PATH

################################## args


### build project name  e.g. : K86_H520
build_prj_name=$1
## system version  e.g. : S1.01
build_version=$2
### build custom
build_device=$3
### eng|user|userdebug
build_type=$4
### build sdk flag, e.g. : ota.print.download.clone.make.cp
build_skd_flag=$5

## project name for system k26 k86 k86A k86m k88
projeck_name=${build_prj_name%_*}
### custom name H520 ZX etc
custom_name=${build_prj_name##*_}

### version for system
# S1 S2 ...
first_version=${build_version%.*}
#01 02 .. 08 09 ..
second_version=${build_version##*.}

### flag for main (0 or 1)
flag_fota=`echo $build_skd_flag | cut -d '.' -f1`
flag_print=`echo $build_skd_flag | cut -d '.' -f2`
flag_download_sdk=`echo $build_skd_flag | cut -d '.' -f3`
flag_clone_app=`echo $build_skd_flag | cut -d '.' -f4`
flag_make_sdk=`echo $build_skd_flag | cut -d '.' -f5`
flag_cpimage=`echo $build_skd_flag | cut -d '.' -f6`
flag_cpcustom=`echo $build_skd_flag | cut -d '.' -f7`

################################# common variate
gettop=`pwd`
cpu_num=`cat /proc/cpuinfo  | egrep 'processor' | wc -l`
cur_time=`date +%m%d_%H%M`
hw_versiom=H3.1
branch_nane=develop
lunch_project=full_${build_device}-${build_type}
project_link="init -u git@src1.spt-tek.com:projects/manifest.git"
system_version=$custom_name\_$hw_versiom\_$first_version\_$projeck_name\_$second_version
fota_version="SPT_VERSION_NO=${system_version}"

### clone system app
commond_app=(FactoryTest CarEngine CarHomeBtn CarSystemUpdateAssistant CarPlatform GaodeMap KwPlayer UniSoundService)
k86a_app=(CarUpdateDFU CarBack CarRecord GaodeNavigation GpsTester BaiduNavigation AnAnEDog)
k86l_app=(CarUpdateDFU CarBack CarRecordDouble CarRecordUsb StormVideo GaodeNavigation XianzhiDSA CarConfig FileCopyManager)
k86s_app=(CarUpdateDFU CarRecordDouble CarRecordUsb GpsTester BaiduNavigation AnAnEDog StormVideo)
k26a_app=(CarRecord GpsTester BaiduNavigation)
k26s_app=(CarRecordDouble CarRecordUsb GpsTester BaiduNavigation StormVideo)
k88_app=(CarUpdateDFU CarBack CarRecord GaodeNavigation GpsTester BaiduNavigation AnAnEDog)
allapp=()

### color purple
function show_vip
{
	if [ "$1" ]
	then
	#	echo "---------------------"
		for ret in "$@"; do
			echo -e -n "\e[1;35m$ret \e[0m"
		done
		echo
	fi
}

#### touch all file
function update_all_type_file_time_stamp()
{
	local tttDir=$1
	if [ -d "$tttDir" ]; then
		find $tttDir -name "*" | xargs touch -c
		find $tttDir -name "*.*" | xargs touch -c
		echo "    TimeStamp $tttDir"
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

#### 恢复默认配置文件
function chiphd_recover_standard_device_cfg()
{
	local tDir=$1
	if [ "$tDir" -a -d $tDir ]; then
		#echo $tDir
		:
	else
		return 0
	fi
	local tOldPwd=$OLDPWD
	local tNowPwd=$PWD
    cd $(gettop)

	#echo "now get all project from repo..."
	local AllRepoProj=`chiphd_get_repo_git_path_from_xml`
	if [ "$AllRepoProj" ]; then
		for ProjPath in $AllRepoProj
		do
			if [ -d "${tDir}/$ProjPath" ]; then
				chiphd_recover_project $ProjPath
			fi
		done
	fi
	cd $tOldPwd
	cd $tNowPwd
}

## rm build_xxx.log
function delete_log()
{
	find . -maxdepth 1 -name "build*.log" -print0 | xargs -0 rm
}

## cp img
function cpimage()
{
	### k86A_H520
	local prj_name=$projeck_name\_$custom_name
	local ver_name=${first_version}.${second_version}
	echo "prj_name = $prj_name"

    ### k86m_H520/S1
	#local BASE_PATH=/home/work5/public/k86A_Test/${prj_name}/${ver_name}
    local firmware_path=~/firmware
	local BASE_PATH=$firmware_path/${prj_name}/${ver_name}
	local DEST_PATH=$BASE_PATH/$system_version
	local OTA_PATH=$BASE_PATH/${system_version}_full_and_ota

	echo "BASE_PATH = $BASE_PATH"
	echo "DEST_PATH = $DEST_PATH"
	echo "OTA_PATH = $OTA_PATH"

    if [ ! -d $firmware_path ];then
        mkdir -p $firmware_path
    else
        echo "---> create $firmware_path ..."
    fi

	if [ ! -d $DEST_PATH ];then
		mkdir -p $DEST_PATH

		if [ ! -d ${DEST_PATH}/database/ ];then
			mkdir -p ${DEST_PATH}/database/ap
			mkdir -p ${DEST_PATH}/database/moden
		else
			echo "---> created /database/ap or /database/moden ..."
		fi
	else
		echo "---> created $DEST_PATH"
	fi

	if [ ! -d $OTA_PATH ];then
		mkdir -p $OTA_PATH
	else
		echo "---> created $OTA_PATH "
	fi

	cp -vf ${OUT}/MT*.txt ${DEST_PATH}
	cp -vf ${OUT}/preloader_${build_device}.bin ${DEST_PATH}
	cp -vf ${OUT}/lk.bin ${DEST_PATH}
	cp -vf ${OUT}/boot.img ${DEST_PATH}
	cp -vf ${OUT}/recovery.img ${DEST_PATH}
	cp -vf ${OUT}/secro.img ${DEST_PATH}
	cp -vf ${OUT}/logo.bin ${DEST_PATH}
	cp -vf ${OUT}/trustzone.bin ${DEST_PATH}
	cp -vf ${OUT}/trustzone.bin ${DEST_PATH}
	cp -vf ${OUT}/system.img ${DEST_PATH}
	cp -vf ${OUT}/cache.img ${DEST_PATH}
	cp -vf ${OUT}/userdata.img ${DEST_PATH}

	cp -vf ${OUT}/obj/CGEN/APDB_MT*W15* ${DEST_PATH}/database/ap
	cp -vf ${OUT}/system/etc/mddb/BPLGUInfoCustomAppSrcP* ${DEST_PATH}/database/moden

    echo "---> cp image end ..."
    echo
    if [ $flag_fota -eq 1 ];then
        cp -v ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}
        cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH}
        echo "cp ota end ..."
        echo
    fi

    echo "cpimage finish ..."
    echo
}

## print variable
function print_variable()
{
	echo "cpu_num = $cpu_num"
	echo '-----------------------------------------'
	echo "build_prj_name = $build_prj_name"
    echo "project_name = $projeck_name"
    echo "custom_name = $custom_name"
	echo '-----------------------------------------'
	echo "build_version = $build_version"
    echo "first_version = $first_version"
    echo "second_version = $second_version"
	echo '-----------------------------------------'
	echo "build_device = $build_device"
	echo "build_type = $build_type"
	echo '-----------------------------------------'
    echo "flag_fota = $flag_fota"
    echo "flag_print = $flag_print"
    echo "flag_download_sdk = $flag_download_sdk"
    echo "flag_clone_app = $flag_clone_app"
    echo "flag_make_sdk = $flag_make_sdk"
    echo "flag_cpimage = $flag_cpimage"
    echo "flag_cpcustom = $flag_cpcustom"
	echo '-----------------------------------------'
	echo "lunch_project = $lunch_project"
	echo "\$1 = $1"
	echo "\$2 = $2"
	echo "\$3 = $3"
	echo "\$4 = $4"
	echo "\$5 = $5"
	echo "\$# = $#"
}

#### 复制差异化文件
function cpcustoms()
{
    local select_project="k86l/newman/zx"
	local thisSDKTop=$(gettop)
	local ConfigsPath=${thisSDKTop}/../yunovo_customs

	if [ -d "$ConfigsPath" ]; then
		ConfigsPath=$(cd $ConfigsPath && pwd)
	else
		echo "no path : $ConfigsPath"
		return 1
	fi

	local ConfigsFName=proj_help.sh
	local ProductSetTop=${ConfigsPath}/custom

    ##遍历所有客户方案配置
	local ProductSetShort=`find $ProductSetTop -name $ConfigsFName | awk -F/ '{print $(NF-3) "/" $(NF-2) "/" $(NF-1)}' | sort`
    local MySEL=

    for custom_project in $ProductSetShort
    do
        if [ "$select_project"  == $custom_project ];then
            MySEL=$custom_project
        fi
    done
	local ProductSelPath="$ProductSetTop/$MySEL"

#    echo "ProductSelPath = $ProductSelPath"
	if [ -d "$ProductSelPath" -a ! "$ProductSelPath" = "$ProductSetTop/" ]; then

	    if [ -f ${ConfigsPath}/NowCustom.sh ]; then
			OldProductSelPath=$(sed -n '1p' ${ConfigsPath}/NowCustom.sh)
			OldProductSelPath=${OldProductSelPath%/*}
			OldProductSelDirAndroid=${OldProductSelPath}/android
		fi
		## 新项目
		echo "${ProductSelPath}/$ConfigsFName" > ${ConfigsPath}/NowCustom.sh

		#### 更新时间戳并拷贝到配置根目录
		ProjectSelDirAndroid=$ProductSelPath/android

		#echo "OldProductSelDirAndroid = $OldProductSelDirAndroid"
		#echo "ProjectSelDirAndroid = $ProjectSelDirAndroid"

        if [ -d $ProjectSelDirAndroid ]; then
			local tOldPwd=$OLDPWD
			local tNowPwd=$PWD

			local thisProjDelFileSh=$thisSDKTop/chiphd_delete.sh
			if [ -f "$thisProjDelFileSh" ]; then rm $thisProjDelFileSh; fi

            ## 清除旧项目的修改
			echo "clean by $OldProductSelDirAndroid" && chiphd_recover_standard_device_cfg $OldProductSelDirAndroid

			## 确保新项目的修改纯净
			echo "clean by $ProjectSelDirAndroid" && chiphd_recover_standard_device_cfg $ProjectSelDirAndroid

			## 新项目代码拷贝
			update_all_type_file_time_stamp $ProjectSelDirAndroid
			echo "copy source code : $ProjectSelDirAndroid/*  " && cp -r $ProjectSelDirAndroid/*  $thisSDKTop/ && echo "copy android custom done"

			cd $tOldPwd
			cd $tNowPwd
		else
			echo "no config : $ProjectSelDir"
		fi
	fi
}

function clone_app()
{
	local OLDP=`pwd`
	local remote_name="master origin/master"
	local app_path=packages/apps
	local ssh_link=ssh://jenkins@gerrit2.spt-tek.com:29418
	local default_branch="master origin/master"

	echo "project_name = $projeck_name"

	if [ $projeck_name == "k86a" -o $projeck_name == "k86m" -o $projeck_name == "k86sm" ];then
		k86a_app+=("${commond_app[@]}")
		allapp+=("${k86a_app[@]}")
	elif [ $projeck_name == "k86l" ];then
		k86l_app+=("${commond_app[@]}")
		allapp+=("${k86l_app[@]}")
		default_branch="long origin/long"
	elif [ $projeck_name == "k86s" ];then
		k86s_app+=("${commond_app[@]}")
		allapp+=("${k86s_app[@]}")
	elif [ $projeck_name == "k26a" ];then
		k26a_app+=("${commond_app[@]}")
		allapp+=("${k26a_app[@]}")
	elif [ $projeck_name == "k26s" ];then
		k26s_app+=("${commond_app[@]}")
		allapp+=("${k26s_app[@]}")
	elif [ $projeck_name == "k88" ];then
		k88_app+=("${commond_app[@]}")
		allapp+=("${k88_app[@]}")
	fi

	cd $app_path > /dev/null

	for app_name in ${allapp[@]}; do
		#statements
		#echo ${app_name}
		if [ -d $app_name ];then
			echo "-------------- pull $app_name app code"
			cd $app_name > /dev/null
			git pull
			cd .. > /dev/null
		else
			echo "-------------- clone $app_name app code"
			git clone $ssh_link/$app_name

			if [ $app_name == "CarEngine"  -o $app_name == "CarRecordDouble" ];then
				echo "app name = $app_name"
				cd $app_name > /dev/null
				git checkout -b ${default_branch}
				cd .. > /dev/null
			fi
		fi
	done

	echo "--> clone or pull app end ..."
	echo
	cd $OLDP > /dev/null
}

## download sdk
function download_sdk()
{

    local defalut=

    if [ $projeck_name == "k86a" -o $projeck_name == "k86m" ];then
        defalut=k86A
    elif [ $projeck_name == "k86s" -o $projeck_name == "k86sm" ] ;then
        defalut=k86s
    elif [ $projeck_name == "k86l" -o $projeck_name == "k86s6" -o $projeck_name == "k86s7" ];then
        defalut=k86s_400x1280
    elif [ $projeck_name == "k88" ];then
        defalut=k88
    elif [ $projeck_name == "k26a" -o $projeck_name == "k26b" ];then
        defalut=k26
    fi

    echo "defalut = $defalut"
	if [ ! -d $gettop/.repo ];then
		#repo init -u git@src1.spt-tek.com:projects/manifest.git -m k86A.xml
		repo $project_link -m ${defalut}.xml
		repo sync -j${cpu_num}
		ls -alF
		repo start $defalut --all
	else
		repo forall -c git fetch && echo "-----------------git fetch ok" && echo
		repo forall -c git pull  && echo "-----------------git pull ok"  && echo
		echo "--> sdk update ..."
		echo
	fi
}

## build sdk
function make-sdk()
{
	source  build/envsetup.sh
	echo "--> source end ..."
	echo

	lunch $lunch_project
	echo "--> lunch end ..."
	echo
	echo "ROOT = $(gettop)"
	echo "OUT = $OUT"

if true;then
	if make installclean;then
		echo "--> make installclean end ..."
		echo
    else
        echo "---> make installclean failed !"
	fi

	if [ -n "$(find . -maxdepth 1 -name "build*.log" -print0)" ];then
		delete_log
	fi

	make -j${cpu_num} ${fota_version} 2>&1 | tee build_$cur_time.log
	if [ $? -eq 0 ];then
        echo "--> make project end ..."
    else
        echo "make android failed !"
        exit 1
    fi

    if [ $flag_fota -eq 1 ];then
        make -j${cpu_num} ${fota_version} otapackage 2>&1 | tee build_ota_$cur_time.log

        if [ $? -eq 0 ];then
            echo "--> make otapackage end ..."
        else
            echo "make otapackage failed !"
            echo
            exit 1
        fi

    fi

fi
}

function main()
{
    if [ $flag_print -eq 1 ];then
	    print_variable $build_prj_name $build_version $build_device $build_type $build_skd_flag
    else
        echo "do not anythings output !"
    fi

    if [ $flag_download_sdk -eq 1 ];then
        download_sdk
    else
        echo "do not download_sdk !"
    fi

    if [ $flag_clone_app -eq 1 ];then
	    clone_app
    else
        echo "do not clone app !"
    fi

    if [ $flag_cpcustom -eq 1 ];then
        source  build/envsetup.sh
	    echo "--> source end ..."
	    echo

	    lunch $lunch_project
	    echo "--> lunch end ..."
	    echo

        cpcustoms
    else
        echo "do not cp customs"
    fi

    if [ $flag_make_sdk -eq 1 ];then
	    make-sdk
    else
        echo "do not make sdk !"
    fi

    if [ $flag_cpimage -eq 1 ];then
	    cpimage
    else
        echo "do not cp image !"
    fi
}

main
