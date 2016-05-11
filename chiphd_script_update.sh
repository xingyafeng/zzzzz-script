#!/bin/bash
############################################################
# show help
function update-chiphd-script() {
	local ooldPwd=$(cd -)
	local nowPwd=$(pwd)

	#local mytop=$(gettop)
	local scriptDir=~/workspace/script/zzzzz-script

	if [ -d ${scriptDir}/.git ]; then
		cd ${scriptDir} &&  git pull
	else
if false;then
		cd ${mytop}/device/softwinner && rm -rf zzzzz-chiphd
		[ $? = 0 ] || (cd $ooldPwd && cd $nowPwd && return 0)   #³ö´í·µ»Ø
		local ScriptUpdatePath=/home2/builder/release/chiphd_script/zzzzz-chiphd
		if [ ${MY_IP_ADDR} != ${CHIPHD_LICHEE_IP} ]; then
			ScriptUpdatePath=${CHIPHD_LICHEE_USER}@${CHIPHD_LICHEE_IP}:${ScriptUpdatePath}
		fi
		git clone $ScriptUpdatePath
fi
    fi
	echo "source again, please"

	cd $ooldPwd && cd $nowPwd
}
#############################################################
## end for this script file
#############################################################
