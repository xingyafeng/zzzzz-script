#!/bin/bash

function main()
{
    ssh-update-script
}

function ssh-update-script()
{
    local init_script=~/workspace/script/zzzzz-script/init_script.sh
    local portN=22

    local hostname=`echo zenportal jenkins`

    local ip_for_zenportal=`echo s1.y`
    local ip_for_jenkins=`echo s1.y s2.y s3.y s4.y s5.y s6.y s7.y f1.y 10.0.0.250`

    for h in ${hostname};do
        case ${h} in

            zenportal)
                for ip in ${ip_for_zenportal} ; do
                    ssh -t -p ${portN} ${h}@${ip} "
                        source ${init_script} && echo "server: ${h}@${ip} " && \
                        echo
                    "
                done
                ;;

            jenkins)
                for ip in ${ip_for_jenkins};do
                    ssh -t -p ${portN} ${h}@${ip} "
                        source ${init_script} && echo "server: ${h}@${ip} " && \
                        echo
                    "
                done
                ;;
            *)
                __err "other server , do nothing ..."
                return 0
                ;;
        esac
    done
}

main $@
