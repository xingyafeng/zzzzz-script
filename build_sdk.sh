#!/bin/bash

### 若某一个命令返回非零值就退出
set -e

#set java env
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$CLASSPATH:$JAVA_HOME/lib:$JRE_HOME/lib
export PATH=${JAVA_HOME}/bin:$JRE_HOME/bin:$PATH
export LANGUAGE=en_US
export LC_ALL=en_US.UTF-8

################################## args

### build custom
build_device=$1
### build sdk flag, e.g. : ota.print.download.clone.make.cp
build_flag=$2
### build project name  e.g. : K86_H520
build_prj_name=$3
### eg: k86l_yunovo_zx
build_file=$4
### eng|user|userdebug
build_type=
### test
build_test=
### make update-api
build_update_api=

## system version  e.g. : S1.01
build_version=""
## project name for system k26 k86 k86A k86m k88
project_name=""
### custom version H520 ZX etc
custom_version=""

### system version and tag version
tag_version=""

### S1.00 S1.01 ...
first_version=""
second_version=""

### 1.00 1.01 ...
first_tag_version=""
second_tag_version=""

### flag for main (0 or 1)
flag_fota=
flag_print=
flag_download_sdk=
flag_clone_app=
flag_make_sdk=
flag_cpimage=
flag_cpcustom=

flag_jenkins_tag=

################################# common variate
hw_versiom=H3.1
branch_nane=develop
cur_time=`date +%m%d_%H%M`
zz_script_path=/home/jenkins/workspace/script/zzzzz-script
cpu_num=`cat /proc/cpuinfo  | egrep 'processor' | wc -l`
project_link="init -u git@src1.spt-tek.com:projects/manifest.git"
tmp_file=$zz_script_path/tmp.txt
lunch_project=
prefect_name=
system_version=
fota_version=

### project name for yunovo
k26P=k26
k86aP=k86a
k86mP=k86m
k86sP=k86s
k86smP=k86sm
k86lP=k86l
k86lsP=k86ls
k88cP=k88c
k86ldP=k86ld

################################ system env
DEVICE=
ROOT=
OUT=

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

function __msg()
{
    local pwd=`pwd`
    echo "currect dir is : $pwd"
}

### 检查是否有lunch
function is_check_lunch()
{
    if [ "$DEVICE" ];then
        echo "lunch : path $DEVICE"
    else
        echo "no lunch"
    fi
}

### 去除变量存在的空格
function remove_space_for_vairable()
{
    ## 去掉空格后的变量
    local new_v=
    local old_v=$1

    new_v=`cat $tmp_file | sed 's/[  ]\+//g'`
    if [ "$new_v" != "$old_v" ];then
        echo $new_v
    else
        echo $old_v
    fi

    if [ -f $tmp_file ];then
        rm $tmp_file
    fi
}

### 是否为云智易联项目
function is_yunovo_project
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    if [ $thisP == $k26P -o $thisP == $k86aP -o $thisP == $k86mP -o $thisP == $k86sP -o $thisP == $k86smP -o  $thisP == $k86lP -o $thisP == $k86lsP -o $thisP == $k88cP -o $thisP == $k86ldP ];then
        echo true
    else
        echo false
    fi
}

function get_project_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    if [ "$thisP" ];then
        echo $thisP
    else
        echo "do not get project name !"
    fi
}

### 是否为编译服务器
function is_yunovo_server()
{
    local hostN=`hostname`
    local serverN=(s1 s2 s3 s4 happysongs ww)

    for n in ${serverN[@]}
    do
        if [ "$n" == "$hostN"  ];then
            echo true
        fi
    done
}

### 是否为使用的芯片类型
function is_build_device()
{
    local cpu_type_more=(aeon6735_65c_s_l1 aeon6735m_65c_s_l1 magc6580_we_l)
    local cpu_type=$1

    for c in ${cpu_type_more[@]}
    do
        if [ $c == $cpu_type ];then
            echo true
        fi
    done
}

