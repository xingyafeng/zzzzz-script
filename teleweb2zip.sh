#!/usr/bin/env bash

# if error;then exit
set -e

# exec shell
shellfs=$0

# init function
. "`dirname $0`/jenkins/jenkins_init.sh"

# 1.项目名
build_zip_project=
# 2.同步类型
build_zip_type=
# 3.同步版本
build_zip_version=
# 4.其他版本
build_zip_other=


function handle_vairable() {

    # 1. 项目名
    build_zip_project=${zip_project:=}

    # 2. 同步类型
    build_zip_type=${zip_type:=}

    # 3. 同步版本
    build_zip_version=${zip_version:=}

    # 4. 其他信息
    build_zip_other=${zip_other:=}
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_zip_project = " ${build_zip_project}
    echo "build_zip_type    = " ${build_zip_type}
    echo "build_zip_version = " ${build_zip_version}
    echo "build_zip_other   = " ${build_zip_other}
    echo '-----------------------------------------'
    echo
}

function init() {

    handle_vairable
    print_variable
}

#####################################################
##
##  函数: enhance_zip
##  功能: 增强压缩系统版本
##  参数: 1 zip_path: 压缩路径
##        2 zip_name: 压缩名称
##
##
##  zip 参数说明:
##　　　-1 : compress faster  2G文件大概花费 2min33s
##      -9 : compress bester  2G文件大概花费 9min18s
####################################################
function enhance_zip() {

    local zip_p=${tmpfs}/zip

    log print "--> zip version start ..."

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "zip_path  = " ${zip_path}
    echo "zip_name  = " ${zip_name}
    echo '-----------------------------------------'
    echo

    pushd ${zip_path} > /dev/null

    if [[ ! -f ${zip_name}.zip ]]; then
        zip -1v ${zip_p}/${zip_name}.zip *.*
        if [[ $? -eq 0 ]]; then
            log print "backup ${zip_name}.zip to Teleweb Server ..."

            sudo cp -vf ${zip_p}/${zip_name}.zip .

            if [[ -d ${zip_p} ]]; then
                rm ${zip_p}/* -rf
            fi
        else
            log error "zip version fail. "
        fi
    else
        log info "The ${zip_name}.zip file is exist ... "
    fi

    log print "--> zip version end ..."

    popd > /dev/null
}

function zip_rom() {

    local ret
    local zip_path  zip_name
    local version=('5' '6' '7' '8' '9' 'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N')

    # 1级目录
    case ${build_zip_project} in

        tokyolitetmo|seattlevzw|seattletmo|apollo84gtmo)
            log print "normal mode .."

            zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
            zip_name=${build_zip_version}
            ;;

        portotmo|thor84gvzw)
            log print "more type mode .."

            # 2级目录
            case ${build_zip_type} in

                tmp|appli)

                    ret=${build_zip_version: -2} && ret=${ret:0:1}
                    log debug "ret = ${ret}"

                    # 3级目录 若版本号倒数第二位 为 ('5' '6' '7' '8' '9' 'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N') 的要特殊处理
                    case ${ret} in
                        3|4|5|6|7|8|9|A|B|C|D|E|F|G|H|I|J|K|L|M|N)
                            if [[ -n ${build_zip_other} ]]; then
                                zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}/${build_zip_other}
                                zip_name=${build_zip_version}_`echo ${build_zip_other} | sed s#/#_#g`
                            else
                                log info "The build_zip_other has error."
                            fi
                          ;;
                    *)
                        zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}
                        zip_name=${build_zip_version}
                        ;;
                    esac
                    ;;

                userdebug)
                    # 3级目录 若版本号倒数第二位 为 p 则会特殊处理
                    ret=${build_zip_version: -2} && ret=${ret:0:1}
                    log debug "ret = ${ret}"

                    # 3级目录 若版本号倒数第二位 为 (P) 的要特殊处理
                    case ${ret} in
                        P)
                            if [[ -n ${build_zip_other} ]]; then
                                zip_path=${rom_p}/${build_zip_project}/${build_zip_type}/${build_zip_version}/${build_zip_other}
                                zip_name=${build_zip_version}_`echo ${build_zip_other} | sed s#/#_#g`
                            else
                                log info "The build_zip_other has error."
                            fi
                            ;;
                        *)
                            ;;
                    esac
            esac
            ;;
        *)
            log error "没匹配到正确的项目."
            ;;
    esac

    if [[ -d ${zip_path} && -n ${zip_name} ]]; then

        #处理压缩包名称,后面增加Teleweb字眼
        zip_name=${zip_name}-Teleweb

        time enhance_zip
    else
        log error "It is the ${zip_path} or ${zip_name} has error."
    fi
}

# 邮件功能
function sendEmail() {

    local isSend=

    if [[ "$1" ]]; then
        isSend=$1
    else
        log error "参数错误."
    fi

    python ${script_p}/extend/sendemail.py ${build_zip_project} ${build_zip_type} ${build_zip_version} ${BUILD_USER_EMAIL} ${isSend}
}

function main() {

    local rom_p=/mfs_tablet/0_Shenzhen

    # 初始化
    init

    # 压缩ROM版本
    zip_rom

    if [[ $? -eq 0 ]]; then
        sendEmail true
    else
        sendEmail false
    fi
}

main "$@"