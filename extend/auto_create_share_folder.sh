#!/usr/bin/env bash

function main()
{
    local OLDP=`pwd`
    local share_p=/$1/share
    local folderN=(App App1 App2 System Drive Hardware Project Test Public Temp)

    local chmod_nu=""
    local chown_user=""

    if [[ ! -d ${share_p} ]];then
        sudo mkdir -p ${share_p}
    fi

    cd ${share_p} > /dev/null

    for n in ${folderN[@]}
    do
        if [[ ! -d ${n} ]];then
            echo "--> dd: $n"
            sudo mkdir ${n}
        fi

        case ${n} in

            Public)
                chmod_nu=755
                chown_user=Leader
                ;;

            Temp)
                chmod_nu=757
                chown_user=root
                ;;

            *)
                chmod_nu=750
                chown_user=${n}
                ;;
        esac

        echo ${chmod_nu}
        echo ${chown_user}

        echo "--------------"
        sudo chmod ${chmod_nu} ${n} -R
        sudo chown yunovo:${chown_user} ${n}/ -R
    done

    cd ${OLDP} > /dev/null

    sudo ln -s ${share_p} /share
}

main $@
