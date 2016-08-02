#!/bin/bash

function test_args()
{
    local ret=$1

    if [ $# -eq 1 ];then
        echo "-----"
        echo "$#"

    else
        echo "$#"
    fi
}

function is_long_project()
{
    ### jenkins path name
    local prjN=(k86l k86ld)

    ### jenkins project name
    local projectN=(k26c)

    local prj_name=$(pwd) && prj_name=${prj_name%/*} && prj_name=${prj_name##*/}

    for p1 in ${prjN[@]}
    do
        if [ "$prj_name" == "$p1" ];then
            echo true
        fi
    done

    for p2 in ${projectN[@]}
    do
        if [ "$project_name" == "$p2"  ];then
            echo true
        fi
    done
}

function get_project_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}
    local project_name=($k26P $k86aP $k86mP $k86sP $k86smP $k86lP $k86lsP $k86ldP $k88cP)
    local isroot=false

    if [ "$thisP" ];then

        for p in ${project_name[@]}
        do
            if [ "$thisP" == "${p}_root" ];then
                isroot=true
                echo $p
            fi
        done

        if [ "$isroot" == "false" ];then
            echo $thisP
        fi
    else
        echo "do not get project name !"
    fi
}

function test_is_number()
{
    local n=$1

    expr $n "+" 10 &> /dev/null

    if [ $? -eq 0  ];then
        echo "$n is number"
    else
        echo "$n not number"
    fi
}

function remove_space()
{
    local new_v=
    local old_v=$1
    tmp_file=~/workspace/script/zzzzz-script/tmp.txt

    new_v=`cat $tmp_file | sed 's/[   ]\+//g'`
    if [ "$new_v" != "$old_v" ];then
        echo $new_v
    else
        echo $old_v
    fi
}

function test_()
{
    local tmp_file=~/workspace/script/zzzzz-script/tmp.txt
    local ret="xxx xxx xxx zzz xxx"
    local new_v=

    echo $ret > $tmp_file
    remove_space $ret

    if [ -f $tmp_file ];then
        rm $tmp_file -r
    fi
}
function checkout_debug_info()
{
    local build_flag=$1
    local which_flag=(1 2 3 4 5 6 7)
    local flag=

    for f in ${which_flag[@]}
    do
        if [ "$build_flag" ];then
            flag=`echo $build_flag | cut -d '.' -f${f}`

            if [ -z $flag ];then
                echo " flag is error , please checkout it !"
                exit 1
            fi

            if [ $flag -ne 0 -a $flag -ne 1 ];then
                echo " flag is error , please checkout it !"
                exit 1
            else
                echo true
            fi
        fi
    done
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

test-str-z()
{
    local src=$1
    if [ -n "$src" ];then
        echo $src

        ### 字符串  为空为真
        if [ -z "$src" ];then
            echo "zzzzzzzzzzzzzzzzzzzzz"
        else
            echo "xxxxxxxxx"
        fi

        ### 字符串　不为空为真
        if [ -n "$src" ];then
            echo "nnnnnnnnnnnnnn"
        else
            echo "xxx"
        fi
    fi
}

test-readfs()
{
    while read line
    do
        echo $line
        ret=${line##*=}
        echo $ret
    done < apptag.txt
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
