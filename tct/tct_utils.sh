#!/usr/bin/env bash

# 探测android根路径 croot
function is_android_gettop() {

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        echo true
    else
        echo false
    fi
}

# 探测预编译apk项目
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

# 探测rom预编译项目
function is_rom_prebuild() {

    case ${job_name} in

        DelhiTF_Gerrit_Build|TransformerVZW_Gerrit_Build|Thor84gVZW-R_Gerrit_Build)
            echo true
        ;;

        DohaTMO-R_Gerrit_Build)
            echo true
        ;;

        *)
            echo false
        ;;
    esac
}

# 探测rom编译项目
function is_rom_build() {

    case ${job_name} in

        transformervzw|dohatmo-r|irvinevzw)
            echo true
        ;;

        *)
            echo false
        ;;
    esac
}

# 探测mediaTek项目
function is_mediatek_project() {

    case ${job_name} in

        DohaTMO-R_Gerrit_Build)
            echo true
        ;;

        *)
            echo false
        ;;
    esac
}

# 探测是否不需要创建versioninfo and manifest
function is_build_debug() {

    case ${VER_VARIANT} in

        appli)
            case ${build_type} in

                userdebug)
                    echo true
                    ;;

                *)
                    echo false
                ;;
            esac
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

    # 正面手动增加编译项目支持qssi构建
    case ${path} in

        device/qcom/qssi|mmitest)
            let count++
        ;;

        *)
        ;;
    esac

    if [[ ${count} -gt 0 ]]; then
        echo true
    else
        echo false
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

# 探测是否在同一台服务器构建
function is_thesame_server() {

    if [[ ${build_server_x} == ${build_server_y} ]]; then
        echo true
    else
        echo false
    fi
}

# perso项目
function is_perso_project() {

    case ${build_zip_project} in

        *)
            echo false
            ;;
    esac
}

# 探测mini版本
function is_mini_version() {

    case ${VER_VARIANT} in

        mini)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

# 探测认证版本
function is_cert_version() {

    case ${VER_VARIANT} in

        cert)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

# 探测发布版本并且为user
function is_user_appli() {

    case ${build_type} in

        user)
            case ${VER_VARIANT} in
                appli)
                    echo true
                ;;

                *)
                    echo false
                ;;
            esac
        ;;

        *)
            echo false
        ;;
    esac
}

# 探测强耦合项目
function is_over_coupling() {

    for tp in ${tct_projects[@]} ; do

        if [[ ${tp} == ${project_path} ]]; then
            echo 'true' && return 0
        fi
    done

    echo false
}