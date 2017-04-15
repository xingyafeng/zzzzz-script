#!/usr/bin/env bash

##############################################
##
##                  git
##
##############################################

function auto_git_push_gerrit()
{
    local branchN=
    local HEAD="HEAD:refs/for"
    local remoteN="origin"

    if [ $# -eq 1 ];then
        branchN=$1
    else
        branchN="`git branch | grep \* | cut -d ' ' -f2`"
    fi

    echo
    show_viy "branchN = $branchN"
    echo

    if [ "$branchN" ];then
        if [ -d .git ];then
            git push $remoteN $HEAD/$branchN
        fi
    fi
}

function auto_relpace_all_branch()
{
    if [ $# -eq 2 ];then
        branchS=$1
        branchD=$2
    else
        show_vir " xargs is error, please check it !"
    fi

    RMT=origin
    MSG="移动${branchS}分支到${branchD}"
    REFS="refs/remotes/$RMT" #只过滤远程分支，不处理本地分支
    PAT="\"[\b]*${branchS}[\b]*\""
    REP_TO=""

    branchN="`git branch | grep \* | cut -d ' ' -f2`"
    default_remote_branch=`git for-each-ref --format "%(refname)" $REFS | grep "$RMT/$branchN"`

    echo "-- $MSG -- $default_remote_branch --"

    for B in `git for-each-ref --format "%(refname)" $REFS`
    do
        STR=`git grep -c1 -n -P "$PAT" $B`
        #echo "@@@@ $B   $STR "

        if [ -z "$STR" ]; then
            continue;
        fi

        if [ $B ];then
            git reset --hard $B
            git clean -fxd
        fi

        #去掉前缀 refs/ 方便提交到 refs/for
        B=${B:${#REFS}+1}

        if [ "HEAD" == "$B" ]; then
            continue
        fi

        LINE=""

        echo "$STR" | while read -r LINE || [ -n "$line" ];
        do
            LINE=${LINE#*:} # 第一个:之前为分支名，去掉
            #echo " line = $LINE"

            FNM="${LINE%%:*}" #去掉第一个:后的，为文件名(原字符串第二个:)
            echo " fum = $FNM"

            LINE=${LINE:${#FNM}+1} #去掉文件名之后就只有文件所在行和正文了
            #echo " line = $LINE"

            NUM="${LINE%%:*}" #去掉正文就是所在行数
            #echo " num = $NUM "

            STR=${LINE:${#NUM}+1}  #正文
            #echo " str = $STR"

            echo " -- $FNM -- $NUM -- $STR -- "

            #echo " -- ${STR/\breview/rv=\"http:\/\/gerrit.y\"} --  "
            #echo " -- $FNM -- $NUM -- "
            #echo '$NUM s/\(review="\)[^"]*/\1tt:\/\/t\.t/g q'
            #sed -i -e "$NUM s/\(review=\"\)[^\"]*/\1http:\/\/gerrit\.y/g" $FNM

            if [ -f $FNM ];then
                sed -i -e "s$\"[:space:]*${branchS}[:space:]*\"\$\"${branchD}\"$" $FNM
            fi
        done

        if true; then
            git diff $FNM
            git add -A
            git commit -m " $MSG "
            git cat-file -p HEAD
            git push $RMT HEAD:refs/for/$B
        else
            :
            #break
        fi
        echo
    done

    git reset --hard $default_remote_branch
}
