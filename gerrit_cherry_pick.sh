#!/usr/bin/env bash

## if error then exit
set -e

################################# common variate
shellfs=$0

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

function usge()
{
    echo ""
    show_vir "$0 args1 args2 args*"
    echo "    args1 : cherry-pick project  如: frameworks device vendor etc"
    echo "    args2 : the same args1 ."
    echo
    show_vig "    e.g. $0 frameworks device vendor "
}

function cherry_pick()
{
    local branch_name="${b}/master"

    if [[ -d ${p} ]]; then
        recover_standard_git_project ${p}
    fi

    cd ${p} > /dev/null

    git fetch -q `git remote`
    git checkout -q "${branch_name}"

    rm -rf "$(git rev-parse --git-dir)/rebase-gerrit" "$(git rev-parse --git-dir)/rebase-apply"
    gerrit-cherry-pick `git remote` `ssh-gerrit gerrit query status:open ${project_name}/${p} | grep number | awk '{ print $2 }' | sed -n '1p'`
    git-push-gerrit "${branch_name}"

    cd .. > /dev/null
}

function main()
{
    local board_list=("mt6580" "mt6735")
    local project_name=""

    if [[ $# -lt 1 ]]; then
        usge
        return;
    fi

    _inlist=(${board_list[@]})
    show_vir "select yunovo board : "
    select_choice board

    case ${board} in

        mt6580)
            project_name=K26
            ;;

        mt6735)
            project_name=k86A
            ;;
    esac

    for b in `git --git-dir=.repo/manifests/.git branch -r | grep -v "\->" | awk -F '/' '{ print $2 }' | sort | uniq`;
    do
        if [[ "${project_name}" == "K26" ]]; then
            case ${b} in
                k26|k26s|k27|k28s|k29|mk01|mk26) ## mk21==k21

                    for p in `cat .repo/manifest.xml  | egrep "<project" | awk '{ print $2 }' | awk -F '"' '{print $2}' | awk -F '/' '{ print $2 }'`
                    do
                        for n in $@
                        do
                            if [[ "${n}" == "${p}" ]]; then
                                case ${p} in
                                    device|frameworks|external|packages|vendor)
                                        show_vig "cherry-pick ... ${project_name}/${p} --- ${b}"
                                        cherry_pick
                                        ;;
                                esac
                            fi
                        done
                    done
                    ;;

                *)
                    :
                    ;;
            esac
        elif [[ "${project_name}" == "k86A" ]]; then
            case ${b} in
                k88c|k89|mx1)

                    for p in `cat .repo/manifest.xml  | egrep "<project" | awk '{ print $2 }' | awk -F '"' '{print $2}' | awk -F '/' '{ print $2 }'`
                    do
                        for n in $@
                        do
                            if [[ "${n}" == "${p}" ]]; then
                                case ${p} in
                                    device|frameworks|external|packages|vendor)
                                        show_vig "cherry-pick ... ${project_name}/${p} --- ${b}"
                                        cherry_pick
                                        ;;
                                esac
                            fi
                        done
                    done
                    ;;

                *)
                    :
                    ;;
            esac
        fi
    done
}

main $@
