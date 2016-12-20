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
### readme.txt
build_readme=
### test master develop for branch
build_branch=
### is clean android source code
build_clean=
### is make ota or not
build_make_ota=
### is create refs
build_refs=
### is update source code
build_update_code=

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
debug_path=~/debug
cur_time=`date +%m%d_%H%M`
time_for_refs=`date +'%Y.%m.%d_%H.%M.%S'`
zz_script_path=/home/jenkins/workspace/script/zzzzz-script
cpu_num=`cat /proc/cpuinfo  | egrep 'processor' | wc -l`
project_link="init -u ssh://jenkins@gerrit.y:29419/manifest"
tmp_file=$debug_path/tmp.txt
readme_file=$debug_path/readme.txt
lunch_project=
prefect_name=
system_version=
fota_version=

### project name for yunovo
k26P=k26
k26sP=k26s
k26sdP=k26sd
k27P=k27
k86aP=k86a
k86mP=k86m
k86mx2P=k86mx2
k86sP=k86s
k86smP=k86sm
k86lP=k86l
k86lsP=k86ls
k88cP=k88c
k88c21P=k88c_21
k88sP=k88s
k86ldP=k86ld
k86lsdP=k86lsd

k26PR=k26_root
k26sPR=k26s_root
k27PR=k27_root
k86aPR=k86a_root
k86mPR=k86m_root
k86mx2PR=k86mx2_root
k86sPR=k86s_root
k86smPR=k86sm_root
k86lPR=k86l_root
k86lsPR=k86ls_root
k88cPR=k88c_root
k88c21PR=k88c_21_root
k88sPR=k88s_root
k86ldPR=k86ld_root
k86lsdPR=k86lsd_root

k27_xinke_ds50_p=k27_xinke_ds50
k86sa1_mazda_p=k86sa1_mazda
mx1_xianzhi_k80_p=mx1_xianzhi_k80
k89_master_p=k89_master

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

    if [ "$1" ];then
        echo "currect dir is : $pwd $1"
    else
        echo "currect dir is : $pwd"
    fi
}

function _echo()
{
    local msg=$1

    if [ $# -eq 1 ];then
        :
    else
        __echo "e.g : _echo xxx"
        return 1
    fi

    if [ "$msg" ];then
        echo "$msg"
        echo
    else
        echo "msg is null, please check it !"
        return 1
    fi
}

function __echo()
{
    local msg=$1

    if [ $# -eq 1 ];then
        :
    else
        echo
        echo "e.g : __echo xxx"
        echo
        return 1
    fi

    if [ "$msg" ];then
        echo
        echo "--> $msg"
        echo
    else
        echo "msg is null, please check it !"
        return 1
    fi
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

    if [ $# -eq 1 ];then
        :
    else
        _echo "$# is error, please check args !"
        return 1
    fi

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

    case $thisP in

        $k26P | $k26PR)
            echo true

            ;;

        $k26sP | $k26sPR | $k26sdP)
            echo true

            ;;
        $k27P | $k27PR)
            echo true

            ;;

        $k86aP | $k86aPR)
            echo true

            ;;
        $k86mP | $k86mPR)
            echo true
            ;;

        $k86mx2P | $k86mx2PR)
            echo true

            ;;
        $k86sP | $k86sPR)
            echo true

            ;;
        $k86smP | $k86smPR)
            echo true

            ;;
        $k86lP | $k86lPR)
            echo true

            ;;
        $k86lsP | $k86lsPR)
            echo true

            ;;
        $k86ldP | $k86ldPR)
            echo true

            ;;
        $k86lsdP | $k86lsdPR)
            echo true

            ;;

        $k88cP | $k88cPR | $k88c21P | $k88c21PR)
            echo true

            ;;
        $k88sP | $k88sPR)
            echo true

            ;;

        $k27_xinke_ds50_p | $k86sa1_mazda_p | $mx1_xianzhi_k80_p | $k89_master_p)
            echo true

            ;;

        *)
            echo false

            ;;
    esac
}

function is_branch_project()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

     case $thisP in
        $k27_xinke_ds50_p | $k86sa1_mazda_p | $k89_master_p)
            echo true

            ;;
        $mx1_xianzhi_k80_p)
            echo true

            ;;


        *)
            echo false

            ;;
    esac

}

function is_root_yunovo_project()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}
    local project_name=($k26P $k26sP $k27P $k86aP $k86mP $k86mx2P $k86sP $k86smP $k86lP $k86lsP $k86ldP $k86lsdP $k88cP $k88c21P $k88sP)

    if [ "$thisP" ];then

        for p in ${project_name[@]}
        do
            if [ "$thisP" == "${p}_root" ];then
                echo true
            fi
        done
    else
        echo "it do not get project name !"
        return 1
    fi
}

function get_project_real_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    if [ "$thisP" ];then
        echo $thisP
    else
        echo "it do not get project name !"
        return 1
    fi
}

function get_project_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}
    local project_name=($k26P $k26sP $k26sdP $k27P $k86aP $k86mP $k86mx2P $k86sP $k86smP $k86lP $k86lsP $k86ldP $k86lsdP $k88cP $k88c21P $k88sP)
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
        echo "it do not get project name !"
        return 1
    fi
}

