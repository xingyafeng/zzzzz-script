#!/usr/bin/env bash

declare -a _inlist

# 测试 function declaring
function test_select_choice()
{
    _target_arg=$1
    _arg_list=(${_inlist[@]})
    _outc=""

    select _c in ${_arg_list[@]}
    do
        if [[ -n "$_c" ]]; then
            _outc=${_c}
            break
        else
            for _i in ${_arg_list[@]}
            do
                _t=`echo ${_i} | grep -E "^$REPLY"`
                if [[ -n "$_t" ]]; then
                    _outc=${_i}
                    break
                fi
            done

            if [[ -n "$_outc" ]]; then
                break
            fi
        fi
    done

    if [[ -n "$_outc" ]]; then
        eval "${_target_arg}=${_outc}"
        export ${_target_arg}=${_outc}
    fi
}
