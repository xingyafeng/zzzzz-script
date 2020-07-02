#!/usr/bin/env bash

#####################################################
##
##  函数: setitle
##  功能: 配置终端标题
##  参数: 1 任意字符串
##
##  举栗:
##      setitle debug
##      setitle happysongs
##
####################################################
function setitle() {

    local TITLE

    case $# in

        0)
            echo "${FUNCNAME[0]} args1  ..."
            echo
            echo "   args1 : debug"
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]} debug               # 设置标题为debug"
            echo "        1. ${FUNCNAME[0]} happysongs          # 设置标题为happysongs"
            echo
            return 1
            ;;

        *)
            TITLE="\[\e]2;$*\a\]"
            ;;
    esac

    if [[ -z "${ORIG}" ]]; then
        ORIG=$PS1
    fi

    PS1=${ORIG}${TITLE}
}

#####################################################
##
##  函数: ssh-set-permission
##  功能: 配置ssh权限
##  参数: 无
##
##  举栗:
##      ssh-set-permission
##
##  说明，此方法无需参数
##
####################################################
function ssh-set-permission()
{
    if [[ -d ~/.ssh ]];then
        chmod 755 ~/.ssh
    else
        log error "The ~/.ssh folder not found!"
    fi

    if [[ -f ~/.ssh/id_rsa && -f ~/.ssh/id_rsa.pub ]];then
        chmod 600 ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
    else
        log error "The id_rsa or The id_rsa.pub file not found!"
    fi

    if [[ -f ~/.ssh/known_hosts ]];then
        chmod 644 ~/.ssh/known_hosts
    else
        log error "The known_hosts fiel not found!"
    fi
}

#####################################################
##
##  函数: set_locale
##  功能: 配置locale
##  参数: 无
##
##  举栗:
##      ssh-set-permission
##
##  说明: 此方法无需参数。
##        设置locale , 当执行命令时, 出现如下：locale: Cannot set LC_ALL to default locale: No such file or directory
##        安装英文版本ubuntu系统,可以使用以下命令解决
##
####################################################
function set_locale() {

    export LANGUAGE=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    locale

    locale-gen en_US.UTF-8
    sudo dpkg-reconfigure locales

    locale
}

## 修复git提交信息乱码问题
function setgitencoding()
{
    git config --global i18n.commitencoding utf-8
    git config --global gui.encoding utf-8
    export LESSCHARSET=utf-8
}

## 设置vim配置文件
function setgitconfig()
{
    case $# in
        1)
            git_username=$1
            ;;
        *)
            if [[ $# -eq 0 ]]; then
                git_username=yafeng.xing
            else
                echo ""
                echo "${FUNCNAME[0]} [args1] ..."
                echo
                echo "    args1 : git账号名称　如：yafeng.xing"
                echo
                echo "    e.g."
                echo "        1. ${FUNCNAME[0]} 无参数"
                echo "        2. ${FUNCNAME[0]} yafeng.xing"
                echo
                return 1
            fi
            ;;
    esac

	if [[ -n ${git_username} ]];then
		git config --global user.name  ${git_username}
        git config --global user.email ${git_username}@tcl.com
		git config --global ssh.variant ssh
	fi

    git config --global alias.st status
    git config --global alias.br branch
    git config --global alias.co checkout
    git config --global alias.ci commit
    git config --global alias.date iso
    git config --global core.editor vim
    git config --global color.ui true
    git config --global branch.autosetuprebase always
    #git config --global push.default simple
    git config --global alias.lg "log --date=short --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %C(green)%s %C(reset)(%cd) %C(bold blue)<%an>%Creset' --abbrev-commit"
}

## 配置Java环境为jdk1.8
function set_java_version_1.8() {

    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export JRE_HOME=${JAVA_HOME}/jre
    export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
    export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH
}

## 设置java环境变量
function set_java_version()
{
    local java_version=""
    local java_list=(java7 java8)

    _inlist=(${java_list[@]})
    show_vir "Choose which version of java? "
    select_choice java_version

    case ${java_version} in

    java7)
        export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
        ;;

    java8)
        export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
        ;;

    *)
        export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
        ;;
    esac

    export JRE_HOME=${JAVA_HOME}/jre
    export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
    export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH

    java -version
}

## 设置命令别名
function set_alias()
{
    ### grep
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    # some more ls aliases
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
}

