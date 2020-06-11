#!/bin/bash

# script
aux_p=${script_p}/extend
config_p=${script_p}/config
yunovo_p=${script_p}/yunovo
jenkins_p=${script_p}/jenkins
gerrit_p=${script_p}/gerrit

# jenkins build
source ${jenkins_p}/yunovo_show.sh
source ${jenkins_p}/yunovo_build.sh
source ${jenkins_p}/yunovo_common.sh
source ${jenkins_p}/yunovo_tools.sh
source ${jenkins_p}/yunovo_git_func.sh
source ${jenkins_p}/yunovo_simple_func.sh

# jenkins extend
source ${jenkins_p}/extend/yunovo_jenkins_function.sh

# gerrit
source ${gerrit_p}/yunovo_ssh_gerrit.sh

# yunovo local script
source ${yunovo_p}/yunovocommon.sh
source ${yunovo_p}/yunovo_config.sh
source ${yunovo_p}/yunovo_misc.sh
source ${yunovo_p}/yunovo_alias.sh
source ${yunovo_p}/yunovo_git_misc.sh
source ${yunovo_p}/yunovohelp.sh

# auxiliary tools
source ${aux_p}/clone_project.sh
source ${aux_p}/auto_create_manifest.sh
source ${aux_p}/auto_create_android_mk.sh

# Abandoned
source ${script_p}/chiphd/chiphd_adb_shell.sh
#source ${script_p}/chiphd/chiphd_make_android.sh
#source ${script_p}/chiphd/chiphd_make_lichee.sh
#source ${script_p}/chiphd/chiphd_make_ota.sh
