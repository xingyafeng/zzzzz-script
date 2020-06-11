#! /bin/bash
RTPT=$1
#寻找指定目录下只包含目录的最深的目录，遇到目录下有文件就停止，用于安卓源码仓库细拆
echo $1
function read_dir(){
 local TMP_LST=`ls $1`
 local hasdir=0
 local fname
 #echo " --- $RTPT , $1 --- "
 #遍历当前目录，一旦存在文件则返回，不打印，其中 滤掉根目录可能存在的 repo Makefile 等文件避免影响判断

 echo $1
 for fname in ${TMP_LST} ; do
  if [[ "$RTPT" != "$1" ]] && [[ -f "$1/$fname" ]] && [[ "repo" != "$fname" ]] && [[ "Makefile" != "$fname" ]] ; then
   #echo "$1/$fname is file , stop next and return "
   echo "$1" >> manifest_path_8321.txt  #输出父路径即可
   return
  fi
 done
 #如果当前目录只有目录，则滤掉.git out 目录，
 for fname in ${TMP_LST} ; do
  if [[ -d "$1/$fname" ]] && [[ ".git" != "$fname" ]] && [[ "out" != "$fname" ]] ; then
   read_dir "$1/$fname"
  fi
 done
}
#echo " --- $0 , $1 --- "

read_dir ${RTPT}