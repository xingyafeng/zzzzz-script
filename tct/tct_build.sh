#!/usr/bin/env bash

# 编译moden模块
function build_moden() {

    # 记录变量WORKSPACE
    tmpworkspace=${WORKSPACE}

    pushd ${project_path} > /dev/null

    if [[ -f linux_build.sh ]]; then
        unset WORKSPACE && bash linux_build.sh -a delhitf tf
    else
        log error "The linux_build.sh has no found ..."
    fi

    popd > /dev/null

    export WORKSPACE=${tmpworkspace}
}

function build_kernel() {

    make -j${JOBS} kernel
}