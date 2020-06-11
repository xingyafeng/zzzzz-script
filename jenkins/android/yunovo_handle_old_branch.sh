#!/usr/bin/env bash

### 是否为长屏分支的app
function is_long_branch_app()
{
    local check_long_app=$1
    local long_branch_app_name=(CarEngine CarRecordDouble NewsmyNewyan NewsmyRecorder NewsmySPTAdapter)

    if [[ $# -eq 1 ]];then
        :
    else
        log error "$# has error, please check args!"
    fi

    for a in ${long_branch_app_name[@]}
    do
        if [[ ${a} == ${check_long_app} ]];then
            echo true
        fi
    done
}

###是否为长屏项目
function is_long_project()
{
    ### jenkins path name
    local prjN=(k26s k26sd k86l k86ls k86ld k86lsd k86mx2 k88s)

    ### jenkins project name
    local projectN=(k26c k26d k27l k86mx1)

    local OLDP=`pwd`

    cd ${ROOT} > /dev/null

    local prj_name=$(pwd) && prj_name=${prj_name%/*} && prj_name=${prj_name##*/}

    for p1 in ${prjN[@]}
    do
        if [[ "$prj_name" == "$p1" ]];then
            echo true
        fi
    done

    for p2 in ${projectN[@]}
    do
        if [[ "$project_name" == "$p2"  ]];then
            echo true
        fi
    done

    cd ${OLDP} > /dev/null
}

function handler_update_source_code()
{
    local app_name=$1
    local branch_name=$2

    if git pull;then
        _echo "---- pull $branch_name $app_name successful ..."
    else
        log error "---- pull $branch_name $app_name failed ... "
    fi
}

function handler_checkout_branch()
{
    local branch_name=$1

    ##检查远程仓库是否存在
    if [[ "`git branch -r | grep \"${branch_name}\"`" ]];then

        ##检查本地是否存在
        if [[ "`git branch | grep \"${branch_name}\"`" ]];then

            ## 检查当前是否存在
            if [[ "`git branch | grep \* | cut -d ' ' -f2`" != "$branch_name" ]];then
                git checkout ${branch_name}
            else
                _echo "curr branch name: $branch_name ..."
            fi
        else
            git checkout -b ${branch_name} origin/${branch_name}
        fi
    else
        git checkout master
    fi
}

## download all app
function down_load_app_for_yunovo()
{
    local OLDP=`pwd`
    local ant_app_path=~/yunovo_app/packages/apps
    local android_app_path=packages/apps

    local ssh_link=ssh://jenkins@gerrit.y:29419/yunovo_packages
    local ssh_link_yunovo=ssh://jenkins@gerrit.y:29419/yunovo/packages/apps
    local yunovo_ant_app_file=${script_p}/config/yunovo_ant_app.txt
    local yunovo_android_app_file=${script_p}/config/yunovo_app.txt

    if [[ ! -d ${ant_app_path} ]];then
        mkdir -p ${ant_app_path}
    fi

if false;then
    cd ${ant_app_path} > /dev/null

    ## clone ant app
    while read app_name
    do
        clone_app ${app_name}
    done < ${yunovo_ant_app_file}

    _echo "-------- clone ant app end !"

    cd ${OLDP} > /dev/null
fi
    cd ${android_app_path} > /dev/null

    ## clone make app
    while read app_name
    do
        clone_app ${app_name}
    done < ${yunovo_android_app_file}

    _echo "-------- clone make app end !"

    cd ${OLDP} > /dev/null
}

## clone app for yunovo
function clone_app()
{
    if [[ $# -eq 1 ]];then
        :
    else
        log error clone_app fail , eg: clone <app_name> ...
    fi

    local app_name=$1

    if [[ -d ${app_name} ]];then

        ##调试app切换分支问题
        if false;then
            if [[ ${app_name} != "YOcVoice" ]];then
                continue;
            fi
        fi
        ## handler switch branch
        handler_branch_for_app ${app_name}
    else

        ## clone apk
        if [[ "$app_name" == "YOcScreenSaver" ]];then

            if [[ "$ssh_link_yunovo" ]];then
                git clone -b master ${ssh_link_yunovo}/${app_name}
                _echo "---- clone $app_name"
            fi
        else

            if [[ "$ssh_link" ]];then
                git clone -b master ${ssh_link}/${app_name}
                _echo "---- clone $app_name"
            fi
        fi

        ## handler switch branch
        handler_branch_for_app ${app_name}
    fi
}

function handler_branch_for_app()
{
    local app_name=$1
    local tag_name=""
    local branch_name=""
    local default_branch=""
    local local_branch_name=""
    local remote_branch_name=""

    ## 1.短屏分支
    local master_branch="master origin/master"
    local develop_branch="develop origin/develop"
    local test_branch="test origin/test"

    ## 2.长屏分支
    local long_branch="long origin/long"
    local develop_long_branch="develop_long origin/develop_long"
    local test_long_branch="test_long origin/test_long"

    ## 3.选择分支名称
    local branch_for_test="test"
    local branch_for_master="master"
    local branch_for_develop="develop"

    local branchR=""

    if [[ $# -eq 1 ]];then
        :
    else
        log error "e.g : handler_branch  app name ..."
    fi

    cd ${app_name} > /dev/null

    ## 更新远程仓库
    git fetch -p

    ## 长屏方案
    if [[ "`is_long_project`" == "true" ]];then

        if [[ "`is_long_branch_app $app_name`" == "true" ]];then

            if [[ ${build_branch} == ${branch_for_test} ]];then
                defalut_branch=${test_long_branch}
            elif [[ ${build_branch} == ${branch_for_develop} ]];then
                defalut_branch=${develop_long_branch}
            elif [[ ${build_branch} == ${branch_for_master} ]];then
                defalut_branch=${long_branch}
            else
                defalut_branch=${long_branch}
            fi

        else
            if [[ ${build_branch} == ${branch_for_test} ]];then
                defalut_branch=${test_branch}
            elif [[ ${build_branch} == ${branch_for_develop} ]];then
                defalut_branch=${develop_branch}
            elif [[ ${build_branch} == ${branch_for_master} ]];then
                defalut_branch=${master_branch}
            else
                defalut_branch=${master_branch}
            fi
        fi

    ## 短屏方案
    else
        if [[ ${build_branch} == ${branch_for_test} ]];then
            defalut_branch=${test_branch}
        elif [[ ${build_branch} == ${branch_for_develop} ]];then
            defalut_branch=${develop_branch}
        elif [[ ${build_branch} == ${branch_for_master} ]];then
            defalut_branch=${master_branch}
        else
            defalut_branch=${master_branch}
        fi
    fi

    if [[ "$defalut_branch" ]];then
        local_branch_name=${defalut_branch% *}
        remote_branch_name=${defalut_branch##* }
    else
        log error "The defalut_branch is null, please check it !"
    fi

    #echo "local_branch_name = $local_branch_name"
    #echo "remote_branch_name = $remote_branch_name"

    ## 1. 检查当前分支是否有检出对应的分支
    if [[ "`git branch | grep ${local_branch_name}`" ]];then

        ## 2. 检查当前分支是否为需要切换的分支
        if [[ "`git branch | grep \* | cut -d ' ' -f2`" != ${local_branch_name} ]];then

            if git checkout ${local_branch_name};then
                _echo "---- checkout $local_branch_name $app_name successful ..."
            else
                log error "---- checkout $local_branch_name $app_name fail ..."
            fi

            if git pull;then
                _echo "---- pull $local_branch_name $app_name successful ..."
            else
                log error "---- pull $local_branch_name $app_name fail ... "
            fi
        else
            if git pull;then
                _echo "---- pull $local_branch_name $app_name successful ..."
            else
                log error "---- pull $local_branch_name $app_name fail ... "
            fi
        fi

    ## 当前没有检出分支，开始进行检出分支..
    else
        if [[ "`git branch -r | grep "${remote_branch_name}$"`" ]];then
            branchR="`git branch -r | grep "${remote_branch_name}$"`"
            branchR=`remove_space_for_vairable "$branchR"`
        fi

        ## 检查 local_branch_name 远程分支是否存在?
        if [[ "$branchR" == "$remote_branch_name" ]];then

            if git checkout -b ${defalut_branch};then
                _echo "---- checkout $local_branch_name $app_name successful ..."
            else
                log error "---- checkout $local_branch_name $app_name fail ..."
            fi

            ## update apk
            if git pull;then
                _echo "---- pull $local_branch_name $app_name successful ..."
            else
                log error "---- pull $local_branch_name $app_name fail ... "
            fi

        ## 若不存在，则默认
        else
            if [[ "`git branch | grep master`" ]];then
                git checkout master
                _echo "---- checkout master successful ..."
            else
                if [[ "`git branch -r | grep master`" ]];then
                    git checkout -b ${master_branch}
                else
                    :
                fi
            fi

            ## update apk
            if git pull;then
                _echo "---- pull $app_name successful ..."
            else
                log error "---- pull $app_name fail ... "
            fi
        fi
    fi

    ## handler YOcLauncherRes branchs
    if [[ ${app_name} == "YOcLauncherRes" ]];then
        handler_branch_for_YOcLauncherRes
    fi

    ## handler k26s_LD-A107C branch
    if [[ ${app_name} == "YOcRecord" ]];then
        handler_branch_for_YOcRecord
    fi

    if [[ ${app_name} == "CarRecordUsb" ]];then
        handler_branch_for_CarRecordUsb
    fi

    if [[ ${app_name} == "YOcSplitScreen" ]];then
        handler_branch_for_YOcSplitScreen
    fi

    if [[ ${app_name} == "YOcMediaFolder" ]];then
        handler_branch_for_YOcMediaFolder
    fi

    if [[ ${app_name} == "YOcSettings" ]];then
        handler_branch_for_YOcSettings
    fi

    if [[ ${app_name} == "YOcBTCall" ]];then
        handler_branch_for_YOcBTCall
    fi

    if [[ ${app_name} == "YOcBTCallGoc" ]];then
        handler_branch_for_YOcBTCallGoc
    fi

    if [[ ${app_name} == "YOcTools" ]];then
        handler_branch_for_YOcTools
    fi

    if [[ ${app_name} == "TxzVoice" ]];then
        handler_branch_for_TxzVoice
    fi

    if [[ ${app_name} == "CarEngine" ]];then
        handler_branch_for_CarEngine
    fi

if false;then
    if [[ ${local_branch_name} == "long" || ${local_branch_name} == "develop_long" || ${local_branch_name} == "test_long" ]];then
        tag_name=L
    elif [[ ${local_branch_name} == ${branch_for_master} || ${local_branch_name} == ${branch_for_develop} || ${local_branch_name} == ${branch_for_test} ]];then
        tag_name=M
    fi

    if [[ "$local_branch_name" && "$tag_name" || "$app_name" ]];then

        ### 处理不同分支tag
        handler_tag_branch ${local_branch_name} ${tag_name} ${app_name}
    fi
fi
    #auto_create_refs_branch_for_app

    cd .. > /dev/null
}

function handler_branch_for_YOcLauncherRes()
{
    local sz_branch_name=

    #_echo "build_prj_name = $build_prj_name"
    case ${build_prj_name} in

        k26s_LD-A107C)
            sz_branch_name=S6_LD_V10
            ;;

        k27l_AJ-AJS-1)
            sz_branch_name=S6_AJ_V10
            ;;

        k27l_HBS-T2)
            sz_branch_name=S6_HBS_V10
            ;;

        k86ls_LS6-ZX | k86ls_S6-ZX | k88s_YT-YBT686 | k27l_S6-ZX | k88s_S6-ZX | k26s_YJ-K7 | k26s_K26-ZX | k27l_N91-ZX | k28s_K28-ZX | k26s_NM-D900 | k88s_QC-C66 | k89_QC-C66 | k27l_BY-K5 | k27l_KKXL-S6)
            sz_branch_name=S6_NXOS_V10
            ;;

        k26s_S6-ZX | k27_QC-M6PLUS | k85_S6-ZX | k26s_NM-D900)
            sz_branch_name=S6_NXOS_V21
            ;;

        k86ls_LHZ)
            sz_branch_name=S7_LHZ_V20
            ;;

        k27l_S7-ZX | k86ls_K86-ZX | k86ls_LHZ-KPS | k86mx2_K86-ZX | k26s_S7-ZX)
            sz_branch_name=S7_NXOS_V10
            ;;

        k86mx1_GY-G2B)
            sz_branch_name=S7_GY-G2B_V20
            ;;

        k86ls_K86-ZX2 | k88s_K88-ZX | k88s_S7-ZX | k86s7_S7-ZX)
            sz_branch_name=S7_NXOS_V20
            ;;

        k26s_LD-HS810A)
            sz_branch_name=S7_LD_V10
            ;;

        k86mx1_KKXL-C9)
            sz_branch_name=S7_KKXL_V20
            ;;

        k86mx1_QC-M78)
            sz_branch_name=S7_QC-M78_V21
            ;;

        k86mx1_ZYD-CM21)
            sz_branch_name=S7_ZYD-CM21_V21
            ;;

        k89_HP-S760)
            sz_branch_name=S7_HP-S760_V21
            ;;

        k86s7_NM-N810 | k88s_NM-D200)
            sz_branch_name=S7_NM-N810_V20
            ;;

        k86ls_K80)
            sz_branch_name=S7_XZ-K80_V20
            ;;

        k26s_RWY-CS85)
            sz_branch_name=S7_RWY-CS85_V22
            ;;

        k26s_RWY-CS82)
            sz_branch_name=S6_RWY-CS82_V22
            ;;

        k89_LD-HS830A)
            sz_branch_name=S7_LD-K89_V21
            ;;

        k89_LD-HS720A | k86mx1_LD-ZX)
            sz_branch_name=S7_LD-HS720A_V20
            ;;

        k88s_NM-D210)
            sz_branch_name=S7_NM-D210_V20
            ;;

        k86mx1_MB-M8S | k86mx1_MB-M8A)
            sz_branch_name=S7_MB-M8S_V21
            ;;

        k26s_MB-M60)
            sz_branch_name=S6_MB-M60_V21
            ;;

        k89_QC-X78 | k89_QC-X68)
            sz_branch_name=S6_QC-X78_V21
            ;;

        k26s_S5-ZX)
            sz_branch_name=S5_NXOS_V30
            ;;

        k26s_NM-C66)
            sz_branch_name=S6_NM-C66_V21
            ;;

        k89_T99)
            sz_branch_name=S6_XZ-T99_V21
            ;;

        k26s_MB-M50)
            sz_branch_name=S6_MB-M50_V21
            ;;

        k26e_QC-X18)
            sz_branch_name=S6_QC-X18_V21

            ;;
        *)
            sz_branch_name=S6_NXOS_V20
            ;;
    esac

    _echo "sz_branch_name = $sz_branch_name"

    if [[ "$sz_branch_name" ]];then
        handler_checkout_branch ${sz_branch_name}
        handler_update_source_code YOcLauncherRes ${sz_branch_name}
    fi
}

