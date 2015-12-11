#!/bin/bash

function test-pwd
{
	local test_path=`pwd`
	show_vir "test_path = $test_path"
}


function cecho
{
	echo $@ '#'
}

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