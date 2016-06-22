#!/bin/bash

### ota path
ota_target_file=out/target/product/*/obj/PACKAGING/target_files_intermediates

function make_target
{
	if get_uboot;then
		show_vip "--> get uboot end."
		if make target-files-package;then
			show_vip "--> make target file end."
		fi
	fi
}

function make-target
{
	if make_target;then
		if [ -d $ota_target_file ];then
			mv $ota_target_file/*.zip ./old_target_files.zip
		fi
	fi
}

function sync_ota_server()
{
    local ota_local_path=~/OTA
    local server_name=`hostname`
    local share_path=/home/share/jenkins_share
    local jenkins_server=jenkins@s4.y
    local custom_project=$1
    local custom_version=$2
    local ota_version_path=$3
    local ota_server_custom_path=$share_path/OTA/${custom_project}\_${custom_version}

    #echo "-------------"
    #echo "ota_version_path = $ota_version_path"
    #echo "ota_server_custom_path = $ota_server_custom_path"
    #echo "-------------"

    if [ $server_name == "s1" -o $server_name == "s2" -o $server_name == "s3" -o $server_name == "happysongs" -o $server_name == "siawen" ];then
        if [ -d $ota_local_path ];then
            rsync -av $ota_local_path $jenkins_server:$share_path
        fi
    elif [ $server_name == "s4" ];then
        if [ ! -d $ota_server_custom_path ];then
            mkdir -p $ota_server_custom_path
        fi

        if [ -d $ota_version_path -a -d $ota_server_path ];then
            mv $ota_version_path $ota_server_custom_path
        fi
    fi
}

function make-inc
{
    if [ $# -eq 2 ];then

        if [ "`is_make_project`" == "true" ];then
            echo
            show_vir "make inc start ..."
            echo
        else
            echo
            show_vir "please checkout your dirictory in xxx/androd/* "
            echo
            return 1
        fi
    else
        echo
        show_vir "------------------------------------------"
        show_vir "e.g : make-inc xxx.04.zip xxx.05.zip"
        show_vir "------------------------------------------"
        echo
        return 1
    fi

    local ota_py=./build/tools/releasetools/ota_from_target_files
    local ota_previous=$1
    local ota_current=$2
    local hardware_version=H3.1
    local software_version=S1
    local custom_project=$ota_previous && custom_project=${custom_project%.*} && custom_project=${custom_project%.*} && custom_project=${custom_project##*.}
    local custom_version=$ota_previous && custom_version=${custom_version%%_*}
    local firmware_prev_version=$ota_previous && firmware_prev_version=${firmware_prev_version%.*} && firmware_prev_version=${firmware_prev_version##*.}
    local firmware_curr_version=$ota_current && firmware_curr_version=${firmware_curr_version%.*} && firmware_curr_version=${firmware_curr_version##*.}
    local OTA_FILE=${custom_project}\_${custom_version}\_${hardware_version}\_${software_version}.${firmware_curr_version}\_for\_${software_version}.${firmware_prev_version}.zip

    local ota_local_path=~/OTA
    local ota_server_path=/home/share/jenkins_share
    local ota_version_path=$ota_local_path/${custom_project}\_${custom_version}/${software_version}.${firmware_curr_version}\_for\_${software_version}.${firmware_prev_version}

if false;then
    echo "ota_previous = $ota_previous"
    echo "ota_current = $ota_current"
    echo "custom_project = $custom_project"
    echo "custom_version = $custom_version"
    echo "firmware_prev_version = $firmware_prev_version"
    echo "firmware_curr_version = $firmware_curr_version"
    echo "OTA_FILE = $OTA_FILE"
    echo "ota_version_path = $ota_version_path"
fi

    if [ ! -d $ota_local_path ];then
        mkdir -p $ota_local_path
    fi

    if [ ! -d $ota_version_path ];then
        mkdir -p $ota_version_path
    fi

    if [ -e $ota_py -a "`is_make_project`" == "true" ];then
        $ota_py -i $td/$ota_previous $td/$ota_current $ota_version_path/$OTA_FILE
        cp -vf $td/$ota_previous $ota_version_path
        cp -vf $td/$ota_current $ota_version_path
    fi

    ### sync server for OTA
    sync_ota_server $custom_project $custom_version $ota_version_path

    if [ $? -eq 0 ];then
        rm $ota_local_path/* -r
    fi

    echo
    show_vir "make inc end ..."
    echo

if false;then
	if make otapackage_inc;then
		show_vip "--> make inc end."
	fi
fi
}

function show-make-android
{
	echo
	show_vir "##############################"
	show_vir "###    make android end.   ###"
	show_vir "##############################"

}

### make update
function make-update
{
	if make-android;then
		show-make-android
		if get_uboot;then
			show_vip "--> get uboot end."
			if make otapackage -j32;then
				mv $ota_target_file/*.zip ./old_target_files.zip
				show_vip "--> make all end."
			fi
		fi
	fi
}

### make uboot, lichee, android
function make-sdk
{
	local android_path=$(pwd)
	local lichee_path=$android_path/../lichee

#	echo "android_path = $android_path "
#	echo "lichee_path = $lichee_path"

	cd $lichee_path
	make-uboot
	echo
	echo
	make-lichee
	echo
	echo
	cd $android_path
	make-android
	show-make-android
}

### 注释掉
no() {
function show_inc
{
	show_vir "##############################"
	show_vir "###    make inc more end   ###"
	show_vir "##############################"
}
###dest path
ANDROID_TOP=$(gettop)
TARGET_PATH=$ANDROID_TOP/../target
EAGLE_PATH=$ANDROID_TOP/../eagle-inc

menu_target_name=(target_files_v1.0.zip target_files_v2.0.zip target_files_v3.0.zip target_files_v4.0.zip target_files_v5.0.zip)

### make inc
function make-inc-more
{
	echo $ANDROID_TOP
	echo $TARGET_PATH

	### create inc patch
	if [ ! -d $EAGLE_PATH ];then mkdir $EAGLE_PATH && show_vip "--> mkdir file ok.";fi

	if [ -d $TARGET_PATH ];then
		local target_name
		local i=1
		for target_name in "${menu_target_name[@]}";do
		#	show_vip $target_name

			if [ -f $TARGET_PATH/$target_name ];then
				if [ -f $ANDROID_TOP/old_target_files.zip ];then
					rm old_target_files.zip
					show_vip "--> rm old_target_files ."
				fi

				### cp target package
				if cp $TARGET_PATH/$target_name  $ANDROID_TOP/old_target_files.zip ;then
					show_vip "--> copy old_target_files.zip ."
					if make-inc;then
						### copy inc
						if [ -d $EAGLE_PATH ];then
							cp $OUT/*.zip $EAGLE_PATH/inc-v$i.0-v$(($i+1)).0.zip && show_vip "copy inc-xxx.zip ."
						fi
					fi
				fi
				show_vir "-------------------------"
				show_vir "- make inc $i count end -"
				show_vir "-------------------------"
				i=$(($i+1))
			fi
		done
	fi
	echo
	show_inc
	echo
}
}
