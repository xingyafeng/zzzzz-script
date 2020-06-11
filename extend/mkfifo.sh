#!/usr/bin/env bash

temp_fifo_file=$$.info        #以当前进程号，为临时管道取名
mkfifo ${temp_fifo_file}        #创建临时管道
exec 6<>${temp_fifo_file}       #创建标识为6，可以对管道进行读写
rm ${temp_fifo_file}            #清空管道内容

function f_sleep
{
    sleep 2
}

temp_thread=2                 #进程数

for ((i=0;i<temp_thread;i++)) #为进程创建相应的占位
do
    echo                      #每个echo输出一个回车，为每个进程创建一个占位
done >&6                      #将占位信息写入标识为6的管道

for ((i=0;i<2;i++))
do
    read                      #获取标识为6的占位
    {
        f_sleep
        echo $$,${i},`date`
        echo a
        sleep 5
        echo $$,${i},`date`
        echo b
        echo >&6              #>>>>>当任务执行完后，会释放管道占位，所以补充一个占位
    }&                        #>>>>>在后台执行{}中的任务

done <&6                      #将标识为6的管道作为标准输入

wait                          #等待所有任务完成
exec 6>&-                     #关闭标识为6的管道
