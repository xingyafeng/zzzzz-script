#!/usr/bin/env bash

function _print() {
  echo
  echo " ########################################################################################### "
  echo " ###### sync yunos branch ${p} -- ${b} ###### "
  echo " ########################################################################################### "
  echo
}

function main() {

    local URI_P="ssh://dh_yunovo@gerrit-custom2.yunos.com:29418"
    local MANIFEST_P=`echo repo/pbase/platform repo/yunos/pad`

    for p in ${MANIFEST_P} ; do

        for b in `git ls-remote ${URI_P}/${p} | cut -f 2 | grep ^refs/heads | cut -d '/' -f 3` ; do

            _print

            if [[ -d .repo && -h aliyun && -h git ]];then
                repo init -u ${URI_P}/${p} -b ${b}
                repo sync
            else
                echo "currect path no aliyun code repositories ..."
            fi
        done
    done
}

main $@
