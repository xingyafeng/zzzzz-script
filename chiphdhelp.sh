#!/bin/bash

function script-help()
{
	show_vir "        script version [$THIS_SCRIPT_VERSION]"
	echo
cat <<EOF
	functions from /a/0ps/zzzzz-script , down: git clone ssh://git@192.168.1.20//home/git/chiphd_devices/box/zzzzz-script.git
	open terminal auto source

	- lunch-chiphd          source android project and you select eagle dolphin.
	- make-android          build android project.
	- make-lichee           build android project.
	- make-uboot            buold uboot and boot0
	- gfind                 find on all local  
	- grepfs                Greps on all local .c .cc .cpp .h .java .xml .sh .mk .cfg Kconfig  .sh files.
	- openfs                open file folder
	- rsyncfs               rsync file and folder 
	- geditfs               open file run backgroud
	- renamefs              rename photo FileName
	- recover_sdk           clean all customs file
	- get_modify_file       get project all customs file
	- get_package_name      get apk packageName and className
	- setgitconfig          set git --list
	- change_ps             set .ssh and set .repo
	- change_mode           set usb mode  devices or host
	- debug_mask            set net debug and ir debug
	- mount-server          mount server boxbuilder and other
	- showfile:             e.g. showfile FileName 20 30   -- show the 20th to 30th lines of the "FileName" file.

	------------------------
	adb-tips, just show for copy to cmd windows:
	adb reboot                                              -- reboot
	adb install [apk]                                       -- install apk
	adb pull /system/vendor/modules/                        -- pull .ko file
	adb push  /system/vendor/modules                        -- push .ko file
	adb push  /system/etc/permissions                       -- push permission file
	adb push  /system/etc                                   -- push some cfg file
	adb shell cat /proc/kmsg                                -- print kernel debug info
	     	  cat /proc/meminfo                             -- print meminfo
	      	  cat /proc/cpuinfo                             -- print cpuinfo
	          cat /proc/version                             -- print version
	adb shell input text "xw26614116888"                    -- input text
	adb shell input keyevent 7                              -- input key (7:KEYCODE_0, 29:KEYCODE_A)
	adb shell getevent                                      -- get event
	adb shell sendevent [device] [type] [code] [value]      -- send event
	adb shell am start -n [packageName/className] -a [action] -d [data] -m [MIME-TYPE] -c [category] -e [ext-data]
	
	e.g. am start -n com.android.settings/com.android.settings.Settings     ---- open setting.apk
	     am start -a android.intent.action.VIEW -d http://www.sohu.com      ---- open http://www.sohu.com

EOF
}
