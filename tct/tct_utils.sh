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

    local image=
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

    # 清理动作,防止构建失败后,临时文件未及时清理
    if [[ -d ${zip_p} ]]; then
        rm ${zip_p}/* -rvf
    fi

    if [[ ${#images[@]} -gt 0 ]]; then

        for image in ${images[@]} ; do
            cp -vf ${image} ${zip_p}/`check_rom_image`
        done

        pushd ${zip_p} > /dev/null
        zip -1v ${zip_p}/${zip_name}.zip *.*
        popd > /dev/null

    else
        zip -1v ${zip_p}/${zip_name}.zip *.*
    fi

    if [[ $? -eq 0 ]]; then
        if [[ -n ${bts_perso} ]]; then
            case `get_file_type ${perso_p}` in

                mbn)
                    image=`basename ${perso_p}`

                    pushd `dirname ${perso_p}` > /dev/null
                    # rename image
                    cp -vf ${image} ${zip_p}/`check_rom_image`

                    # updte perso image
                    pushd ${zip_p} > /dev/null
                    zip -1uv ${zip_p}/${zip_name}.zip `check_rom_image`
                    popd > /dev/null

                    popd > /dev/null
                ;;

                zip)
                    local perso_name=`test -n ${perso_p} && test -f ${perso_p} && unzip -l ${perso_p} | egrep ".raw|.mbn" | tail -1 | awk '{print $NF}'`
                    local perso_image=

                    show_vig "perso_name = ${perso_name}"

                    pushd ${zip_p} > /dev/null

                    unzip ${perso_p} -d .
                    if [[ -f ${perso_name} ]]; then
                        case `get_file_type ${perso_name}` in

                            raw|mbn)
                                image=${perso_name}
                                perso_image=`check_rom_image`
                                mv -vf ${image} ${perso_image}
                            ;;

                            *)
                                log error "格式不匹配 ..."
                            ;;
                        esac

                        if [[ ${perso_image} == `unzip -l ${zip_p}/${zip_name}.zip | egrep ${perso_image} | awk '{print $NF}'` ]]; then
                            zip -d ${zip_p}/${zip_name}.zip ${perso_image}
                        fi

                        zip -1uv ${zip_p}/${zip_name}.zip ${perso_image}
                    else
                        log warn "Could not found the ${perso_image} ..."
                    fi

                    popd > /dev/null
                ;;

                *)
                    log error "文件格式：get_file_type ${perso_p}，暂不支持!"
                    ;;
            esac
        fi
    else
        log error "zip version fail. "
    fi

    log debug "--> zip version end ..."

    popd > /dev/null
}

# 备份压缩包至Teleweb服务器
function backup_zip_to_teleweb() {

    local zip_p=${tmpfs}/zip

    pushd ${zip_path} > /dev/null

    if [[ -f ${zip_p}/${zip_name}.zip ]]; then
        sudo cp -vf ${zip_p}/${zip_name}.zip .

        # 清理动作
        if [[ -d ${zip_p} ]]; then
            rm ${zip_p}/* -rf
        fi
    fi

    show_vip "--> Backup the ${zip_name}.zip file to Teleweb Server."

    popd > /dev/null
}

function check_rom_image() {

    case ${image} in

        B*[01]?.mbn)
            echo 'boot.img'
            ;;

        [Yy]*[01]?.mbn|[Yy]*.raw)
            echo 'system.img'
            ;;

        S*[01]?.mbn|U*[01]?.mbn)
            echo 'userdata.img'
            ;;

        R*[01]?.mbn)
            echo 'recovery.img'
            ;;

        3*??.mbn)
            echo 'super.img'
            ;;
        *)
            log error "check image file failed ..."
        ;;
    esac
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