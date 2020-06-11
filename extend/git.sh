#!/usr/bin/env bash

PRJ_ROOT=/home/yafeng/workspace/git
DEST_ROOT=/home/yafeng/workspace/tt

ssh_link=ssh://xingyafeng@gerrit.y:29419

function doconfig()
{
    prj_abs_path=${projectP}/${projectN}
    prj_prefix_path=${projectP}

    prj_prefix_path=`echo ${prj_prefix_path} | tr '[:upper:]' '[:lower:]'`

    echo "$prj_prefix_path --- $prj_abs_path"

    if [[ ! -d  "$DEST_ROOT/${projectN}.git"  ]];then
        git init ${DEST_ROOT}/${projectN}.git --bare
        echo "init---"
    fi

    cd ${DEST_ROOT}/${projectN}.git

    git remote add ${prj_prefix_path} ${ssh_link}/${prj_abs_path}
    git config remote.${prj_prefix_path}.fetch refs/*:refs/${prj_prefix_path}/*
    git fetch ${prj_prefix_path}

    cd -
}

##
function get_name()
{
    for n in `ls`
    do
        n=${n%.*}
        echo "::n -> $n"
        echo ${n} >> ${ff}
    done

}

function main()
{
    local ff_name=config/project_list_name.txt
    local ff_path=config/project_list_path.txt

    echo "---- start ..."
    echo

    while read projectP;do
        while read projectN;do

            echo ${projectP}/${projectN}
            doconfig
        done < ${ff_name}
    done < ${ff_path}

    echo
    echo "---- end ..."
}

main
