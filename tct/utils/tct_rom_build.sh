#!/usr/bin/env bash

function tct::utils::get_manifest_branch() {

    local branch=

    if [[ -n ${build_tmpbranch} ]]; then
        branch=${build_tmpbranch}
    else
        branch=$(/local/tools_int/bin/${getprojectinfo} ${PLATFORM} ${build_version:0:3}X -Branch)
    fi

    echo ${branch}
}

function tct::utils::get_build_project() {

    local build_project=
    build_project=$(/local/tools_int/bin/${getprojectinfo} ${PLATFORM} ${build_version:0:3}X -QcomProject)
    echo ${build_project}
}

function tct::utils::get_project_name() {

    local project_name=
    project_name=$(/local/tools_int/bin/${getprojectinfo} ${PLATFORM} ${build_version:0:3}X -Project)
    echo ${project_name}
}

function tct::utils::get_modem_project() {

    local modem_project=
    modem_project=$(/local/tools_int/bin/${getprojectinfo} ${PLATFORM} ${build_version:0:3}X -SignScript)
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


    git_sync_repository ${versioninfo} ${build_manifest%.*}

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
        #local perso_build_name=$(tct::utils::perso_build_name)
        local teleweb_img_name=$(tct::utils::teleweb_img_name)
        local img_arr=
        local perso_build_name=
        
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
        elif [[ ${build_version:2:1} == "R" ]]; then
            if [[ -d ${teleweb_p}/${PROJECTNAME}/driveronly/v${build_version} ]]; then
                creat_time=`date +%Y%m%d%H%M -r ${teleweb_p}/${PROJECTNAME}/driveronly/v${build_version}`
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
        elif [[ ${build_version:2:1} == "R" ]]; then
            telewebdir=${teleweb_p}/${PROJECTNAME}/driveronly/v${build_version}
            telewebdir_bak=${teleweb_p}/${PROJECTNAME}/driveronly/v${build_version}_${creat_time}
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
                echo "python amss_nicobar_la2.0.1/vendor/script/collect_parameters.py -t ${PROJECTNAME}/$beetlepath/v$build_version -b ${build_manifest%.*} -y false"
                python amss_4350_spf1.0/vendor/script/collect_parameters.py -t ${PROJECTNAME}/${beetlepath}/v${build_version} -b ${build_manifest%.*} -y false
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

        Command "rm -rf ${releasedir}"
        Command "mkdir -vp ${releasedir}"
        Command "sudo mkdir -vp ${telewebdir}"

        if [[ $(is_compile_mpcs) == 'true' ]]; then
            Command "cp -rf out/target/product/${productname}/Teleweb/${teleweb_img_name} ${releasedir}/${teleweb_img_name}"
            Command "cp -rf /local/tools_int/simlockimage/${PROJECTNAME}/* ${releasedir}/${teleweb_img_name}/"

            if [[ "${PROJECTNAME}" == "Doha_TMO" ]];then
                #arr_simlock=(tmo/simlock tmo/nosimlock ${perso_build_name}/simlock ${perso_build_name}/nosimlock)
                img_arr=(super.img vbmeta_system.img vbmeta_vendor.img tct_fota_meta.zip md1img-verified.img dfile_v${build_version}.zip MDDB_InfoCustomAppSrcP_MT6765_*.EDB)
                perso_build_name=boost
                pushd out_${perso_build_name}/target/product/${productname} > /dev/null
                for img in ${img_arr[@]} ; do
                   if [[ -f ${img} ]];then
                        Command "cp ${img} ${releasedir}/${teleweb_img_name}/${perso_build_name}_${img}"
                    fi 
                done

                popd > /dev/null

                tct::utils::checksum tmo nosimlock
                show_vip "checksum tmo nosimlock end ... "

                tct::utils::checksum tmo simlock
                show_vip "checksum tmo simlock end ... "

                tct::utils::checksum ${perso_build_name} nosimlock
                show_vip "checksum ${perso_build_name} nosimlock end ... "

                tct::utils::checksum ${perso_build_name} simlock
                show_vip "checksum ${perso_build_name} simlock end ... "

                tct::utils::renameimage
                show_vip "renameimage end ... "

                Command "sudo cp -rfv ${releasedir}/* ${telewebdir}"

            fi


        else
            Command "cp -rfv out/target/product/${productname}/Teleweb/* ${releasedir}"
            Command "sudo cp -rfv out/target/product/${productname}/Teleweb/* ${telewebdir}"

        fi
        Command "chmod -R 0755 ${releasedir}"
        Command "sudo chmod -R 0755 ${telewebdir}"
        echo "copy to teleweb..."


        show_vip "copyimage end ... "

    fi
}

