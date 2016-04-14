#!/bin/bash

####################################################### define
### project name

sdate=$td
sz_yunovo=/home/yafeng/yunovo

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

function cyunovo()
{
	cd $sz_yunovo
}

function cworkspace
{
	cd $workspace
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
