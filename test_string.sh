#!/bin/bash

test-string()
{
	var=chiphd

	# get string length
	length=${#var}	

	show_vir $length
}


test-let()
{
	no1=100
	no2=120


	result=$((no1+no2))
	result=$[ no1 + no2 ]
	echo $result 

	echo "--------------------------符号 运算--------------------------"
	let result=no1+no2
	result_expr=`expr 3 + 5`

	echo $result 
	echo $result_expr

	echo "----------------------------bc----------------------------------"
}