#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "`dirname $0`/jenkins/jenkins_init.sh"

parse_all_patchset()
{
    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    echo "INFO: Enter ${FUNCNAME[0]}()"

    pushd ${tmpfs}/gerrit > /dev/null

    if [[ -n "$GERRIT_TOPIC" ]]; then

        ssh-gerrit query --current-patch-set "intopic:^.*${GERRIT_TOPIC}.* branch:${GERRIT_BRANCH}" \
            --format json > changeid.json

        if [[ "$?" -eq 0 ]]; then

            python ${script_p}/parse_change_infos.py changeid.json
            if [[ "$?" -ne 0 ]]; then
                log error "parse Topic: $GERRIT_TOPIC infomation failed"
            fi
        else
            echo "Error occured when link ${GERRIT_HOST}."
            exit 1
        fi
    fi

    if [[ -n "$GERRIT_TOPIC" ]]; then
        if [[ -s change_number_list.txt ]]; then
            change_number_list=($(cat change_number_list.txt | sort -n))
        else
            echo "parse Topic: $GERRIT_TOPIC change number list null"
            echo "${GERRIT_CHANGE_URL} The patch status is Abandoned or Merged or already verified +1 by gerrit trrigger auto compile, no need to build this time."
            ssh -o ConnectTimeout=32 -p 29418  ${username}@${GERRIT_HOST} gerrit review  -m '"Warning_Log_URL:"'${BUILD_URL}'"/console The patchset has been Abandoned or Merged or already verified +1 by gerrit trigger auto compile, so no need to build this time."'  ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
            exit 0
        fi
    else
        change_number_list=${GERRIT_CHANGE_NUMBER}
    fi

    popd > /dev/null

    echo "change_number_list = " ${change_number_list[@]}
    echo "INFO: Exit ${FUNCNAME[0]}()"

    trap - ERR
}

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

    local GERRIT_TOPIC='ALM-10094805'
    local GERRIT_BRANCH='msm7250-q0-seattlevzw-la1.1_prepaid'
    local GERRIT_HOST='sz.gerrit.tclcom.com'

    local change_number_list=

    log debug "start ..."

    _echo "main"

    parse_all_patchset

    echo "change_number_list = " ${change_number_list[@]}

    log debug "end ..."

    trap - ERR
}

main "$@"