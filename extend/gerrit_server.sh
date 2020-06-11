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

function f_sleep()
{
    sleep 2
}

## 备份gerrit 仓库和数据库.
function rdiff_backup_gerrit()
{
    if [[ -d ${root_p} && -d ${rdiff_p} ]];then
        script -q -f -c "rdiff-backup -v5 --include $root_p/$gerrit_p --include $root_p/$mysql_p --exclude '**' $root_p ${rdiff_p}" > ${tmpfs}

        echo "gerrit rdiff-back end." > ${tmpfs}
    fi
}

## 删除过期的差分文件，两个月前.
function remove_increments_gerrit()
{
    if [[ -d ${rdiff_p} ]];then
        script -q -f -c "rdiff-backup --force --remove-older-than ${dt}B ${rdiff_p}" > ${tmpfs}
    fi
}

## 查看差分包
function file_gerrit()
{
    if [[ -d ${rdiff_p} ]];then
        script -q -f -c "rdiff-backup -l ${rdiff_p}" > ${tmpfs}
    fi
}

## 完整同步 gerrit 仓库和数据库.
function rsync_backup_gerrit()
{
    if [[ -d "$root_p" && -d "$rsync_p" ]];then
        ## 1. 同步git仓库
        script -q -f -c "rsync -av $root_p/$gerrit_p ${rsync_p}" > ${tmpfs}

        echo "gerrit rsync end." > ${tmpfs}

        ## 2. 同步gerrit数据库
        script -q -f -c "rsync -av $root_p/$mysql_p ${rsync_p}" > ${tmpfs}

        echo "mysql rsync end." > ${tmpfs}

        ## 3. 同步至新服务器
        script -q -f -c "rsync -av /media/root/rsync_backup/projects/ yunovo@s3.y:/media/yunovo/bcache0/repositories/git/projects" > ${tmpfs}

        echo "projects rsync end." > ${tmpfs}

    fi
}

function stop_gerrit()
{
    script -q -f -c "/etc/init.d/apache2 stop" > ${tmpfs}
    echo "apache2 stop." > ${tmpfs}
    script -q -f -c "/etc/init.d/gerrit stop"  > ${tmpfs}
    echo "gerrit stop." > ${tmpfs}
    script -q -f -c "/etc/init.d/mysql stop"   > ${tmpfs}
    echo "mysql stop." > ${tmpfs}
}

function start_gerrit()
{
    script -q -f -c "/etc/init.d/mysql start"   > ${tmpfs}
    echo "mysql start." > ${tmpfs}
    script -q -f -c "/etc/init.d/gerrit start"  > ${tmpfs}
    echo "gerrit start." > ${tmpfs}
    script -q -f -c "/etc/init.d/apache2 start" > ${tmpfs}
}

## 更新add-ons仓库
function update_add-ons()
{
    local OLDP=`pwd`

    cd ${addones_git_dir} > /dev/null

    if [[ -n "`git status -s`" ]];then
        git checkout -- .
    fi

    git pull -q

    cd ${OLDP} > /dev/null
}

## 编译add-ons插件
function make_add-ons()
{
    script -q -f -c "/media/yunovo/bcache0/add-ons/tools/onekey_generate.sh" > ${tmpfs}
}

## 更新Javadoc仓库
function update_javadoc()
{
    local OLDP=`pwd`

    cd ${javadoc_git_dir} > /dev/null

    thisFiles=`git diff --cached --name-only`
    if [[ -n "$thisFiles" ]];then
        git reset HEAD . ###recovery for cached files
    fi

    thisFiles=`git clean -dn`
    if [[ -n "$thisFiles" ]]; then
        git clean -df
    fi

    thisFiles=`git diff --name-only`
    if [[ -n "$thisFiles" ]]; then
        git checkout HEAD ${thisFiles}
        git checkout -- .
    fi

    script -q -f -c "git pull" > ${tmpfs}

    cd ${OLDP} > /dev/null
}

## 同步yunos代码
function sync_yunos()
{
    local OPWD=$(pwd)

    if [[ -d ${aliyunos_dir} ]];then
        cd ${aliyunos_dir} > /dev/null

        if [[ -x auto_sync_yunos.sh ]]; then
            script -f -q -c "./auto_sync_yunos.sh" > ${tmpfs}
        fi

        cd ${OPWD} > /dev/null
    fi
}

function main()
{
    local tmpfs=/tmp/f.ss
    local counts=""
    local dt=60

    local bcache_p=/media/yunovo/bcache0
    local root_p=${bcache_p}/repositories/git/projects
    local backup_p=/media/yunovo/bk1

    local gerrit_p=projects
    local mysql_p=mysql_db

    ## 备份路径
    local rdiff_p=${backup_p}/rdiff_backup
    local rsync_p=${backup_p}/rsync_backup

    local addones_git_dir=${bcache_p}/add-ons
    local aliyunos_dir=${bcache_p}/repositories/git/mirror

    local javadoc_git_dir=/home/git/repositories/javadoc/javadoc

    if [[ ! -p ${tmpfs} ]];then
        mkfifo ${tmpfs}
        chmod go+w ${tmpfs}
    fi

    if [[ ! -d "$rdiff_p" ]];then
        mkdir -p ${rdiff_p}
    fi

    if [[ ! -d "$rsync_p" ]];then
        mkdir -p ${rsync_p}
    fi

    while true;do

        if read cmd < ${tmpfs};then

            if [[ -n "$cmd" ]];then
                show_vig "recv : $cmd"
                case ${cmd} in

                    javadoc)
                        if [[ -d ${javadoc_git_dir}/.git ]];then
                            update_javadoc
                        else
                            script -q -f -c "git clone -b master ssh://yunovo@gerrit-in.yunovo.cn:29419/yunovo/javadoc ${javadoc_git_dir}/" > ${tmpfs}
                        fi
                        ;;

                    aliyunos)
                        sync_yunos
                        ;;

                    add-ons)
                        update_add-ons

                        make_add-ons
                        ;;

                    sync)
                        ## 停止gerrit服务
                        stop_gerrit

                        ## 开始备份gerrit
                        rsync_backup_gerrit

                        ## 启动gerrit服务
                        start_gerrit
                        ;;

                    file)
                        ## 查看差分信息
                        file_gerrit
                        ;;

                    backup)
                        ## 停止gerrit服务
                        stop_gerrit

                        ## 开始备份gerrit
                        rdiff_backup_gerrit

                        ## 启动gerrit服务
                        start_gerrit
                        ;;

                    remove)
                        counts=`rdiff-backup -l ${rdiff_p} | grep increments | wc -l`

                        if [[ ${counts} -gt ${dt} ]];then
                            ## 删除60天之前的差分备份. 若不超过60,查看差分信息
                            remove_increments_gerrit
                        else
                            ## 查看差分信息
                            file_gerrit
                        fi

                        ;;
                    *)
                        echo -e " $cmd, Do not match it ...\n" > ${tmpfs}
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
