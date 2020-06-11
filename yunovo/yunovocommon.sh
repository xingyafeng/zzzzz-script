#!/bin/bash

####################################################### define
## env
export rom_p=/public/share/ROM
export otafs_p=${rom_p}/otafs

## define common variable
td=${workspace_p}/date/`date +%m%d`
app_p=${workspace_p}/app
share_p=${workspace_p}/share
manifest_p=${workspace_p}/app/manifest

################################################### function

### shortcut for cd
function cworkspace
{
    if [[ -d ${workspace_p} ]];then
	    cd ${workspace_p}
    else
        __err " $workspace_p no found !"
        return 1
    fi
}

function cjobs
{
    local jobs_p=~/jobs

    if [[ -d ${jobs_p} ]];then
	    cd ${jobs_p}
    else
        __err " $jobs_p no found !"
        return 1
    fi
}

function capp
{
    if [[ -d ${app_p} ]];then
	    cd ${app_p}
    else
        __err " $app_p no found !"
        return 1
    fi
}

function cmanifest
{
    if [[ -d ${manifest_p} ]];then
	    cd ${manifest_p}
    else
        __err " $manifest_p no found !"
        return 1
    fi
}

function cshare
{
    local hostN=`hostname`

    case ${hostN} in

        s1)

            if [[ -d ${share_p} ]];then
                cd ${share_p}
            else
                __err "$share_p no found !"
                return 1
            fi
            ;;

        *)
            if [[ -d ${share_p} ]];then
                cd ${share_p}
            else
                __err "$share_p no found !"

            fi
            return 1
            ;;
    esac
}

function cscript
{
    if [[ -d ${script_p} ]];then
	    cd ${script_p}
    else
        __err " $script_p no found !"
        return 1
    fi
}

function cdate
{
    if [[ -d ${td} ]];then
	    cd ${td}
    else
        __err " $td no found !"
        return 1
    fi
}

function crom
{

    if [[ -d ${rom_p} ]];then
        \cd ${rom_p}
    else
        __err " $rom_p no found !"
        return 1
    fi

}

