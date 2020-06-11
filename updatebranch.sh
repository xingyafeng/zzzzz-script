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
            git commit -m "manifest branch renamed to `echo ${b} | sed s#origin/##g`"
        fi

        git-push-gerrit
    fi
}

function mm() {

    local branch=

    for x in `ls` ; do
        if [[ -f ${x} ]]; then
            if [[ -n "`cat ${x} | egrep -w ${dest}`" ]]; then

                case ${manifest_branch} in

                    HEAD|yunovo/empty)
                        continue;
                    ;;

                    *)
                        for bb in ${branchs[@]} ; do
                            if [[ ${bb} == K26 ]]; then
                                branch=${bb}/${dest}
                            else
                                branch="`echo ${bb} | tr 'A-Z' 'a-z'`/${dest}"
                            fi

                            if [[ "${manifest_branch}" == "${branch}" ]]; then
                                show_vir "==> -- ${bb} -- ${dest}"

                                if ${DEBUG}; then
                                    # 更新分支名
                                    sed -i "s#${dest}#${branch}#g" ${x}
                                else
                                    echo "sed -i \"s#${dest}#${branch}#g\" ${x}" >> ${script_p}/config/branchs.txt
                                fi
                            fi
                        done
                    ;;
                esac

                case ${manifest_branch} in

                    HEAD|yunovo/empty)
                        echo "continue >> ${manifest_branch}"
                        continue;
                        ;;

                    *)
                        if ${DEBUG}; then
                            for bb in ${branchs[@]} ; do
                                if [[ ${branch} == K26 ]]; then
                                    branch=${bb}/${dest}
                                else
                                    branch="`echo ${bb} | tr 'A-Z' 'a-z'`/${dest}"
                                fi

                                if [[ "${manifest_branch}" == "${branch}" ]]; then
                                    __green__ "-- git commit -> ${b} == ${manifest_branch}"
                                    echo "----------------------------------------------------------------"
                                    echo

                                    # 提交代码
                                    git_commit
                                fi
                            done
                        else
                            for bb in ${branchs[@]} ; do
                                if [[ ${bb} == K26 ]]; then
                                    branch=${bb}/${dest}
                                else
                                    branch="`echo ${bb} | tr 'A-Z' 'a-z'`/${dest}"
                                fi

                                if [[ "${manifest_branch}" == "${branch}" ]]; then
                                    __green__ "-- git commit -> ${bb} == ${manifest_branch}"
                                    echo "----------------------------------------------------------------"
                                    echo
                                fi
                            done
                        fi
                        ;;
                esac
            fi
        fi
    done
}

function main()
{
    local dest="master"
    local branchs=(A36 D1402 K26 k1402 k18 k570e k86 k66 k6806 k86A xt273 m170m m66 s802)

    local manifest_branch=

    :> ${script_p}/config/branchs.txt
    for b in `git branch -r | egrep -E -w 'a36|d1402|K26|k1402|k18|k570e|k86|k66|k6806|k86A|xt273|m170m|m66|s802'`;
    do
        manifest_branch=`echo ${b} | sed s#origin/##g`

        if [[ "${b}" != "->" ]];then

            echo "----------------------------------------------------------------"
            # 切换分支并更新.
            git checkout ${manifest_branch} && git pull -q

            mm
        fi
    done
}

main $@
