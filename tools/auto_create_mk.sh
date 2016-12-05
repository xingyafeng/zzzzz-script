#!/usr/bin/env bash

### unzip apks lib
function main()
{
    local app_name=$1

    auto_create_android_mk $app_name
}

### 自动创建android.mk
function auto_create_android_mk()
{
    local android_mk_file_name=Android.mk
    local armeabi_so=armeabi
    local armeabi_v7a_so=armeabi-v7a
    local tmp=~/.tmpfs
    local curr_apk_name=$1

    local jni_lib="LOCAL_PREBUILT_JNI_LIBS := \\"
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

    if [ ! -d $tmp ];then
        mkdir $tmp
    fi

    (cat << EOF) > ./$android_mk_file_name
LOCAL_PATH := \$(call my-dir)

EOF
    if [ "$curr_apk_name" ];then
        curr_apk_name="${curr_apk_name/%.apk/}"
    else
        return 1
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
        unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi-v7a\/.*.so$/ {print $(NF)}' > $tmp/${armeabi_v7a_so}.txt
    elif [ "`unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}'`" ];then
        unzip -l ${curr_apk_name}.apk | awk '$(NF) ~ /armeabi\/.*.so$/ {print $(NF)}' > $tmp/${armeabi_so}.txt
    else
        echo $build_prebuild >> ./$android_mk_file_name
    fi

    if [ -f $tmp/${armeabi_v7a_so}.txt ];then
        echo $jni_lib >> ./$android_mk_file_name
        while read lib_path;do
            echo "    @$lib_path \\" >> ./$android_mk_file_name
            echo "$lib_path"
        done < $tmp/${armeabi_v7a_so}.txt

        echo >> ./$android_mk_file_name
        echo $build_prebuild >> ./$android_mk_file_name

        rm $tmp/${armeabi_v7a_so}.txt
    elif [ -f $tmp/${armeabi_so}.txt ];then

        echo $jni_lib >> ./$android_mk_file_name

        while read lib_path;do
            echo "    @$lib_path \\" >> ./$android_mk_file_name
            echo "$lib_path"
        done < $tmp/${armeabi_so}.txt

        echo >> ./$android_mk_file_name
        echo $build_prebuild >> ./$android_mk_file_name

        rm $tmp/${armeabi_so}.txt
    else
        if [ -f $android_mk_file_name ];then
            sed -i '/LOCAL_MULTILIB := 32/d' $android_mk_file_name
        else
            echo "Android.mk not found, please check it !"
            return 1
        fi
    fi

    echo
    show_vir "auto create android.mk end ..."
    echo
}

main
