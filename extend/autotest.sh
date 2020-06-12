##!/system/bin/sh
#!/usr/bin/env bash

## 点击home
function key_home()
{
    #input keyevent 3
    input tap 400 400
}

## 点击返回
function key_back()
{
    input keyevent 4
}

function sleep_f()
{
    sleep 0.1
#    echo "  sleep ... "
}

function key_back_home
{
    input tap 40 30
}

function key_touch
{
    input tap 200 300
}

function main()
{
    local LCH="com.spt.carengine"
    local TOS="com.spt.carengine.traffic"
    local STR="温馨提示"
    local STR1="微信公众号"

    echo "auto test start ..."

    while true;
    do
        ## 保存最后一次执行的时间.
        date +'%Y.%m.%d_%H.%M.%S' > /data/local/tmp/time.log

        MSG="`uiautomator dump /proc/self/fd/1`"

        if [[ -n "`echo ${MSG} | grep ${TOS}`" ]];then
            if [[ -n "`echo ${MSG} |grep ${STR}`" ]];then
                echo " $STR ..."
                key_touch
                #sleep_f
            fi
        else
            :
            #echo "no $STR ..."
        fi

        count=`echo ${MSG} | grep -o ${LCH} | grep -c ${LCH}`

        echo "count = $count"

        if [[ -n "`echo ${MSG} | grep ${LCH}`" ]];then

            case `echo ${MSG} | grep -o ${LCH} | grep -c ${LCH}` in

                4)
                    key_back_home
                    ;;
                *)
                    :
                    ;;
            esac

            if [[ "`echo ${MSG} |grep ${STR1}`" ]];then
                echo "str :: $STR1"
                key_back_home
            fi

            #sleep_f
        fi
    done
}
main
