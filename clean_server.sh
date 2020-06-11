#!/usr/bin/env bash

function clean_server()
{
    local TOPDIR='/local'

    if [[ -d ${TOPDIR}/tools_int ]];then

        pushd /local/tools_int > /dev/null
        flock /local/tools_int -c "git reset --hard HEAD && git pull"
        popd > /dev/null

        python ${TOPDIR}/tools_int/misc/CleanDeliveryDir.py ${TOPDIR}/release 7
        python ${TOPDIR}/tools_int/misc/CleanBuildDir.py
        python ${TOPDIR}/tools_int/misc/CleanCache.py
    else
        echo "The tool_init folder not found ..."
    fi
}

function main() {

    clean_server
}

main "$@"