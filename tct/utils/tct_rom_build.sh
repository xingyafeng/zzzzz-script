#!/usr/bin/env bash

function tct::utils::get_manifest_branch() {

    local branch=

    if [[ -n ${tct_tmpbranch} ]]; then
        branch=${tct_tmpbranch}
    else
        branch=$(${tmpfs}/tools_int/bin/Qcom_C_GetVerInfo ${PLATFORM} ${tct_version:0:3}X -Branch)
    fi

    echo ${branch}
}

function tct::utils::get_build_project() {

    local build_project=
    build_project=$(${tmpfs}/tools_int/bin/Qcom_C_GetVerInfo ${PLATFORM} ${tct_version:0:3}X -QcomProject)
    echo ${build_project}
}

function tct::utils::get_project_name() {

    local project_name=
    project_name=$(${tmpfs}/tools_int/bin/Qcom_C_GetVerInfo ${PLATFORM} ${tct_version:0:3}X -Project)
    echo ${project_name}
}

function tct::utils::get_modem_project() {

    local modem_project=
    modem_project=$(${tmpfs}/tools_int/bin/Qcom_C_GetVerInfo QC4350 ${tct_version:0:3}X -SignScript)
    echo ${modem_project}
}

function tct::utils::get_version_variant()
{
    local variant=

    case ${tct_version:2:1} in

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
            case ${#tct_version} in

                4)
                    variant=appli
                    ;;
                6)
                    variant=daily
                    ;;
                *)
                    log error "***** Not a valid version number: ${tct_version}"
                    ;;
            esac
        ;;
    esac

    echo ${variant}
}

function tct::utils::create_version_info() {

    echo 'ceate vesion ...'

    local tmpversion=/${tmpfs}/jenkins/${JOB_NAME}_${VERSION}_tmp_vesion.inc

    local main=${VERSION:0:4}
    local security=0
    #local efuse=0
    local perso=${PERSONUM}
    local platform=DQ
    local extension=00

    if [[ ${ISEFUSE} == "true" ]]; then
        security_efuse_flag=1
    else
        security_efuse_flag=0
    fi

    if [[ ${VER_VARIANT} == "daily" ]]; then
        sub=${VERSION:5:1}
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

#    if [[ ${#VERSION} == "6" ]] || [[ ${PERSONUM} == "0" ]];then
#    	echo "#define vendor              \"Q${main}${security}${perso}${sub}${platform}${extension}\"" >> $tmpversion
#        echo "#define SIMLOCK_VER         \"X${main}${security}${perso}${sub}${platform}${extension}\"" >> $tmpversion
#        echo "#define LOGO_VER            \"L${main}${security}${perso}${sub}${platform}${extension}\"" >> $tmpversion
#    else
#    	echo "#define vendor              \"Q${main:0:3}ML${perso}${sub}${platform}${extension}\"" >> $tmpversion
#        echo "#define SIMLOCK_VER         \"X${main:0:3}ML${perso}${sub}${platform}${extension}\"" >> $tmpversion
#        echo "#define LOGO_VER            \"L${main:0:3}ML${perso}${sub}${platform}${extension}\"" >> $tmpversion
#    fi

    git_sync_repository qualcomm/version master

    pushd ${tmpfs}qualcomm/version > /dev/null

    if [[ -f version.inc ]]; then
        cp -vf ${tmpversion} version.inc
    fi

    if [[ "`git status -s`" ]];then
        git add version.inc
        git commit -m "Release ${VERSION}"
        git push `git remote` HEAD:master
    else
        log error 'The version.inc do not update.'
    fi

    pushd > /dev/null

    if [[ -f ${tmpversion} ]]; then
        rm -f ${tmpversion}
    fi
}

function tct::utils::create_manifest()
{
    PojectName=`tr '[A-Z]' '[a-z]' <<<${PROJECTNAME}`
    comment="create int/${PojectName}/v${VERSION}.xml by int_tool create_manifest"
    echo "comment:$comment"


    repo manifest -r -o .repo/manifests/default.xml

    pushd .repo/manifests > /dev/null

    if [[ -n $(git status -s) ]]; then
        git add default.xml
        git commit -m "$comment"
        git push origin default:master
    else
        log warn 'The default.xml has not update.'
    fi

	pushd > /dev/null
}

function tct::utils::get_perso_num() {

    local perso_num=

    case ${VER_VARIANT} in

        appli)
            perso_num=${VERSION:3:1}
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