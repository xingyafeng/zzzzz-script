#!/usr/bin/env bash

#####
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

function rsync_jenkins()
{
    if [[ -d ${local_p} ]];then
        rsync -av ${local_p} jenkins@f1.y:${service_p}
    fi

    show_vip "-- done --"
}

function main()
{
    local local_p=/media/s2/hdd3/jenkins/.jenkins
    local service_p=/home/jenkins/.js

    if [[ `hostname` == "s2" ]];then

        echo
        show_vip "--> rsync start ."

        ## 同步备份Jenkins 数据库文件
        rsync_jenkins

        show_vip "--> rsync stop ."
    fi
}

main
