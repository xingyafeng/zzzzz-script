#!/usr/bin/env bash

##################################################################
#
#     linux中的三剑客
#
# 1. grep 更适合单纯的查找或匹配文本
# 2. sed  更适合编辑匹配到的文本
# 3. awk  更适合格式化文本，对文本进行较复杂格式处理
#
##################################################################

# 多行处理 N;P;D -> n,p,d
# 将多行内容写成一样，使用分隔符$op隔开
function test_join_lines() {

    local op path

    case $# in

        2)
            op=${1:-}
            path=${2:=config/text}
            ;;
        *)
            log error "The args has error ..."
            ;;
    esac

    sed 'H;$!d;${x;s/^\n//;s/\n/'${op}'/g}' ${path}
    #sed ':a;$!N;s/\n/'${op}'/;ta' ${path}

    echo
}

##################################################################
#
#   3; awk处理过程: 依次对每一行进行处理，然后输出
#
#   awk的用法：
#       awk 参数 ' BEGIN{ }  //  { action1;action2 } ' END{ } 文件名
#
#   参数：
#       -F  --  指定分隔符
#       -f  --  调用脚本
#       -v  --  定义变量
#
#   Begin{} :
#       初始化代码块，在对每一行进行处理之前，初始化代码，主要是引用全局变量，设置FS分隔符
#
#   // :
#       匹配代码块，可以是字符串或正则表达式
#
#   { } :
#       命令代码块，包含一条或多条命令,多条命令用 ;  隔开
#
#   END{ }:
#       结尾代码块，在对每一行进行处理之后再执行的代码块，主要是进行最终计算或输出结尾摘要信息
#
##  awk中字符的含义：
#
#   $0        表示整个当前行
#   $1        每行第一个字段
#   NF        字段数量变量
#   NR        每行的记录号，多文件记录递增
#   FNR       与NR类似，不过多文件记录不递增，每个文件都从1开始
#   \t        制表符
#   \n        换行符
#   FS        BEGIN时定义分隔符
#   RS        输入的记录分隔符， 默认为换行符(即文本是按一行一行输入)
#   ~         包含
#   !~        不包含
#   ==        等于，必须全部相等，精确比较
#   !=        不等于，精确比较
#   &&        逻辑与
#   ||        逻辑或
#   +         匹配时表示1个或1个以上
#   /[0-9][0-9]+/     两个或两个以上数字
#   /[0-9][0-9]*/     一个或一个以上数字
#   OFS       输出字段分隔符， 默认也是空格，可以改为其他的
#   ORS       输出的记录分隔符，默认为换行符,即处理结果也是一行一行输出到屏幕
#   -F  [:#/] 定义了三个分隔符
#
#
##################################################################
function test_awk_syntax() {

    # print 打印
    awk 'BEGIN{ X=0 } /root/ { X+=1 } END{ print "I find",X,"root lines" }' /etc/passwd
    awk '{printf "%s === %s\n",$NF,$1}'  /etc/passwd
}

