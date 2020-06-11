#!/usr/bin/env bash

set -e

function push_to_gerrit() {

    if [[ ${m} == "K26" ]]; then
        repo forall -c git push origin HEAD:refs/heads/${m}/master
    else
        repo forall -c git push origin HEAD:refs/heads/`echo ${m} | tr 'A-Z' 'a-z'`/master
    fi
}

function download_for_m() {

    if [[ ! -d ${m} ]]; then
        mkdir -p ${m}
    fi

    cd ${m} > /dev/null

    repo init -u ssh://xingyafeng@gerrit.y:29419/manifest -m ${m}.xml
    repo sync -c -d --no-tags --force-sync
    push_to_gerrit

    cd - > /dev/null
}

function download_for_branch() {

    if [[ ! -d ${m} ]]; then
        mkdir -p ${m}
    fi

    cd ${m} > /dev/null

    if [[ "${m} != K26" ]]; then
        m=`echo ${m} | tr 'A-Z' 'a-z'`
    fi

    repo init -u ssh://xingyafeng@gerrit.y:29419/manifest -b ${m}/master
    repo sync -c -d --no-tags --force-sync

    cd - > /dev/null
}

function main() {

    local mani_xml="A36 D1402 K26 k1402 k18 k570e k86 k66 k6806 k86A xt273 m170m m66 s802"

    echo "---- start "
    echo

    for m in ${mani_xml} ; do

        echo "----  ${m}/master "

        if [[ -n "${m}" ]]; then
            download_for_branch
        fi
    done

    echo
    echo "---- end "
}

main $@