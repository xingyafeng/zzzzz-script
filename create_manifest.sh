#!/usr/bin/env bash

function creat_manifest_xml()
{
    local manifest_path=fs/manifest.xml
    local string="<project name=\"yunovo_packages/CarEngine\" path=\"yunovo_packages/apps/CarEngine\" revision=\"master\" />"

    if [ ! -d fs ];then
        mkdir fs
    fi

    if [ -f $manifest_path ];then
        rm $manifest_path && touch $manifest_path
    else
        touch $manifest_path
    fi

    for ((i=1; i<=116; i++))
    do
        if [ -f $manifest_path ];then
            echo $string >> $manifest_path
        fi
    done

    if [ -f $manifest_path ];then
        modify_packages_name
    fi
}


function modify_packages_name()
{
    local count=1
    local tmp=fs/tmp.txt
    local manifest_path=fs/manifest.xml

    while read app;do
        echo "---> app = $app"

        while read p;do
            if [ "`echo $p | grep CarEngine`" ];then
                sed -i "${count}s/CarEngine/$app/g" $manifest_path
                let count++
                break
            fi
        done < $manifest_path
    done < $tmp
}
