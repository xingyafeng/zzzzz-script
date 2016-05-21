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
### eg: k86l_yunovo_zx
build_file=$6

## project name for system k26 k86 k86A k86m k88
project_name=${build_prj_name%%_*}
### custom version H520 ZX etc
custom_version=${build_prj_name##*_}

### project name k26 k86
file_project=${build_file%%_*}
### custom name yunovo newman qichen etc
file_name=${build_file%_*} && file_name=${file_name##*_}
### zx etc
file_version=${build_file##*_}

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
system_version=$custom_version\_$hw_versiom\_${first_version}.${project_name}.${second_version}
fota_version="SPT_VERSION_NO=${system_version}"
prefect_name="$file_project/$file_name/$file_version"

### clone system app
commond_app=(FactoryTest CarEngine CarHomeBtn CarSystemUpdateAssistant CarPlatform GaodeMap KwPlayer UniSoundService CarConfig XianzhiDSA FileCopyManager CarBack GpsTester YOcRadPowerManager BaiduInput CarDog AnAnEDogUE AnAnEDog)
k86a_app=(CarUpdateDFU CarRecord GaodeNavigation GpsTester BaiduNavigation CldNavi NewsmyNewyan NewsmyRecorder NewsmySPTAdapter)
k86l_app=(CarUpdateDFU CarRecordDouble CarRecordUsb GpsTester XianzhiDSA FileCopyManager GaodeCarMap)
k86s_app=(CarUpdateDFU CarRecordDouble CarRecordUsb GpsTester BaiduNavigation CldNavi NewsmyNewyan NewsmyRecorder NewsmySPTAdapter)
k26a_app=(CarRecord GpsTester BaiduNavigation)
k26s_app=(CarRecordDouble CarRecordUsb GpsTester BaiduNavigation)
k88_app=(CarUpdateDFU CarBack CarRecord GaodeNavigation GpsTester BaiduNavigation)
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
	local prj_name=$project_name\_$custom_version
	local ver_name=${first_version}.${second_version}
	echo "prj_name = $prj_name"

    ### k86m_H520/S1
	#local BASE_PATH=/home/work5/public/k86A_Test/${prj_name}/${ver_name}
    local firmware_path=~/debug
	local BASE_PATH=$firmware_path/${prj_name}/${ver_name}
	local DEST_PATH=$BASE_PATH/$system_version
	local OTA_PATH=$BASE_PATH/${system_version}_full_and_ota

    local server_name=`hostname`
    local firmware_path_server=~/workspace/share/debug
    local BASE_PATH_SERVER=$firmware_path_server/$prj_name/$ver_name
    local DEST_PATH_SERVER=$BASE_PATH_SERVER/$system_version
    local OTA_PATH_SERVER=$BASE_PATH_SERVER/${system_version}_full_and_ota

    echo "-------------------------local base"
	echo "BASE_PATH = $BASE_PATH"
	echo "DEST_PATH = $DEST_PATH"
	echo "OTA_PATH = $OTA_PATH"
    echo "-------------------------server base"
    echo "BASE_PATH_SERVER = $BASE_PATH_SERVER"
    echo "DEST_PATH_SERVER = $DEST_PATH_SERVER"
    echo "OTA_PATH_SERVER = $OTA_PATH_SERVER"
    echo "---------------------------------end"

    if [ $server_name == "s1" -o $server_name == "s2" -o $server_name == "s3" ];then
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

	    if [ $server_name == "s2" -o $server_name == "s3" ];then
            cp -vf ${OUT}/trustzone.bin ${DEST_PATH}
        fi

        cp -vf ${OUT}/system.img ${DEST_PATH}
	    cp -vf ${OUT}/cache.img ${DEST_PATH}
	    cp -vf ${OUT}/userdata.img ${DEST_PATH}

	    cp -vf ${OUT}/obj/CGEN/APDB_MT*W15* ${DEST_PATH}/database/ap
	    cp -vf ${OUT}/system/etc/mddb/BPLGUInfoCustomAppSrcP* ${DEST_PATH}/database/moden

        echo "---> cp image end ..."
        echo
        if [ $flag_fota -eq 1 ];then
            cp -v ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}/sdupdate.zip
            cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH}/${system_version}.zip
            echo "cp ota end ..."
            echo
        fi
    elif [ $server_name == "s4" ];then
        if [ ! -d $firmware_path_server ];then
            mkdir -p $firmware_path_server
        else
            echo "---> create $firmware_path_server ... in $server_name"
        fi

	    if [ ! -d $DEST_PATH_SERVER ];then
		    mkdir -p $DEST_PATH_SERVER

		    if [ ! -d ${DEST_PATH_SERVER}/database/ ];then
			    mkdir -p ${DEST_PATH_SERVER}/database/ap
			    mkdir -p ${DEST_PATH_SERVER}/database/moden
		    else
			    echo "---> created /database/ap or /database/moden ... in $server_name"
		    fi
	    else
		    echo "---> created $DEST_PATH_SERVER in $server_name"
	    fi

	    if [ ! -d $OTA_PATH_SERVER ];then
		    mkdir -p $OTA_PATH_SERVER
	    else
		    echo "---> created $OTA_PATH_SERVER in $server_name"
	    fi

	    cp -vf ${OUT}/MT*.txt ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/preloader_${build_device}.bin ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/lk.bin ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/boot.img ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/recovery.img ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/secro.img ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/logo.bin ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/trustzone.bin ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/system.img ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/cache.img ${DEST_PATH_SERVER}
	    cp -vf ${OUT}/userdata.img ${DEST_PATH_SERVER}

	    cp -vf ${OUT}/obj/CGEN/APDB_MT*W15* ${DEST_PATH_SERVER}/database/ap
	    cp -vf ${OUT}/system/etc/mddb/BPLGUInfoCustomAppSrcP* ${DEST_PATH_SERVER}/database/moden

        echo "---> cp image end ... in $server_name"
        echo
        if [ $flag_fota -eq 1 ];then
            cp -v ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH_SERVER}/sdupdate.zip
            cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH_SERVER}/${system_version}.zip
            echo "cp ota end ... in $server_name"
            echo
        fi
    fi

    echo "cpimage finish ... in $server_name"
    echo
}

