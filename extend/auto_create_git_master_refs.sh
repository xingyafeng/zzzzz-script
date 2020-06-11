#!/usr/bin/env bash

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

function main()
{
    local sz_findfs="*.git"
    local sz_config_file=refs/meta/config
    local sz_git_path=`find . -type d -name "$sz_findfs" | sort`

    echo
    show_vip "---> auto create git refs master start ..."
    echo

    for p in ${sz_git_path}
    do
        cd ${p} > /dev/null

        echo "    $p"
        if [[ "`git for-each-ref refs/heads/yunos/yunovo/master`" ]];then
            show_vir "    [`git for-each-ref refs/heads/yunos/yunovo/master`] is exist ..."
            echo
        else
            show_vip "    --> update ref master"
            echo
            git update-ref refs/heads/yunos/yunovo/master refs/heads/mt6735_pb5.0.2_yunovo_tron_t8
        fi

        cd - > /dev/null
    done

    echo
    show_vip "---> auto create git refs master end ..."
    echo
}

main