#####################################################
##
##  函数: enhance_mkdir_folder
##  功能: 增强创建文件
##
##  描述: 此函数都使用绝对路径,无需参数
##
####################################################
function enhance_create_dir() {

    for p in ${pathfs[@]} ; do
        if [[ ! -d ${p} ]];then
            mkdir -p ${p}
        fi
    done
}

#####################################################
##
##  函数: enhance_copy_file
##  功能: 增强备份系统文件
##  参数: 1 src: 原有路径
##        2 dst: 目的路径
##
##  描述: 此函数必须有两个参数,否则按照错误来处理.
##
####################################################
function enhance_copy_file() {

    local src dst

    case "$#" in

        2)
            src="$1"
            dst="$2"

            if [[ ! -d ${dst} ]]; then
                mkdir -p ${dst}
            fi
            ;;
        *)
            log error "The ${FUNCNAME[0]} function must be hava two args ..."
        ;;
    esac

    for file in ${copyfs[@]} ; do
        if [[ -f ${src}/${file} ]]; then
            cp -vf ${src}/${file} ${dst}
        else
            ## 优化,有些版本没有此文件,需要忽略. 斟酌处理掉
            case ${file} in

                custom.img)
                    log warn  "It is ${file} that has not found ..."
                    ;;

                acp)
                    log warn  "It is ${file} that has not found ..."
                    ;;

                *)
                    __err "It is ${file} that has not found ..."
                ;;
            esac
        fi
    done
}

## 获取文件类型
function get_file_type() {

    local file=

    if [[ $# -eq 1 ]]; then
        file=$1
    else
        echo ""
        echo "${FUNCNAME[0]} [args1] ..."
        echo
        echo "    args1 : 文件名称，可以包含路径。 [ 注: 必须带后缀 如: .txt .log etc ]"
        echo
        echo "    e.g."
        echo "        1. ${FUNCNAME[0]} yunovohelp.sh"
        echo "        2. ${FUNCNAME[0]} script/zzzzz-script/yunovo/yunovohelp.sh"
        echo
        return 0
    fi

    if [[ -n "${file}" && "${file}" =~ '.' ]]; then
        basename ${file} | awk -F. '{ print $NF }'
    else
        __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
    fi
}

## 获取文件名
function get_file_name() {

    local file=

    if [[ "$#" -eq 1 ]]; then
        file="$1"
    else
        echo ""
        echo "${FUNCNAME[0]} [args1] ..."
        echo
        echo "    args1 : 文件名称，可以包含路径。 [ 注: 必须带后缀 如: .txt .log etc ]"
        echo
        echo "    e.g."
        echo "        1. ${FUNCNAME[0]} yunovohelp.sh"
        echo "        2. ${FUNCNAME[0]} script/zzzzz-script/yunovo/yunovohelp.sh"
        echo
        return 0
    fi

    if [[ -n "${file}" && "`basename ${file}`" =~ '.' ]]; then
        basename ${file} | sed s/`get_file_type ${file}`// | sed "s/.$//"
    else
        __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
    fi
}

function left_remove_first() {

    local var

    case $# in
        1)
            case $@ in
                -h|--help)
                    echo ""
                    echo "${FUNCNAME[0]} [args1] [args2] ..."
                    echo
                    echo "    args1 : 处理的字符串 "
                    echo "    args2 : 分割符 如 / ' \" : etc "
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}"              #帮助
                    echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
                    echo
                    return 0
                    ;;

                *)
                    echo ""
                    echo "${FUNCNAME[0]} [args1] [args2] ..."
                    echo
                    echo "    args1 : 处理的字符串 "
                    echo "    args2 : 分割符 如 / ' \" : etc "
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}"              #帮助
                    echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
                    echo
                    return 0
                    ;;
            esac

            ;;

        2)
            var=$1
            op=$2
            ;;

        *)
            echo ""
            echo "${FUNCNAME[0]} [args1] [args2] ..."
            echo
            echo "    args1 : 处理的字符串 "
            echo "    args2 : 分割符 如 / ' \" : etc "
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]}"              #帮助
            echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
            echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
            echo
            return 0
            ;;
    esac

    echo ${var#*${op}}
}

