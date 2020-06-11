#!/bin/bash

### color red
function show_vir
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;31m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color green
function show_vig
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;32m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color yellow
function show_viy
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;33m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color blue
function show_vib
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;34m$ret \e[0m"
        done

        echo
        echo
    fi
}

### color purple
function show_vip
{
    if [[ "$1" ]]
    then
        for ret in "$@"; do
            echo -e -n "\e[1;35m$ret \e[0m"
        done

        echo
        echo
    fi
}

## 清理动作
function remove_increments_jenkins()
{
    script -q -f -c "rdiff-backup --force --remove-older-than ${dt}B ${backup_server_address}::${jenkins_rdiff_backup_p}" > ${tmpfs}
}

## 备份jenkins数据 rdiff-backup
function rdiff_backup_jenkins()
{
    if [[ -d ${local_p} ]];then
        script -q -f -c "rdiff-backup -v5 ${local_p} ${backup_server_address}::${jenkins_rdiff_backup_p}" > ${tmpfs}
    fi
}

## 备份jenkins数据 rsync
function rsync_backup_gerrit()
{
    if [[ -d ${local_p} ]];then
        script -q -f -c "rsync -av --force --delete ${local_p} ${backup_server_address}:${jenkins_rsync_backup_p}" > ${tmpfs}
    fi
}

## 查看数据备份的状态
function file_jenkins()
{
    script -q -f -c "rdiff-backup -l ${backup_server_address}::${jenkins_rdiff_backup_p}" > ${tmpfs}
}

function main()
{
    local userN="`git config --get user.name`"
    local hostN=f1.y

    local tmpfs=/tmp/f.jenkins
    local counts=""
    local dt=60

    local backup_server_address=${userN}@${hostN}
    local jenkins_rsync_backup_p=/home/jenkins/.jenkins-backup/rsync-backup
    local jenkins_rdiff_backup_p=/home/jenkins/.jenkins-backup/rdiff-backup
    local local_p=/media/s2/hdd3/jenkins/.jenkins

    if [[ ! -p ${tmpfs} ]];then
        mkfifo ${tmpfs}
        chmod go+w ${tmpfs}
    fi

    while true;do

        if read cmd < ${tmpfs};then
            if [[ -n "$cmd" ]];then
                show_vig "recv : $cmd"
                case ${cmd} in

                    rsync)
                        ## 开始备份gerrit
                        rsync_backup_gerrit
                        ;;

                    rfile)
                        ## 查看差分信息
                        file_jenkins
                        ;;

                    rdiff)
                        ## 开始备份gerrit
                        rdiff_backup_jenkins
                        ;;

                    remove)
                        counts=`rdiff-backup -l ${backup_server_address}::${jenkins_rdiff_backup_p} | grep increments | wc -l`

                        if [[ ${counts} -gt ${dt} ]];then
                            ## 删除60天之前的差分备份. 若不超过60,查看差分信息
                            remove_increments_jenkins
                        else
                            ## 查看差分信息
                            file_jenkins
                        fi

                        ;;
                    *)
                        echo -e  "$cmd, Do not match it ...\n" > ${tmpfs}
                        show_vir "$cmd, Do not match it ..."
                        ;;
                esac

                echo "--done--" > ${tmpfs}
            else
                show_vir "cmd is NULL ..."
            fi
        fi

        show_vip "--done--"
    done
}

echo "server PID:$$"
echo "-------------------"
main
