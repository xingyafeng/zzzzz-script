#!/bin/bash

## if error then exit
set -e

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

k26PR=k26_root
k86aPR=k86a_root
k86mPR=k86m_root
k86sPR=k86s_root
k86smPR=k86sm_root
k86lPR=k86l_root
k86lsPR=k86ls_root
k88cPR=k88c_root
k86ldPR=k86ld_root


## ota from to version
ota_from_version=$1
ota_to_version=$2

## server name
sz_f1_server_name=f1
sz_ota_tmp_path=~/workspace/otafs

function __msg()
{
    local pwd=`pwd`
    echo "currect dir is : $pwd"
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

### 是否为云智易联项目
function is_yunovo_project
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    case $thisP in

        $k26P | $k26PR)
            echo true

            ;;
        $k86aP | $k86aPR)
            echo true

            ;;
        $k86mP | $k86mPR)
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
        $k88cP | $k88cPR)
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
    local project_name=($k26P $k86aP $k86mP $k86sP $k86smP $k86lP $k86lsP $k86ldP $k88cP)

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
        echo "it do not get project name !"
        return 1
    fi
}

### 是否为编译服务器
function is_yunovo_server()
{
    local hostN=`hostname`
    local serverN=(s1 s2 s3 s4 happysongs ww)
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

function handler_variable()
{
    if [ $# -eq 2 ];then
        :
    else
        _echo "xargs -nq 2 ,please checkout xargs ."
    fi
}


function sync_ota_server()
{
    local ota_local_path=~/OTA
    local share_path=/public/jenkins/jenkins_share_20T
    local jenkins_server=jenkins@f1.y

    if [ -d $ota_local_path ];then
        rsync -av $ota_local_path $jenkins_server:$share_path
    fi
}

function cpfs()
{
    if [ $# -eq 1 ];then
        :
    else
        __echo "e.g cpfs ota_file server ... "
        return 1
    fi

    local sz_ota_file=$1
    local sz_local_path=/home/jenkins/workspace/otafs
    local sz_server_path=/public/jenkins/jenkins_share_20T/otafs

    if [ ! -d $sz_local_path ];then
        mkdir -p $sz_local_path
    fi

    if [ "`is_yunovo_server`" == "true" ];then
        scp -r jenkins@f1.y:$sz_server_path/$sz_ota_file $sz_local_path
        if [ $? -eq 0 ];then
            echo "scp $sz_ota_file successful ..."
        else
            _echo "scp fail ..."
            return 1
        fi
    else
        _echo "it is not on the yunovo server, please check it !"
        return 1
    fi
}

function remove_f1_otafs()
{
    local ip=f1.y
    local portN=22
    local hostN=jenkins
    local ota_path=/public/jenkins/jenkins_share_20T/otafs

    ssh -t -p $portN $hostN@$ip "
        rm $ota_path/*
    "
}

function make-inc
{
    if [ $# -eq 2 ];then

        if [ "`is_yunovo_project`" == "true" ];then
            __echo "make inc start ..."
        else
            __echo "please checkout your dirictory in xxx/androd/* "
            return 1
        fi
    else
        echo
        echo "------------------------------------------"
        echo "e.g : make-inc xxx.04.zip xxx.05.zip"
        echo "------------------------------------------"
        echo
        return 1
    fi

    local ota_py=./build/tools/releasetools/ota_from_target_files
    local ota_previous=$1
    local ota_current=$2
    local hardware_version=H3.1
    local ota_path=/home/jenkins/workspace/otafs
    local software_version=$ota_to_version && software_version=${software_version##*_} && software_version=${software_version%%.*}
    local custom_project=$ota_previous && custom_project=${custom_project%.*} && custom_project=${custom_project%.*} && custom_project=${custom_project##*.}
    local custom_version=$ota_previous && custom_version=${custom_version%%_*}
    local firmware_prev_version=$ota_previous && firmware_prev_version=${firmware_prev_version%.*} && firmware_prev_version=${firmware_prev_version##*.}
    local firmware_curr_version=$ota_current && firmware_curr_version=${firmware_curr_version%.*} && firmware_curr_version=${firmware_curr_version##*.}
    local OTA_FILE=${custom_project}\_${custom_version}\_${hardware_version}\_${software_version}.${firmware_curr_version}\_for\_${software_version}.${firmware_prev_version}.zip

    local ota_local_path=~/OTA
    local ota_server_path=/home/share/jenkins_share
    local ota_version_path=$ota_local_path/$custom_project/${custom_project}\_${custom_version}/${software_version}.${firmware_curr_version}\_for\_${software_version}.${firmware_prev_version}
    local is_sync=false

if false;then
    echo "ota_previous = $ota_previous"
    echo "ota_current = $ota_current"
    echo "custom_project = $custom_project"
    echo "custom_version = $custom_version"
    echo "software_version = $software_version"
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

    ### 1.从f1服务器复制文件到　编译服务器上
    if [ "$ota_previous" ];then
        cpfs $ota_previous
    else
        _echo "ota_previous is null, please check it !"
        return 1
    fi

    if [ "$ota_current" ];then
        cpfs $ota_current
        echo
    else
        _echo "ota_current is null, please check it !"
    fi

    ### 2.编译OTA包存放指定路径
    if [ -e $ota_py -a "`is_yunovo_project`" == "true" -a -f $ota_path/$ota_previous -a -f $ota_path/$ota_current ];then
        $ota_py -i $ota_path/$ota_previous $ota_path/$ota_current $ota_version_path/$OTA_FILE

        if [ -d $ota_version_path ];then
            echo
            cp -vf $ota_path/$ota_previous $ota_version_path
            cp -vf $ota_path/$ota_current $ota_version_path
            echo
        fi
    fi

    ### 3.将生产的OTA包和targer包备份至f1服务器上
    if [ "`is_yunovo_project`" == "true" -a "`is_yunovo_server`" == "true" ];then
        sync_ota_server
        if [ $? -eq 0 ];then
            is_sync=true
            rm $ota_local_path/* -r
            rm $ota_path/*
        else
            _echo "sync_ota_server fail !"
            return 1
        fi
    else
        _echo "please checkout your direction and your server name !"
        return 1
    fi

    ### 4.清空 f1 服务器 otafs 下所有文件
    if [ "$is_sync" == "true" ];then
        #remove_f1_otafs
        :
    fi

    __echo "make inc end ..."
}

function main()
{
    if [ "`is_yunovo_server`" == "true" ];then
        :
    else
        echo "current directory is not android !"
        return 1
    fi

    if [ "`is_yunovo_project`" == "true" ];then
        :
    else
        _echo "currect server is not on yunovo server, please check it !"
        return 1
    fi

    if [ "$ota_from_version" -a "$ota_to_version" ];then
        handler_variable $ota_from_version $ota_from_version
    else
        _echo "xargs is error ,please checkout xargs ."
        return 1
    fi

    make-inc $ota_from_version $ota_to_version
}

main
