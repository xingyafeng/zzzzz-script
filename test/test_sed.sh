#!/usr/bin/env bash

# 多行处理 N;P;D -> n,p,d
# 将多行内容写成一样，使用分隔符$op隔开
function test_join_lines() {

    local op path

    case $# in

        2)
            op=${1:-}
            path=${2:=config/text}
            ;;
        *)
            log error "The args has error ..."
            ;;
    esac

    sed 'H;$!d;${x;s/^\n//;s/\n/'${op}'/g}' ${path}
    #sed ':a;$!N;s/\n/'${op}'/;ta' ${path}

    echo
}
