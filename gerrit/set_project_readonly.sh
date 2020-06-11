#!/usr/bin/env bash

# if error;then exit
set -e

# exec shell
shellfs=$0

# init function
. "`dirname $0`/yunovo_init.sh"

####################################################################################################
##  配置项目的继承关系:
##    1. 查询需要设置继承关系项目，其原本的继承关系图,方便反悔。 ${tmpfs}/ls-project.log
##    2. 配置新的继承关系 ssh-gerrit-set-project-parent ${the_project} ${the_parent}
##    3. 查询新配置的继承关系的正确性 同1
##    4. 若反悔，只是需要将变量the_parent修改为原来的即可。当原来的父亲存在多个时，就需要加以区分。
##
####################################################################################################
function main() {

    local the_parent=ReadOnly # All-Projects

    # 备份各个项目原先的权限结构
    ssh-gerrit gerrit ls-projects -t | egrep "All-Projects|A36/android|D1402|K26|k1402/alps|k18|k570e|k86/|k66|k6806|k86A|xt273|m170m|m66|s802|ReadOnly" > ${tmpfs}/ls-project.log

    for the_project in `ssh-gerrit gerrit ls-projects | egrep "A36/android|D1402|K26|k1402/alps|k18|k570e|k86/|k66|k6806|k86A|xt273|m170m|m66|s802"`
    do
        show_vig "--> set parent 0: ---- ${the_project}"
        ssh-gerrit-set-project-parent ${the_project} ${the_parent}
        show_vir "---- set parent end."
    done

    for the_project in `ssh-gerrit gerrit ls-projects | egrep '^platform' | awk -F/ '{print $1 "/" $2}' | sort | uniq`
    do
        while read prj ;do
            if [[ ${prj} == `basename ${the_project}` ]]; then

                if [[ ${prj} == "md32" ]]; then
                    the_project=${the_project}/${prj}
                fi

                show_vig "--> set parent 1: ---- ${the_project}"
                ssh-gerrit-set-project-parent ${the_project} ${the_parent}
                show_vir "---- set parent end."
            fi
        done < ${script_p}/config/micro.txt
    done
}

main $@
