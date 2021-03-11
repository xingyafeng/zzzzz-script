#!/usr/bin/env bash

# if error;then exit
set -e

# 项目名
build_project=
# 项目类型
build_type=
# 项目待升级版本
build_from_version=
build_from_more=
# 项目升级版本
build_to_version=
build_to_more=
# oem|odm type
build_custom_type=

# ---------------
tools_branch_name=

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

function get_flag() {

    local image=${1:-}

    if [[ -n ${image} ]]; then
        cat P* | egrep -w ${image} | sed 's%.*rename_prefix="%%'| sed 's%".*%%' | head -1
    fi
}

function backup_oem_odm() {

    local dir=${1:-}
    local image=

    # oem odm 标记，第一位是首位　第二位是倒数第二位
    local oemflag=$(get_flag oem.img)
    local oem0=${oemflag:0:1}
    local oem1=${oemflag:1:1}

    local odmflag=$(get_flag odm.img)
    local odm0=${odmflag:0:1}
    local odm1=${odmflag:1:1}

    pushd data/${dir}/ > /dev/null

    for mbn in "`ls ${oem0}*${oem1}0.mbn`" ; do
        image=`ls O*${build_custom_type}*M0.mbn`

        if [[ ! -d tmp/oem ]]; then
            mkdir -p tmp/oem
        fi

        mv ${mbn} tmp/oem

        if [[ ${image} == ${mbn} ]]; then
            mv -vf tmp/oem/${image} .
        fi
    done

    for mbn in "`ls ${odm0}*${odm1}0.mbn`" ; do
        image=`ls ${odm0}*${build_custom_type}*${odm1}0.mbn`

        if [[ ! -d tmp/odm ]]; then
            mkdir -p tmp/odm
        fi

        mv ${mbn} tmp/odm

        if [[ ${image} == ${mbn} ]]; then
            mv -vf tmp/odm/${image} .
        fi
    done

    popd > /dev/null
}