function tct::utils::downlolad_tools() {

    local branch=${build_manifest}

    # 下载 tools_int and version
    if [[ $(is_thesame_server) == 'true' ]]; then
        case ${object} in
            'target_download'|'ap'|'download')
                git_sync_repository alps/tools_int master /local
#                git_sync_repository ${versioninfo} ${branch}
            ;;
        esac
    else
        show_vip "git_sync_repository alps/tools_int master"
        git_sync_repository alps/tools_int master /local
#        git_sync_repository ${versioninfo} ${branch}
    fi
}

# 拿到平台信息
function tct::utils::get_platform_info() {

    case ${JOB_NAME} in

        transformervzw|irvinevzw)
            PLATFORM=QC4350
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

        transformervzw|irvinevzw)
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

        echo "curl -X POST -v 'http://10.129.93.215:8080/job/Auto-delivery-new/buildWithParameters?token=Auto-delivery-new&version=${build_version}&baseversion=${basever}&project=${PROJECTNAME}&build_server=${build_server_y}&delivery_bug=${build_delivery_bug}&band=EU&BUILD_DUALSIM=false'"
        curl -X POST -v "http://10.129.93.215:8080/job/Auto-delivery-new/buildWithParameters?token=Auto-delivery-new&version=${build_version}&baseversion=${basever}&project=${PROJECTNAME}&build_server=${build_server_y}&delivery_bug=${build_delivery_bug}&band=EU&BUILD_DUALSIM=false"
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

        transformervzw|irvinevzw)
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

        transformervzw|dohatmo-r|irvinevzw)
            echo "curl -X POST -v http://10.129.93.215:8080/job/${JOB_NAME}/buildWithParameters?token=${JOB_NAME}&${debug_variable}"
            curl -X POST -v "http://10.129.93.215:8080/job/${JOB_NAME}/buildWithParameters?token=${JOB_NAME}&${debug_variable}"
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

        transformervzw|irvinevzw)
            custo_name_platform=DQ
        ;;

        dohatmo-r)
            custo_name_platform=CX
        ;;

        *)
            custo_name_platform=DH
        ;;
    esac

    echo ${custo_name_platform}
}

# 设置appli&&userdebug版本参数
function tct::utils::handle_debug_compile_para() {
    local debug_compile_para=
    debug_compile_para[${#debug_compile_para[@]}]="tct_version=${build_version}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_baseversion=${build_baseversion}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_tmpbranch=${build_tmpbranch}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_type=userdebug&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_server_y=${build_server_x}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_anti_rollback=${build_anti_rollback}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_rsu_key=${build_rsu_key}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_update_code=${build_update_code}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_clean=${build_clean}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_efuse=${build_efuse}&"
    debug_compile_para[${#debug_compile_para[@]}]="tct_isship=${build_isship}&"

    case ${JOB_NAME} in

        transformervzw)

            debug_compile_para[${#debug_compile_para[@]}]="tct_enduser=${build_enduser}&"
        ;;

        *)
            :
        ;;
    esac
    echo ${debug_compile_para[@]}
}

#查看磁盘空间
function tct::utils::check_dist_space() {
    local space=
    space=`df -lh -B G /local | awk '{print $4}'| tail -1`
    show_vip "free space:${space}----${space%?}"
    if [[ ${space%?} -lt 500 ]]; then
        log error "there is no enough space left on device.there is only ${space} left."
    fi

}

# 判断是否更新GAPP
function tct::utils::is_update_gapp() {

    local is_update_gapp=

    case ${JOB_NAME} in

        transformervzw|dohatmo-r)
            is_update_gapp=true
        ;;

        irvinevzw)
            is_update_gapp=false
        ;;

        *)
            is_update_gapp=false
        ;;
    esac

    echo ${is_update_gapp}
}

function tct::utils::build_mpcs(){
    source_init
    case ${JOB_NAME} in
        dohatmo-r)
            Command "choosecombo 1 full_Doha_TMO ${build_type} false 1"
            Command "python build/make/makePerso.py -p Doha_TMO -a 'SIGNAPK_USE_RELEASEKEY=Doha_TMO SIGN_SECIMAGE_USEKEY=Doha_TMO MP_BRANCH_VALUE=1 ANTI_ROLLBACK=${build_anti_rollback}'"
            if [[ $? -eq 0 ]];then
                echo
                show_vip "--> make MPCS end ..."
                Command "mv out out_boost"
                Command "mv out_tmo out"

            else
                log error "--> make android MPCS failed !"
            fi
        ;;

        *)
            :
        ;;
    esac
    
}