function handler_branch_for_YOcSettings()
{
    local YOcSettings_branch=

    case ${build_prj_name} in
        k88s_S6-ZX | k88s_S7-ZX | k88s_NM-D200 | k88s_NM-D210)
            YOcSettings_branch=new_2.0
            ;;

        k26s_S6-ZX | k26s_S7-ZX | k26s_NM-D900 | k26s_MB-M60 | k26s_MB-M50 | k26s_NM-C66 | k26e_QC-X18)
            YOcSettings_branch=new_2.0
            ;;

        k27l_S6-ZX | k27l_S7-ZX | k27l_N91-ZX | k27_QC-M6PLUS)
            YOcSettings_branch=new_2.0
            ;;

        k86ls_K80 | k89_T99)
            YOcSettings_branch=new_2.0
            ;;

        k86mx1_QC-M78 | k86mx1_MB-M8S | k86mx1_KKXL-C9 | k86mx1_MB-M8A | k86mx1_ZYD-CM21)
            YOcSettings_branch=new_2.0
            ;;

        k86s7_NM-N801 | k86s7_NM-N810)
            YOcSettings_branch=new_2.0
            ;;

        k26s_RWY-CS85 | k26s_RWY-CS82)
            YOcSettings_branch=new_2.0
            ;;

        k89_HP-S760 | k89_LD-HS830A | k89_LD-HS720A | k86mx1_LD-ZX | k89_QC-X78 | k89_QC-X68)
            YOcSettings_branch=new_2.0
            ;;

        k26s_S5-ZX)
            YOcSettings_branch=master_5c
            ;;

        *)
            __echo "YOcSettings_branch is null !"
            ;;
    esac

    if [[ "$YOcSettings_branch" ]];then
        handler_checkout_branch ${YOcSettings_branch}
        handler_update_source_code YOcSettings ${YOcSettings_branch}
    fi
}

