#!/usr/bin/env bash

# if error;then exit
set -e

# 当前Shell文件名
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

# debug
DEBUG=true

# 自动提交代码
function git_commit() {

    if [[ -d `git rev-parse --git-dir` ]];then

        if [[ -n "`git status -s`" ]];then
            git add . -A
        fi

        thisFiles=`git diff --name-only`
        if [[ -n "${thisFiles}" ]]; then
            git add ${thisFiles}
        fi

        thisFiles=`git diff --cached --name-only`
        if [[ -n "${thisFiles}" ]]; then
            git commit -m "git repositories renamed to \"platform\" in `echo ${b} | sed s#origin/##g`"
        fi

        git-push-gerrit
    fi
}

function mm() {

    for x in `ls` ; do
        if [[ -f ${x} ]]; then
            if [[ -n "`cat ${x} | egrep -w ${p}`" ]]; then
                show_vir "==> ${p} -- ${b} -- ${x}"

                if ${DEBUG}; then
                    # 更新新仓库名
                    sed -i "s#${p}#${dest}#g" ${x}
                else
                    echo "sed -i \"s#${p}#${dest}#g\" ${x}"
                fi

                case `echo ${b} | sed 's#origin/##g'` in
                    master)
                        echo ${x} >> ${script_p}/config/master.txt
                        for m in ${mani_xml[@]} ; do
                            if [[ -f ${m}.xml && ${m}.xml == ${x} ]]; then
                                if ${DEBUG}; then
                                    # 更新分支名
                                    sed -i "s#master#`echo ${m} | tr 'A-Z' 'a-z'`/master#g" ${x}
                                else
                                    echo "sed -i \"s#master#`echo ${m} | tr 'A-Z' 'a-z'`/master#g\" ${x}"
                                fi
                            fi
                        done
                    ;;

                    spt)
                        echo ${x} >> ${script_p}/config/spt.txt
                        for m in ${mani_xml[@]} ; do
                            if [[ -f ${m}.xml && ${m}.xml == ${x} ]]; then

                                if ${DEBUG}; then
                                    # 更新分支名
                                    sed -i "s#master#`echo ${m} | tr 'A-Z' 'a-z'`/master#g" ${x}
                                else
                                    echo "sed -i \"s#master#`echo ${m} | tr 'A-Z' 'a-z'`/master#g\" ${x}"
                                fi
                            fi
                        done
                    ;;

                    HEAD)
                        continue;
                    ;;

                    *)
                        for m in ${mani_xml[@]} ; do

                            if [[ "`echo ${b} | sed 's#origin/##g'`" == "`echo ${m} | tr 'A-Z' 'a-z'`/master" ]]; then
                                if ${DEBUG}; then
                                    # 更新分支名
                                    sed -i "s#master#`echo ${m} | tr 'A-Z' 'a-z'`/master#g" ${x}
                                else
                                    echo "sed -i \"s#master#`echo ${m} | tr 'A-Z' 'a-z'`/master#g\" ${x}"
                                fi
                            fi
                        done

                        echo ${b} | sed s#origin/##g >> ${script_p}/config/branch.txt
                    ;;
                esac

                case `echo ${b} | sed s#origin/##g` in

                    HEAD|yunovo/empty)
                        echo "continue >> `echo ${b} | sed s#origin/##g`"
                        continue;
                        ;;

                    *)
                        __green__ "-- git commit -> ${b} == `echo ${b} | sed s#origin/##g`"
                        echo "----------------------------------------------------------------"
                        echo

                        if ${DEBUG}; then
                            # 提交代码
                            git_commit
                        fi
                    ;;
                esac
            fi
        fi
    done
}

# 找出manifest 分支中包含 A36/android|D1402|K26|k1402/alps|k18|k570e|k86/|k66|k6806|k86A|xt273|m170m|m66|s802 仓库的分支
# 将上述分支都切换为合并的项目
function main()
{
    local dest="platform"
    local project=(A36/android D1402 K26 k1402/alps k18 k570e k86 k66 k6806 k86A xt273 m170m m66 s802)
    local mani_xml=(A36 D1402 K26 k1402 k18 k570e k86 k66 k6806 k86A xt273 m170m m66 s802)

    :> ${script_p}/config/branch.txt
    :> ${script_p}/config/master.txt
    :> ${script_p}/config/spt.txt

    for b in `git branch -r`;
    do
        #if [[ "${b}" != "->" && "`echo ${b} | sed s#origin/##g`" == "mk26/stable" ]];then
        if [[ "${b}" != "->" ]];then

            echo "----------------------------------------------------------------"
            # 切换分支并更新.
            git checkout `echo ${b} | sed s#origin/##g` && git pull -q

            for p in ${project[@]} ; do
                mm
            done
        fi
    done
}

main $@
