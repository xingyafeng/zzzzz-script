#!/usr/bin/env bash

function main() {

    local prj=fs/aa.txt

    local board=
    local custom=
    local project=

    local prj_name=

    # touch empty file
    :> ver.log
    :> Ver.log

    ssh jenkins@f1.y find /public/share/ROM/share_test/test -name sdupdate.zip | sort > fs/path.txt

    while read p;do

        board=`echo   ${p} | awk -F/ '{print $1}'`
        custom=`echo  ${p} | awk -F/ '{print $2}' | tr 'a-z' 'A-Z'`
        project=`echo ${p} | awk -F/ '{print $3}' | tr 'a-z' 'A-Z'`

        prj_name="${board}_${custom}-${project}"

        echo "----yunovo ${board}_$custom-$project"

        while read path;do
            echo ${path} | grep ${prj_name} | awk -F/ '{ print $(NF-1) } ' | sed s/_full_and_ota//g >> ver.log
        done < fs/path.txt

    done < ${prj}

    sort -n ver.log | uniq >> Ver.log
}

main $@