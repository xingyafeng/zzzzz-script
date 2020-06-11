#!/usr/bin/env bash

# 当前Shell文件名
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

# 初始化
function init() {

    # 1. 解压otatools.zip

    # 2. 配置环境变量

    # 3. 修改 ota_scatter.txt文件路径
    if [[ -f ${target_dir}/target_files/META/ota_scatter.txt ]]; then
        cust_dir=`cat ${target_dir}/target_files/SYSTEM/build.prop | grep ^ro.product.device= | awk -F '=' '{print $2}'`
        mkdir -p out/target/product/${cust_dir}
        cp -vf ${target_dir}/target_files/META/ota_scatter.txt out/target/product/${cust_dir}
    fi
}

# 制作差分包
function make_inc() {

    local cmd=

    cmd="./otatools/releasetools/ota_from_target_files -v -p otatools/linux-x86 -k tools/security/testkey -i v1.00.zip v1.01.zip OTA.zip"

    eval ${cmd}

    if [[ $? -eq 0 ]]; then
        echo successful ...
    fi
}

# 上传文件服务器
function rsync_to_server() {
    :
}

# 主函数
function main() {

    init

    make_inc

    rsync_to_server
}

main "$@"