## print variable
function print_variable()
{
	echo "cpu_num = $cpu_num"
	echo '-----------------------------------------'
	echo "build_prj_name = $build_prj_name"
    echo "project_name = $project_name"
    echo "custom_version = $custom_version"
	echo '-----------------------------------------'
    echo "prefect_name = $prefect_name"
    echo "file_project = $file_project"
    echo "file_project = $file_name"
    echo "file_version = $file_version"
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
	echo "\$6 = $6"
	echo "\$# = $#"
	echo '-----------------------------------------'
    echo
}

#### 复制差异化文件
function cpcustoms()
{
    local select_project=$prefect_name
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

    #echo "ProductSetShort = $ProductSetShort"
    for custom_project in $ProductSetShort
    do
        if [ "$select_project"  == $custom_project ];then
            MySEL=$custom_project
        fi
    done
	local ProductSelPath="$ProductSetTop/$MySEL"

    #echo "ProductSelPath = $ProductSelPath"
    #echo "MySEL = $MySEL"
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
    local app_file=~/workspace/script/zzzzz-script/allapp.txt
	local app_path=packages/apps
	local default_branch="master origin/master"
	local ssh_link=ssh://jenkins@gerrit2.spt-tek.com:29418

    echo
    echo "---------------------------"
    echo "-   project_name = $project_name   -"
    echo "---------------------------"
    echo
    if [ $project_name == "k86l" -o $project_name == "k86s6" -o $project_name == "k86s7" ];then
        default_branch="long origin/long"
    fi

	cd $app_path > /dev/null

    while read app_name
    do
		#echo ${app_name}
		if [ -d $app_name ];then
			cd $app_name > /dev/null
			git pull
			echo "-------------- pull $app_name"
            echo
			cd .. > /dev/null
		else
			git clone $ssh_link/$app_name
			echo "-------------- clone $app_name"
            echo
			if [ $app_name == "CarEngine"  -o $app_name == "CarRecordDouble" ];then
				if [ "$default_branch" != "master origin/master" ];then
                    echo "app_name = $app_name"
                    echo "default_branch = $default_branch"
                    cd $app_name > /dev/null
				    git checkout -b ${default_branch}
                    echo
				    cd .. > /dev/null
                fi
			fi
		fi
    done < $app_file

    echo
    echo "--> clone app or pull app end ..."
	echo
	cd $OLDP > /dev/null
}


