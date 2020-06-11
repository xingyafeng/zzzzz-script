#!/usr/bin/env bash

function is_5c_prject()
{
    case ${build_prj_name} in

        k27_S5-ZX|k26s_S5-ZX|k88c7_S5-ZX)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

function is_6c_prject()
{
    case ${build_prj_name} in

        k26)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

function is_7c_prject()
{
    case ${build_prj_name} in

        k27)
            echo true
            ;;

        *)
            echo false
            ;;
    esac
}

function handle_branch_for_YOcLauncher()
{
    case ${build_prj_name} in
        k89_T99)
            branch_name=k26s/xianzhi/t99
            ;;
        *)
            :
            ;;
    esac
}

function handle_branch_for_YOcLauncherRes()
{
    case ${build_prj_name} in

        k27_S5-ZX|k26s_S5-ZX|k88c7_S5-ZX)
            branch_name=S5_NXOS_V30
            ;;

        k26s_LD-A107C)
            branch_name=S6_LD_V10
            ;;

        k27l_AJ-AJS-1)
            branch_name=S6_AJ_V10
            ;;

        k27l_HBS-T2)
            branch_name=S6_HBS_V10
            ;;

        k86ls_LS6-ZX|k86ls_S6-ZX|k86mx1_S6-ZX|k88s_YT-YBT686|k27l_S6-ZX|k88s_S6-ZX|k26s_YJ-K7|k26s_K26-ZX|k27l_N91-ZX|k28s_K28-ZX|k26s_NM-D900|k88s_QC-C66|k89_QC-C66|k27l_BY-K5|k27l_KKXL-S6|k88c_QC-X2)
            branch_name=S6_NXOS_V10
            ;;

        k26s_S6-ZX|k27_QC-D30|k27_QC-M6PLUS|k89_S6-ZX|k26e_XK-D620|k27_LD-ZX|k27_QC-R02)
            branch_name=S6_NXOS_V21
            ;;

        k86ls_LHZ)
            branch_name=S7_LHZ_V20
            ;;

        k27l_S7-ZX | k86ls_K86-ZX | k86ls_LHZ-KPS | k86mx2_K86-ZX | k26s_S7-ZX)
            branch_name=S7_NXOS_V10
            ;;

        k86mx1_GY-G2B)
            branch_name=S7_GY-G2B_V20
            ;;

        k86ls_K86-ZX2 | k88s_K88-ZX | k88s_S7-ZX | k86s7_S7-ZX|k86mx1_JLRX-ZX)
            branch_name=S7_NXOS_V20
            ;;

        k26s_LD-HS810A)
            branch_name=S7_LD_V10
            ;;

        k86mx1_KKXL-C9)
            branch_name=S7_KKXL_V20
            ;;

        k86mx1_QC-M78|k86mx1_S7-ZX)
            branch_name=S7_QC-M78_V21
            ;;

        k89_HP-S760)
            branch_name=S7_HP-S760_V21
            ;;

        k86s7_NM-N810 | k88s_NM-D200)
            branch_name=S7_NM-N810_V20
            ;;

        k86ls_K80)
            branch_name=S7_XZ-K80_V20
            ;;

        k26s_RWY-CS85)
            branch_name=S7_RWY-CS85_V22
            ;;

        k26s_RWY-CS82)
            branch_name=S6_RWY-CS82_V22
            ;;

        k89_LD-HS830A)
            branch_name=S7_LD-K89_V21
            ;;

        k89_LD-HS720A | k86mx1_LD-ZX)
            branch_name=S7_LD-HS720A_V20
            ;;

        k88s_NM-D210)
            branch_name=S7_NM-D210_V20
            ;;

        k86mx1_MB-M8S | k86mx1_MB-M8A)
            branch_name=S7_MB-M8S_V21
            ;;

        k26s_MB-M60)
            branch_name=S6_MB-M60_V21
            ;;

        k89_QC-X78 | k89_QC-X68)
            branch_name=S6_QC-X78_V21
            ;;

        k26s_NM-C66)
            branch_name=S6_NM-C66_V21
            ;;

        k89_T99)
            branch_name=S6_XZ-T99_V21
            ;;

        k26s_MB-M50)
            branch_name=S6_MB-M50_V21
            ;;

        k26e_QC-X18|k26e_NM-D910|k26e_QC-X18ZX|k26e_QC-X88ZX|k26e_QC-X88BP|k26e_QC-X18BP|k26s_QC-YX88)
            branch_name=S6_QC-X18_V21
            ;;

        k26e_BHZ-X700)
            branch_name=S6_HBZ-X600_V21
            ;;

        k86mx1_S9-ZX|k86mx1_JLRX-M3)
            branch_name=S7_NXOS_V24
            ;;

        k26s_MB-M30)
            branch_name=S7_MB-M30_V21
            ;;

        k26s_LJ-D880)
            branch_name=S7_LJ-D880_V21
            ;;

        k26s_LJ-D800)
            branch_name=S6_LJ-D800_V21
            ;;

        k26s_ZX-T6)
            branch_name=S7_BYOS-8_V21
            ;;

        k26s_DWT-T02)
            branch_name=S6_DWT-T02_V21
            ;;

        k26s_KKXL-K8)
            branch_name=S6_KKXL-K8_V21
            ;;

        k26e_BHZ-X700A)
            branch_name=S7_HBZ-X700A_V21
            ;;

        k89_XY-C30)
            branch_name=S9_XY-C30_V24
            ;;

        k88c_QC-JNX18)
            branch_name=S6_JN-X18_V21
            ;;
        *)
            :
            ;;
    esac
}