function handler_branch_for_CarEngine()
{
    local CarEngine_branch=

    if [[ ${build_prj_name} == "k88c_MB-SQ01" ]];then
        CarEngine_branch=k88c/mb/sq01
    else
         if [[ "`git branch -r | grep 'test'`" || "`git branch -r | grep develop`" ]];then
            :
        else
            git checkout master
        fi
    fi

    if [[ "$CarEngine_branch" ]];then
        handler_checkout_branch ${CarEngine_branch}
        handler_update_source_code CarEngine ${CarEngine_branch}
    fi
}

function handler_branch_for_YOcMediaFolder()
{
    local YOcMediaFolder_branch=

    if [[ ${build_prj_name} == "k26s_LD-A107C" || ${build_prj_name} == "k89_LD-HS830A" || ${build_prj_name} == "k89_LD-HS720A" || ${build_prj_name} == "k86mx1_LD-ZX" ]];then
        YOcMediaFolder_branch=yunovo/k26s/lingdu/common
    else
         if [[ "`git branch -r | grep 'test'`" || "`git branch -r | grep develop`" ]];then
            :
        else
            git checkout master
        fi
    fi

    if [[ "$YOcMediaFolder_branch" ]];then
        handler_checkout_branch ${YOcMediaFolder_branch}
        handler_update_source_code YOcMediaFolder ${YOcMediaFolder_branch}
    fi
}

