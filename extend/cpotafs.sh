#!/usr/bin/env bash

# TODO 据要求拷贝OTA基准包.
function main() {

    local otafs=""
    local rom_p=/public/share/ROM
    local otafs_p=${rom_p}/otafs
    local otafs_dest_p=
    local rom_type=

    local tmp=
    local custom_p=
    local yunovo_to_version=${@: -1}

    declare -a ver
    declare -a rom_path

    if [[ "$#" -lt 1 ]]; then
        echo ""
        echo "cpotafs \$@"
        echo
        echo "    参数: 1. OTA编译完成后生成的的时间轴文件夹 如: S1.00.2019.04.01_20.37.34 "
        echo "          2. 可以同时传入多个时间轴,如: S1.00.2019.04.01_20.37.34 S1.00.2019.04.02_11.30.07 "
        echo
        echo "    e.g. cpotafs S1.00.2019.04.01_20.37.34 S1.00.2019.04.02_11.30.07 "
        echo

        return 0
    fi

    if [[ "$1" ]]; then
        rom_type=$1
        rom_path[${#rom_path[@]}]="${rom_p}/share_nxos/ROM/${rom_type}"
        rom_path[${#rom_path[@]}]="${rom_p}/share_jenkins/ROM/${rom_type}"
    else
        echo "参数1不正确 ..."
    fi

    # 拿到客制化目录,反推客制化 版型/客户/项目
    if [[ -n ${yunovo_to_version} ]]; then
        custom_p=`find "${rom_path[@]}" -name ${yunovo_to_version} | awk -F/ '{ print $(NF-2) "/" $(NF-1) }'`
        if [[ -z ${custom_p} ]]; then
            __err "custom_p is null."
            return 1
        fi
    else
        __err "服务器未发现此版本, 请检查服务器是否存在?"
        return 1
    fi

    # 版型/客户/项目
    yunovo_board=`echo ${custom_p} | awk -F/  '{ print $1 }' | tr 'A-Z' 'a-z'`
    if [[ -z ${yunovo_board} ]]; then
        __err "版型为空."
        return 1
    fi

    tmp=`echo ${custom_p} | awk -F/ '{ print $2 }' | tr 'A-Z' 'a-z'`

    yunovo_custom=`echo ${tmp}  | awk -F '-' '{ print $1 }'`
    if [[ -z ${yunovo_custom} ]]; then
        __err "客户名为空."
        return 1
    fi

    yunovo_project=`echo ${tmp} | awk -F '-' '{ print $2 }'`
    if [[ -z ${yunovo_project} ]]; then
        __err "项目名为空."
        return 1
    fi

    for v in $@ ; do
        if [[ "${v}" == "Release" || "${v}" == "Debug" ]]; then
            continue
        fi

        otafs=`find "${rom_path[@]}" -name "*.zip" | egrep "${v}" | grep -vE 'inc|fake' | grep -vE 'target_files-package.zip|otatools.zip' | grep -v "sdupdate.*.zip"`

        # 保存OTA基准包
        ver[${#ver[@]}]="${otafs##*/}"

        otafs_dest_p=${otafs_p}/${yunovo_board}/${yunovo_custom}-${yunovo_project}/${v}
        if [[ ! -d ${otafs_dest_p} ]]; then
            mkdir -p ${otafs_dest_p}
        fi

        if [[ -n "${otafs}" ]]; then
            cp -f "${otafs}" "${otafs_dest_p}"
        else
            echo "null"
            return 1
        fi

        for b in `find "${rom_path[@]}" -name "preloader*.bin" -o -name "lk.bin" | grep ${v}`
        do
            cp -f ${b} "${otafs_p}/binfs"
        done
    done

    echo ${ver[@]}
}

main "$@"