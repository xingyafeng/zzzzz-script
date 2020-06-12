#!/usr/bin/env bash

#####################################################################
#
#                  帮助文档
#
# 说明: 在ubuntu系统中，执行 cat tools/init >> ~/.bashrc 命令后
#       每次开机系统，或者打开终端事，系统自动将script脚本导入
#       环境中，执行成功就可以使用啦.
#       $ help--script 查看快捷命令
#
#       e.g :
#           1 cscript
#           2 show_vip
#           3 grepfs gfind
#           4 setgitconfig
#           5 get_file_name
#           6 get_file_type
#
#       以上只是其中部分，有需要可以句需求封装，为了高效率的工作。
#
#
#####################################################################

# script help
function help--script()
{
    echo
	show_vig "## help--script ## version is [$THIS_SCRIPT_VERSION]"
cat <<EOF
functions from zzzzz-script , down: git clone ssh://xingyafeng@gerrit-in.yunovo.cn:29419/xyf/zzzzz-script

    open terminal auto source

    - grepfs                Greps on all local .c .cc .cpp .h .java .xml .sh .mk .cfg Kconfig  .sh files.
    - gfind                 find on all local
    - openfs                open file folder
    - geditfs               open file run backgroud
    - recover_android       clean all customs file

    @@@ get
    - get_week              Calculate the day of the month in a certain year
    - get_file_name         Get the name of the file and remove the suffix
    - get_file_type         Get the type and suffix of the file
    - get_modify_file       Get the name of the project modified in the repo project
    - get_package_name      Get the information in the APK file containing the package name and other

    @@@ set
    - setgitconfig          set gitconfig list

    @@@
    - showfile:             e.g. showfile FileName 20 30   -- show the 20th to 30th lines of the "FileName" file.

    @@@
    - cgrep                 Greps on all local C/C++ files.
    - ggrep                 Greps on all local Gradle files.
    - jgrep                 Greps on all local Java files.
    - resgrep               Greps on all local res/*.xml files.
    - mangrep               Greps on all local AndroidManifest.xml files.
    - mgrep                 Greps on all local Makefiles files.
    - sepgrep               Greps on all local sepolicy files.
    - sgrep                 Greps on all local source files.

    ------------------------

    adb-tips, just show for copy to cmd windows:
    adb reboot                                              -- reboot
    adb install -r [apk]                                    -- install apk
    adb uninstall  [apk]                                    -- uninstall apk
    adb pull  /system/vendor/modules/                       -- pull .ko file
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

    -----------------------
    @@@ cmd for simple

    - ssh-set-permission      -- set .ssh/* chmod
    - ssh-update-script       -- update the zzzzz-script on server
    - ssh-jenkins             -- login jenkins
    - ssh-gerrit              -- login gerrit

    -----------------------
    @@@
    - make_idegen               -- android studio config
    - auto_make_key             -- create android key

    @@@ print
    -  __echo
    -  __debug
    -  __msg
    -  __wrn
    -  __err

    @@@ show
    - show_vibk
    - show_vir
    - show_vig
    - show_viy
    - show_vib
    - show_vip
    - show_vidg
    - show_viw

    @@@ __color__
    - __red__
    - __green__
    - __yellow__
    - __black__
    - __black__
    - __black__
    - __black__
    - __black__
    - __black__

    ----------------------
    e.g. am start -n com.android.settings/com.android.settings.Settings     ---- open setting.apk
         am start -a android.intent.action.VIEW -d http://www.sohu.com      ---- open http://www.sohu.com

EOF
}
