#!/usr/bin/env bash

function tct::utils::get_manifest_branch() {

    local branch=

    if [[ -n ${build_tmpbranch} ]]; then
        branch=${build_tmpbranch}
    else
        branch=$(${tmpfs}/tools_int/bin/${getprojectinfo} ${PLATFORM} ${build_version:0:3}X -Branch)
    fi

    echo ${branch}
}

function tct::utils::get_build_project() {

    local build_project=
    build_project=$(${tmpfs}/tools_int/bin/${getprojectinfo} ${PLATFORM} ${build_version:0:3}X -QcomProject)
    echo ${build_project}
}

function tct::utils::get_project_name() {

    local project_name=
    project_name=$(${tmpfs}/tools_int/bin/${getprojectinfo} ${PLATFORM} ${build_version:0:3}X -Project)
    echo ${project_name}
}

function tct::utils::get_modem_project() {

    local modem_project=
    modem_project=$(${tmpfs}/tools_int/bin/${getprojectinfo} ${PLATFORM} ${build_version:0:3}X -SignScript)
    if [[ ${JOB_NAME} == "transformervzw" || ${JOB_NAME} == "irvinevzw" ]];then
        echo ${modem_project} | sed "s#vzw##"
    else
        echo ${modem_project}
    fi
}

function tct::utils::get_version_variant()
{
    local variant=

    case ${build_version:2:1} in

        'R')
            variant=driveronly
        ;;

        [W-Z])
            variant=mini
        ;;

        'S'|'T'|'U'|'V')
            variant=cert
        ;;

        *)
            case ${#build_version} in

                4)
                    variant=appli
                    ;;
                6)
                    variant=daily
                    ;;
                *)
                    log error "***** Not a valid version number: ${build_version}"
                    ;;
            esac
        ;;
    esac

    echo ${variant}
}

# 拿到编译modem类型
function tct::utils::get_moden_type() {

    case ${JOB_NAME} in

        transformervzw|dohatmo-r|irvinevzw)
            case ${VER_VARIANT} in

                appli)
                    modem_type=vzw
                    ;;

                mini)
                    modem_type=mini
                ;;

                cert)
                    modem_type=cert
                ;;

                *)
                    modem_type=vzw
                ;;
            esac
        ;;

        *)
            :
            ;;
    esac
}

# 拿到apk签名
function tct::utils::get_signapk_para() {

    case ${JOB_NAME} in

        transformervzw)
            case ${VER_VARIANT} in

                appli)
                    signapk="SIGNAPK_USE_RELEASEKEY=transformervzw"
                    ;;

                *)
                    :
                ;;
            esac
        ;;

        *)
            :
            ;;
    esac
}

function tct::utils::create_version_info() {

    local tmpversion=${tmpfs}/jenkins/${JOB_NAME}_${build_version}_tmpvesion.inc

    local security_efuse_flag=

    local main=${build_version:0:4}
    local security=0
    #local efuse=0
    local perso=${perso_num}
    local platform=${custo_name_platform}
    local extension=00

    if [[ ${build_efuse} == "true" ]]; then
        security_efuse_flag=1
    else
        security_efuse_flag=0
    fi

    if [[ ${VER_VARIANT} == "daily" ]]; then
        sub=${build_version:5:1}
        perso=0
    else
        sub=0
    fi

    echo "#define PARTITION_VER       \"P${main}${security}${perso}${sub}${platform}${extension}\""  > ${tmpversion}
    echo "#define PATCH_VER           \"Z${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define MODEM_VER           \"N${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define SBL1_VER            \"C${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define DEBUG_VER           \"D${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define GPTBAK_VER          \"G${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define GPTMAIN_VER         \"O${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define TZ_VER              \"T${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define RPM_VER             \"W${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define APPSBOOT_VER        \"L${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define ANDROID_BOOT_VER    \"B${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define ANDROID_SYS_VER     \"Y${main}${security}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}

    echo "#define ANDROID_USR_VER     \"U${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define RECOVERY_VER        \"R${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define PERSIST_VER         \"J${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define TCTPERSIST_VER      \"F${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define STUDY_PARA_VER      \"S${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define TUNING_PARA_VER     \"V${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define PERSO_VER           \"M${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define EFS_VER             \"H${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define SIMLOCK_VER         \"X${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}
    echo "#define PRODUCT_VER         \"O${main}${security_efuse_flag}${perso}${sub}${platform}${extension}\"" >> ${tmpversion}

#    if [[ ${#build_version} == "6" ]] || [[ ${PERSONUM} == "0" ]];then
#    	echo "#define vendor              \"Q${main}${security}${perso}${sub}${platform}${extension}\"" >> $tmpversion
#        echo "#define SIMLOCK_VER         \"X${main}${security}${perso}${sub}${platform}${extension}\"" >> $tmpversion
#        echo "#define LOGO_VER            \"L${main}${security}${perso}${sub}${platform}${extension}\"" >> $tmpversion
#    else
#    	echo "#define vendor              \"Q${main:0:3}ML${perso}${sub}${platform}${extension}\"" >> $tmpversion
#        echo "#define SIMLOCK_VER         \"X${main:0:3}ML${perso}${sub}${platform}${extension}\"" >> $tmpversion
#        echo "#define LOGO_VER            \"L${main:0:3}ML${perso}${sub}${platform}${extension}\"" >> $tmpversion
#    fi

    #下载version仓库


#    git_sync_repository ${versioninfo} ${build_manifest%.*}

    pushd ${tmpfs}/${version_path} > /dev/null

    if [[ -f version.inc ]]; then
        cp -vf ${tmpversion} version.inc
    fi

    show_vip "git push $(git remote) HEAD:${build_manifest%.*}"

    if [[ -n "`git status -s`" ]];then
        git add version.inc
        git commit -m "Release ${build_version}"
        git pull
        git push `git remote` HEAD:${build_manifest%.*}
    else
        log warn 'The version.inc do not update.'
    fi

    popd > /dev/null

    if [[ -f ${tmpversion} ]]; then
        rm -f ${tmpversion}
    fi
}

