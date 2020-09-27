#!/usr/bin/env bash

# 生成manifest中name对于的path列表
function generate_manifest_list() {

    local manifest_list_p=${tmpfs}/manifest_list.txt

    if [[ -f .repo/manifest.xml ]]; then
        xmlstarlet sel -T -t -m /manifest/project -v "concat(@name,':',@path,'')" -n .repo/manifest.xml > ${manifest_list_p}
    else
        log error ".repo/manifest.xml has no found ..."
    fi

    while IFS=":" read -r _name _path _;do
        #echo ${_name} '---' ${_path}
        if [[ -z ${_path} ]]; then
            _path=${_name}
        fi

        manifest_info[${_name}]=${_path}
    done < ${manifest_list_p}
}

# 拿到项目路径
function get_project_path() {

    if [[ -n ${project} ]]; then
        echo ${manifest_info[${project}]}
    else
        log error "get project path failed ..."
    fi
}

# 生成result_installed.txt
function generate_buildlist_file() {

    local path_py=${script_p}/tools/pathJson.py

    if [[ -f ${path_py} && -f out/target/product/qssi/module-info.json ]]; then
        Command "python ${path_py} out/target/product/qssi/module-info.json build/make/tools/buildlist"
#        Command "python ${path_py} $(get_build_var TARGET_PRODUCT_OUT_ROOT)/qssi/module-info.json ${tmpfs}/buildlist"
#        Command "python ${path_py} module-info.json buildlist"
    else
        log warn "${path_py} or out/target/product/qssi/module-info.json has no found!"
    fi
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
        #echo ${_path} '---' ${_target}
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