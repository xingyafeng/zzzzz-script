#!/bin/bash

function usge()
{
    echo ""
    echo -e -n "\e[1;34m$0 args1 args2\e[0m"
    echo
    echo
    echo "    args1 : 查找manifest文件名, 即manifest目录下的xml文件, 如: default.xml yunovo_packages.xml "
    echo "    args2 : 查找项目名称, 如: CarRecordUsb "
    echo
    echo "    e.g. $0 yunovo_packages.xml CarRecordUsb"
    echo
}

function main()
{
    local file project_name project_branch

    case $# in

        2)
            # manifest下的文件
            file=$1

            # 项目名称
            project_name=$2

            # 创建空文件
            :> branch.name.log
        ;;

        *)
            usge
            return 0
        ;;
    esac

    {
        echo -e "    项目名    \t    manifest    \t\t    项目分支"
        echo -e "------------------------------------------------------------------------------------------"
    } 2>&1 | tee -a branch.name.log

    for b in `git branch -r | sort`
    do
        if [[ "$b" != "->" ]];then
            if [[ -n "`git ls-tree --name-only ${b} | grep ${file}`" ]];then
            {
                if [[ -n "`git blame ${b} ${file} | egrep ${project_name}`"  ]]; then
                    project_branch=`git blame ${b} ${file} | egrep ${project_name} | awk '{print $(NF-1)}' | awk -F '"' '{print $2}'`

                    #echo "manifest branch = " ${b} "; project : " ${project_name} "; branch = " ${project_branch}

                    # 删除分支前缀 origin/
                    b=`echo ${b} | sed 's#origin/##'`

                    # 当分支名为空,说明与manifest分支一样,需要重新赋值
                    if [[ "${project_branch}" =~ ${project_name} ]]; then
                        project_branch=${b}
                    fi

                    # 过滤废弃的分支
                    case ${b} in

                    *test|*volte*)
                        continue
                        ;;&
                    *)
                        :
                        ;;
                    esac

                    printf "%-s\t %-28s\t %s\n" ${project_name} ${b} ${project_branch}
                fi
            } 2>&1 | tee -a branch.name.log
            fi
        fi
    done
}

main "$@"