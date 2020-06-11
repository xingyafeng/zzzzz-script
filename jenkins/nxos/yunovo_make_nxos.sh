#!/usr/bin/env bash

## 编译nxos应用[支持多渠道编译]
function build_nxos_app()
{
    local compile_state=""

    echo
    echo "#################################################################"
    cat ${WORKSPACE}/yunovo_multi_channel.cfg
    echo "#################################################################"
    echo

    case ${ROOT_BUILD_CAUSE} in

        MANUALTRIGGER)
            if [[ ${#build_multi_channel[@]} -gt 0 ]]; then ## 多渠道构建模式
                for cm in ${build_multi_channel[@]}
                do
                    ## 当识别为common时,就任务是无渠道构建模式
                    if [[ "${cm}" == "common" ]]; then
                        build_channel_no=""
                    else
                        build_channel_no=${cm}
                    fi

                    build_version="assemble`echo ${build_channel_no}`${build_release_type}"
                    __green__ "@@@ channel no : ${build_channel_no}"

                    echo "${tmpfs}/config/tools/gradle/gradle-4.1/bin/gradle -q clean ${build_version} -PBUILD_TIME=${BUILD_TIME} -PPRODUCT_NAME=${build_channel_no} -PJENKINS=1 --refresh-dependencies"
                    ${tmpfs}/config/tools/gradle/gradle-4.1/bin/gradle -q clean ${build_version} -PBUILD_TIME=${BUILD_TIME} -PPRODUCT_NAME=${build_channel_no} -PJENKINS=1 --refresh-dependencies

                    if [[ $? -ne 0 ]]; then
                        __return__ 1
                    fi

                    get_apk_name
                    backup_apk
                    touch_readme_log

                    channel_app_name[${#channel_app_name[@]}]=${APK_PRODUCT_NAME}
                done
            else
                log error "---- The channel_mode has no found ..."
            fi
            ;;

        TIMERTRIGGER)
            :
            __err "自动触发方式 ..."
            ;;

        *)
            __err "未知的触发方式 ..."
            ;;
    esac
}

## 获取当前编译的成品文件名称
function get_apk_name()
{
    local OPWD=`pwd`
    local apk_path="${workspace}/apks/${build_channel_no}"

    cd ${apk_path} > /dev/null

    APK_PRODUCT_NAME=`ls *${build_channel_no}*${BUILD_TIME}*`
    if [[ -n ${APK_PRODUCT_NAME} ]]; then
        show_vig "@@@ apk nane : $APK_PRODUCT_NAME"
    else
        log error "成品文件名称为空 ..."
    fi

    cd ${OPWD} > /dev/null
}

## 归档成品文件apk
function backup_apk()
{
    local BASE_PATH="${workspace}/apks/${build_channel_no}"
    local DEST_PATH="${nxos_path}/${BUILD_DISPLAY_NAME}/${build_channel_no}"

    if [[ -z ${build_channel_no} ]]; then
        BASE_PATH="${workspace}/apks"
        DEST_PATH="${nxos_path}/${BUILD_DISPLAY_NAME}/common"
    fi

    if [[ ! -d ${DEST_PATH} ]];then
        mkdir -p ${DEST_PATH}
    fi

    if [[ -f ${BASE_PATH}/${APK_PRODUCT_NAME} ]];then
        cp -vf ${BASE_PATH}/${APK_PRODUCT_NAME} ${DEST_PATH}
    else
       log error "成品文件未找到 ..."
    fi
}

## 归档成品测试报告
function backup_test_report()
{
    local BASE_PATH="${tmpfs}/test_report/${job_name}/${channel}/${rom}_${BUILD_TIME}"
    local DEST_PATH="${nxos_path}/${BUILD_DISPLAY_NAME}/${channel}"

    if [[ ! -d ${DEST_PATH} ]]; then
        mkdir -p DEST_PATH
    fi

    if [[ -d ${BASE_PATH} ]]; then
        cp -rf ${BASE_PATH} ${DEST_PATH}
    else
        __err "测试报告文件未找到 ..."
    fi
}

## 上传成品文件至f1文件服务器
function sync_to_f1()
{
    ## 1. 备份本次产品版本
    if [[ -f ${tmpfs}/current_product_version.txt ]];then
        mv ${tmpfs}/current_product_version.txt ${tmpfs}/product_version.txt

        ## 由于产品型号是包含所以的渠道模式,故放到NXOS目标下.
        cp -vf ${tmpfs}/product_version.txt ${nxos_path}
    fi

    ## 2. 备份已构建的app
    if [[ -d ${nxos_path} ]];then
        rsync -av ${nxos_path}/ ${git_username}@${f1_server}:${test_path}/NXOS/${job_name}
    else
        log error "${nxos_path} no found."
    fi

    ## 3. 清理动作
    if [[ -f ${nxos_path} ]];then
        rm -rf ${nxos_path}/*
    fi

    if [[ -d ${tmpfs}/test_report ]]; then
        rm -rf ${tmpfs}/test_report/*
    fi

    show_vip "--> sync end ..."

    ## 发送邮件给app开发者
    send_email_to_nxos_app_developer
}

## 检查渠道与ROM 对应关系
function check_multi_channel()
{
    local device_ip=""
    local nxos_version=""
    local the_test_results=""
    local separator=";|" # 分隔符
    local md5=""

    # 部署的应用
    declare -x deploy_app

    ## 1. 匹配 渠道与rom的关系
    ## 2. 匹配 rom与机器的关系 问题: 1. 若何找到对应ROM所在的机器呢?
    ## 3. 若匹配到正确的机器 并找到机器的ip  后需要检查依赖关系
    ## 4. 当依赖关系正确的情况下, 会安装预装的应用
    ## 5. 在应用安装成功的情况下, 会启动测试软件
    ## 6. 检查测试的结果
    ## 7. 测试完成后, 输出测试报告并邮件通知.
    for channel in ${!matchup[@]};
    do
        for app in "${channel_app_name[@]}";
        do
            ## [无渠道|有渠道] 都应该在不同的ROM中进行测试验证.
            if [[ "common" == "${channel}" || ${app} =~ "${channel}" ]]; then
                for rom in `echo ${matchup[${channel}]} | sed 's/,/ /g'`;
                do
                    #echo  ${app} --  ${rom}
                    for device_rom in `ssh pc@d1.y query_devinfo.sh -r`
                    do
                        if [[ "${device_rom}" == "${rom}" ]]; then

                            deploy_app=${nxos_path}/${BUILD_DISPLAY_NAME}/${channel}/${app}
                            md5=`md5sum ${deploy_app} | cut  -d ' ' -f1`

                            __green__ "@@ deploy app : ${deploy_app}"

                            # 1. 拿到当前设备的ip地址
                            device_ip=`ssh pc@d1.y query_devinfo.sh -d ${device_rom}`

                            __green__ "device ip : $device_ip"
                            # 检查设备是否在线
                            if [[ "false" == "`check_device_on_line`" ]]; then
                                auto_connect_device
                            fi
                            # 拿到系统版本号
                            nxos_version=`adb -s ${device_ip} shell getprop | grep ro.nxos.version | awk -F ':' '{print $2}' | sed -e 's/^[ \t]*//g'`
                            nxos_version=`echo "${nxos_version//[$'\t\r\n ']}" | sed -n 's/.*\[\(.*\)\].*/\1/p'`

                            # 2. 自动部署的APK [路径和名称]
                            auto_deploy ${deploy_app}

                            # 3. 运行自动测试脚本
                            ${tmpfs}/nxTestSuite/main.sh ${rom}

                            # 4. 归档测试报告
                            backup_test_report

                            if [[ $? -ne 0 ]]; then
                                __return__ 3
                            fi

                            if [[ -f ${tmpfs}/.the.test.results ]]; then

                                case `cat ${tmpfs}/.the.test.results` in
                                    0)
                                        echo "[${app}], 在[${rom}]上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|    0   | 测试成功                                    |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=PASS
                                        ;;

                                    1)
                                        echo "[${app}], 在[${rom}]上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|   1    | 测试失败                                    |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=FAIL
                                        ;;

                                    2)
                                        echo "[${app}], 在[${rom}]上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|   2    | 无法找到设备                                |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=FAIL
                                        ;;

                                    3)
                                        echo "[${app}], 在[${rom}]上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|   3    | UI测试超时                                  |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=FAIL
                                        ;;

                                    4)
                                        echo "[${app}], 在[${rom}]上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|   4    | 接口测试超时，可能接口测试的宿主apk挂了     |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=FAIL
                                        ;;

                                    5)
                                        echo "[${app}], 在[${rom}]上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|   5    | UI测试等待超时                              |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=FAIL
                                        ;;

                                    6)
                                        echo "[${app}], 在[${rom}]上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|   6    | 系统版本号不匹配                            |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=FAIL
                                        ;;

                                    7)
                                        echo "[${app}], 在[${rom}]上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|   7    | 测试报告路径异常                            |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=FAIL
                                        ;;

                                    *)
                                        echo "${app}在${rom}上的测试结果: "
                                        echo "_______________________________________________________"
                                        echo "| 返回值 | 返回值描述                                  |"
                                        echo "|   \*   | 未知的返回值                                |"
                                        echo "|______________________________________________________|"
                                        echo
                                        the_test_results=FAIL
                                        ;;
                                esac

                                test_report[${#test_report[@]}]="${separator}${GIT_COMMIT}${separator}${channel}${separator}${rom}${separator}${nxos_version}${separator}${the_test_results}${separator}${md5}${separator}"
                                #echo ${test_report[@]}
                            fi
                        fi
                    done
                done
            fi
        done
    done
}

## 保存构建的差异信息表 <本次构建与上次构建的提交差异>.
function touch_readme_log()
{
    local readme_p=${nxos_path}/${build_channel_no}

    if [[ ! -d ${readme_p} ]]; then
        mkdir -p ${readme_p}
    fi

    if [[ -f ${f1_nxos_p}/${job_name}/${build_channel_no}/readme.log ]]; then
        cp ${f1_nxos_p}/${job_name}/${build_channel_no}/readme.log ${readme_p}/readme.log
    else
        touch ${readme_p}/readme.log
    fi

    echo Apk product name:${APK_PRODUCT_NAME} >> ${readme_p}/last_readme.log
    echo "Modify,see details in readme.log:" >> ${readme_p}/last_readme.log

    if [[ -n "${GIT_PREVIOUS_COMMIT}" && -n "${GIT_COMMIT}" ]]; then
        git log ${GIT_PREVIOUS_COMMIT}..${GIT_COMMIT} --pretty=format:'    %h -%d %s (%ci) <%an>' >> ${readme_p}/last_readme.log
    fi

    echo >> ${readme_p}/last_readme.log
    echo "------------------------------------ $BUILD_DISPLAY_NAME" >> ${readme_p}/last_readme.log
    echo >> ${readme_p}/last_readme.log

    if [[ -f ${readme_p}/readme.log && ${readme_p}/last_readme.log ]];then
        mv  ${readme_p}/readme.log  ${tmpfs}/readme_tmp.log
        cat ${readme_p}/last_readme.log ${tmpfs}/readme_tmp.log > ${readme_p}/readme.log

        ## 清除临时文件 1. last_readme.log 2. readme_tmp.log
        if [[ -f ${readme_p}/last_readme.log ]];then
            rm -rf ${readme_p}/last_readme.log
        fi

        if [[ -f ${tmpfs}/readme_tmp.log ]];then
            rm -rf ${tmpfs}/readme_tmp.log
        fi
    else
        log error "The readme.log or The last_readme.log has no found."
    fi
}
