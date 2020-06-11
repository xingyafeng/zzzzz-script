#!/bin/bash

# 若某一个命令返回非零值就退出
set -e

unset -v JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH

################################## args
build_version=""
build_multi_channel=""
build_channel_no=""
build_release_type=""
build_email=""
build_cc_address=""
build_app_name=""
build_repository_name=""
build_repository_branch=""
build_deploy=""

################################## system env
declare -x BUILD_TIME=`date +'%Y.%m.%d_%H.%M.%S'`
################################## common
# 拿到当前执行的脚本名称
shellfs=$0

# init function
. "`dirname $0`/jenkins/yunovo_init.sh"

################################# public vairable

## nxos存放路径
nxos_path=${tmpfs}/nxos
f1_nxos_p=${tmpfs}/NXOS
commit_p=${tmpfs}/commit

## 渠道模式
declare -a channel_mode
## 渠道应用
declare -a channel_app_name
## 测试报告
declare -a test_report
## 匹配 渠道与ROM
declare -A matchup

## 产品名称
APK_PRODUCT_NAME=""
## 最新的提交[commit id]
GIT_COMMIT=""
## 更新前一次提交[commit id]
GIT_PREVIOUS_COMMIT=""

## 处理jenkins传过来的变量, 并检查其有效性.
function handle_variable()
{
    # 1.1 构建渠道号
    if [[ -f ${WORKSPACE}/yunovo_multi_channel.cfg ]]; then
        get_app_support_channel_no
        build_multi_channel=`echo ${!matchup[@]}`

        # 清除上传的配置文件
        #rm ${WORKSPACE}/yunovo_multi_channel.cfg -rf
    else
        log error "无法访问 ${WORKSPACE}/yunovo_multi_channel.cfg: 没有那个文件或目录"
    fi

    # 1.2 构建类型
    build_release_type=${yunovo_release_type:=Release}

    # 2. 收件人
    build_email=${yunovo_email:="notify@yunovo.cn"}

    # 3. 抄送人
    build_cc_address=${yunovo_cc_email:-}

    # 4. 应用中文名称
    get_app_chinese_name

    # 5. 仓库名称
    build_repository_name=${yunovo_repository_name:=}

    # 6. 对应仓库的分支名
    build_repository_branch=${yunovo_repository_branch:=}

    # 7. 是否部署测试
    build_deploy=${yunovo_deploy:=false}

    handle_common_variable
    handle_common_variable_for_nxos
}

## 打印公共变量
function print_variable()
{
    echo
    echo "JOBS     = " ${JOBS}
    echo '-----------------------------------------'
    echo "builder  = " ${build_builder}
    echo '-----------------------------------------'
    echo "JOB_NAME = $JOB_NAME"
    echo '-----------------------------------------'
    echo "build_repository_name   = ${build_repository_name}"
    echo "build_repository_branch = ${build_repository_branch}"
    echo "build_release_type      = ${build_release_type}"
    echo "build_email             = ${build_email}"
    echo "build_cc_address        = ${build_cc_address}"
    echo "build_deploy            = ${build_deploy}"
    echo "build_multi_channel     = ${build_multi_channel[@]}"
    echo '-----------------------------------------'
    echo
}

function init()
{
    if [[ ! -d ${nxos_path} ]]; then
        mkdir -p ${nxos_path}
    else
        rm ${nxos_path}/* -rf
    fi

    if [[ ! -d ${f1_nxos_p} ]]; then
        mkdir -p ${f1_nxos_p}
    fi

    if [[ ! -d ${commit_p} ]]; then
        mkdir -p ${commit_p}
    fi

    ## 获取服务器最新的readme.log
    rsync -av --delete ${git_username}@${f1_server}:${test_path}/NXOS/ ${f1_nxos_p}

    ## 下载构建工具gradle
    download_and_update_apk_repository ReglinkDroidCar/config yunovo/reglink/droidcar/develop

    ## 下载自动测试脚本
    download_and_update_apk_repository nxos/nxTestSuite master

    ## 下载构建项目的仓库
    download_and_update_apk_repository ${build_repository_name} ${build_repository_branch} ${WORKSPACE}

    ## 最新的提交[commit id]
    if [[ -d `git rev-parse --git-dir` ]];then
        GIT_COMMIT=`git rev-parse --short --verify HEAD`
    else
        log error "fatal: Not a git repository ..."
    fi

    ## 前一次提交[commit id]
    if [[ -f ${commit_p}/.git.commit.${job_name} ]]; then
        GIT_PREVIOUS_COMMIT=`cat ${commit_p}/.git.commit.${job_name}`
    else
        if [[ -d `git rev-parse --git-dir` ]];then
            GIT_PREVIOUS_COMMIT=`git rev-parse --short --verify HEAD^`
        else
            log error "fatal: Not a git repository ..."
        fi
    fi
}

function main()
{
    local startT=`date +'%Y-%m-%d %H:%M:%S'`

    if [[ "`is_app_zenchain`" == "true" ]]; then

        workspace=${WORKSPACE}/${job_name}

        if [[ ! -d ${workspace} ]]; then
            mkdir -p ${workspace}
        fi

        if [[ -n ${workspace} && -d ${workspace} ]]; then
            cd ${workspace} > /dev/null
        else
            log error "The job path has no found! "
        fi
    else
        show_viy "This project is not a Zen platform ."
    fi

    if [[ "`is_yunovo_server`" == "true" ]];then

        echo
        show_vip "--> build app start ."

        handle_variable
        print_variable
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi

    init
    build_nxos_app

    if [[ ${build_deploy} == "true" ]]; then
        check_multi_channel
        touch_json
    fi

    sync_to_f1

    ## 保存最后一次 commit id
    if [[ -n ${GIT_COMMIT} && -d ${commit_p} ]]; then
        echo ${GIT_COMMIT} > ${commit_p}/.git.commit.${job_name}
    else
        log error "GIT COMMIT 值为空 ..."
    fi

    if [[ "`is_yunovo_server`" == "true" ]];then

        ## 打印编译所需要的时间
        print_make_completed_time

        echo
        show_vip "--> build app end ."
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi
}

main "$@"