function handler_branch_for_YOcRecord()
{
    local YOcRecord_branch=

    if [[ ${build_prj_name} == "k26s_LD-A107C" || ${build_prj_name} == "k26s_LD-HS810A" ]];then
        YOcRecord_branch=k26s/ld/a107c
    elif [[ ${build_prj_name} == "k27l_HBS-T2" ]];then
        YOcRecord_branch=yunovo/k27l/hbs/common
    elif [[ ${build_prj_name} == "k89_LD-HS830A" || ${build_prj_name} == "k89_LD-HS720A" || ${build_prj_name} == "k86mx1_LD-ZX" ]];then
        YOcRecord_branch=k89/ld/hs830a
    elif [[ ${build_prj_name} == "k26s_S5-ZX" ]];then
        YOcRecord_branch=master_5c
    elif [[ ${build_prj_name} == "k86ls_K80" ]];then
        YOcRecord_branch=mx1/xianzhi/k80
    elif [[ ${build_prj_name} == "k89_T99" ]];then
        YOcRecord_branch=k89/xianzhi/t99
    else
        if [[ "`git branch -r | grep 'test'`" || "`git branch -r | grep develop`" ]];then
            :
        else
            git checkout master
        fi

        _echo "checkout master branch on YOcRecord"
    fi

    if [[ "$YOcRecord_branch" ]];then
        handler_checkout_branch ${YOcRecord_branch}
        handler_update_source_code YOcRecord ${YOcRecord_branch}
    fi
}

