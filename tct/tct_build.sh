#!/usr/bin/env bash

# 需要整编译的工程
function is_full_build_project() {

    case ${bp} in
        device/qcom/*|device/sample/*|device/google/*|device/linaro/*)
            is_full_build=true
            break;
        ;;

        build/soong/*|build/make/*)
            is_full_build=true
            break;
        ;;

        vendor/tct/frameworks/base/services)
            is_full_build=true
            break;
        ;;
    esac

    if [[ ${is_full_build} == "true" ]]; then
        export TARGET_PRODUCT=qssi
    fi
}

# 编译moden模块
function build_moden() {

    # 记录变量WORKSPACE
    local tmpworkspace=${WORKSPACE}
    local tmpath=

    # 查询提交文件
    listfs=(`git --git-dir=${project_path}/.git log --name-only --pretty=format: ${GERRIT_PATCHSET_REVISION} -1 | grep -v "^$" | sort -u`)
    for fs in ${listfs[@]} ; do
        tmpath=$(gotdir ${fs})
        if [[ -n ${tmpath} ]]; then
            case ${tmpath} in
                BOOT.XF.4.1) # 过滤错误选项
                    build_modem[${#build_modem[@]}]="unset WORKSPACE && bash linux_build.sh -b delhitf tf"
                ;;

                MPSS.HA.1.0)
                    build_modem[${#build_modem[@]}]="unset WORKSPACE && bash linux_build.sh -m delhitf tf"
                ;;

                RPM.BF.1.10)
                    build_modem[${#build_modem[@]}]="unset WORKSPACE && bash linux_build.sh -r delhitf tf"
                ;;

                ADSP.VT.5.4.1)
                    build_modem[${#build_modem[@]}]="unset WORKSPACE && bash linux_build.sh -d delhitf tf"
                ;;

                CDSP.VT.2.4.1)
                    build_modem[${#build_modem[@]}]="unset WORKSPACE && bash linux_build.sh -s delhitf tf"
                ;;

                TZ.XF.5.1)
                    build_modem[${#build_modem[@]}]="unset WORKSPACE && bash linux_build.sh -t delhitf tf"
                ;;

                *)
                    build_modem[${#build_modem[@]}]="unset WORKSPACE && bash linux_build.sh -a delhitf tf"
                ;;
            esac
        fi
    done

    if [[ -n ${build_modem[@]} ]]; then

        # 去重
        build_modem=($(awk -vRS=' ' '!a[$1]++' <<< ${build_modem[@]}))
        show_vir "[tct]: build modem = ${build_modem[@]}"

        pushd ${project_path} > /dev/null

        if [[ -f linux_build.sh ]]; then
            Command ${build_modem[@]}
        else
            log error "The linux_build.sh has no found ..."
        fi

        popd > /dev/null
    fi

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
        show_vir "[tct]: mma -j${JOBS} ${build_module_list[@]}"
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