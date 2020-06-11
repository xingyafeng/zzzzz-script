#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

# init function
. "`dirname $0`/yunovo_init.sh"

# 执行submit, 审核进gerrit, 即合并代码
function commit() {

    declare -a array_ref

    refs=(`ssh-gerrit gerrit query --current-patch-set status:open owner:${owner} branch:${b} project:${the_project} | grep ref | sort | awk '{print $NF}'`)
    refs_id=(`ssh-gerrit gerrit query --current-patch-set status:open owner:${owner} branch:${b} project:${the_project} | grep ref | sort | awk '{print $NF}'| awk -F/ '{ print $(NF-1)} ' | sort`)

    for id in ${refs_id[@]} ; do
        for ref in ${refs[@]} ; do
            if [[ "${ref}" =~ "${id}" ]]; then
                array_ref[${id}]="${ref}"
            fi
        done
    done

    for id in ${refs_id[@]} ; do
        #echo "ref : array_ref[${id}]=${array_ref[${id}]}"
        commit=(`ssh-gerrit gerrit query --current-patch-set status:open owner:${owner} branch:${b} project:${the_project} | grep "${array_ref[${id}]}" -B 5 | grep revision | awk '{print $NF}'`)
        __blue__ "the_project:${the_project}; branch:${b}; ref:${array_ref[${id}]}; commit:${commit}"
        ssh-gerrit gerrit review --code-review +2 --submit --project ${the_project} ${commit}
        show_vir "--> ${the_project} submit ..."
    done
}

## 1. 通过具体项目的分支, 来确定提交的 ref id 个数。
## 2. 通过 ref 确定 commit id
## 3. 审核补丁
function review() {

    local commit=
    local branch=
    local refs=

    branch=(`ssh-gerrit gerrit ls-user-refs -u xingyafeng -p ${the_project} --only-refs-heads | cut -d '/' -f 3-`)
    for b in ${branch[@]} ; do
        if [[ -n "${the_branch}" ]]; then
            if [[ "${the_branch}" == "${b}" ]]; then
                commit
            fi
        else
            commit
        fi
    done
}

####################################################################################################
##  功能  ： 批量审核相关项目
##  函数名： ssh-gerrit-review
##  e.g
##      1. ./$script_p/gerrit/ssh-gerrit-review.sh
##
##  代码自动审核,步骤：
##  1. 查找需要审核的项目，通过 status:open|project|owner|branch 定位项目
##  2. 查找commit id , 通过 status|owner|project 定位 id
##  3. 审核 项目对应的补丁 及commit id
##
####################################################################################################
function main() {

    local owner=
    local the_project=
    local the_curr_project=
    local the_branch=

    while getopts "o:p:b:" opt;do

        #参数存在$OPTARG中
        case ${opt} in

             o)
                owner=$OPTARG
                ;;

             p)
                the_curr_project=$OPTARG
                ;;

             b)
                the_branch=$OPTARG
                ;;

             \?)
                echo ""
                show_vip "$0 [ -o <owner> | -p <project> -b <branch> ] ..."
                echo "    -o : 作者信息"
                echo "    -p : 需要审核的项目"
                echo "    -b : 需要审核的分支"
                echo "    -h : 帮助"
                echo
                echo "    e.g."
                echo "        1. $0 -o xingyf@yunovo.cn"
                echo "        2. $0 -o xingyf@yunovo.cn -p xyf/zzzzz-script"
                echo "        3. $0 -o xingyf@yunovo.cn -p xyf/zzzzz-script -b yunovo/master"
                echo "        4. $0 -o xingyf@yunovo.cn -b master"
                echo
                return 0
                ;;
        esac
    done

    if [[ $# -eq 0 ]]; then
        echo ""
        show_vip "$0 [ -o <owner> | -p <project> -b <branch> ] ..."
        echo "    -o : 作者信息"
        echo "    -p : 需要审核的项目"
        echo "    -b : 需要审核的分支"
        echo "    -h : 帮助"
        echo
        echo "    e.g."
        echo "        1. $0 -o xingyf@yunovo.cn"
        echo "        2. $0 -o xingyf@yunovo.cn -p xyf/zzzzz-script"
        echo "        3. $0 -o xingyf@yunovo.cn -p xyf/zzzzz-script -b yunovo/master"
        echo "        4. $0 -o xingyf@yunovo.cn -b master"
        echo
        return 0
    fi

    local the_projects=

    #echo "owner = ${owner}; the_curr_project = ${the_curr_project}; the_branch = ${the_branch}"

    if [[ -n "${owner}" ]]; then
        if [[ -n "${the_branch}" ]];then
            the_projects=(`ssh-gerrit gerrit query status:open owner:${owner} branch:${the_branch} | egrep -w project | sort | uniq | awk '{print $NF}'`)
        else
            the_projects=(`ssh-gerrit gerrit query status:open owner:${owner} | egrep -w project | sort | uniq | awk '{print $NF}'`)
        fi
    else
        if [[ -n "${the_branch}" ]];then
            the_projects=(`ssh-gerrit gerrit query status:open branch:${the_branch} | egrep -w project | sort | uniq | awk '{print $NF}'`)
        else
            # All Projects
            the_projects=(`ssh-gerrit gerrit query status:open | egrep -w project | sort | uniq | awk '{print $NF}'`)
        fi
    fi

    if [[ -z "${the_projects[@]}" ]]; then
        log error "无法找到项目名,请检查参数是否有误?"
    fi

    echo
    show_vip "--> review start."

    if [[ -n ${the_curr_project} && ${the_projects[@]} =~ ${the_curr_project} ]]; then
        the_project=${the_curr_project}

        echo ${the_project}:

        echo
        read -p "请慎重检查下, 上述项目的补丁是否需要全部提交服务器? [Yes|No]: " key
        echo

        case ${key} in
            [yY][eE][sS]|[yY])

                read -p "是否继续? : yes|no : " Reply
                echo

                case ${Reply} in
                    [nN][oO]|[nN])
                        __wrn "已取消执行 ..."
                        return 0
                    ;;

                    [yY][eE][sS]|[yY])
                        review
                    ;;

                    *)
                        __wrn "已取消执行 ..."
                        return 0
                    ;;
                esac

            ;;

            [nN][oO]|[nN])
               __wrn "已取消执行 ..."
            ;;

            *)
                __wrn "已取消执行 ..."
                return 0
            ;;
        esac
    else
        for the_project in ${the_projects[@]} ; do
            echo ${the_project}
        done

        echo
        read -p "请慎重检查下, 上述项目的补丁是否需要全部提交服务器? [Yes|No]: " key
        echo

        case ${key} in
            [yY][eE][sS]|[yY])

                read -p "是否继续? : [yes|no]: " Reply
                echo

                case ${Reply} in
                    [nN][oO]|[nN])
                        __wrn "已取消执行 ..."
                        return 0
                    ;;

                    [yY][eE][sS]|[yY])
                        for the_project in ${the_projects[@]} ; do
                            review
                        done
                    ;;

                    *)
                        __wrn "已取消执行 ..."
                        return 0
                    ;;
                esac
            ;;

            [nN][oO]|[nN])
               __wrn "已取消执行 ..."
            ;;

            *)
                __wrn "已取消执行 ..."
                return 0
            ;;
        esac
    fi

    show_vip "--> review end."
}

main "$@"