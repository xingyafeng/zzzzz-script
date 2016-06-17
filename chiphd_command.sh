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
	cd $sz_eastaeon
}

function cyunovo()
{
	cd $yunovo_root
}

function cworkspace
{
	cd $workspace
}

function cjenkins
{
	cd $jenkins_path
}

function cshare
{
    if [ -d $share_path ];then
	    cd $share_path
    else
        show_vir " $share_path is no found !"
    fi
}

function cscript
{
	cd $script_path
}

function cdate
{
	cd $sdate
}

function crsync
{
	cd $rsync_path
}

function cs1.y()
{
    cd $s1_path
}

function cs2.y()
{
    cd $s2_path
}

function cs3.y()
{
    cd $s3_path
}

function cs4.y()
{
    cd $s4_path
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

    cd $sz_project_path
}
