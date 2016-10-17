#!/bin/bash

#测试 pwd
function test-pwd
{
	local test_path=`pwd`
	show_vir "test_path = $test_path"
}


function cecho
{
	echo $@ '#'
}

#测试字符串 提取
function tstring
{
	jpg_name="chiphd.sameple.jpg"

	## %  从左往右匹配 遇到最后一个就结束  获取文件名称
	name_1=${jpg_name%.*}

	## %% 从左往右匹配 遇到第一个就结束
	name_2=${jpg_name%%.*}

	## # 从右支左 遇到最后一个 匹配结束
	name_11=${jpg_name#*.}

	## ## 从右支左 遇到第一个 匹配结束   获取后缀名
	name_22=${jpg_name##*.}

	echo $jpg_name
	echo --------------------

	echo File '%'  name: $name_1
	echo File '%%' name: $name_2
	echo File '#'  name: $name_11
	echo File '##' name: $name_22
}

# 测试环境变量
function test-env
{
	echo $*
	echo $@
	echo $#
	echo $?

	### $*  整体
	for args in "$*"; do
		#statements
		show_vir $args
	done

	### $@  单个
	for args in "$@"; do
		#statements
		show_vir $args
	done

	### $@  单个
	for args in $*; do
		#statements
		show_vir $args
	done

	## 当前进程ID号
	echo $$

	## 后台最后一个进程号
	echo $!
}

### 测试计算方法
test-let()
{
	no1=100
	no2=120

	echo "--------------------------符号 运算--------------------------"
	result=$((no1+no2))
	result=$[ no1 + no2 ]
	echo $result

	echo "--------------------------expr--------------------------"
	let result=no1+no2
	result_expr=`expr 3 + 5`

	let no2++
	let no1--
	let result+=10

	echo $result
	echo $result_expr

    echo "--------------------------expr make compile whole time------------------------------"
    startT=`date +'%Y-%m-%d %H:%M:%S'`
    #sleep 4
    endT=`date +'%Y-%m-%d %H:%M:%S'`
    hh=
    mm=
    ss=

    #userT=$(($(date +%s -d "$endT") - $(date +%s -d "$startT")))
    userT=$(($(date +%s -d '2010-01-01 11:11:11') - $(date +%s -d '2010-01-01')))

    echo $userT

    hh=$((userT/3600))
    mm=$(((userT - hh*3600) / 60))
    ss=$((userT - hh*3600 - mm*60))
    echo "hh = $hh"
    echo "mm = $mm"
    echo "ss = $ss"

	echo "----------------------------bc----------------------------------"
	no=54
	echo "4 * 0.56" | bc
	result=`echo "$no * 1.5 " | bc`
	echo $result
}

test-array()
{
	local array_var=(1 2 3 4 5 6 7 8 9 0)
	local index=5

	local array[0]='test0'
	local array[1]='test1'
	local array[2]='test2'
	local array[3]='test3'
	local array[4]='test4'
	local array[5]='test5'
	local array[6]='test6'

	#注意是打括号
	local array_length=${#array_var[*]}

	show_vir '===========简单数组================='
	echo "array_var[6] = ${array_var[$index]}"
	echo "length = $array_length"

	if true;then
		echo ${array_var[*]}
		echo --------------------------------
		echo ${array_var[@]}

		echo
		##便利数组
		for arr in ${array[@]}; do
			#statements
			echo ${arr}
		done
		echo
	fi

	show_vir '===========关联数组================='

	declare -A month_name
	local month_name=( [1]='Jan' [2]='Feb' [3]='Mar' [4]='Apr' [5]='May' [6]='Jun' [7]='Jul' [8]='Aug' [9]='Sep' [10]='Oct' [11]='Nov' [12]='Dec' )
	local month_length=${#month_name[*]}

	echo "month_name =  ${month_name[1]}"
	echo "---------------------------------"
	echo "length = $month_length"

	### 实现顺序便利  一般for   method one
	for (( i = 0; i < $month_length+1 ; i++ )); do
		#statements
		echo ${month_name[$i]}
	done

	echo ==============

	###  for ... in ...  method two
	for month in ${month_name[@]}; do
		#statements
		echo ${month[@]}
	done

	# 列出索引
	echo ${!month_name[*]}

	echo ==============

	### for  method three
	for i in "${!month_name[@]}"; do
		printf "%s\t%s\n" "$i" "${month_name[$i]}"
	done

	echo ==============

	### while method four
	local j=0
	while [ $j -lt ${#month_name[@]} ]; do
	    echo ${month_name[$j]}
	    let j++
	done
}
