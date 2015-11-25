###########################################################
###
###				tools functions
###
###	
### date 	: 2013-12-05 19:55
### author  : yafeng
###
###########################################################

#!/bin/bash

### color red
function show_vir
{
	if [ "$1" ]
	then
	#	echo "---------------------"
		for ret in "$@"; do
			echo -e -n "\e[1;31m$ret \e[0m"
		done
		echo
	fi
}

### color green 
function show_vig
{
	if [ "$1" ]
	then
	#	echo "---------------------"
		for ret in "$@"; do
			echo -e -n "\e[1;32m$ret \e[0m"
		done
		echo
	fi
}

### color yellow 
function show_viy
{
	if [ "$1" ]
	then
	#	echo "---------------------"
		for ret in "$@"; do
			echo -e -n "\e[1;33m$ret \e[0m"
		done
		echo
	fi
}

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

### color dark green 
function show_vid
{
	if [ "$1" ]
	then
	#	echo "---------------------"
		for ret in "$@"; do
			echo -e -n "\e[1;36m$ret \e[0m"
		done
		echo
	fi
}


### debug
function __msg
{
	[ "$__dbg" == "on" ] && $@ || :
}

function csoftwinner
{
	local T	
	T=$(gettop)
	cd "$T/device/softwinner"
	#show_vig $T
}

function crooooooot
{
	cdevice && croot
}

###########################
#### 	file EOF		###
###########################
