#!/usr/bin/env bash

## 自动创建manifest
function auto_create_manifest_xml()
{
    if [[ $# -lt 2 ]];then
        echo
        show_vip "## creat manifest start ..."
        echo

    else
        echo "# is error ! please check it !"
        return 1
    fi

    local board=""
    local count=""

    local main_xml=""
    local default_xml=fs/default.xml
    local string="    <project name=\"yunovo_packages/CarEngine\" path=\"yunovo/packages/apps/CarEngine\" "
    local appstring="revision=\"master\" "
    local endstring="/>"
    local project_end="</manifest>"

    local apps_xml=fs/apps.xml
    local appfs=fs/apps.txt
    local board_list=("mtk6580" "mtk5735")

    if [[ -f "$appfs" ]];then
        count=`cat ${appfs} | wc -l`

        if [[ -z "$count" ]];then
            echo "count is NULL ."
            return 1
        fi
    fi


    _inlist=(${board_list[@]})
    show_vir "select yunovo board : "
    select_choice board

    if [[ "$board" == "mtk6580" ]];then
        main_xml=config/k26_main.xml
    elif [[ "$board" == "mtk5735" ]];then
        main_xml=config/k86A_main.xml
    fi

    if [[ ! -d fs ]];then
        mkdir fs
    fi

    if [[ -f ${apps_xml} ]];then
        rm ${apps_xml} && touch ${apps_xml}
    else
        touch ${apps_xml}
    fi

    for ((i=1; i<=$count; i++))
    do
        if [[ -f ${apps_xml} ]];then

            if [[ -n "$1" ]];then
                echo ${string}${appstring}${endstring} >> ${apps_xml}
            else
                echo ${string}${endstring} >> ${apps_xml}
            fi

        fi
    done

    if [[ -f ${apps_xml} ]];then
        modify_packages_name
    fi

    if [[ -f ${main_xml} ]];then
        cat ${main_xml} > ${default_xml}

        while read line;do
            echo "    $line" >> ${default_xml}
        done < ${apps_xml}

        echo >> ${default_xml}
        echo ${project_end} >> ${default_xml}
    fi

    echo
    show_vip "## create manifest end ..."
    echo
}


function modify_packages_name()
{
    local count=1

    if [[ -f ${appfs} ]];then
        :
    else
        echo "apps.txt is not exist !"
        return 1
    fi

    while read app;do
        show_vir "    ---> app = $app"

        while read p;do
            if [[ "`echo ${p} | grep CarEngine`" ]];then
                sed -i "${count}s/CarEngine/$app/g" ${apps_xml}
                let count++
                break
            fi
        done < ${apps_xml}
    done < ${appfs}
}
