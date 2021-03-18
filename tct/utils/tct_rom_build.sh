#!/usr/bin/env bash

function tct::utils::get_manifest_branch() {

    local branch=

    if [[ -n ${build_tmpbranch} ]]; then
        branch=${build_tmpbranch}
    else
        branch=$(${tmpfs}/tools_int/bin/Qcom_C_GetVerInfo ${PLATFORM} ${build_version:0:3}X -Branch)
    fi

    echo ${branch}
}

function tct::utils::get_build_project() {

    local build_project=
    build_project=$(${tmpfs}/tools_int/bin/Qcom_C_GetVerInfo ${PLATFORM} ${build_version:0:3}X -QcomProject)
    echo ${build_project}
}

function tct::utils::get_project_name() {

    local project_name=
    project_name=$(${tmpfs}/tools_int/bin/Qcom_C_GetVerInfo ${PLATFORM} ${build_version:0:3}X -Project)
    echo ${project_name}
}

function tct::utils::get_modem_project() {

    local modem_project=
    modem_project=$(${tmpfs}/tools_int/bin/Qcom_C_GetVerInfo ${PLATFORM} ${build_version:0:3}X -SignScript)
    echo ${modem_project} | sed "s#${modem_type}##"
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

        transformervzw)
            case ${VER_VARIANT} in

                appli)
                    modem_type=vzw
                    ;;

                mini)
                    modem_type=mini
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
    local perso=${PERSONUM}
    local platform=DQ
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

    
    pushd ${tmpfs} > /dev/null
    
    if [[ -d version ]]; then
        Command "rm -rf version"
        if [[ $? -eq 0 ]];then
            show_vip "--> version deleted success ..."
        else
            log error "--> version deleted fail ..."
        fi
    fi    

    Command "git clone git@shenzhen.gitweb.com:${versioninfo}.git -b ${build_manifest}"    
    if [[ $? -eq 0 ]];then
        show_vip "--> version download success ..."
    else
        log error "--> version download fail ..."
    fi

    pushd ${tmpfs}/version > /dev/null

    if [[ -f version.inc ]]; then
        Command "cp -vf ${tmpversion} version.inc"
    fi

    show_vip "git push git remote HEAD:${build_manifest}"

    if [[ "`git status -s`" ]];then
        git add version.inc
        git commit -m "Release ${build_version}"
        git pull
        git push `git remote` HEAD:${build_manifest}
    else
        log warn 'The version.inc do not update.'
    fi

    pushd > /dev/null

    if [[ -f ${tmpversion} ]]; then
        Command "rm -f ${tmpversion}"
    fi
}

# 效验version.inc的正确性
function tct::utils::tct_check_version.inc() {

    local version_inc=

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        Command "repo sync -c -d --no-tags version"
    fi

    version_inc=$(cat version/version.inc | awk '/ANDROID_SYS_VER/{ print $NF }')
    if [[ ${version_inc:2:4} != ${build_version:0:4} ]]; then
        log error "The version.inc file is error."
    fi
}

function tct::utils::create_manifest()
{
    PojectName=`tr '[A-Z]' '[a-z]' <<<${PROJECTNAME}`
    comment="create int/${PojectName}/v${build_version}.xml by int_tool create_manifest"
    echo "comment:$comment"
    
    Command "rm -rf ./*.xml"    
    repo manifest -o v$build_version.xml -r --suppress-upstream-revision
    #repo manifest -r -o .repo/manifests/default.xml
    Command "cp -dpRv v$build_version.xml .repo/manifests/int/${PojectName}/"

    pushd .repo/manifests > /dev/null

    if [[ -n $(git status -s) ]]; then
        git add int/${PojectName}/v$build_version.xml
        git commit -m "$comment"
        git push origin default:master
    else
        log error 'create_manifest v$build_version.xml error.'
    fi

	pushd > /dev/null
}

# 备份版本
function tct::utils::backup_image_version() {

    if true; then
        log debug "start backup image version ..."
    else
        source_init

        sh copyimgs.sh

        releasedir=/local/release/${JOB_NAME}/v${VERSION}
        creat_time=`date +%Y%m%d%H%M -r /teleweb/${PROJECTNAME}/tmp/v${VERSION}`
        telewebdir_bak=/teleweb/${PROJECTNAME}/tmp/v${version}_${creat_time}
        telewebdir=/teleweb/${PROJECTNAME}/tmp/v${VERSION}

        if [[ -d ${telewebdir} ]]; then
            sudo mv ${telewebdir} ${telewebdir_bak}
        fi

        rm -rf ${releasedir}
        mkdir -vp ${releasedir}
        sudo mkdir -vp ${telewebdir}
        cp -rfv ${TOPDIR}/build/${JOB_NAME}/v${VERSION}/out/target/product/holi/Teleweb/* ${releasedir}
        sudo cp -rfv ${TOPDIR}/build/${JOB_NAME}/v${VERSION}/out/target/product/holi/Teleweb/* ${telewebdir}
        chmod -R 0755 ${releasedir}
        sudo chmod -R 0755 ${telewebdir}
    fi
}

function tct::utils::downlolad_tools() {

    # 下载 tools_int and version
    if [[ $(is_thesame_server) == 'true' ]]; then
        case ${object} in
            'target_download'|'ap')
                git_sync_repository alps/tools_int master
                git_sync_repository qualcomm/version master
            ;;
        esac
    else
        git_sync_repository alps/tools_int master
        git_sync_repository qualcomm/version master
    fi
}

# 拿到平台信息
function tct::utils::get_platform_info() {

    case ${JOB_NAME} in

        transformervzw)
            PLATFORM=QC4350
        ;;

        portotmo-r)
            PLATFORM=QC6125
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

        transformervzw)
            version_inc=/qualcomm/version
        ;;

        portotmo-r)
            version_inc=/qualcomm/version
        ;;

        *)
            version_inc=''
        ;;
    esac
    echo ${version_inc}
}
