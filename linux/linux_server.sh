#!/usr/bin/env bash

### 挂载服务器到本地
function sshfs-server()
{
    local userN=jenkins
    local hostN=`echo s1.y s4.y s5.y s6.y s7.y f1.y`
    local jobs_path=""

    local f1_path=/public/share
    local s4_path=/work/home/jenkins/jobs
    local s5_path=/work/home/jenkins/jobs
    local s6_path=/work/jenkins/jobs
    local s7_path=/media/s7/hdd4/jobs

    if [[ "`is_yunovo_server`" == "true" ]];then

        for hostname in ${hostN}
        do
            if [[ ! -d ~/${hostname} ]];then
                mkdir -p ~/${hostname}
            fi

            ##检查是否有挂载上，有就返回，否则进行挂载动作
            if [[ "`mount | grep ${hostname}`" ]];then
                #echo $hostname
                continue
            fi

            if [[ -d ~/${hostname} ]];then

                case ${hostname} in

                    f1.y)
                        jobs_path=${f1_path}
                        ;;

                    s4.y)
                        jobs_path=${s4_path}
                        ;;

                    s6.y)
                        jobs_path=${s6_path}
                        ;;

                    s7.y)
                        jobs_path=${s7_path}
                        ;;

                    *)
                        jobs_path=/home/${userN}/jobs
                        ;;

                esac

                if [[ "$jobs_path" ]];then
                    sshfs ${userN}@${hostname}:${jobs_path} ~/${hostname}
                fi

            else
                show_vir "hostname path is not exist, please checkout path !"
                exit 1
            fi
        done
    fi
}

## 查看已完整到本地的服务列表
function ls-server()
{
    local hostN=`echo s1.y s4.y s5.y s6.y s7.y f1.y`

    if [[ "`is_yunovo_server`" == "true" ]];then
        for hostname in ${hostN}
        do
            if [[ -d ~/${hostname} ]];then
                ls ~/${hostname}
                show_vig "--------$hostname"
            else
                show_vir " $hostname is not exist ."
            fi
        done
    fi
}

## 卸载服务器
function fusermount-server()
{
    local hostN=`echo s1.y s4.y s5.y s6.y s7.y f1.y`

    if [[ "`is_yunovo_server`" == "true" ]];then
        for hostname in ${hostN}
        do
            if [[ -d ~/${hostname} ]];then
                fusermount -u ~/${hostname}
                if [[ $? -eq 0 ]];then
                    rm ~/${hostname} -r
                fi
            fi
        done
    fi
}

# 挂载code
function sshfs-code() {

    sshfs yafeng@s5.y:/opt/code /home/yafeng/code
}