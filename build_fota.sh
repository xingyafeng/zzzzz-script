#!/usr/bin/env bash

# Common utilities, variables and checks for all build scripts.
set -o errexit
set -o nounset
set -o pipefail

# 项目名
build_project=
# 项目类型
build_from_type=
# 项目待升级版本
build_from_version=
build_from_more=
# 项目类型
build_to_type=
# 项目升级版本
build_to_version=
build_to_more=
# oem|odm type
build_custom_type=

# ---------------
# 工具仓库分支名
tools_branch_name=

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

# 配置su权限
is_su_enable='yes'

# 配置testkey
export is_testkey=''

function backup_oem_odm() {

    local dir=${1:-}
    local image=

    if [[ -z ${dir} ]]; then
        log error "The dir is null ..."
    else
        log print "The dir: ${dir} ..."
    fi

    pushd data/${dir}/ > /dev/null

    # oem odm 标记，第一位是首位　第二位是倒数第二位
    local oemflag=$(get_custom_flag oem.img)
    local oem0=${oemflag:0:1}
    local oem1=${oemflag:1:1}

    local odmflag=$(get_custom_flag odm.img)
    local odm0=${odmflag:0:1}
    local odm1=${odmflag:1:1}

    if false;then
    echo '------------------------------------- backup_oem'
    echo 'oemflag = ' ${oemflag}
    echo 'oem0    = ' ${oem0}
    echo 'oem1    = ' ${oem1}
    echo '------------------------------------- backup_odm'
    echo 'odmflag = ' ${odmflag}
    echo 'odm0    = ' ${odm0}
    echo 'odm1    = ' ${odm1}
    echo '------------------------------------- backup_end'
    fi

    for mbn in `ls ${oem0}*${oem1}0.mbn` ; do
        image=`ls ${oem0}*${build_custom_type}*${oem1}0.mbn`

        if [[ ! -d tmp/oem ]]; then
            mkdir -p tmp/oem
        fi

        mv ${mbn} tmp/oem

#        echo 'image = ' ${image}
#        echo 'mbn   = ' ${mbn}

        if [[ ${image} == ${mbn} ]]; then
            if [[ -f tmp/oem/${image} ]]; then
                mv -vf tmp/oem/${image} .
            else
                log warn 'it oem image has no found ...'
            fi
        fi
    done

    for mbn in `ls ${odm0}*${odm1}0.mbn` ; do
        image=`ls ${odm0}*${build_custom_type}*${odm1}0.mbn`

        if [[ ! -d tmp/odm ]]; then
            mkdir -p tmp/odm
        fi

        mv ${mbn} tmp/odm

#        echo 'image = ' ${image}
#        echo 'mbn   = ' ${mbn}

        if [[ ${image} == ${mbn} ]]; then
            if [[ -f tmp/odm/${image} ]]; then
                mv -vf tmp/odm/${image} .
            else
                log warn 'it odm image has no found ...'
            fi
        fi
    done

    popd > /dev/null
}

