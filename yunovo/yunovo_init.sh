#!/bin/bash

############################################################################### common var

#工具类
utils_p=${script_p}/utils
#配置文件
config_p=${script_p}/config

#------------------------------------------------------------------------------ 导入环境

# 自动导入脚本
for fname in `find ${script_p} -type f -name *_init.sh | awk -F/ '{print $(NF-1)}'` ; do

    # load script
    for script in `find ${script_p}/${fname} -type f -name ${fname}_*.sh` ; do

        case `basename ${script}` in

            ${fname}_init.sh)
                continue
                ;;

            *)
                source ${script}
                ;;
        esac
    done

done

# utils 文件名不规则，独立导入
for script in `find ${utils_p} -type f -name "*.sh"` ; do
    source ${script}
done