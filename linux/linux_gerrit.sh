#!/usr/bin/env bash

## ssh-gerrit-who
function ssh-gerrit-who()
{
    local username=""

    _inlist=(`getent passwd | grep /work | awk -F: '{print $1}'| sort` exit)
    show_vir "Choose which version of username ?"
    select_choice username

    case ${username} in

        exit)
            ssh -p 29419 xingyafeng@gerrit.y $@
            ;;
        *)
            ssh -p 29419 ${username}@gerrit.y $@
            ;;
    esac
}

## ssh-gerrit
function ssh-gerrit()
{
    # ${git_username}
    ssh -o ConnectTimeout=32 -p 29418 Integration.tablet@sz.gerrit.tclcom.com gerrit "$@"
}

## check verified +1
function check_verified() {

    local patchset=
    local rowCount=

    case $# in

        1)
            patchset=${1-}
            ;;

        *)
            unset patchset
            ;;
    esac

    if [[ -n ${patchset} ]]; then
        rowCount=$(ssh-gerrit query "status:open --patch-sets=${patchset} label:Verified+1" | egrep 'rowCount:' | awk '{print $NF}')
    else
        log error "patch-set is null ..."
    fi

    if [[ ${rowCount} -eq 0 ]]; then
        echo false
    else
        echo true
    fi
}

## check code-review +2
function check_code-review() {

    local patchset=
    local rowCount=

    case $# in

        1)
            patchset=${1-}
            ;;

        *)
            unset patchset
            ;;
    esac

    if [[ -n ${patchset} ]]; then
        rowCount=$(ssh-gerrit query "status:open --patch-sets=${patchset} label:code-review+2" | egrep 'rowCount:' | awk '{print $NF}')
    else
        log error "patch-set is null ..."
    fi

    if [[ ${rowCount} -eq 0 ]]; then
        echo false
    else
        echo true
    fi
}

## 创建空的脚本
function touch_empty_shell() {

    local shell=${tmpfs}/shell.sh

    :> ${shell}

    echo "#!/usr/bin/env bash" >> ${shell}
    echo >> ${shell}

    chmod u+x ${shell}
}

## 仓库manifest 项目
function create_manifest_project() {

    local count=
    local pre=

    if [[ -n $1 ]]; then
        pre=$1
    fi

    if [[ "$#" -gt 1 ]]; then
        echo ""
        echo "create_manifest_project \$@"
        echo
        echo "    参数1 : 仓库路径的前缀 如: platform 或者为空等等"
        echo
        echo "    e.g. check_gerrit_repositories platform"
        echo "    e.g. check_gerrit_repositories"
        echo

        return 0
    fi

    local common_name_and_path="<project groups=\"pdk\" name=\"${pre}/ret\" path=\"ret\"/>"
    local common_name_only="<project groups=\"pdk\" name=\"ret\"/>"

    local empty=empty.xml
    local default=default.xml

    if [[ -f ${empty} ]];then
        count=`cat ${empty} | wc -l`

        if [[ -z ${count} ]];then
            echo "count is NULL ."
            return 1
        fi
    fi

    #创建default.xml
    if [[ -f ${default} ]];then
        rm ${default} && touch ${default}
    else
        touch ${default}
    fi

    for ((i=1; i<=${count}; i++))
    do
        if [[ -f ${default}  ]]; then

            if [[ -z "$1" ]]; then
                echo ${common_name_only} >> ${default}
            else
                echo ${common_name_and_path} >> ${default}
            fi
        fi
    done

    if [[ -f ${default} ]]; then
        modify_project
    fi
}

## 修改项目名
function modify_project()
{
    local count=1

    if [[ -f empty.xml ]];then
        :
    else
        echo "empty.xml is not exist !"
        return 1
    fi

    while read p;do
        replace_string=${p}

        while read line;do
            if [[ ${line} =~ 'ret' ]];then
                sed -i "${count}s#ret#${replace_string}#g" ${default}
                let count++
                break
            fi
        done < ${default}
    done < empty.xml
}