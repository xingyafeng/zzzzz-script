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
#	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}	
	local lichee_name=lichee

	if [ ! -z $thisPath ];then
		show_ui $lichee_name $thisPath
	else
		show_vir  thisPath is null!	
	fi

	if [ "`is_make_project`" = "true" ];then
		### 判断pro_name 是否已经选择对应的平台	
		if [ -z $pro_name ];then	
			show_vir "请按照下面提示输入对应的编译平台: dolphin 和 eagle" 
			show_vir "-----------------------------------------------"
			echo -n "Please follow the tips below input " && show_vig dolphin or eagle
			read -p "Enter dolphin or eagle :" pro_name

		fi
		show_viy "pro_name = $pro_name"

		echo
		if [ $pro_name = "dolphin" ];then
			thisPath=$dolphin44
		elif [ $pro_name = "eagle" ];then
			thisPath=$eagle44
		fi
	fi

	if [ -e eagle -a -e dolphin ];then
		cd linux-3.4
		make clean
		cd ..
		rm out/ -rf
		rm eagle
		rm dolphin

		show_vir "---------------------------clean"
	fi

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
#	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}

	local uboot_name=u-boot
	local old_pwd=$(pwd)
	local uboot_path=brandy/u-boot-2011.09

	show_ui $uboot_name $thisPath

	if [ "`is_make_project`" = "true" ];then
		show_vir "请按照下面提示输入对应的编译平台: dolphin 和 eagle" 
		show_vir "-----------------------------------------------"
		echo -n "Please follow the tips below input " && show_vig dolphin or eagle
		read -p "Enter dolphin or eagle :" pro_name

		### 创建标志文件
		if [ ! -e $pro_name ];then
			touch $pro_name
			show_vir "--------------------------------touch $pro_name"
		fi

		if [ $pro_name = "dolphin" ];then
			thisPath=$dolphin44
		elif [ $pro_name = "eagle" ];then
			thisPath=$eagle44
		fi
	fi

	cd $uboot_path
	case $thisPath in
	$eagle44)
		if make distclean;then
			show_vir "--> disclean end ..."
			echo
			if make sun8iw6p1_config;then
				show_vir "--> choose sun8iw6p1_config end ..."
				echo
				if make -j32;then
					show_vip "--> make h8 uboot end."
					echo
					if make boot0;then
						show_vip "--> make h8 boot0 end."
					fi
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