function handler_branch_for_CarRecordUsb()
{
     local CarRecordUsb_branch=

    if [[ ${build_prj_name} == "k86ls_K86-ZX2" ]];then
        CarRecordUsb_branch=test_mode
    else
        if [[ "`git branch -r | grep 'test'`" || "`git branch -r | grep develop`" ]];then
            :
        else
            git checkout master
        fi

        _echo "checkout master branch on CarRecordUsb"
    fi

    if [[ "$CarRecordUsb_branch" ]];then
        handler_checkout_branch ${CarRecordUsb_branch}
        handler_update_source_code CarRecordUsb ${CarRecordUsb_branch}
    fi
}

function handler_branch_for_YOcSplitScreen()
{
    local YOcSplitScreen_branch=

    if [[ ${build_prj_name} == "k26s_S5-ZX" ]];then
        YOcSplitScreen_branch=master_5c
    else
        if [[ "`git branch -r | grep 'test'`" || "`git branch -r | grep develop`" ]];then
            :
        else
            git checkout master
        fi

        _echo "checkout master branch on YOcRecord"
    fi

    if [[ "$YOcSplitScreen_branch" ]];then
        handler_checkout_branch ${YOcSplitScreen_branch}
        handler_update_source_code YOcSplitScreen ${YOcSplitScreen_branch}
    fi
}

