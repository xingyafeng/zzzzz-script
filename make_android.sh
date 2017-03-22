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
### build project name  e.g. : K86_H520
build_prj_name=$2
### eg: k86l_yunovo_zx
build_file=$3
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

### S1.00 S1.01 ...
first_version=""
second_version=""

### send email
email_receiver=""
email_content=""

################################# common variate
hw_versiom=H3.1
debug_path=~/debug
version_p=~/.jenkins_make_version
cur_time=`date +%m%d_%H%M`
time_for_version=`date +'%Y.%m.%d_%H.%M.%S'`
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
mx1_teyes_t7_p=mx1_teyes_t7
mx1_teyes_t72_p=mx1_teyes_t72
mx1_yunovo_zx_p=mx1_yunovo_zx

mx1_xianzhi_t80c_p=mx1_xianzhi_t80c
mx1_xianzhi_t80_p=mx1_xianzhi_t80

k26b_vst_s2_p=k26b_vst_s2
k26b_fxft_h480_p=k26b_fxft_h480

k26s_vst_s1_p=k26s_vst_s1
k26s_vst_s2_p=k26s_vst_s2
k26s_vst_k3_p=k26s_vst_k3
k26s_vst_a1a_p=k26s_vst_a1a
k26s_vst_a2a_p=k26s_vst_a2a
k26s_vst_a1_p=k26s_vst_a1
k26s_vst_a2_p=k26s_vst_a2

k26s_ld_a107c_p=k26s_ld_a107c
k26s_newsmy_d900_p=k26s_newsmy_d900
k26s_fxft_h481_p=k26s_fxft_h481

k27_hbs_t2_p=k27_hbs_t2
k27_xinke_ds50_p=k27_xinke_ds50
k27_aj_ajs_p=k27_aj_ajs
k27_vst_d1_p=k27_vst_d1

k28s_ld_a107c_p=k28s_ld_a107c
k28s_ld_hs995d_p=k28s_ld_hs995d
k28s_rwy_cs85_p=k28s_rwy_cs85

k88c_jm_cm01_p=k88c_jm_cm01
k88c_jm01_cm01_p=k88c_jm01_cm01
k88c_bt_bt188_p=k88c_bt_bt188

k89_ld_hs720a_p=k89_ld_hs720a

k86mx1_jh_s04a_p=k86mx1_jh_s04a
k86mx1_jh01_s04a_p=k86mx1_jh01_s04a
k86mx1_rwy_dz80_p=k86mx1_rwy_dz80
k86mx1_byos_s8_p=k86mx1_byos_s8
k86mx1_meiban_m8s_p=k86mx1_meiban_m8s

k88c_6735_VoLTE_develop_p=6735_VoLTE_develop
mtk6753_volte_develop_p=mtk6753_volte_develop
mtk6753_volte_develop_p=mtk6753_volte_develop
mtk6735_gps_develop_p=mtk6735_gps_develop

k86sa1_tpl_tpl86s_hd_p="k86sa1_tpl_tpl86s-hd"
k86sa1_mazda_master_p=k86sa1_mazda_master
k86sa1_meiban_m4z_p=k86sa1_meiban_m4z

k86s7_wc_vs188_p=k86s7_wc_vs188

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
        _echo "---- dir is : $pwd $1"
    else
        _echo "---- dir is : $pwd"
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
        _echo "msg is null, please check it !"
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

        $mx1_teyes_t7_p | $mx1_teyes_t72_p | $mx1_yunovo_zx_p)
            echo true

            ;;

        $k26b_vst_s2_p | $k26b_fxft_h480_p | $k26s_vst_s1_p | $k26s_vst_s2_p | $k26s_newsmy_d900_p | $k26s_vst_k3_p)
            echo true

            ;;


        $k26s_ld_a107c_p | $k26s_vst_a1a_p | $k26s_vst_a2a_p | $k26s_fxft_h481_p | $k26s_vst_a1_p | $k26s_vst_a2_p)
            echo true

            ;;

        $k27_hbs_t2_p | $k27_xinke_ds50_p | ${k27_aj_ajs_p}-1 | $k27_vst_d1_p)
            echo true

            ;;

        $k28s_ld_a107c_p | $k28s_ld_hs995d_p | $k28s_rwy_cs85_p)
            echo true

            ;;

        $k88c_jm_cm01_p | $k88c_jm01_cm01_p | $k88c_bt_bt188_p)
            echo true

            ;;

        $k89_ld_hs720a_p)
            echo true
            ;;

        $mx1_xianzhi_t80c_p | $mx1_xianzhi_t80_p)
            echo true

            ;;

        $k86mx1_jh_s04a_p | $k86mx1_jh01_s04a_p | $k86mx1_rwy_dz80_p | $k86mx1_byos_s8_p | $k86mx1_meiban_m8s_p)
            echo true

            ;;

        $k86sa1_tpl_tpl86s_hd_p | $k86sa1_mazda_master_p | $k86sa1_meiban_m4z_p)
            echo true

            ;;

        $k88c_6735_VoLTE_develop_p | $mtk6753_volte_develop_p |$mtk6735_gps_develop_p)
            echo true

            ;;

        $k86s7_wc_vs188_p)
            echo true
            ;;

        *)
            echo false

            ;;
    esac
}

