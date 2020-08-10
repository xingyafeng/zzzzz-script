#!/usr/bin/env bash

# if error;then exit
set -e

# 1. src version
build_source_version=
# 2. tgt version
build_target_version=
# 3. src more
build_source_more=
# 4. tgt sore
build_target_more=
# 5. oem type
build_oem_type=

# exec shell
shellfs=$0

# init function
. "`dirname $0`/tct/tct_init.sh"

function backup_oem() {

    local dir=$1
    local TM=

    pushd data/${dir}/ > /dev/null

    for mbn in "`ls O*M0.mbn`" ; do
        TM=`ls O*${build_oem_type}*M0.mbn`

        mkdir -p tmp/oem
        mv -vf ${mbn} tmp/oem
        mv tmp/oem/${TM} .
    done

    for mbn in "`ls V*80.mbn`" ; do
        TM=`ls V*${build_oem_type}*80.mbn`

        mkdir -p tmp/oem
        mv -vf ${mbn} tmp/oem
        mv tmp/oem/${TM} .
    done

    popd > /dev/null
}

function prepare() {

    local rom_p=${mfs_p}/teleweb/thor84gvzw

    local GET_VERSION_SRC_PATH=
    local GET_VERSION_TGT_PATH=

    if [[ ! -d tmp ]]; then
        mkdir -p tmp
    fi

    if [[ ! -d data ]]; then
        mkdir -p data
    fi

    if ${userdebug}; then
        GET_VERSION_SRC_PATH=originfiles/userdebug
        GET_VERSION_TGT_PATH=originfiles/userdebug
    else
        if [[ -n "${build_source_more}" ]]; then
            GET_VERSION_SRC_PATH=${build_source_more}
        fi

        if [[ -n "${build_target_more}" ]]; then
            GET_VERSION_TGT_PATH=${build_target_more}
        fi
    fi

    log debug "------------------- ${GET_VERSION_SRC_PATH} -------------------"
    if [[ -d ${rom_p}/appli/${build_source_version}/${GET_VERSION_SRC_PATH} ]]; then
        cp ${rom_p}/appli/${build_source_version}/${GET_VERSION_SRC_PATH}/*.mbn data/src
        backup_oem src
    elif [[ -d ${rom_p}/tmp/${build_source_version}/${GET_VERSION_SRC_PATH} ]]; then
        cp ${rom_p}/tmp/${build_source_version}/${GET_VERSION_SRC_PATH}/*.mbn data/src
        backup_oem src
    fi

    log debug "------------------- ${GET_VERSION_TGT_PATH} -------------------"
    if [[ -d ${rom_p}/appli/${build_target_version}/${GET_VERSION_TGT_PATH} ]]; then
        cp ${rom_p}/appli/${build_target_version}/${GET_VERSION_TGT_PATH}/*.mbn data/tgt -fv
        backup_oem tgt
    elif [[ -d ${rom_p}/tmp/${build_target_version}/${GET_VERSION_TGT_PATH} ]]; then
        cp ${rom_p}/tmp/${build_target_version}/${GET_VERSION_TGT_PATH}/*.mbn data/tgt -fv
        backup_oem tgt
    fi
}

function dowork() {

    declare -a scripts

    scripts[${#scripts[@]}]=prepare_pkg_source.sh
    scripts[${#scripts[@]}]=prepare_pkg_target.sh
    scripts[${#scripts[@]}]=gen_diff_pkg_releasekey.sh
    scripts[${#scripts[@]}]=gen_diff_pkg_testkey.sh
    scripts[${#scripts[@]}]=gen_diff_downgrade_pkg_releasekey.sh

    for script in ${scripts[@]};do
        if [[ -f ${script} && -x ${script} ]]; then
            log print "------ exec ${script}"
            ./${script}
        else
            log error "脚本文件不存在或者没有权限."
        fi
    done

    handle_xml
}

function handle_xml() {

    local xml=TCL_9048S_1.xml
    local remove_v_build_source_version=`echo ${build_source_version} | sed s/"[v|V]"//`
    local remove_v_build_target_version=`echo ${build_target_version} | sed s/"[v|V]"//`

    __green__ "remove_v_build_source_version = ${remove_v_build_source_version}"
    __green__ "remove_v_build_target_version = ${remove_v_build_target_version}"

    pushd data > /dev/null

    # 1. upgrade
    python File2Base64.py -b update_rkey.zip
    echo "" >>update_rkey.zip__base64

    if [[ -f ${xml} ]]; then
        git checkout -- ${xml}
        sed -i s/8.1.0/${remove_v_build_source_version}/g ${xml}
        sed -i s/8.2.3/${remove_v_build_target_version}/g ${xml}
        size=`ls -al update_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${xml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
    fi

    head -c -1 -q ${xml} update_rkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${build_source_version}_${build_target_version}_upgrade.xml

    # 2. downgrade <降级包>
    python File2Base64.py -b downgrade_rkey.zip
    echo "" >>downgrade_rkey.zip__base64

    if [[ -f ${xml} ]]; then
        git checkout -- ${xml}
        sed -i s/TCL_9048S_8.1.0_8.2.3/TCL_9048S_8.1.0_8.2.3_downgrade/g ${xml}
        sed -i s/8.1.0/${remove_v_build_target_version}/g ${xml}
        sed -i s/8.2.3/${remove_v_build_source_version}/g ${xml}
        size=`ls -al downgrade_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${xml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
    fi

    head -c -1 -q ${xml} downgrade_rkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${build_target_version}_${build_source_version}_downgrade.xml

    # 3. bad_integrity_9.19.3 <testkey>
    python File2Base64.py -b update_tkey.zip
    echo "" >>update_tkey.zip__base64

    if [[ -f ${xml} ]]; then
        git checkout -- ${xml}
        sed -i s/TCL_9048S_8.1.0_8.2.3/TCL_9048S_8.1.0_8.2.3_bad_integrity/g ${xml}
        sed -i s/8.1.0/${remove_v_build_source_version}/g ${xml}
        sed -i s/8.2.3/${remove_v_build_target_version}/g ${xml}
        size=`ls -al update_tkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${xml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
    fi

    head -c -1 -q ${xml} update_tkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${build_source_version}_${build_target_version}_bad_integrity_9.19.3.xml

    # 4. invalid_9.19.1 <error > 升级包中使用降级包
    if [[ -f ${xml} ]]; then
        git checkout -- ${xml}
        sed -i s/TCL_9048S_8.1.0_8.2.3/TCL_9048S_8.1.0_8.2.3_invalid/g ${xml}
        sed -i s/8.1.0/${remove_v_build_source_version}/g ${xml}
        sed -i s/8.2.3/${remove_v_build_target_version}/g ${xml}
        size=`ls -al downgrade_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${xml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
    fi

    head -c -1 -q ${xml} downgrade_rkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${build_source_version}_${build_target_version}_invalid_9.19.1.xml

    # 5. size_over_1.5G_9.19.4 升级包中添加了大文件fillfile
    if ${ADD_BIG_UPC}; then
        echo "-------------------make big upc-------------------------------"
        cp update_rkey.zip bigupdate.zip
        zip bigupdate.zip fillfile
        java -Xmx2048m -Djava.library.path=${tmpfs}/JrdDiffTool/lib64 -Dcom.tclcom.apksig.connect=localhost:50051,10.128.180.21:50051,10.128.180.117:50051,10.128.180.220:50051 -Dcom.tclcom.apksig.keysuite=thor84gvzw -jar ${tmpfs}/JrdDiffTool/framework/signapk.jar -providerClass com.tclcom.apksig.StubJCAProvider -w ${tmpfs}/JrdDiffTool/TCT_releasekeys/releasekey.x509.pem ${tmpfs}/JrdDiffTool/TCT_releasekeys/releasekey.pk8 ${tmpfs}/JrdDiffTool/data/bigupdate.zip ${tmpfs}/JrdDiffTool/data/bigupdate_rkey.zip
        python File2Base64.py -b bigupdate_rkey.zip
        echo "" >>bigupdate_rkey.zip__base64
        if [[ -f ${xml} ]]; then
            git checkout -- ${xml}
            sed -i s/TCL_9048S_8.1.0_8.2.3/TCL_9048S_8.1.0_8.2.3_size_over_1.5G/g ${xml}
            sed -i s/8.1.0/${remove_v_build_source_version}/g ${xml}
            sed -i s/8.2.3/${remove_v_build_target_version}/g ${xml}
            size=`ls -al bigupdate_rkey.zip | awk '{print $5}'`
            sed -i s/2862528/${size}/g ${xml}
            sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
        fi

        head -c -1 -q ${xml} bigupdate_rkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${build_source_version}_${build_target_version}_size_over_1.5G_9.19.4.xml
    else
        echo "------------------ADD_BIG_UPC = $ADD_BIG_UPC------------------"
    fi

    backup_fota

    popd > /dev/null
}

function backup_fota() {

    local ota_path=/mfs_tablet/teleweb/thor84gvzw/fota

    if ${userdebug}; then
        local prj_path=${build_source_version}_${build_target_version}_userdebug_fota_`date +"%Y-%m-%d_%H-%M-%S"`
    else
        local prj_path=${build_source_version}_${build_target_version}_fota_`date +"%Y-%m-%d_%H-%M-%S"`
    fi

    if [[ ! -d ${ota_path}/${prj_path} ]]; then
        sudo mkdir -p ${ota_path}/${prj_path}
    fi

    if [[ -f update_rkey.zip ]]; then
        sudo cp -vf update_rkey.zip ${ota_path}/${prj_path}
    fi

    if [[ -f downgrade_rkey.zip ]]; then
        sudo cp -vf downgrade_rkey.zip ${ota_path}/${prj_path}
    fi

    if [[ -f update_tkey.zip ]]; then
        sudo cp -vf update_tkey.zip ${ota_path}/${prj_path}
    fi

    if [[ -n "`ls TCL_9048S_${build_source_version}_${build_target_version}_*.xml`" ]]; then
        sudo cp -vf TCL_9048S_${build_source_version}_${build_target_version}_*.xml ${ota_path}/${prj_path}
        sudo cp -vf TCL_9048S_${build_target_version}_${build_source_version}_*.xml ${ota_path}/${prj_path}
    fi
}

function handle_vairable() {

    # 1. src version
    build_source_version=${ota_src_version:=}
    if [[ -z "`echo ${build_source_version} | sed -n '/^[v|V]/p'`" ]]; then
        build_source_version=v${build_source_version}
        if [[ -z ${build_source_version} ]]; then
            log error "The build_source_version is null, please check it."
        fi
    fi

    # 2. tgt version
    build_target_version=${ota_tgt_version:=}
    if [[ -z "`echo ${build_target_version} | sed -n '/^[v|V]/p'`" ]]; then
        build_target_version=v${build_target_version}

        if [[ -z ${build_target_version} ]]; then
            log error "The build_target_version is null, please check it."
        fi
    fi

    # 3. src more
    build_source_more=${ota_src_more:=}
    if [[ -z ${build_source_more} ]];then
        log error "The build_source_more is null, please check it."
    fi

    # 4. tgt more
    build_target_more=${ota_tgt_more:=}
    if [[ -z ${build_target_more} ]];then
        log error "The build_target_more is null, please check it."
    fi

    # 5. oem type
    build_oem_type=${oem_type:-TM}
    if [[ -z ${build_oem_type} ]];then
        log error "The build_oem_type is null, please check it."
    fi
}

function print_variable() {

    echo
    echo "JOBS = " ${JOBS}
    echo '-----------------------------------------'
    echo "build_source_version = " ${build_source_version}
    echo "build_target_version = " ${build_target_version}
    echo "build_oem_type       = " ${build_oem_type}
    echo '-----------------------------------------'
    echo
}

function init() {

    handle_vairable
    print_variable

    # 下载仓库
    git_sync_repository jrd/JrdDiffTool thor84g_vzw_1.0
}

function main() {

    mfs_p=/mfs_tablet

    init

    pushd ${tmpfs}/JrdDiffTool > /dev/null

    prepare
    dowork

    pushd > /dev/null
}

main "$@"
