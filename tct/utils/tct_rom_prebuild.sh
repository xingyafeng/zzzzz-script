#!/usr/bin/env bash

# 获取正确的编译路径
function getdir() {

    local prjdir=${1:-}
    local tmpdir=

    if [[ ! -f ${buildlist} ]]; then
        log error "The ${buildlist} file has no found!"
    fi

    if [[ ${project_path} == ${prjdir} ]]; then
        if [[ -n ${module_target[${prjdir}]} ]]; then
            echo ${prjdir}

            return 0
        else
            return 0
        fi
    else
        tmpdir=$(dirname ${prjdir})
#        echo '@@ tmpdir: ' ${tmpdir}
        while IFS=':' read -r k v ; do
#            echo 'k : ' ${k} ' --- ' 'v : ' ${v}
            if [[ -n ${v} ]]; then
#                echo 'k : ' ${k}
                if [[ ${k} == "${tmpdir}" ]]; then
                    if [[ ${tmpdir} != ${project_path} ]]; then
                        if [[ -n ${module_target[${tmpdir}]} ]]; then
                            echo ${tmpdir}

                            return 0
                        fi
                    fi
                fi
            fi
        done < ${buildlist}

        getdir ${tmpdir}
    fi
}

# 获取最顶层路径
function gotdir() {

    local prjdir=${1:-}
    local tmpdir=

    tmpdir=$(dirname ${prjdir})

    if [[ -z $(echo ${tmpdir} | egrep '/') ]]; then
        echo ${tmpdir}
    else
        gotdir ${tmpdir}
    fi
}

# 拿到modem类型
function get_modem_type() {

    case ${build_project} in

        DelhiTF_Gerrit_Build)
            build_modem_type=tf
        ;;

        TransformerVZW_Gerrit_Build)
            build_modem_type=vzw
        ;;

        *)
            log error 'The build modem type is null ...'
        ;;
    esac
}


# 统计编译的工程
function statistical_compilation_project() {

    if [[ ! -f ${tmpfs}/bpath.txt ]]; then
        :> ${tmpfs}/bpath.txt
    fi

    if [[ ! -f ${tmpfs}/bproject.txt ]]; then
        :> ${tmpfs}/bproject.txt
    fi

    :> ${tmpfs}/tmp.txt
    # 统计build path
    if [[ -n ${build_path[@]} ]]; then
        for bp in ${build_path[@]}; do
            echo ${bp} >> ${tmpfs}/tmp.txt
        done

        cat ${tmpfs}/tmp.txt | sort -u >> ${tmpfs}/bpath.txt
        __pruple__ "build path:"
        cat ${tmpfs}/bpath.txt | sort -u
        cat ${tmpfs}/bpath.txt | sort -u > ${tmpfs}/tmp.txt
        cat ${tmpfs}/tmp.txt   | sort -u > ${tmpfs}/bpath.txt
    fi

    :> ${tmpfs}/tmp.txt
    # 统计build project
    if [[ -n ${project_paths[@]} ]]; then
        for pp in ${project_paths[@]}; do
            echo ${pp} >> ${tmpfs}/tmp.txt
        done

        cat ${tmpfs}/tmp.txt | sort -u >> ${tmpfs}/bproject.txt
        __pruple__ "project path:"
        cat ${tmpfs}/bproject.txt | sort -u
        cat ${tmpfs}/bproject.txt | sort -u > ${tmpfs}/tmp.txt
        cat ${tmpfs}/tmp.txt      | sort -u > ${tmpfs}/bproject.txt
    fi
}