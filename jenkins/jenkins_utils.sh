#!/usr/bin/env bash

## 定义数组变量
declare -a _inlist

## 选择正确的值,并赋值给它
function select_choice()
{
   local _target_arg=$1
   local _arg_list=(${_inlist[@]})
   local _outc=""

    select _c in ${_arg_list[@]}
    do
        if [[ -n "$_c" ]]; then
            _outc=${_c}
            break
        else
            for _i in ${_arg_list[@]}
            do
                _t=`echo ${_i} | grep -E "^$REPLY"`
                if [[ -n "$_t" ]]; then
                    _outc=${_i}
                    break
                fi
            done

            if [[ -n "$_outc" ]]; then
                break
            fi
        fi
    done

    echo

    if [[ -n "$_outc" ]]; then
        eval "${_target_arg}=${_outc}"
        export ${_target_arg}=${_outc}
    fi
}

function command() {
    command="$@"

    echo
    echo '@@@@@'
    __green__ "cmd: \$ $command"
    echo '@@@@@'
    echo

    eval ${command}
    if [[ $? -ne 0 ]]; then
        log error  "FAILED: $command"
    fi
}

# 检查路径是否存在, -d
function check_if_dir_exists() {

    if [[ ! -d "$1" ]]; then
        log error "Could not find the dir: \"$1\", aborting ..."
    fi
}

# 检查文件是否存在， -f
function check_if_file_exists() {

    if [[ ! -f "$1" ]]; then
        log error "Could not find the file: \"$1\", aborting ..."
    fi
}