function tct::utils::renameimage(){
    
    local image_name=
    local mbn_name=
    local originpath="../../${teleweb_img_name}"   

    local naming_rule_path=${root_p}/${job_name}Y/${build_manifest%.*}/out/target/product/${productname}/naming_rule.txt

    Command "rm -rf ${naming_rule_path}"
    Command "ls -lh out/target/product/${productname}/Teleweb | grep -E '.mbn|.db|.sca|.EDB|.ini' | cut -d ':' -f 2 | cut -d ' ' -f 2,4 | sort >> ${naming_rule_path}"
    image_name=`cat ${naming_rule_path} | cut -d ' ' -f 2 | cut -d '/' -f 2 | sort | uniq `

    Command "mkdir -vp ${releasedir}/${perso_build_name}/nosimlock"
    if [[ $? -eq 0 ]];then
        pushd ${releasedir}/${perso_build_name}/nosimlock > /dev/null
        for image in ${image_name}
        do
            mbn_name=`cat ${naming_rule_path} | grep "\<${image}\>" | cut -d ' ' -f 1`
            
            if [[ "${image}" == "simlock.img" ]]; then
                ln -s ${originpath}/${perso_build_name}_no_simlock.img $mbn_name                       
            elif [[ "${image}" == "Checksum.ini" ]]; then
                ln -s ${originpath}/${perso_build_name}_nosimlock_Checksum.ini $mbn_name
            
            elif [[ "${img_arr[@]}"  =~ "${image}" ]]; then
                Command "ln -s ${originpath}/${perso_build_name}_${image} $mbn_name"

            else
                ln -s ${originpath}/$image $mbn_name
            fi
        done
        if ls ${originpath}/${perso_build_name}_MDDB_InfoCustomAppSrcP_MT6765_*.EDB 1> /dev/null 2>&1; then
            Command "rm -rf `cat ${naming_rule_path} | grep -E '.EDB' | cut -d ' ' -f 1`"
            Command "ln -s ${originpath}/${perso_build_name}_MDDB_InfoCustomAppSrcP_MT6765_*.EDB `cat ${naming_rule_path} | grep -E '.EDB' | cut -d ' ' -f 1`"
        fi
        popd > /dev/null
    else
        log error "--> mkdir -vp ${releasedir}/${perso_build_name}/nosimlock failed !"
    fi
    
    Command "mkdir -vp ${releasedir}/${perso_build_name}/simlock"
    if [[ $? -eq 0 ]];then
        pushd ${releasedir}/${perso_build_name}/simlock > /dev/null
        for image in ${image_name}
        do
            mbn_name=`cat ${naming_rule_path} | grep "\<${image}\>" | cut -d ' ' -f 1`

            if [[ "${image}" == "simlock.img" ]]; then
                ln -s ${originpath}/${perso_build_name}_simlock.img $mbn_name
            elif [[ "${image}" == "Checksum.ini" ]]; then
                ln -s ${originpath}/${perso_build_name}_simlock_Checksum.ini $mbn_name

            elif [[ "${img_arr[@]}"  =~ "${image}" ]]; then
                Command "ln -s ${originpath}/${perso_build_name}_${image} $mbn_name"

            else
                ln -s ${originpath}/$image $mbn_name
            fi
        done
        if ls ${originpath}/${perso_build_name}_MDDB_InfoCustomAppSrcP_MT6765_*.EDB 1> /dev/null 2>&1; then
            Command "rm -rf `cat ${naming_rule_path} | grep -E '.EDB' | cut -d ' ' -f 1`"
            Command "ln -s ${originpath}/${perso_build_name}_MDDB_InfoCustomAppSrcP_MT6765_*.EDB `cat ${naming_rule_path} | grep -E '.EDB' | cut -d ' ' -f 1`"
        fi
        popd > /dev/null
    else
        log error "--> mkdir -vp ${releasedir}/${perso_build_name}/simlock failed !"
    fi

    Command "mkdir -vp ${releasedir}/tmo/nosimlock"
    if [[ $? -eq 0 ]];then
        pushd ${releasedir}/tmo/nosimlock > /dev/null
        for image in ${image_name}
        do
            mbn_name=`cat ${naming_rule_path} | grep "\<${image}\>" | cut -d ' ' -f 1`
            if [[ "${image}" == "simlock.img" ]]; then
                ln -s ${originpath}/tmo_no_simlock.img $mbn_name
            elif [[ "${image}" == "Checksum.ini" ]]; then
                ln -s ${originpath}/tmo_nosimlock_Checksum.ini $mbn_name
            else
                ln -s ${originpath}/$image $mbn_name
            fi
        done
        popd > /dev/null
    else
        log error "--> mkdir -vp ${releasedir}/tmo/nosimlock failed !"
    fi

    Command "mkdir -vp ${releasedir}/tmo/simlock"
    if [[ $? -eq 0 ]];then
        pushd ${releasedir}/tmo/simlock > /dev/null
        for image in ${image_name}
        do
            mbn_name=`cat ${naming_rule_path} | grep "\<${image}\>" | cut -d ' ' -f 1`
            if [[ "${image}" == "simlock.img" ]]; then
                ln -s ${originpath}/tmo_simlock.img $mbn_name
            elif [[ "${image}" == "Checksum.ini" ]]; then
                ln -s ${originpath}/tmo_simlock_Checksum.ini $mbn_name
            else
                ln -s ${originpath}/$image $mbn_name
            fi
        done
        popd > /dev/null
    else
        log error "--> mkdir -vp ${releasedir}/tmo/simlock failed !"
    fi

}

