#!/usr/bin/env bash

##################################
#
#  知识点:
#     频繁切换目录， pushd/popd/dirs
#
#     1、dirs [-clpv] [+N | -N]
#        Display the list of currently remembered directories. Directories are added to the list with the pushd command;
#        the popd command removes directories from the list.
#        The current directory is always the first directory in the stack.
#     2、popd [-n] [+N | -N]
#        When no arguments are given, popd removes the top directory from the stack and performs a cd to the new top directory.
#        The elements are numbered from 0 starting at the first directory listed with dirs; that is, popd is equivalent to popd +0.
#     3、pushd [-n] [+N | -N | dir]
#        Save the current directory on the top of the directory stack and then cd to dir.
#        With no arguments, pushd exchanges the top two directories and makes the new top the current directory.
#
#        e.g pushd <-> cd -
#
#  问题点:
#     如果你要在脚本里频繁改变当前目录，可以看看 pushd/popd/dirs 等命令
#     可能你在代码里面写的 cd/pwd 命令都是没有必要的
#
##################################
function test_dir() {

    show_vip "start current dir: "`dirs`

    for ts in `find . -maxdepth 1 -name .git -prune -o -name "*" -type d` ; do
        pushd ${ts} > /dev/null
        echo 'All dirs : '`dirs`
        echo 'one dirs : '`dirs +0`
        echo 'two dirs : '`dirs +1`
        echo '----'
        popd > /dev/null
    done

    echo
    show_vip "end current dir: "`dirs`
}

##################################
#
#  知识点:
#                           ${@:位置:个数}
#  1. 参数的获取方法，${2-} ${@:2:1}
#  2. 文件定向到标准输入　使用 exec  0 <标准输入> 1<标准输出> 2<标准错误>
#  3. while read line;do echo $line;done 循环一行一行读取
#
##################################
function test_exec() {

    # 拿到默认参数 $1 的值，可以指定默认值
    filename=${1-}

    if [[ -n "$filename" ]]; then
        # 将文件定向至标准输入
        exec 0< ${filename}
    fi

    while read line; do
        echo ${line}
    done
}

##################################
#
#  知识点
#  1. 直接引用
#　2. 间接引用
#
##################################
function test_indirect() {

    local a=letter_of_alphabet
    local letter_of_alphabet=z

    echo "a = $a"           # Direct reference.
    echo "Now a = ${!a}"    # Indirect reference.
}

##################################
#
#  知识点
#  1. 备份文件，无须重复copy份，利用bash的展开特性可以这样做
#　   e.g  touch test{1,2,3} 创建个文件　test1 test2 test3　
#
##################################
function test_backup_file() {

    if [[ ! -f config/file.list  ]]; then
        touch config/file.list
    fi

    cp -vf config/file.list{,.$(date +'%Y.%m.%d_%H.%M.%S')}
}

# 测试读取txt文件
function read_txt()
{
    declare -A dic
    declare -A dicN
    declare -a update

    echo ${update[@]}
    echo "--empty--"

    while read p;do
        echo "key = ${p%=*}"
        #echo "value = ${p##*=}"

        if [[ "${p%=*}" != "version_start" && "${p%=*}" != "version_end" ]];then
            dic[${p%=*}]=${p##*=}
        fi

    done < fs/test.txt

    echo "###################"

    while read p;do
        echo "key = ${p%=*}"
        #echo "value = ${p##*=}"

        if [[ "${p%=*}" != "version_start" && "${p%=*}" != "version_end" ]];then
            dicN[${p%=*}]=${p##*=}
        fi

    done < fs/testN.txt

    echo "-------"
    for i in ${!dic[@]}
    do
        echo "$i --- ${dic[$i]}"
    done

    echo "========="
    for i in ${!dicN[@]}
    do
        echo "$i --- ${dicN[$i]}"
    done

    echo "&&&&&&&&&&&&&&&&&&&&&&&&"

    for i in ${!dic[@]}
    do
        for j in ${!dicN[@]}
        do
            if [[ ${i} == ${j} ]];then
                echo "start : $i == $j ${dic[$i]} --- ${dicN[$j]} "

                if [[ ${i} == "main_version" && ${j} == "main_version" ]];then
                    if [[ ${dic[$i]} -lt ${dicN[$j]} ]];then
                        unset update
                        update[${#update[@]}]=all
                        echo "---- end ----"
                        echo ${update[@]}
                        return
                    fi
                else
                    if [[ ${dic[$i]} -lt ${dicN[$j]} ]];then
                        update[${#update[@]}]=${i}
                    fi
                fi
            else
                :
            fi
        done
    done

    echo "---- end ----"

    echo ${update[@]}
}

ret0=false
ret1=false

# 测试程序返回值
function test_retrun_value
{
    local ret=1

if ${ret0};then
    echo ${ret}
    return 1
fi

if ${ret1};then
    ret=2
    echo ${ret}
    return 0
fi
    echo ${ret}
}

# 测试子进程
function test_process()
{
    local ret=hello
    local str=$1

    ret=(`echo ${str} | sed 's/[   ]\+//g'`)

    echo ${ret}
}

# 测试数字
function test_is_number()
{
    local n=$1

    expr ${n} "+" 10 &> /dev/null

    if [[ $? -eq 0  ]];then
        echo "$n is number"
    else
        echo "$n not number"
    fi
}

### 测试计算方法
test-let()
{
	no1=100
	no2=120

	echo "--------------------------符号 运算--------------------------"
	result=$((no1+no2))
	result=$[ no1 + no2 ]
	echo ${result}

	echo "--------------------------expr--------------------------"
	let result=no1+no2
	result_expr=`expr 3 + 5`

	let no2++
	let no1--
	let result+=10

	echo ${result}
	echo ${result_expr}

    echo "--------------------------expr make compile whole time------------------------------"
    startT=`date +'%Y-%m-%d %H:%M:%S'`
    #sleep 4
    endT=`date +'%Y-%m-%d %H:%M:%S'`
    hh=
    mm=
    ss=

    #userT=$(($(date +%s -d "$endT") - $(date +%s -d "$startT")))
    userT=$(($(date +%s -d '2010-01-01 11:11:11') - $(date +%s -d '2010-01-01')))

    echo ${userT}

    hh=$((userT/3600))
    mm=$[ (userT - hh*3600) / 60 ]
    ss=$[ (userT - hh*3600 - mm*60) ]
    echo "hh = $hh"
    echo "mm = $mm"
    echo "ss = $ss"

	echo "----------------------------bc----------------------------------"
	no=54
	echo "4 * 0.56" | bc
	result=`echo "$no * 1.5 " | bc`
	echo ${result}
}
