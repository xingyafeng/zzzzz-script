#!/bin/bash

rm -f Android.mk
touch Android.mk

echo "" >> Android.mk
echo "#This file is created automatically, please do not modify!!!" >> Android.mk
echo "" >> Android.mk
echo "LOCAL_PATH := \$(call my-dir)" >> Android.mk
echo "" >> Android.mk

for f in `ls .`
do
	if [[ -f ${f} ]] && [[ `basename ${f}` != Android.mk ]] && [[ `basename ${f}` != `basename $0` ]] && ( [[ `basename ${f##*.}` == apk ]] || [[ `basename ${f##*.}` == lar ]] ); then
		if [[ `basename ${f##*.}` == apk ]];then
			module=`echo ${f} | sed 's/\.apk$//g'`
			suffix="apk"
		else
			module=`echo ${f} | sed 's/\.lar$//g'`
			suffix="lar"
		fi
		echo "include \$(CLEAR_VARS)" >> Android.mk
                if [[ ${module} == GpsTestUtil ]]; then
                    echo "LOCAL_MODULE_TAGS := debug" >> Android.mk
                else
	            echo "LOCAL_MODULE_TAGS := optional" >> Android.mk
                fi
		echo "LOCAL_MODULE := $module" >> Android.mk
                if [[ ${module} == launcher4 ]]; then
                    echo "LOCAL_OVERRIDES_PACKAGES := Launcher3">> Android.mk
                fi
                if [[ ${module} == "file" ]]; then
                    echo "LOCAL_PRIVILEGED_MODULE := true">> Android.mk
                fi
		echo "LOCAL_SRC_FILES := $module.$suffix" >> Android.mk
		echo "LOCAL_MODULE_CLASS := APPS" >> Android.mk
		echo "LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)" >> Android.mk
		echo "LOCAL_CERTIFICATE := platform" >> Android.mk

        LIBS_X86=$(unzip -l ${f} *x86/*.so | grep "\.so" | awk '{print $4}')

        if [[ "`unzip -l ${f} | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ {print $(NF)}'`" ]];then
            LIBS_ARM=$(unzip -l ${f} */armeabi-v7a/*.so | grep "\.so" | awk '{print $4}')
        elif [[ "`unzip -l ${f} | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ {print $(NF)}'`"  ]];then
            LIBS_ARM=$(unzip -l ${f} *armeabi/*.so | grep "\.so" | awk '{print $4}')
        else
            LIBS_ARM=$(unzip -l ${f} */armeabi/*.so | grep "\.so" | awk '{print $4}')
        fi

		if [[ -n "$LIBS_ARM" ]]; then
			echo "ifneq (\$(filter \$(TARGET_ARCH), arm arm64),)" >> Android.mk
			echo "LOCAL_MULTILIB := 32" >> Android.mk
			echo "LOCAL_PREBUILT_JNI_LIBS := \\" >> Android.mk
            lib_last=$(echo ${LIBS_ARM} | awk '{print $NF}')
			for libpath in ${LIBS_ARM}
			do
                if [[ "$libpath" = "$lib_last" ]]; then
				    echo "    @${libpath}" >> Android.mk
                else
				    echo "    @${libpath} \\" >> Android.mk
                fi
			done
			echo "endif" >> Android.mk
		fi
		if [[ -n "$LIBS_X86" ]]; then
			echo "ifneq (\$(filter \$(TARGET_ARCH), x86 x86_64),)" >> Android.mk
			echo "LOCAL_MULTILIB := 32" >> Android.mk
			echo "LOCAL_PREBUILT_JNI_LIBS := \\" >> Android.mk
            lib_last=$(echo ${LIBS_X86} | awk '{print $NF}')
			for libpath in ${LIBS_X86}
			do
                if [[ "$libpath" = "$lib_last" ]]; then
				    echo "    @${libpath}" >> Android.mk
                else
				    echo "    @${libpath} \\" >> Android.mk
                fi
			done
			echo "endif" >> Android.mk
		fi
		echo "include \$(BUILD_PREBUILT)" >> Android.mk
		echo "" >> Android.mk
	elif [[ -f ${f} ]] && [[ `basename ${f}` != Android.mk ]] && [[ `basename ${f}` != `basename $0` ]] && [[ `basename ${f##*.}` == iso ]]; then
		echo "\$(shell mkdir -p \$(TARGET_OUT)/mobile_toolkit/)" >> Android.mk
		echo "\$(shell \`cp \$(LOCAL_PATH)/$f \$(TARGET_OUT)/mobile_toolkit/iAmCdRom.iso\`)" >> Android.mk
		echo "" >> Android.mk
	fi
done

