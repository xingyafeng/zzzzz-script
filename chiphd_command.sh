#!/bin/bash

####################################################### define
### project name
eastaeon51=eastaeon5.1-mt6735m

sdate=$td

yunovo_root=~/yunovocode
sz_eastaeon=$yunovo_root/$eastaeon51/android
jenkins_path=/home/work5/jenkins
share_path=~/workspace/share_jenkins

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
	cd $share_path
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