function handler_branch_for_YOcBTCall()
{
    local YOcBTCall_branch=

    case ${build_prj_name} in

        k88s_S6-ZX | k88s_S7-ZX | k88s_NM-D200 | k88s_NM-D210)
            YOcBTCall_branch=bt_new2.0
            ;;

        k26s_S6-ZX | k26s_S7-ZX | k26s_NM-D900 | k26s_NM-C66)
            YOcBTCall_branch=bt_new2.0
            ;;

        k27l_S6-ZX | k27l_S7-ZX | k27l_N91-ZX)
            YOcBTCall_branch=bt_new2.0
            ;;

        k86mx1_QC-M78 | k86mx1_MB-M8S | k86mx1_MB-M8A | k86mx1_ZYD-CM21)
            YOcBTCall_branch=bt_new2.0
            ;;

        k86ls_K80 | k89_T99)
            YOcBTCall_branch=bt_new2.0
            ;;

        k86s7_NM-N801 | k86s7_NM-N810)
            YOcBTCall_branch=bt_new2.0
            ;;

        k26s_RWY-CS85)
            YOcBTCall_branch=bt_new2.0
            ;;

        k89_HP-S760 | k89_LD-HS830A | k89_LD-HS720A | k86mx1_LD-ZX)
            YOcBTCall_branch=bt_new2.0
            ;;

        *)
            __echo "YOcBTCall_branch is null !"
            ;;
    esac

    if [[ "$YOcBTCall_branch" ]];then
        handler_checkout_branch ${YOcBTCall_branch}
        handler_update_source_code YOcBTCall ${YOcBTCall_branch}
    fi
}

function handler_branch_for_YOcBTCallGoc()
{
    local YOcBTCallGoc_branch=

    case ${build_prj_name} in

        k86ls_K80 | k89_T99)
            YOcBTCall_branch="mx1/xianzhi/k80"
            ;;

        *)
            __echo "YOcBTCallGoc_branch is null !"
            ;;
    esac

    if [[ "$YOcBTCallGoc_branch" ]];then
        handler_checkout_branch ${YOcBTCallGoc_branch}
        handler_update_source_code YOcBTCallGoc ${YOcBTCallGoc_branch}
    fi
}

function handler_branch_for_YOcTools()
{
    local YOcTools_branch=

    case ${build_prj_name} in

        k86s7_NM-N810)
            YOcTools_branch="k86s7/newsmy/n810"
            ;;

        *)
            __echo "YOcTools_branch is null !"
            ;;
    esac

    if [[ "$YOcTools_branch" ]];then
        handler_checkout_branch ${YOcTools_branch}
        handler_update_source_code YOcTools ${YOcTools_branch}
    fi
}

