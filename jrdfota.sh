#!/usr/bin/env bash

# if error;then exit
set -e

mfs_p=/mfs_tablet

source_version=${src_version}
target_version=${tgt_version}
oem_type=${oem_type}

function download() {

    if [[ ! -d ${tmpfs}/JrdDiffTool/.git ]];then
        git clone -b thor84g_vzw_1.0 git@shenzhen.gitweb.com:jrd/JrdDiffTool.git ${tmpfs}/JrdDiffTool
    else
        cd ${tmpfs}/JrdDiffTool > /dev/null
        git clean -dxf
        cd - > /dev/null
    fi
}

function backup_oem() {

    local dir=$1
    local TM=

    cd data/${dir}/ > /dev/null

    for mbn in "`ls O*M0.mbn`" ; do
        TM=`ls O*${oem_type}*M0.mbn`

        mkdir -p tmp/oem
        mv -vf ${mbn} tmp/oem
        mv tmp/oem/${TM} .
    done

    for mbn in "`ls V*80.mbn`" ; do
        TM=`ls V*${oem_type}*80.mbn`

        mkdir -p tmp/oem
        mv -vf ${mbn} tmp/oem
        mv tmp/oem/${TM} .
    done

    cd - > /dev/null
}

function prepare() {

    local rom_p=${mfs_p}/teleweb/thor84gvzw

    if [[ ! -d tmp ]]; then
        mkdir -p tmp
    fi

    if [[ ! -d data ]]; then
        mkdir -p data
    fi

    if [[ -f ${rom_p}/appli/${source_version}/${source_version}.zip ]]; then
        unzip ${rom_p}/appli/${source_version}/${source_version}.zip -d data/src/
        backup_oem src
    elif [[ -f ${rom_p}/tmp/${source_version}/${source_version}.zip ]]; then
        unzip ${rom_p}/tmp/${source_version}/${source_version}.zip -d data/src/
        backup_oem src
    fi

    if [[ -f ${rom_p}/appli/${target_version}/${target_version}.zip ]]; then
        unzip ${rom_p}/appli/${target_version}/${target_version}.zip -d data/tgt/
        backup_oem tgt
    elif [[ -f ${rom_p}/tmp/${target_version}/${target_version}.zip ]]; then
        unzip ${rom_p}/tmp/${target_version}/${target_version}.zip -d data/tgt/
        backup_oem tgt
    fi

    if [[ -f "`ls ${rom_p}/appli/${source_version}/7*.mbn`" ]]; then
        cp -vf ${rom_p}/appli/${source_version}/7*.mbn data/src/
    elif [[ -f "`ls ${rom_p}/tmp/${source_version}/7*.mbn`" ]]; then
        cp -vf ${rom_p}/tmp/${source_version}/7*.mbn data/src/
    fi

    if [[ -f "`ls ${rom_p}/appli/${target_version}/7*.mbn`" ]]; then
        cp -vf ${rom_p}/appli/${target_version}/7*.mbn data/tgt/
    elif [[ -f "`ls ${rom_p}/tmp/${target_version}/7*.mbn`" ]]; then
        cp -vf ${rom_p}/tmp/${target_version}/7*.mbn data/tgt/
    fi
}

function exec_sh() {

    local sh

    case "$#" in

        1)
            sh="$1"
            ;;
        *)
            echo "The ${FUNCNAME[0]} function must be hava two args ..."
        ;;
    esac

    if [[ -f ${sh} && -x ${sh} ]]; then
        echo "-----exec ${sh}"
        ./${sh}
    else
        echo "文件不存在或者没有权限.."
    fi
}

