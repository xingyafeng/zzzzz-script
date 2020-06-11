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

function auto_create_git_refs()
{
    local sz_hash_value=""
    local sz_commit_msg="Created project"
    local sz_all_project_name="[access]\n\tinheritFrom = All-Projects"

    ## 1.
    sz_hash_value=`echo -e "[access]\n\tinheritFrom = All-Projects" | git  hash-object -w --stdin`

    ## 2.
    sz_hash_value=`echo -e "100644 blob ${sz_hash_value}\tproject.config" | git mktree`

    ## 3.
    sz_hash_value=`git commit-tree ${sz_hash_value} -m "$sz_commit_msg"`

    ## 4.
    git update-ref refs/meta/config ${sz_hash_value}
}

function main()
{
    local sz_findfs="*.git"
    local sz_config_file=refs/meta/config
    local sz_git_path=`find . -type d -name "$sz_findfs" | sort`

    echo
    show_vip "---> auto create git refs start ..."
    echo

    for p in ${sz_git_path}
    do
        cd ${p} > /dev/null

        echo "    path = $p"

        if [[ ! -e ${sz_config_file} ]];then
            auto_create_git_refs
        else
            show_vir "    $sz_config_file is exist ..."
            echo
        fi

        cd - > /dev/null
    done

    echo
    show_vip "---> auto create git refs end ..."
    echo
}

main