# 效验version.inc的正确性
function tct::utils::tct_check_version.inc() {

    local version_inc=
    local pwd_path=`pwd`

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        Command "repo sync -c -d --no-tags version"
    else
        #Command "git_sync_repository ${versioninfo} ${build_manifest} ${pwd_path}"
        Command "git clone git@shenzhen.gitweb.com:${versioninfo} -b ${build_manifest%.*} ${pwd_path}/version"
    fi

    version_inc=$(cat version/version.inc | awk '/ANDROID_SYS_VER/{ print $NF }')
    if [[ ${version_inc:2:4} != ${build_version:0:4} ]]; then
        log error "The version.inc file is error."
    fi
}

function tct::utils::create_manifest() {

    local PojectName=`tr '[A-Z]' '[a-z]' <<<${PROJECTNAME}`
    local comment="create int/${PojectName}/v${build_version}.xml by int_tool create_manifest"

    show_vip "comment: ${comment}"

    if [[ ! -d .repo/manifests/int/${PojectName} ]]; then
        mkdir -p .repo/manifests/int/${PojectName}
    fi

    Command repo manifest -r -o .repo/manifests/int/${PojectName}/v${build_version}.xml

    pushd .repo/manifests > /dev/null

    if [[ -n "$(git status -s)" ]]; then
        git add int/${PojectName}/v${build_version}.xml
        git commit -m "${comment}"
        git pull
        git push origin default:master
    else
        log warn "The v${build_version}.xml do not update."
    fi

	popd > /dev/null
}

