#!/usr/bin/env bash

apps_xml=fs/apps.xml

function auto_create_manifest_xml()
{
    local count=$1

    local main_xml=tools/main.xml
    local default_xml=fs/default.xml
    local string="    <project name=\"yunovo_packages/CarEngine\" path=\"yunovo_packages/apps/CarEngine\" />"
    local project_end="</manifest>"

    if [ "$count" ];then
        echo
        show_vip "    creat manifest start ..."
        echo
    else
        echo "count is null ! e.g. auto_create_manifest_xml count ..."
        return 1
    fi

    if [ ! -d fs ];then
        mkdir fs
    fi

    if [ -f $apps_xml ];then
        rm $apps_xml && touch $apps_xml
    else
        touch $apps_xml
    fi

    for ((i=1; i<=$count; i++))
    do
        if [ -f $apps_xml ];then
            echo $string >> $apps_xml
        fi
    done

    if [ -f $apps_xml ];then
        modify_packages_name
    fi

    if [ -f $default_path ];then
        cat $main_xml > $default_xml

        while read line;do
            echo "    $line" >> $default_xml
        done < $apps_xml

        echo >> $default_xml
        echo $project_end >> $default_xml
    fi

    echo
    show_vip "    creat manifest end ..."
    echo
}


function modify_packages_name()
{
    local count=1
    local appfs=fs/apps.txt

    if [ -f $appfs ];then
        :
    else
        echo "apps.txt is not exist !"
        return 1
    fi

    while read app;do
        show_vir "    ---> app = $app"

        while read p;do
            if [ "`echo $p | grep CarEngine`" ];then
                sed -i "${count}s/CarEngine/$app/g" $apps_xml
                let count++
                break
            fi
        done < $apps_xml
    done < $appfs
}
