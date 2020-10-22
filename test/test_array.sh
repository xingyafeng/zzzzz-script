#!/usr/bin/env bash

## 打印关联数组
function test_print_ass_array()
{
    declare -a key
    declare -a value
    declare -A ass

    key+=($1)
    value+=($2)

    if [[ ${#key[@]} -ne ${#value[@]} ]]; then
        echo "key vaule no match ..."
        return
    fi

    for k in ${!key[@]} ; do
        for v in ${!value[@]} ; do
            if [[ ${k} == ${v} ]]; then
                echo ${key[$k]}
                echo ${value[$v]}
                echo '-----'
                ass[${key[$k]}]=${value[$v]}
            fi
        done
    done

    for a in ${!ass[@]} ; do
        echo " $a --- ${ass[$a]} "
    done

    echo ${ass[@]} -- ${!ass[@]}
}

# e.g test_print_ass_array "5 6 7" "a b c"

# 列出所有键值对
function print_key_value() {

    declare -A color

    color["red"]="#ff0000"
    color["green"]="#00ff00"
    color["blue"]="#0000ff"
    color["white"]="#ffffff"
    color["black"]="#000000"

    #获取所有元素值
    for value in ${color[*]}
    do
        echo ${value}
    done

    echo "****************"

    #获取所有元素下标（键）
    for key in ${!color[*]}
    do
        echo ${key}
    done

    echo "****************"

    #列出所有键值对
    for key in ${!color[@]}
    do
        echo "${key} -> ${color[$key]}"
    done
}

# 测试数组相加
function test_array_add() {

    declare -a arr
    declare -a tmp

    unset arr tmp

    for i in {1..9} ; do
        arr[${#arr[@]}]=${i}
    done
    unset arr tmp

    tmp=(a b c)

    arr+=(${tmp[@]})

    echo ${arr[@]}
}

# 测试数组 去重
function test_array_uniq
{
    declare -a array
    declare -a array_a=(a b c)

    if [[ "$1" ]];then
        array[${#array[@]}]=$1
    fi

    if [[ "$2" ]];then
        array[${#array[@]}]=$2
    fi

    if [[ "$3" ]];then
        array[${#array[@]}]=$3
    fi

    echo ${array[@]}
    echo "all =" ${array_a[@]}

    for p in ${array_a[@]}
    do
        echo "p = $p"
        array[${#array[@]}]=${p}
    done

    echo "all_end =" ${array[@]}
    array=($(awk -vRS=' ' '!a[$1]++' <<< ${array[@]}))

    ## 去重后的数组
    echo "end ${array[@]}"
}

# 测试普通数组
test_array_common()
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
	while [[ ${j} -lt ${#month_name[@]} ]]; do
	    echo ${month_name[$j]}
	    let j++
	done
}