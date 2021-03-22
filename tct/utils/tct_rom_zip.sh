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
    local tmpzip=${tmpfs}/zip

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
    if [[ -d ${tmpzip} ]]; then
        rm ${tmpzip}/* -rvf
    fi

    if [[ ${#images[@]} -gt 0 ]]; then

        for image in ${images[@]} ; do

            case `check_rom_image` in

                vendor.img)
                    if [[ -n ${bts_perso} ]]; then
                        pushd `dirname ${perso_p}` > /dev/null
                        cp -vf ${image} ${tmpzip}/`check_rom_image`
                        popd > /dev/null
                    else
                        cp -vf ${image} ${tmpzip}/`check_rom_image`
                    fi
                    ;;

                *)
                    cp -vf ${image} ${tmpzip}/`check_rom_image`
                    ;;
            esac
        done

        pushd ${tmpzip} > /dev/null
        zip -1v ${tmpzip}/${zip_name}.zip *.*
        popd > /dev/null

    else

        #据版本不同压缩路径和名称存在差异性
        case ${build_zip_type} in

            mini)
                #处理压缩包名称,后面增加Teleweb字眼
                zip_name=${build_zip_version}-Teleweb

                zip -1v ${tmpzip}/${zip_name}.zip *.* -x bts_*.zip
            ;;

            *)
                #处理压缩包名称,后面增加Teleweb字眼
                zip_name=${zip_name}

                # 备份版本至指定的路径，然后进行路径压缩
                cp -vf *.mbn ${zip_p}

                pushd ${tmpfs} > /dev/null
                if [[ -d HZNPI ]]; then
                    zip -1vr ${tmpzip}/${zip_name}.zip HZNPI/ -x bts_*.zip
                    rm -rf HZNPI/ &
                fi
                popd > /dev/null
            ;;
        esac
    fi

    # 处理追加文件，perso vendor.img
    if [[ -n ${bts_perso} ]]; then
        case `get_file_type ${perso_p}` in

            mbn)
                image=`basename ${perso_p}`

                pushd `dirname ${perso_p}` > /dev/null
                # rename image
                cp -vf ${image} ${tmpzip}/`check_rom_image`

                # updte perso image
                pushd ${tmpzip} > /dev/null
                zip -1uv ${tmpzip}/${zip_name}.zip `check_rom_image`
                popd > /dev/null

                popd > /dev/null
            ;;

            zip)
                local perso_name=`test -n ${perso_p} && test -f ${perso_p} && unzip -l ${perso_p} | egrep ".raw|.mbn" | tail -1 | awk '{print $NF}'`
                local perso_image=

                show_vig "perso_name = ${perso_name}"

                pushd ${tmpzip} > /dev/null

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

                    if [[ ${perso_image} == `unzip -l ${tmpzip}/${zip_name}.zip | egrep ${perso_image} | awk '{print $NF}'` ]]; then
                        zip -d ${tmpzip}/${zip_name}.zip ${perso_image}
                    fi

                    zip -1uv ${tmpzip}/${zip_name}.zip ${perso_image}
                else
                    log warn "Could not found the ${perso_image} ..."
                fi

                popd > /dev/null
            ;;

            *)
                log error "文件格式：get_file_type ${perso_p}，暂不支持!"
                ;;
        esac

    # 当不存在perso文件的时候，vendor.img的压缩,处理perso目录下的^2.*.mbn
    elif [[ -n ${bts_vendor} ]];then

        image=`basename ${perso_p}`

        pushd `dirname ${perso_p}` > /dev/null
        # rename image
        cp -vf ${image} ${tmpzip}/`check_rom_image`

        # updte perso image
        pushd ${tmpzip} > /dev/null
        zip -1uv ${tmpzip}/${zip_name}.zip `check_rom_image`
        popd > /dev/null

        popd > /dev/null
    fi

    log debug "--> zip version end ..."

    popd > /dev/null
}

# 备份压rom bts缩包至Teleweb服务器
function backup_zip_to_teleweb() {

    local tmpzip=${tmpfs}/zip

    if [[ -f ${tmpzip}/${zip_name}.zip ]]; then
        sudo cp -vf ${tmpzip}/${zip_name}.zip ${teleweb_p}

        if [[ -L ${zip_path}/${zip_name}.zip ]]; then
            sudo rm ${zip_path}/${zip_name}.zip
        fi

        # 压缩包
        sudo ln -sv ${teleweb_p}/${zip_name}.zip ${zip_path}

        # 清理动作
        if [[ -d ${tmpzip} ]]; then
            rm ${tmpzip}/* -rf
        fi
    else
        log error 'The zip has not found ...'
    fi

    show_vip "--> Backup the ${zip_name}.zip file to Teleweb Server."
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

        [Vv]*[Dd]?.mbn|2*.mbn)
            echo 'vendor.img'
            ;;

        V*8?.mbn)
            echo 'oem.img'
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

    local reg='^[Yy].*[01]0.mbn$?'

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

# check oem.img
function check_if_oem_exists() {

    local reg=''

    if [[ -n "${build_bts_more}" ]]; then
        case "`right_remove_end ${build_bts_more} '/'`" in
            MP*)
                reg='^V.*MP.*[8]0.mbn$?'
                ;;

            TM*)
                reg='^V.*TM.*[8]0.mbn$?'
                ;;

            *)
                reg='^V.*[8]0.mbn$?'
                ;;
        esac
    fi

    get_rom_image | head -1
}

# check vendor.img
function check_if_vendor_exists() {

    local reg='^[Vv].*[Dd]0.mbn$?'

    case `get_rom_image | wc -l` in

        1)
            get_rom_image
            ;;

        *)
            for img in `get_rom_image` ; do
                img=`get_file_name ${img}`
                if [[ `get_perso_num ${img}` == ${preso_num} ]]; then
                    echo ${img}.mbn
                fi
            done
            ;;
    esac
}

# 拿到所以perso img
function get_perso_img() {

    local reg="*${preso_num}.{4}.mbn$"

    declare -a perso_img_list

    for file in `ls | egrep ${reg} 2> /dev/null` ; do
        if [[ -f ${file} ]]; then
            perso_img_list[${#perso_img_list[@]}]=${file}
        fi
    done

    if [[ ${#perso_img_list[@]} -gt 0 ]]; then
        echo ${perso_img_list[@]}
    fi
}