#!/usr/bin/env bash

#######################################################
#
#字段定义 info
# 0. 设备修改时间 限制重启
# 1. 已离线授权执行次数 (存储位置待定 custom or system)
# 2. 当前设备时间戳
# 3. 设备固件编译时间点 (ro.build.date.utc)
# 4. 芯片信息 (ro.hardware)
# 5. 设备mac地址 (不用':' 分割)
# 6. 设备imei ()
# 7. 设备指纹 (ro.build.fingerprint) ## ro.build.fingerprint=alps/full_magc6580_we_l/magc6580_we_l:5.1/LMY47I/1541495006:user/test-keys
# 8. 设备SN (mtk和sc 拿到的方法不一样)
#
#######################################################
declare -A info  # 方式一, 有顺序;方式二, 无顺序
declare -a add   # 增加字段
declare -a combo # 组合
declare -a tmp   # 临时

## [0|2|3|4|7|8] 必须不能为空
## [1|5|6] 允许为空

## [0|1|2|3|5|6|8]  数字
## [4|7]            字符串

## 默认规则
# 1.授权设备 不重启情况下, 5s内可以用  限制条件: [0|2] 必须不能空,才会有此规则
# 2.授权设备 只能使用五次 限制条件: [1] 必须不能为空 , 同时将 [0] 值空.
# 3.授权SN号段可用 只能使用五次 前置条件同2, 将参数[8] 修改成段号 123888 -> 允许 123000-123999可用, 就传回 123
# 授权 [123,678]
# 4.允许多版本之间升级

DEBUG=false

