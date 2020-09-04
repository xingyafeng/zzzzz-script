#!/usr/bin/env bash

# 测试删除字符的空格
function test_remove_space()
{
    local new_v=
    local old_v=$1
    tmp_file=~/workspace/script/zzzzz-script/tmp.txt

    new_v=`cat ${tmp_file} | sed 's/[   ]\+//g'`
    if [[ "$new_v" != "$old_v" ]];then
        echo ${new_v}
    else
        echo ${old_v}
    fi
}

# 测试参数提取
function test_get_args() {

    for parameter in $@
    do
        echo $@
        echo
        echo 'args: '${parameter}
        echo '----------------'
        echo

        start=$(expr match "${parameter}" '-\|--')
        option=${parameter:${start}}

        echo '1.start  : '${start}
        echo '2.option : '${option}
        echo '3.${parameter:0:1} : '${parameter:0:1}
        log print '---- end'

        if [[ ${start} -gt 0 ]]; then
            start=$(expr match "${parameter}" '-\|--')
            option=${parameter:${start}}
        elif [[ "${parameter:0:1}" != '-' ]];then

            if [[ ${index} -eq 0 ]];then
                project=${parameter};
            fi

            if [[ ${index} -eq 1 ]];then
                operator=${parameter};
            fi

            log debug "project = ${project} ; operator= ${operator}"
            ((index++))
        else
            echo "!!unvalid parameter '$parameter' !!\n"
            return 0
        fi
    done
}