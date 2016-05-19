#!/bin/bash

test-readfs()
{
    while read line
    do
        echo $line
    done < allapp.txt
}

test-string()
{
	local var=chiphd

	# get string length
	local length=${#var}	

	show_vir $length
}


test-reboot()
{
	###
	echo reboot
}

test-jenkins()
{
	share_path=~/workspace/share_jenkins
	cur_time=`date +%m%d_%H%M`
	app_name=CarBack
	app_version=`cat $app_name/AndroidManifest.xml | grep android:versionName= | awk -F '"' '{print $2}'`

	if [[ ! -d $share_path/CarBack ]]; then
		#statements
		mkdir -p $jenkins_path/CarBack/
		if [[ $? -eq 0 ]]; then
			#statements
			cp output/CarBack.apk  $jenkins_path/CarBack/CarBack_$cur_time_$app_version.apk
		fi
	fi
}

function test-help()
{

	ret=$1
	if [ "$ret" == "--help" ];then

		echo "test help ..."
		return 0
	fi

	echo "you go here ..."

}


function clone_app()
{
        local remote_name="master origin/master"
        app=(1 2 3 4 5)
        commond_app=(FactoryTest CarEngine CarHomeBtn CarSystemUpdateAssistant CarPlatform GaodeMap KwPlayer UniSoundService)
        k86a_app=(CarUpdateDFU CarBack CarRecord GaodeNavigation GpsTester BaiduNavigation AnAnEDog)
        k86l_app=(CarUpdateDFU CarBack CarRecordDouble CarRecordUsb StormVideo GaodeNavigation XianzhiDSA)
        k86s_app=(CarUpdateDFU CarRecordDouble CarRecordUsb GpsTester BaiduNavigation AnAnEDog StormVideo)
        k26a_app=(CarRecord GpsTester BaiduNavigation)
        k26s_app=(CarRecordDouble CarRecordUsb GpsTester BaiduNavigation StormVideo)
        k88_app=(CarUpdateDFU CarBack CarRecord GaodeNavigation GpsTester BaiduNavigation AnAnEDog)


        for arr in ${commond_app[@]}; do
			#statements
			echo ${arr}
		done
		echo "========="
		#### support append index
        k86a_app+=("${commond_app[@]}")

        for arr in ${k86a_app[@]}; do
			#statements
			echo ${arr}
		done


}

if false;then

	a=(1 2 3)
	b=(a b c)

	fun()
	{
	   local a=($1)
	   local b=($2)
	   echo ${a[*]}
	   echo ${b[*]}
	}

	fun "${a[*]}" "${b[*]}"
	cp -vf ${OUT}/MT*.txt  ${DEST_PATH}
    cp -vf ${OUT}/preloader_${build_device}.bin  ${DEST_PATH}
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

    cp -vf ${OUT}/obj/CGEN/APDB_MT*W15*  ${DEST_PATH}/database/ap
    cp -vf ${OUT}/system/etc/mddb/BPLGUInfoCustomAppSrcP*  ${DEST_PATH}/database/moden

    cp -v ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}
    cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH}
fi
