#!/usr/bin/env bash

# if error;then exit
set -e

# 仓库名称
declare -a git_prj_name
declare -a manifest_branch

# exec shell
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

# 并发数,并发数过大可能造成系统崩溃
Qp=$[JOBS/4]
# 存放进程的队列
Qarr=();
# 运行进程数
run=0

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

function get_git_path_from_xml() {

    local xml=

    cd ${tmpfs}/manifest > /dev/null

    for mb in ${manifest_branch[@]} ; do
        if [[ ${mb} =~ '.xml' ]]; then
            xml=${mb}
        else
            xml=${mb}.xml
        fi

        if [[ -f ${xml} ]]; then
            append=$(cat ${xml} | grep ${url}: | sed "s%.*${url}:%%" | sed 's%".*%%')
            echo "append ... ${append} ..."
            if [[ -n "${append}" ]]; then
                git_prj_name[${#git_prj_name[@]}]=${append}/`egrep -E '<project' ${xml} | grep name | egrep -v '<!--' | grep path | sed 's%.*name="%%' | sed 's%".*%%'`
                git_prj_name[${#git_prj_name[@]}]=${append}/`egrep -E '<project' ${xml} | grep name | egrep -v '<!--|path' | sed 's%.*name="%%' | sed 's%".*%%'`
            else
                git_prj_name[${#git_prj_name[@]}]=`egrep -E '<project' ${xml} | grep name | egrep -v '<!--' | grep path | sed 's%.*name="%%' | sed 's%".*%%'`
                git_prj_name[${#git_prj_name[@]}]=`egrep -E '<project' ${xml} | grep name | egrep -v '<!--|path' | sed 's%.*name="%%' | sed 's%".*%%'`
            fi
        fi
    done

    cd - > /dev/null
}

function download_mirror() {

    get_git_path_from_xml

    pushd ${mirror_p} > /dev/null

    for g in ${git_prj_name[@]} ; do
        git_path=`dirname ${g}`
        git_name=`basename ${g}`

        if [[ ! -d ${git_path} ]]; then
            mkdir -p ${git_path}
        fi

        pushd ${git_path} > /dev/null

        if [[ ! -d ${git_name}.git ]]; then

            git clone --mirror ${url}:${g}.git &
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

function main() {

    local url='git@shenzhen.gitweb.com'
    local mirror_p=/${tmpfs}/mirror

    local git_path=
    local git_name=

    if [[ ! -d ${mirror_p} ]]; then
        mkdir ${mirror_p}
    fi

    manifest_branch[${#manifest_branch[@]}]=q6125_portotmo

    for b in ${branch} ; do
        manifest_branch[${#manifest_branch[@]}]=${b}
    done

    # 1.下载manifest仓库
    download_and_update_apk_repository gcs_sz/manifest master

    # 2.下载或更新mirror仓库
    download_mirror
}

main $@