function handler_branch_for_TxzVoice()
{
    local TxzVoice_branch=

    case ${build_prj_name} in

        k86s7_NM-N810 | k86mx1_MB-M8S | k86ls_K80 | k86mx1_MB-M8A | k26s_MB-M60 | k26s_MB-M50 | k89_QC-X78 | k89_QC-X68 |　k26s_RWY-CS82　| k26e_QC-X18 | k86mx1_ZYD-CM21 | k89_T99)
            TxzVoice_branch=txzing2.0
            ;;

        *)
            __echo "TxzVoice_branch is null !"
            ;;
    esac

    if [[ "$TxzVoice_branch" ]];then
        handler_checkout_branch ${TxzVoice_branch}
        handler_update_source_code TxzVoice ${TxzVoice_branch}
    fi
}

function down_load_apk_for_yunovo()
{
    local OLDP=`pwd`
    local app_path=packages/apps

    local ssh_link=ssh://jenkins@gerrit.y:29419/yunovo_packages
    local yunovo_apk_file=${script_p}/config/yunovo_apk.txt

    cd ${app_path} > /dev/null

    while read apk_name
    do
        if [[ -d ${apk_name} ]];then

            ## handler switch branch
            handler_branch_for_apk ${apk_name}
        else

            ## clone apk
            if [[ "$ssh_link" ]];then
                git clone -b master ${ssh_link}/${apk_name}
                _echo "---- clone $apk_name"
            else
                log error "The $ssh_link is null. please check it !"
            fi
        fi
    done < ${yunovo_apk_file}

    _echo "-------- clone apk end !"

    cd ${OLDP}
}

