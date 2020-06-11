#!/usr/bin/env bash

## 若某一个命令返回非零值就退出
set -e

#### --------------------------------------
## 0.1 如: [ aeon6735_65c_s_l1|magc6580_we_l|yunovo| ** ]
build_device=""
## 0.2 编译类型 如: [user|userdebug|eng]
build_type=""
## 1.0 build board [版型]  # cm02_NXOS-ZX_S1.00_2019.03.22_19.47.54
build_board=""

# 封板标签
declare -a refs

ver_name=""
to_ver_name=""
to_flag=false

#### --------------------------------------
## 当前Shell文件名
shellfs=$0

### init function
. "`dirname $0`/jenkins/yunovo_init.sh"

# 封板标签xml的存放路径
ref_p=${tmpfs}/ref

# 备份差异表
function copy_repo_diffmanifests_content() {

    local BASE_PATH=""
    local DEST_PATH=""

    local custom_name=${yunovo_custom}_${yunovo_project}

    BASE_PATH=${diffmanifest_p}/${yunovo_board}/${BUILD_DISPLAY_NAME}
    DEST_PATH=${BASE_PATH}

    echo "dimanifest_p = $diffmanifest_p"
    echo "BASE_PATH = ${BASE_PATH}"
    echo "DEST_PATH = ${DEST_PATH}"
    echo

    if [[ ! -d ${diffmanifest_p} ]];then
        mkdir -p ${diffmanifest_p}
    fi

    if [[ ! -d ${DEST_PATH} ]];then
        mkdir -p ${DEST_PATH}
    fi

    if [[ -d ${DEST_PATH} && -f ${rdiffs} ]];then
        cp -vf ${rdiffs} ${DEST_PATH}

        # 清除中间文件
        if [[ -f ${rdiffs} ]]; then
            rm -rf ${rdiffs}
        fi
    else
        log error "The $DEST_PATH or The $rdiffs no exist ..."
    fi
}

