#!/usr/bin/env bash

## rename photo modify bootanimation.zip
function renamefs()
{
	local count=1

	for old_photo_name in `find . -iname "*.png" -o -iname "*.jpg" -type f | sort`; do
		#statements
        if [[ ${count} -lt 10 ]];then
		    new_photo_name=000${count}.${old_photo_name##*.}
        elif [[ ${count} -lt 100 ]];then
		    new_photo_name=00${count}.${old_photo_name##*.}
        elif [[ ${count} -lt 1000 ]];then
		    new_photo_name=0${count}.${old_photo_name##*.}
        fi

        #show_vir "renamephoto $old_photo_name to $new_photo_name"
		mv "$old_photo_name" "$new_photo_name"

		let count++
	done
}

## 打包android代码 排除.repo .git .gitignore
function tardroid()
{
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile  ]];then
        tar --exclude=out --exclude=.git --exclude=.repo --exclude=.gitignore -czvf ../x.tar.gz . | tee log.txt
    else
        __err "current directory is not android !"
    fi
}

## 生成studio config file
function make_idegen()
{
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile  ]];then
        make -j${JOBS} idegen && development/tools/idegen/idegen.sh
    else
        __err "current directory is not android !"
    fi
}

## 生成android签名文件
function auto_make_key()
{
    local certs_p=~/.android-certs
    local make_key=./development/tools/make_key
    local board_list=("yunovo" "carrobot" "android")
    local subject=""

    if [[ ! -d ${certs_p} ]];then
        mkdir ${certs_p}
    else
        #cp -r $certs_p $certs_p-`date +%y%m%d%H`
        rm ${certs_p}/*
    fi

    _inlist=(${board_list[@]})
    show_vir "select custom name : "
    select_choice keyN

    show_vip "--> key name : $keyN"

    case ${keyN} in

        yunovo)
            subject='/C=CN/ST=GuangDong/L=ShenZhen View/O=Yunovo/OU=Develop/CN=yunovo.cn/emailAddress=notify@yunovo.cn'
            ;;

        carrobot)
            subject='/C=CN/ST=BeiJing/L=BeiJing View/O=Carrobot/OU=Develop/CN=carrobot.com/emailAddress=developer@carrobot.com';
            ;;

        android)
            subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
            ;;

        *)
            subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
            ;;
    esac

    for x in releasekey testkey platform shared media;
    do
        if [[ -f ${make_key} ]];then
            if [[ -x ${make_key} ]];then
                ${make_key} ${certs_p}/${x} "$subject"
            else
                __err "bash: $make_key: 权限不够"
                return 1
            fi
        else
            __err "bash: $make_key: 没有那个文件或目录"
            return 1
        fi
    done
}

function resync()
{
    local ref=""

    if [[ "$#" -ne 1 ]]; then
        echo ""
        echo "resync \$@"
        echo
        echo "    参数1 : refs/changes/82/46882/1"
        echo
        echo "    e.g. resync refs/changes/82/46882/1 "
        echo

        return 0
    fi

    if [[ "$1" ]];then
        ref="$1"
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        if [[ -n "${ref}" ]]; then
            repo init -b "${ref}"
        fi

        repo sync -d --no-tags
    else
        echo "current directory is not android !"
    fi
}

## 获取系统编译后的app与apk
function get_system_app_type()
{
    if [[ "$OUT" ]];then
        DEVICE_PROJECT=`get_build_var TARGET_DEVICE`
    fi

    local app_path=${config_p}/yunovo_app.txt
    local apk_path=${config_p}/yunovo_apk.txt
    local allappsfs=${script_p}/fs/allapp.txt
    local allappsfs_tmp=${script_p}/fs/apps_tmp.txt
    local findfs=out/target/product/${DEVICE_PROJECT}/system/

    find ${findfs} -name "*.apk" | grep app | sed 's/.*app\/\([^\/]*\).*/\1/g' | sort > ${allappsfs_tmp}
    find ${findfs} -name "*.apk" | grep preinstall | sed 's/.*all\/\([^.]*\).*/\1/g' >> ${allappsfs_tmp}

    if [[ -f ${allappsfs_tmp} ]];then

        cat ${allappsfs_tmp} | sort > ${allappsfs}
    fi

    echo
    show_vir "-----------------------------------apk"
    while read p;do
        while read apk;do
            if [[ ${p} == ${apk} ]];then
                show_vip "$apk"
            fi
        done < ${apk_path}
    done < ${allappsfs}

    echo
    show_vir "----------------------------------app"

    while read p;do
        while read app;do
            if [[ ${p} == ${app} ]];then
                show_vip "$app"
            fi
        done < ${app_path}
    done < ${allappsfs}
}