function handle_branch_for_YOcRecord()
{
    case ${build_prj_name} in

        k26s_LD-HS810A)
            branch_name=k26s/ld/a107c
            ;;

        k89_LD-HS830A|k86mx1_LD-ZX)
            branch_name=k89/ld/hs830a
            ;;

        k89_T99)
            branch_name=k89/xianzhi/t99
            ;;

        k86mx1_JLRX-ZX)
            branch_name=k86mx1/jlrx/zx
            ;;

        k26e_BHZ-X700)
            branch_name=k26e/bhz/x600
            ;;

        k86mx1_S9-ZX)
            branch_name=k86mx1/s9/zx
            ;;

        k86mx1_JLRX-M3)
            branch_name=master
            ;;

        k26s_QC-YX88)
            branch_name=k26e/qc/yx-88
            ;;

        *)
            :
            ;;
    esac
}

function handle_branch_for_YOcMediaFolder()
{
    case ${build_prj_name} in

        k86mx1_LD-ZX|k89_LD-HS830A)
            branch_name=yunovo/k26s/lingdu/common
        ;;

        *)
            :
        ;;
    esac
}

function handle_branch_for_YOcSettings()
{
    case ${build_prj_name} in
        k88s_S6-ZX | k88s_S7-ZX | k88s_NM-D200 | k88s_NM-D210)
            branch_name=new_2.0
            ;;

        k26s_S6-ZX | k26s_S7-ZX | k26s_NM-D900 | k26s_MB-M60 | k26s_MB-M50 | k26s_NM-C66 | k26e_QC-X18)
            branch_name=new_2.0
            ;;

        k27l_S6-ZX | k27l_S7-ZX | k27l_N91-ZX)
            branch_name=new_2.0
            ;;

        k86ls_K80 | k89_T99)
            branch_name=new_2.0
            ;;

        k86mx1_QC-M78 | k86mx1_MB-M8S | k86mx1_KKXL-C9 | k86mx1_MB-M8A)
            branch_name=new_2.0
            ;;

        k86s7_NM-N801 | k86s7_NM-N810)
            branch_name=new_2.0
            ;;

        k26s_RWY-CS85 | k26s_RWY-CS82)
            branch_name=new_2.0
            ;;

        k89_HP-S760 | k89_LD-HS830A | k89_LD-HS720A | k86mx1_LD-ZX | k89_QC-X78 | k89_QC-X68)
            branch_name=new_2.0
            ;;

        k26s_S5-ZX|k88c7_S5-ZX)
            branch_name=new_2.0
            ;;

        *)
            :
            ;;
    esac
}

