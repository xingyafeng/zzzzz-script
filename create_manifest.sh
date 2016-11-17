#!/usr/bin/env bash

apps_xml=fs/apps.xml
appfs=fs/apps.txt

function auto_create_manifest_xml()
{
    if [ $# -lt 3 ];then
        echo
        show_vip "    creat manifest start ..."
        echo

    else
        echo "# is error ! please check it !"
        return 1
    fi

    local manifest_type=$1
    local count=`cat $appfs |wc -l`

    local main_xml=
    local default_xml=fs/default.xml
    local string="    <project name=\"yunovo_packages/CarEngine\" path=\"yunovo/packages/apps/CarEngine\" "
    local appstring="revision=\"master\" "
    local endstring="/>"
    local project_end="</manifest>"

    if [ "$count" ];then
        :
    else
        echo "count is null ! e.g. auto_create_manifest_xml count ..."
        return 1
    fi

    if [ "$manifest_type" == "k26" ];then
        main_xml=tools/k26_main.xml
    elif [ "$manifest_type" == "k86A" ];then
        main_xml=tools/k86A_main.xml
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

            if [ -n "$2" ];then
                echo $string$appstring$endstring >> $apps_xml
            else
                echo $string$endstring >> $apps_xml
            fi

        fi
    done

    if [ -f $apps_xml ];then
        modify_packages_name
    fi

    if [ -f $main_xml ];then
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
