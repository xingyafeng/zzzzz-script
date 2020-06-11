#!/usr/bin/env bash

function main()
{
    if [[ ! -d add-ons ]];then
        echo "add-ons folder no found !"
        echo
        return 1
    fi

    if [[ ! -f mkstubs.jar ]];then
        echo "mkstubs.jar no found !"
        echo
        return 1
    fi

    echo
    echo "start ..."
    echo

    for j in `ls $(find add-ons/  ! -name signapk.jar -a -name \*.jar)`
    do
        prefix=${j%.*}
        java -jar tools/mkstubs.jar ${j} ${prefix}_0.jar +*

        if [[ -e ${prefix}_0.jar ]];then
            mv ${prefix}_0.jar ${j}
        fi

        echo '--------------------------------' && echo
    done

    echo
    echo "end ..."
    echo
}
main $@
