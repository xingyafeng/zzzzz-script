#!/usr/bin/env bash

function update_base_version() {

    local char=${1:-}
    local baseversion=TCL_9048S_8.1.0_8.2.3

    if [[ -z ${char} ]]; then
        log error "The ${char} is null ..."
    fi

    sed -i s/${baseversion}/${baseversion}_${char}/g ${prexml}
}

function update_from_version() {

    local version=${1:-}
    local from_version=8.1.0

    if [[ -z ${version} ]]; then
        log error "The ${version} is null ..."
    fi

    sed -i s/${from_version}/${version}/g ${prexml}
}

function update_to_version() {

    local version=${1:-}
    local to_version=8.2.3

    if [[ -z ${version} ]]; then
        log error "The ${version} is null ..."
    fi

    sed -i s/${to_version}/${version}/g ${prexml}
}

function update_size() {

    local file=${1:-}
    local size=2862528

    if [[ -z ${file} || ! -f ${file} ]]; then
        log error "The ${file} is null ..."
    fi

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

# ----------------------------------------------------------------------------------------------diff

function update_predownload_message() {

    local src='<PreDownloadMessage>Android 8.2.3 is now ready to download and install.'
    local tgt=''

    case ${build_eux_texts} in
        Security_Update_Only)
            tgt='<PreDownloadMessage>&lt;p&gt;&lt;img src=&quot;https://cdn2.vzwdm.com/images/1040x500_SecurityUpdate.jpg&quot; /&gt;&lt;/p &gt; &lt;p&gt;&lt;b&gt;System Update X&lt;/b&gt;&lt;/p &gt; &lt;p&gt;This system update improves the security of your 9048S.&lt;/p &gt;'
            ;;
        Security_Update_and_Bug_Fixes_or_Enhancement)
            tgt='<PreDownloadMessage>&lt;p&gt;&lt;img src=&quot;https://cdn2.vzwdm.com/images/1040x500_SecurityUpdates_and_Improvements.jpg&quot; /&gt;&lt;/p &gt; &lt;p&gt;&lt;b&gt;System Update X&lt;/b&gt;&lt;/p &gt; &lt;p&gt;This system update improves the security of your 9048S and includes other enhancements.&lt;/p &gt;'
            ;;
    esac

    if [[ -n ${tgt} ]]; then
        sed -i s/${src}/${tgt}/g ${prexml}
        update_device_name
    else
        log warn 'The tgt content is empty.'
    fi
}

function update_postdownload_message() {

    local src='<PostDownloadMessage>Android 8.2.3 is now ready to download and install.'
    local tgt=''

    case ${build_eux_texts} in
        Security_Update_Only)
            tgt='<PostDownloadMessage>&lt;p&gt;&lt;img src=&quot;https://cdn2.vzwdm.com/images/1040x500_SecurityUpdate.jpg&quot; /&gt;&lt;/p &gt; &lt;p&gt;&lt;b&gt;System Update X&lt;/b&gt;&lt;/p &gt; &lt;p&gt;This update will restart your 9048S. During the update you won’t be able to make or receive 911 calls for 10 minutes.&lt;/p &gt;'
        ;;

        Security_Update_and_Bug_Fixes_or_Enhancement)
            tgt='<PostDownloadMessage>&lt;p&gt;&lt;img src=&quot;https://cdn2.vzwdm.com/images/1040x500_SecurityUpdates_and_Improvements.jpg&quot; /&gt;&lt;/p &gt; &lt;p&gt;&lt;b&gt;System Update X&lt;/b&gt;&lt;/p &gt; &lt;p&gt;This update will restart your 9048S. During the update you won’t be able to make or receive 911 calls for 10 minutes.&lt;/p &gt;'
        ;;
    esac

    if [[ -n ${tgt} ]]; then
        sed -i s/${src}/${tgt}/g ${prexml}

        # updte time
        sed -i "s#10 minutes#${build_update_time} minutes#" ${prexml}

        update_device_name
    else
        log warn 'The tgt content is empty.'
    fi
}

function update_postupdate_message() {

    local src='System updated'
    local tgt='&lt;p&gt;&lt;img src=&quot;https://cdn2.vzwdm.com/images/1040x500_YouAreAllSet.jpg&quot; /&gt;&lt;/p &gt; &lt;p&gt;&lt;b&gt;System Update X&lt;/b&gt;&lt;/p &gt;'

    if [[ -n ${tgt} ]]; then
        sed -i s/${src}/${tgt}/g ${prexml}
    else
        log warn 'The tgt content is empty.'
    fi
}

# 初始化备份的文件名
function init_copy_fota() {

    copyfs=()

    copyfs[${#copyfs[@]}]=update_rkey.zip
    copyfs[${#copyfs[@]}]=update_tkey.zip
    copyfs[${#copyfs[@]}]=downgrade_rkey.zip

    for fs in $(ls TCL_${device_name}_${build_from_version}_${build_to_version}_*.xml) ; do
        copyfs[${#copyfs[@]}]=${fs}
    done

    for fs in $(ls TCL_${device_name}_${build_to_version}_${build_from_version}_*.xml) ; do
        copyfs[${#copyfs[@]}]=${fs}
    done
}

# 备份FOTA版本
function copy_fota_version() {

    local userdebug=false
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

function get_device_name() {

    case ${build_project} in

        thor84gvzw)

            if [[ -n ${from_more} && -n ${to_more} ]]; then

                # 保证选择的版本一致性
                if [[ ${from_more} != ${to_more} ]]; then
                    log error "project don't matchup ..."
                fi

                case ${from_more} in

                    KIDS)
                        device_name='9049L'
                        ;;

                    *)
                        device_name='9048S'
                        ;;
                esac
            fi
        ;;

        transformervzw)
            device_name='9198S'
        ;;

        *)
            log error "The build_project has no found ..."
        ;;
    esac
}

function get_custom_flag() {

    local image=${1:-}

    if [[ -n ${image} ]]; then
        cat P* | egrep -w ${image} | sed 's%.*rename_prefix="%%'| sed 's%".*%%' | head -1
    fi
}

# 配置项目是否需要使用testkey签名
function set_testkey() {

    case ${build_type} in

        daily_version)
            is_testkey='yes'
        ;;

        *)
            is_testkey=''
        ;;
    esac
}