### 是否是正确的编译类型
function is_build_type()
{
    local build_type_more=(eng user userdebug)
    local buildT=$1

    for t in ${build_type_more[@]}
    do
        if [ $t == $buildT ];then
            echo true
        fi
    done
}

### 是否为长屏分支的app
function is_long_branch_app()
{
    local check_long_app=$1
    local long_branch_app_name=(CarEngine CarRecordDouble NewsmyNewyan NewsmyRecorder NewsmySPTAdapter)

    for a in ${long_branch_app_name[@]}
    do
        if [ $a == $check_long_app ];then
            echo true
        fi
    done
}

function checkout_debug_info()
{
    local which_flag=(1 2 3 4 5 6 7)
    local flag=""

    for f in ${which_flag[@]}
    do
        flag=`cat $tmp_file | cut -d '.' -f${f}`

        if [ -z $flag ];then
            return 1
        fi

        if [ "$flag" == "0" -o "$flag" == "1" ];then
            continue
        else
            return 1
        fi
    done

    echo true
}

### 获取debug配置信息
function get_debug_info()
{
    local build_flag=$1
    local which_flag=(1 2 3 4 5 6 7)

    for f in ${which_flag[@]}
    do
        case $f in
            1)
                flag_fota=`echo $build_flag | cut -d '.' -f${f}`
                ;;
            2)
                flag_print=`echo $build_flag | cut -d '.' -f${f}`
                ;;
            3)
                flag_download_sdk=`echo $build_flag | cut -d '.' -f${f}`
                ;;
            4)
                flag_clone_app=`echo $build_flag | cut -d '.' -f${f}`
                ;;
            5)
                flag_make_sdk=`echo $build_flag | cut -d '.' -f${f}`
                ;;
            6)
                flag_cpimage=`echo $build_flag | cut -d '.' -f${f}`
                ;;
            7)
                flag_cpcustom=`echo $build_flag | cut -d '.' -f${f}`
                ;;
        esac
    done
}