function handler_branch_for_apk()
{
    local apk_name=$1
    local default_branch=""
    local local_branch_name=""
    local remote_branch_name=""
    local master_branch="master origin/master"
    local long_branch="long origin/long"

    if [[ $# -eq 1 ]];then
        :
    else
        log error "e.g : The handler_branch  name ..."
    fi

    cd ${apk_name} > /dev/null

    ## 长屏方案
    if [[ "`is_long_project`" == "true" ]];then

        if [[ "`is_long_branch_app $apk_name`" == "true" ]];then

            defalut_branch=${long_branch}
        else

            defalut_branch=${master_branch}
        fi

    ## 短屏方案
    else
        defalut_branch=${master_branch}
    fi

    if [[ "$defalut_branch" ]];then
        local_branch_name=${defalut_branch% *}
        remote_branch_name=${defalut_branch##* }
    else
        log error "The defalut_branch is null, please check it !"
    fi

    #echo "local_branch_name = $local_branch_name"
    #echo "remote_branch_name = $remote_branch_name"

    ## 检查当前分支是否有检出对应的分支
    if [[ "`git branch | grep ${local_branch_name}`" ]];then

        ## 检查当前分支是否为需要切换的分支
        if [[ "`git branch | grep \* | cut -d ' ' -f2`" != ${local_branch_name} ]];then

            if git checkout ${local_branch_name};then
                _echo "---- checkout $local_branch_name $apk_name successful ..."
            else
                log error "---- checkout $local_branch_name $apk_name fail ..."
            fi

            if git pull;then
                _echo "---- pull $local_branch_name $apk_name successful ..."
            else
                log error "---- pull $local_branch_name $apk_name fail ... "
            fi
        else
            if git pull;then
                _echo "---- pull $local_branch_name $apk_name successful ..."
            else
                log error "---- pull $local_branch_name $apk_name fail ... "
            fi
        fi
    else

        ## 检查 local_branch_name 远程分支是否存在?
        if [[ "`git branch -r | grep ${local_branch_name}`" == "$remote_branch_name" ]];then

            ## 当前没有检出分支，开始进行检出分支..
            if git checkout -b ${defalut_branch};then
                _echo "---- checkout $local_branch_name $apk_name successful ..."
            else
                log error "---- checkout $local_branch_name $apk_name fail ..."
            fi

            ## update apk
            if git pull;then
                _echo "---- pull $local_branch_name $apk_name successful ..."
            else
                log error "---- pull $local_branch_name $apk_name fail ... "
            fi

        ## 若不存在,则默认master分支
        else
            if [[ "`git branch | grep master`" ]];then
                git checkout master
            else
                if [[ "`git branch -r | grep master`" ]];then
                    git checkout -b ${master_branch}
                else
                    :
                fi
            fi

            if git pull;then
                _echo "---- pull $apk_name successful ..."
            else
                _echo "---- pull $apk_name fail ..."
            fi
        fi

    fi

    if [[ ${apk_name} == "TxzCore" ]];then
        handler_branch_for_TxzCore
    fi

    if [[ ${apk_name} == "TxzWebchat" ]];then
        handler_branch_for_TxzWebchat
    fi

    if [[ ${apk_name} == "CheYueBao" ]];then
        handler_branch_for_CheYueBao
    fi

    if [[ ${apk_name} == "Car_YZYLN" ]];then
        handler_branch_for_Car_YZYLN
    fi

    #auto_create_refs_branch_for_app

    cd .. > /dev/null
}

function handler_branch_for_TxzCore()
{
    local TxzCore_branch=

    case ${build_prj_name} in

        k86s7_NM-N810|k88s_NM-D200|k88s_NM-D210|k86mx1_MB-M8S|k86ls_K80|k86mx1_MB-M8A|k26s_MB-M60|k26s_MB-M50|k89_QC-X78|k89_QC-X68|k26s_RWY-CS82|k26e_QC-X18|k86mx1_ZYD-CM21|k89_T99)
            TxzCore_branch=txzing2.0
            ;;

        *)
           __echo "TxzCore_branch is null !"
            ;;
    esac

    if [[ "$TxzCore_branch" ]];then
        handler_checkout_branch ${TxzCore_branch}
        handler_update_source_code TxzCore ${TxzCore_branch}
    fi
}

function handler_branch_for_TxzWebchat()
{
    local TxzWebchat_branch=

    case ${build_prj_name} in

        k86s7_NM-N810|k88s_NM-D200|k88s_NM-D210|k86mx1_MB-M8S|k86ls_K80|k86mx1_MB-M8A|k26s_MB-M60|k26s_MB-M50|k89_QC-X78|k89_QC-X68|k26s_RWY-CS82|k26e_QC-X18|k86mx1_ZYD-CM21|k89_T99)
            TxzWebchat_branch=txzing2.0
            ;;

        *)
           __echo "TxzWebchat_branch is null !"
            ;;
    esac

    if [[ "$TxzWebchat_branch" ]];then
        handler_checkout_branch ${TxzWebchat_branch}
        handler_update_source_code TxzWebchat ${TxzWebchat_branch}
    fi
}

function handler_branch_for_CheYueBao()
{
    local CheYueBao_branch=

    case ${build_prj_name} in

        k86mx1_MB-M8S | k86ls_K80 | k86mx1_MB-M8A | k26s_MB-M50 | k89_QC-X78 | k89_QC-X68)
            CheYueBao_branch=cyb1.6
            ;;

        *)
           __echo "CheYueBao_branch is null !"
            ;;
    esac

    if [[ "$CheYueBao_branch" ]];then
        handler_checkout_branch ${CheYueBao_branch}
        handler_update_source_code CheYueBao ${CheYueBao_branch}
    fi
}

function handler_branch_for_Car_YZYLN()
{
    local Car_YZYLN_branch=

    case ${build_prj_name} in

        k86mx1_MB-M8S)
            Car_YZYLN_branch="mx1/meiban/m8s"
            ;;

        *)
           __echo "Car_YZYLN_branch is null !"
            ;;
    esac

    if [[ "$Car_YZYLN_branch" ]];then
        handler_checkout_branch ${Car_YZYLN_branch}
        handler_update_source_code Car_YZYLN ${Car_YZYLN_branch}
    fi
}

