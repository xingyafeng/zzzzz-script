#!/usr/bin/env bash

### color purple
function show_vip
{
	if [[ "$1" ]]
	then
	#	echo "---------------------"
		for ret in "$@"; do
			echo -e -n "\e[1;35m$ret \e[0m"
		done
		echo
	fi
}

### color red
function show_vir
{
	if [[ "$1" ]]
	then
	#	echo "---------------------"
		for ret in "$@"; do
			echo -e -n "\e[1;31m$ret \e[0m"
		done
		echo
	fi
}

zzzzz_script=~/workspace/script/zzzzz-script

yunos_log=${zzzzz_script}/fs/yunos.log
yunovo_log=${zzzzz_script}/fs/yunovo.log

count=0

### color yellow
function show_viy
{
	if [[ "$1" ]]
	then
	#	echo "---------------------"
		for ret in "$@"; do
			echo -e -n "\e[1;33m$ret \e[0m"
		done
		echo
	fi
}

function check_git_folder_diff()
{
    while read yunovo;do

        #echo "--- yunovo = $yunovo"
        while read yunos;do

            local tmp=${yunos%%\/*}

            if [[ ${yunovo} == ${tmp} ]];then
               #echo "--- yunos = $yunos"
               #echo "-------------------------------"

               if [[ -d ${yunos} ]];then
                   show_vip "--> $yunos is exist ..."
               else
                   show_vir "--> $yunos is not exist ..."
               fi
            fi
        done < ${yunos_log}

        let count++
        show_viy "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ $count @"
    done < ${yunovo_log}
}

function main()
{
    echo main
}