## 获取文本中字符串所在的行号
function get_line_from_file()
{
    local file_name=$1
    local string=$2

    if [[ $# -ne 2 ]];then
        log error "args is error, please check args!"
    fi

    sed -n "/^${string}/=" ${file_name}
}

## 检查两个文件是否相同
function check_file_are_the_same()
{
    local file_1=$1
    local file_2=$2

    if [[ $# -ne 2 ]];then
        log error "args is error, please check args!"
    fi

    diff ${file_1} ${file_2} > /dev/null
    if [[ $? -eq 0 ]]; then
        echo true
    else
        echo false
    fi
}

## 打印普通数组
function print_array()
{
    for i in $@
    do
        echo ${i}
    done
}

## 打印关联数组
function print_ass_array()
{
    declare -a key
    declare -a value
    declare -A ass

    key=($1)
    value=($2)

    if [[ $# -ne 2 ]]; then
        echo ""
        show_vir "print_ass_array args1 args2 "
        echo "    参数1 : ${!ass[@]}"
        echo "    参数2 : ${ass[@]} "
        echo
        show_vig '    e.g. print_ass_array ${!ass[@]} ${ass[@]}'
        return
    fi

    if [[ ${#key[@]} -ne ${#value[@]} ]]; then
        echo "print_ass_array: key vaule no match ..."
        return
    fi

    for k in ${!key[@]} ; do
        for v in ${!value[@]} ; do
            if [[ ${k} == ${v} ]]; then
                ass[${key[$k]}]=${value[$v]}
            fi
        done
    done

    for a in ${!ass[@]} ; do
        echo "ass[$a]=${ass[$a]}"
    done
}

## 生成Checksum.ini
function check_sum_ini()
{
    local OPWD=`pwd`
    local CSG=yunovo/build/CheckSum_Gen
    local DELFS=(CheckSum_Gen libflashtoolEx.so libflashtool.so libflashtool.v1.so)

    ## 1. 拷贝CheckSum_Gen文件和库到DEST_PATH目录下
    if [[ -d ${CSG}  ]];then
        cp -vf ${CSG}/* ${DEST_PATH}
    else
        log error "CheckSum_Gen file no found ."
    fi

    cd ${DEST_PATH} > /dev/null

    ## 2. 生成 Checksum.ini
    if [[ -x CheckSum_Gen ]];then
        ./CheckSum_Gen
    else
        log error "bash: ./CheckSum_Gen: 权限不够."
    fi

    ## 3. 清理动作
    for f in ${DELFS[@]}
    do
        if [[ -e ${f} ]];then
            rm ${f}
        fi
    done

    cd ${OPWD} > /dev/null
}

## 检查远程分支是否有冲突,即是否存在 (local out of date) 问题.
function check_remote_branch() {

    local tags="`git remote show origin | grep ${GITRES_BRANCH} | grep pushes | egrep -w 'local out of date'  | awk -F'(' '{print $NF}' | awk -F')' '{print $1}'`"

    if [[ "${tags}" == "local out of date" ]]; then
        echo true
    else
        echo false
    fi
}

## 检查邮件的合法性
function is_check_email() {

    local regex="^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+$"
    local email=""

    if [[ "$1" ]]; then
        email="$1"
    else
        log error "无效参数 e.g ${FUNCNAME[0]} xingyf@yunovo.cn"
    fi

    if [[ "${email}" =~ ${regex} ]]; then
        echo true
    else
        echo false
    fi
}

# 检查邮件的合法性
function validator {

    local regex="^([A-Za-z]+[A-Za-z0-9]*((\.|\-|\_)?[A-Za-z]+[A-Za-z0-9]*){1,})@(([A-Za-z]+[A-Za-z0-9]*)+((\.|\-|\_)?([A-Za-z]+[A-Za-z0-9]*)+){1,})+\.([A-Za-z]{2,})+$"
    local email=

    if [[ "$1" ]]; then
        email="$1"
    else
        log error "无效参数 e.g ${FUNCNAME[0]} xingyf@yunovo.cn"
    fi

    if [[ "${email}" =~ ${regex} ]]; then
        printf "* %-48s \e[1;32m[pass]\e[m\n" "${email}"
    else
        printf "* %-48s \e[1;31m[fail]\e[m\n" "${email}"
    fi
}

# 分割字符串
function splitstring() {

    local source=
    local separator=
    declare -a string

    if [[ "$1" ]]; then
        source="$1"
    else
        log debug "无效参数1 ..."
    fi

    if [[ "$2" ]]; then
        separator=$2
    else
        log debug "无效参数2 ..."
    fi

    if [[ "$#" -ne 2 ]]; then
        log error "无效参数 e.g ${FUNCNAME[0]} \"ab;cd;ef;\" \";\" ..."
    fi

    OIFS=$IFS
    IFS="${separator}"
    for s in ${source} ; do
        string[${#string[@]}]=${s}
    done
    IFS=${OIFS}

    echo ${string[@]}
}

## 创建json文件
function touch_json()
{
    local json=${tmpfs}/report.json
    local DEST_PATH="${nxos_path}/${BUILD_DISPLAY_NAME}"

    if [[ ! -d ${DEST_PATH} ]]; then
        mkdir -p ${DEST_PATH}
    fi

    printf "{\n" > ${json}
    printf '\t"report":[\n' >> ${json}
    printf '\t\t{\n' >> ${json}

    if [[ ${#test_report[@]} -ne 0 ]]; then
        for ((i=0; i<${#test_report[@]}; i++))
        do
            if [[ ${i} == $[${#test_report[@]}-1] ]]; then
                printf "\t\t\t`echo "${test_report[$i]}" | sed 's/|//g' | sed 's/^;//' | sed -r 's/^(.*);(.*);(.*);(.*);(.*);(.*);(.*)$/"commit_id":"\1","channel":"\2","rom":"\3","version":"\4","result":"\5","md5":"\6"/'`\n\t\t}\n" >> ${json}
            else
                printf "\t\t\t`echo "${test_report[$i]}" | sed 's/|//g' | sed 's/^;//' | sed -r 's/^(.*);(.*);(.*);(.*);(.*);(.*);(.*)$/"commit_id":"\1","channel":"\2","rom":"\3","version":"\4","result":"\5","md5":"\6",/'`\n" >> ${json}
            fi
        done
    else
        printf "\t\t}\n" >> ${json}
    fi

    printf "\t]\n" >> ${json}
    printf "}\n" >> ${json}

    ## 备份测试报告文件 report.json
    if [[ -f ${json} ]]; then
        cp -vf ${json} ${DEST_PATH}
    else
        log error "未找到生成测试报告文件 ..."
    fi
}

## 创建rom info json文件
function touch_rom_json()
{
    local json=${tmpfs}/rom.json
    local DEST_PATH=${rom_path}/${job_name}/${BUILD_DISPLAY_NAME}

    if [[ ! -d ${DEST_PATH} ]]; then
        mkdir -p ${DEST_PATH}
    fi

    printf "{\n" > ${json}
    printf '\t"rom":[\n' >> ${json}
    printf '\t\t{\n' >> ${json}

    if [[ ${#rom_info[@]} -ne 0 ]]; then
        for ((i=0; i<${#rom_info[@]}; i++))
        do
            if [[ ${i} == $[${#rom_info[@]}-1] ]]; then
                printf "\t\t\t`echo "${rom_info[$i]}" | sed -r 's/^(.*);(.*);(.*)$/"prj_name":"\1","system_version":"\2","VER":"\3"/'`\n\t\t}\n" >> ${json}
            else
                printf "\t\t\t`echo "${rom_info[$i]}" | sed -r 's/^(.*);(.*);(.*)$/"prj_name":"\1","system_version":"\2","VER":"\3",/'`\n\t\t}\n" >> ${json}
            fi
        done
    else
        printf "\t\t}\n" >> ${json}
    fi

    printf "\t]\n" >> ${json}
    printf "}\n" >> ${json}

    ## 备份测试报告文件 report.json
    if [[ -f ${json} ]]; then
        cp -f ${json} ${DEST_PATH}

        if [[ $? -eq 0 ]]; then
            rm -rf ${json}
        fi
    else
        log error "未找到生成测试报告文件 ..."
    fi
}

## 去掉变量中的所有空格
function remove_space_for_vairable()
{
    ## 去掉空格后的变量
    local new_v=
    local old_v=$1

    if [[ $# -eq 1 ]];then
        :
    else
        log error "args is error, please check args !"
    fi

    new_v=(`echo ${old_v} | sed 's/[  ]\+//g'`)
    if [[ "$new_v" != "$old_v" ]];then
        echo ${new_v}
    else
        echo ${old_v}
    fi
}