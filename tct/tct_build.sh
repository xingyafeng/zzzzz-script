#!/usr/bin/env bash

# 需要整编译的工程
function is_full_build_project() {

    case ${project_path} in
        device/qcom/*|device/mediatek/*|device/mediateksample/*|device/sample/*|device/google/*|device/linaro/*)
            echo true
        ;;

        build/soong/*|build/make/*)
            echo true
        ;;

        *)
            for bp in ${build_path[@]} ; do
                case ${bp} in
                    vendor/tct/frameworks/base/services|vendor/qcom/proprietary/prebuilt_HY11/target/product/qssi)
                        echo true
                        break;
                    ;;
                esac
            done
        ;;
    esac
}

# 修正错误的模块名
function fix_incorrect_module() {

    tmp=()
    for bm in ${build_module_list[@]} ; do
        case ${bm} in
            lights.msmnile)
                tmp=${build_module_list[@]//${bm}/lights.bengal}
                unset build_module_list && build_module_list=${tmp[@]}
                ;;
        esac
    done
}

# 设置无效的目标
function set_invalid_module() {

    invalid_module[${#invalid_module[@]}]=sensors_list
    invalid_module[${#invalid_module[@]}]=audio.primary.msmnile
    invalid_module[${#invalid_module[@]}]=msmnile_
    invalid_module[${#invalid_module[@]}]=libandroid_runtime
    invalid_module[${#invalid_module[@]}]=vendor_common_inc.cfi
    invalid_module[${#invalid_module[@]}]=vendor_common_inc.cfi.vendor
}

# 过滤无效目标
function module_filter() {

    for bml in ${build_module_list[@]} ; do
        for im in ${invalid_module[@]} ; do
            if [[ "${bml}" == "${im}" ]]; then
                build_module_list=(${build_module_list[@]/$im})
            else
                if [[ "${bml}" =~ "${im}" ]]; then
                    build_module_list=(${build_module_list[@]/$bml})
                fi
            fi
        done
    done
}

# 编译boot
function make_boot() {

    Command bash linux_build.sh -b ${build_project} ${build_modem_type}
}

# 编译modem
function make_modem() {

    Command bash linux_build.sh -m ${build_project} ${build_modem_type}
}

# 编译rpm
function make_rpm() {

    Command bash linux_build.sh -r ${build_project} ${build_modem_type}
}

# # 编译adsp
function make_adsp() {

    Command bash linux_build.sh -d ${build_project} ${build_modem_type}
}

# 编译cdsp
function make_cdsp() {

    Command bash linux_build.sh -s ${build_project} ${build_modem_type}
}

# 编译tz
function make_tz() {

    Command bash linux_build.sh -t ${build_project} ${build_modem_type}
}

# 编译all
function make_all() {

    Command bash linux_build.sh -a ${build_project} ${build_modem_type}
}

# 编译moden模块
function build_moden() {

    # 记录变量WORKSPACE
    local tmpworkspace=${WORKSPACE}
    local project_path=
    local tmpath=

    while IFS="@" read -r GERRIT_CHANGE_URL GERRIT_PROJECT GERRIT_REFSPEC GERRIT_PATCHSET_NUMBER GERRIT_PATCHSET_REVISION GERRIT_CHANGE_NUMBER GERRIT_BRANCH _;do
        project_path=$(get_project_path)
        case ${project_path} in
            amss_4250_spf1.0|amss_4350_spf1.0|amss_nicobar_la2.0.1)
                # 查询提交文件
                listfs=(`git --git-dir=${project_path}/.git log --name-only --pretty=format: ${GERRIT_PATCHSET_REVISION} -1 | grep -v "^$" | sort -u`)
                for fs in ${listfs[@]} ; do
                    tmpath=$(gotdir ${fs})
                    #__blue__ "[tct]: fs = ${fs}"
                    #__blue__ "[tct]:  tmpath　= ${tmpath}"
                    if [[ -n ${tmpath} ]]; then
                        case ${tmpath} in
                            BOOT.XF.4.1|boot_images) # 过滤错误选项
                                build_modem[${#build_modem[@]}]=make_boot
                            ;;

                            MPSS.HA.1.0|modem_proc)
                                build_modem[${#build_modem[@]}]=make_modem
                            ;;

                            RPM.BF.1.10|rpm_proc)
                                build_modem[${#build_modem[@]}]=make_rpm
                            ;;

                            ADSP.VT.5.4.1|adsp_proc)
                                build_modem[${#build_modem[@]}]=make_adsp
                            ;;

                            CDSP.VT.2.4.1|cdsp_proc)
                                build_modem[${#build_modem[@]}]=make_cdsp
                            ;;

                            TZ.XF.5.1|trustzone_images)
                                build_modem[${#build_modem[@]}]=make_tz
                            ;;

                            *)
                                build_modem[${#build_modem[@]}]=make_all
                            ;;
                        esac
                    fi
                done

                if [[ -n ${build_modem[@]} ]]; then

                    # 去重
                    build_modem=($(awk -vRS=' ' '!a[$1]++' <<< ${build_modem[@]}))
                    __red__ "[tct]: 1. build modem = ${build_modem[@]}"

                    # 当需要全编译,就无需进行单编译.
                    for bm in ${build_modem[@]} ; do
                        if [[ ${bm} == "make_all" ]]; then
                            unset build_modem && build_modem[${#build_modem[@]}]=make_all
                            break;
                        fi
                    done

                    __red__ "[tct]: 2. build modem = ${build_modem[@]}"

                    pushd ${moden_path} > /dev/null

                    # 置空WORKSPACE
                    unset WORKSPACE

                    if [[ -f linux_build.sh ]]; then
                        Command ${build_modem[@]}
                    else
                        log error "The linux_build.sh has no found ..."
                    fi

                    popd > /dev/null
                fi

                export WORKSPACE=${tmpworkspace}
            ;;
        esac
    done < ${tmpfs}/${job_name}.env.ini
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

                *)
                    # 编译moden 需要重新choosecombo
                    if [[ ${bcase} == 'build_moden' ]]; then
                        source_init
                    fi

                    Command ${bcase}
                    if [[ $? -eq 0 ]]; then
                        if [[ ${is_full_build} == "false" ]]; then # 非全编译
                            if [[ ${#build_path[@]} -eq 0 ]]; then # 非单编译
                                if [[ ${build_case[${#build_case[@]}-1]} == ${bcase} ]]; then # 最后个单编译Moden
                                    verify_patchset_submit 0
                                fi
                            fi
                        fi
                    else
                        if [[ ${is_full_build} == "false" ]]; then
                            if [[ ${#build_path[@]} -eq 0 ]]; then
                                if [[ ${build_case[${#build_case[@]}-1]} == ${bcase} ]]; then
                                    verify_patchset_submit 1
                                fi
                            fi
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
                vendor/qcom/proprietary/sensors-see/sensors-hal-2.0|vendor/qcom/opensource/audio-hal/primary-hal/hal)
                    module_filter
                ;;

                vendor/qcom/proprietary/sensors-see/registry|frameworks/base/core/jni|vendor/qcom/proprietary/common)
                    module_filter
                ;;
            esac
        fi
    done

    if [[ ${#build_module_list[@]} -ne 0 ]];then
        fix_incorrect_module

        case ${job_name} in
            DohaTMO-R_Gerrit_Build)
                show_vir "[tct]: make-app ${build_module_list[@]}"
            ;;

            *)
                show_vir "[tct]: mma -j${JOBS} ${build_module_list[@]}"
            ;;
        esac

        if ${build_debug};then
            source_init
            case ${job_name} in
                DohaTMO-R_Gerrit_Build)
                    make-app ${build_module_list[@]}
                ;;

                *)
                    mma -j${JOBS} ${build_module_list[@]}
                ;;
            esac

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

    log print "TCT::TARGET_PRODUCT = ${TARGET_PRODUCT}"

    if ${build_debug};then

        if [[ $(is_mediatek_project) == 'true' ]]; then
            Command ./tclMake -o=${compile_para[@]} ${build_project} remake
        else
            if [[ "${TARGET_PRODUCT}" == "qssi" ]]; then
                Command "bash build.sh --qssi_only -j${JOBS}"
            else
                Command "bash build.sh --target_only -j${JOBS}"
            fi

        fi

        if [[ $? -eq 0 ]] ; then
            verify_patchset_submit 0
        else
            verify_patchset_submit 1
        fi
    fi
}