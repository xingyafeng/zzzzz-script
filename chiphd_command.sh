#!/bin/bash

####################################################### define
### project name
eastaeon51=eastaeon5.1-mt6735m

sdate=$td

yunovo_root=~/yunovocode
sz_eastaeon=$yunovo_root/$eastaeon51/android

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
