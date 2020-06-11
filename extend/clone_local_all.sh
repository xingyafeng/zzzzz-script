#!/bin/sh
#思路： 单纯 object pack 文件，只能用一个作为基底，将其余的 pack 文件移除掉，用 git unpack-objects 解出松散对象，可以自动去掉重复的来达到减肥
#查找重复对象办法：git show-index < .git/objects/pack/pack-*.idx 显示每一个压缩包所有对象，然后用  uniq -d 显示重复行即可
#for F in `find -name pack-*.idx`;do echo -e "$F\n$F">>1.txt; git show-index < $F >> 1.txt ; done;
#步骤： clone 仓库顺序 4.2  4.4 5.1 6.0 7.0
#每个仓库步骤： .git  链接到具体仓库的.git 目录，然后checkout 出来相应的主分支
#
function doconfig {
	local pj_path=$1
	local pj_name=$2
	#echo ${pj_path} -- ${pj_name}
	local pj_abs_path=${pj_path}/${pj_name}
	#typeset -l pj_prefix_name
	local pj_prefix_name=$pj_path
	# A36/android --> A36
	if [ "`echo $pj_path | grep /`" ];then
		pj_prefix_name=${pj_path%%/*}
		#echo rename ${pj_prefix_name}
	fi
	pj_prefix_name=`echo ${pj_prefix_name}|tr '[:upper:]' '[:lower:]'`
	local pj_save_path=${pj_prefix_name}_${pj_name}
	echo ${pj_abs_path}
	#echo ${pj_abs_path} -- doconfig -- ${pj_prefix_name} ${pj_save_path}
	if [ ! -d  "${pj_name}.git" ];then
		#echo "create proj mkdir ${pj_name}.git"
		git init "${pj_name}.git" --bare
	fi
	#git --git-dir="${pj_name}.git" remote add $pj_prefix_name ssh://${uuu}@gerrit.y:29419/${pj_abs_path}
	git --git-dir="${pj_name}.git" remote add $pj_prefix_name /home/git/repositories/projects/${pj_abs_path}
	git --git-dir="${pj_name}.git" config remote.${pj_prefix_name}.fetch refs/*:refs/${pj_prefix_name}/*
	git --git-dir="${pj_name}.git" fetch $pj_prefix_name
}

#set -x
base_pj="D1402"
#/home/git/repositories/app_git/git/ ->  /home/git/repositories/projects
#共用部分20个库
common_pj_name="abi bionic bootable build cts dalvik development device docs external frameworks hardware libcore  libnativehelper ndk packages pdk prebuilts sdk system"
all_pj_path="A36/android D1402 K26 k1402/alps k18 k570e k86 k66 k6806 k86A xt273 m170m m66 s802"
#git clone --config user.name=${uuu} -c user.mail=${eee}  ssh://${uuu}@gerrit.y:29419/${pj_abs_path} && cd ${pj_abs_path} &&  scp -p -P 29419 ${uuu}@gerrit.y:hooks/commit-msg .git/hooks/ 
#git clone --mirror --config user.name=${uuu} -c user.mail=${eee}  ssh://${uuu}@gerrit.y:29419/${pj_abs_path}
#cd ${pj_name}.git
echo pwd is $PWD , cd is $CD
all_pj_path_s1=""
for pj_path in $all_pj_path;do
	for pj_name in $common_pj_name;do
		doconfig "$pj_path" "$pj_name"
	done
done
#cd $PWD

#打印出所有剩余的a36
common_pj_name="gdk tools"
base_pj1="A36/android"
for pj_name in $common_pj_name;do
	doconfig "$base_pj1" "$pj_name"
done
base_pj1="A36/lichee"
common_pj_name="boot-v1.0 brandy buildroot linux-3.3 linux-3.4 out"
for pj_name in $common_pj_name;do
	doconfig "$base_pj1" "$pj_name"
done

#公共 差异部分 3个库
common_pj_name="art developers vendor"
#排除 A36/android 的工程
all_pj_path="D1402 K26 k1402/alps k18 k570e k86 k66 k6806 k86A xt273 m170m m66 s802"
for pj_path in $all_pj_path;do
	for pj_name in $common_pj_name;do
		doconfig "$pj_path" "$pj_name"
	done
done

#mtk公共部分
all_pj_path="A36/lichee D1402 K26 k1402/alps k18 k570e k86 k66 k6806 k86A xt273"
for pj_path in $all_pj_path;do
	doconfig "$pj_path" "tools"
done

#mtk公共部分
all_pj_path="k6806 k1402/alps k18 k570e xt273"
common_pj_name="kernel mediatek"
for pj_path in $all_pj_path;do
	for pj_name in $common_pj_name;do
		doconfig "$pj_path" "$pj_name"
	done
done

base_pj1="D1402"
common_pj_name="modem kernel u-boot"
for pj_name in $common_pj_name;do
	doconfig "$base_pj1" "$pj_name"
done
doconfig "k1402/alps" "modem"

base_pj1="k1402/project"
common_pj_name="k1402 mw703"
for pj_name in $common_pj_name;do
	doconfig "$base_pj1" "$pj_name"
done

common_pj_name="kernel-3.10 md32"
all_pj_path="k86 k86A k66 K26"
for pj_path in $all_pj_path;do
	for pj_name in $common_pj_name;do
		doconfig "$pj_path" "$pj_name"
	done
done

all_pj_path="A36/lichee D1402 k18 xt273 k570e m170m s802 m66"
for pj_path in $all_pj_path;do
	doconfig "$pj_path" "spt"
done

#amlogic 差异部分
common_pj_name="aml_resource common gdk uboot"
all_pj_path="m170m s802 m66"
for pj_path in $all_pj_path;do
	for pj_name in $common_pj_name;do
		doconfig "$pj_path" "$pj_name"
	done
done

