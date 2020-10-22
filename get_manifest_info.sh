#!/usr/bin/env bash

# if error;then exit
set -e

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

# exec shell
shellfs=$0

declare -A manifest_info
declare -A branch_count

# init function
. "`dirname $0`/jenkins/jenkins_init.sh"

function main() {

    trap 'ERRTRAP ${LINENO} ${FUNCNAME} ${BASH_LINENO}' ERR

#    local manifest=(sm6125-r0-portotmo-dint.xml sm7250-r0-seattletmo-dint.xml mt6762-tf-r0-v1.1-dint.xml qct-sm4250-tf-r-v1.0-dint.xml)
    local manifest=(qct-sm4250-tf-r-v1.0-dint.xml)

    log debug "start ..."

    # 下载manifest
    git_sync_repository gcs_sz/manifest master ${workspace_p}/app

    for m in ${manifest[@]} ; do

        echo 'manifest : ' ${m}

        # 拿到name revision
        xmlstarlet sel -T -t -m /manifest/project -v "concat(@name,':',@revision,'')" -n ${workspace_p}/app/manifest/${m} > ${tmpfs}/${m}.txt

        while IFS=":" read -r _name _revision _;do
            if [[ -z ${_revision}  ]]; then
                _revision=$(xmlstarlet sel -T -t -m /manifest/default -v "concat(@revision,'')" -n ${workspace_p}/app/manifest/${m})
            fi

#            echo ${_name} '---' ${_revision}
            manifest_info[${_name}]=${_revision}

        done < ${tmpfs}/${m}.txt

        for branch in $(xmlstarlet sel -T -t -m /manifest/project -v "concat(@revision,'')" -n ${workspace_p}/app/manifest/${m} | grep -v "^$" | sort -u) ; do
            local count=$(xmlstarlet sel -T -t -m /manifest/project -v "concat(@revision,'')" -n ${workspace_p}/app/manifest/${m} | egrep -w ${branch} | wc -l)
            branch_count[${branch}]=${count}
        done
    done

if false;then
    show_vig 'manifest info :'
    for key in ${!manifest_info[@]}
    do
        echo "${key} -> ${manifest_info[$key]}"
    done
fi

    show_vig 'branch count info :'

    echo 'manifest : ' ${m}
    echo 'project : branch -> count'
    echo '--------------------------------------'
    for key in ${!branch_count[@]}
    do
        case ${branch_count[$key]} in

            1)
                case ${key} in
                    sm7250-r0-seattletmo-dint|mt6762-tf-r0-v1.1-dint|qct-sm4250-tf-r-v1.0-dint)
                        continue
                        ;;
                esac

                for mf in ${!manifest_info[@]} ; do
                    if [[ "${key}" == "${manifest_info[${mf}]}" ]]; then
                        echo ${mf} ':' ${key} '->' ${branch_count[$key]}
                    fi
                done
                ;;
        esac
    done

    echo
    echo 'branch -> count'
    echo '--------------------------------------'
    for key in ${!branch_count[@]}
    do
        case ${branch_count[$key]} in

            1)
                continue
                ;;

            *)
                echo ${key} '->' ${branch_count[$key]}
                ;;
        esac
    done

    log debug "end ..."

    trap - ERR
}

main "$@"