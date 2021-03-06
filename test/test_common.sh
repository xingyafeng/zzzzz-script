#!/usr/bin/env bash

####################################################################################################
#
#   1. readlink    # 获取软连接指定的真实文件名
#   2. tac         # 倒叙读取文件内容
#   3. paste -sd, /tmp/test.txt         # 将一个文本的所有行用逗号连接起来
#   4. sort /tmp/test.txt -u            # 过滤重复行
#   5. grep -w '10.0.0.1' /tmp/ip.list  # grep查找单词
#   6. echo "${@:2}"                    # $1,$2...等位置参数的使用
#   7. arg=${1:-0}                      # 赋值$1参数
#   8. echo 'abc-i' | grep -- -i        # rep查找字符串中是否包含-i
#   9. 函数的返回值默认是最后一行语句的返回值
#   10. 打印文件行
#       head -1 test.txt                # 打印文件的第一行
#       sed -n '2p' test.txt            # 打印文件的第2行
#       sed -n '2,5p' test.txt          # 打印文件的第2到5行
#       sed -n '2,+4p' test.txt         # 打印文件的第2行始（包括第2行在内）5行的内容
#       tail -2 test.txt | head -1      # 打印倒数第二行
#       tac test.txt | sed -n '2p'      # 打印倒数第二行
#   11.   > test.txt                    # 清空一个文件
#   12. echo "${str#?}"                 # 删除字符串中的第一个
#       echo "${str%?}"                 # 删除字符串中的最后个 类似地，你也可以删除2个、3个、4个……
#       echo "${str:1:-1}"
#   13. pre_dir=$(dirname $(readlink -e $(dirname $0)))     # 拿到父路径
#       cur_dir=$(dirname $(readlink -e ${BASH_SOURCE[0]})) # 拿到当前路径
#   14. set 用来显示本地变量, 特殊的妙用　 set -- "a b c d"
#   15. env 用来显示环境变量
#   16. export 用来显示和设置环境变量
#   17. xmlstarlet sel -T -t -m /manifest/project -v "concat(@name,' --- ',@revision,' --- ',@groups)" -n ${xml}
####################################################################################################

# 返回值的写法
function return_value()
{
    local default=

    # 脚本中通过python print ，shell echo 将值返回.
    if (! python ${vendor_root}/tools/TCTHeaderGen.py -s ${vendor_root}/Macro_Desc.csv -v $1 -p ${project} -o ${operator}); then
        echo ${default}
    fi
}

# set 关键字的妙用
function test_set()
{
    # 设置固定参数
    set -- "hello" "joking"

    while [[ $# -ne 0 ]]; do
        echo ${1:-}
        shift
    done
}