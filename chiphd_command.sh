#!/bin/bash

####################################################### define

### define common
da=$workspace/date
time_date=`date +%m%d`
td=$da/$time_date

### project name
eastaeon51=eastaeon5.1-mt6735m
k2651=k26
k86a51=k86a
k86s51=k86s
k86l51=k86l

sdate=$td

yunovo_root=~/yunovocode
sz_eastaeon=$yunovo_root/$eastaeon51/android
jenkins_path=/home/work5/jenkins
share_path=/home/share/jenkins_share

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
    if [ -d $share_path ];then
	    cd $share_path
    else
        show_vir " $share_path  not found !"
    fi
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
