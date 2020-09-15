#!/usr/bin/env bash

# if error;then exit
set -e

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

# 1、mirror debug
build_mirror_debug=

# 仓库名称
declare -a git_prj_name
declare -a manifest_branch
declare -a prefix

# 并发数,并发数过大可能造成系统崩溃
Qp=
# 存放进程的队列
Qarr=();
# 运行进程数
run=0
# 调试开关
DEBUG=false

# 将进程的添加到队列里的函数
function push() {
	Qarr=(${Qarr[@]} $1)
	run=${#Qarr[@]}
}

# 检测队列里的进程是否运行完毕
function check() {
	oldQ=(${Qarr[@]})
	Qarr=()
	for p in "${oldQ[@]}";do
		if [[ -d "/proc/$p" ]];then
			Qarr=(${Qarr[@]} ${p})
		fi
	done
	run=${#Qarr[@]}
}

function download_mirror() {

    local xml=
    declare -a tmp

    cd ${tmpfs}/manifest > /dev/null

    for mb in ${manifest_branch[@]} ; do
        if [[ ${mb} =~ '.xml' ]]; then
            xml=${mb}
        else
            xml=${mb}.xml
        fi

        if [[ -f "${xml}" ]]; then
            local append=$(xmlstarlet sel -T -t -m /manifest/remote  -v "concat(@fetch,'')" -n ${xml})
            if [[ -n "${append}" ]]; then
                append=$(echo ${append} | awk -F ':' '{print $NF}' | sort -u)
            fi

            unset tmp
            unset git_prj_name
            tmp[${#tmp[@]}]=$(xmlstarlet sel -T -t -m /manifest/project -v "concat(@name,' ')" -n ${xml} | sort -u)

            if [[ -n "${append}" ]]; then
                for t in ${tmp[@]} ; do
                    git_prj_name[${#git_prj_name[@]}]=${append}/${t}
                done
            else
                git_prj_name[${#git_prj_name[@]}]+=${tmp[@]}
            fi

            if [[ "${DEBUG}" == "true" ]]; then
                __green__ "[git] project: ${mb}"
                echo 'append : ' ${append}
                echo ${git_prj_name[@]}
                echo
            fi

            download_mirror_repository
        fi
    done

    cd - > /dev/null
}

function download_mirror_repository() {

    pushd ${mirror_p} > /dev/null

    for g in ${git_prj_name[@]} ; do

        git_path=`dirname ${g}`
        git_name=`basename ${g}`

        if [[ -n "${append}" ]]; then
            if [[ "${git_path}" =~ "${append}" ]]; then
                if [[ `dirname "${git_path}"` == '.' ]]; then
                    git_path='.'
                else
                    git_path=`echo "${git_path}" | sed "s#${append}/##"`
                fi
            fi
        fi

        if [[ ! -d ${git_path} ]]; then
            mkdir -p ${git_path}
        fi

        if [[ "${DEBUG}" == "true" ]]; then
            echo '------'
            echo 'git_path = ' ${git_path}
            echo 'git_name = ' ${git_name}
            echo '------'
            echo
        fi

        pushd ${git_path} > /dev/null

        if [[ ! -d ${git_name}.git ]]; then

            if [[ "${DEBUG}" == "true" ]]; then
                __green__ 'pwd = ' $(pwd)
                __green__ "path, name = " ${git_path} ',' ${git_name}
                __green__ "git clone --mirror ${default_gerrit}:${g}.git &"
            else
                git clone --mirror ${default_gerrit}:${g}.git &
            fi
            push $!
            while [[ ${run} -gt ${Qp} ]];do
                check
                sleep 0.1
            done
        else
            pushd ${git_name}.git > /dev/null
            git remote update &
            push $!
            while [[ ${run} -gt ${Qp} ]];do
                check
                sleep 0.1
            done
            popd > /dev/null
        fi

        popd > /dev/null
    done

    popd > /dev/null
    wait

    echo "Running time is $SECONDS."
}

function get_process() {

    if [[ ${JOBS} -gt 8 ]]; then
        Qp=$((JOBS/4))
    else
        Qp=${JOBS}
    fi
}

function set_manifest_branch() {

    manifest_branch[${#manifest_branch[@]}]=mt6762-tf-r0-v1.1-dint
    manifest_branch[${#manifest_branch[@]}]=sm7250-r0-seattletmo-dint
    manifest_branch[${#manifest_branch[@]}]=sm6125-r0-portotmo-dint
    manifest_branch[${#manifest_branch[@]}]=qct-sm4250-tf-r-v1.0-dint

    for branch in ${mirror_branch} ; do
        manifest_branch[${#manifest_branch[@]}]=${branch}
    done

    # 去重
    manifest_branch=($(awk -vRS=' ' '!a[$1]++' <<< ${manifest_branch[@]}))
}

function handle_common_variable() {

    if [[ ${build_mirror_debug} == "true" ]]; then
        mirror_p=~/mirror
    else
        mirror_p=~/mirror
    fi

    if [[ ! -d ${mirror_p} ]]; then
        mkdir ${mirror_p}
    fi

    # 拿到进程数
    get_process

    # 设置要下载的分支名
    set_manifest_branch

    # 下载 manifest
    git_sync_repository gcs_sz/manifest master
}

function handle_vairable() {

    # mirror项目名

    build_mirror_debug=${mirror_debug:-false}
    DEBUG=${build_mirror_debug:-false}

    handle_common_variable
}

function print_variable() {

    echo
    echo "JOBS  = " ${JOBS}
    echo "DEBUG = " ${DEBUG}
    echo '-----------------------------------------'
    echo "build_mirror_debug = " ${build_mirror_debug}
    echo '-----------------------------------------'
    echo
}

function init() {

    handle_vairable
    print_variable
}

function main() {

    local mirror_p=

    local git_path=
    local git_name=

    init

    # 下载、更新mirror
    download_mirror
}

main "$@"