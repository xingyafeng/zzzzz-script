#!/usr/bin/env bash

# TODO 临时的、短期解决方案的、或者足够好但不够完美的代码

## 当前Shell文件名
shellfs=$0

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

declare -a file

time_for_version=`date +'%m.%d_%H.%M.%S'`

# 下载 oss
function download_oss_file() {

    # 备份上次
    cp -r ${oss_p} ${target_p}

    # 更新服务器
    ossutil64 cp oss://yunovo-newlogs ${oss_p} -r -u --include 'feedback_*.txt' --include 'feedback_*.3gp'
}

function check_file() {

    local target_p=${tmpfs}/yunovo-target_${time_for_version}

    echo
    show_vip "---- start check file ..."

    download_oss_file

    for f in `find ${oss_p} -type f | grep feedback`
    do
        tmp=`echo ${f} | sed "s/yunovo-newlogs/yunovo-target_${time_for_version}/"`

        if [[ ! -f ${tmp} ]]; then
            file[${#file[@]}]="`echo ${f} | cut -d '/' -f 5-`"
        fi
    done

    if [[ -d ${target_p} ]]; then
        rm -rf ${target_p}
    fi
}

function init() {

    if [[ ! -d ${oss_p} ]]; then
        mkdir ${oss_p}
    fi
}

function main() {

    local oss_p=${tmpfs}/yunovo-newlogs
    local title="Hi,听风者."
    local content="测试内容"

    init

    check_file

    for f in ${file[@]}; do

        title="`echo ${f} | awk -F/ '{ print $(NF-1) "-" $(NF) }'`"
        content=${f}

        echo "---| ${f}"

        case `get_file_type ${f}` in

            txt)
                local tel="`egrep "*1[3578][0-9]{9}" ${tmpfs}/${f}`"

                if [[ -n "${tel}" ]]; then
                    dingding_robot_send_message 1 txt "${tel} path:${content}"
                else
                    dingding_robot_send_message 1 txt "TEL=null path:${content}"
                fi
            ;;

            3gp)
                dingding_robot_send_message 1 3gp "`ossutil64 sign oss://${f} --timeout 2160000 | head -1`"
            ;;
        esac
    done

    show_vip "---- send massage end ..."
}

main $@