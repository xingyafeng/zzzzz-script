#!/usr/bin/env bash

###################################
#
#  字符串截取
#
#      ${string:position:length}
#
#  1) 从字符串左边开始计数
#       ${string: start   :length}
#  2) 从右边开始计数
#       ${string: 0-start :length}
#       ${string:  -start :length}
#  3) 字符串长度
#       ${#string}
#
#   说明: 参数1: 起始位置 <注意，方向比一样，正数由左开始，负数由右开始，0可以不写,需使用空格替代。>
#         参数2: 字符串长度
#
###################################
function test_string_cut() {

    local url="c.biancheng.net"

    echo 'url:' ${url}
    echo 'length : ' ${#url}
    echo '-------------'
    echo '${url:2:4} : ' ${url:2:4}
    echo '${url:6:5} : ' ${url:6:5}
    echo '${url:0:1} : ' ${url:0:1}
    echo '${url:0}   : ' ${url:0}
    echo '${url:2}   : ' ${url:2}
    echo '-------------'
    echo '${url: -3}    : ' ${url: -3}
    echo '${url: -3:3}  : ' ${url: -3:3}
    echo '${url: -13:9} : ' ${url: -13:9}
    echo '${url: -0}    : ' ${url: -0}
}

###################################
#
#  打印不匹配内容,即删除匹配的字符串
#
#  1) 从字符串左边开始计数 #
#       ${string#substring}
#       ${string##substring}
#  2) 从右边开始计数
#       ${string%substring}
#       ${string%%substring}
#
#   说明: 从开头（#）或结尾（%）打印 <不匹配> 的内容 substring 任意字符串，支持统配符
#
###################################
function test_string_delete
{
	jpg_name="chiphd.sameple.jpg"

	## '#' 从左往右 遇到第一个  匹配项 '.' 就结束，delete 匹配的字符串
	name_11=${jpg_name#*.}

	## '#' 从左往右 遇到最后一个匹配项 '.' 就结束，delete 匹配的字符串　<获取后缀>
	name_22=${jpg_name##*.}

	## '%' 从右往左 遇到第一个　匹配项 '.' 就结束，delete 匹配的字符串  <获取文件名>
	name_1=${jpg_name%.*}

	## '%%' 从右往左 遇到最后一个匹配项 '.' 就结束，delete 匹配的字符串
	name_2=${jpg_name%%.*}

	echo ${jpg_name}
	echo --------------------

	echo "File '#'  name: " ${name_11}
	echo "File '##' name: " ${name_22}
	echo "File '%'  name: " ${name_1}
	echo "File '%%' name: " ${name_2}
}

###################################
#
#  字符串匹配并替换
#
#  1) '//'  all replace
#       ${string//substring/replacement}
#  2) '/' single repalce
#       ${string/substring/replacement}
#  3) '/#' start position
#       ${string/#substring/replacement}
#  4) '/%' end  position
#       ${string/%substring/replacement}
#
#   说明: '//' 匹配所有
#         '/'  左边，匹配一次
#         '/#' 左边，开始的位置　匹配一次
#         '/%' 右边，结束的位置　匹配一次
#
###################################
function test_string_replace() {

    local str=23abc1bb4234123

    echo 'str : ' ${str}
    echo '-------------'
    echo ${str//23/gg}  #--将 '包含' 的23字符替换为bb打印（全部替换）
    echo ${str/23/gg}   #--将 '包含' 的23字符替换为bb打印（匹配一次）

    echo ${str/#23/zz}  #--将 '开头' 的23字符替换为xx打印（匹配一次）
    echo ${str/%23/zz}  #--将 '结尾' 的23字符替换为xx打印（匹配一次）
}

function test_string_expr() {

    local str='abc123xyz'

    show_vip 'str : ' ${str}

    # 获取字符串长度
    echo "expr length ${str} : " `expr length ${str}`
    echo '----------------------------------------'

    # 获取字符串位置
    echo "expr index ${str} 'abc' : " `expr index ${str} 'abc'`
    echo "expr index ${str} '123' : " `expr index ${str} '123'`
    echo "expr index ${str} 'xyz' : " `expr index ${str} 'xyz'`
    echo "expr index ${str} 'a'   : " `expr index ${str} 'a'`
    echo "expr index ${str} '1'   : " `expr index ${str} '1'`
    echo "expr index ${str} 'x'   : " `expr index ${str} 'x'`
    echo '----------------------------------------'

    # 从字符串开头到子串的最大长度
    echo "expr match ${str} 'abc.*3'   : " `expr match ${str} 'abc.*3'`
    echo '----------------------------------------'

    # 匹配显示内容，与上面的match不同
    echo "expr match ${str} '\([a-c]*[0-9]*\)'   : " `expr match ${str} '\([a-c]*[0-9]*\)'`
    echo "expr ${str} : '\([a-c]*[0-9]\)'　　　  : " `expr ${str} : '\([a-c]*[0-9]\)'`
    echo "expr ${str} : '.*\([0-9][0-9][0-9]\)'  : " `expr ${str} : '.*\([0-9][0-9][0-9]\)'`
    echo '----------------------------------------'
}