### 是否为master test develop分支
function is_yunovo_branch()
{
    local branch_name=$1
    local branchN=(master develop test)

    if [ $# -eq 1 ];then
        :
    else
        _echo "$# is error, please check args !"
        return 1
    fi

    for b in ${branchN[@]}
    do
        if [ $b == $branch_name ];then
            echo true
        fi
    done
}

### 是否为编译服务器
function is_yunovo_server()
{
    local hostN=`hostname`
    local serverN=(s1 s2 s3 s4 s5 happysongs ww he-All-Series. yangmingming)
    local isServer=false

    for n in ${serverN[@]}
    do
        if [ "$n" == "$hostN"  ];then
            isServer=true
            echo true
        fi
    done

    if [ $isServer == "false" ];then
        echo "it do not make on yunovo server !"
        return 1
    fi
}

### 是否为使用的芯片类型
function is_build_device()
{
    local cpu_type_more=(aeon6735_65c_s_l1 aeon6735m_65c_s_l1 magc6580_we_l)
    local cpu_type=$1

    if [ $# -eq 1 ];then
        :
    else
        _echo "$# is error, please check args !"
        return 1
    fi

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

    if [ $# -eq 1 ];then
        :
    else
        _echo "$# is error, please check args !"
        return 1
    fi

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

    if [ $# -eq 1 ];then
        :
    else
        _echo "$# is error, please check args !"
        return 1
    fi

    for a in ${long_branch_app_name[@]}
    do
        if [ $a == $check_long_app ];then
            echo true
        fi
    done
}

###是否为长屏项目
function is_long_project()
{
    ### jenkins path name
    local prjN=(k26s k26sd k86l k86ld k86lsd k86mx2 k88s)

    ### jenkins project name
    local projectN=(k26c k26d k27l)

    local OLDP=`pwd`

    cd $ROOT > /dev/null

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

    cd $OLDP > /dev/null
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

function print_make_completed_time()
{
    local startT=$1
    local endT=`date +'%Y-%m-%d %H:%M:%S'`
    local useT=

    local hh=
    local mm=
    local ss=

    useT=$(($(date +%s -d "$endT") - $(date +%s -d "$startT")))

    hh=$((useT / 3600))
    mm=$(((useT - hh * 3600) / 60))
    ss=$((useT - hh * 3600 - mm * 60))

    echo "#### make completed successfully ($hh:$mm:$ss (hh:mm:ss)) ###"
}

function print_system_app_and_apk()
{
    local zzz_path=~/workspace/script/zzzzz-script
    local app_path=$zzz_path/yunovo_app.txt
    local apk_path=$zzz_path/yunovo_apk.txt
    local allapps_path=$zzz_path/fs/allapp.txt
    local allapps_tmp=$zzz_path/fs/apps_tmp.txt
    local findfs=out/target/product/$DEVICE_PROJECT/system/

    if [ "`is_yunovo_project`" ];then
        find $findfs -name "*.apk" | grep app | sed 's/.*app\/\([^\/]*\).*/\1/g' | sort > $allapps_tmp
        find $findfs -name "*.apk" | grep preinstall | sed 's/.*all\/\([^.]*\).*/\1/g' >> $allapps_tmp

        cat $allapps_tmp | sort > $allapps_path

    else
        _echo "current directory is not android !"
        return 1
    fi

    echo "-----------------------"
    while read p;do
        while read apk;do
            if [ $p == $apk ];then
                echo "$apk"
            fi
        done < $apk_path
    done < $allapps_path

    echo

    while read p;do
        while read app;do
            if [ $p == $app ];then
                echo "$app"
            fi
        done < $app_path
    done < $allapps_path
    echo "-----------------------"
    echo
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

    ### 处理k86l系类工程
    if [ $prj_name == "k86l" -o $prj_name == "k86ld" -o $prj_name == "k86ls" -o $prj_name == "k86lsd" ];then
        prj_name=k86
    elif [ $prj_name == "k26s" -o $prj_name == "k26sd" ];then
        prj_name=k2*
    elif [ $prj_name == "k88c_21" ];then
        prj_name=k88
    fi

    ### 1. project name
    if [ "$sz_build_project" ];then

        ### remove space
        echo "$sz_build_project" > $tmp_file
        sz_build_project=`remove_space_for_vairable $sz_build_project`

        if [ -n "$sz_build_project" ];then
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

            first_version=${build_version%%.*}
            second_version=${build_version#*.}

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

        if [ "`echo $sz_build_file | egrep /`" ];then
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

        if [ "$tag_version" == "all" -o "$tag_version" == "ALL" -o "$tag_version" == "All" ];then
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
        tag_version=ALL

        first_tag_version=9
        second_tag_version=99

    if false;then
        while read apptag;do
            tag_version=${apptag##*=}
            first_tag_version=${tag_version%.*}
            second_tag_version=${tag_version##*.}
        done < $tag_file
    fi
    fi

    ### 9. build readme.txt
    if [ "$yunovo_readme" ];then
        build_readme="$yunovo_readme"

        if [ "$build_readme" ];then

            echo -e "$build_prj_name ${build_version} 修改点:" > $readme_file
            echo >> $readme_file

            for r in ${yunovo_readme[@]}
            do
                echo -e "$r" >> "$readme_file"
            done
        fi
    else
        echo -e "$build_prj_name ${build_version} 修改点:" > $readme_file
        echo >> $readme_file

        build_readme="未填写，请与出版本的同学联系，并让其补全修改点."
        echo "$build_readme" >> $readme_file
    fi

    ### 10. build branch
    if [ "$yunovo_branch" ];then

        if [ `is_yunovo_branch $yunovo_branch` == "true" ];then
            build_branch=$yunovo_branch
        else
            echo "yunovo_branch is error , please check it !"
            return 1
        fi
    else
        ### jenkins 没有填写，默认为master
        build_branch=master
    fi

    ### 11. build clean
    if [ "$yunovo_clean" ];then
        build_clean=$yunovo_clean
    else
        build_clean=false
    fi

    ### 12. build ota
    if [ "$yunovo_make_ota" ];then
        build_make_ota=$yunovo_make_ota
    else
        build_make_ota=false
    fi

    ## 13. build refs
    if [ "$yunovo_refs" ];then
        build_refs=$yunovo_refs
    else
        build_refs=false
    fi

    ## 14. build update source code
    if [ "$yunovo_update_code" ];then
        build_update_code=$yunovo_update_code
    else
        build_update_code=true
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

        thisFiles=`git diff --cached --name-only`
        if [ "$thisFiles" ];then
            git reset HEAD . ###recovery for cached files
        fi

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
                if [ $ProjPath != "packages" ];then
                    chiphd_recover_project $ProjPath
                fi
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
            _echo "---> create $firmware_path ..."
        fi

	    if [ ! -d $DEST_PATH ];then
		    mkdir -p $DEST_PATH

		    if [ ! -d ${DEST_PATH}/database/ ];then
			    mkdir -p ${DEST_PATH}/database/ap
			    mkdir -p ${DEST_PATH}/database/moden
		    else
			    _echo "---> created /database/ap or /database/moden ..."
		    fi
	    else
		    _echo "---> created $DEST_PATH"
	    fi

	    if [ ! -d $OTA_PATH ];then
		    mkdir -p $OTA_PATH
	    else
		    _echo "---> created $OTA_PATH "
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

        _echo "---> cp image end ..."

        if [ $flag_fota -eq 1 ];then
            if [ $build_make_ota == "true" ];then
                if [ "`ls ${OUT}/full_${build_device}-ota*.zip`" ];then
                    cp -v ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}/sdupdate.zip
                    _echo "copy sdupdate.zip successful ..."
                fi

                if [ "`ls ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip`" ];then
                    cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH}/${system_version}.zip
                    _echo "copy ota file successful ..."
                fi
            fi
        fi

        ### add readme.txt in version
        if [ -f $readme_file ];then
            cp -vf $readme_file ${BASE_PATH}
            if [ $? -eq 0 ];then
                rm $readme_file -r
            fi
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
    echo "build_branch = $build_branch"
    echo "build_clean= $build_clean"
    echo "build_make_ota = $build_make_ota"
    echo "build_refs = $build_refs"
	echo "lunch_project = $lunch_project"
	echo "fota_version = $fota_version"
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
    echo "yunovo_clean = $yunovo_clean"
    echo "yunovo_branch = $yunovo_branch"
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
	local ConfigsPath=

    if [ "`is_branch_project`" == "true" ];then
        ConfigsPath=${thisSDKTop}/yunovo/customs
    else
        ConfigsPath=${thisSDKTop}/../yunovo_customs
    fi

	if [ -d "$ConfigsPath" ]; then
		ConfigsPath=$(cd $ConfigsPath && pwd)
	else
		echo "no path : $ConfigsPath"
		return 1
	fi

	local ConfigsFName=proj_help.sh
	local ProductSetTop=${ConfigsPath}/custom


    #_echo " config path = $ConfigsPath"
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
    local local_branch_name=$1
    local tag_name=$2
    local app_name=$3

    #echo "local_branch_name = $local_branch_name"
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

        ### 检查当前是否存在　local_branch_name
        if [ "`git branch | grep $local_branch_name`" ];then

            ## 检查当前是切换到了local_branch_name
            if [ "`git branch | grep \* | cut -d ' ' -f2`" != "$local_branch_name" ];then
                git checkout $local_branch_name && _echo "---- switch $local_branch_name $app_name"
            fi
        fi
    fi
}

function handler_branch_for_apk()
{
    local apk_name=$1
    local default_branch=""
    local local_branch_name=""
    local remote_branch_name=""
    local master_branch="master origin/master"
    local long_branch="long origin/long"

    if [ $# -eq 1 ];then
        :
    else
        __echo "e.g : handler_branch  name ..."
        return 1
    fi

    cd $apk_name > /dev/null

    ## 长屏方案
    if [ "`is_long_project`" == "true" ];then

        if [ "`is_long_branch_app $apk_name`" == "true" ];then

            defalut_branch=$long_branch
        else

            defalut_branch=$master_branch
        fi

    ## 短屏方案
    else
        defalut_branch=$master_branch
    fi

    if [ "$defalut_branch" ];then
        local_branch_name=${defalut_branch% *}
        remote_branch_name=${defalut_branch##* }
    else
        echo "defalut_branch is null, please check it !"
        return 1
    fi

    #echo "local_branch_name = $local_branch_name"
    #echo "remote_branch_name = $remote_branch_name"

    ## 检查当前分支是否有检出对应的分支
    if [ "`git branch | grep $local_branch_name`" ];then

        ## 检查当前分支是否为需要切换的分支
        if [ "`git branch | grep \* | cut -d ' ' -f2`" != $local_branch_name ];then

            if git checkout $local_branch_name;then
                _echo "---- checkout $local_branch_name $apk_name successful ..."
            else
                _echo "---- checkout $local_branch_name $apk_name fail ..."
                return 1
            fi

            if git pull;then
                _echo "---- pull $local_branch_name $apk_name successful ..."
            else
                _echo "---- pull $local_branch_name $apk_name fail ... "
                return 1
            fi
        else
            if git pull;then
                _echo "---- pull $local_branch_name $apk_name successful ..."
            else
                _echo "---- pull $local_branch_name $apk_name fail ... "
                return 1
            fi
        fi
    else

        ## 检查 local_branch_name 远程分支是否存在?
        if [ "`git branch -r | grep $local_branch_name`" ];then

            ## 当前没有检出分支，开始进行检出分支..
            if git checkout -b $defalut_branch;then
                _echo "---- checkout $local_branch_name $apk_name successful ..."
            else
                _echo "---- checkout $local_branch_name $apk_name fail ..."
                return 1
            fi

            ## update apk
            if git pull;then
                _echo "---- pull $local_branch_name $apk_name successful ..."
            else
                _echo "---- pull $local_branch_name $apk_name fail ... "
                return 1
            fi

        ## 若不存在,则默认master分支
        else
            if [ "`git branch | grep master`" ];then
                git checkout master
            else
                if [ "`git branch -r | grep master`" ];then
                    git checkout -b $master_branch
                else
                    :
                fi
            fi

            if git pull;then
                _echo "---- pull $master_branch $apk_name successful ..."
            else
                _echo "---- pull $master_branch $apk_name fail ..."
            fi
        fi

    fi

    if [ $apk_name == "TxzCore" ];then
        handler_branch_for_TxzCore
    fi

    if [ $apk_name == "TxzWebchat" ];then
        handler_branch_for_TxzWebchat
    fi

    auto_git_create_branch_refs

    cd .. > /dev/null
}

function handler_system_app()
{
    local app_name=$1
    local outputP=output
    local apk_path=~/android/packages/apps

    if [ "$app_name" ];then
        :
    else
        _echo "app name is null, please check it !"
        return 1
    fi

    if [ ! -d $apk_path/$app_name ];then
        mkdir -p $apk_path/$app_name
    fi

    ## 1. 复制app 到指定目录下
    if [ -f ${outputP}/${app_name}.apk ];then
        cp -vf ${outputP}/${app_name}.apk $apk_path/$app_name
    fi

    ## 2. 自动生成自己的android.mk文件
    if [ -f ${apk_path}/$app_name/${app_name}.apk ];then

        cd $apk_path/$app_name > /dev/null

        auto_create_android_mk $app_name

        cd - > /dev/null
    else
        _echo "app name not found, please check it !"
        return 1
    fi
}

function handler_update_source_code()
{
    local app_name=$1
    local branch_name=$2

    if git pull;then
        _echo "---- pull $branch_name $app_name successful ..."
    else
        _echo "---- pull $branch_name $app_name fail ... "
        return 1
    fi
}

function handler_branch_for_YOcLauncherRes()
{
    local sz_branch_name=

    #_echo "build_prj_name = $build_prj_name"
    case $build_prj_name in

        k26s_LD-A107C)
            sz_branch_name=S6_LD_V10

            ;;
        k27l_AJ-AJS-1)
            sz_branch_name=S6_AJ_V10

            ;;
        k27l_HBS-T2)
            sz_branch_name=S6_HBS_V10

            ;;
        k86ls_LS6-ZX | k86ls_S6-ZX | k88s_YT-YBT686 | k27l_S6-ZX | k88s_S6-ZX | k26s_S6-ZX | k26s_YJ-K7 | k26s_K26-ZX | k27l_N91-ZX)
            sz_branch_name=S6_NXOS_V10

            ;;
        k86ls_LHZ)
            sz_branch_name=S7_LHZ_V20

            ;;
        k27l_S7-ZX | k86ls_K86-ZX | k86ls_LHZ-KPS | k86mx2_K86-ZX | k26s_S7-ZX)
            sz_branch_name=S7_NXOS_V10

            ;;
        k86mx1_GY-G2B)
            sz_branch_name=S7_GY-G2B_V20
            ;;

        k86ls_K86-ZX2 | k88s_K88-ZX | k88s_S7-ZX)
            sz_branch_name=S7_NXOS_V20

            ;;
        k26s_LD-HS810A)
            sz_branch_name=S7_LD_V10

            ;;

        k86mx1_KKXL-C9)
            sz_branch_name=S7_KKXL_V20

            ;;

        k86mx1_QC-M78)
            sz_branch_name=S7_QC-M78_V21

            ;;

        k89_HP-S760)
            sz_branch_name=S7_HP-S760_V21

            ;;

        k86s7_NM-N810 | k88s_NM-D200)
            sz_branch_name=S7_NM-N810_V20

            ;;

        k86ls_K80)
            sz_branch_name=S7_XZ-K80_V20

            ;;

        k26s_RWY-CS85)
            sz_branch_name=S7_RWY-CS85_V22

            ;;

        k89_LD-HS830A)
            sz_branch_name=S7_LD-K89_V21

            ;;


        *)
            sz_branch_name=S6_NXOS_V20
            ;;
    esac

    _echo "sz_branch_name = $sz_branch_name"

    if [ "$sz_branch_name" ];then
        handler_checkout_branch $sz_branch_name
        handler_update_source_code YOcLauncherRes $sz_branch_name
    fi
}

