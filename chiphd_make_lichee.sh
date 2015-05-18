#!/bin/bash

show_ui()
{
	if [ $1 -a $2 ];then
		show_vip "########################################################"
		show_vip "#     make rebuilder $1 ... for $2    #"
		show_vip "########################################################"
		echo
	fi
}

function make-lichee
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}	
	local pro_name=lichee
	
	show_ui $pro_name $thisPath
	case $thisPath in

    $eagle44)
		if [ -d out ];then
			./build.sh	
		else
			show_vir "please select: sun8iw6p1-android"	
			echo "------------------------------------"
			./build.sh lunch
		fi
	;;

	$debug44)
		if [ -d out ];then
			./build.sh 	
		else
			show_vir "please select: sun8iw6p1-android"	
			echo "------------------------------------"
			./build.sh lunch
		fi
	;;

	$dolphin44)
		if [ -d out ];then
			./build.sh
		else
			show_vir "please select: sun8iw7p1-android"	
			echo "------------------------------------"
			./build.sh lunch
		fi
	;;
	
	*)
		show_vir "do not matching ..."
	;;
	esac
}

function make-uboot
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}

	local pro_name=u-boot
	local old_pwd=$(pwd)
	local uboot_path=brandy/u-boot-2011.09

	show_ui $pro_name $thisPath

	cd $uboot_path
	case $thisPath in
	$eagle44)
		if make distclean;then
			show_vir "--> disclean end ..."
			if make sun8iw6p1_config;then
				show_vir "--> choose sun8iw6p1_config end ..."
				if make -j32;then
					show_vip "--> make h8 uboot end."
				fi
			fi
		fi
	;;
	$debug44)
		if make distclean;then
			show_vir "--> disclean end ..."
			if make sun8iw6p1_config;then
				show_vir "--> choose sun8iw6p1_config end ..."
				if make -j32;then
					show_vip "--> make h8 uboot end."
				fi
			fi
		fi
	;;
	$dolphin44)
		if make distclean;then
			show_vir "--> disclean end ..."
			if make sun8iw7p1_config;then
				show_vir "--> choose sun8iw7p1_config end ..."
				if make -j32;then
					show_vip "--> make h3 uboot end."
				fi
			fi
		fi
	;;
	
	*)
		show_vir "do not matching ..."
	;;
	esac
	
	cd $old_pwd
}
