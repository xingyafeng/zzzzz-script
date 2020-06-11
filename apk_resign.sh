#!/usr/bin/env bash

## 若某一个命令返回非零值就退出
set -e

# 1. 待签名文件
build_pre_signapk=
# 2. 服务器地址
build_host=
# 3.端口号
build_port=

## 当前Shell文件名
shellfs=$0

declare -a signapk

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

function get_resign_apk() {

    OIFS=$IFS
    IFS=','
    for f in ${build_pre_signapk} ; do
        signapk[${#signapk[@]}]=${f}
    done
    IFS=${OIFS}
}

function handle_commom_vairable() {
    :
}

function handle_vairable() {

    # 1. 待签名文件
    build_pre_signapk=${yunovo_pre_signapk:-}
    if [[ -n "${build_pre_signapk}" ]]; then
        get_resign_apk
    else
        __err "pre signapk is null ..."
        return 1
    fi

    # 2. 服务器地址
    build_host=${yunovo_host:-}

    # 3. 端口号
    build_port=${yunovo_port:-}

    handle_commom_vairable
}

function print_variable() {

    echo
    echo "JOBS = "${JOBS}
    echo '-----------------------------------------'
    echo "build_pre_signapk = "${build_pre_signapk}
    echo "build_host        = "${build_host}
    echo "build_port        = "${build_port}
    echo '-----------------------------------------'
    echo "signapk           = "${signapk[*]}
    echo
}

function init() {

    if [[ ! -d ${pre_signapk_p} ]]; then
        mkdir -p ${pre_signapk_p}
    fi

    # 1. 下载签名仓库 path:${tmpfs}/${nx_security}
    download_and_update_apk_repository yunovo/zenportal/NxCustomSecurity yunovo/master

    handle_vairable
    print_variable
}

function re-sign() {

    local signapk_p=${script_p}/tools/security/signapk.jar

    for apk in ${signapk[@]} ; do

        if [[ -f ${pre_signapk_p}/${apk} && `get_file_type ${pre_signapk_p}/${apk}` == "apk" ]]; then
            java -jar ${signapk_p} ${tmpfs}/${nx_security}/platform.x509.pem ${tmpfs}/${nx_security}/platform.pk8 ${pre_signapk_p}/${apk} ${pre_signapk_p}/${apk}.sig
        else
            __err "pre signapk no found ..."
            return 1
        fi
    done
}

function main() {

    local pre_signapk_p=${tmpfs}/pre_signapk

    init

    # 1. 下载待签名apk
    for apk in ${signapk[@]} ; do
        curl tftp://${build_host}:${build_port}/${apk} --output ${pre_signapk_p}/${apk}
    done

    # 2. 重签名
    re-sign

    # 3. 上传签名apk
    for apk in ${signapk[@]} ; do
        curl -T ${pre_signapk_p}/${apk}.sig tftp://${build_host}:${build_port}
    done

    # 4. 清理动作
    if [[ -d ${pre_signapk_p} ]]; then
        rm -rf ${pre_signapk_p}
    fi
}

main $@