function handler_checkout_branch()
{
    local branch_name=$1

    ##检查远程仓库是否存在
    if [ "`git branch -r | grep \"$branch_name\"`" ];then

        ##检查本地是否存在
        if [ "`git branch | grep \"$branch_name\"`" ];then

            ## 检查当前是否存在
            if [ "`git branch | grep \* | cut -d ' ' -f2`" != "$branch_name" ];then
                git checkout $branch_name
            else
                _echo "curr branch name: $branch_name ..."
            fi
        else
            git checkout -b $branch_name origin/$branch_name
        fi
    else
        git checkout master
    fi
}

function handler_branch_for_YOcSettings()
{
    local YOcSettings_branch=

    case $build_prj_name in
        k88s_S6-ZX | k88s_S7-ZX | k88s_NM-D200)

            YOcSettings_branch=new_2.0
            ;;

        k26s_S6-ZX | k26s_S7-ZX)

            YOcSettings_branch=new_2.0
            ;;

        k27l_S6-ZX | k27l_S7-ZX | k27l_N91-ZX)

            YOcSettings_branch=new_2.0
            ;;

        k86ls_K80)

            YOcSettings_branch=new_2.0
            ;;

        k86mx1_QC-M78)

            YOcSettings_branch=new_2.0
            ;;


        k86s7_NM-N801 | k86s7_NM-N810)

            YOcSettings_branch=new_2.0
            ;;

        k26s_RWY-CS85)

            YOcSettings_branch=new_2.0
            ;;

        k89_HP-S760 | k89_LD-HS830A)

            YOcSettings_branch=new_2.0
            ;;


        *)
            __echo "YOcSettings_branch is null !"
            ;;
    esac

    if [ "$YOcSettings_branch" ];then
        handler_checkout_branch $YOcSettings_branch
        handler_update_source_code YOcSettings $YOcSettings_branch
    fi
}


