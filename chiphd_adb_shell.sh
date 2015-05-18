#!/bin/bash

### define
devices_tvdsettings=TvdSettings.apk
devices_systemui=SystemUI.apk
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
	if [ -z $1 ];then
		adb connect 192.168.2.86
	else
		adb connect 192.168.2.$1
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
			esac
		fi	
    fi	
}

adb-pull-app()
{
	adb pull system/app/$1 $td
}

adb-push-framework()
{
	if adb-remount;then
		adb push system/framework/$1 system/framework
		if [ $? -eq 0 ];then
			adb-reboot
		fi
	fi
}

adb-pull-framework()
{
    adb pull system/framework/$1 $td	
}

adb-push-prop()
{
    if adb-remount;then
        adb push $1 system/
        if [ $? -eq 0 ];then
            if adb-chmod $1;then
                adb-reboot
            fi     
        fi
    fi
}

adb-pull-prop()
{
    adb pull system/$devices_prop $td
}

adb-push-sunxi-kl()
{
	if adb-remount;then
		adb push $1 system/usr/keylayout/
		adb-chmod $1
		adb shell sync
		adb-reboot
	fi
}

adb-push-ko()
{
	if adb-remount;then
		adb push $1 system/vendor/modules/
		adb-chmod $1
		adb-reboot
	fi
}