## 去掉变量中的所有空格
function remove_space_for_vairable()
{
    ## 去掉空格后的变量
    local new_v=
    local old_v=$1

    if [[ $# -eq 1 ]];then
        :
    else
        echo "args[] is error, please check args !"
        return
    fi

    new_v=(`echo ${old_v} | sed 's/[  ]\+//g'`)
    if [[ "$new_v" != "$old_v" ]];then
        echo ${new_v}
    else
        echo ${old_v}
    fi
}

function allow_time_stamp()
{
    if [[ "${info[0]}" -gt 0 && "${info[2]}" -gt 0 ]]; then
        add[0]=$((${info[2]}+5))
    fi
}

function allow_times()
{
    if [[ ${info[1]} -gt 0 ]]; then
        #unset info[0]
        add[1]=$((${info[1]}+5))
    fi
}

function allow_sn_rage()
{
    :
}

function replace_space_and_enter()
{
    local ret=""

    if [[ -n "$1" ]]; then
        ret=$1
    else
        echo "args[] is error, please check args !"
        return
    fi

    # 将 '+' 变成空格, 回车变成linux格式
    ret=${ret//+/ }
    ret=${ret//%0D%0A/%0A}

    echo ${ret}
}

function urldecode()
{
    local ret=""

    if [[ -n "$1" ]]; then
        ret=$1
    else
        echo "args[] is error, please check args !"
        return
    fi

    ret=$(printf '%b' "${ret//%/\\x}")

    echo ${ret}
}

function urlreplace()
{
    local ret=""

    if [[ -n "$1" ]]; then
        ret=$1
    else
        echo "args[] is error, please check args !"
        return
    fi

    ret=`echo "$QUERY_STRING" | sed -n "s/^.*${ret}=\([^&]*\).*$/\1/p"`
    ret=`replace_space_and_enter "${ret}"`
    ret=`urldecode "${ret}"`

    ret=$(printf '%b' "${ret//%/\\x}")

    echo ${ret}
}

function __print()
{
    echo "info: ${info[@]}; len = ${#info[@]} "
}

## 打印关联数组
function print_ass_array()
{
    declare -a key
    declare -a value
    declare -A ass

    key=($1)
    value=($2)

    if [[ $# -ne 2 ]]; then
        echo ""
        echo "print_ass_array args1 args2 "
        echo "    参数1 : ${!ass[@]}"
        echo "    参数2 : ${ass[@]} "
        echo
        echo '    e.g. print_ass_array ${!ass[@]} ${ass[@]}'
        return
    fi

    if [[ ${#key[@]} -ne ${#value[@]} ]]; then
        echo "print_ass_array: key vaule no match ..."
        return
    fi

    for k in ${!key[@]} ; do
        for v in ${!value[@]} ; do
            if [[ ${k} == ${v} ]]; then
                ass[${key[$k]}]=${value[$v]}
            fi
        done
    done

    for a in ${!ass[@]} ; do
        echo "ass[$a]=${ass[$a]}"
    done
}

function main()
{
    local TYPE=""
    local CMDSTR=""

    local mode_flag_number=""
    local mode_flag_string=""

    local keys=`echo proc_stamp count utc ro_build_utc ro_hw mac imei ro_fp sn`

    ## 模拟数据,用于测试
    #local QUERY_STRING="cmd=12+%26+1+%26+25535+%26+12455+%26+mt6735+%26+4545454545+%26+123123+%26+alps%2Ffull_magc6580_we_l%2Fmagc6580_we_l%3A5.1%2FLMY47I%2F1541495006%3Auser%2Ftest-keys+%26+abf133&fmt=args&type=0&proc_stamp=432432&count=22&utc=cccc&ro_build_utc=aaaa&ro_hw=dddd&mac=24214&imei=111&ro_fp=222&sn=7777"
    local QUERY_STRING="cmd=1544253210342000313%261%261544253210350082775%261534233004%26mt6580%26156%261%26alps%2Ffull_magc6580_we_l%2Fmagc6580_we_l%3A5.1%2FLMY47I%2F1534232901%3AuserDEBUG%2Ftest-keys%262100111801000020&fmt=args&type=0&proc_stamp=432432&count=22&utc=cccc&ro_build_utc=aaaa&ro_hw=dddd&mac=24214&imei=111&ro_fp=222&sn=7777"



    if ${DEBUG};then
    echo
    echo "-------------------------------------------------------------------------------------- mode0"
    echo
    fi

    CMDSTR=`urlreplace cmd`
    if ${DEBUG};then
    echo "cmd = $CMDSTR"
    echo '---------'
    fi

    OIFS=$IFS
    IFS=$'&'
    for c in ${CMDSTR}; do
        #echo `remove_space_for_vairable "$c"`
        info[${#info[@]}]=`remove_space_for_vairable "$c"`
    done
    IFS=${OIFS}


    ## [0|1|2|3|5|6]  数字
    ## [4|7]          字符串

    ## [0|2|3|4|7]    必须为非空
    ## [1|5|6]        允许为空

    ## [8] 比较特殊
    for (( VAR = 0; VAR < ${#info[*]}; ++VAR )); do
        #echo "$VAR : ${info[${VAR}]}"

        case ${VAR} in
            0|1|2|3|5|6) ## 数字
                if [[ ${info[${VAR}]} -gt 0 ]]; then
                    case ${VAR} in
                        0|2|3)
                            if [[ ${info[${VAR}]} != "" ]]; then
                                mode_flag_number=true
                            else
                                mode_flag_number=false
                                break
                            fi
                            ;;
                    esac
                else
                    mode_flag_number=false
                    break
                fi
                ;;

            4|7|8) ## 字符串
                if [[ "${info[${VAR}]}" != "" ]]; then
                    mode_flag_string=true
                else
                    mode_flag_string=false
                    break
                fi
                ;;
        esac
    done
    #__print

    #echo "mode_flag_number = ${mode_flag_number}"
    #echo "mode_flag_string = ${mode_flag_string}"

    if ${DEBUG};then
    echo
    echo "-------------------------------------------------------------------------------------- mode1"
    echo
    fi

    if [[ "${mode_flag_number}" == "false" || "${mode_flag_string}" == "false" ]]; then
        mode_flag_number=""
        mode_flag_string=""

        for k in ${keys} ; do
            info[${k}]="`echo "$QUERY_STRING" | sed -n "s/^.*${k}=\([^&]*\).*$/\1/p"`"

            if [[ "${k}" == "ro_fp" ]]; then
                info[${k}]="`urldecode "${info[$k]}"`"
            fi
        done

        local key=${!info[@]}
        local value=${info[@]}

        #print_ass_array "$key" "$value"

        #echo "#############"
        for key in ${!info[*]}
        do
            echo "${key} : ${info[$key]}"
            case ${key} in
                proc_stamp|count|mac|utc|imei|ro_build_utc) ## 数字
                    #echo "----value == ${info[$key]} --- "
                    if [[ ${info[$key]} -gt 0 ]]; then
                        case ${key} in
                            proc_stamp|utc|ro_build_utc)
                                if [[ ${info[$key]} != "" ]]; then
                                    mode_flag_number=true
                                else
                                    mode_flag_number=false
                                    break
                                fi
                                ;;
                        esac
                    else
                        mode_flag_number=false
                        break
                    fi
                    ;;

                ro_hw|ro_fp|sn)
                    #echo "----value == ${info[$key]} --- "
                    if [[ ${info[$key]} != "" ]]; then
                        mode_flag_string=true
                    else
                        mode_flag_string=false
                        break
                    fi
                    ;;
            esac
        done
    fi
    if ${DEBUG};then
    echo
    echo "mode_flag_number = ${mode_flag_number}"
    echo "mode_flag_string = ${mode_flag_string}"

    echo
    echo "-------------------------------------------------------------------------------------- type"
    echo
    fi

    ## 授权的方式
    ## 0. 时间
    ## 1. 次数

    TYPE=`urlreplace type`
    #echo "type = $TYPE"

    if [[ ! ${TYPE} -ge 0 ]]; then
        echo "type is error ..."
    fi

    case ${TYPE} in

        0)
            allow_time_stamp

            add[1]=0
            add[2]=`date "+%s"`
            ;;

        1)
            allow_times
            add[0]=0
            add[2]=`date "+%s"`
            ;;

        *)
            allow_time_stamp
            add[1]=0
            add[2]=`date "+%s"`
            ;;
    esac

    if [[ "${mode_flag_number}" == "true" && "${mode_flag_string}" == "true" ]]; then

        tmp=(${add[@]} ${info[@]})

        if ${DEBUG};then
        echo
        echo "-------------------------------------------------------------------------------------- combe"
        echo

        echo "组合: "
        echo "add   ==> ${add[@]}"
        echo "info  ==> ${info[@]}"
        echo "combo ==> ${tmp[@]}"
        fi

        for i in "${!tmp[@]}";
        do
            #printf "%s\t%s\n" "$i" "${tmp[$i]}"
            combo[${#combo[@]}]="${tmp[$i]}"
            combo[${#combo[@]}]="&"
        done

        unset combo[$((${#combo[*]}-1))]
        echo "${combo[@]}"
    fi
}

URL_TYPE="text/plain"
echo -e "Content-Type: ${URL_TYPE}\r\n\r\n"

main "$@"

if false;then
#返回的格式  base64 或者不填
FMTSTR=`echo "$QUERY_STRING" | sed -n 's/^.*fmt=\([^&]*\).*$/\1/p'`

TYPE="text/plain"
if [[ -z "$FMTSTR" ]] && [[ -n "$CMDSTR" ]]; then
  TYPE="application/octet-stream"
else
  FMTSTR="base64"
fi

#如果用命令生成，少输出一个 \n ，因为echo会自行输出一个
echo -e "Content-Type: ${TYPE}\r\n\r"
if [[ -z "$CMDSTR" ]]; then
 date
 echo " none cmd!"
 echo " $QUERY_STRING "
 echo " cmd : $CMDSTR "
fi
fi

if false;then
echo ${info[@]}
echo "---key:"
echo ${!info[@]}
echo "---vaule:"
echo ${info[@]}
fi