#####################################################
##
##  函数: update_fota_config
##  功能: 更新xml配置文件
##  参数: 1. update_releasekey      <升级包>
##        2. downgrade              <降级包>
##        3. bad_integrity_9.19.3   <testkey>
##        4. invalid_9.19.1         <error > 升级包中使用降级包
##        5. size_over_1.5G_9.19.4 升级包中添加了大文件fillfile
#
##  举栗:
##      update_fota_config update_releasekey
##      update_fota_config downgrade
##
####################################################
function update_fota_config() {

    local fs=${1:-}
    local fota_name=
    local fota_xmls=

    log print "update fota config : ${fs} ..."

    case ${fs} in

        update_releasekey) # 1. release key　升级包

            fota_name=update_rkey.zip
            fota_xmls=TCL_${device_name}_${build_from_version}_${build_to_version}_upgrade.xml

            if [[ -f ${fota_name} ]]; then
                python File2Base64.py -b ${fota_name} && echo >> ${fota_name}__base64
            fi

            if [[ -f ${prexml} ]]; then
                git checkout -- ${prexml}

                update_from_version ${dv_from_version}
                update_to_version ${dv_to_version}
                update_size ${fota_name}
                update_time
                update_device_name
            fi

            head -c -1 -q ${prexml} ${fota_name}__base64 ${endxml} > ${fota_xmls}
        ;;

        downgrade_releasekey) # 2. release key　降级包

            fota_name=downgrade_rkey.zip
            fota_xmls=TCL_${device_name}_${build_to_version}_${build_from_version}_downgrade.xml

            if [[ -f ${fota_name} ]]; then
                python File2Base64.py -b ${fota_name} && echo >> ${fota_name}__base64
            fi

            if [[ -f ${prexml} ]]; then
                git checkout -- ${prexml}

                update_base_version downgrade
                update_from_version ${dv_to_version}
                update_to_version ${dv_from_version}
                update_size ${fota_name}
                update_time
                update_device_name
            fi

            head -c -1 -q ${prexml} ${fota_name}__base64 ${endxml} > ${fota_xmls}
        ;;

        update_testkey) # 3. test key 升级包

            fota_name=update_tkey.zip
            fota_xmls=TCL_${device_name}_${build_from_version}_${build_to_version}_bad_integrity_9.19.3.xml

            if [[ -f ${fota_name} ]]; then
                python File2Base64.py -b ${fota_name} && echo >> ${fota_name}__base64
            fi

            if [[ -f ${prexml} ]]; then
                git checkout -- ${prexml}

                update_base_version downgrade
                update_from_version ${dv_from_version}
                update_to_version ${dv_to_version}
                update_size ${fota_name}
                update_time
                update_device_name
            fi

            head -c -1 -q ${prexml} ${fota_name}__base64 ${endxml} > ${fota_xmls}
        ;;

        invalid) # 4. 无效升级包，升级包中使用降级包

            fota_name=downgrade_rkey.zip
            fota_xmls=TCL_${device_name}_${build_from_version}_${build_to_version}_invalid_9.19.1.xml

            if [[ -f ${prexml} ]]; then
                git checkout -- ${prexml}

                update_base_version invalid
                update_from_version ${dv_from_version}
                update_to_version ${dv_to_version}
                update_size ${fota_name}
                update_time
                update_device_name
            fi

            head -c -1 -q ${prexml} ${fota_name}__base64 ${endxml} > ${fota_xmls}

        ;;

        bigupdate_releasekey)  # 5. 大文件升级包

            local bigfile=bigupdate.zip

            fota_name=update_rkey.zip
            fota_xmls=TCL_${device_name}_${build_from_version}_${build_to_version}_size_over_1.5G_9.19.4.xml

            if ! ${ADD_BIG_UPC}; then
                break;
            fi

            if [[ -f ${fota_name} ]]; then
                cp -vf ${fota_name} ${bigfile}

                if [[ -f fillfile ]]; then
                    # 增加大文件，超过1G
                    zip ${bigfile} fillfile
                else
                    log error 'The fill file has no found ...'
                fi

                java -Xmx2048m -Djava.library.path=${tmpfs}/fota/JrdDiffTool/lib64 \
                    -Dcom.tclcom.apksig.connect=localhost:50051,10.128.180.21:50051,10.128.180.117:50051,10.128.180.220:50051 \
                    -Dcom.tclcom.apksig.keysuite=${build_project} \
                    -jar ${tmpfs}/fota/JrdDiffTool/framework/signapk.jar \
                    -providerClass com.tclcom.apksig.StubJCAProvider \
                    -w ${tmpfs}/fota/JrdDiffTool/TCT_releasekeys/releasekey.x509.pem \
                       ${tmpfs}/fota/JrdDiffTool/TCT_releasekeys/releasekey.pk8 \
                       ${tmpfs}/fota/JrdDiffTool/data/${bigfile} \
                       ${tmpfs}/fota/JrdDiffTool/data/bigupdate_rkey.zip

                python File2Base64.py -b bigupdate_rkey.zip && echo >> bigupdate_rkey.zip__base64
            fi

            if [[ -f ${prexml} ]]; then
                git checkout -- ${prexml}

                update_base_version size_over_1.5G
                update_from_version ${dv_from_version}
                update_to_version ${dv_to_version}
                update_size bigupdate_rkey.zip
                update_time
                update_device_name
            fi

            head -c -1 -q ${prexml} bigupdate_rkey.zip__base64 ${endxml} > ${fota_xmls}
        ;;
    esac
}

function update_fota_xml() {

    local ADD_BIG_UPC=false
    local prexml=TCL_prebase.xml
    local endxml=TCL_endbase.xml
    local configs=(update_releasekey downgrade_releasekey update_testkey invalid bigupdate_releasekey)

    local dv_from_version=`echo ${build_from_version} | sed s/"[v|V]"//`
    local dv_to_version=`echo ${build_to_version} | sed s/"[v|V]"//`

    pushd data > /dev/null

    for cfg in ${configs[@]} ; do
        update_fota_config ${cfg}
    done

    # 备份FOTA版本
    copy_fota_version

    popd > /dev/null
}

