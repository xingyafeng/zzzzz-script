#!/bin/bash

## 打印关联数组
function print_ass_array()
{
    declare -a key
    declare -a value
    declare -A ass

    key+=($1)
    value+=($2)

    if [[ ${#key[@]} -ne ${#value[@]} ]]; then
        echo "key vaule no match ..."
        return
    fi

    for k in ${!key[@]} ; do
        for v in ${!value[@]} ; do
            if [[ ${k} == ${v} ]]; then
                echo ${key[$k]}
                echo ${value[$v]}
                echo '-----'
                ass[${key[$k]}]=${value[$v]}
            fi
        done
    done

    for a in ${!ass[@]} ; do
        echo " $a --- ${ass[$a]} "
    done

    echo ${ass[@]} -- ${!ass[@]}
}

#print_ass_array "5 6 7" "a b c"

if false; then
declare -a arr
declare -a tmp

unset arr tmp

for i in {1..9} ; do
    arr[${#arr[@]}]=${i}
done
unset arr tmp

tmp=(a b c)

arr+=(${tmp[@]})

echo ${arr[@]}
fi

function test_eval()
{
    declare -A print_var

    preinstall_apk_name=yov
    preinstall_apk_package_name=com.yunovo

    print_var[${#print_var[@]}]=preinstall_apk_name
    print_var[${#print_var[@]}]=preinstall_apk_package_name

    for v in ${print_var[@]}
    do
        var="echo $v = \$$v"
        eval ${var}
    done
}

function read_txt()
{
    declare -A dic
    declare -A dicN
    declare -a update

    echo ${update[@]}
    echo "--empty--"

    while read p;do
        echo "key = ${p%=*}"
        #echo "value = ${p##*=}"

        if [[ "${p%=*}" != "version_start" && "${p%=*}" != "version_end" ]];then
            dic[${p%=*}]=${p##*=}
        fi

    done < fs/test.txt

    echo "###################"

    while read p;do
        echo "key = ${p%=*}"
        #echo "value = ${p##*=}"

        if [[ "${p%=*}" != "version_start" && "${p%=*}" != "version_end" ]];then
            dicN[${p%=*}]=${p##*=}
        fi

    done < fs/testN.txt

    echo "-------"
    for i in ${!dic[@]}
    do
        echo "$i --- ${dic[$i]}"
    done

    echo "========="
    for i in ${!dicN[@]}
    do
        echo "$i --- ${dicN[$i]}"
    done

    echo "&&&&&&&&&&&&&&&&&&&&&&&&"

    for i in ${!dic[@]}
    do
        for j in ${!dicN[@]}
        do
            if [[ ${i} == ${j} ]];then
                echo "start : $i == $j ${dic[$i]} --- ${dicN[$j]} "

                if [[ ${i} == "main_version" && ${j} == "main_version" ]];then
                    if [[ ${dic[$i]} -lt ${dicN[$j]} ]];then
                        unset update
                        update[${#update[@]}]=all
                        echo "---- end ----"
                        echo ${update[@]}
                        return
                    fi
                else
                    if [[ ${dic[$i]} -lt ${dicN[$j]} ]];then
                        update[${#update[@]}]=${i}
                    fi
                fi
            else
                :
            fi
        done
    done

    echo "---- end ----"

    echo ${update[@]}
}

ret0=false
ret1=false

function test_retrun_v
{
    local ret=1

if ${ret0};then
    echo ${ret}
    return 1
fi

if ${ret1};then
    ret=2
    echo ${ret}
    return 0
fi

    echo ${ret}

}

function test_array
{
    declare -a array
    declare -a array_a=(a b c)

    if [[ "$1" ]];then
        array[${#array[@]}]=$1
    fi

    if [[ "$2" ]];then
        array[${#array[@]}]=$2
    fi

    if [[ "$3" ]];then
        array[${#array[@]}]=$3
    fi

    echo ${array[@]}
    echo "all =" ${array_a[@]}

    for p in ${array_a[@]}
    do
        echo "p = $p"
        array[${#array[@]}]=${p}
    done

    echo "all_end =" ${array[@]}
    array=($(awk -vRS=' ' '!a[$1]++' <<< ${array[@]}))
    ## 去重后的数组
    echo "end ${array[@]}"
}

a="aaa"
b="bbb"
c="ccc"
main_args="$a $b $c"

function test_args_f()
{
    echo $#

    echo $1
    echo $2
    echo $3

    echo "test args ..."
}

function test_process()
{
    local ret=hello
    local str=$1

    ret=(`echo ${str} | sed 's/[   ]\+//g'`)

    echo ${ret}
}

function test_shell()
{

    aa=`test_process "xxx xx x x x x x 11 1 1 1 1 22 2 2 2 2"`

    echo ${aa}
}
function test_read()
{
    read -p "Enter your name : " name

    echo ${name}
}

function is_root_yunovo_project()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}
    local project_name=(${k26P} ${k86aP} ${k86mP} ${k86sP} ${k86smP} ${k86lP} ${k86lsP} ${k86ldP} ${k88cP})

    if [[ "$thisP" ]];then

        for p in ${project_name[@]}
        do
            if [[ "$thisP" == "${p}_root" ]];then
                echo true
            fi
        done
    else
        echo "it do not get project name !"
        return 1
    fi

}

### 函数中的变量会直接在新函数中直接使用和修改
function handler_hat()
{
    echo "---------"

    echo "hat = $hat"

    ## 可以再次修改不用定义
    hat=10

    echo "hat = $hat"
}

function test_args()
{
    local ret=$1
    local hat=1000

    if [[ $# -eq 1 ]];then
        echo "-----"
        echo "$#"

        handler_hat
    else
        echo "$#"
    fi
}

function is_long_project()
{
    ### jenkins path name
    local prjN=(k86l k86ld)

    ### jenkins project name
    local projectN=(k26c)

    local prj_name=$(pwd) && prj_name=${prj_name%/*} && prj_name=${prj_name##*/}

    for p1 in ${prjN[@]}
    do
        if [[ "$prj_name" == "$p1" ]];then
            echo true
        fi
    done

    for p2 in ${projectN[@]}
    do
        if [[ "$project_name" == "$p2"  ]];then
            echo true
        fi
    done
}

function get_project_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}
    local project_name=(${k26P} ${k86aP} ${k86mP} ${k86sP} ${k86smP} ${k86lP} ${k86lsP} ${k86ldP} ${k88cP})
    local isroot=false

    if [[ "$thisP" ]];then

        for p in ${project_name[@]}
        do
            if [[ "$thisP" == "${p}_root" ]];then
                isroot=true
                echo ${p}
            fi
        done

        if [[ "$isroot" == "false" ]];then
            echo ${thisP}
        fi
    else
        echo "do not get project name !"
    fi
}

function test_is_number()
{
    local n=$1

    expr ${n} "+" 10 &> /dev/null

    if [[ $? -eq 0  ]];then
        echo "$n is number"
    else
        echo "$n not number"
    fi
}

function remove_space()
{
    local new_v=
    local old_v=$1
    tmp_file=~/workspace/script/zzzzz-script/tmp.txt

    new_v=`cat ${tmp_file} | sed 's/[   ]\+//g'`
    if [[ "$new_v" != "$old_v" ]];then
        echo ${new_v}
    else
        echo ${old_v}
    fi
}

function test_()
{
    local tmp_file=~/workspace/script/zzzzz-script/tmp.txt
    local ret="xxx xxx xxx zzz xxx"
    local new_v=

    echo ${ret} > ${tmp_file}
    remove_space ${ret}

    if [[ -f ${tmp_file} ]];then
        rm ${tmp_file} -r
    fi
}
function checkout_debug_info()
{
    local build_flag=$1
    local which_flag=(1 2 3 4 5 6 7)
    local flag=

    for f in ${which_flag[@]}
    do
        if [[ "$build_flag" ]];then
            flag=`echo ${build_flag} | cut -d '.' -f${f}`

            if [[ -z ${flag} ]];then
                echo " flag is error , please checkout it !"
                exit 1
            fi

            if [[ ${flag} -ne 0 && ${flag} -ne 1 ]];then
                echo " flag is error , please checkout it !"
                exit 1
            else
                echo true
            fi
        fi
    done
}

### 获取debug配置信息
function get_debug_info()
{
    local build_flag=$1
    local which_flag=(1 2 3 4 5 6 7)

    for f in ${which_flag[@]}
    do
        case ${f} in
            1)
                flag_fota=`echo ${build_flag} | cut -d '.' -f${f}`
                ;;
            2)
                flag_print=`echo ${build_flag} | cut -d '.' -f${f}`
                ;;
            3)
                flag_download_sdk=`echo ${build_flag} | cut -d '.' -f${f}`
                ;;
            4)
                flag_clone_app=`echo ${build_flag} | cut -d '.' -f${f}`
                ;;
            5)
                flag_make_sdk=`echo ${build_flag} | cut -d '.' -f${f}`
                ;;
            6)
                flag_cpimage=`echo ${build_flag} | cut -d '.' -f${f}`
                ;;
            7)
                flag_cpcustom=`echo ${build_flag} | cut -d '.' -f${f}`
                ;;
        esac
    done
}

test-str-z()
{
    local src=$1
    if [[ -n "$src" ]];then
        echo ${src}

        ### 字符串  为空为真
        if [[ -z "$src" ]];then
            echo "zzzzzzzzzzzzzzzzzzzzz"
        else
            echo "xxxxxxxxx"
        fi

        ### 字符串　不为空为真
        if [[ -n "$src" ]];then
            echo "nnnnnnnnnnnnnn"
        else
            echo "xxx"
        fi
    fi
}

test-readfs()
{
    while read line
    do
        echo ${line}
        ret=${line##*=}
        echo ${ret}
    done < apptag.txt
}

test-string()
{
	local var=chiphd

	# get string length
	local length=${#var}

	show_vir ${length}
}


test-reboot()
{
	###
	echo reboot
}

test-jenkins()
{
	share_path=~/workspace/share_jenkins
	cur_time=`date +%m%d_%H%M`
	app_name=CarBack
	app_version=`cat ${app_name}/AndroidManifest.xml | grep android:versionName= | awk -F '"' '{print $2}'`

	if [[ ! -d ${share_path}/CarBack ]]; then
		#statements
		mkdir -p ${jenkins_path}/CarBack/
		if [[ $? -eq 0 ]]; then
			#statements
			cp output/CarBack.apk  ${jenkins_path}/CarBack/CarBack_${cur_time_}${app_version}.apk
		fi
	fi
}

function test-help()
{

	ret=$1
	if [[ "$ret" == "--help" ]];then

		echo "test help ..."
		return 0
	fi

	echo "you go here ..."

}


function clone_app()
{
        local remote_name="master origin/master"
        app=(1 2 3 4 5)
        commond_app=(FactoryTest CarEngine CarHomeBtn CarSystemUpdateAssistant CarPlatform GaodeMap KwPlayer UniSoundService)
        k86a_app=(CarUpdateDFU CarBack CarRecord GaodeNavigation GpsTester BaiduNavigation AnAnEDog)
        k86l_app=(CarUpdateDFU CarBack CarRecordDouble CarRecordUsb StormVideo GaodeNavigation XianzhiDSA)
        k86s_app=(CarUpdateDFU CarRecordDouble CarRecordUsb GpsTester BaiduNavigation AnAnEDog StormVideo)
        k26a_app=(CarRecord GpsTester BaiduNavigation)
        k26s_app=(CarRecordDouble CarRecordUsb GpsTester BaiduNavigation StormVideo)
        k88_app=(CarUpdateDFU CarBack CarRecord GaodeNavigation GpsTester BaiduNavigation AnAnEDog)


        for arr in ${commond_app[@]}; do
			#statements
			echo ${arr}
		done
		echo "========="
		#### support append index
        k86a_app+=("${commond_app[@]}")

        for arr in ${k86a_app[@]}; do
			#statements
			echo ${arr}
		done


}

function test_a_o()
{

    echo $1
    echo $2
    if [[ "$1" == "a" || "$1" == "b" ]] && [[ "$2" == "c" || "$2" == "d" ]];then
        echo "ok ."
    else
        echo "fail ."
    fi

}

TARGET_BUILD_VARIANT_LIST=("eng" "user" "userdebug")

#function declaring
declare -a _inlist
function select_choice()
{
    _target_arg=$1
    _arg_list=(${_inlist[@]})
    _outc=""

    select _c in ${_arg_list[@]}
    do
        if [[ -n "$_c" ]]; then
            _outc=${_c}
            break
        else
            for _i in ${_arg_list[@]}
            do
                _t=`echo ${_i} | grep -E "^$REPLY"`
                if [[ -n "$_t" ]]; then
                    _outc=${_i}
                    break
                fi
            done

            if [[ -n "$_outc" ]]; then
                break
            fi
        fi
    done

    if [[ -n "$_outc" ]]; then
        eval "${_target_arg}=${_outc}"
        export ${_target_arg}=${_outc}
    fi
}

function main()
{
    _inlist=(${TARGET_BUILD_VARIANT_LIST[@]})
    select_choice TARGET_BUILD_VARIANT
}

#测试 pwd
function test-pwd
{
	local test_path=`pwd`
	show_vir "test_path = $test_path"
}


function cecho
{
	echo $@ '#'
}

#测试字符串 提取
function tstring
{
	jpg_name="chiphd.sameple.jpg"

	## %  从左往右匹配 遇到最后一个就结束  获取文件名称
	name_1=${jpg_name%.*}

	## %% 从左往右匹配 遇到第一个就结束
	name_2=${jpg_name%%.*}

	## # 从右支左 遇到最后一个 匹配结束
	name_11=${jpg_name#*.}

	## ## 从右支左 遇到第一个 匹配结束   获取后缀名
	name_22=${jpg_name##*.}

	echo ${jpg_name}
	echo --------------------

	echo File '%'  name: ${name_1}
	echo File '%%' name: ${name_2}
	echo File '#'  name: ${name_11}
	echo File '##' name: ${name_22}
}

# 测试环境变量
function test-env
{
	echo $*
	echo $@
	echo $#
	echo $?

	### $*  整体
	for args in "$*"; do
		#statements
		show_vir ${args}
	done

	### $@  单个
	for args in "$@"; do
		#statements
		show_vir ${args}
	done

	### $@  单个
	for args in $*; do
		#statements
		show_vir ${args}
	done

	## 当前进程ID号
	echo $$

	## 后台最后一个进程号
	echo $!
}

### 测试计算方法
test-let()
{
	no1=100
	no2=120

	echo "--------------------------符号 运算--------------------------"
	result=$((no1+no2))
	result=$[ no1 + no2 ]
	echo ${result}

	echo "--------------------------expr--------------------------"
	let result=no1+no2
	result_expr=`expr 3 + 5`

	let no2++
	let no1--
	let result+=10

	echo ${result}
	echo ${result_expr}

    echo "--------------------------expr make compile whole time------------------------------"
    startT=`date +'%Y-%m-%d %H:%M:%S'`
    #sleep 4
    endT=`date +'%Y-%m-%d %H:%M:%S'`
    hh=
    mm=
    ss=

    #userT=$(($(date +%s -d "$endT") - $(date +%s -d "$startT")))
    userT=$(($(date +%s -d '2010-01-01 11:11:11') - $(date +%s -d '2010-01-01')))

    echo ${userT}

    hh=$((userT/3600))
    mm=$[ (userT - hh*3600) / 60 ]
    ss=$[ (userT - hh*3600 - mm*60) ]
    echo "hh = $hh"
    echo "mm = $mm"
    echo "ss = $ss"

	echo "----------------------------bc----------------------------------"
	no=54
	echo "4 * 0.56" | bc
	result=`echo "$no * 1.5 " | bc`
	echo ${result}
}

test-array()
{
	local array_var=(1 2 3 4 5 6 7 8 9 0)
	local index=5

	local array[0]='test0'
	local array[1]='test1'
	local array[2]='test2'
	local array[3]='test3'
	local array[4]='test4'
	local array[5]='test5'
	local array[6]='test6'

	#注意是打括号
	local array_length=${#array_var[*]}

	show_vir '===========简单数组================='
	echo "array_var[6] = ${array_var[$index]}"
	echo "length = $array_length"

	if true;then
		echo ${array_var[*]}
		echo --------------------------------
		echo ${array_var[@]}

		echo
		##便利数组
		for arr in ${array[@]}; do
			#statements
			echo ${arr}
		done
		echo
	fi

	show_vir '===========关联数组================='

	declare -A month_name
	local month_name=( [1]='Jan' [2]='Feb' [3]='Mar' [4]='Apr' [5]='May' [6]='Jun' [7]='Jul' [8]='Aug' [9]='Sep' [10]='Oct' [11]='Nov' [12]='Dec' )
	local month_length=${#month_name[*]}

	echo "month_name =  ${month_name[1]}"
	echo "---------------------------------"
	echo "length = $month_length"

	### 实现顺序便利  一般for   method one
	for (( i = 0; i < $month_length+1 ; i++ )); do
		#statements
		echo ${month_name[$i]}
	done

	echo ==============

	###  for ... in ...  method two
	for month in ${month_name[@]}; do
		#statements
		echo ${month[@]}
	done

	# 列出索引
	echo ${!month_name[*]}

	echo ==============

	### for  method three
	for i in "${!month_name[@]}"; do
		printf "%s\t%s\n" "$i" "${month_name[$i]}"
	done

	echo ==============

	### while method four
	local j=0
	while [[ ${j} -lt ${#month_name[@]} ]]; do
	    echo ${month_name[$j]}
	    let j++
	done
}


if false;then

	a=(1 2 3)
	b=(a b c)

	fun()
	{
	   local a=($1)
	   local b=($2)
	   echo ${a[*]}
	   echo ${b[*]}
	}

	fun "${a[*]}" "${b[*]}"
	cp -vf ${OUT}/MT*.txt  ${DEST_PATH}
    cp -vf ${OUT}/preloader_${build_device}.bin  ${DEST_PATH}
    cp -vf ${OUT}/lk.bin ${DEST_PATH}
    cp -vf ${OUT}/boot.img ${DEST_PATH}
    cp -vf ${OUT}/recovery.img ${DEST_PATH}
    cp -vf ${OUT}/secro.img ${DEST_PATH}
    cp -vf ${OUT}/logo.bin ${DEST_PATH}
    cp -vf ${OUT}/trustzone.bin ${DEST_PATH}
    cp -vf ${OUT}/trustzone.bin ${DEST_PATH}
    cp -vf ${OUT}/system.img ${DEST_PATH}
    cp -vf ${OUT}/cache.img ${DEST_PATH}
    cp -vf ${OUT}/userdata.img ${DEST_PATH}

    cp -vf ${OUT}/obj/CGEN/APDB_MT*W15*  ${DEST_PATH}/database/ap
    cp -vf ${OUT}/system/etc/mddb/BPLGUInfoCustomAppSrcP*  ${DEST_PATH}/database/moden

    cp -v ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}
    cp -v ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH}
fi
