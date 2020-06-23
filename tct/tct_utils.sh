#!/usr/bin/env bash

#####################################################
##
##  函数: enhance_zip
##  功能: 增强压缩系统版本
##  参数: 1 zip_path: 压缩路径
##        2 zip_name: 压缩名称
##
##
##  zip 参数说明:
##　　　-1 : compress faster  2G文件大概花费 2min33s
##      -9 : compress bester  2G文件大概花费 9min18s
####################################################
function enhance_zip() {

    local zip_p=${tmpfs}/zip

    log debug "--> zip version start ..."

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "zip_path   = " ${zip_path}
    echo "zip_name   = " ${zip_name}
    echo '-----------------------------------------'
    echo

    pushd ${zip_path} > /dev/null

    if [[ ! -f ${zip_name}.zip ]]; then
        if [[ ${#image[@]} -gt 0 ]]; then
            zip -1v ${zip_p}/${zip_name}.zip ${image[@]}
        else
            zip -1v ${zip_p}/${zip_name}.zip *.*
        fi

        if [[ $? -eq 0 ]]; then
            if [[ -n ${build_zip_perso} ]]; then
                case `get_file_type ${perso_p}` in

                    mbn)
                        pushd `dirname ${perso_p}` > /dev/null
                        zip -1uv ${zip_p}/${zip_name}.zip `basename ${perso_p}`
                        popd > /dev/null
                    ;;

                    zip)
                        local perso_mbn=
                        local perso_name=`test -n ${perso_p} && test -f ${perso_p} && unzip -l ${perso_p} | egrep ".raw|.mbn" | tail -1 | awk '{print $NF}'`

                        show_vig "perso_name = ${perso_name}"

                        pushd ${zip_p} > /dev/null

                        unzip ${perso_p} -d .
                        if [[ -f ${perso_name} ]]; then
                            case `get_file_type ${perso_name}` in

                                raw)
                                    perso_mbn=`echo ${perso_name} | sed 's/.raw/.mbn/'`
                                    mv -vf ${perso_name} ${perso_mbn}
                                ;;

                                *)
                                    perso_mbn=${perso_name}
                                ;;
                            esac

                            zip -1uv ${zip_p}/${zip_name}.zip ${perso_mbn}
                        else
                            log warn "Could not found the ${perso_name} ..."
                        fi

                        popd > /dev/null
                    ;;
                esac
            fi

            show_vip "Backup the ${zip_name}.zip file to Teleweb Server."

            sudo cp -vf ${zip_p}/${zip_name}.zip .
            if [[ -d ${zip_p} ]]; then
                rm ${zip_p}/* -rf
            fi
        else
            log error "zip version fail. "
        fi
    else
        log warn "The ${zip_name}.zip file is exist ... "
    fi

    log debug "--> zip version end ..."

    popd > /dev/null
}

function get_rom_image() {

    for file in `ls | egrep ${reg} 2> /dev/null` ; do
        if [[ -f ${file} ]]; then
            echo ${file}
        else
            echo null
        fi
    done
}

# check boot.img
function check_if_boot_exists() {

    local reg='^B.*[01]0.mbn$?'

    get_rom_image
}

# check system.img
function check_if_system_exists() {

    local reg='^Y.*[01]0.mbn$?'

    get_rom_image
}

# check recovery.img
function check_if_recovery_exists() {

    local reg='^R.*[01]0.mbn$?'

    get_rom_image
}

# check userdata.img
function check_if_userdata_exists() {

    local reg=''

    if [[ `is_mtk_board` == "true" ]]; then
        reg='^S.*[0|1]0.mbn$?'
    else
        reg='^U.*[0|1]0.mbn$?'
    fi

    get_rom_image
}

# 探测MTK芯片
function is_mtk_board() {

    local sca=`ls *.sca 2> /dev/null`

    if [[ -n ${sca} && -f ${sca} ]]; then
        echo true
    else
        echo false
    fi
}