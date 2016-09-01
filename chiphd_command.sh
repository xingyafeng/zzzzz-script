#!/bin/bash

####################################################### define

### define common
da=$workspace/date
time_date=`date +%m%d`
td=$da/$time_date

### project name
eastaeonP=eastaeon5.1-mt6735m

### project name for yunovo
k26P=k26
k26sP=k26s
k27P=k27
k86aP=k86a
k86mP=k86m
k86mx2P=k86mx2
k86sP=k86s
k86smP=k86sm
k86lP=k86l
k86lsP=k86ls
k88cP=k88c
k88sP=k88s
k86ldP=k86ld

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
k88sPR=k88s_root
k86ldPR=k86ld_root
sdate=$td

yunovo_root=~/yunovocode
sz_eastaeon=$yunovo_root/$eastaeon51/android
jenkins_path=/home/work5/jenkins

### share for server path
s1_share_path=/home/jenkins/workspace/share
s2_share_path=/home/jenkins/workspace/share
s3_share_path=/home/work5/public/share
s4_share_path=/home/share/jenkins_share
f1_share_path=/public/jenkins/jenkins_share_20T


s1_path=~/jobs/k26/android
s2_path=~/jobs/k86s/android
s3_path=~/jobs/k86a/android
s4_path=~/jobs/k86l/android

### args
pro_name=
pro_type=
################################################### function
### shortcut for cd

## tools bcompare
function bcompare()
{
	OLD_PWD=`pwd`
	echo $OLD_PWD
	cd ~/bin/ > /dev/null

	if [ -x bcompare ];then
		./bcompare &
	fi
	cd $OLD_PWD > /dev/null
}

function ceastaeon()
{
    if [ -d $sz_eastaeon ];then
	    cd $sz_eastaeon
    else
        show_vir " $sz_eastaeon not found !"
        return 1
    fi
}

function cyunovo()
{
    if [ -d $yunovo_root ];then
	    cd $yunovo_root
    else
        show_vir " $yunovo_root not found !"
        return 1
    fi
}

function cworkspace
{
    if [ -d $workspace ];then
	    cd $workspace
    else
        show_vir " $workspace mot found !"
        return 1
    fi
}

function cjenkins
{
    if [ -d $jenkins_paths ];then
	    cd $jenkins_path
    else
        show_vir " $jenkins_path not found !"
        return 1
    fi

}

function cshare
{
    local hostN=`hostname`

    case $hostN in
    s1)
        if [ -d $s1_share_path ];then
            cd $s1_share_path
        else
            show_vir "$s1_share_path not found !"
            return 1
        fi
        ;;
    s2)
        if [ -d $s2_share_path ];then
            cd $s2_share_path
        else
            show_vir "$s2_share_path not found !"
            return 1
        fi
        ;;
    s3)
        if [ -d $s3_share_path ];then
            cd $s3_share_path
        else
            show_vir "$s3_share_path not found !"
            return 1
        fi

        ;;
    s4)
        if [ -d $s4_share_path ];then
            cd $s4_share_path
        else
            show_vir "$s4_share_path not found !"
            return 1
        fi

        ;;
    f1)
        if [ -d $f1_share_path ];then
            cd $f1_share_path
        else
            show_vir "$f1_share_path not found !"
            return 1
        fi

        ;;

    *)
        show_vir "it do not match anythings !"
        return 1
        ;;
    esac
}

function cscript
{
    if [ -d $script_path ];then
	    cd $script_path
    else
        show_vir " $script_path not found !"
        return 1
    fi
}

function cdate
{
    if [ -d $sdate ];then
	    cd $sdate
    else
        show_vir " $sdate not found !"
        return 1
    fi
}

function crsync
{
    if [ -d $rsync_path ];then
	    cd $rsync_path
    else
        show_vir " $rsync_path not found !"
        return 1
    fi
}

function cs1.y()
{
    if [ -d $s1_path ];then
        cd $s1_path
    else
        show_vir " $s1_path not found !"
        return 1
    fi
}

function cs2.y()
{
    if [ -d $s2_path ];then
        cd $s2_path
    else
        show_vir " $s2_path not found !"
        return 1
    fi
}

function cs3.y()
{
    if [ -d $s3_path ];then
        cd $s3_path
    else
        show_vir " $s3_path not found !"
        return 1
    fi
}

function cs4.y()
{
    if [ -d $s4_path ];then
        cd $s4_path
    else
        show_vir " $s4_path not found !"
        return 1
    fi
}

function ctoms()
{
    local sz_hostname=`hostname`
    local sz_project_path=
    local sz_project=

    if [ $sz_hostname == "s1" ];then
        sz_project=k26
    elif [ $sz_hostname == "s2" ];then
        sz_project=k86s
    elif [ $sz_hostname == "s3" ];then
        sz_project=k86a
    elif [ $sz_hostname == "s4" ];then
        sz_project=k86l
    fi

    sz_project_path=~/jobs/$sz_project/yunovo_customs/custom

    if [ -d $sz_project_path ];then
        cd $sz_project_path
    else
        show_vir " $sz_project_path not found !"
        return 1
    fi
}
