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