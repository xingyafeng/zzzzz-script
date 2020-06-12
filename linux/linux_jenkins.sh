#!/usr/bin/env bash

## ssh-jenkins
function ssh-jenkins()
{
    local jenkins_url=""

    set_java_version_1.8

    case `hostname` in

        happysongs)
            jenkins_url="http://10.0.0.252:8080"
            ;;

        s1|s2|s4|s5|s6|s7|c1|c2|f1)
            jenkins_url="http://jenkins.y"
            ;;
        *)
            return 0
            ;;
    esac

    echo
    show_vig "$jenkins_url"

    if [[ -n "$jenkins_url" ]];then
        #java -jar $script_p/tools/jenkins-cli.jar -s $jenkins_url -ssh -user xingyafeng $@
        java -jar ${script_p}/tools/jenkins-cli.jar -remoting -s ${jenkins_url} $@
    else
        __err "No found url ..."
    fi
}

## 更新服务器的脚本仓库
function ssh-update-script()
{
    local server_ip=`echo s1.y s2.y s3.y s4.y s5.y s6.y s7.y f1.y c1.y c2.y 10.0.0.250`
    local portN=22
    local server_name=jenkins
    local init_script=/home/jenkins/workspace/script/zzzzz-script/init_script.sh

    for ip in ${server_ip};do

        ssh -t -p ${portN} ${server_name}@${ip} "
            source $init_script && echo "server: ${ip}" && \
            echo
        "

        if false;then
            ssh -t -p ${portN} ${server_name}@${ip} '
                cd ~/workspace && touch ssh_test && mkdir test && \
                cd ~ && touch xxx
            '
        fi
    done
}



## 检查gerrit是否已新建仓库
function check_gerrit_repositories() {

    local count=0
    local tmp=
    local has_p=has_project.log

    if [[ "$1" && -f "$1" ]]; then
        tmp=$1
    else
        __err "参数1为空 or 文件不存在 ..."
        return 1
    fi

    if [[ -f ${has_p} ]]; then
        :> ${has_p}
    else
        touch ${has_p}
    fi

    if [[ "$#" -ne 1 ]]; then
        echo ""
        echo "check_gerrit_repositories \$@"
        echo
        echo "    参数1 : 是一个普通文件,内容存放者仓库的路径."
        echo
        echo "    e.g. check_gerrit_repositories empty.xml "
        echo

        return 0
    fi

    ssh-gerrit gerrit ls-projects > ${script_p}/fs/ok.log

    while read line;
    do
        while read p;
        do
            if [[ "${line}" == ${p} ]]; then
                echo ${p} >> ${has_p}
                __pruple__ ${p} is exist ...
                let count++
            fi
        done < ${script_p}/fs/ok.log
    done < ${tmp}

    echo ${count}
}

function get_default_nodes() {

    cat ${jenkins_home}/jobs/${job}/config.xml | grep assignedNode | awk -F ">" '{ print $2 }' | awk -F "<" '{ print $1 }'
}

# 修改nxos应用的运行节点.
function replace_run_nodes() {

    local jenkins_home=~/.jenkins
    local default=
    local repalce=

    if [[ -n "$1" ]]; then
        repalce="$1"
    else
        __err "参数1为空 ..."
    fi

    if [[ $# -ne 1 ]]; then

        echo ""
        echo "replace_run_nodes default repalce"
        echo
        echo "    repalce : 替换后的节点名称"
        echo
        echo "    e.g. replace_run_nodes \"s1||s4||s5|s6||s7\" "
        echo

        return 0
    fi

    for prj in `ssh-gerrit gerrit ls-projects | grep ^nxos/nx`
    do
        for job in `ssh-jenkins list-jobs | grep ^nx` ; do
            if [[ `basename ${prj}` == ${job} ]]; then

                default="`get_default_nodes`"

                if [[  ${default} != ${repalce} ]]; then
                    echo "--> <${job}> repalce nodes : ${default} -> ${repalce} ... "

                    find ${jenkins_home}/jobs/${job} -type f -name config.xml -print0 | xargs -0 sed -i "s#<assignedNode>${default}</assignedNode>#<assignedNode>${repalce}</assignedNode>#g"
                fi
            fi
        done
    done
}