### handler vairable for jenkins
function handler_vairable()
{
    local tag_file=~/workspace/script/zzzzz-script/apptag.txt

    local prj_name=`get_project_name`

    local sz_build_project=$1
    local sz_build_device=$2
    local sz_build_file=$3
    local sz_build_flag=$4

    ### 1. project name
    if [ "$sz_build_project" ];then

        ### remove space
        echo "$sz_build_project" > $tmp_file
        sz_build_project=`remove_space_for_vairable $sz_build_project`

        ## 检查是否是要进行编译的工程
        if [ -n "`echo $sz_build_project | grep $prj_name`" ];then
            build_prj_name=$sz_build_project

            project_name=${build_prj_name%%_*}
            custom_version=${build_prj_name##*_}

            if [ -z "$project_name" -o  -z "$custom_version" ];then
                echo "project_name or custom_version is null ."
                return 1
            fi
        else
            echo "build_prj_name is error, please checkout it ."
            return 1
        fi
    else
        echo "sz_build_project is null !"
        return 1
    fi

    ### 2. build version
    if [ "$yunovo_version" ];then

        ### remove space
        echo "$yunovo_version" > $tmp_file
        yunovo_version=`remove_space_for_vairable $yunovo_version`

        ## 检查版本号是否是以S开头
        if [ -n "`echo $yunovo_version | sed -n '/^S/p'`" ];then
            build_version=$yunovo_version

            first_version=${build_version%.*}
            second_version=${build_version##*.}
            if [ -z "$first_version" -o -z "$second_version" ];then
                echo "first_version or second_version is null !"
                return 1
            fi
        else
            echo "build_version is error, please checkout it ."
            return 1
        fi
    else
        echo "yunovo_version is null !"
        return 1
    fi

    ### 3. build device
    if [ "$sz_build_device" ];then

        ### remove space
        echo "$sz_build_device" > $tmp_file
        sz_build_device=`remove_space_for_vairable $sz_build_device`

        if [ `is_build_device $sz_build_device` == "true" ];then
            build_device=$sz_build_device
        else
            echo "build_device is error, please checkout it"
            return 1
        fi
    else
        echo "build_device is null !"
    fi

    ### 4. build type
    if [ "$yunovo_type" ];then

        ### remove space
        echo "$yunovo_type" >$tmp_file
        yunovo_type=`remove_space_for_vairable $yunovo_type`

        if [ `is_build_type $yunovo_type` == "true" ];then
            build_type=$yunovo_type
        else
            ## jenkins 填写不符合规范，默认为user
            build_type=user
        fi
    else
        ## jenkins　不填写，默认为user
        build_type=user
    fi

    if [ "$build_device" -a "$build_type" ];then
        lunch_project=full_${build_device}-${build_type}
    else
        echo "lunch_project is null !"
        return 1
    fi

    ### 5. build flag
    if [ "$sz_build_flag" ];then

        ### remove space
        echo "$sz_build_flag" > $tmp_file
        sz_build_flag=`remove_space_for_vairable $sz_build_flag`

        ## 保存至文件中
        echo $sz_build_flag > $tmp_file

        if [ "`checkout_debug_info`" == "true" ];then
            build_flag=$sz_build_flag

            get_debug_info $build_flag
            ### 处理完成后，删除$tmp_file
            if [ $? -eq 0 ];then
                rm $tmp_file -r
            else
                echo "get_debug_info error . please checkout it ."
                return 1
            fi
        else
            echo "build_flag is error, please checkout it !"
            return 1
        fi
    else
        echo "build_sdk_flag is null !"
        return 1
    fi

    ### 6. build file
    if [ "$sz_build_file" ];then

        ### remove space
        echo "$sz_build_file" > $tmp_file
        sz_build_file=`remove_space_for_vairable $sz_build_file`

        if [ `echo $sz_build_file | grep $prj_name | egrep /` ];then
            prefect_name=$sz_build_file
        else
            echo "build_file is error, please checkout it !"
            return 1
        fi
    else
        echo "sz_build_file is null !"
        return 1
    fi

    ### 7. build test
    if [ "$yunovo_test" ];then
        build_test=$yunovo_test
    else
        build_test=false
    fi

    ### 8. build make update-api
    if [ "$yunovo_update_api" ];then
        build_update_api=$yunovo_update_api
    else
        build_update_api=false
    fi

    if [ "$yunovo_tag" ];then

        ### remove space
        echo "$yunovo_tag" > $tmp_file
        yunovo_tag=`remove_space_for_vairable $yunovo_tag`

        tag_version=$yunovo_tag

        if [ "$tag_version" == "all" -o "$tag_version" == "ALL" ];then
            ### tag version 1.00 1.02 ... 2.00 2.01 ...
            first_tag_version=9
            second_tag_version=99
        else
            if [ "`echo $tag_version | grep '.'`" ];then
                ### tag version 1.00 1.02 ... 2.00 2.01 ...
                first_tag_version=${tag_version%.*}
                second_tag_version=${tag_version##*.}
            else
                echo "tag_version is error ! please check it !"
                return 1
            fi
        fi
    else
        while read apptag;do
            tag_version=${apptag##*=}
            first_tag_version=${tag_version%.*}
            second_tag_version=${tag_version##*.}
        done < $tag_file
    fi

    system_version=$custom_version\_$hw_versiom\_${first_version}.${project_name}.${second_version}
    fota_version="SPT_VERSION_NO=${system_version}"
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
		cd $tDir > /dev/null
        if [ "`git status -s`" ];then
            echo "---- recover $tDir"
        else
            cd $OLDPWD
            return 0
        fi

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

#### 恢复默认配置文件 android
function recover_standard_android_project()
{
	local tOldPwd=$OLDPWD
	local tNowPwd=$PWD
	cd $(gettop)
	#echo "now get all project from repo..."

	local AllRepoProj=`chiphd_get_repo_git_path_from_xml`
    #echo $AllRepoProj
	if [ "$AllRepoProj" ]; then
		for ProjPath in $AllRepoProj
		do
            if [ -d $(gettop)/$ProjPath ];then
                if [ $ProjPath != "packages" ];then
                    chiphd_recover_project $ProjPath
                fi
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
	local BASE_PATH=$firmware_path/${project_name}/${prj_name}/${ver_name}
	local DEST_PATH=$BASE_PATH/$system_version
	local OTA_PATH=$BASE_PATH/${system_version}_full_and_ota

    local server_name=`hostname`
    local firmware_path_server=/home/share/jenkins_share/debug
    local test_path_server=/home/share/jenkins_share/Test

    local TEST_DEST_PATH_SERVER=$test_path_server/$prj_name
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

    if [ "`is_yunovo_server`" == "true" ];then
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

	    if [ -e ${OUT}/trustzone.bin ];then
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

        if [ ! -d $test_path_server ];then
            mkdir -p $test_path_server
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

        if [ $build_test == "true" ];then
            if [ ! -d $TEST_DEST_PATH_SERVER ];then
                mkdir -p $TEST_DEST_PATH_SERVER
            fi
            mv $BASE_PATH_SERVER $TEST_DEST_PATH_SERVER
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
	echo '-----------------------------------------'
	echo "build_version = $build_version"
    echo "first_version = $first_version"
    echo "second_version = $second_version"
	echo '-----------------------------------------'
    echo "tag_version = $tag_version"
    echo "first_tag_version = $first_tag_version"
    echo "second_tag_version = $second_tag_version"
	echo '-----------------------------------------'
	echo "build_device = $build_device"
	echo "build_type = $build_type"
	echo "lunch_project = $lunch_project"
	echo '-----------------------------------------'
    echo "flag_fota = $flag_fota"
    echo "flag_print = $flag_print"
    echo "flag_download_sdk = $flag_download_sdk"
    echo "flag_clone_app = $flag_clone_app"
    echo "flag_make_sdk = $flag_make_sdk"
    echo "flag_cpimage = $flag_cpimage"
    echo "flag_cpcustom = $flag_cpcustom"
	echo '-----------------------------------------'
    echo "yunovo_test = $yunovo_test"
    echo "yunovo_update_api = $yunovo_update_api"
	echo '-----------------------------------------'

	echo "\$1 = $1"
	echo "\$2 = $2"
	echo "\$3 = $3"
	echo "\$4 = $4"
	echo "\$5 = $5"
	echo "\$6 = $6"
	echo "\$7 = $7"
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

function handler_custom_config()
{
    local hardware_config=HardWareConfig.mk
    local project_config=ProjectConfig.mk
    local bootable_config=${DEVICE_PROJECT}.mk
    local boot_logo_config=boot_logo.mk
    local bootable_config_path=bootable/bootloader/lk/project
    local hardware_config_file=$ROOT/$DEVICE/$hardware_config
    local project_config_file=$ROOT/$DEVICE/$project_config
    local boot_logo_config_file=$ROOT/$bootable_config_path/$boot_logo_config
    local bootable_config_file=$ROOT/$bootable_config_path/$bootable_config

    local src_boot_logo=
    local src_boot_logo_other=`echo BOOT_LOGO=cmcc_lte_qhd`
    local src_boot_logo_k26=`echo BOOT_LOGO := cmcc_lte_hd720`
    local src_boot_logo_k88=`echo BOOT_LOGO=cu_lte_wvga cmcc_lte_hd720`


    ### handler customs config file
    if [ -f $hardware_config_file -a -f $project_config_file ];then
        cat $hardware_config_file >> $project_config_file

        if [ $? -eq 0 ];then
            rm $hardware_config_file
        else
            echo "cat fail and >> file !"
            return 1
        fi

        echo
        echo "--------------------------------"
        echo "-   1.hardware config modify   -"
        echo "--------------------------------"
    fi

    while read sz_boot_logo
    do
        #echo "$sz_boot_logo"
        if [ "$sz_boot_logo" == "$src_boot_logo_other" ];then
            src_boot_logo=$src_boot_logo_other
        elif [ "$sz_boot_logo" == "$src_boot_logo_k26" ];then
            src_boot_logo=$src_boot_logo_k26
        elif [ "$sz_boot_logo" == "$src_boot_logo_k88" ];then
            src_boot_logo=$src_boot_logo_k88
        fi
    done < $bootable_config_file

    if [ -f $boot_logo_config_file -a -f $bootable_config_file ];then
        local dest_boot_logo=`cat $boot_logo_config_file`

        #echo "src_boot_logo = $src_boot_logo"
        #echo "dest_boot_logo = $dest_boot_logo"

        if [ "$src_boot_logo" ];then
            sed -i "s/${src_boot_logo}/${dest_boot_logo}/g" $bootable_config_file
            if [ $? -eq 0 ];then
                rm $boot_logo_config_file
            else
                echo "sed fail ..."
                return 1
            fi
        else
            echo "src_boot_logo is null !"
            return 1
        fi

        echo
        echo "---------------------------------"
        echo "-   2.boot logo config modify   -"
        echo "---------------------------------"
        echo

    fi

    if false;then
        echo "-----------------------------------------------"
        echo "pwd = `pwd`"
        echo "DEVICE = $DEVICE"
        echo "hardware_config_file = $hardware_config_file"
        echo "project_config_file  = $project_config_file"

        echo "boot_logo_config_file = $boot_logo_config_file"
        echo "bootable_config_file = $bootable_config_file"

        echo "-----------------------------------------------"
    fi
}

function handler_tag_branch()
{
    local branch_nane=$1
    local tag_name=$2
    local app_name=$3

    #echo "branch_nane = $branch_nane"
    #echo "tag_name = $tag_name"
    #echo "app_name = $app_name"

    ### 检查是否有打相关的tag
    if [ "`git tag | grep $tag_name$first_tag_version.$second_tag_version`" ];then

        ### 检查是否已经检出tag分支
        if [ "`git branch | grep $tag_name$first_tag_version.$second_tag_version`" ];then
            ### 检查当前分支是否是tag分支
            if [ "`git branch -a | grep \* | cut -d ' ' -f2`" != "$tag_name$first_tag_version.$second_tag_version" ];then
                ### 切换到相关tag分支
                git checkout $tag_name$first_tag_version.$second_tag_version && echo "-------- switch $tag_name tag $app_name"
                echo
            fi
        else
            ### 检出相关tag分支
            git checkout -b $tag_name$first_tag_version.$second_tag_version $tag_name$first_tag_version.$second_tag_version
            echo "-------- switch $tag_name tag -b $app_name"
            echo
        fi
    ### 没有打相关tag, 用于处理中性软件
    else
        ### 检出当前分支是否在long分支
        if [ "`git branch -a | grep \* | cut -d ' ' -f2`" != "$branch" ];then
            ### 切换到long分支,并且更新代码
            git checkout $branch && echo "-------- switch $branch $app_name"
            echo
        fi
    fi
}

function clone_app()
{
	local OLDP=`pwd`
    local app_file=~/workspace/script/zzzzz-script/allapp.txt
    local yunovo_apk_file=~/workspace/script/zzzzz-script/yunovo_apk.txt
    local yunovo_app_file=~/workspace/script/zzzzz-script/yunovo_app.txt
	local app_path=packages/apps
	local default_branch="master origin/master"
	local ssh_link=ssh://jenkins@gerrit2.spt-tek.com:29418
	local branch_nane=
	local tag_name=

    echo "---------------------------"
    echo "-   project_name = $project_name   -"
    echo "---------------------------"
    echo

    local prj_name=$(pwd) && prj_name=${prj_name%/*} && prj_name=${prj_name##*/}

    if [ $prj_name == "k86l" -o $prj_name == "k86ld" ];then
        default_branch="long origin/long"
    fi

    if [ $project_name == "k26c" ];then
        default_branch="long origin/long"
    fi

	cd $app_path > /dev/null

    while read app_name
    do
		#echo ${app_name}
		if [ -d $app_name ];then
            ### 第三方apk 不进行tag分支处理
            while read apk_name
            do
                if [ $apk_name == $app_name  ];then
                    cd $app_name > /dev/null
                    git pull && echo "-------------- pull $app_name"
                    echo
                fi
            done < $yunovo_apk_file

            ### 客户化apk进行tag处理
            while read app_name_yunovo
            do
                ### 临时处理DT-M40
                if [ $build_prj_name == "k86a_DT-M40" -a $app_name == "CarRecord" -a $app_name_yunovo == "CarRecord" ];then
                    echo "build_prj_name = $build_prj_name"
                    continue
                fi

                if [ $app_name == $app_name_yunovo ];then
                    cd $app_name > /dev/null

                    ### 确保每次分支都在master or long
                    ### 检查是否是是long分支
                    if [ "$default_branch" != "master origin/master" ];then
                        if [ "`is_long_branch_app $app_name`" == "true" ] ;then
                            if [ "`git branch -a | grep \* | cut -d ' ' -f2`" != "long"  ];then
                                git checkout long
                                git pull && echo "-------------- pull $app_name"
                                echo
                            else
                                git pull && echo "-------------- pull $app_name"
                                echo
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
                    fi

                    ### i.特殊apk 处理
                    if [ "`is_long_branch_app $app_name`" == "true" ];then
                        ### ii. 处理long tag
                        if [ "$default_branch" != "master origin/master" ];then
                            branch_nane=long
                            tag_name=L
                        ### ii. 处理 master tag
                        else
                            branch_nane=master
                            tag_name=M
                        fi
                    ### i.其他apk处理  master tag
                    else
                        branch_nane=master
                        tag_name=M
                    fi

                    if [ "$branch_nane" -a "$tag_name" -o "$app_name" ];then
                        ### 处理不同分支tag
                        handler_tag_branch $branch_nane $tag_name $app_name
                    fi
                fi
            done < $yunovo_app_file

            cd .. > /dev/null
		else
			git clone $ssh_link/$app_name
			echo "-------------- clone $app_name"
            echo
			if [ "`is_long_branch_app $app_name`" == "true" ];then
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

    echo "--> clone app or pull app end ..."
	echo
	cd $OLDP > /dev/null
}

## download sdk
function download_sdk()
{
    local project_name=`get_project_name`
    local defalut=

    if [ "$project_name" ];then
        if [ $project_name == "k86a" -o $project_name == "k86m" ];then
            defalut=k86A
        elif [ $project_name == "k86s" -o $project_name == "k86sm" ] ;then
            defalut=k86s
        elif [ $project_name == "k86l" ];then
            defalut=k86s_400x1280
        elif [ $project_name == "k86ls" ];then
            defalut=k86l_split
        elif [ $project_name == "k88c" ];then
            defalut=k88
        elif [ $project_name == "k26" ];then
            defalut=K26
        else
            echo "project do not match it !"
            return 1
        fi
    else
        echo "project path do not found !"
        return 1
    fi

    echo "defalut = $defalut"

	if [ ! -d .repo ];then
		if [ "$defalut" -a "$project_link" ];then
            repo $project_link -m ${defalut}.xml
        fi
		repo sync -j${cpu_num}
        ls -alF

        if [ "$defalut" == "K26" -o "$defalut" == "k86A" ];then
            defalut=master
        fi

        if [ $defalut ];then
            repo start $defalut --all
        fi

        ## 第一次下载完成后，需要初始化环境变量
        if [ -d .repo ];then
            source_init
        else
            echo "The (.repo) not found ! please download sdk !"
            return 1
        fi
	else
        if [ `is_yunovo_server` == "true" ];then
            ## 还原 androiud源代码 ...
            recover_standard_android_project

            ## 更新 android源代码 ...
		    repo forall -c git fetch
            echo "-----------------git fetch successful ."
            echo

		    repo forall -c git pull
            echo "-----------------git pull successful ."
		    echo
        fi
	fi
}

## build sdk for yunovo project
function make-sdk()
{
	if [ "$DEVICE" ];then
        :
    else
        if [ -d .repo ];then
            source_init
        else
            echo "The (.repo) not found ! please download sdk !"
            return 1
        fi
    fi

	if make installclean;then
		echo "--> make installclean end ..."
		echo
    else
        echo "---> make installclean failed !"
        return 1
	fi

	if [ -n "$(find . -maxdepth 1 -name "build*.log" -print0)" ];then
		delete_log
    else
        echo "log is not delete, please checkout it ! "
	fi

    if make clean-lk;then
		echo "--> make clean lk end ..."
        echo
    else
		echo "--> make clean lk fail ..."
        echo
        return 1
    fi

    if [ "$cpu_num" -gt 0 ];then
        :
    else
        echo "cpu_num in not number ..."
        return 1
    fi

    make -j${cpu_num} ${fota_version} 2>&1 | tee build_$cur_time.log
    if [ $? -eq 0 ];then
        echo "--> make project end ..."
        echo
    else
        echo "make android failed !"
        echo
        return 1
    fi

    if [ $flag_fota -eq 1 ];then
        make -j${cpu_num} ${fota_version} otapackage 2>&1 | tee build_ota_$cur_time.log

        if [ $? -eq 0 ];then
            echo "--> make otapackage end ..."
        else
            echo "make otapackage failed !"
            echo
            return 1
        fi
    fi
}

function sync_jenkins_server()
{
    local firmware_path=~/debug
    local share_path=/public/jenkins/jenkins_share_20T
    local jenkins_server=jenkins@f1.y

    if [ "`is_yunovo_server`" == "true" ];then
        if [ $build_test == "true" ];then
            rsync -av $firmware_path/ $jenkins_server:$share_path/Test
        else
            rsync -av $firmware_path $jenkins_server:$share_path
        fi

        if [ -d $firmware_path ];then
            rm $firmware_path/* -rf
        else
            echo "$firmware_path not found !"
        fi

        echo "--> sync end ..."
        echo
    fi
}

function auto_update_yunovo_customs()
{
	local nowPwd=$(pwd)
    local sz_project_name=`echo k26 k86a k86m k86s k86sm k86l k86ls k88c`
    local sz_base_path=~/jobs

    for sz_custom in $sz_project_name
    do
        if [ "`get_project_name`" == "$sz_custom" ];then
            local sz_yunovo_customs_path=$sz_base_path/$sz_custom/yunovo_customs
            local sz_yunovo_customs_link=`echo /home/jenkins/workspace/git_server/$sz_custom/yunovo_customs.git`
            local sz_yunovo_customs_link_server=`echo ssh://jenkins@s4.y/home/jenkins/workspace/git_server/$sz_custom/yunovo_customs.git`
            local sz_yunovo_path=$sz_base_path/$sz_custom
        else
            continue
        fi

        if [ -d $sz_yunovo_customs_path/.git ];then

            cd $sz_yunovo_customs_path > /dev/null
            git pull && echo "-------- $sz_custom yunovo_customs update successful ..."
            echo

            cd - > /dev/null
        else
            if [ ! -d $sz_yunovo_path ];then
                mkdir -p $sz_yunovo_path
            fi

            cd $sz_yunovo_path > /dev/null

            if [ `hostname` == "s4" ];then
                if [ "$sz_yunovo_customs_link" ];then
                    echo
                    echo "custom link = $sz_yunovo_customs_link"
                    echo

                    git clone $sz_yunovo_customs_link
                    echo
                else
                    echo "$sz_yunovo_customs_link not found !"
                fi
            else
                if [ "$sz_yunovo_customs_link_server" ];then
                    echo
                    echo "custom link = $sz_yunovo_customs_link_server"
                    echo

                    git clone $sz_yunovo_customs_link_server
                    echo
                else
                    echo "$sz_yunovo_customs_link_server not found !"
                fi
            fi

            cd - > /dev/null
        fi
    done

	cd $nowPwd
}

### 打印系统环境变量
function print_env()
{
    echo "ROOT = $(gettop)"
    echo "OUT = $OUT"
    echo "DEVICE = $DEVICE"
    echo
}

function source_init()
{
    local magcomm_project=magc6580_we_l
    local eastaeon_project=aeon6735_65c_s_l1
    local eastaeon_project_m=aeon6735m_65c_s_l1

    source  build/envsetup.sh
    echo
    echo "--> source end ..."
    echo

    lunch $lunch_project
    echo "--> lunch end ..."
    echo

    ROOT=$(gettop)
    OUT=$OUT
    DEVICE_PROJECT=`get_build_var TARGET_DEVICE`

    if [ $DEVICE_PROJECT == $magcomm_project ];then
        DEVICE=device/magcomm/$DEVICE_PROJECT
    elif [ $DEVICE_PROJECT == $eastaeon_project -o $DEVICE_PROJECT == $eastaeon_project_m ];then
        DEVICE=device/eastaeon/$DEVICE_PROJECT
    else
        DEVICE=device/eastaeon/$DEVICE_PROJECT
        echo "DEVICE do not match it ..."
    fi
    print_env
}

function main()
{
    if [ "`is_yunovo_project`" == "true" ];then
        :
    else
        echo "current directory is not android !"
        return 1
    fi

    if [ "`is_yunovo_server`" == "true" ];then
        echo
        echo "---> make android start ."
        echo
    else
        echo "server name is not s1 s2 s3 s4 happysongs ww !"
        return 1
    fi

    if [ "$build_prj_name" -a "$build_device" -a "$build_file" -a "$build_flag"  ];then
        ### 处理输入参数，并检查其有效性...
        handler_vairable $build_prj_name $build_device $build_file $build_flag
    else
        echo "xargs is error ,please checkout xargs ."
        return 1
    fi

    if [ $flag_print -eq 1 ];then
	    print_variable $build_prj_name $build_version $build_device $build_type $build_flag $build_file $build_test
    else
        echo "it is not print variable . please checkout your flag_print !"
    fi

    if [ -d .repo ];then
        ### 初始化环境变量
        if [ "`is_check_lunch`" == "no lunch" ];then
            source_init
        else
            print_env
        fi
    fi

    ## auto update customs
    auto_update_yunovo_customs

    if [ $flag_download_sdk -eq 1 ];then
        ### download source code
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

        if [ "`is_check_lunch`" == "no lunch" ];then
            echo "current directory is not android ! gettop is null !"
            return 1
        else
            cpcustoms
            handler_custom_config
        fi
    else
        echo "do not cp customs !"
    fi

    if [ "$build_update_api" == "true" ];then
        make update-api -j${cpu_num}
        if [ $? -eq 0 ];then
            echo "---> make update-api end !"
        else
            echo "make update-api fail !"
            return 1
        fi
    else
        echo "do not make update-api !"
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

    if [ "`is_yunovo_server`" == "true" ];then
        echo
        echo "---> make android end ."
        echo
    else
        echo "server name is not s1 s2 s3 s4 happysongs ww !"
        return 1
    fi
}

main
