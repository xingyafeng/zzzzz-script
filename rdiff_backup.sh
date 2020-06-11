#!/usr/bin/env bash

#################
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

## 增量备份
function backup_jenkins()
{
    if [[ -d ${local_p} ]];then
        rdiff-backup -v5 ${local_p} ${server_address}::${service_p}
    fi

    show_vip "-- done --"
}

## 删除差分包, 一月前的差分包
function remove_increments()
{
    rdiff-backup --force --remove-older-than ${dt}B ${server_address}::${service_p}
    echo
}

function main()
{
    local dt=60
    local counts=""
    local server_address=jenkins@s1.y
    local local_p=/media/s2/hdd3/jenkins/.jenkins
    local service_p=/home/jenkins/rdiff-backup/jenkins

    if [[ `hostname` == "s2" ]];then

        echo
        show_vip "--> rdiff-backup start ."

        rdiff-backup --test-server ${server_address}::${service_p}
        echo

        counts=`rdiff-backup -l ${server_address}::${service_p} | grep increments | wc -l`

        show_vig "@@@ counts: $counts"

        ## 增量备份
        backup_jenkins

        if [[ ${counts} -gt ${dt} ]];then
            ## 删除差分包，保证硬盘空间.
            remove_increments
        fi

        echo
        show_vip "--> rdiff-backup stop ."
    fi
}

main
