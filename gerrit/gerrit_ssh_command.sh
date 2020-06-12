#!/usr/bin/env bash

####################################################################################################
#  功能  ： 获取对应组的信息,在哪些项目上使用啦。并列出具体项目信息、
#  函数名：
#  e.g.
#       1. ssh-gerrit-get-projects  group_framework
#       2. ssh-gerrit-get-projects  group_app
#
####################################################################################################
function ssh-gerrit-get-projects() {

    local groups=

    if [[ -n "$1" ]]; then
        groups=$1
    else
        echo ""
        echo "ssh-gerrit-get-projects args1"
        echo
        echo "    args1 : 查询的组的信息"
        echo
        echo "    e.g."
        echo "        1. ssh-gerrit-get-projects  group_framework"
        echo "        2. ssh-gerrit-get-projects  group_app"
        echo
        return 0
    fi

    for p in `ssh-gerrit gerrit ls-projects`
    do
        for g in `ssh-gerrit gerrit ls-groups -p ${p}`;do
            if [[ ${g} == "${groups}" ]]; then
                echo "${p} => ${groups}"
            fi
        done
    done
}

####################################################################################################
#  功能  ： 配置项目的继承关系 单个配置 < 注：不支持批量 >
#  函数名： set_project_parent
#  e.g.
#       1. set_project_parent demo1 demo # 配置项目demo1的父亲是demo及表示demo1从demo继承
#
####################################################################################################
# the_project 儿子
# the_parent 父亲
function set_project_parent() {

    local the_project=
    local the_parent=

    if [[ $# -eq 2 ]]; then
        the_project=$1
        the_parent=$2
    else
        echo ""
        echo "ssh-gerrit-set-project-parent args1 args2"
        echo
        echo "    args1 : 子项目,即当前项目"
        echo "    args2 : 父项目,需要设置子项目的父项目"
        echo
        echo "    e.g."
        echo "                                         子项目 父项目 "
        echo "        1. ssh-gerrit-set-project-parent  demo1   demo "
        echo
        return 0
    fi

    ssh-gerrit gerrit set-project-parent ${the_project} --parent ${the_parent}
}

####################################################################################################
#  功能  ： 配置项目的继承关系 单个配置 < 注：支持批量 >
#  函数名： ssh-gerrit-set-project-parent
#  e.g.
#       1. ssh-gerrit-set-project-parent demo1 demo # 配置项目demo1的父亲是demo及表示demo1从demo继承
#
####################################################################################################
function ssh-gerrit-set-project-parent() {

    local shell=${tmpfs}/shell.sh

    local the_projects=
    local the_parent=

    if [[ $# -eq 2 ]]; then
        the_projects=$1
        the_parent=$2
    else
        echo ""
        echo "ssh-gerrit-set-project-parent args1 args2"
        echo
        echo "    args1 : 子项目,即当前项目"
        echo "    args2 : 父项目,需要设置子项目的父项目"
        echo
        echo "    e.g."
        echo "                                         子项目 父项目 "
        echo "        1. ssh-gerrit-set-project-parent demo1   demo  "
        echo
        return 0
    fi

    touch_empty_shell

    for the_project in ${the_projects[@]} ; do
        if [[ -f ${shell} ]]; then
            echo "ssh -p 29419 xingyafeng@gerrit.y gerrit set-project-parent ${the_project} --parent ${the_parent}" >> ${shell}
        fi
    done

    if [[ -x ${shell} ]]; then
        ${shell}
    else
        __err "bash: ${shell}: 权限不够"
    fi
}

####################################################################################################
#  功能  ： 查看项目的继承关系
#  函数名： ssh-gerrit-ls-projects-t
#  e.g.
#       1. ssh-gerrit-ls-projects-t "prj1|prj2|***"
#
####################################################################################################
function ssh-gerrit-ls-projects-t {

    local the_projects=

    if [[ $# -eq 1 ]]; then
        the_projects=$1
    else
        echo ""
        echo "ssh-gerrit-ls-projects-t \"prj1|prj2|***\" "
        echo
        echo "    prj1 : 项目,即查询项目名称"
        echo "    prj2 : 同上"
        echo
        echo "    e.g."
        echo "        1. ssh-gerrit-ls-projects-t \"demo|ReadOnly|All-Projects\""
        echo
        return 0
    fi

    ssh-gerrit gerrit ls-projects -t | egrep "${the_projects}"
}