function handler_branch_for_YOcMediaFolder()
{
    local YOcMediaFolder_branch=

    if [ $build_prj_name == "k26s_LD-A107C" ];then
        YOcMediaFolder_branch=yunovo/k26s/lingdu/common
    else
         if [ "`git branch -r | grep 'test'`" -o "`git branch -r | grep develop`" ];then
            :
        else
            git checkout master
        fi
    fi

    if [ "$YOcMediaFolder_branch" ];then
        handler_checkout_branch $YOcMediaFolder_branch
        handler_update_source_code YOcMediaFolder $YOcMediaFolder_branch
    fi
}

function handler_branch_for_YOcRecord()
{
    local YOcRecord_branch=

    if [ $build_prj_name == "k26s_LD-A107C" -o $build_prj_name == "k26s_LD-HS810A" ];then
        YOcRecord_branch=k26s/ld/a107c
    elif [ $build_prj_name == "k27l_HBS-T2" ];then
        YOcRecord_branch=yunovo/k27l/hbs/common
    else
        if [ "`git branch -r | grep 'test'`" -o "`git branch -r | grep develop`" ];then
            :
        else
            git checkout master
        fi

        _echo "checkout master branch on YOcRecord"
    fi

    if [ "$YOcRecord_branch" ];then
        handler_checkout_branch $YOcRecord_branch
        handler_update_source_code YOcRecord $YOcRecord_branch
    fi
}

function handler_branch_for_YOcBTCall()
{
    local YOcBTCall_branch=

    case $build_prj_name in

        k88s_S6-ZX | k88s_S7-ZX | k88s_NM-D200)

            YOcBTCall_branch=bt_new2.0
            ;;

        k26s_S6-ZX | k26s_S7-ZX)

            YOcBTCall_branch=bt_new2.0
            ;;

        k27l_S6-ZX | k27l_S7-ZX | k27l_N91-ZX)

            YOcBTCall_branch=bt_new2.0
            ;;

        k86mx1_QC-M78)

            YOcBTCall_branch=bt_new2.0
            ;;


        k86ls_K80)

            YOcBTCall_branch=bt_new2.0
            ;;

        k86s7_NM-N801 | k86s7_NM-N810)

            YOcBTCall_branch=bt_new2.0
            ;;

        k26s_RWY-CS85)

            YOcBTCall_branch=bt_new2.0
            ;;

        k89_HP-S760 | k89_LD-HS830A)

            YOcBTCall_branch=bt_new2.0
            ;;


        *)
            __echo "YOcBTCall_branch is null !"
            ;;
    esac

    if [ "$YOcBTCall_branch" ];then
        handler_checkout_branch $YOcBTCall_branch
        handler_update_source_code YOcBTCall $YOcBTCall_branch
    fi
}