function backup_image_version() {

    log debug "'dir1: ' ${dir1} 'dir2: ' ${dir2}"
    if [[ -d ${dir1} && -d ${dir2} ]]; then
        time cp -vf ${dir1}/*.mbn ${dir2}

        # 备份正确的oem odm image
        backup_oem_odm $(basename ${dir2})
    fi
}

function prepare() {

    local from_ota_p=${mfs_p}/${build_project}/${build_from_type}/${build_from_version}/${build_from_more}
    local to_ota_p=${mfs_p}/${build_project}/${build_to_type}/${build_to_version}/${build_to_more}
    local dir1=
    local dir2=

    if [[ -d `git rev-parse --git-dir` ]];then
        git clean -dxfq
    else
        log error "Could not found '.git' folder ..."
    fi

    # 备份from version
    dir1=${from_ota_p}
    dir2=data/src
    backup_image_version

    # 备份to version
    dir1=${to_ota_p}
    dir2=data/tgt
    backup_image_version
}

function make_inc() {

    scripts=()

    # 准备基准包 一个基准包 一个升级包
    prepare

    scripts[${#scripts[@]}]=prepare_pkg_source.sh
    scripts[${#scripts[@]}]=prepare_pkg_target.sh
    scripts[${#scripts[@]}]=gen_diff_pkg_releasekey.sh
    scripts[${#scripts[@]}]=gen_diff_pkg_testkey.sh
    scripts[${#scripts[@]}]=gen_diff_downgrade_pkg_releasekey.sh

    for script in ${scripts[@]};do
        if [[ -f ${script} && -x ${script} ]]; then
            Command bash ${script}
        else
            log error "${script} 脚本文件不存在或者没有权限."
        fi
    done

    # 更新差分包xml
    update_fota_xml
}

function handle_common_variable() {

    # 拿到项目对应工具仓库
    get_tools_branch

    # 下载仓库
    git_sync_repository tools/JrdDiffTool ${tools_branch_name} ${fota_tools_p}

    # 获取设备名
    get_device_name

    # 配置testkey
    set_testkey

    # 配置java version
    tct::utils::set_java_version
}

function handle_vairable() {

    # 项目名
    build_project=${fota_project:-}
    if [[ -z ${build_project} ]]; then
        log error 'The build project is null ...'
    fi

    # 项目类型
    build_from_type=${fota_from_type:-}
    if [[ -z ${build_from_type} ]]; then
        log error 'The build type is null ...'
    fi

    build_to_type=${fota_to_type:-}
    if [[ -z ${build_to_type} ]]; then
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
        log warn "The build_from_more is null, please check it."
    else
        from_more=$(dirname ${build_from_more})
    fi

    # 升级版本号更多信息
    build_to_more=${fota_to_more:=}
    if [[ -z ${build_to_more} ]];then
        log warn "The build_to_more is null, please check it."
    else
        to_more=$(dirname ${build_to_more})
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

    echo "build_project        = " ${build_project}
    echo '-----------------------------------------'
    echo "build_from_type      = " ${build_from_type}
    echo "build_from_version   = " ${build_from_version}

    if [[ -n ${build_from_more} ]]; then
        echo "build_from_more      = " ${build_from_more}
    fi

    echo '-----------------------------------------'
    echo "build_to_type        = " ${build_to_type}
    echo "build_to_version     = " ${build_to_version}

    if [[ -n ${build_to_more} ]]; then
        echo "build_to_more        = " ${build_to_more}
    fi

    echo '-----------------------------------------'
    echo "build_custom_type    = " ${build_custom_type}
    echo '-----------------------------------------'
    echo "tools_branch_name    = " ${tools_branch_name}

    if [[ -n ${from_more} ]]; then
        echo "from_more            = " ${from_more}
    fi

    if [[ -n ${to_more} ]]; then
        echo "to_more              = " ${to_more}
    fi

    echo "device_name          = " ${device_name}
    echo '-----------------------------------------'
    echo "is_su_enable         = " ${is_su_enable}

    if [[ -n ${is_testkey} ]]; then
        echo "is_testkey           = " ${is_testkey}
    fi

    echo '-----------------------------------------'
    echo
}

function init() {

    local from_more=
    local to_more=

    handle_vairable
    print_variable
}

function main() {

    local mfs_p=/mfs_tablet/teleweb
    local fota_tools_p=${tmpfs}/fota
    local device_name=

    init

    pushd ${fota_tools_p}/JrdDiffTool > /dev/null

    make_inc

    popd > /dev/null
}

main "$@"
