#!/usr/bin/env bash

### 初始化环境变量
function source_init()
{
    local magcomm_project=magc6580_we_l
    local eastaeon_project=aeon6735_65c_s_l1
    local eastaeon_project_m=aeon6735m_65c_s_l1
    local eastaeon_project_m0=aeon6737t_66_m0
    local along_project=along8321_emmc_706m

    source  build/envsetup.sh

    show_vip "--> source end ..."

    case ${YUNOS_PROJECT_NAME} in
        6735m|aeon6735m_65c_s_l1)
            echo "choose 6735m"
            config_unsign
            lunch full_aeon6735m_65c_s_l1-${TARGET_BUILD_VARIANT}
        ;;

        6735|aeon6735_65c_s_l1)
            echo "choose 6735"
            lunch full_aeon6735_65c_s_l1-${TARGET_BUILD_VARIANT}
        ;;

        magc6580_we_l)
            echo "choose magc6580_we_l"
            lunch full_magc6580_we_l-${TARGET_BUILD_VARIANT}
        ;;

        aeon6737t_66_m0)
            echo "choose aeon6737t_66_m0"
            lunch full_aeon6737t_66_m0-${TARGET_BUILD_VARIANT}
        ;;

        *)
            __err "DON'T KNOW HOW TO MAKE !"
        ;;
    esac

    show_vip "--> lunch end ..."

    ROOT=$(gettop)
    OUT=${OUT}
    DEVICE_PROJECT=`get_build_var TARGET_DEVICE`

    if [[ ${DEVICE_PROJECT} == ${magcomm_project} ]];then
        DEVICE=device/magcomm/${DEVICE_PROJECT}
    elif [[ ${DEVICE_PROJECT} == ${eastaeon_project} || ${DEVICE_PROJECT} == ${eastaeon_project_m} || ${DEVICE_PROJECT} == ${eastaeon_project_m0} ]];then
        DEVICE=device/eastaeon/${DEVICE_PROJECT}
    elif [[ ${DEVICE_PROJECT} == ${along_project} ]];then
        DEVICE=device/along/${DEVICE_PROJECT}
    else
        __errr "DEVICE do not match it ."
        return 1
    fi
    print_env
}

function down_load_yunos_source_code()
{

    show_vig "@@@ manifest_branchN = $manifest_branchN"

    ## 当.repo存在，只需要去更新代码. 当发现不存在Makefile文件的时候，即可判断作为代码下载出错或意外中断处理.
    if [[ -d .repo ]];then
        update_yunos_source_code
    else
        download_yunos_source_code
    fi
}

## 更新阿里源码
function update_yunos_source_code()
{
    ## 当文件build/core/envsetup.mk和Makefile存在，说明下载完整,否则判断为意外中断会出错处理.直接去下载代码.
    if [[ -f build/core/envsetup.mk && -f Makefile ]]; then

        recover_standard_android_project

        if [[ `is_yunovo_server` == "true" ]];then

            repo init -b ${manifest_branchN}

            ## 更新源代码
            repo_sync_for_code
        fi

    else

        ## 下载中断处理,需要重新下载代码
        rm .repo/ -rf

        download_yunos_source_code
    fi
}

## 下载阿里源码
function download_yunos_source_code()
{
    local ssh_link="ssh://jenkins@gerrit.y:29419/manifest"

    if [[ "$ssh_link" && "$manifest_branchN" ]];then
        repo init -u ${ssh_link} -b ${manifest_branchN}
    fi

    ## 更新源代码
    repo_sync_for_code

    ## 第一次下载完成后，需要初始化环境变量
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        source_init
    else
        __err "The (.repo) not found!"
        return 1
    fi
}

