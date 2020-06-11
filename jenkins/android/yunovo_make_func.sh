#!/usr/bin/env bash

function get_repo_reference_info()
{
    if [[ -n "`get_cpu_type`" ]];then
        echo
        __green__ "----  mirror  ----"
        git --git-dir=${manifest_git_p} config --get repo.reference
        __green__ "----  mirror  ----"
        echo
    fi
}

function init_download_proejct_name()
{
    if [[ "$prj_name" ]];then

        case ${prj_name} in
            k86a | k86m)
                defalut=k86A
                ;;

            k86s | k86sm)
                defalut=k86s
                ;;

            k86l | k86ld)
                defalut=k86s_400x1280
                ;;

            k86ls | k86lsd)
                defalut=k86l_split
                ;;

            k86mx2)
                defalut=k86_mx2
                ;;

            k88c)
                defalut=k88
                ;;

            k88c_21)
                defalut=k88_v2.1
                ;;

            k88s)
                defalut=k88_split
                ;;

            k26)
                defalut=K26
                ;;

            k26s)
                defalut=k26_split
                ;;

            *)
                if [[ "`is_main_branch`" == "true" || "`is_car_project`" == "true" ]];then
                    :
                else
                    show_vig "@@@ prj_name = $prj_name"
                fi

                ;;
        esac

    else
        log error "The project name has not found ."
    fi
}

## 自动下载更新云智源代码
function auto_download_yunovo_source_code()
{
    local prj_name=`get_project_real_name`
    local defalut=

    local reference_p=""
    local mirror_p=~/jobs/mirror
    local manifest_git_p=.repo/manifests/.git

    if [[ -n "`get_cpu_type`"  ]];then
        reference_p=${mirror_p}/`get_cpu_type`
    else
         __err " reference is NULL ..."
    fi

    show_vig "@@@ reference_p = $reference_p"

    init_download_proejct_name

    if [[ -n "$defalut" ]];then
        show_vig "defalut = $defalut"
    fi

    if [[ -n "$manifest_branchN" ]];then
        show_vig "manifest_branchN = $manifest_branchN"
    fi

    if [[ -d .repo ]];then
        auto_update_sdk
    else
        auto_download_source_code
    fi
}

## 自动更新源代码
function auto_update_sdk()
{
    if [[ -f build/core/envsetup.mk && -f Makefile ]]; then

        recover_standard_android_project

        if [[ `is_yunovo_server` == "true"  ]];then

            if [[ -n "$defalut" ]];then
                repo init -m ${defalut}.xml --reference=${reference_p}
            fi

            if [[ -n "$manifest_branchN" ]];then
                repo init -b ${manifest_branchN} --reference=${reference_p}
            fi

            ## 获取 reference info
            get_repo_reference_info

            ## 更新源代码
            repo_sync_for_code
        fi
    else

        ##下载中断处理,需要重新下载代码
        rm .repo/ -rf

        ##自动下载源代码
        auto_download_source_code
    fi
}

## 自动下载源代码
function auto_download_source_code()
{
    local ssh_link="ssh://jenkins@gerrit.y:29419/manifest"

    if [[ "$defalut" ]];then
        repo init -u ${ssh_link} -m ${defalut}.xml --reference=${reference_p}
    fi

    if [[ "$manifest_branchN" ]];then
        repo init -u ${ssh_link} -b ${manifest_branchN} --reference=${reference_p}
    fi

    ## 获取 reference info
    get_repo_reference_info

    ## 更新源代码
    repo_sync_for_code

    echo
    ls -alF

    ## 第一次下载完成后，需要初始化环境变量
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        source_init
    else
        log error "The (.repo) has not found!"
    fi
}

