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

    local errcode=$?
    local lineno="$1"
    local funcstack="$2"
    local linecallfunc="$3"

    if [[ -n "${funcstack}" && -n "${linecallfunc}" ]]; then
        __red__ "[LINE:${linecallfunc}:${lineno}] Error: called at function : ${funcstack[0]}() - command exited with status : ${errcode} - "
    fi
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
