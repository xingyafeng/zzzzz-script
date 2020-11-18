#!/usr/bin/env bash

# 编译moden模块
function build_moden() {

    # 记录变量WORKSPACE
    tmpworkspace=${WORKSPACE}

    pushd ${project_path} > /dev/null

    if [[ -f linux_build.sh ]]; then
        unset WORKSPACE && bash linux_build.sh -a delhitf tf
    else
        log error "The linux_build.sh has no found ..."
    fi

    popd > /dev/null

    export WORKSPACE=${tmpworkspace}
}

# 编译kernel
function build_kernel() {

    make -j${JOBS} kernel
}

# 编译特殊模块
function make_android_for_case() {

    if [[ -n "${build_case[@]}" ]]; then

        __green__ "[tct]: build case = ${build_case[@]}"

        for bcase in ${build_case[@]} ; do

            case ${bcase} in
                'exclude')
                    Command ${bcase}
                    if [[ $? -eq 0 ]]; then
                        if [[ ${#change_number_list[@]} -eq 1 ]]; then
                            verify_patchset_submit 0
                        fi
                    else
                        if [[ ${#change_number_list[@]} -eq 1 ]]; then
                            verify_patchset_submit 1
                        fi
                    fi

                    return 0
                ;;

                *)
                    Command ${bcase}
                    if [[ $? -eq 0 ]]; then
                        if [[ ${#change_number_list[@]} -eq 1 ]]; then
                            verify_patchset_submit 0
                        fi
                    else
                        if [[ ${#change_number_list[@]} -eq 1 ]]; then
                            verify_patchset_submit 1
                        fi
                    fi
                ;;
            esac
        done
    fi
}

# mma/mmma 单编译模式
function make_android_for_single() {

    for bp in ${build_path[@]} ; do
        if [[ -n ${module_target[${bp}]} ]]; then
            build_module_list[${#build_module_list[@]}]=${module_target[${bp}]}

            # 解决无效目标导致的编译失败
            case ${bp} in
                vendor/qcom/proprietary/sensors-see/sensors-hal-2.0)
                    module_filter
                ;;
            esac
        fi
    done

    if [[ ${#build_module_list[@]} -ne 0 ]];then
        show_vip "[tct]: mma -j${JOBS} ${build_module_list[@]}"
        if ${build_debug};then
            mma -j${JOBS} ${build_module_list[@]}
            if [[ ${PIPESTATUS[0]} -eq 0 ]] ; then
                verify_patchset_submit 0
            else
                verify_patchset_submit 1
                log error "mma -j${JOBS} ${build_module_list[@]} failed ..."
            fi
        fi
    fi
}

# 增量编译
function make_android_for_whole() {

    export WITHOUT_CHECK_API=false

    if ${build_debug};then
        if [[ "${TARGET_PRODUCT}" == "qssi" ]]; then
            Command "bash build.sh --qssi_only -j${JOBS}"
        else
            Command "bash build.sh --target_only -j${JOBS}"
        fi

        if [[ $? -eq 0 ]] ; then
            verify_patchset_submit 0
        else
            verify_patchset_submit 1
        fi
    fi
}