function handle_branch_for_YOcBTCall()
{
    case ${build_prj_name} in
        k88s_S6-ZX | k88s_S7-ZX | k88s_NM-D200 | k88s_NM-D210)
            branch_name=bt_new2.0
            ;;

        k26s_S6-ZX | k26s_S7-ZX | k26s_NM-D900 | k26s_NM-C66)
            branch_name=bt_new2.0
            ;;

        k27l_S6-ZX | k27l_S7-ZX | k27l_N91-ZX)
            branch_name=bt_new2.0
            ;;

        k86mx1_QC-M78 | k86mx1_MB-M8S | k86mx1_MB-M8A)
            branch_name=bt_new2.0
            ;;

        k86ls_K80 | k89_T99)
            branch_name=bt_new2.0
            ;;

        k86s7_NM-N801 | k86s7_NM-N810)
            branch_name=bt_new2.0
            ;;

        k26s_RWY-CS85)
            branch_name=bt_new2.0
            ;;

        k89_HP-S760 | k89_LD-HS830A | k89_LD-HS720A | k86mx1_LD-ZX)
            branch_name=bt_new2.0
            ;;

        *)
            :
            ;;
    esac
}

function handle_branch_for_YOcBTCallGoc()
{
    case ${build_prj_name} in

        k86ls_K80 | k89_T99)
            branch_name=mx1/xianzhi/k80
            ;;

        *)
            :
            ;;
    esac
}

function handle_branch_for_YOcTools()
{
    case ${build_prj_name} in

        k86s7_NM-N810)
            branch_name=k86s7/newsmy/n810
            ;;

        k26s_LJ-D880)
            branch_name=k26s/lj/d880
            ;;

        *)
            :
            ;;
    esac
}

function handle_branch_for_TxzVoice()
{
    case ${build_prj_name} in

        k86s7_NM-N810 | k88s_NM-D200 | k88s_NM-D210 | k86mx1_MB-M8S | k86ls_K80 | k86mx1_MB-M8A | k26s_MB-M60 | k26s_MB-M50 | k89_QC-X78 | k89_QC-X68 | k89_T99)
            branch_name=txzing2.0
            ;;

        *)
            :
            ;;
    esac
}

function handle_branch_for_FactoryTest()
{
    case ${build_prj_name} in
        k89_T99)
            branch_name=k89/master
            ;;
        *)
            :
            ;;
    esac
}

function handle_branch_for_CarRecordUsb()
{
    case ${build_prj_name} in
        k86mx1_JLRX-ZX)
            branch_name=k86mx1/jlrx/zx
            ;;

        k86mx1_S9-ZX|k86mx1_JLRX-M3)
            branch_name=k86mx1/s9/zx
            ;;

        *)
            :
            ;;
    esac
}

function handle_branch_for_CarPlatform()
{
    case ${build_prj_name} in
        k27_LD-ZX)
            branch_name=k89/ld/720a
            ;;

        *)
            :
            ;;
    esac
}

## 自动更新APP源码
function auto_update_source_code()
{
    local TMP=
    local project_apps=${tmpfs}/${build_prj_name}.log

    if [[ "$1" ]];then
        TMP=$1
    fi

    if [[ -f ${project_apps} ]];then

        while read apps;
        do

            if [[ "$apps" == ${TMP} ]];then

                ## 更新远程仓库
                time git fetch -p

                if git pull;then
                    _echo "---- pull $branch_name $TMP successful ..."
                else
                    log error "---- pull $branch_name $TMP failed ... "
                fi
            fi
        done < ${project_apps}

    else

        ## 更新远程仓库
        time git fetch -p

        if git pull;then
            _echo "---- pull $branch_name $TMP successful ..."
        else
            log error "---- pull $branch_name $TMP fail ... "
        fi
    fi
}

function checkout_branch()
{
    local TMP=

    if [[ "$1" ]];then
        TMP=$1
    fi

    ##检查远程仓库是否存在
    if [[ "`git branch -r | grep \"${branch_name}\"`" ]];then

        ##检查本地是否存在
        if [[ "`git branch | grep \"${branch_name}\"`" ]];then

            ## 检查当前是否存在
            if [[ "`git branch | grep \* | cut -d ' ' -f2`" != "$branch_name" ]];then
                git checkout ${branch_name}
            else
                show_viy "This $TMP branchN:$branch_name"
            fi
        else
            git checkout -b ${branch_name} origin/${branch_name}
        fi
    else
        git checkout master
    fi

    ## 查看切换后分支状态
    git branch
}

