#!/usr/bin/env bash

##################################
#
#  while知识点:
#
#  1、读取文件首行前三个字段并赋值给变量，当然 这里可以是任意字段，当不希望读取后面的采用 throwaway结束 或者 '_'
#  2、有时候，为了书写方便，可以简单地用_来替换throwaway变量
#
##################################
function test_while() {

    local fs=config/test_while.log

    while IFS=" " read -r field1 field2 field3 field4 throwaway;do
        echo ${field1} '---' ${field2} '---' ${field3} ==== ${field4}
    done < ${fs}
}