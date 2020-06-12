#!/bin/bash

####################################################### define

# ---------------------------------------- env
export rom_p=/public/share/ROM
export otafs_p=${rom_p}/otafs

# ---------------------------------------- common variable

# 时间文件夹
td=${workspace_p}/date/`date +%m%d`

################################################### function

# -------------------------------- shortcut for \cd

function cworkspace
{
    check_if_dir_exists ${workspace_p}
    if [[ $? -eq 0 ]]; then
        \cd ${workspace_p} > /dev/null
    fi
}

function cjobs
{
    local jobs_p=~/jobs

    check_if_dir_exists ${jobs_p}
    if [[ $? -eq 0 ]]; then
        \cd ${jobs_p} > /dev/null
    fi
}

function capp
{
    local app_p=${workspace_p}/app

    check_if_dir_exists ${app_p}
    if [[ $? -eq 0 ]]; then
        \cd ${app_p} > /dev/null
    fi
}

function cmanifest
{
    local manifest_p=${workspace_p}/app/manifest

    check_if_dir_exists ${manifest_p}
    if [[ $? -eq 0 ]]; then
        \cd ${manifest_p} > /dev/null
    fi
}

function cshare
{
    local hostN=`hostname`
    local share_p=${workspace_p}/share

    case ${hostN} in

        *)
            check_if_dir_exists ${share_p}
            if [[ $? -eq 0 ]]; then
                \cd ${share_p} > /dev/null
            fi
            ;;
    esac
}

function cscript
{
    check_if_dir_exists ${script_p}
    if [[ $? -eq 0 ]]; then
        \cd ${script_p} > /dev/null
    fi
}

function cdate
{
    check_if_dir_exists ${td}
    if [[ $? -eq 0 ]]; then
        \cd ${td} > /dev/null
    fi
}

function crom
{
    check_if_dir_exists ${rom_p}
    if [[ $? -eq 0 ]]; then
        \cd ${rom_p} > /dev/null
    fi
}