function checkout_app_branch()
{
    cd ${app_name} > /dev/null

    if [[ "`is_5c_prject`" == true ]];then

        case ${app_name} in

            CarRecordDouble | YOcBTCallGoc | YOcFM | YOcSettings | YOcSplitScreen)
                branch_name=master_5c
                ;;

            CarUpdateDFU | CarPlatform | FactoryTest | FileCopyManager)
                branch_name=develop
                ;;

            TxzVoice)
                branch_name=txzing2.0
                ;;

            *)
                branch_name=master
                ;;
        esac
    elif [[ "`is_6c_prject`" == "true" ]];then

        case ${app_name} in
            YOcSettings)
                branch_name=new_2.0
                ;;

            *)
                branch_name=master
                ;;
        esac
    elif [[ "`is_7c_prject`" == "true" ]];then

        case ${app_name} in
            YOcSettings)
                branch_name=new_2.0
                ;;

            *)
                branch_name=master
                ;;
        esac
    else
        ## 老项目
        case ${app_name} in
            AiosAdapterVoice|CarBack|CarEngine|CarPlatform|CarRecord|CarRecordDouble|CarRecordUsb|CarUpdateDFU|FactoryTest|FileCopyManager|TxzVoice|YOcFM|YOcVoice)
                branch_name=develop
                ;;

            YOcSettings)
                branch_name=new_2.0
                ;;

            *)
                branch_name=master
                ;;
        esac
    fi

    ## 处理特别的分支
    case ${app_name} in

        FactoryTest)
            handle_branch_for_FactoryTest
            ;;

        YOcLauncher)
            handle_branch_for_YOcLauncher
            ;;

        YOcLauncherRes)
            handle_branch_for_YOcLauncherRes
            ;;

        YOcRecord)
            handle_branch_for_YOcRecord
            ;;

        YOcMediaFolder)
            handle_branch_for_YOcMediaFolder
            ;;

        YOcSettings)
            handle_branch_for_YOcSettings
            ;;

        YOcBTCall)
            handle_branch_for_YOcBTCall
            ;;

        YOcBTCallGoc)
            handle_branch_for_YOcBTCallGoc
            ;;

        YOcTools)
            handle_branch_for_YOcTools
            ;;

        TxzVoice)
            handle_branch_for_TxzVoice
            ;;

        CarRecordUsb)
            handle_branch_for_CarRecordUsb
            ;;

        CarPlatform)
            handle_branch_for_CarPlatform
            ;;

        *)
            :
            ;;
    esac

    if [[ "$branch_name" ]];then
        checkout_branch ${app_name}
        auto_update_source_code ${app_name}
    fi

    if [[ "$build_refs" == "true"_yunovo ]];then
        auto_create_refs_branch_for_app
    fi

    _echo "#######################################################################"
    cd .. > /dev/null
}

function auto_checkout_app_branch()
{
    local OLDP=`pwd`

    local branch_name=
    local gerrit_name=`git config --get user.name`
    local applist=yunovo_app.txt
    local projectO=yunovo_packages
    local projectN=yunovo/packages/apps
    local app_path=packages/apps
    local appfs=${script_p}/config/${applist}

    local ssh_link="ssh://${gerrit_name}@gerrit.y:29419"

    cd ${app_path} > /dev/null

    ## down load app
    while read app_name
    do
        if [[ -d ${app_name} ]];then

            ##调试APP切换分支问题
            if false;then
                if [[ ${app_name} != "YOcVoice" ]];then
                    continue;
                fi
            fi

            ## handle checkout branch for app
            checkout_app_branch
        else

            ## 下载特殊APP
            if [[ "$app_name" == "YOcScreenSaver" ]];then
                if [[ "$ssh_link/$projectN" ]];then
                    time git clone -b master ${ssh_link}/${projectN}/${app_name}
                    _echo "---- clone $app_name"
                else
                    log error "----The project name is null, please check it ."
                fi
            else
                if [[ "$ssh_link/$projectO" ]];then
                    time git clone -b master ${ssh_link}/${projectO}/${app_name}
                    _echo "---- clone $app_name"
                else
                    __err "---- projectO is null ! please check it ."
                fi
            fi

            ## handle checkout branch
            checkout_app_branch
        fi

    done < ${appfs}

    show_vip "---- download app end !"

    cd ${OLDP} > /dev/null
}