# 上传服务器
function rsync_repo_diffmanifests_upload_server() {

    local rdiffs="$tmpfs/${DFN}.html"
    local diffmanifest_p=${version_p}

    email_massage_has_colors
    copy_repo_diffmanifests_content

    rsync -av ${diffmanifest_p}/ ${git_username}@${f1_server}:${rom_p}/share/diffmanifest

    if [[ -d ${diffmanifest_p} ]];then
        rm -rf ${diffmanifest_p}/*
    fi

    echo
    show_vip "--> sync diffmanifest end ..."
}

# 拿到两个版本的default.xml
function get_default_xml() {

    local manifest_p=${tmpfs}/manifest

    cd ${manifest_p} > /dev/null

    for ref in ${refs[@]};
    do
        if [[ -d .git && -n "${ref}" ]];then
            git fetch -q `git remote` refs/build/${git_username}/${ref}
            git checkout -q FETCH_HEAD

            # 备份default.xml
            cp -rf default.xml ${ref_p}/${ref}.xml
        fi
    done

    # 切换默认分支 master
    git checkout -q master

    cd - > /dev/null
}

# 清除中间
function clean_xml() {

    local thisFiles=""

    cd .repo/manifests > /dev/null

    if [[ -n "`git status -s`" ]];then
        echo "---- recover .repo/manifests "
    else
        return 0
    fi

    thisFiles=`git diff --cached --name-only`
    if [[ -n "$thisFiles" ]];then
        git reset HEAD . ###recovery for cached files
    fi

    thisFiles=`git clean -dn`
    if [[ -n "$thisFiles" ]]; then
        git clean -df
    fi

    thisFiles=`git diff --name-only`
    if [[ -n "$thisFiles" ]]; then
        git checkout HEAD ${thisFiles}
    fi

    cd .. -> /dev/null
}

# 生成 差异表
function rdiff() {

    get_default_xml

    if [[ -d ${ref_p} ]]; then
        cp -rf ${ref_p}/*.xml .repo/manifests
    fi

    # 输出版本差异表
    if [[ -n "${refs[0]}" && -n "${refs[1]}" ]]; then
        repo diffmanifests ${refs[0]}.xml ${refs[1]}.xml | tee ${diff_table}
    elif [[ -n "${refs[0]}" ]]; then
        repo diffmanifests ${refs[0]}.xml | tee ${diff_table}
    elif [[ -n "${refs[1]}" ]]; then
        repo diffmanifests ${refs[1]}.xml | tee ${diff_table}
    fi

    clean_xml
}

# 获取 版本/客户/项目
function get_ver_info() {

    local tag=

    if [[ "$1" ]]; then
        tag=$1
    else
        log error "函数:${FUNCNAME[0]}, 参数错误 ..."
    fi

    refs[${#refs[@]}]=${tag}

    yunovo_board=`echo ${tag} | awk -F '_' '{ print $1 }' | tr 'A-Z' 'a-z'`
    tmp=`echo ${tag} | awk -F '_' '{ print $2 }' | tr 'A-Z' 'a-z'`
    yunovo_custom=`echo ${tmp}  | awk -F '-' '{ print $1 }'`
    yunovo_project=`echo ${tmp} | awk -F '-' '{ print $2 }'`
}

function handle_vairable() {

    local tmp=""

    ## 1. yunovo pre tag
    if [[ -n "${yunovo_pre_tag}" ]]; then
        get_ver_info ${yunovo_pre_tag}

        if [[ -z ${yunovo_cur_tag} ]]; then
            ver_name=`echo ${yunovo_pre_tag} | awk -F '_' '{ print $(NF-2) "_" $(NF-1) "_" $(NF) }'`
        fi
    else
        __err "yunovo_pre_tag has error. please check it ."
    fi

    ## 2. yunovo cur tag
    if [[ -n "${yunovo_cur_tag}" ]]; then

        if [[ -z ${yunovo_pre_tag} ]]; then
            ver_name=`echo ${yunovo_cur_tag} | awk -F '_' '{ print $(NF-2) "_" $(NF-1) "_" $(NF) }'`
        else
            ver_name=`echo ${yunovo_pre_tag} | awk -F '_' '{ print $(NF-2) "_" $(NF-1) "_" $(NF) }'`
            to_ver_name=`echo ${yunovo_cur_tag} | awk -F '_' '{ print $(NF-2) "_" $(NF-1) "_" $(NF) }'`
        fi

        get_ver_info ${yunovo_cur_tag}
    else
        log error "The yunovo_cur_tag and The yunovo_pre_tag has error, please check it ."
    fi

    cd_to_gettop

    # 0.1 build_device
    build_device=`get_device_type`
    if [[ "`is_build_device`" == "false" || -z ${build_device} ]];then
        log error "The build_device has error, please check it ."
    fi

    # 0.2 build_type
    build_type=${yunovo_type:=user}

    ## 1.0 build board [版型]  # cm02_NXOS-ZX_S1.00_2019.03.22_19.47.54
    build_board=${yunovo_board}
    if [[ -z ${build_board} ]]; then
        log error "build_board has error. please check it ."
    fi

    ## 1.1 yunovo custom [客户]
    if [[ -z "${yunovo_custom}" ]];then
        log error "The yunovo_custom has error. please check it ."
    fi

    ## 1.2 yunovo project [项目]
    if [[ -z "${yunovo_project}" ]];then
        log error "yunovo_project has error. please check it ."
    fi

    # diff name
    DFN=${yunovo_board}_${yunovo_custom}-${yunovo_project}
}

function print_variable() {

    echo "JOBS = $JOBS"
    echo '-----------------------------------------'
    echo "build_board      = ${build_board}"
    echo "build_device     = ${build_device}"
    echo "build_type       = ${build_type}"
    echo '-----------------------------------------'
    echo "yunovo_board     = ${yunovo_board}"
    echo "yunovo_custom    = ${yunovo_custom}"
    echo "yunovo_project   = ${yunovo_project}"
    echo "yunovo_pre_tag   = ${yunovo_pre_tag}"
    echo "yunovo_cur_tag   = ${yunovo_cur_tag}"
    echo "ver_name         = ${ver_name}"
    echo "to_ver_name      = ${to_ver_name}"
    echo "refs             = ${refs[@]}"
    echo '-----------------------------------------'
    echo "manifest branch  = ${manifest_branchN}"
    echo "manifest path    = ${manifest_path}"
    echo '-----------------------------------------'
    echo
}

function init() {

    if [[ ! -d ${ref_p} ]]; then
        mkdir -p ${ref_p}
    fi

    handle_vairable
    print_variable

    # 更新仓库
    download_and_update_apk_repository manifest master
}

function main() {

    local startT=`date +'%Y-%m-%d %H:%M:%S'`

    echo
    show_vip "--> repo diffmanifests start ." && log debug "--> repo diffmanifests start ."

    init

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        ### 初始化环境变量
        if [[ "`is_check_lunch`" == "no lunch" ]];then
            handle_lunch_project
            source_init
        else
            print_env
        fi
    fi

    download_mirror
    down_load_yunovo_source_code

    rdiff

    rsync_repo_diffmanifests_upload_server

    if [[ "`is_yunovo_server`" == "true" ]];then

        ### 打印编译所需要的时间
        print_make_completed_time

        echo
        show_vip "--> repo diffmanifests end ." && log debug "--> repo diffmanifests end ."
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi
}

main $@