function prepare() {

    local rom_p=${mfs_p}/${build_project}
    local pre_ota_p=
    local curr_ota_p=

    if [[ ! -d tmp ]]; then
        mkdir -p tmp
    fi

    if [[ ! -d data ]]; then
        mkdir -p data
    fi

    if ${userdebug}; then
        build_from_more=originfiles/userdebug
        build_to_more=originfiles/userdebug
    fi

    pre_ota_p=${rom_p}/${build_type}/${build_from_version}/${build_from_more}
    curr_ota_p=${rom_p}/${build_type}/${build_to_version}/${build_to_more}

    if [[ -d ${pre_ota_p} ]]; then
        cp -vf ${pre_ota_p}/*.mbn data/src
        backup_oem_odm src
    fi

    if [[ -d ${curr_ota_p} ]]; then
        cp -vf ${curr_ota_p}/*.mbn data/tgt
        backup_oem_odm tgt
    fi
}

function make_inc() {

    declare -a scripts

    scripts[${#scripts[@]}]=prepare_pkg_source.sh
    scripts[${#scripts[@]}]=prepare_pkg_target.sh
    scripts[${#scripts[@]}]=gen_diff_pkg_releasekey.sh
    scripts[${#scripts[@]}]=gen_diff_pkg_testkey.sh
    scripts[${#scripts[@]}]=gen_diff_downgrade_pkg_releasekey.sh

    for script in ${scripts[@]};do
        if [[ -f ${script} && -x ${script} ]]; then
            Command bash ${script}
        else
            log error "脚本文件不存在或者没有权限."
        fi
    done

    handle_xml
}

function update_from_version() {

    local version=${1:-}
    local from_version=8.2.3

    sed -i s/${from_version}/${version}/g ${prexml}
}

function update_to_version() {

    local version=${1:-}
    local to_version=8.1.0

    sed -i s/${to_version}/${version}/g ${prexml}
}

function update_size() {

    local file=${1:-}
    local size=2862528

    sed -i s/${size}/$(get_file_size ${file})/g ${prexml}
}

function update_time() {

    local time=2018-05-23

    sed -i s/${time}/$(date +"%Y-%m-%d")/g ${prexml}
}

function update_device_name() {

    local devname=9048S

    sed -i s/${devname}/${device_name}/g ${prexml}
}

function update_fota_config() {

    local fs=${1:-}
    local fota_name=

    case ${fs} in

        update_releasekey)     # release key　升级包

            fota_name=update_rkey.zip


            if [[ -f ${fota_name} ]]; then
                python File2Base64.py -b ${fota_name} && echo >> ${fota_name}__base64
            fi

            if [[ -f ${prexml} ]]; then
                git checkout -- ${prexml}
                sed -i s/8.1.0/${remove_v_build_from_version}/g ${prexml}
                sed -i s/8.2.3/${remove_v_build_to_version}/g ${prexml}
                size=`ls -al update_rkey.zip | awk '{print $5}'`
                sed -i s/2862528/${size}/g ${prexml}
                sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${prexml}
                sed -i s/9048S/${device_name}/g ${prexml}
            fi

            head -c -1 -q ${prexml} update_rkey.zip__base64 ${endxml} > TCL_${device_name}_${build_from_version}_${build_to_version}_upgrade.xml

        ;;

        update_testkey)        # test    key　升级包
        ;;

        downgrade_releasekey)  # release key　降级包
        ;;

        invalid)               # 无效升级包，升级包中使用降级包
        ;;

        bigupdate_releasekey)  # 大文件升级包
        ;;
    esac
}

function handle_xml() {

    local prexml=TCL_9048S_1.xml
    local xml2=TCL_9048S_2.xml
    local remove_v_build_from_version=`echo ${build_from_version} | sed s/"[v|V]"//`
    local remove_v_build_to_version=`echo ${build_to_version} | sed s/"[v|V]"//`

    __green__ "remove_v_build_from_version = ${remove_v_build_from_version}"
    __green__ "remove_v_build_to_version = ${remove_v_build_to_version}"

    pushd data > /dev/null

    # 1. upgrade
    python File2Base64.py -b update_rkey.zip
    echo "" >>update_rkey.zip__base64

    if [[ -f ${prexml} ]]; then
        git checkout -- ${prexml}
        sed -i s/8.1.0/${remove_v_build_from_version}/g ${prexml}
        sed -i s/8.2.3/${remove_v_build_to_version}/g ${prexml}
        size=`ls -al update_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${prexml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${prexml}
        sed -i s/9048S/${device_name}/g ${prexml}
    fi

    head -c -1 -q ${prexml} update_rkey.zip__base64 ${endxml} > TCL_${device_name}_${build_from_version}_${build_to_version}_upgrade.xml

    # 2. downgrade <降级包>
    python File2Base64.py -b downgrade_rkey.zip
    echo "" >>downgrade_rkey.zip__base64

    if [[ -f ${prexml} ]]; then
        git checkout -- ${prexml}
        sed -i s/TCL_9048S_8.1.0_8.2.3/TCL_9048S_8.1.0_8.2.3_downgrade/g ${prexml}
        sed -i s/8.1.0/${remove_v_build_to_version}/g ${prexml}
        sed -i s/8.2.3/${remove_v_build_from_version}/g ${prexml}
        size=`ls -al downgrade_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${prexml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${prexml}
        sed -i s/9048S/${device_name}/g ${prexml}
    fi

    head -c -1 -q ${prexml} downgrade_rkey.zip__base64 ${endxml} > TCL_${device_name}_${build_to_version}_${build_from_version}_downgrade.xml

    # 3. bad_integrity_9.19.3 <testkey>
    python File2Base64.py -b update_tkey.zip
    echo "" >>update_tkey.zip__base64

    if [[ -f ${prexml} ]]; then
        git checkout -- ${prexml}
        sed -i s/TCL_9048S_8.1.0_8.2.3/TCL_9048S_8.1.0_8.2.3_bad_integrity/g ${prexml}
        sed -i s/8.1.0/${remove_v_build_from_version}/g ${prexml}
        sed -i s/8.2.3/${remove_v_build_to_version}/g ${prexml}
        size=`ls -al update_tkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${prexml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${prexml}
        sed -i s/9048S/${device_name}/g ${prexml}
    fi

    head -c -1 -q ${prexml} update_tkey.zip__base64 ${endxml} > TCL_${device_name}_${build_from_version}_${build_to_version}_bad_integrity_9.19.3.xml

    # 4. invalid_9.19.1 <error > 升级包中使用降级包
    if [[ -f ${prexml} ]]; then
        git checkout -- ${prexml}
        sed -i s/TCL_9048S_8.1.0_8.2.3/TCL_9048S_8.1.0_8.2.3_invalid/g ${prexml}
        sed -i s/8.1.0/${remove_v_build_from_version}/g ${prexml}
        sed -i s/8.2.3/${remove_v_build_to_version}/g ${prexml}
        size=`ls -al downgrade_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${prexml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${prexml}
        sed -i s/9048S/${device_name}/g ${prexml}
    fi

    head -c -1 -q ${prexml} downgrade_rkey.zip__base64 ${endxml} > TCL_${device_name}_${build_from_version}_${build_to_version}_invalid_9.19.1.xml

    # 5. size_over_1.5G_9.19.4 升级包中添加了大文件fillfile
    if ${ADD_BIG_UPC}; then
        echo "-------------------make big upc-------------------------------"
        cp update_rkey.zip bigupdate.zip
        zip bigupdate.zip fillfile
        java -Xmx2048m -Djava.library.path=${tmpfs}/JrdDiffTool/lib64 -Dcom.tclcom.apksig.connect=localhost:50051,10.128.180.21:50051,10.128.180.117:50051,10.128.180.220:50051 -Dcom.tclcom.apksig.keysuite=thor84gvzw -jar ${tmpfs}/JrdDiffTool/framework/signapk.jar -providerClass com.tclcom.apksig.StubJCAProvider -w ${tmpfs}/JrdDiffTool/TCT_releasekeys/releasekey.x509.pem ${tmpfs}/JrdDiffTool/TCT_releasekeys/releasekey.pk8 ${tmpfs}/JrdDiffTool/data/bigupdate.zip ${tmpfs}/JrdDiffTool/data/bigupdate_rkey.zip
        python File2Base64.py -b bigupdate_rkey.zip
        echo "" >>bigupdate_rkey.zip__base64
        if [[ -f ${prexml} ]]; then
            git checkout -- ${prexml}
            sed -i s/TCL_9048S_8.1.0_8.2.3/TCL_9048S_8.1.0_8.2.3_size_over_1.5G/g ${prexml}
            sed -i s/8.1.0/${remove_v_build_from_version}/g ${prexml}
            sed -i s/8.2.3/${remove_v_build_to_version}/g ${prexml}
            size=`ls -al bigupdate_rkey.zip | awk '{print $5}'`
            sed -i s/2862528/${size}/g ${prexml}
            sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${prexml}
            sed -i s/9048S/${device_name}/g ${prexml}
        fi

        head -c -1 -q ${prexml} bigupdate_rkey.zip__base64 ${endxml} > TCL_${device_name}_${build_from_version}_${build_to_version}_size_over_1.5G_9.19.4.xml
    else
        echo "------------------ADD_BIG_UPC = $ADD_BIG_UPC------------------"
    fi

    backup_fota

    popd > /dev/null
}

# 初始化备份的文件名
function init_copy_fota() {

    copyfs=()

    copyfs[${#copyfs[@]}]=update_rkey.zip
    copyfs[${#copyfs[@]}]=update_tkey.zip
    copyfs[${#copyfs[@]}]=downgrade_rkey.zip
    copyfs[${#copyfs[@]}]=$(ls TCL_${device_name}_${build_from_version}_${build_to_version}_*.xml)
    copyfs[${#copyfs[@]}]=$(ls TCL_${device_name}_${build_to_version}_${build_from_version}_*.xml)

}

function backup_fota() {

    local ota_path=${mfs_p}/${build_project}/fota
    local DEST_PATH=

    if ${userdebug}; then
        local prj_path=${build_from_version}_${build_to_version}_userdebug_fota_`date +"%Y-%m-%d_%H-%M-%S"`
    else
        local prj_path=${build_from_version}_${build_to_version}_fota_`date +"%Y-%m-%d_%H-%M-%S"`
    fi

    DEST_PATH=${ota_path}/${prj_path}

    init_copy_fota
    enhance_copy_file '.' ${DEST_PATH}

    echo
    show_vip "--> copy fota image finish ..."
}

function handle_vairable() {

    # 项目名
    build_project=${foat_project:-}
    if [[ -z ${build_project} ]]; then
        log error 'The build project is null ...'
    fi

    # 项目类型
    build_type=${foat_type:-}
    if [[ -z ${build_type} ]]; then
        log error 'The build type is null ...'
    fi

    # 待升级版本号
    build_from_version=${fota_from_version:-}
    if [[ -z "`echo ${build_from_version} | sed -n '/^[v|V]/p'`" ]]; then

        build_from_version=v${build_from_version}
        if [[ -z ${build_from_version} ]]; then
            log error "The build_from_version is null, please check it."
        fi
    fi

    # 升级版本号
    build_to_version=${fota_to_version:=}
    if [[ -z "`echo ${build_to_version} | sed -n '/^[v|V]/p'`" ]]; then

        build_to_version=v${build_to_version}
        if [[ -z ${build_to_version} ]]; then
            log error "The build_to_version is null, please check it."
        fi
    fi

    # 待升级版本号更多信息
    build_from_more=${fota_from_more:=}
    if [[ -z ${build_from_more} ]];then
        log error "The build_from_more is null, please check it."
    fi

    # 升级版本号更多信息
    build_to_more=${fota_to_more:=}
    if [[ -z ${build_to_more} ]];then
        log error "The build_to_more is null, please check it."
    fi

    # 5. oem type
    build_custom_type=${fota_custom_type:-}
    if [[ -z ${build_custom_type} ]];then
        log error "The build_custom_type is null, please check it."
    fi

    handle_common_variable
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_from_version   = " ${build_from_version}
    echo "build_from_more      = " ${build_from_more}
    echo "build_to_version     = " ${build_to_version}
    echo "build_to_more        = " ${build_to_more}
    echo "build_custom_type    = " ${build_custom_type}
    echo '-----------------------------------------'
    echo "tools_branch_name    = " ${tools_branch_name}
    echo "project_name_src     = " ${project_name_src}
    echo "project_name_tgt     = " ${project_name_tgt}
    echo "device_name          = " ${device_name}
    echo '-----------------------------------------'
    echo
}

function get_device_name() {

    project_name_src=$(dirname ${build_from_more})
    project_name_tgt=$(dirname ${build_to_more})

    if [[ ${project_name_src} != ${project_name_tgt} ]]; then
        log error "project don't matchup ..."
    fi

    case ${project_name_src} in

        KIDS)
            device_name="9049L"
            ;;
        *)
            device_name="9048S"
            ;;
    esac
}

# 拿到tools/JrdDiffTool仓库的分支名
function get_tools_branch() {

    case ${build_project} in

        thor84gvzw)
            tools_branch_name='thor84g_vzw_1.0'
            ;;

        transformervzw)
            tools_branch_name='TransformerVZW'
        ;;

        *)
            tools_branch_name=''
        ;;
    esac
}

function handle_common_variable() {

    get_tools_branch

    # 下载仓库
    git_sync_repository tools/JrdDiffTool ${tools_branch_name}

    # 获取设备名
    get_device_name
}

function init() {

    local project_name_src=
    local project_name_tgt=

    handle_vairable
    print_variable
}

function main() {

    local mfs_p=/mfs_tablet/teleweb
    local device_name=

    init

    pushd ${tmpfs}/JrdDiffTool > /dev/null

    prepare
    make_inc

    popd > /dev/null
}

main "$@"
