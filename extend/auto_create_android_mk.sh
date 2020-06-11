#!/usr/bin/env bash

usage() {
    echo >&2 "Usage: ${FUNCNAME[0]} apk <文件名> ..."
    echo
    echo >&2 "   eg: ${FUNCNAME[0]} Launcher3.apk"
    return 1
}

function auto_create_android_mk()
{
    local tmpfs=~/.tmpfs
    local APK_NAME=""

    local LIBS='LOCAL_PREBUILT_JNI_LIBS := \'
    local BUILDS='include $(BUILD_PREBUILT)'

    if [[ ! -d ${tmpfs} ]]; then
        mkdir -p ${tmpfs}
    fi

    if [[ -n "$1" && $# -eq 1 ]]; then
        APK_NAME=$1
    fi

    if [[ "$#" -eq 1 ]];then
        echo
        echo "--> create android.mk start ..."
        echo

        echo "APK_NAME = $APK_NAME"
        echo
    else
        usage
    fi

    if [[ "${APK_NAME}" ]];then
        APK_NAME="${APK_NAME/%.apk/}"
    else
        return 1
    fi

    if [[ -z "${build_signature_type}" ]]; then
        build_signature_type=PRESIGNED
    fi

    cat << EOF > Android.mk
LOCAL_PATH := \$(call my-dir)

EOF

    cat << EOF >> Android.mk
###################################################### ${APK_NAME}

include \$(CLEAR_VARS)
LOCAL_MODULE := ${APK_NAME}
LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := ${build_signature_type}
LOCAL_MODULE_CLASS := APPS
LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)

EOF

    if [[ -n ${build_override_module} ]];then
        echo "LOCAL_OVERRIDES_PACKAGES := `echo ${build_override_module} | sed 's/;/ /g'`" >> Android.mk
        echo >> Android.mk
    fi

    if [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/arm64-v8a\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/arm64-v8a\/.*.so$/ { print $(NF) }' > ${tmpfs}/arm64_v8a.txt
    fi

    if [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ { print $(NF) }' > ${tmpfs}/armeabi-v7a.txt
    elif [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ { print $(NF) }' > ${tmpfs}/armeabi.txt
    fi

    if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then

        echo 'ifeq ($(strip $(TARGET_ARCH)), arm64)' >> Android.mk
        echo 'LOCAL_MULTILIB := 64' >> Android.mk
        echo 'endif' >> Android.mk
        echo >> Android.mk

        echo 'ifeq ($(strip $(TARGET_ARCH)), arm64)' >> Android.mk
        echo >> Android.mk
        echo ${LIBS} >> Android.mk

        while read lib_path;do
            echo "    @${lib_path} \\" >> Android.mk
            # print
            echo "${lib_path}"
        done < ${tmpfs}/arm64_v8a.txt
        echo >> Android.mk
        echo 'endif' >> Android.mk
        echo >> Android.mk
    fi

    if [[ -f ${tmpfs}/armeabi-v7a.txt || -f ${tmpfs}/armeabi.txt ]]; then

        if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then
            echo 'ifeq ($(strip $(TARGET_ARCH)), arm)' >> Android.mk
        else
            echo 'ifneq ($(strip $(filter $(TARGET_ARCH), arm arm64)), )' >> Android.mk
        fi

        echo 'LOCAL_MULTILIB := 32' >> Android.mk
        echo 'endif' >> Android.mk

        echo >> Android.mk
        if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then
            echo 'ifeq ($(strip $(TARGET_ARCH)), arm)' >> Android.mk
        else
            echo 'ifneq ($(strip $(filter $(TARGET_ARCH), arm arm64)), )' >> Android.mk
        fi
        echo >> Android.mk
        echo ${LIBS} >> Android.mk

        if [[ -f ${tmpfs}/armeabi-v7a.txt ]];then
            while read lib_path;do
                echo "    @${lib_path} \\" >> Android.mk
                # print
                echo "${lib_path}"
            done < ${tmpfs}/armeabi-v7a.txt
            echo >> Android.mk
            echo 'endif' >> Android.mk
            echo >> Android.mk
        elif [[ -f ${tmpfs}/armeabi.txt ]];then
            while read lib_path;do
                echo "    @${lib_path} \\" >> Android.mk
                # print
                echo "${lib_path}"
            done < ${tmpfs}/armeabi.txt
            echo >> Android.mk
            echo 'endif' >> Android.mk
            echo >> Android.mk
        fi
    fi

    if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then
        rm ${tmpfs}/arm64_v8a.txt
    fi

    if [[ -f ${tmpfs}/armeabi-v7a.txt ]];then
        rm ${tmpfs}/armeabi-v7a.txt
    fi

    if [[ -f ${tmpfs}/armeabi.txt ]];then
        rm ${tmpfs}/armeabi.txt
    fi

    echo ${BUILDS} >> Android.mk
    echo >> Android.mk

    echo
    echo "--> create android.mk end ..."
    echo
}