## 编译系统源代码
function make_yunovo_android()
{
    if [[ -n "$(find . -maxdepth 1 -name "build*.log" -print0)" ]];then
		delete_log
    else
        __wrn "Log removed ... "
	fi

if ${build_debug};then
    if [[ "$build_clean" == "true" ]];then

        if make clean;then
            echo
            show_vip "--> make clean end ..."
        else
            log error "--> make clean failed ..."
        fi
    else
        if make installclean;then
            echo
            show_vip "--> make installclean end ..."
        else
            log error "--> make installclean failed ..."
        fi
    fi

    if [[ "$build_update_api" == "true" ]];then

        if make update-api -j${JOBS};then
            echo
            show_vip "--> make update-api end !"
        else
            log error "make update-api failed ... "
        fi
    else
        __wrn "This time you don't execution make update-api."
    fi

    if [[ "$JOBS" -gt 0 ]];then
        :
    else
        log error "The jos is error ..."
    fi

    if make -j${JOBS} ${compile_para[@]};then
        echo
        show_vip "--> make project end ..."

        if [[ "$build_make_ota" == "false" ]];then
            send_email_to_admin
        fi
    else
        log error "Make android project has failed !"
    fi

    if [[ "$build_make_ota" == "true" ]];then
        if make -j${JOBS} ${compile_para[@]} otapackage;then
            echo
            show_vip "--> make otapackage end ..."

            if [[ "$build_make_ota" == "false" ]];then
                send_email_to_admin
            fi
        else
            log error "make otapackage failed ..."
        fi
    else
        show_vig "@@@ build_make_ota = $build_make_ota"
    fi

    if [[ "`is_car_project`" == "true" ]];then
        auto_create_manifest
    else

        if [[ "`is_main_branch`" == "true" ]];then
            auto_create_manifest
        fi

        create_refs_branch
    fi
fi
    if [[ "`is_car_project`" == "true" ]];then
        :
    else
        print_system_app
    fi

    # 备份版本
    copy_image_version

    # 同步版本
    rsync_image_upload_server
}

### 自动更新客制化
function auto_update_yunovo_customs()
{
	local nowPwd=$(pwd)

    local custom=""
    local base_path=~/jobs
    local username=`git config --get user.name`

    case `get_project_real_name` in
       k21)
           custom=k21
            ;;

       k26)
           custom=k26
            ;;

        k26s | k26sd)
           custom=k26s
            ;;

        k27)
           custom=k27
            ;;

        k86a)
           custom=k86a
            ;;

        k86m)
           custom=k86m
            ;;

        k86s)
           custom=k86s
            ;;

        k86sm)
           custom=k86sm
            ;;

        k86l | k86ld)
           custom=k86l
            ;;

        k86ls | k86lsd)
           custom=k86ls
            ;;

        k88c)
           custom=k88c
            ;;

        k88s)
           custom=k86s
            ;;

        *)
            log error "The no custom paths : $yunovo_path "
            ;;
    esac

    local yunovo_path=${base_path}/${custom}
    local yunovo_customs_path=${yunovo_path}/yunovo_customs
    local yunovo_customs_link_server=`echo ssh://${username}@gerrit.y:29419/xyf/${custom}/yunovo_customs`

    if false;then
    _echo "@@ yunovo_path = $yunovo_path"
    _echo "## yunovo_customs_path = $yunovo_customs_path"
    _echo "@@ yunovo_customs_link_server = $yunovo_customs_link_server"
    fi

    if [[ -d ${yunovo_customs_path}/.git ]];then

        cd ${yunovo_customs_path} > /dev/null

        git pull
        show_vip "-------- $custom yunovo_customs update successful ..."

        echo

        cd - > /dev/null
    else
        if [[ ! -d ${yunovo_path} ]];then
            mkdir -p ${yunovo_path}
        fi

        cd ${yunovo_path} > /dev/null

        if [[ -n "$yunovo_customs_link_server" ]];then

            show_vig "@@@ custom link = $yunovo_customs_link_server"

            git clone -b master ${yunovo_customs_link_server}
            echo
        else
            log error "$yunovo_customs_link_server not found !"
        fi

        cd - > /dev/null
    fi

    cd ${nowPwd}
}
