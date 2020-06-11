#!/bin/bash

function help--script()
{
    echo
	show_vig "## help--script ## version is [$THIS_SCRIPT_VERSION]"
cat <<EOF
functions from zzzzz-script , down: git clone ssh://xingyafeng@gerrit-in.yunovo.cn:29419/xyf/zzzzz-script

    open terminal auto source

    - gfind                 find on all local
    - grepfs                Greps on all local .c .cc .cpp .h .java .xml .sh .mk .cfg Kconfig  .sh files.
    - openfs                open file folder
    - rsyncfs               rsync file and folder
    - geditfs               open file run backgroud
    - renamefs              rename photo FileName
    - recover_android       clean all customs file
    - change_ps             set .ssh and set .repo
    - change_mode           set usb mode  devices or host
    - H-to-D H-to-H
    - B-to-D D-to-B

    @@@ get
    - get_week              Calculate the day of the month in a certain year
    - get_file_name         Get the name of the file and remove the suffix
    - get_file_type         Get the type and suffix of the file
    - get_modify_file       Get the name of the project modified in the repo project
    - get_package_name      Get the information in the APK file containing the package name and other

    @@@ set
    - setgitconfig          set gitconfig list
    - set_ssh_permission    set .ssh/* chmod

    @@@
    - showfile:             e.g. showfile FileName 20 30   -- show the 20th to 30th lines of the "FileName" file.

    @@@@
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

    - ssh-update-script
    - ssh-jenkins
    - ssh-gerrit

    -----------------------
    @@@
    cpotafs                                                 -- cp otf files to path
    make_idegen                                             -- android studio config
    auto_make_key                                           -- create android key
    copy_image_to_folder                                    -- cp img to release path

    -----------------------
    @@@ sshfs
    ls-server
    sshfs-server
    fusermount-server

    ----------------------
    e.g. am start -n com.android.settings/com.android.settings.Settings     ---- open setting.apk
         am start -a android.intent.action.VIEW -d http://www.sohu.com      ---- open http://www.sohu.com

EOF
}