function handler_branch_for_YOcBTCallGoc()
{
    local YOcBTCallGoc_branch=

    case $build_prj_name in

        k86ls_K80)

            YOcBTCall_branch="mx1/xianzhi/k80"
            ;;

        *)
            __echo "YOcBTCallGoc_branch is null !"
            ;;
    esac

    if [ "$YOcBTCallGoc_branch" ];then
        handler_checkout_branch $YOcBTCallGoc_branch
        handler_update_source_code YOcBTCallGoc $YOcBTCallGoc_branch
    fi
}

function handler_branch_for_TxzCore()
{
    local TxzCore_branch=

    case $build_prj_name in

        k86s7_NM-N810 | k88s_NM-D200 | k88s_NM-D210)

            TxzCore_branch=txzing2.0
            ;;

        *)

           __echo "TxzCore_branch is null !"
            ;;

    esac

    if [ "$TxzCore_branch" ];then
        handler_checkout_branch $TxzCore_branch
        handler_update_source_code TxzCore $TxzCore_branch
    fi
}

function handler_branch_for_TxzWebchat()
{
    local TxzWebchat_branch=

    case $build_prj_name in

        k86s7_NM-N810 | k88s_NM-D200 | k88s_NM-D210)

            TxzWebchat_branch=txzing2.0
            ;;

        *)

           __echo "TxzWebchat_branch is null !"
            ;;

    esac

    if [ "$TxzWebchat_branch" ];then
        handler_checkout_branch $TxzWebchat_branch
        handler_update_source_code TxzWebchat $TxzWebchat_branch
    fi
}

