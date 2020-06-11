#!/usr/bin/env bash

#### 获取所有repo下的xml文件中的git仓库路径
function get_repo_git_path_from_xml()
{
    local OPWD=`pwd`

    cd .repo/manifests > /dev/null

    for xml in `ls`
    do
        if [[ -f ${xml} ]];then
            git_prj_name[${#git_prj_name[@]}]=`egrep -E '<project' ${xml} | grep name | egrep -v '<!--' | grep path | sed 's%.*path="%%' | sed 's%".*%%'`
            git_prj_name[${#git_prj_name[@]}]=`egrep -E '<project' ${xml} | grep name | egrep -v '<!--|path' | sed 's%.*name="%%' | sed 's%".*%%'`
        fi
    done

    cd ${OPWD} > /dev/null

    echo ${git_prj_name[@]}
}

# 拿到Android根路径,会覆盖source中的gettop函数
function gettop() {

    if [[ -n "${gettop_p}" ]]; then
        (cd ${gettop_p}; PWD= /bin/pwd)
    else
        log error "Don't get the gettop, please check it ..."
    fi
}

## 切换至gettop目录下
function cd_to_gettop() {

    get_manifest_branch_name_from_zen

    workspace=${WORKSPACE}/${manifest_path}/android
    if [[ ! -d ${workspace} ]]; then
        mkdir -p ${workspace}
    fi

    if [[ -n ${workspace} && -d ${workspace} ]]; then
        cd ${workspace} > /dev/null

        gettop_p=`pwd`
    else
        log error "The workspace path no found."
    fi
}

## 下载更新APK仓库
function download_and_update_apk_repository()
{
    local OPWD=$(pwd)
    local GITRES=""
    local GITRES_BRANCH=""
    local GITRES_PATH=""

    if [[ ! -d ${tmpfs} ]]; then
        mkdir -p ${tmpfs}
    fi

    if [[ "$1" ]]; then
        GITRES=$1
    else
        __err "参数1为空."
    fi

    if [[ "$2" ]]; then
        GITRES_BRANCH=$2
    else
        __err "参数2为空."
    fi

    if [[ "$3" ]]; then
        GITRES_PATH=$3
    else
        GITRES_PATH=${tmpfs}
    fi

    if [[ "$#" -gt 3 || "$#" -lt 2 ]]; then
        echo ""
        echo "download_and_update_repository options [ string ] "
        echo
        echo "    options : "
        echo "      download_and_update_repository git_path git_branch  更新代码仓库."
        echo
        echo "    e.g. download_and_update_repository nxos/nxTraffic yunovo/nxos/nxTraffic/master"
        echo
        return 1
    fi

    show_vip "update [ repository|branch|path ] ==> [ ${GITRES##*/}|${GITRES_BRANCH}|${GITRES_PATH}/${GITRES##*/}] ..."

    if [[ -d ${GITRES_PATH}/${GITRES##*/}/.git ]];then

        ## 恢复本来面目
        recover_standard_git_project "${GITRES_PATH}/${GITRES##*/}"

        cd ${GITRES_PATH}/${GITRES##*/} > /dev/null

        if [[ "${GITRES_BRANCH}" == "`git branch | grep \* | cut -d ' ' -f2`" ]]; then
            # 异常删除远程分支后存在问题. 当远程分支存在变化的时候,需要特殊出来
            if [[ "`check_remote_branch`" == "true" ]]; then
#                git fetch -q
#                git checkout master
#                git branch -D ${GITRES_BRANCH}

                git fetch -q
                git checkout ${GITRES_BRANCH}
                git pull
            else
                git pull
            fi
        else
            git fetch -q
            git checkout ${GITRES_BRANCH}
            git pull
        fi

        cd ${OPWD} > /dev/null
    else
        git clone -b ${GITRES_BRANCH} ${git_username}@${gerrit_server}:${gerrit_port}/${GITRES} ${GITRES_PATH}/${GITRES##*/}

        cd ${GITRES_PATH}/${GITRES##*/} > /dev/null

        gitdir=$(git rev-parse --git-dir); scp -p -P 29419 ${git_username}@${gerrit_server}:hooks/commit-msg ${gitdir}/hooks/

        cd ${OPWD} > /dev/null
    fi
}

## 恢复到干净工作区,每个项目仓库.
function recover_standard_git_project()
{
	local tDir=$1
	local OPWD=$(pwd)

	if [[ ! "$tDir" ]]; then
		tDir=.
	fi

	if [[ -d ${tDir}/.git ]]; then

		cd ${tDir} > /dev/null

        if [[ -n "`git status -s`" ]];then
            echo "---- recover ${tDir}"
        else
            cd ${OPWD} > /dev/null
            return 0
        fi

        thisFiles=`git diff --cached --name-only`
        if [[ -n "$thisFiles" ]];then
            git reset HEAD . ###recovery for cached files
        fi

		thisFiles=`git clean -dn`
		if [[ -n "$thisFiles" ]]; then
			git clean -df
		fi

		thisFiles=`git diff --name-only`
		if [[ -n "$thisFiles" ]]; then
			git checkout HEAD ${thisFiles}
		fi

		cd ${OPWD} > /dev/null
	fi
}

### 恢复到干净工作区, android目录下所有的git仓库.
function recover_standard_android_project()
{
	local project=`get_repo_git_path_from_xml`

	if [[ -n "$project" ]]; then
		for p in ${project}
		do
            if [[ -d $(gettop)/${p} ]];then
                recover_standard_git_project ${p}
            fi
		done
	fi
}

### 备份APP
function auto_create_refs_branch_for_app()
{
    local username=`git config --get user.name`
    local remotename=origin
    local refsname=${VER}

    if [[ "`git ls-remote --refs ${remotename} | grep ${refsname}`" ]];then
        _echo "--> $refsname is exist ."
    else
        git push ${remotename} HEAD:refs/build/${username}/${refsname}
    fi
}

### 备份源码
function create_refs_branch()
{
    local username=`git config --get user.name`
    local remotename=origin
    local refsname=${VER}
    local ls_remote_p=frameworks
    local is_create_refs=

    if [[ "`is_yunovo_server`" == "true" ]];then

        cd ${ls_remote_p} > /dev/null

        if [[ "`git ls-remote --refs ${remotename} | grep ${refsname}`" ]];then
            is_create_refs=true
        else
            is_create_refs=false
        fi

        cd - > /dev/null

        if [[ "$is_create_refs" == "true" ]];then
            _echo "--> $refsname is exist ..."
        else
            repo forall -c git push ${remotename} HEAD:refs/build/${username}/${refsname}

            __echo "create branch refs successful ..."
        fi
    else
        log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi
}

## 回写当前manifest
function auto_create_manifest()
{
    local remotename=
    local username=`git config --get user.name`
    local refsname=${VER}
    local groups_name="all,yunovo_adv"

    local manifest_path=.repo/manifests
    local manifest_default=default.xml
    local manifest_name=tmp.xml

    _echo "manifest branch name = $manifest_branchN"

    if [[ "`is_yunovo_server`" == "true" ]];then

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
                _echo "$manifest_default is not change ."
            fi
        else
            log error "The $manifest_name is not exist."
        fi

        cd - > /dev/null

        repo init -b ${manifest_branchN}
    else
       log error "The server is not running on s1 s3 s4 s5 s6 s7 happysongs."
    fi
}

## 给OTA构建者提供邮件的信息
function email_massage_to_ota_builder()
{
    ## 1.显示版本信息
    echo "OTA 构建信息 : " >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. 构建者     : ${build_builder}" >> ${logfs}
    echo "2. 服务器     : `hostname`" >> ${logfs}
    echo "3. 全路径     : ${OLDPWD}" >> ${logfs}
    echo "4. 工程名     : ${custom_project}" >> ${logfs}
    echo "5. 项目名     : ${custom_version}" >> ${logfs}
    echo "6. 版本的路径 : ${share_smb_ota_p}" >> ${logfs}
    echo "7. 当前分支名 : ${manifest_branchN}" >> ${logfs}
    echo "8. 构建编号   : ${BUILD_DISPLAY_NAME}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. type                 : ${build_type}" >> ${logfs}
    echo "2. device               : ${build_device}" >> ${logfs}
    echo "3. build_clean_data     : ${build_clean_data}" >> ${logfs}
    echo "4. build_update_code    : ${build_update_code}" >> ${logfs}
    echo "5. build_signature_type : ${build_signature_type}" >> ${logfs}
    echo "6. build_lk             : ${build_lk}" >> ${logfs}
    echo "7. build_preloader      : ${build_preloader}" >> ${logfs}
    echo "8. build_rom_type       : ${build_rom_type}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. yunovo_board         : ${yunovo_board}" >> ${logfs}
    echo "2. yunovo_custom        : ${yunovo_custom}" >> ${logfs}
    echo "3. yunovo_project       : ${yunovo_project}" >> ${logfs}
    echo "4. yunovo_form_version  : ${custom_project}/${custom_version}/${yunovo_form_version}" >> ${logfs}
    echo "5. yunovo_to_version    : ${custom_project}/${custom_version}/${yunovo_to_version}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. ota_previous         : ${ota_previous}" >> ${logfs}
    echo "2. ota_current          : ${ota_current}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. build_prj_name       : ${build_prj_name}" >> ${logfs}
    echo "2. custom_project       : ${custom_project}" >> ${logfs}
    echo "3. custom_version       : ${custom_version}" >> ${logfs}
    echo "4. software_prev_version: ${software_prev_version}" >> ${logfs}
    echo "5. software_curr_version: ${software_curr_version}" >> ${logfs}
    echo "6. firmware_prev_version: ${firmware_prev_version}" >> ${logfs}
    echo "7. firmware_curr_version: ${firmware_curr_version}" >> ${logfs}
    echo "8. OTA_FILE             : ${OTA_FILE}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. manifest branch      : ${manifest_branchN}" >> ${logfs}
    echo "2. manifest path        : ${manifest_path}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}

    ## 显示留言板
    if [[ -f ${WORKSPACE}/yunovo_versiondescription ]];then
        cat ${WORKSPACE}/yunovo_versiondescription >> ${logfs}
        echo >> ${logfs}
        echo "-------------------------------------------------" >> ${logfs}
        echo >> ${logfs}
    else
        __wrn "留言板未填写任何内容..."
    fi

    ## 备份jenkins build info
    if [[ -f ${logfs} ]]; then
        cp -vf ${logfs} ${tmpfs}/jenkins.ini
        cp -vf ${tmpfs}/jenkins.ini ${ota_version_path}
    fi

    if [[ -f ${logfs} ]];then
        cat ${logfs} >> ${diff_table}

        ## 清理临时文件
        if [[ $? -eq 0 ]];then
            rm -rf ${logfs} ${tmpfs}/jenkins.ini
        fi
    fi
}

## 给项目经理提供邮件的信息
function email_massage_to_apps()
{
    local tmp=${tmpfs}/.the.test.report.log

    echo > ${logfs}
    ## 应用名称
    for app in "${channel_app_name[@]}";
    do
        echo "<font size="5" color="\#FF0000">${app} </font>" >> ${logfs}
    done

    ## 1. 构建信息
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. 构建者 : ${build_builder}" >> ${logfs}
    echo "2. 服务器 : `hostname`" >> ${logfs}
    echo "3. 全路径 : `pwd`" >> ${logfs}
    echo "4. 项目名 : ${job_name}" >> ${logfs}
    echo "4. 仓库名 : ${build_repository_name}"  >> ${logfs}
    echo "5. 分支名 : ${build_repository_branch}" >> ${logfs}
    echo "6. 渠道号 : ${build_multi_channel[@]}" >> ${logfs}
    echo "7. ROM版本: ${matchup[@]}" >> ${logfs}
    echo "8. 版本路径 : ${share_smb_app_p}" >> ${logfs}
    echo "9. 构建编号: ${BUILD_DISPLAY_NAME}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}

    ## 2. 修改信息,主要是git修改点
    echo "Modify, see details in readme.log:" >> ${logfs}
    echo >> ${logfs}
    echo "------------------------------------ $BUILD_DISPLAY_NAME" >> ${logfs}

    if [[ -n "${GIT_PREVIOUS_COMMIT}" && -n "${GIT_COMMIT}" ]]; then
        git log ${GIT_PREVIOUS_COMMIT}..${GIT_COMMIT} --pretty=format:'    %h -%d %s (%ci) <%an>' >> ${logfs}
        echo >> ${logfs}
        echo "-------------------------------------------------" >> ${logfs}
        echo >> ${logfs}
    fi

    ## 3. 测试报告
    if [[ ${build_deploy} == "true" ]]; then

        echo "${job_name} 测试报告:" >> ${logfs}
        echo "_____________________________________________________________________________________________________________________________" >> ${logfs}
        echo "|   id     渠道号     ROM版本                   系统版本                   测试结果                 md5                     |" >> ${logfs}
        echo "|___________________________________________________________________________________________________________________________|" >> ${logfs}

        # 清理临时文件的内容
        echo > ${tmp}

        for report in ${test_report[@]} ; do
            echo ${report} >> ${tmp}
        done

        cat ${tmp} > ${tmpfs}.tmp.log
        column -t -s ';' ${tmpfs}.tmp.log > ${tmp}
    else
        echo > ${tmp}
    fi

    if [[ -f "$logfs"  ]];then
        cat ${logfs} ${tmp} >> ${diff_table}

        if [[ ${build_deploy} == "true" ]]; then
            echo "|___________________________________________________________________________________________________________________________|" >> ${diff_table}
        fi

        echo >> ${diff_table}

        ## 清理临时文件
        if [[ $? -eq 0 ]];then
            rm -rf ${logfs} ${tmp}
        fi
    else
        __err "The $logfs or the $tmp no found !"
    fi
}

## 给项目经理提供邮件的信息
function email_massage_to_project()
{
    local OLDPWD=`pwd`

    ##输出硬件信息
    local drive_config_mk=${ROOT}/yunovo/NxCustomConfig/${yunovo_custom}/${yunovo_project}/drive.mk
    local endV=${VER}

    ## 1.显示版本信息
    echo ${endV} > ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. 构建者 : ${build_builder}" >> ${logfs}
    echo "2. 服务器 : `hostname`" >> ${logfs}
    echo "3. 全路径 : ${OLDPWD}" >> ${logfs}
    echo "4. 工程名 : ${project_name}" >> ${logfs}
    echo "5. 项目名 : ${custom_version}" >> ${logfs}
    echo "6. 版本号 : ${build_version}" >> ${logfs}
    echo "7. 客制化路径 : ${prefect_name}" >> ${logfs}
    echo "8. 系统版本号 : ${system_version}" >> ${logfs}
    echo "9. 版本的路径 : ${share_smb_p}" >> ${logfs}
    echo "10.当前分支名 : ${manifest_branchN}" >> ${logfs}
    echo "11.构建编号: ${BUILD_DISPLAY_NAME}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. 工程名称 : ${lunch_project}" >> ${logfs}
    echo "2. 清除编译 : ${build_clean}" >> ${logfs}
    echo "3. 更新代码 : ${build_update_code}" >> ${logfs}
    echo "4. 编译OTA  : ${build_make_ota}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. type         : ${build_type}" >> ${logfs}
    echo "2. device       : ${build_device}" >> ${logfs}
    echo "3. update-api   : ${build_update_api}" >> ${logfs}
    echo "4. update code  : ${build_update_code}" >> ${logfs}
    echo "5. compile para : ${compile_para[@]}" >> ${logfs}
    echo "6. test version : ${is_test_version}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}

    ## 2.显示硬件参数
    if [[ -f ${drive_config_mk} ]];then
        cat ${drive_config_mk} >> ${logfs}

        echo >> ${logfs}
        echo "-------------------------------------------------" >> ${logfs}
        echo >> ${logfs}
    else
        __err "HardWareConfig.mk or drive.mk no found !"
    fi

    ## 3. 显示留言板
    if [[ -f ${WORKSPACE}/yunovo_versiondescription ]];then
        cat ${WORKSPACE}/yunovo_versiondescription >> ${logfs}
        echo >> ${logfs}
        echo "-------------------------------------------------" >> ${logfs}
        echo >> ${logfs}
    else
        __wrn "留言板未填写任何内容..."
    fi

    if [[ -f ${logfs} ]];then
        cat ${logfs} >> ${diff_table}

        ## 清理临时文件
        if [[ $? -eq 0 ]];then
            rm -r ${logfs}
        fi
    fi
}

## 发送给开发部门的邮件内容
function email_massage_to_development()
{
    local OLDPWD=`pwd`

    ##临时保持文件
    local output_diff_log=${tmpfs}/diffmanifests.log

    ##当前项目与对比项目路径
    local manifest_path=.repo/manifests
    local manifest_path_old=yunovo/diffmanifests

    ##对应的文件和git路径
    local old_manifestfs=${manifest_path_old}/default.xml
    local old_manifest_git_path=${manifest_path_old}/.git

    ##对应的default.xml
    local diff_xml=diff.xml

    ## 输出硬件配置参数信息
    local hardware_config_mk=${ROOT}/${DEVICE}/HardWareConfig.mk
    local drive_config_mk=${ROOT}/yunovo/NxCustomConfig/${yunovo_custom}/${yunovo_project}/drive.mk

    ## 输出当前版本与对比版本的信息
    local startV=""
    local endV=${VER}

    if [[ -d "$old_manifest_git_path" ]];then
        startV=`git --git-dir=${old_manifest_git_path} lg -1 | awk '{print $(NF-2)}'`
    fi

    show_vig "@@@ start: $startV -> $endV"

    ## 1.显示版本信息
    echo ${startV} "->" ${endV} > ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. 构建者 : ${build_builder}" >> ${logfs}
    echo "2. 服务器 : `hostname`" >> ${logfs}
    echo "3. 全路径 : ${OLDPWD}" >> ${logfs}
    echo "4. 工程名 : ${project_name}" >> ${logfs}
    echo "5. 项目名 : ${custom_version}" >> ${logfs}
    echo "6. 版本号 : ${build_version}" >> ${logfs}
    echo "7. 客制化路径 : ${prefect_name}" >> ${logfs}
    echo "8. 系统版本号 : ${system_version}" >> ${logfs}
    echo "9. 版本的路径 : ${share_smb_p}" >> ${logfs}
    echo "10.当前分支名 : ${manifest_branchN}" >> ${logfs}
    echo "11.构建编号: ${BUILD_DISPLAY_NAME}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. 工程名称 : ${lunch_project}" >> ${logfs}
    echo "2. 清除编译 : ${build_clean}" >> ${logfs}
    echo "3. 更新代码 : ${build_update_code}" >> ${logfs}
    echo "4. 编译OTA  : ${build_make_ota}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}
    echo "1. type         : ${build_type}" >> ${logfs}
    echo "2. device       : ${build_device}" >> ${logfs}
    echo "3. update-api   : ${build_update_api}" >> ${logfs}
    echo "4. update code  : ${build_update_code}" >> ${logfs}
    echo "5. compile para : ${compile_para[@]}" >> ${logfs}
    echo "6. test version : ${is_test_version}" >> ${logfs}
    echo "-------------------------------------------------" >> ${logfs}
    echo >> ${logfs}

    ## 2.显示硬件参数
    if [[ -f ${hardware_config_mk} ]];then

        ##　将硬件参数发以邮件发送通知研发部
        cat ${hardware_config_mk} >> ${logfs}

        echo >> ${logfs}
        echo "-------------------------------------------------" >> ${logfs}
        echo >> ${logfs}
    elif [[ -f ${drive_config_mk} ]];then
        cat ${drive_config_mk} >> ${logfs}

        echo >> ${logfs}
        echo "-------------------------------------------------" >> ${logfs}
        echo >> ${logfs}
    else
        if [[ "`is_zen_project`" == "true" ]]; then
            log warn "The HardWareConfig.mk or drive.mk file no found ..."
        fi
    fi

    ## 3. 显示留言板
    if [[ -f ${WORKSPACE}/yunovo_versiondescription ]];then
        cat ${WORKSPACE}/yunovo_versiondescription >> ${logfs}
        echo >> ${logfs}
        echo "-------------------------------------------------" >> ${logfs}
        echo >> ${logfs}
    else
        if [[ "`is_zen_project`" == "true" ]]; then
            log warn "请在留言板留言哦 ..."
        fi
    fi

    ## 备份jenkins build info
    if [[ -f ${logfs} ]]; then
        cp -f ${logfs} ${tmpfs}/jenkins.ini

        if [[ "`is_zen_project`" == "true" ]]; then
            # 备份信息打包进系统中.
            cp -f ${tmpfs}/jenkins.ini ${YUNOVO_ROOT}/${YUNOVO_BUILD}/${YUNOVO_COMMON}/system/etc
        fi
    else
        log error "The ${logfs} file not found ..."
    fi

    ##拷贝比较项目的default.xml至当前项目下,重命名diff.xml
    if [[ -f "$old_manifestfs" ]];then
        cp ${old_manifestfs} ${manifest_path}/${diff_xml}

        if [[ -f "$manifest_path/$diff_xml" ]];then
            #repo diffmanifests --pretty-format="%C(yellow)%h %Creset%s %C(red)<%an> %C(green)(%ci)" ${diff_xml} > ${output_diff_log}
            repo diffmanifests ${diff_xml} > ${output_diff_log}
            cat ${logfs} ${output_diff_log} >> ${diff_table}

            ## 清理临时文件
            if [[ $? -eq 0 ]];then
                rm ${logfs} ${output_diff_log} ${manifest_path}/${diff_xml}
            fi
        else
            log warn "The yunovo/diffmanifests/default.xml file not found ..."
        fi
    else
        if [[ "`is_zen_project`" == "true" ]]; then
            log warn "The old manifest <default.xml> file no found ..."
        fi
    fi
}

## 给邮件内容着色,看起来会非常清晰.
function email_massage_has_colors()
{
    local email_content="$tmpfs/${DFN}.html"

    if [[ -f ${diff_table} ]];then

    cat >>  ${email_content} << EOF
    <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        </head>
        <body>
        <pre>
EOF

    cat ${diff_table} >> ${email_content}

    ## 标题上版本->当前版本
    sed -i 's#\[32m\(.*\)#<font size="5" color="\#FF0000">\1</font> #g' ${email_content}
    sed -i 's/'`echo -e "\033"`'//g' ${email_content}

    ## [-] red
    sed -i 's#\[1\;31m\(.*\)\[m\[#<font color="\#FF1493">\1</font> #g' ${email_content}

    ## [+] green
    sed -i 's#\[1\;32m\(.*\)\[m\[#<font color="\#32CD32">\1</font> #g' ${email_content}

    ## 长的HASH值 yellow
    sed -i 's#\[m\[33m\(.*\)\[m #<font color="\#FFA500">\1</font> #g' ${email_content}

    ## 分支名
    sed -i 's#\[m\[33m\(.*\)\[m#<font color="\#0000FF">\1</font> #g' ${email_content}

    ## 短的HASH值
    sed -i 's#33m\(.*\)\[m #<font color="\#FFA500">\1</font> #g' ${email_content}

    ## 代码目录结构
    sed -i 's#\[1m\(.*\)\[m#<font color="\#DC143C">\1</font> #g' ${email_content}

    ## 去掉多余的结尾符
    sed -i 's#\[m##g' ${email_content}

    cat >> ${email_content} << EOF
    </pre>
    </body>
    </html>
EOF

        ## 清除临时文件
        if [[ -f ${diff_table} ]];then
            rm -r ${diff_table}
        fi
    fi
}

usage() {
    echo >&2 "Usage: touch_android_mk apk文件名 ..."
    echo
    echo >&2 "   eg: touch_android_mk Launcher3.apk"
    return 1
}

function touch_android_mk()
{
    local APK_NAME=""

    local LIBS='LOCAL_PREBUILT_JNI_LIBS := \'
    local BUILDS='include $(BUILD_PREBUILT)'

    test $# -gt 0 || usage

    if [[ -n "$1" && $# -eq 1 ]]; then
        APK_NAME=$1
    fi

    if [[ $# -eq 1 ]];then
        echo
        show_vip "--> create android.mk start ..."

        show_vig "APK_NAME = $APK_NAME"
    else
        __err "Please e.g touch_android_mk  \${name}.apk ..."
        return 1
    fi

    if [[ "${APK_NAME}" ]];then
        APK_NAME="${APK_NAME/%.apk/}"
    else
        return 1
    fi

    cat << EOF >> Android.mk
###################################################### ${APK_NAME}

include \$(CLEAR_VARS)
LOCAL_MODULE := ${APK_NAME}
LOCAL_MODULE_TAGS := optional
LOCAL_CERTIFICATE := ${build_signature_type}
LOCAL_MODULE_CLASS := APPS
LOCAL_SRC_FILES := \$(LOCAL_MODULE).apk
LOCAL_MODULE_SUFFIX := \$(COMMON_ANDROID_PACKAGE_SUFFIX)

EOF

    if [[ -n ${build_override_module} ]];then
        echo "LOCAL_OVERRIDES_PACKAGES := `echo ${build_override_module} | sed 's/;/ /g'`" >> Android.mk
        echo >> Android.mk
    fi

    if [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/arm64-v8a\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/arm64-v8a\/.*.so$/ { print $(NF) }' > ${tmpfs}/arm64_v8a.txt
    fi

    if [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi-v7a\/.*.so$/ { print $(NF) }' > ${tmpfs}/armeabi-v7a.txt
    elif [[ -n "`unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ { print $(NF) }'`" ]];then
        unzip -l ${APK_NAME}.apk | awk '$(NF) ~ /lib\/armeabi\/.*.so$/ { print $(NF) }' > ${tmpfs}/armeabi.txt
    fi

    if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then

        echo 'ifeq ($(strip $(TARGET_ARCH)), arm64)' >> Android.mk
        echo 'LOCAL_MULTILIB := 64' >> Android.mk
        echo 'endif' >> Android.mk
        echo >> Android.mk

        echo 'ifeq ($(strip $(TARGET_ARCH)), arm64)' >> Android.mk
        echo >> Android.mk
        echo ${LIBS} >> Android.mk

        while read lib_path;do
            echo "    @${lib_path} \\" >> Android.mk
            # print
            echo "${lib_path}"
        done < ${tmpfs}/arm64_v8a.txt
        echo >> Android.mk
        echo 'endif' >> Android.mk
        echo >> Android.mk
    fi

    if [[ -f ${tmpfs}/armeabi-v7a.txt || -f ${tmpfs}/armeabi.txt ]]; then

        if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then
            echo 'ifeq ($(strip $(TARGET_ARCH)), arm)' >> Android.mk
        else
            echo 'ifneq ($(strip $(filter $(TARGET_ARCH), arm arm64)), )' >> Android.mk
        fi

        echo 'LOCAL_MULTILIB := 32' >> Android.mk
        echo 'endif' >> Android.mk

        echo >> Android.mk
        if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then
            echo 'ifeq ($(strip $(TARGET_ARCH)), arm)' >> Android.mk
        else
            echo 'ifneq ($(strip $(filter $(TARGET_ARCH), arm arm64)), )' >> Android.mk
        fi
        echo >> Android.mk
        echo ${LIBS} >> Android.mk

        if [[ -f ${tmpfs}/armeabi-v7a.txt ]];then
            while read lib_path;do
                echo "    @${lib_path} \\" >> Android.mk
                # print
                echo "${lib_path}"
            done < ${tmpfs}/armeabi-v7a.txt
            echo >> Android.mk
            echo 'endif' >> Android.mk
            echo >> Android.mk
        elif [[ -f ${tmpfs}/armeabi.txt ]];then
            while read lib_path;do
                echo "    @${lib_path} \\" >> Android.mk
                # print
                echo "${lib_path}"
            done < ${tmpfs}/armeabi.txt
            echo >> Android.mk
            echo 'endif' >> Android.mk
            echo >> Android.mk
        fi
    fi

    if [[ -f ${tmpfs}/arm64_v8a.txt ]]; then
        rm ${tmpfs}/arm64_v8a.txt
    fi

    if [[ -f ${tmpfs}/armeabi-v7a.txt ]];then
        rm ${tmpfs}/armeabi-v7a.txt
    fi

    if [[ -f ${tmpfs}/armeabi.txt ]];then
        rm ${tmpfs}/armeabi.txt
    fi

    echo ${BUILDS} >> Android.mk
    echo >> Android.mk

    echo
    show_vip "--> create android.mk end ..."
}
