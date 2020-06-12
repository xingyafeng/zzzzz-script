#!/bin/bash

# script
aux_p=${script_p}/extend
config_p=${script_p}/config
yunovo_p=${script_p}/yunovo
jenkins_p=${script_p}/jenkins
gerrit_p=${script_p}/gerrit

# load jenkins script
for script in `find ${jenkins_p} -type f -name jenkins_*.sh` ; do

    case `basename ${script}` in

        jenkins_init.sh)
            continue
            ;;

        *)
            source ${script}
            ;;
    esac
done

# gerrit
source ${gerrit_p}/yunovo_ssh_gerrit.sh

# load yunovo script
for script in `find ${yunovo_p} -type f -name yunovo_*.sh` ; do

    case `basename ${script}` in

        yunovo_init.sh)
            continue
            ;;

        *)
            source ${script}
            ;;
    esac
done

# auxiliary tools
source ${aux_p}/clone_project.sh
source ${aux_p}/auto_create_manifest.sh
source ${aux_p}/auto_create_android_mk.sh

# Abandoned
source ${script_p}/chiphd/chiphd_adb_shell.sh
#source ${script_p}/chiphd/chiphd_make_android.sh
#source ${script_p}/chiphd/chiphd_make_lichee.sh
#source ${script_p}/chiphd/chiphd_make_ota.sh
