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

            case `check_rom_image` in

                vendor.img)
                    if [[ -n ${bts_perso} ]]; then
                        pushd `dirname ${perso_p}` > /dev/null
                        cp -vf ${image} ${zip_p}/`check_rom_image`
                        popd > /dev/null
                    else
                        cp -vf ${image} ${zip_p}/`check_rom_image`
                    fi
                    ;;

                *)
                    cp -vf ${image} ${zip_p}/`check_rom_image`
                    ;;
            esac
        done

        pushd ${zip_p} > /dev/null
        zip -1v ${zip_p}/${zip_name}.zip *.*
        popd > /dev/null

    else
        zip -1v ${zip_p}/${zip_name}.zip *.* -x bts_*.zip
    fi

    # 处理追加文件，perso vendor.img
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

    # 当不存在perso文件的时候，vendor.img的压缩,处理perso目录下的^2.*.mbn
    elif [[ -n ${bts_vendor} ]];then

        image=`basename ${perso_p}`

        pushd `dirname ${perso_p}` > /dev/null
        # rename image
        cp -vf ${image} ${zip_p}/`check_rom_image`

        # updte perso image
        pushd ${zip_p} > /dev/null
        zip -1uv ${zip_p}/${zip_name}.zip `check_rom_image`
        popd > /dev/null

        popd > /dev/null
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

# 探测预编译apk
function is_apk_prebuild() {

    case ${JOB_NAME} in

        JrdSetupWizard|Launcher3|Settings|SystemUI|ApkPrebuild|HiddenMenu)
            echo true
            ;;

        *)
            echo false
        ;;
    esac
}

# 区分由时间触发
function is_gerrit_trigger() {

    case ${GERRIT_VERSION} in

        '2.15.7')
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

# 是否为QSSI编译
function is_qssi_product() {

    local path=
    local count=0
    local result_installed=result_installed.txt

    declare -A moudule_info

    case $# in
        1)
            path=${1-}
            ;;
        *)
            retrun 1
            ;;
    esac

    if [[ ! -f result_installed.txt ]]; then
        generate_buildlist_file
    fi

    while IFS=":" read -r _path _target _;do
        moudule_info[${_path}]=${_target}
    done < ${result_installed}

    for tgt in ${moudule_info[${path}]} ; do

        case ${tgt} in

            out/target/product/qssi/system/*)
                let count++
                ;;

            out/target/product/qssi/system_ext/*)
                let count++
                ;;

            out/target/product/qssi/product/*)
                let count++
                ;;
        esac
    done

    if [[ ${count} -gt 0 ]]; then
        echo true
    else
        echo false
    fi
}

# 获取正确的编译路径
function getdir() {

    local prjdir=${1:-}
    local tmpdir=

    if [[ ! -f ${buildlist} ]]; then
        log error "The ${buildlist} file has no found!"
    fi

    if [[ ${project_path} == ${prjdir} ]]; then
        if [[ -n ${module_target[${prjdir}]} ]]; then
            echo ${prjdir}

            return 0
        else
            return 0
        fi
    else
        tmpdir=$(dirname ${prjdir})
#        echo '@@ tmpdir: ' ${tmpdir}
        while IFS=':' read -r k v ; do
#            echo 'k : ' ${k} ' --- ' 'v : ' ${v}
            if [[ -n ${v} ]]; then
#                echo 'k : ' ${k}
                if [[ ${k} == "${tmpdir}" ]]; then
                    if [[ ${tmpdir} != ${project_path} ]]; then
                        if [[ -n ${module_target[${tmpdir}]} ]]; then
                            echo ${tmpdir}

                            return 0
                        fi
                    fi
                fi
            fi
        done < ${buildlist}

        getdir ${tmpdir}
    fi
}

# 获取最顶层路径
function gotdir() {

    local prjdir=${1:-}
    local tmpdir=

    tmpdir=$(dirname ${prjdir})

    if [[ -z $(echo ${tmpdir} | egrep '/') ]]; then
        echo ${tmpdir}
    else
        gotdir ${tmpdir}
    fi
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

# 拿到perso号
function get_perso_num() {

    local mbn=${1-}

    echo ${mbn: -5:1}
}

# perso项目
function is_perso_project() {

    case ${build_zip_project} in

        *)
            echo false
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

# 统计编译的工程
function statistical_compilation_project() {

    if [[ ! -f ${tmpfs}/tmp.txt ]]; then
        :> ${tmpfs}/tmp.txt
    fi

    if [[ ! -f ${tmpfs}/bpath.txt ]]; then
        :> ${tmpfs}/bpath.txt
    fi

    if [[ ! -f ${tmpfs}/bproject.txt ]]; then
        :> ${tmpfs}/bproject.txt
    fi

    # 统计build path
    if [[ -n ${build_path[@]} ]]; then
        echo ${build_path[@]} > ${tmpfs}/tmp.txt
        cat ${tmpfs}/tmp.txt | sort -u >> ${tmpfs}/bpath.txt
        __pruple__ "build path:"
        cat ${tmpfs}/bpath.txt | sort -u
        cat ${tmpfs}/bpath.txt | sort -u > ${tmpfs}/tmp.txt
        cat ${tmpfs}/tmp.txt | sort -u > ${tmpfs}/bpath.txt
    fi

    # 统计build project
    if [[ -n ${project_paths[@]} ]]; then
        echo ${project_paths[@]} > ${tmpfs}/tmp.txt
        cat ${tmpfs}/tmp.txt | sort -u >> ${tmpfs}/bproject.txt
        __pruple__ "project path:"
        cat ${tmpfs}/bproject.txt | sort -u
        cat ${tmpfs}/bproject.txt | sort -u > ${tmpfs}/tmp.txt
        cat ${tmpfs}/tmp.txt | sort -u > ${tmpfs}/bproject.txt
    fi
}