# 备份版本
function tct::utils::backup_image_version() {

    if false; then
        log debug "Do not copy ..."
    else
        show_vip "start backup image version ..."
        #source_init

        local releasedir=
        local creat_time=
        local telewebdir_bak=
        local telewebdir=
        local productname=
        local beetlepath=

        Command "sh copyimgs.sh"


        releasedir=/local/release/${PROJECTNAME}-release/v${build_version}

        if [[ -f `ls out/target/product/*/vendor.img` ]];then
            productname=$(ls out/target/product/*/vendor.img | awk -F '/' '{print $(NF-1)" "$NF}' | awk '{print $1}')
        else
            productname=${PROJECTNAME}
        fi

        if [[ ${build_version:2:1} == "O" ]]; then
            if [[ -d ${teleweb_p}/${PROJECTNAME}/cts_version/v${build_version} ]]; then
                creat_time=`date +%Y%m%d%H%M -r ${teleweb_p}/${PROJECTNAME}/cts_version/v${build_version}`
            fi
        else
            if [[ -d ${teleweb_p}/${PROJECTNAME}/tmp/v${build_version} ]]; then
                creat_time=`date +%Y%m%d%H%M -r ${teleweb_p}/${PROJECTNAME}/tmp/v${build_version}`
            fi
        fi

        if [[ ${build_version:2:1} == "O" ]]; then
            if [[ $(is_build_debug) == 'true' ]]; then
             telewebdir=${teleweb_p}/${PROJECTNAME}/cts_version/v${build_version}_userdebug
             telewebdir_bak=${teleweb_p}/${PROJECTNAME}/cts_version/v${build_version}_userdebug_${creat_time}
           else
             telewebdir=${teleweb_p}/${PROJECTNAME}/cts_version/v${build_version}
             telewebdir_bak=${teleweb_p}/${PROJECTNAME}/cts_version/v${build_version}_${creat_time}
           fi
        elif [[ $(is_build_debug) == 'true' ]]; then
            telewebdir=${teleweb_p}/${PROJECTNAME}/userdebug/appli/v${build_version}
            telewebdir_bak=${teleweb_p}/${PROJECTNAME}/userdebug/appli/v${build_version}_${creat_time}
        else
            telewebdir=${teleweb_p}/${PROJECTNAME}/tmp/v${build_version}
            telewebdir_bak=${teleweb_p}/${PROJECTNAME}/tmp/v${build_version}_${creat_time}
        fi

        if [[ -d ${telewebdir} ]]; then
            Command "sudo mv ${telewebdir} ${telewebdir_bak}"
        fi

        #generate beetle_version.txt file
        if [[ ${VER_VARIANT} == "appli" ]]; then
            beetlepath=appli
        elif [[ ${VER_VARIANT} == "mini" ]]; then
            beetlepath=mini
        elif [[ ${VER_VARIANT} == "cert" ]]; then
            beetlepath=certification
        else
            echo "do nothing"
        fi

        if [[ ${JOB_NAME} == "transformervzw" ]]; then
            if [[ $(is_build_debug) == 'true' || ${#build_version} != "4" ]]; then
                show_vip "no need upload to beat web ..."
            else
                echo "python amss_nicobar_la2.0.1/vendor/script/collect_parameters.py -t ${PROJECTNAME}/$beetlepath/v$build_version -b $build_manifest -y false"
                python amss_4350_spf1.0/vendor/script/collect_parameters.py -t ${PROJECTNAME}/${beetlepath}/v${build_version} -b ${build_manifest} -y false
            fi
        fi

        if [[ ${VER_VARIANT} == "mini" ]]; then
            if [[ ${JOB_NAME} == "transformervzw" ]]; then
                cp amss_4350_spf1.0/vendor/tct/transformer/build/partition_load_pt/ufs/provision/provision_ufs22.xml out/target/product/${productname}/Teleweb/provision_ufs22.xml
            fi
            pushd out/target/product/${productname}/Teleweb/ > /dev/null
                zip -v _v${build_version}-Teleweb.zip *.*
            pushd > /dev/null
        fi

        Command "rm -rvf ${releasedir}"
        Command "mkdir -vp ${releasedir}"
        Command "sudo mkdir -vp ${telewebdir}"

        Command "cp -rfv out/target/product/${productname}/Teleweb/* ${releasedir}"
        Command "sudo cp -rfv out/target/product/${productname}/Teleweb/* ${telewebdir}"

        Command "chmod -R 0755 ${releasedir}"
        Command "sudo chmod -R 0755 ${telewebdir}"



        show_vip "copyimage end ... "

    fi
}

function tct::utils::downlolad_tools() {

    local branch=${build_manifest}

    # 下载 tools_int and version
    if [[ $(is_thesame_server) == 'true' ]]; then
        case ${object} in
            'target_download'|'ap'|'download')
                git_sync_repository alps/tools_int master
                git_sync_repository ${versioninfo} ${branch}
            ;;
        esac
    else
        git_sync_repository alps/tools_int master
        git_sync_repository ${versioninfo} ${branch}
    fi
}

# 拿到平台信息
function tct::utils::get_platform_info() {

    case ${JOB_NAME} in

        transformervzw|irvinevzw)
            PLATFORM=QC4350
        ;;

        portotmo-r)
            PLATFORM=QC6125
        ;;

        dohatmo-r)
            PLATFORM=MT6762
        ;;

        *)
            PLATFORM=''
        ;;
    esac
}

function tct::utils::get_perso_num() {

    local perso_num=

    case ${VER_VARIANT} in

        appli)
            perso_num=${build_version:3:1}
        ;;

        *)
            perso_num=0
        ;;
    esac

    echo ${perso_num}
}

function tct::utils::is_img_sign() {

    if [[ ${tct_efuse} == 'true' ]]; then
        echo true
    else
        echo false
    fi
}

# 获取version.inc仓库地址
function tct::utils::get_version_info() {

    local version_inc=

    case ${JOB_NAME} in

        transformervzw|portotmo-r|irvinevzw)
            version_inc=qualcomm/version
        ;;

        dohatmo-r)
            version_inc=mtk/version_cd
        ;;

        *)
            version_inc=''
        ;;
    esac

    echo ${version_inc}
}

function tct::utils::releasemail()
{
    if [[ ${VER_VARIANT} == "appli" ]] || [[ ${VER_VARIANT} == "mini" ]] || [[ ${VER_VARIANT} == "cert" ]]; then
        local basever=`python /local/tools_int/misc/getLastBigVersion.py -cur ${build_version}`

        if [[ ${build_version:3:1} == "1" ]]; then
            basever=${build_version}
        fi

        echo "curl -X POST -v 'http://10.129.93.215:8080/job/Auto-delivery-new/buildWithParameters?token=Auto-delivery-new&version=${build_version}&baseversion=${basever}&project=${PROJECTNAME}&build_server=${build_server_y}&delivery_bug=false&band=EU&BUILD_DUALSIM=false'"
        curl -X POST -v "http://10.129.93.215:8080/job/Auto-delivery-new/buildWithParameters?token=Auto-delivery-new&version=${build_version}&baseversion=${basever}&project=${PROJECTNAME}&build_server=${build_server_y}&delivery_bug=false&band=EU&BUILD_DUALSIM=false"
    fi

    if [[ ${VER_VARIANT} == "daily" ]]; then
        local lastversion=`/local/tools_int/misc/getLastDailyNumber2.py -cur ${build_version}`

        echo 'Send release mail ...'

        if [[ "${lastversion:5:1}" != 0 ]]; then
            basever=${lastversion}
        else
            basever=${lastversion:0:4}
        fi

        /local/tools_int/bin/superspam_new -user hudson.adm# -project ${PROJECTNAME} -version ${build_version} -base ${basever} -sendto all -mailpassword 12345678
	    if [[ $? -ne 0 ]]; then
	        log error "releasemail fail ..."
	    fi
    fi
}

# 拿到项目信息
function tct::utils::get_project_info() {

    case ${JOB_NAME} in

        transformervzw|portotmo-r|irvinevzw)
            getprojectinfo=Qcom_C_GetVerInfo
        ;;

        dohatmo-r)
            getprojectinfo=GetVerInfo
        ;;

        *)
            :
        ;;
    esac
}

function tct::utils::build_userdebug() {

    case ${JOB_NAME} in

        transformervzw)
            echo "curl -X POST -v http://10.129.93.215:8080/job/transformervzw/buildWithParameters?token=transformervzw&tct_version=${build_version}&tct_server_y=${build_server_x}&tct_update_code=${build_update_code}&tct_anti_rollback=${build_anti_rollback}&tct_type=userdebug&tct_clean=${build_clean}&&tct_tmpbranch=${build_tmpbranch}"
            curl -X POST -v "http://10.129.93.215:8080/job/transformervzw/buildWithParameters?token=transformervzw&tct_version=${build_version}&tct_server_y=${build_server_x}&tct_update_code=${build_update_code}&tct_anti_rollback=${build_anti_rollback}&tct_type=userdebug&tct_clean=${build_clean}&&tct_tmpbranch=${build_tmpbranch}"
        ;;

        dohatmo-r)
            echo "curl -X POST -v http://10.129.93.215:8080/job/dohatmo-r/buildWithParameters?token=dohatmo-r&tct_version=${build_version}&tct_server_y=${build_server_x}&tct_update_code=${build_update_code}&tct_anti_rollback=${build_anti_rollback}&tct_type=userdebug&tct_clean=${build_clean}&&tct_tmpbranch=${build_tmpbranch}"
            curl -X POST -v "http://10.129.93.215:8080/job/dohatmo-r/buildWithParameters?token=dohatmo-r&tct_version=${build_version}&tct_server_y=${build_server_x}&tct_update_code=${build_update_code}&tct_anti_rollback=${build_anti_rollback}&tct_type=userdebug&tct_clean=${build_clean}&&tct_tmpbranch=${build_tmpbranch}"
        ;;

        *)
            :
        ;;
    esac
}

# 生成version.inc文件
function tct::utils::create_versioninfo(){

    show_vip "create version.inc start ..."
    tct::utils::create_version_info
    tct::utils::tct_check_version.inc
    show_vip "create version.inc end ..."
}

# 设置版本序列倒数第三，第四位
function tct::utils::custo_name_platform() {

    local custo_name_platform=

    case ${JOB_NAME} in

        transformervzw|dohatmo-r|irvinevzw)
            custo_name_platform=DQ
        ;;

        *)
            custo_name_platform=DH
        ;;
    esac

    echo ${custo_name_platform}
}