function handle_branch_for_TxzWebchat_and_TxzCore()
{
    case ${build_prj_name} in

        k86s7_NM-N810|k88s_NM-D200|k88s_NM-D210|k86mx1_MB-M8S|k86ls_K80|k86mx1_MB-M8A|k26s_MB-M60|k26s_MB-M50|k89_QC-X78|k89_QC-X68 | k89_T99)
            branch_name=txzing2.0
            ;;

        k27_S5-ZX|k26s_S5-ZX|k88c7_S5-ZX)
            branch_name=txzing2.0
            ;;

        *)
            branch_name=master
            ;;
    esac
}

function handle_branch_for_CheYueBao()
{
    case ${build_prj_name} in
        k86mx1_MB-M8S|k86ls_K80|k86mx1_MB-M8A|k26s_MB-M50|k89_QC-X78|k89_QC-X68)
            branch_name=cyb1.6
            ;;
        *)
            branch_name=master
            ;;
    esac
}

function handle_branch_for_Car_YZYLN()
{
    case ${build_prj_name} in
        k86mx1_MB-M8S)
            branch_name=mx1/meiban/m8s
            ;;
        *)
            branch_name=master
            ;;
    esac
}

function handle_branch_for_GaodeCustomerMap()
{

    case ${build_prj_name} in
        k89_T99 | k26e_QC-X18)
            branch_name=master
            ;;
        *)
            branch_name=master
            ;;
    esac
}

function handle_branch_for_ECarVoip_and_ECar()
{

    case ${build_prj_name} in
         k86mx1_QC-M78 | k86S7_QC-M78 | k27_QC-M6PLUS)
            branch_name=k86mx1/qc/m78
            ;;
        *)
            branch_name=master
            ;;
    esac
}

function checkout_apk_branch()
{
    cd ${apk_name} > /dev/null

    ## 第三方APK默认使用master
    case ${apk_name} in

        *)
            branch_name=master
            ;;
    esac

    ## 处理特别的分支
    case ${apk_name} in
        NewsmyNewyan | NewsmyRecorder | NewsmySPTAdapter)
            branch_name=long
            ;;

        TxzWebchat | TxzCore)
            handle_branch_for_TxzWebchat_and_TxzCore
            ;;

        CheYueBao)
            handle_branch_for_CheYueBao
            ;;

        Car_YZYLN)
            handle_branch_for_Car_YZYLN
            ;;

        GaodeCustomerMap)
            handle_branch_for_GaodeCustomerMap
            ;;

        ECarVoip | ECar)
            handle_branch_for_ECarVoip_and_ECar
            ;;

        *)
            :
            ;;
    esac

    if [[ "$branch_name" ]];then
        checkout_branch ${apk_name}
        auto_update_source_code ${apk_name}
    fi

    if [[ "$build_refs" == "true"_yunovo ]];then
        auto_create_refs_branch_for_app
    fi

    _echo "#######################################################################"
    cd .. > /dev/null
}

function auto_checkout_apk_branch()
{
    local OLDP=`pwd`

    local branch_name=
    local gerrit_name=`git config --get user.name`
    local apklist=yunovo_apk.txt
    local projectO=yunovo_packages
    local app_path=packages/apps
    local apkfs=${script_p}/config/${apklist}

    local ssh_link="ssh://${gerrit_name}@gerrit.y:29419"

    cd ${app_path} > /dev/null

    while read apk_name
    do
        if [[ -d ${apk_name}  ]];then

            ## handle checkout branch for apk
            checkout_apk_branch
        else
            if [[ "$ssh_link/$projectO" ]];then
                time git clone -b master ${ssh_link}/${projectO}/${apk_name}
                _echo "---- clone $apk_name"
            else
                log error "The $ssh_link is null, please check it !"
            fi
        fi
    done < ${apkfs}

    show_vip "---- download apk end !"

    cd ${OLDP} > /dev/null
}

function auto_checkout_branch()
{
    auto_checkout_apk_branch
    auto_checkout_app_branch
}