function get_project_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    if [ "$thisP" ];then
        echo $thisP
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

### 是否为调试版本
function is_root_project()
{
    if [ "$build_type" == "userdebug" -o "$build_type" == "eng" ];then
        echo true
    else
        echo false
    fi
}

### 是否为编译服务器
function is_yunovo_server()
{
    local hostN=`hostname`
    local serverN=(s1 s2 s3 s4 s5 happysongs ww he-All-Series.)
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
    local cpu_type_more=(aeon6735_65c_s_l1 aeon6735m_65c_s_l1 magc6580_we_l ea6735_65c_a_l1)
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

### 是否为调试版本
function is_root_version()
{
    local build_type_root=(eng userdebug)

    local buildR=$1

    if [ $# -eq 1 ];then
        :
    else
        _echo "$# is error, please check args [is_root_version] !"
        return 1
    fi

    for t in ${build_type_root[@]}
    do
        if [ $t == $buildR ];then
            echo true
        fi
    done
}

function sendEmail_diffmanifest_to_who()
{
    local sz_receiver=$1
    local sz_message_file=$2
    local title="${build_prj_name} project !"

    local receiver=""
    local content=""
    local user="notify@yunovo.cn"
    local sender="jenkins<$user>"

    local key=n123456
    local server_name=smtp.exmail.qq.com
    local content_type="message-content-type=html"
    local charset="message-charset=utf-8"

    if [ "$sz_receiver" ];then
        receiver=$sz_receiver
    else
        __echo "receiver is null ."
        return 1
    fi

    if [ "$sz_message_file" -a -f "$sz_message_file" ];then
        content=$sz_message_file
    elif [ "$sz_message_file" ];then
        content=$sz_message_file
    fi

    if [ -f "$content" ];then
        sendEmail -f $sender -s $server_name -u $title -o $charset -o $content_type -xu $user -xp $key -t $receiver -o message-file=$content

        ## backup diff.html file
        scp -r $content jenkins@f1.y:/public/jenkins/jenkins_share_20T/backupfs
    else

        if [ ! -f "$content" ];then
            content="make project successful ..."
        fi

        sendEmail -f "$sender" -s $server_name -u $title -o $charset -o $content_type -xu $user -xp $key -t $receiver -m "$content"
    fi

    if [ -f "$content" ];then
        rm -rf $content
    fi
}


function repo_diffmanifests_to_jenkins()
{
    local old_manifest_version=yunovo/diffmanifests/default.xml
    local manifest_path=.repo/manifests
    local diff_manifest_xml=diff.xml
    local diff_manifest_log=$version_p/diff.log
    local OLDPWD=`pwd`
    local diff_manifests_git=yunovo/diffmanifests/.git
    local tmp_version=$zz_script_path/fs/version.log
    local diff_manifests_tmp=$zz_script_path/fs/diff.log

    local startV=
    local datetime=`date +'%Y.%m.%d_%H.%M.%S'`
    local endV=${build_prj_name}_${build_version}_${datetime}

    if [ -d $diff_manifests_git ];then
        startV=`git --git-dir=$diff_manifests_git lg -1 | awk '{ print $7 }'`
    fi

    echo "start: $startV"
    echo "end  : $endV"
    ##add version form ... to ...
    echo $startV "->" $endV > $tmp_version
    echo "-------------------------------------------------" >> $tmp_version
    echo >> $tmp_version
    echo "1. 构建者 : ${BUILD_USER}" >> $tmp_version
    echo "2. 服务器 : `hostname`" >> $tmp_version
    echo "3. 全路径 : ${OLDPWD}" >> $tmp_version
    echo "4. 工程名 : ${project_name}" >> $tmp_version
    echo "5. 项目名 : ${custom_version}" >> $tmp_version
    echo "6. 版本号 : ${build_version}" >> $tmp_version
    echo "7. 客制化路径 : ${prefect_name}" >> $tmp_version
    echo "8. 系统版本号 : ${system_version}" >> $tmp_version
    echo "-------------------------------------------------" >> $tmp_version
    echo "1. lunch选工程， lunch       = ${lunch_project}" >> $tmp_version
    echo "2. 是否编译OTA， make ota    = ${build_make_ota}"  >> $tmp_version
    echo "3. 是否清除编译，make clean  = ${build_clean}"  >> $tmp_version
    echo "4. 是否更新代码，update code = ${build_update_code}" >> $tmp_version
    echo "-------------------------------------------------" >> $tmp_version

    if [ -f $old_manifest_version ];then
        cp $old_manifest_version $manifest_path/$diff_manifest_xml
    fi

    if [ -f $manifest_path/$diff_manifest_xml ];then

        repo diffmanifests $diff_manifest_xml > $diff_manifests_tmp

        if [ -f $tmp_version ];then
            cat $tmp_version $diff_manifests_tmp > $diff_manifest_log
            rm -r $tmp_version
        fi

        if [ $? -eq 0 ];then
            rm $manifest_path/$diff_manifest_xml
        fi
    else
        _echo "yunovo/diffmanifests/default.xml not found !"
    fi
}

function auto_create_manifest()
{
    local remotename=
    local username=`whoami`
    local datetime=`date +'%Y.%m.%d_%H.%M.%S'`
    local refsname=${build_prj_name}_${build_version}_${datetime}
    local prj_name=`get_project_name`

    local manifest_path=.repo/manifests
    local manifest_default=default.xml
    local manifest_name=tmp.xml
    local manifest_branch=

    local projectN=${prj_name%%_*}
    local customN=${prj_name#*_} && customN=${customN%%_*}
    local modeN=${prj_name##*_}

    if [ $customN == "gps" ];then
        customN=gps_repair
    fi

    manifest_branch="$projectN/$customN/$modeN"

    _echo "manifest_branch = $manifest_branch"

    if [ "`is_yunovo_project`" == "true" ];then

        ## create tmp.xml
        repo manifest -r -o $manifest_path/$manifest_name

        cd $manifest_path > /dev/null

        remotename=`git remote`

        if [ -f $manifest_name ];then
            mv $manifest_name $manifest_default
            if [ "`git status -s`" ];then
                git add $manifest_default
                git commit -m "add manifest for $refsname"
                git push $remotename HEAD:refs/build/$username/$refsname
            else
                _echo "$manifest_default is not change ."
            fi
        else
            _echo "$manifest_name is not exist ."
            exit 1
        fi

        cd - > /dev/null

        repo init -b $manifest_branch
    else
        _echo "current directory is not android !"
        exit 1
    fi
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

    echo "#### make completed successfully ($hh:$mm:$ss (hh:mm:ss)) ($endT) ###"
}

### handler vairable for jenkins
function handler_vairable()
{
    local prj_name=`get_project_name`

    local sz_build_project=$1
    local sz_build_device=$2
    local sz_build_file=$3

    ### 1. project name
    if [ "$sz_build_project" ];then

        ### remove space
        echo "$sz_build_project" > $tmp_file
        sz_build_project=`remove_space_for_vairable $sz_build_project`

        build_prj_name=$sz_build_project
        project_name=${build_prj_name%%_*}
        custom_version=${build_prj_name##*_}

        if [ -z "$project_name" -o  -z "$custom_version" ];then
            echo "project_name or custom_version is null ."
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

    ### 3. build file
    if [ "$sz_build_file" ];then

        ### remove space
        echo "$sz_build_file" > $tmp_file
        sz_build_file=`remove_space_for_vairable $sz_build_file`

        if [ `echo $sz_build_file | egrep /` ];then
            prefect_name=$sz_build_file
        else
            echo "build_file is error, please checkout it !"
            return 1
        fi
    else
        echo "sz_build_file is null !"
        return 1
    fi

    ### 4. build device
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

    ### 5. build type
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

    ### 6. build test
    if [ "$yunovo_test" ];then
        build_test=$yunovo_test
    else
        build_test=false
    fi

    ### 7. build ota
    if [ "$yunovo_make_ota" ];then
        build_make_ota=true
    else
        if [ "`is_root_project`" == "true" ];then
            build_make_ota=false
        else
            build_make_ota=true
        fi
    fi

    if [ "$yunovo_ota" ];then
        build_make_ota=$yunovo_ota
    else
        if [ "`is_root_project`" == "true" ];then
            build_make_ota=false
        else
            build_make_ota=true
        fi
    fi

    ### 8. build make update-api
    if [ "$yunovo_update_api" ];then
        build_update_api=$yunovo_update_api
    else
        build_update_api=false
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

    ## 12. build refs
    if [ "$yunovo_refs" ];then
        build_refs=$yunovo_refs
    else
        build_refs=false
    fi

    ## 13. build update source code
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

function copy_out_image()
{
	### k86A_H520
	local prj_name=$project_name\_$custom_version

	echo "prj_name = $prj_name"

    if [ "`is_root_project`" == "true" ];then
        local ver_name=${first_version}.${second_version}
    else
        local ver_name=${first_version}.${second_version}.${time_for_version}
    fi

    ### k86m_H520/S1
	#local BASE_PATH=/home/work5/public/k86A_Test/${prj_name}/${ver_name}
    local firmware_path=$version_p
	local BASE_PATH=$firmware_path/${project_name}/${prj_name}/${ver_name}
	local DEST_PATH=$BASE_PATH/$system_version
	local OTA_PATH=$BASE_PATH/${system_version}_full_and_ota

    local server_name=`hostname`
    local firmware_path_server=/home/share/jenkins_share/debug

    echo "--------------------------local base"
	echo "BASE_PATH = $BASE_PATH"
	echo "DEST_PATH = $DEST_PATH"
	echo "OTA_PATH = $OTA_PATH"
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

        if [ -f ${OUT}/custom.img ];then
            cp -vf ${OUT}/custom.img ${DEST_PATH}
        fi

        cp -vf ${OUT}/system.img ${DEST_PATH}
	    cp -vf ${OUT}/cache.img ${DEST_PATH}
	    cp -vf ${OUT}/userdata.img ${DEST_PATH}

	    cp -vf ${OUT}/obj/CGEN/APDB_MT*W* ${DEST_PATH}/database/ap
	    cp -vf ${OUT}/system/etc/mddb/BPLGUInfoCustomAppSrcP* ${DEST_PATH}/database/moden

        _echo "---> copy out image end ..."

        if [ $build_make_ota == "true" ];then
            if [ "`ls ${OUT}/full_${build_device}-ota*.zip`" ];then
                if [ "`get_project_name`" == "k88c_jm01_cm01"  ];then
                    cp -v ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}/jmupdate.zip
                else
                    cp -v ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}/sdupdate.zip
                fi
                _echo "copy sdupdate.zip successful ..."
            fi

            if [ "`ls ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip`" ];then
                cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH}/${system_version}.zip
                _echo "copy ota file successful ..."
            fi
        fi

        if [ "`ls ${OUT}/target_files-package.zip`" ];then
            cp -v ${OUT}/target_files-package.zip ${OTA_PATH}
        fi
        ### add readme.txt in version
        if [ -f $readme_file ];then
            cp -vf $readme_file ${BASE_PATH}
            if [ $? -eq 0 ];then
                rm $readme_file -r
            fi
        fi
    fi

    _echo "copy out image finish ... in $server_name"
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
	echo "build_device = $build_device"
	echo "build_type = $build_type"
    echo "build_branch = $build_branch"
    echo "build_clean= $build_clean"
    echo "build_make_ota = $build_make_ota"
    echo "build_update_api = $build_update_api"
    echo "build_update_code = $build_update_code"
    echo "build_refs = $build_refs"
	echo "lunch_project = $lunch_project"
	echo "fota_version = $fota_version"
	echo '-----------------------------------------'
    echo "yunovo_test = $yunovo_test"
    echo "yunovo_clean = $yunovo_clean"
    echo "yunovo_branch = $yunovo_branch"
    echo "yunovo_update_api = $yunovo_update_api"
    echo "yunovo_update_code = $yunovo_update_code"
	echo '-----------------------------------------'

	echo "\$1 = $1"
	echo "\$2 = $2"
	echo "\$3 = $3"
	echo "\$4 = $4"
	echo "\$5 = $5"
	echo "\$# = $#"
	echo '-----------------------------------------'
    echo
}

#### 复制差异化文件
function copy_customs_to_android()
{
    local select_project=$prefect_name
	local thisSDKTop=$(gettop)
	local ConfigsPath=${thisSDKTop}/yunovo/customs

	if [ -d "$ConfigsPath" ]; then
		ConfigsPath=$(cd $ConfigsPath && pwd)
	else
		echo "no path : $ConfigsPath"
		return 1
	fi

	local ConfigsFName=proj_help.sh
	local ProductSetTop=${ConfigsPath}

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

            if false;then
            ## 清除旧项目的修改
			echo "clean by $OldProductSelDirAndroid" && chiphd_recover_standard_device_cfg $OldProductSelDirAndroid

			## 确保新项目的修改纯净
			echo "clean by $ProjectSelDirAndroid" && chiphd_recover_standard_device_cfg $ProjectSelDirAndroid
            fi

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

function handler_android_mk()
{
    local app=$1
    local OLDPWD=`pwd`
    local yunovo_app_path=yunovo/packages/apps
    local sh=appmk.sh

    if [ $build_prj_name == "k28s_LD-A107C" -o $build_prj_name == "k28s_LD-HS995" -o $build_prj_name == "k28s_LD-HS995D" ];then

        if [ "$app" == "CarConfig" ];then
            cd $yunovo_app_path/$app > /dev/null

            if [ -f $sh ];then
                chmod +x $sh
                ./$sh $app
            fi

            cd $OLDPWD > /dev/null
        fi
    fi
}

## 更新源代码
function update_source_code()
{
    if [ -f build/core/envsetup.mk -a -f Makefile  ]; then

        ## 初始化环境变量
        source_init

        ## 还原 androiud源代码 ...
        recover_standard_android_project

        if [ `is_yunovo_server` == "true" ];then

        ## start repo init
        repo init -b ${branchN}

        ## update android source code for yunovo project ...
        if repo sync -j${cpu_num} -c -d --no-tags --prune;then
            __echo "repo sync successful ..."
        fi
        fi

    else

        ## 下载中断处理,需要重新下载代码
        rm .repo/ -rf

        download_source_code
    fi

}

## 下载源代码
function download_source_code()
{
    if [ "$project_link" -a "$branchN" ];then
        repo $project_link -b ${branchN}
        repo sync -j${cpu_num} -c -d --no-tags --prune
    fi

    ## 第一次下载完成后，需要初始化环境变量
    if [ -d .repo ];then
        source_init
    else
        echo "The (.repo) not found ! please download sdk !"
        return 1
    fi
}

function down_load_yunovo_source_code()
{
    local prj_name=`get_project_name`
    local branchN=

    local projectN=${prj_name%%_*}
    local customN=${prj_name#*_} && customN=${customN%%_*}
    local modeN=${prj_name##*_}

    if [ $customN == "gps" ];then
        customN=gps_repair
    fi

    branchN="$projectN/$customN/$modeN"

    _echo "branchN = $branchN"

	if [ -d .repo ];then
        update_source_code
	else
        download_source_code
	fi
}

## build android system for yunovo project
function make_yunovo_android()
{
    local receiver="514779897@qq.com"
    local content="make project successful ..."

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
    fi

    if [ "$cpu_num" -gt 0 ];then
        :
    else
        _echo "cpu_num is error ..."
        return 1
    fi

    if make -j${cpu_num} ${fota_version};then
        _echo "--> make project end ..."

        sendEmail_diffmanifest_to_who "$receiver" "$content"
    else
        _echo "make android failed !"
        return 1
    fi

    if [ "$build_make_ota" == "true" ];then
        if make -j${cpu_num} ${fota_version} otapackage;then
            _echo "--> make otapackage end ..."
        else
            _echo "make otapackage fail ..."
            return 1
        fi
    else
        _echo "build_make_ota = $build_make_ota"
    fi
}

function sync_image_to_server()
{
    local firmware_path=$version_p
    local share_path=/public/jenkins/jenkins_share_20T
    local jenkins_server=jenkins@f1.y

    local root_version=userdebug
    local root_version_eng=eng
    local branch_for_test=test
    local branch_for_master=master
    local branch_for_develop=develop

    if [ ! -d $firmware_path ];then
        mkdir $firmware_path
    fi

    if [ "`is_yunovo_server`" == "true" ];then

        if [ $build_test == "true" ];then

            rsync -av $firmware_path/ $jenkins_server:$share_path/happysongs
        elif [ "$build_branch" == $branch_for_test ];then

            if [ "$build_type" == "$root_version" -o "$build_type" == "$root_version_eng" ];then
                rsync -av $firmware_path/ $jenkins_server:$share_path/${branch_for_test}_root
            else
                rsync -av $firmware_path/ $jenkins_server:$share_path/$branch_for_test
            fi
        elif [ "$build_branch" == $branch_for_develop ];then

            if [ "$build_type" == "$root_version" -o "$build_type" == "$root_version_eng" ];then
                rsync -av $firmware_path/ $jenkins_server:$share_path/${branch_for_develop}_root
            else
                rsync -av $firmware_path/ $jenkins_server:$share_path/$branch_for_develop
            fi
        else
            if [ "$build_type" == "$root_version" -o "$build_type" == "$root_version_eng" ];then
                rsync -av $firmware_path/ $jenkins_server:$share_path/yunovo_root
            else
                rsync -av $firmware_path/ $jenkins_server:$share_path/yunovo
            fi
        fi

        if [ -d $firmware_path ];then
            rm $firmware_path/* -rf
        else
            _echo "$firmware_path not found !"
        fi

        _echo "--> sync end ..."
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
    __echo "source end ..."

    lunch $lunch_project

    __echo "lunch end ..."

    ROOT=$(gettop)
    OUT=$OUT
    DEVICE_PROJECT=`get_build_var TARGET_DEVICE`

    if [ $DEVICE_PROJECT == $magcomm_project ];then
        DEVICE=device/magcomm/$DEVICE_PROJECT
    elif [ $DEVICE_PROJECT == $eastaeon_project -o $DEVICE_PROJECT == $eastaeon_project_m ];then
        DEVICE=device/eastaeon/$DEVICE_PROJECT
    else
        DEVICE=device/eastaeon/$DEVICE_PROJECT
        _echo "DEVICE do not match it ..."
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

        if [ ! -d $version_p ];then
            mkdir -p $version_p
        fi

        if [ ! -d $zz_script_path/fs ];then
            mkdir -p $zz_script_path/fs
        fi
    else
        _echo "current directory is not android !"
        return 1
    fi

    if [ "`is_yunovo_server`" == "true" ];then

        __echo "make android start ."

        if [ "$build_prj_name" -a "$build_device" -a "$build_file" ];then

            ### 处理输入参数，并检查其有效性...
            handler_vairable $build_prj_name $build_device $build_file
            ### 输出完整参数
            print_variable $build_prj_name $build_version $build_device $build_type $build_file

            if [ "`is_root_version $build_type`" == "true" ];then
                email_receiver="281220263@qq.com"
                email_content="make root project successful ..."
            else
                email_receiver="android_software@yunovo.cn"
                email_content="$version_p/diff.html"
          fi
        else
            _echo "xargs is error, please checkout xargs."
            return 1
        fi

    else
        _echo "server name is not s1 s2 s3 s4 happysongs ww !"
        return 1
    fi

    if [ -d .repo -a -f build/core/envsetup.mk -a -f Makefile ];then
        ### 初始化环境变量
        if [ "`is_check_lunch`" == "no lunch" ];then
            source_init
        else
            print_env
        fi
    fi

    if [ "$build_update_code" == "true" ];then

        ## 下载，更新源码
        down_load_yunovo_source_code

        ### repo diffmainifests
        repo_diffmanifests_to_jenkins

        ### input content diff has colors
        repo_diffmanifests_has_colors

        ### send email
        if [ "`is_root_version $build_type`" != "true" ];then
            sendEmail_diffmanifest_to_who "$email_receiver" "$email_content"
        fi
    fi

    if [ "`is_check_lunch`" != "no lunch" ];then
        if [ "$build_update_code" == "true" ];then
            copy_customs_to_android
            handler_custom_config
            handler_android_mk CarConfig
        else
            _echo "build_update_code is false !"
        fi
    else
        _echo "current directory is not android ! gettop is null !"
        return 1
    fi

    if [ "$build_update_api" == "true" ];then
        if make update-api -j${cpu_num};then
            _echo "---> make update-api end !"
        else
            _echo "make update-api fail !"
            return 1
        fi
    else
        _echo "do not make update-api !"
    fi

    ### 编译源码
    make_yunovo_android

    ### 回写当前manifest
    auto_create_manifest

    ### 版本上传至服务器
    if copy_out_image;then
        sync_image_to_server
    fi

    if [ "`is_yunovo_server`" == "true" ];then

        ### 打印编译所需要的时间
        print_make_completed_time "$start_curr_time"

        __echo "make android end ."
    else
        echo "server name is not s1 s2 s3 s4 happysongs ww !"
        return 1
    fi
}

function repo_diffmanifests_has_colors()
{
    local diff_manifest_log=$version_p/diff.log
    local diff_manifest_html=$version_p/diff.html

    if [ -f $diff_manifest_html ];then

        rm $diff_manifest_html
    fi

    if [ -f $diff_manifest_log ];then

    cat >>  $diff_manifest_html << EOF

    <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        </head>
        <body>
        <pre>
EOF

    cat $diff_manifest_log >> $diff_manifest_html

    sed -i 's#\[32m\(.*\)#<font size="5" color="\#FF1493">\1</font> #g' $diff_manifest_html
    sed -i 's/'`echo -e "\033"`'//g' $diff_manifest_html
    sed -i 's#\[1\;31m\(.*\)\[m\[#<font color="\#32CD32">\1</font> #g' $diff_manifest_html
    sed -i 's#\[1\;32m\(.*\)\[m\[#<font color="\#32CD32">\1</font> #g' $diff_manifest_html
    sed -i 's#\[m\[33m\(.*\)\[m #<font color="\#00CED1">\1</font> #g' $diff_manifest_html
    sed -i 's#\[m\[33m\(.*\)\[m#<font color="\#00CED1">\1</font> #g' $diff_manifest_html
    sed -i 's#33m\(.*\)\[m #<font color="\#A0522D">\1</font> #g' $diff_manifest_html
    sed -i 's#\[1m\(.*\)\[m #<font color="\#EE3A8C">\1</font> #g' $diff_manifest_html
    sed -i 's#\[m##g' $diff_manifest_html

    cat >> $diff_manifest_html << EOF
    </pre>
    </body>
    </html>
EOF

        scp -r $diff_manifest_log jenkins@f1.y:/public/jenkins/jenkins_share_20T/backupfs

        if [ -f $diff_manifest_log ];then
            rm -rf $diff_manifest_log
        fi
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
    if [ "`unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ {print $(NF)}'`" ];then
        unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ {print $(NF)}' > $zz_script_path/${armeabi_v7a_so}.txt
    elif [ "`unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ {print $(NF)}'`" ];then
        unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ {print $(NF)}' > $zz_script_path/${armeabi_so}.txt
    else
        echo $build_prebuild >> ./$android_mk_file_name
    fi

    if [ -f $zz_script_path/${armeabi_v7a_so}.txt ];then
        echo $jni_lib >> ./$android_mk_file_name
        while read lib_path;do
            echo "    @$lib_path \\" >> ./$android_mk_file_name
        done < $zz_script_path/${armeabi_v7a_so}.txt

        echo >> ./$android_mk_file_name
        echo $build_prebuild >> ./$android_mk_file_name

        rm $zz_script_path/${armeabi_v7a_so}.txt
    elif [ -f $zz_script_path/${armeabi_so}.txt ];then

        echo $jni_lib >> ./$android_mk_file_name

        while read lib_path;do
            echo "    @$lib_path \\" >> ./$android_mk_file_name
        done < $zz_script_path/${armeabi_so}.txt

        echo >> ./$android_mk_file_name
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