## 拷贝OTA基准包至指定路径
function cpotafs()
{
    # 差分包列表
    local otafs=
    # 过滤列表
    local filter='target_files-package.zip|otatools.zip'

    # OTA基准版本
    declare -a ver

    case $# in

        0) # 不传参数,直接输出帮助

            echo ""
            echo "${FUNCNAME[0]} [\$@] ..."
            echo
            echo "   \$@ : 集合参数 , 后面跟时间轴,支持多个版本."
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]} # 输出帮助文档"
            echo "        2. ${FUNCNAME[0]} S1.03.2018.06.01_14.05.05 S1.04_2020.01.10_14.26.43"
            echo
            return 0
        ;;

        1)
            case $@ in

                -h|--help)

                    echo ""
                    echo "${FUNCNAME[0]} [\$@] ..."
                    echo
                    echo "   \$@ : 集合参数 , 后面跟时间轴,支持多个版本."
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]} # 输出帮助文档"
                    echo "        2. ${FUNCNAME[0]} S1.03.2018.06.01_14.05.05 S1.04_2020.01.10_14.26.43"
                    echo
                    return 0
                ;;

                *)
                    # 不用干活,其实时变量 [ $@ ] 的值不用处理. It is best to check format for args.
                    :
                ;;

            esac
        ;;

        *)
            # 不用干活,其实时变量 [ $@ ] 的值不用处理. It is best to check format for args.
            :
        ;;
    esac

    for v in $@ ; do

        otafs=`find ${test_path}/test -name "*.zip" | egrep -w "${v}"  | grep -vE "${filter}" | grep -v "sdupdate.*.zip"`

        echo
        show_vig "${otafs##*/} :"

        ver[${#ver[@]}]="${otafs##*/}"

        if [[ -n "${otafs}" ]]; then
            cp -vf "${otafs}" "${otafs_p}"
        else
            log error "The otafs variable is null ..."
        fi

        if [[ -f ${otafs} ]];then
            md5sum ${otafs}
        else
            log error "The ota file has not found ..."
        fi

        if [[ -f ${otafs_p}/${otafs##*/} ]];then
            md5sum ${otafs_p}/${otafs##*/}
        else
            log error "The ota file has not found ..."
        fi
    done

    show_vip "----------------------- end. "

    # 输出需要制作OTA包的版本信息
    echo ${ver[@]}
}

## 获取APK包名和类名
function get_package_name()
{
	local apk_name=

    if [[ $# -eq 1 ]]; then
        apk_name=$1
    else
        echo ""
        echo "get_package_name [args1] ..."
        echo
        echo "    args1 : apk文件或者带路径"
        echo
        echo "    e.g."
        echo "        1. get_package_name nxDataWare.apk"
        echo "        2. get_package_name ~/workspace/date/0904/nxDataWare.apk"
        echo
        return 0
    fi

	if [[ -n "${apk_name}" && -f ${apk_name} ]];then
	    aapt dump badging ${apk_name} | grep name= | awk -F "'" '{print $2}'
		#aapt dump badging ${apk_name} | grep name= | sed 's%.*name=%%'  | sed 's% .*%%'
	else
		__err "输入有误, 请在终端输入 [get_package_name] 查询其帮助文档." && return 1
	fi
}

## 获取APK的基本信息
function get_apk_info()
{
	local apk_name=$1

	if [[ "$apk_name" ]];then
		aapt dump badging ${apk_name}
	else
		show_vir "eg: get_package_name + apk_name"
	fi
}

## 优化apk,系统编译出来的apk, 默认是已经过优化
function checkout_apk_4()
{
	local apk_name_before=$1
	local apk_name_after=${apk_name_before%.*}_after.apk

	if [[ "$apk_name_before" && "$apk_name_after" ]]; then

		### 带参数 -v 显示内容
		if zipalign 4 ${apk_name_before} ${apk_name_after};then
			zipalign -c -v 4 ${apk_name_after} | grep Verification
			show_vir ' $apk_name_after'
		fi
	else
		show_vir "eg:  checkout_apk_4 + apk ..."
		return 0
	fi
}

## 清除修改还原为干净状态
function recover_android()
{
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        recover_standard_android_project
        show_vir "-------------------------------------------------------------------------------------"
    else
        __err "The (.repo) not found ! please check your path, Whether or not in gettop ."
        return 1
    fi
}

## 清除系统中云智的app apk
function rmappfs()
{
    local OLDP=`pwd`
    local app_file=${config_p}/allapp.txt
    local app_path=packages/apps

    if [[ ! "`is_yunovo_project`" == "true" ]];then
        return 1
    fi

    cd ${app_path} > /dev/null

    while read app_name;do
        if [[ -d ${app_name} ]];then
            rm  ${app_name} -r && echo "---> rm $app_name ..."
        else
            show_vir "---> $app_name is not exist !"
        fi
    done < ${app_file}

    cd ${OLDP} > /dev/null
}

## 手动拷贝版本至release
function copy_image_to_folder()
{
    local PROJECT_NAME=$1
    local PROJECT_VERSION=$2
    local BASE_PATH=~/firmware/${PROJECT_VERSION}
    local DEST_PATH=${BASE_PATH}/${PROJECT_NAME}
    local OTA_PATH=${BASE_PATH}/${PROJECT_NAME}_full_and_ota
    local build_device=${OUT##*/}

    if [[ $# -ne 2 ]]; then
        echo "Usage : ./cp_image.sh project_name project_version"
        return 1
    else
        echo
        show_vir "----  cp image start ..."
        echo
    fi

    if [[ ! -d ${BASE_PATH} ]];then
        mkdir -p ${BASE_PATH}
        if [[ ! -d ${DEST_PATH}/database/ ]];then
            mkdir -p ${DEST_PATH}/database/ap
            mkdir -p ${DEST_PATH}/database/moden
        fi
    fi

    if [[ ! -d ${DEST_PATH} ]];then
        mkdir -p ${DEST_PATH}
    fi

    if [[ ! -d ${OTA_PATH} ]];then
        mkdir -p ${OTA_PATH}
    fi

    cp -f ${OUT}/MT*.txt  ${DEST_PATH}
    cp -f ${OUT}/preloader_${build_device}.bin  ${DEST_PATH}
    cp -f ${OUT}/lk.bin ${DEST_PATH}
    cp -f ${OUT}/boot.img ${DEST_PATH}
    cp -f ${OUT}/recovery.img ${DEST_PATH}
    cp -f ${OUT}/secro.img ${DEST_PATH}
    cp -f ${OUT}/logo.bin ${DEST_PATH}
    cp -f ${OUT}/trustzone.bin ${DEST_PATH}
    cp -f ${OUT}/trustzone.bin ${DEST_PATH}
    cp -f ${OUT}/system.img ${DEST_PATH}
    cp -f ${OUT}/cache.img ${DEST_PATH}
    cp -f ${OUT}/userdata.img ${DEST_PATH}

    cp -f ${OUT}/obj/CGEN/APDB_MT*W15*  ${DEST_PATH}/database/ap
    cp -f ${OUT}/system/etc/mddb/BPLGUInfoCustomAppSrcP*  ${DEST_PATH}/database/moden

    cp  ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}
    cp  ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH}

    echo
    show_vir "----  cp image end ..."
    echo
}