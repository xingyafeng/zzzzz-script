#!/bin/bash

### make all project
function make-android
{
	if [ "`is_make_project`" = "true" ];then
		show-make-project		
		if lunch-chiphd;then 
			make_android $1
		fi	
	fi
}

### 是否是需要编译的工程
function is_make_project
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}
	
	if [ $thisPath = $eagle44 -o $thisPath = $dolphin44 -o $thisPath = $debug44 ];then
		echo true
	else
		echo false
	fi
}

### make android
function make_android
{
	local ret=$1
	case $ret in
	###不执行pack 动作
	-p)
		make-project $ret
	;;

	*)
		thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}
		make-project $1
	;;
	esac
}

make-project()
{
	if make installclean;then
		show_vip "--> installclean end."
		if extract-bsp;then
			show_vip "--> bsp end."
			if make -j32;then
				show_vip "--> make project end."
				if [ "$1" = "-p" ];then
					show_vip "--------------------------"
					show_vip "-        make end        -"
					show_vip "--------------------------"
				else		
					if pack;then
						show_vip "--> pack finish."
						if [ "$1" = "-t" ];then
							make-target
						elif [ "$1" = "-i" ];then
							make-inc
						fi
					fi
				fi	
			fi
		fi
	fi
}

#### show printf
show-make-project()
{
	show_vir "###################################################"
	show_vir "#  make rebuilder project  ... for $thisPath  #"
	show_vir "###################################################"
	echo 
}

show-lunch()
{
	echo "---------------------------------"
	show_vip "--> lunch $thisPath"
	echo
}

### source && lunch 
function lunch-chiphd
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}	

	source build/envsetup.sh
	
	case $thisPath in
	
	$debug44)
		lunch eagle_fvd_p1-eng
	;;

	$eagle44)
		lunch eagle_fvd_p1-eng
	;;
	
	$dolphin44)
		lunch dolphin_fvd_p1-eng
	;;

	*)
		show_vir "-------------do not choose lunch--------------"
	;;
	esac
	
	if [ $thisPath = $eagle44 -o $thisPath = $dolphin44 -o $thisPath = $debug44 ];then
		show-lunch
	else
		show_vir "please your must go to the android root directory ..."
	fi
}

########################################################## mmm modules
### common path
path_framework=frameworks/base
path_policy=frameworks/base/policy
path_systemui=frameworks/base/packages/SystemUI
path_launcher2=packages/apps/Launcher2
path_settings=packages/apps/Settings

### h8 h3
path_tvdsettings=vendor/tvd/packages/TvdSettings

show-make-app()
{
	show_vir "######################################"
	show_vir "#  make app  ... for $thisPath  #"
	show_vir "######################################"
}

make-app()
{
	touch * && mm -B
}

make_framework()
{
	touch  $path_framework *
	mmm -B $path_framework -j32
}

make-framework()
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}
	
	case $thisPath in
	$test44)
		show-make-app
		make_framework
		show_vip "#############################"
		show_vip "#   --> make framework end  #"
		show_vip "#############################"
	;;

	*)
		show-make-app	
		make_framework
		show_vip "#############################"
		show_vip "#   --> make framework end  #"
		show_vip "#############################"
	;;
	esac
}

make_policy()
{
	touch  $path_policy *
	mmm -B $path_policy -j32
}

make-policy()
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}
	
	case $thisPath in
	$test44)
		show-make-app
		make_policy
		show_vip "###########################"
		show_vip "#   --> make policy end   #"
		show_vip "###########################"
	;;
	*)
		show-make-app
		make_policy
		show_vip "###########################"
		show_vip "#   --> make policy end   #"
		show_vip "###########################"
		
	;;
	esac	
}

make_systemui()
{
	touch  $path_systemui *
	mmm -B $path_systemui -j32
}

make-systemui()
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}
	
	case $thisPath in
	$test44)
		show-make-app
		make_systemui
		show_vip "#############################"
		show_vip "#   --> make systemui end   #"
		show_vip "#############################"
	;;
	*)
		show-make-app
		make_systemui
		show_vip "#############################"
		show_vip "#   --> make systemui end   #"
		show_vip "#############################"
	;;
	esac

}

make_launcher2()
{
	touch  $path_launcher2 *
	mmm -B $path_launcher2 -j32
}

make-launcher2()
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}
	
	case $thisPath in
	$test44)
		show-make-app
		make_launcher2
		show_vip "#############################"
		show_vip "#   --> make launcher2 end  #"
		show_vip "#############################"
	;;
	*)
		show-make-app
		make_launcher2
		show_vip "#############################"
		show_vip "#   --> make launcher2 end  #"
		show_vip "#############################"
	;;
	esac
}

make_tvdsettings()
{
	touch $path_tvdsettings *
	mmm -B $path_tvdsettings -j32
}

make-tvdsettings()
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}
	
	case $thisPath in
	$test44)
		show-make-app
		make_tvdsettings	
		show_vip "################################"
		show_vip "#   --> make tvdsettings end   #"
		show_vip "################################"
	;;
	
	*)
		show-make-app
		make_tvdsettings
		show_vip "################################"
		show_vip "#   --> make tvdsettings end   #"
		show_vip "################################"
	;;
	esac
}

make_settings()
{
	touch  $path_settings *
	mmm -B $path_settings -j32
}

make-settings()
{
	thisPath=$(pwd) && thisPath=${thisPath%/*} && thisPath=${thisPath##*/}
	
	case $thisPath in
	$test44)
		show-make-app
		make-settings
		show_vip "#############################"
		show_vip "#   --> make settings end   #"
		show_vip "#############################"
	;;

	*)
		show-make-app
		make_settings
		show_vip "#############################"
		show_vip "#   --> make settings end   #"
		show_vip "#############################"
	;;
	esac
}
