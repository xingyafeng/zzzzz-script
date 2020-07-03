#!/usr/bin/env bash

# eval
function test_eval()
{
    declare -A print_var

    preinstall_apk_name=yov
    preinstall_apk_package_name=com.yunovo

    print_var[${#print_var[@]}]=preinstall_apk_name
    print_var[${#print_var[@]}]=preinstall_apk_package_name

    for v in ${print_var[@]}
    do
        var="echo $v = \$$v"
        eval ${var}
    done
}

# 测试关键字 read
function test_read()
{
    read -p "Enter your name : " name

    echo ${name}
}

# 测试 $$
function test_env
{
	echo $*
	echo $@
	echo $#
	echo $?

	### $*  整体
	for args in "$*"; do
		#statements
		show_vir ${args}
	done

	### $@  单个
	for args in "$@"; do
		#statements
		show_vir ${args}
	done

	### $@  单个
	for args in $*; do
		#statements
		show_vir ${args}
	done

	## 当前进程ID号
	echo $$

	## 后台最后一个进程号
	echo $!
}