function clone_app_old()
{
	local OLDP=`pwd`
	local remote_name="master origin/master"
	local app_path=packages/apps
	local ssh_link=ssh://jenkins@gerrit2.spt-tek.com:29418
	local default_branch="master origin/master"

	echo "project_name = $project_name"

	if [ $project_name == "k86a" -o $project_name == "k86m" -o $project_name == "k86sm" -o $project_name == "k86sa" ];then
		k86a_app+=("${commond_app[@]}")
		allapp+=("${k86a_app[@]}")
	elif [ $project_name == "k86l" -o $project_name == "k86s6" -o $project_name == "k86s7" ];then
		k86l_app+=("${commond_app[@]}")
		allapp+=("${k86l_app[@]}")
		default_branch="long origin/long"
	elif [ $project_name == "k86s" -o $project_name == "k86sa1" ];then
		k86s_app+=("${commond_app[@]}")
		allapp+=("${k86s_app[@]}")
	elif [ $project_name == "k26a" ];then
		k26a_app+=("${commond_app[@]}")
		allapp+=("${k26a_app[@]}")
	elif [ $project_name == "k26s" ];then
		k26s_app+=("${commond_app[@]}")
		allapp+=("${k26s_app[@]}")
	elif [ $project_name == "k88" ];then
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

    if [ $project_name == "k86a" -o $project_name == "k86m" ];then
        defalut=k86A
    elif [ $project_name == "k86s" -o $project_name == "k86sm" -o $project_name == "k86sa" -o $project_name == "k86sa1" ] ;then
        defalut=k86s
    elif [ $project_name == "k86l" -o $project_name == "k86s6" -o $project_name == "k86s7" ];then
        defalut=k86s_400x1280
    elif [ $project_name == "k88" ];then
        defalut=k88
    elif [ $project_name == "k26a" -o $project_name == "k26b" -o $project_name == "k26s" ];then
        defalut=K26
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

    if make clean-lk;then
		echo "--> make clean lk end ..."
        echo
    else
		echo "--> make clean lk fail ..."
        echo
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

function sync_jenkins_server()
{
    local firmware_path=~/debug
    local share_path=~/workspace/share
    local jenkins_server=jenkins@s4.y
    local server_name=`hostname`

    if [ $server_name == "s1" -o $server_name == "s2" -o $server_name == "s3" ];then
        rsync -av $firmware_path $jenkins_server:$share_path

        echo
        echo "--> sync end ..."
        echo
    fi
}

function update_yunovo_customs_auto()
{
	local nowPwd=$(pwd)
    local sz_project_name=`echo k26 k86s k86a k86l`
    local sz_base_path=~/jobs
    local sz_yunovo_path=
    local sz_yunovo_customs_link=
    local sz_yunovo_customs_path=

    for sz_custom in $sz_project_name
    do
        sz_yunovo_customs_path=$sz_base_path/$sz_custom/yunovo_customs
        sz_yunovo_customs_link=`echo ssh://jenkins@s4.y/home/jenkins/workspace/git_server/$sz_custom/yunovo_customs.git`

        #echo "sz_custom = $sz_custom"
        if [ -d $sz_yunovo_customs_path/.git ];then
            #echo "sz_yunovo_customs_path = $sz_yunovo_customs_path"
            cd $sz_yunovo_customs_path > /dev/null

            if [ `hostname` == "s4" ];then
                git pull $sz_custom master && echo "-------- $sz_custom yunovo_customs update successful ..."
                echo
            else
                git pull && echo "-------- $sz_custom yunovo_customs update successful ..."
                echo
            fi
            cd - > /dev/null
        else
            sz_yunovo_path=$sz_base_path/$sz_custom
            mkdir -p $sz_yunovo_path

            cd $sz_yunovo_path > /dev/null
            echo $sz_yunovo_customs_link
            git clone $sz_yunovo_customs_link
            echo
            cd - > /dev/null
        fi
    done

	cd $nowPwd
}

function main()
{
    if [ $flag_print -eq 1 ];then
	    print_variable $build_prj_name $build_version $build_device $build_type $build_skd_flag $build_file
    else
        echo "do not anythings output !"
    fi

    ## auto update
    update_yunovo_customs_auto

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
	    if cpimage;then
            sync_jenkins_server
        fi
    else
        echo "do not cp image !"
    fi
}

main