function handler_branch_for_app()
{
    local app_name=$1
    local tag_name=""
    local branch_name=""
    local default_branch=""
    local local_branch_name=""
    local remote_branch_name=""

    ## 1.短屏分支
    local master_branch="master origin/master"
    local develop_branch="develop origin/develop"
    local test_branch="test origin/test"

    ## 2.长屏分支
    local long_branch="long origin/long"
    local develop_long_branch="develop_long origin/develop_long"
    local test_long_branch="test_long origin/test_long"

    ## 3.选择分支名称
    local branch_for_test="test"
    local branch_for_master="master"
    local branch_for_develop="develop"

    if [ $# -eq 1 ];then
        :
    else
        __echo "e.g : handler_branch  app name ..."
        return 1
    fi

    cd $app_name > /dev/null

    ## 长屏方案
    if [ "`is_long_project`" == "true" ];then

        if [ "`is_long_branch_app $app_name`" == "true" ];then

            if [ $build_branch == $branch_for_test ];then
                defalut_branch=$test_long_branch
            elif [ $build_branch == $branch_for_develop ];then
                defalut_branch=$develop_long_branch
            elif [ $build_branch == $branch_for_master ];then
                defalut_branch=$long_branch
            else
                defalut_branch=$long_branch
            fi

        else
            if [ $build_branch == $branch_for_test ];then
                defalut_branch=$test_branch
            elif [ $build_branch == $branch_for_develop ];then
                defalut_branch=$develop_branch
            elif [ $build_branch == $branch_for_master ];then
                defalut_branch=$master_branch
            else
                defalut_branch=$master_branch
            fi
        fi

    ## 短屏方案
    else
        if [ $build_branch == $branch_for_test ];then
            defalut_branch=$test_branch
        elif [ $build_branch == $branch_for_develop ];then
            defalut_branch=$develop_branch
        elif [ $build_branch == $branch_for_master ];then
            defalut_branch=$master_branch
        else
            defalut_branch=$master_branch
        fi
    fi

    if [ "$defalut_branch" ];then
        local_branch_name=${defalut_branch% *}
        remote_branch_name=${defalut_branch##* }
    else
        echo "defalut_branch is null, please check it !"
        return 1
    fi

    #echo "local_branch_name = $local_branch_name"
    #echo "remote_branch_name = $remote_branch_name"

    ## 1. 检查当前分支是否有检出对应的分支
    if [ "`git branch | grep $local_branch_name`" ];then

        ## 2. 检查当前分支是否为需要切换的分支
        if [ "`git branch | grep \* | cut -d ' ' -f2`" != $local_branch_name ];then

            if git checkout $local_branch_name;then
                _echo "---- checkout $local_branch_name $app_name successful ..."
            else
                _echo "---- checkout $local_branch_name $app_name fail ..."
                return 1
            fi

            if git pull;then
                _echo "---- pull $local_branch_name $app_name successful ..."
            else
                _echo "---- pull $local_branch_name $app_name fail ... "
                return 1
            fi
        else
            if git pull;then
                _echo "---- pull $local_branch_name $app_name successful ..."
            else
                _echo "---- pull $local_branch_name $app_name fail ... "
                return 1
            fi
        fi

    ## 当前没有检出分支，开始进行检出分支..
    else

        ## 检查 local_branch_name 远程分支是否存在?
        if [ "`git branch -r | grep $local_branch_name`" ];then

            if git checkout -b $defalut_branch;then
                _echo "---- checkout $local_branch_name $app_name successful ..."
            else
                _echo "---- checkout $local_branch_name $app_name fail ..."
                return 1
            fi

            ## update apk
            if git pull;then
                _echo "---- pull $local_branch_name $app_name successful ..."
            else
                _echo "---- pull $local_branch_name $app_name fail ... "
                return 1
            fi

        ## 若不存在，则默认
        else
            if [ $first_tag_version == "9" -a $second_tag_version == "99"  ];then

                if [ "`git branch | grep master`" ];then
                    git checkout master
                    _echo "---- checkout master successful ..."
                else
                    if [ "`git branch -r | grep master`" ];then
                        git checkout -b $master_branch
                    else
                        :
                    fi
                fi

                ## update apk
                if git pull;then
                    _echo "---- pull $local_branch_name $app_name successful ..."
                else
                    _echo "---- pull $local_branch_name $app_name fail ... "
                    return 1
                fi
            else
                :
            fi
        fi
    fi

    ## handler YOcLauncherRes branchs
    if [ $app_name == "YOcLauncherRes" ];then
        handler_branch_for_YOcLauncherRes
    fi

    ## handler k26s_LD-A107C branch
    if [ $app_name == "YOcRecord" ];then
        handler_branch_for_YOcRecord
    fi

    if [ $app_name == "YOcMediaFolder" ];then
        handler_branch_for_YOcMediaFolder
    fi

    if [ $app_name == "YOcSettings" ];then
        handler_branch_for_YOcSettings
    fi

    if [ $app_name == "YOcBTCall" ];then
        handler_branch_for_YOcBTCall
    fi

    if [ $app_name == "YOcBTCallGoc" ];then
        handler_branch_for_YOcBTCallGoc
    fi

    if [ $local_branch_name == "long" -o $local_branch_name == "develop_long" -o $local_branch_name == "test_long" ];then
        tag_name=L
    elif [ $local_branch_name == $branch_for_master -o $local_branch_name == $branch_for_develop -o $local_branch_name == $branch_for_test ];then
        tag_name=M
    fi

    if [ "$local_branch_name" -a "$tag_name" -o "$app_name" ];then

        ### 处理不同分支tag
        handler_tag_branch $local_branch_name $tag_name $app_name
    fi

    auto_git_create_branch_refs

    cd .. > /dev/null
}

function down_load_apk_for_yunovo()
{
    local OLDP=`pwd`
    local app_path=packages/apps

    local ssh_link=ssh://jenkins@gerrit.y:29419/yunovo_packages
    local yunovo_apk_file=$zz_script_path/yunovo_apk.txt

    cd $app_path > /dev/null

    while read apk_name
    do
        if [ -d $apk_name ];then

            ## handler switch branch
            handler_branch_for_apk $apk_name
        else

            ## clone apk
            if [ "$ssh_link" ];then
                git clone $ssh_link/$apk_name
                _echo "---- clone $apk_name"
            else
                _echo "$ssh_link is null. please check it !"
                return 1
            fi
        fi
    done < $yunovo_apk_file

    _echo "-------- clone apk end !"

    cd $OLDP
}

## ant source code app for project
function ant_app()
{
    local OLDP=`pwd`
    local app_path=~/yunovo_app/packages/apps
    local apk_path=~/android/packages/apps
    local yunovo_ant_app_file=$zz_script_path/yunovo_ant_app.txt
    local branch_file=$zz_script_path/fs/branch.txt
    local is_same_project=false
    local is_same_branch=false
    local branch_name=""

    if [ ! -d $zz_script_path/fs ];then
        mkdir -p $zz_script_path/fs
    fi

    cd $app_path > /dev/null

    if [ -f $branch_file ];then
        branch_name=`cat $branch_file`
    fi

    ## 删除旧的版本apk
    if [ -d $apk_path ];then
        rm $apk_path -r

        _echo "---- remove $apk_path successful ..."
    fi

    ## 1,若为同个分支不进行clean bin/ 目录，2,若为不同分支则会rm bin/ -r
    if [ "$branch_name" ];then
        if [ "$branch_name" == "$build_branch" ];then
            is_same_branch=true
        else
            is_same_branch=false
            echo $build_branch > $branch_file
        fi
    else
        is_same_branch=false
        echo $build_branch > $branch_file
    fi

    _echo "is same branch  = $is_same_branch "

    while read appN
    do
        echo $appN
        cd $appN > /dev/null

        ###编译之前是否进行清理 bin/
        if [ $is_same_project == "true" ];then

            if [ $is_same_branch == "true" ];then
                :
            else
                if [ -d /bin ];then
                    rm bin/ -rf
                fi
            fi
        else
            if [ -d bin/ ];then
                rm bin/ -rf
            fi
        fi

        (
            if (ant -q > /dev/null);then
                handler_system_app $appN
            else
                _echo "make $appN fail ..."
                return 1
            fi
        )

        cd .. > /dev/null

    done < $yunovo_ant_app_file

    cd $OLDP > /dev/null

    __echo "ant app end ..."
}

## clone app for yunovo
function clone_app()
{
    if [ $# -eq 1 ];then
        :
    else
        _echo clone_app fail , eg: clone <app_name> ...
        return 1
    fi

    local app_name=$1

    if [ -d $app_name ];then

        ## handler switch branch
        handler_branch_for_app $app_name
    else

        ## clone apk
        if [ "$app_name" == "YOcScreenSaver" ];then

            if [ "$ssh_link_yunovo" ];then
                git clone $ssh_link_yunovo/$app_name
                _echo "---- clone $app_name"
            fi
        else

            if [ "$ssh_link" ];then
                git clone $ssh_link/$app_name
                _echo "---- clone $app_name"
            fi
        fi

        ## handler switch branch
        handler_branch_for_app $app_name
    fi
}


## download all app
function down_load_app_for_yunovo()
{
    local OLDP=`pwd`
    local ant_app_path=~/yunovo_app/packages/apps
    local android_app_path=packages/apps

    local ssh_link=ssh://jenkins@gerrit.y:29419/yunovo_packages
    local ssh_link_yunovo=ssh://jenkins@gerrit.y:29419/yunovo/packages/apps
    local yunovo_ant_app_file=$zz_script_path/yunovo_ant_app.txt
    local yunovo_android_app_file=$zz_script_path/yunovo_app.txt

    if [ ! -d $ant_app_path ];then
        mkdir -p $ant_app_path
    fi

if false;then
    cd $ant_app_path > /dev/null

    ## clone ant app
    while read app_name
    do
        clone_app $app_name
    done < $yunovo_ant_app_file

    _echo "-------- clone ant app end !"

    cd $OLDP > /dev/null
fi
    cd $android_app_path > /dev/null

    ## clone make app
    while read app_name
    do
        clone_app $app_name
    done < $yunovo_android_app_file

    _echo "-------- clone make app end !"

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
        elif [ $project_name == "k86l" -o $project_name == "k86ld" ];then
            defalut=k86s_400x1280
        elif [ $project_name == "k86ls" -o $project_name == "k86lsd" ];then
            defalut=k86l_split
        elif [ $project_name == "k86mx2" ];then
            defalut=k86_mx2
        elif [ $project_name == "k88c" ];then
            defalut=k88
        elif [ $project_name == "k88c_21" ];then
            defalut=k88_v2.1
        elif [ $project_name == "k88s" ];then
            defalut=k88_split
        elif [ $project_name == "k26" ];then
            defalut=K26
        elif [ $project_name == "k26s" -o $project_name == "k26sd" ];then
            defalut=k26_split
        elif [ $project_name == "k27" ];then
            defalut=k27
        else
            __echo "project_name = $project_name"
            echo "project do not match it !"
        fi
    else
        echo "project path do not found !"
        return 1
    fi

    _echo "defalut = $defalut"

	if [ ! -d .repo ];then
		if [ "$defalut" -a "$project_link" ];then
            repo $project_link -m ${defalut}.xml -b yunovo
        fi
		repo sync -c -d --prune --no-tags -j${cpu_num}
        ls -alF

    if flase;then
        if [ "$defalut" == "K26" -o "$defalut" == "k86A" ];then
            defalut=master
        fi

        if [ $defalut ];then
            repo start $defalut --all
        fi
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

            ## 重新初始化manifest
            if [ "$defalut" ];then
                repo init -m ${defalut}.xml -b yunovo
            fi

            ## update android source code for yunovo project ...
            if repo sync -c -d --prune --no-tags -j${cpu_num};then
                _echo "----------------- repo sync successful ..."
            fi
        fi
	fi
}

## build android system for yunovo project
function make_yunovo_android()
{
	if [ "$DEVICE" ];then
        :
    else
        if [ -d .repo ];then
            source_init
        else
            _echo "The (.repo) not found ! please download android source code !"
            return 1
        fi
    fi

    if [ -n "$(find . -maxdepth 1 -name "build*.log" -print0)" ];then
		delete_log
    else
        _echo "log is not delete, please check it ! "
	fi

    if [ $build_clean == "true" ];then

        if make clean;then
            _echo "--> make clean end ..."
        else
            _echo "--> make clean fail ..."
            return 1
        fi
    else

        if make installclean;then
            _echo "--> make installclean end ..."
        else
            _echo "---> make installclean fail ..."
            return 1
        fi

    if false;then
        if make clean-lk;then
            _echo "--> make clean lk end ..."
        else
            _echo "--> make clean lk fail ..."
            return 1
        fi
    fi

    fi

    if [ "$cpu_num" -gt 0 ];then
        :
    else
        _echo "cpu_num is error ..."
        return 1
    fi

    make -j${cpu_num} ${fota_version} 2>&1 | tee build_$cur_time.log
    if [ $? -eq 0 ];then
        _echo "--> make project end ..."
    else
        _echo "make android failed !"
        return 1
    fi

    if [ $flag_fota -eq 1 ];then

        if [ "$build_make_ota" == "true" ];then
            make -j${cpu_num} ${fota_version} otapackage 2>&1 | tee build_ota_$cur_time.log

            if [ $? -eq 0 ];then
                _echo "--> make otapackage end ..."
            else
                _echo "make otapackage fail ..."
                return 1
            fi
        else
            _echo "build_make_ota = $build_make_ota"
        fi
    fi
}

function sync_jenkins_server()
{
    local firmware_path=~/debug
    local share_path=/public/jenkins/jenkins_share_20T
    local jenkins_server=jenkins@f1.y

    local root_version=userdebug
    local branch_for_test=test
    local branch_for_master=master
    local branch_for_develop=develop

    if [ "`is_yunovo_server`" == "true" ];then
        if [ $build_test == "true" ];then
            rsync -av $firmware_path/ $jenkins_server:$share_path/happysongs
        elif [ "$build_branch" == $branch_for_test ];then
            if [ "`is_root_yunovo_project`" == "true" -a "$build_type" == "$root_version" ];then
                rsync -av $firmware_path/ $jenkins_server:$share_path/${branch_for_test}_root
            else
                rsync -av $firmware_path/ $jenkins_server:$share_path/$branch_for_test
            fi
        elif [ "$build_branch" == $branch_for_develop ];then
            if [ "`is_root_yunovo_project`" == "true" -a "$build_type" == "$root_version" ];then
                rsync -av $firmware_path/ $jenkins_server:$share_path/${branch_for_develop}_root
            else
                rsync -av $firmware_path/ $jenkins_server:$share_path/$branch_for_develop
            fi
        else
            if [ "`is_root_yunovo_project`" == "true" -a "$build_type" == "$root_version" ];then
                rsync -av $firmware_path/ $jenkins_server:$share_path/debug_root
            else
                rsync -av $firmware_path $jenkins_server:$share_path
            fi
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
    local project_name=($k26P $k26sP $k26sdP $k27P $k86aP $k86mP $k86mx2P $k86sP $k86smP $k86lP $k86lsP $k86ldP $k86lsdP $k88cP $k88c21P $k88sP)
    local sz_project_name=`echo k26 k26s k26sd k27 k86a k86m k86mx2 k86s k86sm k86l k86ls k86ld k86lsd k88c k88c_21 k88s`
    local sz_base_path=~/jobs
    local jenkins_username=""
    local hostN=`hostname`

    if [ $hostN == "happysongs" ];then
        jenkins_username=xingyafeng
    elif [ $hostN == "s1" -o $hostN == "s2" -o $hostN == "s3" -o $hostN == "s4" -o $hostN == "s5" ];then
        jenkins_username=jenkins
    fi

    for sz_custom in $sz_project_name
    do
        local sz_yunovo_customs_path=$sz_base_path/$sz_custom/yunovo_customs
        local sz_yunovo_path=$sz_base_path/$sz_custom

        if [ "`get_project_real_name`" == "$sz_custom" ];then

            case "`get_project_real_name`" in

                k26sd)
                    sz_custom=k26s
                    ;;
                k86ld)
                    sz_custom=k86l
                    ;;
                k86lsd)
                    sz_custom=k86ls
                    ;;
                *)
                    __echo "sz_custom no mactch double mic procject. "
                    ;;
            esac

            local sz_yunovo_customs_link_server=`echo ssh://${jenkins_username}@gerrit.y:29419/xyf/${sz_custom}/yunovo_customs`
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

            for p in ${project_name[@]}
            do
                if [ $sz_custom == "${p}_root" ];then
                    sz_custom=`get_project_name`
                    sz_yunovo_customs_link_server=`echo ssh://${jenkins_username}@gerrit.y:29419/xyf/${sz_custom}/yunovo_customs`
                fi
            done

            cd $sz_yunovo_path > /dev/null

            if [ "$sz_yunovo_customs_link_server" ];then
                _echo "custom link = $sz_yunovo_customs_link_server"

                git clone $sz_yunovo_customs_link_server
                echo
            else
                echo "$sz_yunovo_customs_link_server not found !"
            fi

            cd - > /dev/null
        fi
    done

	cd $nowPwd
}

