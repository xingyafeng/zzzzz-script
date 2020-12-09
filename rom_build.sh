#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# 1. manifest分支
build_manifest=
# 2. 更新代码
build_update_code=

# init function
. "$(dirname "$0")/tct/tct_init.sh"

function get_cpu_core() {

    case ${JOBS} in

        8)
            JOBS=${JOBS}
            ;;

        *)
            JOBS=$((JOBS/2))
            ;;
    esac
}

function set_manifest_xml() {

    if [[ -n ${build_manifest} ]]; then
        if [[ ${build_manifest} =~ '.xml' ]]; then
            build_manifest=${build_manifest}
        else
            build_manifest=${build_manifest}.xml
        fi
    fi
}

function handle_common() {

    # 拿到JOBS
    get_cpu_core

    # 配置manifest.xml
    set_manifest_xml

    # 配置WORKSPACE
    gettop_p=$(pwd)
}

function handle_variable() {

    # 1. manifest
    build_manifest=${tct_manifest:-}
    if [[ -z ${build_manifest} ]]; then
        log error 'The manifest is null ...'
    fi

    # 2. 更新代码
    build_update_code=${tct_update_code:-false}

    handle_common
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_manifest          = " ${build_manifest}
    echo "build_update_code       = " ${build_update_code}
    echo '-----------------------------------------'
    echo
}

function init() {

    handle_variable
    print_variable
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    local root_p=~/jobs

    case $# in
        1)
            local object=${1:-}

            case ${object} in

                qssi)
                    local build_p=${root_p}/${job_name}X/${tct_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${build_p} > /dev/null

                    init

                    if [[ "${build_update_code}" == "true" ]];then
                        # 下载，更新源代码
                        download_android_source_code
                    else
                        log warn "This time you don't update the source code."
                    fi

                    source_init_tct
                    make_android_tct

                    popd > /dev/null
                    ;;

                target|merge|modem)
                    local build_p=${root_p}/${job_name}Y/${tct_manifest}

                    if [[ ! -d ${build_p} ]]; then
                        mkdir -p ${build_p}
                    fi

                    pushd ${build_p} > /dev/null

                    init

                    if [[ ${object} == 'target' ]]; then
                        if [[ "${build_update_code}" == "true" ]];then
                            # 下载，更新源代码
                            download_android_source_code
                        else
                            log warn "This time you don't update the source code."
                        fi
                    else
                        log warn "The ${object} don't download the source code."
                    fi

                    source_init_tct
                    make_android_tct

                    popd > /dev/null
                    ;;

                *)
                    :
                ;;
            esac
            :
        ;;

        *)
            log error '识别错误...'
        ;;
    esac

    trap - ERR
}

main "$@"