# 设置perso项目的目录名
function tct::utils::perso_build_name() {

    local perso_build_name=

    case ${JOB_NAME} in

        dohatmo-r)
            perso_build_name=boost
        ;;

        irvinevzw)
            perso_build_name=MPCS
        ;;

        *)
            :
        ;;
    esac

    echo ${perso_build_name}
}

# 设置teleweb的目录名
function tct::utils::teleweb_img_name() {

    local teleweb_img_name=

    case ${JOB_NAME} in

        dohatmo-r)
            teleweb_img_name=flashtool
        ;;

        irvinevzw)
            teleweb_img_name=originfiles
        ;;

        *)
            :
        ;;
    esac

    echo ${teleweb_img_name}
}

#算MTK平台的checksum
function tct::utils::checksum(){
    
    local out_teleweb_path=out/target/product/${productname}/Teleweb/${teleweb_img_name}
    local out_boost_path=out_${perso_build_name}/target/product/${productname}

    if [[ "$1" == "tmo" ]]; then
        if [[ "$2" == "simlock" ]]; then
            Command "cp /local/tools_int/simlockimage/${PROJECTNAME}/tmo_simlock.img ${out_teleweb_path}/simlock.img"
        else
            Command "cp /local/tools_int/simlockimage/${PROJECTNAME}/tmo_no_simlock.img ${out_teleweb_path}/simlock.img"
        fi
        
    else
        if [[ "$2" == "simlock" ]]; then
            Command "cp /local/tools_int/simlockimage/${PROJECTNAME}/${perso_build_name}_simlock.img ${out_teleweb_path}/simlock.img"
        else
            Command "cp /local/tools_int/simlockimage/${PROJECTNAME}/${perso_build_name}_no_simlock.img ${out_teleweb_path}/simlock.img"
        fi

        for img in ${img_arr[@]} ; do
            if [[ -f ${out_boost_path}/${img} ]];then
                Command "cp ${out_boost_path}/${img} ${out_teleweb_path}/${img}"
            fi 
        done

        if ls ${out_boost_path}/MDDB_InfoCustomAppSrcP_MT6765_*.EDB 1> /dev/null 2>&1; then
            Command "rm -rf ${out_teleweb_path}/MDDB_InfoCustomAppSrcP_MT6765_*.EDB"
            Command "cp ${out_boost_path}/MDDB_InfoCustomAppSrcP_MT6765_*.EDB ${out_teleweb_path}"
        fi
        
        
    fi
    Command "${gettop_p}/build/make/tools/TCLCheckSum_v5.1844.00_linux/CheckSumScriptFile.sh ${gettop_p}/out/target/product/${productname}/Teleweb/${teleweb_img_name} ${gettop_p}"
    Command "cp ${gettop_p}/out/target/product/${productname}/Teleweb/${teleweb_img_name}/Checksum.ini ${releasedir}/${teleweb_img_name}/$1_$2_Checksum.ini"

}