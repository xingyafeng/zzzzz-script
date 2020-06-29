###########################################################
###
###				debug functions
###
###
### date 	: 2020-06-29 14:48
### author  : yafeng
###
###########################################################
#!/usr/bin/env bash

# 调试钩子函数
function __debug__
{
    [[ "${__debug__}" == "on" ]] && $@ || :
}

function EXITTRAP() {

    show_vir "[LINE:$1] Exit: Command or function exited with status $?"
}

function ERRTRAP() {

    show_vir "[LINE:$1] Error: Command or function exited with status $?"
}

function DEBUGTRAP() {

    local datetime=`date +'%F %H:%M:%S'`

    unset print_var_list
    print_var_list[${#print_var_list[@]}]=shellfs

    __blue__ "[debug] $datetime\tfuncname: ${FUNCNAME[0]}\t[line:`caller 0 | awk '{print$1}'`]\tlen${#print_var_list[@]}"
    for v in ${print_var_list[@]}
    do
        eval "echo ${v} = \$${v}"
    done
    echo "-----------------------------"
    echo
}

#######################
###    file EOF    ###
######################