function dowork() {

    declare -a script_fs

    script_fs[${#script_fs[@]}]=prepare_pkg_source.sh
    script_fs[${#script_fs[@]}]=prepare_pkg_target.sh
    script_fs[${#script_fs[@]}]=gen_diff_pkg_releasekey.sh
    script_fs[${#script_fs[@]}]=gen_diff_pkg_testkey.sh
    script_fs[${#script_fs[@]}]=gen_diff_downgrade_pkg_releasekey.sh

    for s in ${script_fs[@]};do
        exec_sh ${s}
    done
}

function handle_xml() {

    local xml=TCL_9048S_1.xml
    local remove_v_source_version=`echo ${source_version} | sed s/"[v|V]"//`
    local remove_v_target_version=`echo ${target_version} | sed s/"[v|V]"//`

    echo "remove_v_source_version = ${remove_v_source_version}"
    echo "remove_v_target_version = ${remove_v_target_version}"
    cd data > /dev/null

    # 1. upgrade
    python File2Base64.py -b update_rkey.zip
    echo "" >>update_rkey.zip__base64

    if [[ -f ${xml} ]]; then
        git checkout -- ${xml}
        sed -i s/8.1.0/${remove_v_source_version}/g ${xml}
        sed -i s/8.2.3/${remove_v_target_version}/g ${xml}
        size=`ls -al update_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${xml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
    fi

    head -c -1 -q ${xml} update_rkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${source_version}_${target_version}_upgrade.xml

    # 2. downgrade <降级包>
    python File2Base64.py -b downgrade_rkey.zip
    echo "" >>downgrade_rkey.zip__base64

    if [[ -f ${xml} ]]; then
        git checkout -- ${xml}
        sed -i s/8.1.0/${remove_v_target_version}/g ${xml}
        sed -i s/8.2.3/${remove_v_source_version}/g ${xml}
        size=`ls -al downgrade_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${xml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
    fi

    head -c -1 -q ${xml} downgrade_rkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${target_version}_${source_version}_downgrade.xml

    # 3. bad_integrity_9.19.3 <testkey>
    python File2Base64.py -b update_tkey.zip
    echo "" >>update_tkey.zip__base64

    if [[ -f ${xml} ]]; then
        git checkout -- ${xml}
        sed -i s/8.1.0/${remove_v_source_version}/g ${xml}
        sed -i s/8.2.3/${remove_v_target_version}/g ${xml}
        size=`ls -al update_tkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${xml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
    fi

    head -c -1 -q ${xml} update_tkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${source_version}_${target_version}_bad_integrity_9.19.3.xml

    # 4. invalid_9.19.1 <error > 升级包中使用降级包
    if [[ -f ${xml} ]]; then
        git checkout -- ${xml}
        sed -i s/8.1.0/${remove_v_source_version}/g ${xml}
        sed -i s/8.2.3/${remove_v_target_version}/g ${xml}
        size=`ls -al downgrade_rkey.zip | awk '{print $5}'`
        sed -i s/2862528/${size}/g ${xml}
        sed -i s/2018-05-23/`date +"%Y-%m-%d"`/g ${xml}
    fi

    head -c -1 -q ${xml} downgrade_rkey.zip__base64 TCL_9048S_2.xml > TCL_9048S_${source_version}_${target_version}_invalid_9.19.1.xml

    backup_fota_file

    cd - > /dev/null
}

function backup_fota_file() {

    local ota_path=/mfs_tablet/teleweb/thor84gvzw/fota
    local prj_path=${source_version}_${target_version}_fota_`date +"%Y-%m-%d_%H-%M-%S"`

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

    if [[ -n "`ls TCL_9048S_${source_version}_${target_version}_*.xml`" ]]; then
        sudo cp -vf TCL_9048S_${source_version}_${target_version}_*.xml ${ota_path}/${prj_path}
        sudo cp -vf TCL_9048S_${target_version}_${source_version}_*.xml ${ota_path}/${prj_path}
    fi
}

function main() {

    local tmpfs=~/.tmpfs/
    local OLDP=`pwd`

    if [[ -d ${tmpfs} ]]; then
        mkdir -p ${tmpfs}
    fi

    if [[ -z "`echo ${source_version} | sed -n '/^[v|V]/p'`" ]]; then
        source_version=v${source_version}
    fi

    if [[ -z "`echo ${target_version} | sed -n '/^[v|V]/p'`" ]]; then
        target_version=v${target_version}
    fi

    echo "source_version = ${source_version}"
    echo "target_version = ${target_version}"
    echo "oem_type       = ${oem_type} "

    if [[ -z ${source_version} ]]; then
        echo "source_version is null ..."
        return 1
    fi

    if [[ -z ${target_version} ]] ; then
        echo "target_version is null ..."
        return 1
    fi

    download

    cd ${tmpfs}/JrdDiffTool > /dev/null

    prepare
    dowork
    handle_xml

    cd ${OLDP} > /dev/null
}

main "$@"
