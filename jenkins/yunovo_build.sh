#!/usr/bin/env bash

function is_check_source() {

    if [[ ${SOURCE_ANDROID} == "true" ]]; then
        echo true
    else
        echo false
    fi
}

function print-config() {

    local previous_mk=`find out/ -maxdepth 4 -name previous_build_config.mk -type f`

    local default_target_build_variant=

    if [[ -n "$1" ]]; then
        default_target_build_variant=$1
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        unset  TARGET_PRODUCT

        source build/envsetup.sh && show_vip "--> source end ..."

        if [[ -f ${previous_mk} ]]; then
            target_product="`cat ${previous_mk} | grep ^PREVIOUS_BUILD_CONFIG | awk '{ print $3 }' | awk -F '-' '{ print $1 }'`"
            target_build_variant="`cat ${previous_mk} | grep ^PREVIOUS_BUILD_CONFIG | awk '{ print $3 }' | awk -F '-' '{ print $2 }'`"
        else
            target_product=`get_build_var TARGET_PRODUCT`
            target_build_variant=`get_build_var TARGET_BUILD_VARIANT`
        fi

        if [[ "`check_build_variant`" == "true" ]]; then
            target_build_variant=${default_target_build_variant}
        else
            target_build_variant=eng
        fi

        if [[ -n "${build_type}" ]]; then
            target_build_variant=${build_type}
        fi

        if [[ -n "${build_device}" ]]; then
            if [[ "`is_sc_project`" == "true" ]]; then
                target_product=${build_device}
            else
                target_product=full_${build_device}
            fi
        fi

        echo '---------------------------------------------'
        echo "target_product       : ${target_product}"
        echo "target_build_variant : ${target_build_variant}"
        echo '---------------------------------------------'
        echo

        if [[ -n "${target_product}" && -n "${target_build_variant}" ]]; then
            lunch "${target_product}"-"${target_build_variant}" && show_vip "--> lunch end ..."
        else
            __err "The target product is null, please check it ..."
            return 1
        fi
    else
        echo "Couldn't locate ANDRODI_TOP . Please change it."
        return 1
    fi
}

function get-device-path() {

    croot
    dirname `find device/ -name AndroidProducts.mk` | egrep -w `get_build_var TARGET_DEVICE` --color=never
}

function get_target_device() {

    get_build_var TARGET_DEVICE
}

function get_product_out() {

    get_build_var PRODUCT_OUT
}

function get_target_board_platform() {

    get_build_var TARGET_BOARD_PLATFORM
}

function get_host_out() {

    get_build_var HOST_OUT
}