function auto_git_create_branch_refs()
{
    local username=`whoami`
    local remotename=origin
    local refsname=${build_prj_name}_${build_version}_${time_for_refs}

    if [ "`git ls-remote --refs $remotename | grep $refsname`" ];then
        _echo "--> $refsname is exist ."
    else
        git push $remotename HEAD:refs/build/$username/$refsname
    fi
}

function auto_create_branch_refs()
{
    local username=`whoami`
    local remotename=origin
    local refsname=${build_prj_name}_${build_version}_${time_for_refs}
    local ls_remote_p=frameworks
    local is_create_refs=

    if [ "`is_yunovo_project`" == "true" ];then

        cd $ls_remote_p > /dev/null

        if [ "`git ls-remote --refs $remotename | grep $refsname`" ];then
            is_create_refs=true
        else
            is_create_refs=false
        fi

        cd - > /dev/null

        if [ "$is_create_refs" == "true" ];then
            _echo "--> $refsname is exist ..."
        else
            repo forall -c git push $remotename HEAD:refs/build/$username/$refsname

            __echo "create branch refs successful ..."
        fi
    else
        _echo "current directory is not android !"
        return 1
    fi
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
    local start_curr_time=`date +'%Y-%m-%d %H:%M:%S'`

    if [ "`is_yunovo_project`" == "true" ];then

        if [ ! -d $debug_path ];then
            mkdir $debug_path -p
        fi
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

    if [ $flag_download_sdk -eq 1 -a "$build_update_code" == "true" ];then
        ### download source code
        download_sdk
    else
        echo "do not download_sdk !"
    fi

    if [ $flag_clone_app -eq 1 ];then
        down_load_apk_for_yunovo
        down_load_app_for_yunovo
        #ant_app
        #auto_copy_app_to_android
    else
        echo "do not clone app !"
    fi

    if [ $flag_cpcustom -eq 1 -a "$build_update_code" == "true" ];then

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
        make_yunovo_android
    else
        echo "do not make sdk !"
    fi

    if [ "$build_refs" == "false" ];then

        ### create refs for source code
        auto_create_branch_refs
        print_system_app_and_apk

        __echo "auto create branch refs successful ..."
    else
        __echo "auto create branch refs fail ..."
    fi

    if [ $flag_cpimage -eq 1 ];then
	    if cpimage;then
            sync_jenkins_server
        fi
    else
        echo "do not cp image !"
    fi

    if [ "`is_yunovo_server`" == "true" ];then

        print_make_completed_time "$start_curr_time"

        echo
        echo "---> make android end ."
        echo
    else
        echo "server name is not s1 s2 s3 s4 happysongs ww !"
        return 1
    fi
}

