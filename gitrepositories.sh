#!/usr/bin/env bash

# if error; then exit
set -e

## 当前Shell文件名
shellfs=$0

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

# 删除分支、标签、隐式分支
function remove_refs() {

    local pre_ref="refs/"

    cd ${git_dir_p}/${f}.git > /dev/null

    git update-ref -d ${pre_ref}/${ref}

    cd - > /dev/null
}

# 移除相同分支
function remove_the_same_branch() {

    cd ${log_dir} > /dev/null

    for f in `ls` ; do
        while read ref;do
            echo "the same ref: ${pre_ref}/${ref}"
        done < ${log_dir}/`get_file_name ${f}`.the_same_branch.log
    done

    cd - > /dev/null
}

# 下载所有refs
function download_all_refs() {

    if [[ ! "`git remote`" =~ ${alias} ]]; then
        git remote add ${alias} ssh://${git_username}@${gerrit_server}:${gerrit_port}/${alias}/${project}
    fi

    if [[ "${has_backup}" == "true" ]]; then
        git config remote.${alias}.fetch +refs/*:refs/`echo ${alias} | tr '[:upper:]' '[:lower:]'`/*
    elif [[ ${has_backup} == "false" ]]; then
        git config remote.${alias}.fetch +refs/*:refs/*
    fi

    git fetch -q ${alias} && git remote remove ${alias}

    show_vip "${alias}/${project} ----- end"
}

function doconfig() {

    if [[ ! -d ${git_dir}  ]];then
        git init ${git_dir} --bare
    fi

    cd ${git_dir} > /dev/null

    __green__ "doconfig: ---- ${alias} -- ${alias}/${project} -- ${git_dir} ---- has_backup = ${has_backup}"

    download_all_refs

    cd - > /dev/null
}

# 保存所有的refs/* 下面的所以 '*' 的内容。
function save_all_refs() {

    cd ${git_dir} > /dev/null

    for ref in `git show-ref | awk '{ print $NF}' | grep -vE 'meta/config|tags/' | sed 's#refs/##g'` ; do
        if [[ ${ref} =~ `echo ${alias} | tr '[:upper:]' '[:lower:]'` ]]; then
            echo ${ref} | sed "s#`echo ${alias} | tr '[:upper:]' '[:lower:]'`/##g" >> ${log_dir}/${project}.log
        fi
    done

    cd - > /dev/null
}

####################################################################################################
# 功能： 找出相同的分支名 [ build|tag|yunovo/empty|meta/config ]
#        找出所有项目中存在相同的heads、tags、changes、build、other 及显示的隐式的分支
# 说明：
#   1.下载refs/tags, 由于tags的特殊性，在git时间线上是唯一。相同的tags是完全一样
#   2.下载build 由于jenkins推送的已时间点为标签故是唯一的。 相同的build也是完全一样
#   3.下载meta/config 是权限配置文件
#   4.下载yunovo/empty 是空分支，创建的时候都是完全一样的
#
####################################################################################################
# 显示相同的分支
function display_the_name_branch() {

    cd ${log_dir} > /dev/null

    for f in `ls` ; do
        cat ${f} | sort | uniq -d >> ${log_dir_the_same_branch}/`get_file_name ${f}`.the_same_branch.log
    done

    cd - > /dev/null
}

# 打印相同分支
function print_the_name_branch() {

    cd ${log_dir_the_same_branch} > /dev/null

    for f in `ls *.the_same_branch.log` ; do
        __green__ "${f} :"
        cat ${f}
        show_viy "---- `get_file_name $(get_file_name ${f})`"
    done

    cd - > /dev/null
}

# 备份所有的refs
function backup_git_repositories() {

    has_backup=true

    for p in `ssh-gerrit gerrit ls-projects | egrep "A36/android|D1402|K26|k1402/alps|k18|k570e|k86/|k66|k6806|k86A|xt273|m170m|m66|s802"`
    do
        alias=`dirname ${p}`
        project=`basename ${p}`
        git_dir=${git_dir_p}/${project}.git

        if [[ "${alias}"  == "A36/android" ]]; then
            doconfig
            save_all_refs
        else
            doconfig
            save_all_refs
        fi
    done

    for p in `ssh-gerrit gerrit ls-projects | egrep '^platform' | awk -F/ '{print $1 "/" $2}' | sort | uniq`
    do
        alias=`dirname ${p}`
        project=`basename ${p}`

        while read prj ;do

            if [[ ${prj} == ${project} ]]; then
                git_dir=${git_dir_p}/${project}.git

                doconfig
                save_all_refs
            fi
        done < ${script_p}/config/micro.txt
    done

    display_the_name_branch
}

# 下载整合仓库(去重后的完整仓库)
function download_git_repositories() {

    has_backup=false

    show_vip "--> download git repositories ..."

    for p in `ssh-gerrit gerrit ls-projects | egrep "A36/android|D1402|K26|k1402/alps|k18|k570e|k86/|k66|k6806|k86A|xt273|m170m|m66|s802"`
    do
        alias=`dirname ${p}`
        project=`basename ${p}`
        git_dir=${git_dir_p}/${project}.git

        if [[ "${alias}"  == "A36/android" ]]; then
            doconfig
        else
            doconfig
        fi
    done

    for p in `ssh-gerrit gerrit ls-projects | egrep '^platform' | awk -F/ '{print $1 "/" $2}' | sort | uniq`
    do
        alias=`dirname ${p}`
        project=`basename ${p}`

        while read prj ;do

            if [[ ${prj} == ${project} ]]; then
                git_dir=${git_dir_p}/${project}.git

                doconfig
            fi
        done < ${script_p}/config/micro.txt
    done
}

function init() {

    if [[ ! -d ${git_dir_p} ]]; then
        mkdir -p ${git_dir_p}
    fi

    if [[ ! -d ${log_dir} ]];then
        mkdir -p ${log_dir}
    fi

    if [[ ! -d ${log_dir_the_same_branch} ]];then
        mkdir -p ${log_dir_the_same_branch}
    fi

    if [[ -d ${log_dir} ]]; then
        rm -rf ${log_dir}/*
    fi

    if [[ -d ${git_dir_p} ]]; then
        rm ${git_dir_p}/* -rf
    fi

    if [[ -d ${log_dir_the_same_branch} ]];then
        rm ${log_dir_the_same_branch}/* -rf
    fi

}

####################################################################################################
#
# 整合代码仓库步骤：
#   1. 找出所有项目中存在相同的heads、tags、changes、build、other
#   2. 去重 (重复的分支或隐式分支应重新创建，增加项目前缀已区分)
#
# 仓库有：
# A36/android|D1402|K26|k1402/alps|k18|k570e|k86/|k66|k6806|k86A|xt273|m170m|m66|s802
#
#    e.g alias/project ==> K26/abi
#
####################################################################################################
function main() {

    local alias=
    local project=
    local git_dir_p=${tmpfs}/git
    local log_dir=${tmpfs}/gitrepositories
    local log_dir_the_same_branch=${tmpfs}/the_same_branch

    local has_backup=

    init
    backup_git_repositories
    download_git_repositories
    print_the_name_branch
}

main "$@"