function auto_create_manifest_for_yunos()
{
    local remotename=
    local username=`whoami`
    local datetime=`date +'%Y.%m.%d_%H.%M.%S'`
    local refsname=${build_prj_name}_${build_version}_${datetime}

    local manifest_path=.repo/manifests
    local manifest_default=default.xml
    local manifest_name=tmp.xml

    _echo "manifest_branchN = $manifest_branchN"

    if [[ "`is_yunos_project`" == "true" ]];then

        ## create tmp.xml
        repo manifest -r -o ${manifest_path}/${manifest_name}

        cd ${manifest_path} > /dev/null

        remotename=`git remote`

        if [[ -f ${manifest_name} ]];then
            mv ${manifest_name} ${manifest_default}
            if [[ "`git status -s`" ]];then
                git add ${manifest_default}
                git commit -m "add manifest for $refsname"
                git push ${remotename} HEAD:refs/build/${username}/${refsname}
            else
                __err "$manifest_default is not change ."
                exit 1
            fi
        else
            __err "$manifest_name is not exist ."
            exit 1
        fi

        cd - > /dev/null

        repo init -b ${manifest_branchN}
    else
        log error "The current directory is not android !"
    fi
}

## 复制版本到阿里版本下 ~/yunos
function copy_image_to_folder()
{
    local firmware_path=${version_p}
    local server_name=`hostname`
    local default_version_name=release-${build_device}
    local BASE_PATH=${firmware_path}/${project_name}/${project_name}_${custom_version}/${build_version}

    if [[ ! -d ${BASE_PATH} ]];then
        mkdir -p ${BASE_PATH}
    fi

    if [[ -d ${default_version_name} ]];then
        mv ${default_version_name}/* ${BASE_PATH}
    fi

    if [[ "`ls ${OUT}/full_${build_device}||ta*.zip`" ]];then
        cp -vf ${OUT}/full_${build_device}-ota*.zip ${BASE_PATH}/../${build_version}_sdupdate.zip
        show_vip "--> copy sdupdate.zip sucessful ..."
    else
        __err "full_${build_device}-ota-xxx.zip don't exist ..."
    fi
}

## 同步阿里版本到f1服务器上
function rsync_version_to_f1_server()
{
    local serverN=f1.y
    local userN="`git config --get user.name`"
    local jenkins_server="${userN}@${serverN}"

    local firmware_path=${version_p}
    local share_path=/share/ROM/share_yunos

    if [[ -d ${firmware_path} ]];then
        rsync -av ${firmware_path}/ ${jenkins_server}:${share_path}/yunos
    fi

    if [[ -d ${firmware_path}  ]];then
        rm ${firmware_path}/* -rf
    else
        __err "$firmware_path not found !"
    fi

    show_vip "--> sync end ..."
}

function make_yunos_android()
{
    if [[ "$DEVICE" ]];then
        :
    else
        if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
            source_init
        else
            __err "The (.repo) not found ! please download android source code !"
            return 1
        fi
    fi

    if [[ "$build_clean" == "true" ]];then
        make clean
        show_vip "--> make clean end."
    else
        make installclean
        show_vip "--> make installclean end."
    fi

    echo "$YUNOS_PROJECT_NAME" > out/projectName.txt
    echo "$TARGET_BUILD_VARIANT" > out/options.txt
    echo "MTK_BASE_PROJECT $MTK_BASE_PROJECT"

    echo "CPU CORES = $JOBS"
    echo "DEFAULT_CONFIG_FILE $DEFAULT_CONFIG_FILE"
    echo "BASE $BASE"
    echo

    if [[ "$build_update_api" == "true" ]];then
        make update-api -j${JOBS}
    else
        __wrn "This time you don't exec make update-api."
    fi

    if [[ "$build_make_ota" == "true" ]];then

        if make otapackage ${compile_para[@]} -j${JOBS} -k ${moreArgs};then
            show_vip "--> make project successful ..."
        else
            __err "--> make project fail ..."
            return 1
        fi

    else

        if make ${compile_para[@]} -j${JOBS} -k ${moreArgs};then
            show_vip "--> make project successful ..."
        else
            __err " make project fail ..."
            return 1
        fi

    fi

    auto_create_manifest_for_yunos

    if [[ -f imgout && -x imgout ]];then
        if [[ "`is_mt6737t_project`" == "true"  ]];then
            ~/workspace/script/zzzzz-script/tools/imgout4mt6737t
        else
            ~/workspace/script/zzzzz-script/tools/imgout
        fi

    fi

    if copy_image_to_folder;then
        rsync_version_to_f1_server
    fi
}