function left_remove_end() {

    local var

    case $# in
        1)
            case $@ in
                -h|--help)
                    echo ""
                    echo "${FUNCNAME[0]} [args1] [args2] ..."
                    echo
                    echo "    args1 : 处理的字符串 "
                    echo "    args2 : 分割符 如 / ' \" : etc "
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}"              #帮助
                    echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
                    echo
                    return 0
                    ;;

                *)
                    echo ""
                    echo "${FUNCNAME[0]} [args1] [args2] ..."
                    echo
                    echo "    args1 : 处理的字符串 "
                    echo "    args2 : 分割符 如 / ' \" : etc "
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}"              #帮助
                    echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
                    echo
                    return 0
                    ;;
            esac

            ;;

        2)
            var=$1
            op=$2
            ;;

        *)
            echo ""
            echo "${FUNCNAME[0]} [args1] [args2] ..."
            echo
            echo "    args1 : 处理的字符串 "
            echo "    args2 : 分割符 如 / ' \" : etc "
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]}"              #帮助
            echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
            echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
            echo
            return 0
            ;;
    esac

    echo ${var##*${op}}
}

function right_remove_first() {

    local var

    case $# in
        1)
            case $@ in
                -h|--help)
                    echo ""
                    echo "${FUNCNAME[0]} [args1] [args2] ..."
                    echo
                    echo "    args1 : 处理的字符串 "
                    echo "    args2 : 分割符 如 / ' \" : etc "
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}"              #帮助
                    echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
                    echo
                    return 0
                    ;;

                *)
                    echo ""
                    echo "${FUNCNAME[0]} [args1] [args2] ..."
                    echo
                    echo "    args1 : 处理的字符串 "
                    echo "    args2 : 分割符 如 / ' \" : etc "
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}"              #帮助
                    echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
                    echo
                    return 0
                    ;;
            esac

            ;;

        2)
            var=$1
            op=$2
            ;;

        *)
            echo ""
            echo "${FUNCNAME[0]} [args1] [args2] ..."
            echo
            echo "    args1 : 处理的字符串 "
            echo "    args2 : 分割符 如 / ' \" : etc "
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]}"              #帮助
            echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
            echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
            echo
            return 0
            ;;
    esac

    echo ${var%${op}*}
}

function right_remove_end() {

    local var

    case $# in
        1)
            case $@ in
                -h|--help)
                    echo ""
                    echo "${FUNCNAME[0]} [args1] [args2] ..."
                    echo
                    echo "    args1 : 处理的字符串 "
                    echo "    args2 : 分割符 如 / ' \" : etc "
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}"              #帮助
                    echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
                    echo
                    return 0
                    ;;

                *)
                    echo ""
                    echo "${FUNCNAME[0]} [args1] [args2] ..."
                    echo
                    echo "    args1 : 处理的字符串 "
                    echo "    args2 : 分割符 如 / ' \" : etc "
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}"              #帮助
                    echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
                    echo
                    return 0
                    ;;
            esac

            ;;

        2)
            var=$1
            op=$2
            ;;

        *)
            echo ""
            echo "${FUNCNAME[0]} [args1] [args2] ..."
            echo
            echo "    args1 : 处理的字符串 "
            echo "    args2 : 分割符 如 / ' \" : etc "
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]}"              #帮助
            echo "        2. ${FUNCNAME[0]} -h --help"    #帮助
            echo "        3. ${FUNCNAME[0]} http://www.aaa.com/123.html /"
            echo
            return 0
            ;;
    esac

    echo ${var%%${op}*}
}

# 拿到某个路径下的磁盘单位，如: M G T etc
function get_disk_unit() {

    local path=

    case $# in

        0)
            path='/home'
            ;;
        1)
            case $@ in
                -h|--help)
                    echo ""
                    echo "${FUNCNAME[0]} [args1]  ..."
                    echo
                    echo "    args1 : 文件夹路径，可为空，默认为/home"
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]} -h --help"    #帮助
                    echo "        2. ${FUNCNAME[0]} /home"        #查看/home目录下
                    echo "        3. ${FUNCNAME[0]} /mnt"
                    echo
                    return 0
                    ;;
                *)
                    path=$1
                    ;;
            esac
            ;;
        *)
            echo ""
            echo "${FUNCNAME[0]} [args1]  ..."
            echo
            echo "    args1 : 文件夹路径，可为空，默认为/home"
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]} -h --help"    #帮助
            echo "        2. ${FUNCNAME[0]} /home"        #查看/home目录下
            echo "        3. ${FUNCNAME[0]} /mnt"
            echo
            return 0
            ;;
    esac

    if [[ -n ${path} ]]; then
        df -lh ${path} | tail -1 | awk '{print $(NF-2)}' | sed 's/.*\(.\)$/\1/'
    fi
}