##################################################################
#   格式化输出
#      -  printf    表示格式输出
#      -  '%'       格式化输出分隔符
#      -  '-8'      表示长度为8个字符
#      -  's'       表示字符串类型，d表示小数
#
##################################################################
function test_awk_printf() {

    log debug '1: 显示 /etc/passwd 中含有 root 的行 ------'
    #1、显示 /etc/passwd 中含有 root 的行
    awk '/root/' /etc/passwd

    log debug '2: 以 : 为分隔，显示/etc/passwd中每行的第1和第7个字段 ------'
    #2、以 : 为分隔，显示/etc/passwd中每行的第1和第7个字段
    awk -F ":" '{print $1,$7}' /etc/passwd

    log debug '------- 相同分割线 --------'
    awk 'BEGIN{FS=":"}{print $1,$7}' /etc/passwd

    log debug '3: 以 : 为分隔，显示/etc/passwd中含有 root 的行的第1和第7个字段 ------'
    #3、以 : 为分隔，显示/etc/passwd中含有 root 的行的第1和第7个字段
    awk -F ":" '/root/{print $1,$7}' /etc/passwd

    log debug '4: 以 : 为分隔，显示/etc/passwd中以 root 开头行的第1和第7个字段 ------'
    #4、以 : 为分隔，显示/etc/passwd中以 root 开头行的第1和第7个字段
    awk -F ":" '/^root/{print $1,$7}' /etc/passwd

    log debug '5: 以 : 为分隔，显示/etc/passwd中第3个字段大于999的行的第1和第7个字段 ------'
    #5、以 : 为分隔，显示/etc/passwd中第3个字段大于999的行的第1和第7个字段
    awk -F ":" '$3>999 {print $1,$7}'  /etc/passwd

    log debug '6: 以 : 为分隔，显示/etc/passwd中第7个字段包含bash的行的第1和第7个字段 ------'
    #6、以 : 为分隔，显示/etc/passwd中第7个字段包含bash的行的第1和第7个字段
    awk -F ":" '$7~"bash"{print $1,$7}' /etc/passwd

    log debug '7: 以 : 为分隔，显示/etc/passwd中第7个字段不包含bash的行的第1和第7个字段 ------'
    #7、以 : 为分隔，显示/etc/passwd中第7个字段不包含bash的行的第1和第7个字段
    awk -F ":" '$7!~"nologin"{print $1,$7}'  /etc/passwd

    log debug '8: 以 : 为分隔，显示$3>999并且第7个字段包含bash的行的第1和第7个字段 ------'
    #8、以 : 为分隔，显示$3>999并且第7个字段包含bash的行的第1和第7个字段
    awk -F ":" '$3>999&&$7~"bash"{print $1,$7}' /etc/passwd

    log debug '9: 以 : 为分隔，显示$3>999或第7个字段包含bash的行的第1和第7个字段 ------'
    #9、以 : 为分隔，显示$3>999或第7个字段包含bash的行的第1和第7个字段
    awk -F ":" '$3>999||$7~"bash"{print $1,$7}' /etc/passwd
}

function test_awk_matchup() {

    log debug '1: 打印出文件中含有root的行 ------'
    # 打印出文件中含有root的行
    awk  -F: '/root/{print }'  /etc/passwd

    log debug '2: 打印出文件中含有变量 $A的行 ------'
    # 打印出文件中含有变量 $A的行

    # 以下在终端执行OK. 脚本需要讲A的值复制在外面不能在BEGIN中
    #awk  -F: 'BEGIN{A=root} /'$A'/{print }'  /etc/passwd

    local A=root
    awk -F: '/'${A}'/{print }'  /etc/passwd

    log debug '3: 打印出文件中不含有root的行 ------'
    # 打印出文件中不含有root的行
    awk -F: '!/root/{print}' /etc/passwd

    log debug '4: 打印出文件中含有root或者tom的行 ------'
    # 打印出文件中含有root或者daemon的行
    awk -F: '/root|daemon/{print}'  /etc/passwd


    log debug '5: 有点问题，/// 打印出文件中含有 mail*mysql 的行，*代表有0个或任意多个字符 ------'
    # 打印出文件中含有 mail*mysql 的行，*代表有0个或任意多个字符
    awk -F: '/root/{print}'  /etc/passwd

    log debug '5: 打印出文件中以27开头的行，如27,277,27gff 等等 ------'
    # 打印出文件中以27开头的行，如27,277,27gff 等等
    awk -F: '/^[r][o][o]*/{print}'  /etc/passwd

    log debug '6: 打印出文件中第一个字段包含root的行 ------'
    # 打印出文件中第一个字段是root的行
    awk -F: '$1~/root/{print}' /etc/passwd

    log debug '７: 打印出文件中第一个字段是root的行 ------'
    # 打印出文件中第一个字段是root的行，与上面的等效
    awk -F: '($1=="root"){print}' /etc/passwd

    log debug '8: 打印出文件中第一个字段不是root的行 ------'
    # 打印出文件中第一个字段不是root的行
    awk -F: '$1!~/root/{print}' /etc/passwd

    log debug '9: 打印出文件中第一个字段不是root的行，与上面的等效 ------'
    # 打印出文件中第一个字段不是root的行，与上面的等效
    awk -F: '($1!="root"){print}' /etc/passwd

    log debug '10: 打印出文件中第一个字段是root或daemon的行 ------'
    # 打印出文件中第一个字段是root或ftp的行
    awk -F: '$1~/root|daemon/{print}' /etc/passwd

    log debug '11: 打印出文件中第一个字段是root或daemon的行 ------'
    # 打印出文件中第一个字段是root或ftp的行，与上面的等效
    awk -F: '($1=="root"||$1=="daemon"){print}' /etc/passwd

    log debug '12: 打印出文件中第一个字段不是root或不是daemon的行 ------'
    # 打印出文件中第一个字段不是root或不是ftp的行
    awk -F: '$1!~/root|ftp/{print}' /etc/passwd

    log debug '13: 打印出文件中第一个字段不是root或不是daemon的行 ------'
    # 打印出文件中第一个字段不是root或不是ftp的行，与上面等效
    awk -F: '($1!="root"||$1!="ftp"){print}' /etc/passwd

    log debug '13: 如果第一个字段是root，则打印第一个字段，否则打印第2个字段 ------'
    # 如果第一个字段是mail，则打印第一个字段，否则打印第2个字段
    # 可以写逻辑... 棒！
    awk -F: '{if($1~/root/) {print $1} else {print $2}}'  /etc/passwd
}