### 自动拷贝系统app
function auto_copy_app_to_android()
{
    local apk_path=~/android
    local prj_name=`get_project_real_name`

    if [ "prj_name" ];then
        local prj_path=~/jobs/${prj_name}/android/
    else
        _echo "prj_name is null, please check it ..."
        return 1
    fi

    if [ -d $apk_path -a -d $prj_path ];then
        cp -r $apk_path/* $prj_path && _echo "cp done: $prj_path ."
    else
        _echo "apk_path prj_path not found, please check it ..."
        return 1
    fi
}

### 自动创建android.mk
function auto_create_android_mk()
{
    local android_mk_file_name=Android.mk
    local armeabi_so=armeabi
    local armeabi_v7a_so=armeabi-v7a
    local curr_apk_name=$1

    local jni_lib="LOCAL_PREBUILT_JNI_LIBS := \\"
    local privileged_module="LOCAL_PRIVILEGED_MODULE := true"
    local build_prebuild="include \$(BUILD_PREBUILT)"

    if [ $# -eq 1 ];then
        :
    else
        _echo "Please e.g auto_create_android_mk  xxx.apk ..."
        return 1
    fi

    (cat << EOF) > ./$android_mk_file_name
LOCAL_PATH := \$(call my-dir)

EOF

if false;then
    if [ "$curr_apk_name" ];then
        curr_apk_name="${curr_apk_name/%.apk/}"
    else
        return 1
    fi
fi

    (cat << EOF) >> ./$android_mk_file_name
include \$(CLEAR_VARS)
LOCAL_MODULE := $curr_apk_name
LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_CLASS := APPS
LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_MULTILIB := 32

EOF
    if [ "`unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi-v7a\/.*.so$/ {print $(NF)}'`" ];then
        unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi-v7a\/.*.so$/ {print $(NF)}' > $zz_script_path/${armeabi_v7a_so}.txt
    elif [ "`unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}'`" ];then
        unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}' > $zz_script_path/${armeabi_so}.txt
    else
        echo $privileged_module >> ./$android_mk_file_name
        echo $build_prebuild >> ./$android_mk_file_name
    fi

    if [ -f $zz_script_path/${armeabi_v7a_so}.txt ];then
        echo $jni_lib >> ./$android_mk_file_name
        while read lib_path;do
            echo "    @$lib_path \\" >> ./$android_mk_file_name
        done < $zz_script_path/${armeabi_v7a_so}.txt

        echo >> ./$android_mk_file_name
        echo $privileged_module >> ./$android_mk_file_name
        echo $build_prebuild >> ./$android_mk_file_name

        rm $zz_script_path/${armeabi_v7a_so}.txt
    elif [ -f $zz_script_path/${armeabi_so}.txt ];then

        echo $jni_lib >> ./$android_mk_file_name

        while read lib_path;do
            echo "    @$lib_path \\" >> ./$android_mk_file_name
        done < $zz_script_path/${armeabi_so}.txt

        echo >> ./$android_mk_file_name
        echo $privileged_module >> ./$android_mk_file_name
        echo $build_prebuild >> ./$android_mk_file_name

        rm $zz_script_path/${armeabi_so}.txt
    else
        if [ -f $android_mk_file_name ];then
            sed -i '/LOCAL_MULTILIB := 32/d' $android_mk_file_name
        else
            __echo "Android.mk not found, please check it !"
            return 1
        fi
    fi
}

main
