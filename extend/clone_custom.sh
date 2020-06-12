####################################
#
#		date:		2018-09-25
#		autor:		yafeng
#		function:	clone custom
#
###################################

#!/usr/bin/env bash

company=magcomm
platform=
base_project=aeon6735_65c_s_l1
new_project=yunovo6735_65c_s_l1

function clone_preloader()
{
	T=$(gettop)

    local preloader_path=bootable/bootloader/preloader/custom
    if [[ ${T} ]];then
        cd ${preloader_path} > /dev/null

        ## clone project
        cp -r ${base_project} ${new_project}
        if [[ ! -f ${new_project}/${new_project}.mk ]];then
            mv ${new_project}/${base_project}.mk ${new_project}/${new_project}.mk
        fi
        ### modify
        sed -i s/${base_project}/${new_project}/g ${new_project}/${new_project}.mk
    fi

    cd ${T} > /dev/null
}

function clone_lk()
{
    T=$(gettop)

    local lk_path=bootable/bootloader/lk
    if [[ ${T} ]];then
        cd ${lk_path} > /dev/null
        cp project/${base_project}.mk project/${new_project}.mk
        cp -r target/${base_project} target/${new_project}
        ## modify
        sed -i s/${base_project}/${new_project}/g project/${new_project}.mk
        sed -i s/${base_project}/${new_project}/g target/${new_project}/include/target/cust_usb.h
    fi

    cd ${T} > /dev/null
}

function clone_kernel()
{
    T=$(gettop)
    kernel_path=kernel-3.10
    arm64_path=arch/arm64
    arm_path=arch/arm
    if [[ ${T} ]];then
        cd ${kernel_path} > /dev/null

        ### one clone
        if [[ "$company" == "eastaeon" ]];then
            cp -r drivers/misc/mediatek/mach/mt6735/${base_project} drivers/misc/mediatek/mach/mt6735/${new_project}
        else
            cp -r drivers/misc/mediatek/mach/mt6580/${base_project} drivers/misc/mediatek/mach/mt6580/${new_project}
        fi

        if [[ "$company" == "eastaeon" ]];then
            cp arch/arm64/boot/dts/${base_project}.dts arch/arm64/boot/dts/${new_project}.dts
            cp arch/arm64/configs/${base_project}_defconfig arch/arm64/configs/${new_project}_defconfig
            cp arch/arm64/configs/${base_project}_debug_defconfig arch/arm64/configs/${new_project}_debug_defconfig

            cd ${arm64_path} > /dev/null
        else
            cp arch/arm/boot/dts/${base_project}.dts arch/arm/boot/dts/${new_project}.dts
            cp arch/arm/configs/${base_project}_defconfig arch/arm/configs/${new_project}_defconfig
            cp arch/arm/configs/${base_project}_debug_defconfig arch/arm/configs/${new_project}_debug_defconfig

            cd ${arm_path} > /dev/null
        fi

        # two modify
        sed -i s/${base_project}/${new_project}/g configs/${new_project}_defconfig
        sed -i s/${base_project}/${new_project}/g configs/${new_project}_debug_defconfig
    fi

    cd ${T} > /dev/null
}

function clone_device()
{
	T=$(gettop)

	if [[ "$T" ]];then

        ### one
        cp -r ${DEVICE}/${base} ${DEVICE}/${new}

        ## 1. ${base}.mk
        mv ${DEVICE}/${new}/${base}.mk ${DEVICE}/${new}/${new}.mk

        ## 2. modify AndroidProducts.mk
        sed -i s/${base}/${new}/g ${DEVICE}/${new}/AndroidProducts.mk

        ## 3. modify ${new}.mk
        sed -i s/${base}/${new}/g ${DEVICE}/${new}/${new}.mk
        sed -i s/`echo ${base} | tr 'a-z' 'A-Z'`/`echo ${new} | tr 'a-z' 'A-Z'`/g ${DEVICE}/${new}/${new}.mk
        sed -i s/`echo ${base} | tr 'a-z' 'A-Z' | awk -F '_' '{ print $1  }'`/`echo ${new} | tr 'a-z' 'A-Z'`/g ${DEVICE}/${new}/${new}.mk

        ## 4. modify vendorsetup.sh
        sed -i s/${base}/${new}/g ${DEVICE}/${new}/vendorsetup.sh
    fi
}

function clone_device_sc()
{
   T=$(gettop)

   if [[ "$T" ]];then

        ### one
        cp -r ${DEVICE}/${base} ${DEVICE}/${new}

        ## 1. ${base}.mk
        mv ${DEVICE}/${new}/${base}.mk ${DEVICE}/${new}/${new}.mk
        sed -i s/${base}/${new}/g ${DEVICE}/${new}/${new}.mk

        ## 2. modify AndroidProducts.mk
        sed -i s/${base}/${new}/g ${DEVICE}/${new}/AndroidProducts.mk

        ## 3. modiyf BoardConfig.mk
        sed -i s/${base}/${new}/g ${DEVICE}/${new}/BoardConfig.mk

        ## 4. modify vendorsetup.sh
        sed -i s/${base}/${new}/g ${DEVICE}/${new}/vendorsetup.sh
    fi
}



function clone_custom()
{
    local ret=$1

    local DEVICE=device/sprd/scx35l

    local base=""
    local new=""

    if [[ "$ret" == "--help" ]];then

        echo Usage: $0 [OPTION...]
        echo

        echo    "   eg: $0 base new company"
        echo
        echo    "   base is you base project name."
        echo    "   new  is you new create project name."
        echo    "   company : magcomm  eastaeon"

        return 0
    fi

    if [[ $# -lt 2 ]];then
        echo
        echo "    you can help for commond , --help"
    else
        base=$1
        new=$2
        clone_device_sc
	fi
}