#print 是 awk打印指定内容的主要命令，也可以用 printf
function test_awk_print() {

    log debug '1: print ------'
    awk '{print}' /etc/passwd

    log debug '2: print $0 ------'
    awk '{print $0}' /etc/passwd

    log debug '3: 输出空行 ------'
    # 不输出passwd的内容，而是输出相同个数的空行，进一步解释了awk是一行一行处理文本
    awk '{print " "}'  /etc/passwd

    log debug '4: 一行一个字母 a ------'
    # 输出相同个数的a行，一行只有一个a字母
    awk '{print "a"}'  /etc/passwd

    log debug '5: 输出第一列 ------'
    awk -F: '{print $1}' /etc/passwd

    log debug '6: 输出第一列 同5------'
    awk -F  ":" '{print $1}' /etc/passwd

    log debug '7: 输入字段1,2，中间不分隔------'
    # 输入字段1,2，中间不分隔
    awk -F: '{print $1 $2}' /etc/passwd

    log debug '8: 输入字段1,2，中间 " === " => 空格＋等号分开------'
    awk -F: '{print $1 " === " $2}' /etc/passwd

    log debug '9: 输出字段1,3,6， 以制表符作为分隔符 ------'
    # 输出字段1,3,6， 以制表符作为分隔符
    awk -F: '{print $1,$3,$6}' OFS="\t" /etc/passwd

    log debug '10: 输入字段1,2，分行输出 ------'
    #  输入字段1,2，分行输出
    awk -F: '{print $1; print $2}' /etc/passwd

    log debug '11: 输入字段1,2，中间以**分隔 ------'
    # 输入字段1,2，中间以**分隔
    awk -F: '{ print $1 "**###***" $2}' /etc/passwd

    log debug '12: 自定义格式输出字段1,2 ------'
    # 自定义格式输出字段1,2
    awk -F: '{print "name:"$1"\tid:"$3}' /etc/passwd

    log debug '13:  显示每行有多少字段 ------'
    # 显示每行有多少字段
    # 注意：取其值 不需要加　＇$＇, 加了'$' 表示的含义是第几列的内容
    awk -F: '{print NF}' /etc/passwd

    log debug '14:  显示最后一列和倒数第二列 ------'
    awk -F: '{print $NF " == " $(NF-1)}' /etc/passwd

    log debug '15:  将每行字段数大于2的打印出来 ------'
    # 将每行字段数大于2的打印出来
    awk -F: 'NF>2 {print }' /etc/passwd

    log debug '16: 打印出/etc/passwd文件中的第5行 ------'

    # 注意：NR NF 取其值 不需要加　＇$＇, 加了'$' 表示的含义是第几列的内容

    #  打印出/etc/passwd文件中的第5行
    awk -F: 'NR==5 {print}' /etc/passwd

    log debug '16: 打印出/etc/passwd文件中的第5行和第6行 ------'
    # 打印出/etc/passwd文件中的第5行和第6行
    awk -F: 'NR==5||NR==6{print}' /etc/passwd

    log debug '17: 不显示第一行 ------'
    # 不显示第一行
    awk -F: 'NR!=1{print}' /etc/passwd

    log debug '18: 输出到文件中 1.txt ------'
    # 输出到文件中
    # 注意：
    #   1 自定义变量，取值的时候不需要加 '$'
    #   2 自定义变量，复制一点要加双引号，遇到字符会截断，如'.'
    awk -F: 'BEGIN{ path="1.txt" } {print > path}' /etc/passwd

    log debug '19: 输出到文件中 2.txt ------'
    awk -F: '{print > "2.txt"}' /etc/passwd

    log debug '20: 使用重定向输出到文件中 3.txt ------'
    #   使用重定向输出到文件中
    awk -F: ' {print}' /etc/passwd > 3.txt
}
