#!/bin/bash

### define
devices_tvdsettings=TvdSettings.apk
devices_systemui=SystemUI.apk
devices_launcher=Launcher2.apk
devices_framework_res=framework-res.apk
devices_framework=framework.jar
devices_services=services.jar
devices_policy=android.policy.jar

devices_prop=build.prop
devices_sun6i_kl=sun6i-ir.kl
devices_sun7i_kl=sun7i-ir.kl

###adb common
function adb-connect
{
	adb-kill-server
	if [ -z $1 ];then
		adb connect 192.168.2.86
	else
		adb connect 192.168.2.$1
	fi
	sleep 1s
	adb-remount
}



function adb-chmod
{
    local ret=$1
    
    case $ret in
    $devices_prop)
        adb shell chmod 644 system/$ret
    ;;

    $device_sun6i_kl)
		adb shell chmod 644 system/usr/keylayout/$ret
	;;

	$devices_sun7i_kl)
		adb shell chmod 644 system/usr/keylayout/$ret
	;;

	*)
        if [ "`echo $ret | grep ko 2>/dev/null`" ];then
            adb shell chmod 644 vendor/modules/$ret
        fi
    ;;
    esac
    show_vip "--------chmod" " $ret"
    adb shell sync
}

adb-push-app()
{
	if [ "$DEVICE" ];then
		cout
	fi

	local ret=$1		
    if adb-remount;then
		if [ "$2" = "-p" ];then
			show_vip "---adb push priv-app"
			adb push system/priv-app/$ret system/priv-app
		else
        	adb push system/app/$ret system/app
		fi	
		if [ $? -eq 0 ];then
			case $ret in 
			$devices_tvdsettings)
				sleep 3s
				adb shell am start -n com.android.settings/com.android.settings.Settings
			;;
			$devices_systemui)
				adb-reboot
			;;
			$devices_launcher)
				adb-reboot
			;;
			esac
		fi	
    fi	
}

adb-pull-app()
{
	local app_name=$1
	
	if [ "$app_name" ];then
		if adb-remount;then
			adb pull system/app/$app_name $td
		fi
	fi	
}

adb-push-framework()
{
	local jar_file=$1

	if [ ! "$jar_file" ];then
		return	
	fi
	
	if adb-remount;then
		adb push system/framework/$jar_file system/framework
		if [ $? -eq 0 ];then
			adb shell sync
			adb-reboot
		fi
	fi
}

adb-pull-framework()
{
	local jar_file=$1

	if [ ! "$jar_file" ];then
		return	
	fi

  	if adb-remount;then
  		adb pull system/framework/$jar_file $td	
	fi
}

adb-push-prop()
{
	local prop_file=$1

    if adb-remount;then
        adb push $prop_file system/
        if [ $? -eq 0 ];then
            if adb-chmod $prop_file;then
				adb shell sync
                adb-reboot
            fi     
        fi
    fi
}

adb-pull-prop()
{
	local device_prop=build.prop
	
	if adb-remount;then	
    	adb pull system/$device_prop $td
	fi
}

adb-push-sunxi-kl()
{
	local sunxi_kl=$1

	if adb-remount;then
		adb push $sunxi_kl system/usr/keylayout/
		adb-chmod $sunxi_kl
		adb shell sync
		adb-reboot
	fi
}

adb-pull-sunxi-kl()
{
	local sunxi_kl=$1
	
	if adb-remount;then
		adb pull system/usr/keylayout/$sunxi_kl $td
	fi
}

adb-push-ko()
{
	local linux_ko=$1	
	
	if adb-remount;then
		adb push $linux_ko system/vendor/modules/
		adb-chmod $linux_ko
		adb-reboot
	fi
}

function adb-pull-ko
{
	local linux_ko=$1

	if adb-remount;then
		adb pull system/vendor/modules/$linux_ko $td
	fi
}

function adb-devices
{
	adb devices
}

function adb-kill-server
{
	adb kill-server
}

function adb-start-server
{
	adb start-server
}

function adb-shell
{
	adb shell
}

function adb-remount
{
	adb remount
}

function adb-reboot
{
	show_vip --------reboot
	adb reboot
}

