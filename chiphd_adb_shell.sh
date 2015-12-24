#!/bin/bash

### define
devices_tvdsettings=TvdSettings.apk
devices_systemui=SystemUI.apk
devices_launcher=Launcher2.apk
devices_browser=Browser.apk
devices_framework_res=framework-res.apk
devices_framework=framework.jar
devices_services=services.jar
devices_policy=android.policy.jar

devices_prop=build.prop
devices_sunxi_kl=sunxi-ir.kl
devices_device=device
devices_host=host

###adb common
function adb-connect
{
	local ip_addr=$1
	adb-kill-server
	if [ -z $ip_addr ];then
		adb connect 192.168.2.86
	else
		adb connect 192.168.$ip_addr
	fi
	sleep 1s
	adb-remount
}

function debug-mask
{
	local ip_addr=$1

	if [ "$ip_addr" ];then
		adb-connect $ip_addr
		adb shell "echo 0xff > /sys/module/sunxi_ir_rx/parameters/debug_mask"
		adb shell "dumpsys input | grep \".kl\""
	else
		show_vir "eg: debug-mask + ip"
	fi
}

function change-mode
{
	local usb_mode=$1
    local ip_addr=$2    

    if [ "$ip_addr" ];then
        adb-connect $ip_addr            
    fi    

	if [ $usb_mode == "$devices_device" ];then
		adb shell cat sys/bus/platform/devices/sunxi_usb_udc/usb_device
	elif [ $usb_mode == "$devices_host" ];then
		adb shell cat /sys/bus/platform/devices/sunxi_usb_udc/usb_host
    else
        show_vir "eg: change-mode + $devices_host + ip"
    fi
}

function adb-chmod
{
    local ret=$1
    
    case $ret in
    $devices_prop)
        adb shell chmod 644 system/$ret
    ;;

	$devices_sunxi_kl)
		adb shell chmod 644 system/usr/keylayout/$ret	
	;;

	*)
        if [ "`echo $ret | grep ko 2>/dev/null`" ];then
            adb shell chmod 644 vendor/modules/$ret
        fi

		if [ "`echo $ret | grep customer_ir_ 2>/dev/null`" ];then
			adb shell chmod 644 system/usr/keylayout/$ret		
		fi
    ;;
    esac
    show_vip "--------chmod" " $ret"
    adb shell sync
}

function is_system_app()
{
	local ret=$1	
	local system_app=`echo $devices_tvdsettings $devices_launcher $devices_browser`
	if [ ! "$ret" ];then
		return
	fi

	if [ "$system_app" == "$ret" ];then
		echo true		
	else
		echo false		
	fi
}

function is_priv_app()
{
	local ret=$1	
	local priv_app=`echo $devices_systemui`

	if [ ! "$ret" ];then
		return
	fi

	if [ "$priv_app" == "$ret" ];then
		echo true		
	else
		echo false		
	fi
}

function adb-push-app()
{
	local old_path=`pwd`

	if [ "$DEVICE" ];then
		cout
	fi

	local ret=$1
    if adb-remount;then
		if [ "`is_priv_app $ret`" == "true" ];then
			show_vip  "--- push priv-app"	
			adb push system/priv-app/$ret system/priv-app
		elif [ "`is_system_app $ret`" == "true" ];then
			show_vip  "--- push system app"	
        	adb push system/app/$ret system/app
		fi	

		if [ $? -eq 0 ];then
			case $ret in 
			$devices_tvdsettings)
				sleep 3s
				adb shell am start -n com.android.settings/com.android.settings.Settings
			;;

            $devices_browser)
				sleep 3s
				adb shell am start -n com.android.browser/com.android.browser.BrowserActivity
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

	cd $old_path
}

adb-pull-app()
{
	local app_name=$1
	
	if [ "$app_name" ];then
		if adb-remount;then
			adb pull system/app/$app_name $td
		fi
	else
		return
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
	local old_path=`pwd`

	if [ "$DEVICE" ];then
		cout
	fi

	if [ ! "$sunxi_kl" ];then
		break;	
	fi

	if adb-remount;then
		adb push system/usr/keylayout/$sunxi_kl system/usr/keylayout/
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

