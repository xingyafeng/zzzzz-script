###########################################################
###
###				tools functions
###
###
### date 	: 2019-02-21 10:12
### author  : yafeng
###
###########################################################
#!/usr/bin/env bash

function log {

    local msg logtype
    local datetime=`date +'%F %H:%M:%S'`

    case $# in

        1)
            case $@ in
                -h|--help)
                    echo "${FUNCNAME[0]} args1 args2 ..."
                    echo
                    echo "   args1 : 如, verbose:0; debug:1; info:2; warn:3; error:4 ..."
                    echo "   args2 : 打印的字符串 ..."
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}                     # 输出帮助文档"
                    echo "        1. ${FUNCNAME[0]} [ -h | --help ]     # 输出帮助文档"
                    echo "        2. ${FUNCNAME[0]} debug 'test info'"
                    echo
                    return 1
                ;;

                *)
                    echo "${FUNCNAME[0]} args1 args2 ..."
                    echo
                    echo "   args1 : 如, verbose:0; debug:1; info:2; warn:3; error:4 ..."
                    echo "   args2 : 打印的字符串 ..."
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]}                     # 输出帮助文档"
                    echo "        1. ${FUNCNAME[0]} [ -h | --help ]     # 输出帮助文档"
                    echo "        2. ${FUNCNAME[0]} debug 'test info'"
                    echo
                    return 1
                    ;;
            esac
            ;;

        2)
            logtype="$1"
            msg="$2"
            ;;

        *)
            if [[ $# -ne 2 ]]; then
                echo "${FUNCNAME[0]} args1 args2 ..."
                echo
                echo "   args1 : 如, verbose:0; debug:1; info:2; warn:3; error:4 ..."
                echo "   args2 : 打印的字符串 ..."
                echo
                echo "    e.g."
                echo "        1. ${FUNCNAME[0]}                     # 输出帮助文档"
                echo "        1. ${FUNCNAME[0]} [ -h | --help ]     # 输出帮助文档"
                echo "        2. ${FUNCNAME[0]} debug 'test info'"
                echo
                return 1
            fi
        ;;
    esac

    logformat="[${logtype}]\t${datetime}\tfuncname:${FUNCNAME[@]/log/}\t[line:`caller 0 | awk '{print$1}'`]\t${msg}"
    {
        case ${logtype} in

            verbose)
                [[ ${loglevel} -le 0 ]] && show_vibk "${logformat}"
                ;;

            debug)
                [[ ${loglevel} -le 1 ]] && show_vib "${logformat}"
                ;;

            info)
                [[ ${loglevel} -le 2 ]] && show_vig "${logformat}"
                ;;

            warn)
                [[ ${loglevel} -le 3 ]] && show_viy "${logformat}"
                ;;

            error)
                [[ ${loglevel} -le 4 ]] && show_vir "${logformat}"
                ;;

            *) # printf
                [[ -n ${loglevel} ]] && show_vip "${logformat}"
                ;;
        esac
    } 2>&1 | tee -a ${logfile}

    if [[ "${logtype}" == "error" ]]; then

        # 在出现错误的时候,删除待上传的文件.
        if [[ -d ${version_p} ]]; then
            rm -rf ${version_p}/*
        fi

        if [[ -d ${rom_path} ]]; then
            rm -rf ${rom_path}/*
        fi

        if [[ "`is_4_return`" == "true" ]]; then
            __return__ 4
        elif [[ "`is_5_return`" == "true" ]];then
            __return__ 5
        else
            __return__
        fi
    fi
}

#######################
###    file EOF    ###
######################
