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
    \cd ${workspace_p} > /dev/null
}

function cjobs
{
    local jobs_p=~/jobs

    check_if_dir_exists ${jobs_p}
    \cd ${jobs_p} > /dev/null
}

function capp
{
    local app_p=${workspace_p}/app

    check_if_dir_exists ${app_p}
    \cd ${app_p} > /dev/null
}

function cmanifest
{
    local manifest_p=${workspace_p}/app/manifest

    check_if_dir_exists ${manifest_p}
    \cd ${manifest_p} > /dev/null
}

function cshare
{
    local hostN=`hostname`
    local share_p=${workspace_p}/share

    case ${hostN} in

        *)
            check_if_dir_exists ${share_p}
            \cd ${share_p} > /dev/null
            ;;
    esac
}

function cscript
{
    check_if_dir_exists ${script_p}
    \cd ${script_p} > /dev/null
}

function cdate
{
    check_if_dir_exists ${td}
    \cd ${td} > /dev/null
}

function crom
{
    check_if_dir_exists ${rom_p}
    \cd ${rom_p} > /dev/null
}