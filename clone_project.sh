####################################
#
#		date:		2016-04-14
#		autor:		yafeng
#		function:	clone project
#
###################################

#!/bin/bash

company=eastaeon
platform=
base_project=aeon6735_65c_s_l1
new_project=yunovo6735_65c_s_l1

function clone_custom()
{
    local ret=$1

    if [ "$ret" == "--help" ];then

        show_vig Usage: clone_custom [OPTION...]

        echo    "   eg: clone_custom base_project new_project"
        echo
        show_vig args outline
        echo    "   base_project is you base project name."
        echo    "   new_project is you new create project name."

        return 0
    fi

    if [ $# -lt 2 ];then

        show_vir What args do you want?
        echo
        echo "    you can help for commond , --help"

    else
        base_project=$1
        new_project=$2

        if [ $base_project -a $new_project ];then
            clone_device
            clone_preloader
            clone_lk
            clone_kernel
        fi
    fi
}

function clone_preloader()
{
	T=$(gettop)

    local preloader_path=bootable/bootloader/preloader/custom
    if [ $T ];then
        cd $preloader_path > /dev/null

        ## clone project
        cp -r $base_project $new_project
        if [ ! -f $new_project/${new_project}.mk ];then
            mv ${new_project}/${base_project}.mk $new_project/${new_project}.mk
        fi
        ### modify
        sed -i s/$base_project/$new_project/g ${new_project}/${new_project}.mk
    fi

    cd $T > /dev/null
}

function clone_lk()
{
    T=$(gettop)

    local lk_path=bootable/bootloader/lk
    if [ $T ];then
        cd $lk_path > /dev/null
        cp project/${base_project}.mk project/${new_project}.mk
        cp -r target/${base_project} target/${new_project}
        ## modify
        sed -i s/${base_project}/${new_project}/g project/${new_project}.mk
        sed -i s/${base_project}/${new_project}/g target/${new_project}/include/target/cust_usb.h
    fi

    cd $T > /dev/null
}

function clone_kernel()
{
    T=$(gettop)
    kernel_path=kernel-3.10
    arm64_path=arch/arm64
    if [ $T ];then
        cd $kernel_path > /dev/null

        ### one clone
        cp -r drivers/misc/mediatek/mach/mt6735/${base_project} drivers/misc/mediatek/mach/mt6735/${new_project}
        cp arch/arm64/boot/dts/${base_project}.dts arch/arm64/boot/dts/${new_project}.dts
        cp arch/arm64/configs/${base_project}_defconfig arch/arm64/configs/${new_project}_defconfig
        cp arch/arm64/configs/${base_project}_debug_defconfig arch/arm64/configs/${new_project}_debug_defconfig

        #echo `pwd`
        cd $arm64_path > /dev/null
        #echo `pwd`
        # two modify
        sed -i s/${base_project}/${new_project}/g configs/${new_project}_defconfig
        sed -i s/${base_project}/${new_project}/g configs/${new_project}_debug_defconfig
    fi

    cd $T > /dev/null
}

function clone_device()
{
	T=$(gettop)
	if [ $T ];then
        ### one
        cp -r device/$company/$base_project device/$company/$new_project
		cp -r device/$company/$base_project/full_${base_project}.mk device/$company/$new_project/full_${new_project}.mk
        cp -r vendor/mediatek/proprietary/custom/$base_project vendor/mediatek/proprietary/custom/$new_project
        cp -r vendor/mediatek/proprietary/trustzone/project/${base_project}.mk vendor/mediatek/proprietary/trustzone/project/${new_project}.mk
        #cp -r md32/md32/project/${base_project}.mk md32/md32/project/${new_project}.mk

        ### two
        sed -i s/${base_project}/${new_project}/g device/${company}/${new_project}/AndroidProducts.mk
        sed -i s/${base_project}/${new_project}/g device/${company}/${new_project}/BoardConfig.mk
        sed -i s/${base_project}/${new_project}/g device/${company}/${new_project}/device.mk
        sed -i s/${base_project}/${new_project}/g device/${company}/${new_project}/full_${new_project}.mk
        sed -i s/${base_project}/${new_project}/g device/${company}/${new_project}/vendorsetup.sh
        sed -i s/${base_project}/${new_project}/g vendor/mediatek/proprietary/custom/${new_project}/Android.mk

        ### three  if not share libraries with base_project, mtk recommend .
        #cp -r vendor/${company}/libs/${base_project} vendor/${company}/libs/${new_project}
        ln -s $T/vendor/${company}/libs/${base_project} $T/vendor/${company}/libs/${new_project}
        ## base project use not share libs
        #device/$company/$new_project/device.mk
        #$(call inherit-product-if-exists, vendor/${company}/libs/${base_project}/device-vendor.mk)

    fi
}
