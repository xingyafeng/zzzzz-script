#!/usr/bin/env bash

### unzip apks lib
function unzip_apks_libs()
{
	local _thisApkFNamg="" ##apk name without .apk
	local _thisApkHasLibs=false

	for f in *.apk
	do
		_thisApkFNamg="${f/%.apk/}"
		if [ "`$MyAAPT dump badging $f | sed -n '/^native.code/'p`" ]; then
			_thisApkHasLibs=true
		else
			_thisApkHasLibs=false
		fi

		if [ $_thisApkHasLibs == true ]; then
			echo "unzip $f, doing..."
			unzip -qq -j $f `unzip -l $f | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}'` -d ./$_thisApkFNamg
		fi
	done
}

### 自动创建android.mk
function auto_create_android_mk()
{
    local android_mk_file_name=Android.mk
    local armeabi_so=armeabi
    local armeabi_v7a_so=armeabi-v7a
    local curr_apk_name=$1

    local jni_lib="LOCAL_PREBUILT_JNI_LIBS := \\"
    local privileged_module="LOCAL_PRIVILEGED_MODULE := true"
    local build_prebuild="include \$(BUILD_PREBUILT)"

    if [ $# -eq 1 ];then
        echo
        show_vir "auto create android.mk start ..."
        echo
        echo "curr_apk_name = $curr_apk_name"
        echo
    else
        echo
        show_vir "Please e.g auto_create_android_mk  xxx.apk ..."
        return 1
    fi
    (cat << EOF) > ./$android_mk_file_name
LOCAL_PATH := \$(call my-dir)

EOF
    if [ "$curr_apk_name" ];then
        curr_apk_name="${curr_apk_name/%.apk/}"
    else
        retrun 1
    fi

    (cat << EOF) >> ./$android_mk_file_name

include \$(CLEAR_VARS)
LOCAL_MODULE := $curr_apk_name
LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_MODULE_CLASS := APPS
LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_MULTILIB := 32

EOF
    if [ "`unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi-v7a\/.*.so$/ {print $(NF)}'`" ];then
        unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi-v7a\/.*.so$/ {print $(NF)}' > $td/${armeabi_v7a_so}.txt
    elif [ "`unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}'`" ];then
        unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}' > $td/${armeabi_so}.txt
    fi

    if [ -f $td/${armeabi_v7a_so}.txt ];then
        echo $jni_lib >> ./$android_mk_file_name
        while read lib_path;do
            echo "    @$lib_path \\" >> ./$android_mk_file_name
            echo "$lib_path"
        done < $td/${armeabi_v7a_so}.txt

        echo >> ./$android_mk_file_name
        echo $privileged_module >> ./$android_mk_file_name
        echo $build_prebuild >> ./$android_mk_file_name

        rm $td/${armeabi_v7a_so}.txt
    fi

    if [ -f $td/${armeabi_so}.txt ];then

        echo $jni_lib >> ./$android_mk_file_name

        while read lib_path;do
            echo "    @$lib_path \\" >> ./$android_mk_file_name
            echo "$lib_path"
        done < $td/${armeabi_so}.txt

        echo >> ./$android_mk_file_name
        echo $privileged_module >> ./$android_mk_file_name
        echo $build_prebuild >> ./$android_mk_file_name

        rm $td/${armeabi_so}.txt
    fi

    echo
    show_vir "auto create android.mk end ..."
    echo
}