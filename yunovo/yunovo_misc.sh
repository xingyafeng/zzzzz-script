#!/usr/bin/env bash

## ssh-gerrit-who
function ssh-gerrit-who()
{
    local username=""

    _inlist=(`getent passwd | grep /work | awk -F: '{print $1}'| sort` exit)
    show_vir "Choose which version of username ?"
    select_choice username

    case ${username} in

        exit)
            ssh -p 29419 xingyafeng@gerrit.y $@
            ;;
        *)
            ssh -p 29419 ${username}@gerrit.y $@
            ;;
    esac
}

## ssh-gerrit
function ssh-gerrit()
{
    ssh -p 29419 ${git_username}@gerrit.y $@
}

## set java1.8
function set_java_version_1.8() {

    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
    export JRE_HOME=${JAVA_HOME}/jre
    export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
    export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH
}

## ssh-jenkins
function ssh-jenkins()
{
    local jenkins_url=""

    set_java_version_1.8

    case `hostname` in

        happysongs)
            jenkins_url="http://10.0.0.252:8080"
            ;;

        s1|s2|s4|s5|s6|s7|c1|c2|f1)
            jenkins_url="http://jenkins.y"
            ;;
        *)
            return 0
            ;;
    esac

    echo
    show_vig "$jenkins_url"

    if [[ -n "$jenkins_url" ]];then
        #java -jar $script_p/tools/jenkins-cli.jar -s $jenkins_url -ssh -user xingyafeng $@
        java -jar ${script_p}/tools/jenkins-cli.jar -remoting -s ${jenkins_url} $@
    else
        __err "No found url ..."
    fi
}

## 更新服务器的脚本仓库
function ssh-update-script()
{
    local server_ip=`echo s1.y s2.y s3.y s4.y s5.y s6.y s7.y f1.y c1.y c2.y 10.0.0.250`
    local portN=22
    local server_name=jenkins
    local init_script=/home/jenkins/workspace/script/zzzzz-script/init_script.sh

    for ip in ${server_ip};do

        ssh -t -p ${portN} ${server_name}@${ip} "
            source $init_script && echo "server: ${ip}" && \
            echo
        "

        if false;then
            ssh -t -p ${portN} ${server_name}@${ip} '
                cd ~/workspace && touch ssh_test && mkdir test && \
                cd ~ && touch xxx
            '
        fi
    done
}

## 设置ssh权限
function ssh-set-permission()
{
    if [[ -d ~/.ssh ]];then
        chmod 755 ~/.ssh
    else
        __err ".ssh folder not found!"
        return 0
    fi

    if [[ -f ~/.ssh/id_rsa && -f ~/.ssh/id_rsa.pub ]];then
        chmod 600 ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
    else
        __err "id_rsa or id_rsa.pub not found!"
        return 0
    fi

    if [[ -f ~/.ssh/known_hosts ]];then
        chmod 644 ~/.ssh/known_hosts
    else
        __err "known_hosts not found!"
        return 0
    fi
}

## 设置locale , 当执行命令时, 出现如下：locale: Cannot set LC_ALL to default locale: No such file or directory
## 安装英文版本ubuntu系统,可以使用以下命令解决.
function set_locale() {

    export LANGUAGE=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    locale

    locale-gen en_US.UTF-8
    sudo dpkg-reconfigure locales

    locale
}

## 检查gerrit是否已新建仓库
function check_gerrit_repositories() {

    local count=0
    local tmp=
    local has_p=has_project.log

    if [[ "$1" && -f "$1" ]]; then
        tmp=$1
    else
        __err "参数1为空 or 文件不存在 ..."
        return 1
    fi

    if [[ -f ${has_p} ]]; then
        :> ${has_p}
    else
        touch ${has_p}
    fi

    if [[ "$#" -ne 1 ]]; then
        echo ""
        echo "check_gerrit_repositories \$@"
        echo
        echo "    参数1 : 是一个普通文件,内容存放者仓库的路径."
        echo
        echo "    e.g. check_gerrit_repositories empty.xml "
        echo

        return 0
    fi

    ssh-gerrit gerrit ls-projects > ${script_p}/fs/ok.log

    while read line;
    do
        while read p;
        do
            if [[ "${line}" == ${p} ]]; then
                echo ${p} >> ${has_p}
                __pruple__ ${p} is exist ...
                let count++
            fi
        done < ${script_p}/fs/ok.log
    done < ${tmp}

    echo ${count}
}

## 创建空的脚本
function touch_empty_shell() {

    local shell=${tmpfs}/shell.sh

    :> ${shell}

    echo "#!/usr/bin/env bash" >> ${shell}
    echo >> ${shell}

    chmod u+x ${shell}
}

## 仓库manifest 项目
function create_manifest_project() {

    local count=
    local pre=

    if [[ -n $1 ]]; then
        pre=$1
    fi

    if [[ "$#" -gt 1 ]]; then
        echo ""
        echo "create_manifest_project \$@"
        echo
        echo "    参数1 : 仓库路径的前缀 如: platform 或者为空等等"
        echo
        echo "    e.g. check_gerrit_repositories platform"
        echo "    e.g. check_gerrit_repositories"
        echo

        return 0
    fi

    local common_name_and_path="<project groups=\"pdk\" name=\"${pre}/ret\" path=\"ret\"/>"
    local common_name_only="<project groups=\"pdk\" name=\"ret\"/>"

    local empty=empty.xml
    local default=default.xml

    if [[ -f ${empty} ]];then
        count=`cat ${empty} | wc -l`

        if [[ -z ${count} ]];then
            echo "count is NULL ."
            return 1
        fi
    fi

    #创建default.xml
    if [[ -f ${default} ]];then
        rm ${default} && touch ${default}
    else
        touch ${default}
    fi

    for ((i=1; i<=${count}; i++))
    do
        if [[ -f ${default}  ]]; then

            if [[ -z "$1" ]]; then
                echo ${common_name_only} >> ${default}
            else
                echo ${common_name_and_path} >> ${default}
            fi
        fi
    done

    if [[ -f ${default} ]]; then
        modify_project
    fi
}

## 修改项目名
function modify_project()
{
    local count=1

    if [[ -f empty.xml ]];then
        :
    else
        echo "empty.xml is not exist !"
        return 1
    fi

    while read p;do
        replace_string=${p}

        while read line;do
            if [[ ${line} =~ 'ret' ]];then
                sed -i "${count}s#ret#${replace_string}#g" ${default}
                let count++
                break
            fi
        done < ${default}
    done < empty.xml
}

## 打包android代码 排除.repo .git .gitignore
function tardroid()
{
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile  ]];then
        tar --exclude=out --exclude=.git --exclude=.repo --exclude=.gitignore -czvf ../x.tar.gz . | tee log.txt
    else
        __err "current directory is not android !"
    fi
}

## 生成studio config file
function make_idegen()
{
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile  ]];then
        make -j${JOBS} idegen && development/tools/idegen/idegen.sh
    else
        __err "current directory is not android !"
    fi
}

## 生成android签名文件
function auto_make_key()
{
    local certs_p=~/.android-certs
    local make_key=./development/tools/make_key
    local board_list=("yunovo" "carrobot" "android")
    local subject=""

    if [[ ! -d ${certs_p} ]];then
        mkdir ${certs_p}
    else
        #cp -r $certs_p $certs_p-`date +%y%m%d%H`
        rm ${certs_p}/*
    fi

    _inlist=(${board_list[@]})
    show_vir "select custom name : "
    select_choice keyN

    show_vip "--> key name : $keyN"

    case ${keyN} in

        yunovo)
            subject='/C=CN/ST=GuangDong/L=ShenZhen View/O=Yunovo/OU=Develop/CN=yunovo.cn/emailAddress=notify@yunovo.cn'
            ;;

        carrobot)
            subject='/C=CN/ST=BeiJing/L=BeiJing View/O=Carrobot/OU=Develop/CN=carrobot.com/emailAddress=developer@carrobot.com';
            ;;

        android)
            subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
            ;;

        *)
            subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
            ;;
    esac

    for x in releasekey testkey platform shared media;
    do
        if [[ -f ${make_key} ]];then
            if [[ -x ${make_key} ]];then
                ${make_key} ${certs_p}/${x} "$subject"
            else
                __err "bash: $make_key: 权限不够"
                return 1
            fi
        else
            __err "bash: $make_key: 没有那个文件或目录"
            return 1
        fi
    done
}

function resync()
{
    local ref=""

    if [[ "$#" -ne 1 ]]; then
        echo ""
        echo "resync \$@"
        echo
        echo "    参数1 : refs/changes/82/46882/1"
        echo
        echo "    e.g. resync refs/changes/82/46882/1 "
        echo

        return 0
    fi

    if [[ "$1" ]];then
        ref="$1"
    fi

    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then

        if [[ -n "${ref}" ]]; then
            repo init -b "${ref}"
        fi

        repo sync -d --no-tags
    else
        echo "current directory is not android !"
    fi
}


## 获取系统编译后的app与apk
function get_system_app_type()
{
    if [[ "$OUT" ]];then
        DEVICE_PROJECT=`get_build_var TARGET_DEVICE`
    fi

    local app_path=${config_p}/yunovo_app.txt
    local apk_path=${config_p}/yunovo_apk.txt
    local allappsfs=${script_p}/fs/allapp.txt
    local allappsfs_tmp=${script_p}/fs/apps_tmp.txt
    local findfs=out/target/product/${DEVICE_PROJECT}/system/

    find ${findfs} -name "*.apk" | grep app | sed 's/.*app\/\([^\/]*\).*/\1/g' | sort > ${allappsfs_tmp}
    find ${findfs} -name "*.apk" | grep preinstall | sed 's/.*all\/\([^.]*\).*/\1/g' >> ${allappsfs_tmp}

    if [[ -f ${allappsfs_tmp} ]];then

        cat ${allappsfs_tmp} | sort > ${allappsfs}
    fi

    echo
    show_vir "-----------------------------------apk"
    while read p;do
        while read apk;do
            if [[ ${p} == ${apk} ]];then
                show_vip "$apk"
            fi
        done < ${apk_path}
    done < ${allappsfs}

    echo
    show_vir "----------------------------------app"

    while read p;do
        while read app;do
            if [[ ${p} == ${app} ]];then
                show_vip "$app"
            fi
        done < ${app_path}
    done < ${allappsfs}
}

## 拷贝OTA基准包至指定路径
function cpotafs()
{
    # 差分包列表
    local otafs=
    # 过滤列表
    local filter='target_files-package.zip|otatools.zip'

    # OTA基准版本
    declare -a ver

    case $# in

        0) # 不传参数,直接输出帮助

            echo ""
            echo "${FUNCNAME[0]} [\$@] ..."
            echo
            echo "   \$@ : 集合参数 , 后面跟时间轴,支持多个版本."
            echo
            echo "    e.g."
            echo "        1. ${FUNCNAME[0]} # 输出帮助文档"
            echo "        2. ${FUNCNAME[0]} S1.03.2018.06.01_14.05.05 S1.04_2020.01.10_14.26.43"
            echo
            return 0
        ;;

        1)
            case $@ in

                -h|--help)

                    echo ""
                    echo "${FUNCNAME[0]} [\$@] ..."
                    echo
                    echo "   \$@ : 集合参数 , 后面跟时间轴,支持多个版本."
                    echo
                    echo "    e.g."
                    echo "        1. ${FUNCNAME[0]} # 输出帮助文档"
                    echo "        2. ${FUNCNAME[0]} S1.03.2018.06.01_14.05.05 S1.04_2020.01.10_14.26.43"
                    echo
                    return 0
                ;;

                *)
                    # 不用干活,其实时变量 [ $@ ] 的值不用处理. It is best to check format for args.
                    :
                ;;

            esac
        ;;

        *)
            # 不用干活,其实时变量 [ $@ ] 的值不用处理. It is best to check format for args.
            :
        ;;
    esac

    for v in $@ ; do

        otafs=`find ${test_path}/test -name "*.zip" | egrep -w "${v}"  | grep -vE "${filter}" | grep -v "sdupdate.*.zip"`

        echo
        show_vig "${otafs##*/} :"

        ver[${#ver[@]}]="${otafs##*/}"

        if [[ -n "${otafs}" ]]; then
            cp -vf "${otafs}" "${otafs_p}"
        else
            log error "The otafs variable is null ..."
        fi

        if [[ -f ${otafs} ]];then
            md5sum ${otafs}
        else
            log error "The ota file has not found ..."
        fi

        if [[ -f ${otafs_p}/${otafs##*/} ]];then
            md5sum ${otafs_p}/${otafs##*/}
        else
            log error "The ota file has not found ..."
        fi
    done

    show_vip "----------------------- end. "

    # 输出需要制作OTA包的版本信息
    echo ${ver[@]}
}

## 设置git编码格式
function setgitencoding()
{
    git config --global i18n.commitencoding utf-8
    git config --global gui.encoding utf-8
    export LESSCHARSET=utf-8
}

## 设置vim配置文件
function setgitconfig()
{
	local git_name=""

    if [[ -n $1 ]]; then
        git_name=$1
    fi

    if [[ $# -gt 1 ]]; then
        echo ""
        echo "setgitconfig \$@"
        echo
        echo "    参数: 1. gerrit username "
        echo
        echo "    e.g. setgitconfig xingyafeng"
        echo

        return 1
    fi

	if [[ -n ${git_name} ]];then
		git config --global user.name  ${git_name}
        git config --global user.email ${git_name}@yunovo.cn
	else
		git config --global user.name  xingyafeng
		git config --global user.email xingyf@yunovo.cn
		git config --global ssh.variant ssh
	fi

    git config --global alias.st status
    git config --global alias.br branch
    git config --global alias.co checkout
    git config --global alias.ci commit
    git config --global alias.date iso
    git config --global core.editor vim
    git config --global color.ui true
    git config --global branch.autosetuprebase always
    #git config --global push.default simple
    git config --global alias.lg "log --date=short --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %C(green)%s %C(reset)(%cd) %C(bold blue)<%an>%Creset' --abbrev-commit"
}

## 设置java环境变量
function set_java_version()
{
    local java_version=""
    local java_list=(java7 java8)

    _inlist=(${java_list[@]})
    show_vir "Choose which version of java? "
    select_choice java_version

    case ${java_version} in

    java7)
        export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
        ;;

    java8)
        export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
        ;;

    *)
        export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
        ;;
    esac

    export JRE_HOME=${JAVA_HOME}/jre
    export CLASSPATH=.:${CLASSPATH}:${JAVA_HOME}/lib:${JRE_HOME}/lib
    export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH

    java -version
}

## 获取APK包名和类名
function get_package_name()
{
	local apk_name=

    if [[ $# -eq 1 ]]; then
        apk_name=$1
    else
        echo ""
        echo "get_package_name [args1] ..."
        echo
        echo "    args1 : apk文件或者带路径"
        echo
        echo "    e.g."
        echo "        1. get_package_name nxDataWare.apk"
        echo "        2. get_package_name ~/workspace/date/0904/nxDataWare.apk"
        echo
        return 0
    fi

	if [[ -n "${apk_name}" && -f ${apk_name} ]];then
	    aapt dump badging ${apk_name} | grep name= | awk -F "'" '{print $2}'
		#aapt dump badging ${apk_name} | grep name= | sed 's%.*name=%%'  | sed 's% .*%%'
	else
		__err "输入有误, 请在终端输入 [get_package_name] 查询其帮助文档." && return 1
	fi
}

## 获取APK的基本信息
function get_apk_info()
{
	local apk_name=$1

	if [[ "$apk_name" ]];then
		aapt dump badging ${apk_name}
	else
		show_vir "eg: get_package_name + apk_name"
	fi
}

## 优化apk,系统编译出来的apk, 默认是已经过优化
function checkout_apk_4()
{
	local apk_name_before=$1
	local apk_name_after=${apk_name_before%.*}_after.apk

	if [[ "$apk_name_before" && "$apk_name_after" ]]; then

		### 带参数 -v 显示内容
		if zipalign 4 ${apk_name_before} ${apk_name_after};then
			zipalign -c -v 4 ${apk_name_after} | grep Verification
			show_vir ' $apk_name_after'
		fi
	else
		show_vir "eg:  checkout_apk_4 + apk ..."
		return 0
	fi
}

## 清除修改还原为干净状态
function recover_android()
{
    if [[ -d .repo && -f build/core/envsetup.mk && -f Makefile ]];then
        recover_standard_android_project
        show_vir "-------------------------------------------------------------------------------------"
    else
        __err "The (.repo) not found ! please check your path, Whether or not in gettop ."
        return 1
    fi
}

## 清除系统中云智的app apk
function rmappfs()
{
    local OLDP=`pwd`
    local app_file=${config_p}/allapp.txt
    local app_path=packages/apps

    if [[ ! "`is_yunovo_project`" == "true" ]];then
        return 1
    fi

    cd ${app_path} > /dev/null

    while read app_name;do
        if [[ -d ${app_name} ]];then
            rm  ${app_name} -r && echo "---> rm $app_name ..."
        else
            show_vir "---> $app_name is not exist !"
        fi
    done < ${app_file}

    cd ${OLDP} > /dev/null
}



## 打开文件
function openfs()
{
    local file_path=$1

	if [[ $# -eq 0 ]];then
		nautilus . &
	else
        if [[ "$file_path" ]];then
            nautilus ${file_path} &
        fi
	fi

	if [[ "file_path" == "--help" ]];then
		show_vip "----------help---------------"
	fi
}

## 编译文件
function geditfs()
{
	local tmp=$1

	if [[ "$tmp" ]];then
		gedit $1 &
	fi
}

## 远程拷贝
function cpfs()
{
    local filefs=$1
    local hostN=$2

    local base_p=""
    local yafeng_p=""
    local server_p=""

    if [[ "$#" -eq 2 ]];then
        :
    else
        __err "参数不正确..."
    fi

    if [[ "`hostname`" == "happysongs" ]];then
        ## 本机拷贝服务器
        base_p=`echo ${td} | awk -F '/' '{ printf "%s/%s/%s\n", $4, $5, $6 }'`
    else
        ## 服务拷贝服务器或本机
        base_p=`echo ${td} | awk -F '/' '{ printf "%s/%s/%s\n", $5, $6, $7 }'`
    fi

    yafeng_p=/home/yafeng/${base_p}
    server_p=/work/home/jenkins/${base_p}

    if [[ -n "$filefs" && -n "$hostN" ]];then

        if [[ "$hostN" == "happysongs" ]];then
            scp -r yafeng@${hostN}:${yafeng_p}/${filefs} .
        else
            scp -r jenkins@${hostN}.y:${server_p}/${filefs} .
        fi

    else
        echo "e.g cpfs file_name hostname"
    fi
}

## 查找不同文件
function gfind()
{
    local files=$1

	if [[ "$files" ]];then
	    types=${files}
    else
		show_vip "please add only one arg, eg:gfind + string"
	fi

    case ${types} in

        c | cc | cpp | java | xml | sh | mk | rc | cfg | makefile | prop)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        bmp | jpg | png)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        txt | pdf | doc | xls)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        zip | rar | tar | gz | img)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        xml | html)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        wav | mp3 | acc | flac | wma | wav)

            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name \*"$types" -print
            ;;

        *)
            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "$files" -print
            ;;
    esac
}

### 收索文件内容，区分不同文件
function grepfs()
{
    local files=$1
    local types=$2

    if [[ "$files" ]];then
        :
    else
        show_vip "what do you want to grep file ?"
    fi

    case ${types} in

        c)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.c' -print0 | xargs -0 grep --color -n "$1"
            ;;

        cc)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.cc' -print0 | xargs -0 grep --color -n "$1"

            ;;

        cpp)

           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.cpp' -print0 | xargs -0 grep --color -n "$1"
            ;;

        java)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.java' -print0 | xargs -0 grep --color -n "$1"

            ;;

        xml)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.xml' -print0 | xargs -0 grep --color -n "$1"

            ;;

        sh)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.sh' -print0 | xargs -0 grep --color -n "$1"

            ;;

        mk)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.mk' -print0 | xargs -0 grep --color -n "$1"

            ;;

        rc)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.rc' -print0 | xargs -0 grep --color -n "$1"

            ;;

        cfg)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.cfg' -print0 | xargs -0 grep --color -n "$1"

            ;;

        makefile)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name 'Makefile' -print0 | xargs -0 grep --color -n "$1"

            ;;

        prop)
           find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name '*.prop' -print0 | xargs -0 grep --color -n "$1"

            ;;
        *)
            find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.java' -o -name '*.xml' -o -name '*.sh' -o -name '*.mk' -o -name '*.rc' -o -name '*.cfg' -o -name 'Makefile' -o -name 'Kconfig' -o -name '*.sh' -o -name '*.prop' \) -print0 | xargs -0 grep --color -n $@

            ;;
    esac
}

function ggrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "*\.gradle" \
        -exec grep --color -n "$@" {} +
}

function jgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "*\.java" \
        -exec grep --color -n "$@" {} +
}

function cgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) \
        -exec grep --color -n "$@" {} +
}

function resgrep()
{
    for dir in `find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -name res -type d`; do
        find ${dir} -type f -name '*\.xml' -exec grep --color -n "$@" {} +
    done
}

function mangrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -type f -name 'AndroidManifest.xml' \
        -exec grep --color -n "$@" {} +
}

function sepgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -name sepolicy -type d \
        -exec grep --color -n -r --exclude-dir=\.git "$@" {} +
}

function rcgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "*\.rc*" \
        -exec grep --color -n "$@" {} +
}

function mgrep()
{
    find . -name .repo -prune -o -name .git -prune -o -path ./out -prune -o -regextype posix-egrep -iregex '(.*\/Makefile|.*\/Makefile\..*|.*\.make|.*\.mak|.*\.mk)' -type f \
        -exec grep --color -n "$@" {} +
}

function treegrep()
{
    find . -name .repo -prune -o -name .git -prune -o -regextype posix-egrep -iregex '.*\.(c|h|cpp|S|java|xml)' -type f \
        -exec grep --color -n -i "$@" {} +
}

## rename photo modify bootanimation.zip
function renamefs()
{
	local count=1

	for old_photo_name in `find . -iname "*.png" -o -iname "*.jpg" -type f | sort`; do
		#statements
        if [[ ${count} -lt 10 ]];then
		    new_photo_name=000${count}.${old_photo_name##*.}
        elif [[ ${count} -lt 100 ]];then
		    new_photo_name=00${count}.${old_photo_name##*.}
        elif [[ ${count} -lt 1000 ]];then
		    new_photo_name=0${count}.${old_photo_name##*.}
        fi

        #show_vir "renamephoto $old_photo_name to $new_photo_name"
		mv "$old_photo_name" "$new_photo_name"

		let count++
	done
}

function obase()
{
	local dest_type=$1
	local src_tpye=$2
	local number=$3

	echo "obase=$dest_type; ibase=$src_tpye; $number" | bc

}

## 十六进制 转 十进制
function H-to-D()
{
	local number=$1
	local cpaString=

	if [[ ""${number}"" ]]; then
		cpaString=`echo ${number} | tr [a-z] [A-Z]`

		obase 10 16 ${cpaString}
	else
		show_vir "please input args ... eg: H-to-D ff"
	fi
}

## 十进制  转 十六进制
function D-to-H()
{
	local number=$1

	if [[ ""${number}"" ]]; then
		obase 16 10 ${number}
	else
		show_vir "please input args ... eg: D-to-H 9"
	fi
}

## 十进制  转 二进制
function D-to-B()
{
	local number=$1

	if [[ ""${number}"" ]]; then
		obase 2 10 ${number}
	else
		show_vir "please input args ... eg: H-to-B 9"
	fi
}

## 二进制  转 十进制
function B-to-D()
{
	local number=$1

	if [[ ""${number}"" ]]; then
		obase 10 2 ${number}
	else
		show_vir "please input args ... eg: H-to-D 1010101000"
	fi
}

## 获取那天是星期几
function get_week()
{
	local month_name=( [1]='Jan' [2]='Feb' [3]='Mar' [4]='Apr' [5]='May' [6]='Jun' [7]='Jul' [8]='Aug' [9]='Sep' [10]='Oct' [11]='Nov' [12]='Dec' )

	local year=$1
	local month=${month_name[$2]}
	local date=$3

	if [[ $# -eq 3 ]];then

        if [[ -n $1 ]]; then
            year="$1"
        else
            __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
        fi

        if [[ -n $2 ]]; then
            month=${month_name["$2"]}
        else
            __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
        fi

        if [[ -n $3 ]]; then
            date="$3"
        else
            __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
        fi

        if [[ -n ${month} && -n ${date} && -n ${year} ]]; then
		    date --date "${month} ${date} ${year}" +%A
		else
		    __err "输入有误, 请在终端输入 [${FUNCNAME[0]}] 查询其帮助文档." && return 1
        fi
	else
        echo ""
        echo "${FUNCNAME[0]} [args1] [args2] [args3] ..."
        echo
        echo "    args1 : 年"
        echo "    args2 : 月"
        echo "    args3 : 日"
        echo
        echo "    e.g."
        echo "        1. ${FUNCNAME[0]} 2018 3 7"
        echo
        return 0
	fi

	if false;then
		for m in ${month[@]}
		do
			date --date "$m 1 2015" +%A
		done
	fi
}

# 挂载code
function sshfs-code() {

    sshfs yafeng@s5.y:/opt/code /home/yafeng/code
}

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

## 手动拷贝版本至release
function copy_image_to_folder()
{
    local PROJECT_NAME=$1
    local PROJECT_VERSION=$2
    local BASE_PATH=~/firmware/${PROJECT_VERSION}
    local DEST_PATH=${BASE_PATH}/${PROJECT_NAME}
    local OTA_PATH=${BASE_PATH}/${PROJECT_NAME}_full_and_ota
    local build_device=${OUT##*/}

    if [[ $# -ne 2 ]]; then
        echo "Usage : ./cp_image.sh project_name project_version"
        return 1
    else
        echo
        show_vir "----  cp image start ..."
        echo
    fi

    if [[ ! -d ${BASE_PATH} ]];then
        mkdir -p ${BASE_PATH}
        if [[ ! -d ${DEST_PATH}/database/ ]];then
            mkdir -p ${DEST_PATH}/database/ap
            mkdir -p ${DEST_PATH}/database/moden
        fi
    fi

    if [[ ! -d ${DEST_PATH} ]];then
        mkdir -p ${DEST_PATH}
    fi

    if [[ ! -d ${OTA_PATH} ]];then
        mkdir -p ${OTA_PATH}
    fi

    cp -f ${OUT}/MT*.txt  ${DEST_PATH}
    cp -f ${OUT}/preloader_${build_device}.bin  ${DEST_PATH}
    cp -f ${OUT}/lk.bin ${DEST_PATH}
    cp -f ${OUT}/boot.img ${DEST_PATH}
    cp -f ${OUT}/recovery.img ${DEST_PATH}
    cp -f ${OUT}/secro.img ${DEST_PATH}
    cp -f ${OUT}/logo.bin ${DEST_PATH}
    cp -f ${OUT}/trustzone.bin ${DEST_PATH}
    cp -f ${OUT}/trustzone.bin ${DEST_PATH}
    cp -f ${OUT}/system.img ${DEST_PATH}
    cp -f ${OUT}/cache.img ${DEST_PATH}
    cp -f ${OUT}/userdata.img ${DEST_PATH}

    cp -f ${OUT}/obj/CGEN/APDB_MT*W15*  ${DEST_PATH}/database/ap
    cp -f ${OUT}/system/etc/mddb/BPLGUInfoCustomAppSrcP*  ${DEST_PATH}/database/moden

    cp  ${OUT}/full_${build_device}-ota*.zip ${OTA_PATH}
    cp  ${OUT}/obj/PACKAGING/target_files_intermediates/full_${build_device}-target_files*.zip ${OTA_PATH}

    echo
    show_vir "----  cp image end ..."
    echo
}

## login ssh server short cut
function jenkins
{
	ssh jenkins@happysongs
}

function jsystem
{
	ssh jenkins@10.0.0.250
}

function jenkins1
{
	ssh jenkins@s1.y
}

function jenkins2
{
	ssh jenkins@s2.y
}

function jenkins3
{
	ssh jenkins@s3.y
}

function jenkins4
{
	ssh jenkins@s4.y
}

function jenkins5
{
    ssh jenkins@s5.y
}

function jenkins6
{
    ssh jenkins@s6.y
}

function jenkins7
{
    ssh jenkins@s7.y
}

function jenkinsf1
{
    ssh jenkins@f1.y
}

function jenkinsc1
{
    ssh jenkins@c1.y
}

function jenkinsc2
{
    ssh jenkins@c2.y
}

function jenkinsd1
{
    ssh jenkins@d1.y
}

function yafengs5
{
    ssh yafeng@s5.y
}

function zenportal() {

    ssh zenportal@10.0.3.50
}

function droid20() {
    ssh android@10.129.46.20
}

function droid186() {
    ssh -l android-bld 10.128.180.186
}

function droidyafeng() {
    ssh -l yafeng WS186
}

##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  一次性使用

## 批量复制文件到制定路径
function cplogofs()
{
    ### e.g: magc6580_we_l.mk
    local findfs_name=$1

    ### e.g: yunovo_customs_logo_hd720
    local content_name=$2

    local boot_logo_mk=${findfs_name}

    local boot_logo_file=boot_logo.mk
    local boot_logo_file_path=${script_path}/${boot_logo_file}

    local findfs_file=${script_path}/findfs.txt

    if [[ $# -eq 2 ]];then
        echo
        show_vig "cp files start ..."
        echo
    else
        show_vir "e.g: cplogofs file_name content_name"
    fi

    ### 获取项目路径
    if [[ "$findfs_name" ]];then
        find . -name ${findfs_name} -print0 | xargs -0 grep ${content_name} | cut -d ":" -f1 > ${findfs_file}
    fi

    #echo "boot_logo_file = $boot_logo_file"

    ## 拷贝到指定项目中
    while read findfs
    do
        findfs=${findfs%/*}

        ### 生成boot_logo.mk
        if [[ -f ${findfs}/${boot_logo_mk} ]];then
            cat ${findfs}/${boot_logo_mk} | grep BOOT_LOGO > ${boot_logo_file_path}
        else
            echo "1. $findfs/$boot_logo_mk not found !"
            return 1
        fi

        if [[ -f ${boot_logo_file_path} && "$findfs" ]];then
            cp -vf ${boot_logo_file_path} ${findfs}
        else
            echo "2. $boot_logo_file_path not found !"
            return 1
        fi

        if [[ -f ${findfs}/${boot_logo_mk} ]];then
            rm ${findfs}/${boot_logo_mk}
            #echo "1---> $findfs/$boot_logo_mk"
        else
            echo "2. $findfs/$boot_logo_mk not found !"
            return 1
        fi
    done < ${findfs_file}

    ### del tmp file
    if [[ -f ${findfs_file} ]];then
        rm ${findfs_file}
        #echo "2---> $findfs_file"
    fi

    ### del tmp file
    if [[ -f ${boot_logo_file_path} ]];then
        rm ${boot_logo_file_path}
        #echo "3---> $boot_logo_file_path"
    fi

    echo
    show_vig "cp files end ..."
    echo
}

## 一次性函数,不看重复使用
function cphardwarefs()
{
    local findfs_name=$1
    local project_name=$2
    local findfs_file=${script_path}/findfs.txt
    local hardware_file=HardWareConfig.mk
    local hardware_file_path=${script_path}/${hardware_file}

    local start_line=
    local end_line=

    if [[ $# -eq 2 ]];then
        echo
        show_vig "cphardwarefs start ..."
        echo
    else
        show_vir "please e.g: cphardwarefs ProjectConfig.mk k26"
        return 1
    fi

    if [[ "$findfs_name" ]];then
        find . -name ${findfs_name} > ${findfs_file}
    else
        show_vir "$findfs_name not found !"
        return 1
    fi

    while read findfs
    do
        ### get project path
        findfs=${findfs%/*}

        if [[ "$findfs/$findfs_name" ]];then
            if [[ ${project_name} == "k26" ]];then
                start_line=$(sed -n '/^AUTO_ADD_GLOBAL_DEFINE_BY_VALUE/=' ${findfs}/${findfs_name})
                end_line=$(sed -n '/^BOOT_LOGO/=' ${findfs}/${findfs_name})

                if [[ "$start_line" ]];then
                    start_line=`expr ${start_line} + 1`
                fi

                if [[ "$end_line" ]];then
                    end_line=`expr ${end_line} - 1`
                fi
            elif [[ ${project_name} == "k86l" || ${project_name} == "k86s" ]];then
                start_line=$(sed -n '/yafeng/=' ${findfs}/${findfs_name})
                end_line=$(sed -n '/^BOOT_LOGO/=' ${findfs}/${findfs_name})

                if [[ "$start_line" ]];then
                    start_line=`expr ${start_line} - 1`
                fi

                if [[ "$end_line" ]];then
                    end_line=`expr ${end_line} - 1`
                fi
            elif [[ ${project_name} == "k86m" || ${project_name} == "k86sm" ]];then
                start_line=$(sed -n '/add yafeng hardware start/=' ${findfs}/${findfs_name})
                end_line=$(sed -n '/^BOOT_LOGO/=' ${findfs}/${findfs_name})

                if [[ "$start_line" ]];then
                    start_line=`expr ${start_line} - 1`
                fi

                if [[ "$end_line" ]];then
                    end_line=`expr ${end_line} - 1`
                fi
            elif [[ ${project_name} == "k86a" ]];then
                start_line=$(sed -n '/yafeng/=' ${findfs}/${findfs_name})
                end_line=$(sed -n '/^#BOOT_LOGO/=' ${findfs}/${findfs_name})

                if [[ "$start_line" ]];then
                    start_line=`expr ${start_line} - 1`
                fi

                if [[ "$end_line" ]];then
                    end_line=`expr ${end_line} - 1`
                fi
            fi

        fi

        if [[ ${start_line} && ${end_line} && -f ${findfs}/${findfs_name} ]];then

            echo "### hardware info for yunovo cumstoms" > ${hardware_file_path}
            sed -n "$start_line,$end_line"p ${findfs}/${findfs_name} >> ${hardware_file_path}

            ### del tmp file
            if [[ -f ${hardware_file_path} ]];then
                cp -vf  ${hardware_file_path} ${findfs}
                if [[ $? -eq 0 && "$hardware_file_path" ]];then
                    rm ${hardware_file_path}
                else
                    show_vir "$hardware_file_path not found !"
                    return 1
                fi
            fi

            ### del ProjectConfig.mk
            if [[ "$findfs/$findfs_name" ]];then
                rm ${findfs}/${findfs_name}
            else
                show_vir "$findfs/$findfs_name not found !"
                return 1
            fi
        fi

    done < ${findfs_file}

    if [[ -f ${findfs_file} ]];then
        rm ${findfs_file}
    else
        show_vir "$findfs_file not fount ! "
        return 1
    fi

    echo
    show_vig "cp files end ..."
    echo
}

### 批量删除文件夹
function deletefolder()
{
    local deletefs=$1
    local findfs_file=${script_path}/findfs.txt

    if [[ ${deletefs} ]];then
        gfind ${deletefs} > ${findfs_file}
    fi

    while read findfs
    do
        findfs=${findfs%/*}
        #echo "fs = $findfs"

        if [[ "$findfs" ]];then
            rm ${findfs} -rf
        else
            show_vir "$findfs not found !"
            return 1
        fi

    done < ${findfs_file}

    if [[ -f ${findfs_file} ]];then
        rm ${findfs_file} -rf
    else
        echo "$findfs_file not found !"
        return 1
    fi
}

##　批量删除指定文件
function deletefs()
{
    local deletefs=$1

    if [[ "$deletefs" ]];then
        gfind ${deletefs} | xargs rm -r
    else
        echo "$deletefs not found !"
        return 1
    fi
}

## 批量删除out目录
function rmoutfs()
{
    local project_name=`echo k26 k27 k86a k86m k86s k86sm k86l k86ls k86ld k88c`
    local project_path=""
    local tmp_path=/home/work5/jenkins/tmp

    for prj_name in ${project_name}
    do
        project_path=/home/jenkins/jobs/${prj_name}/android/out

        if [[ -d ${project_path} ]];then
            if [[ `hostname` == "s3" ]];then
                mv ${project_path} ${tmp_path}/out_${prj_name}
            else
                mv ${project_path} ${td}/out_${prj_name}
            fi
        else
            show_vir "$project_path not found !"
        fi
    done

    if [[ `hostname` == "s3" ]];then
        if [[ -d ${tmp_path} ]];then
            rm ${tmp_path}/* -rf
        fi
    else
        if [[ -d ${td} ]];then
            rm ${td}/* -rf
        fi
    fi
}

## 批量删除customs
function rmcustomsfs()
{
    local sz_base_path=~/jobs
    local customs_path=
    local sz_project_name=

    case `hostname` in

        s4)
            sz_project_name=`echo k86l k86ld k86l_root k86ls k86lsd k86ls_root k88c`
            ;;

        s3)
            sz_project_name=`echo k26 k27 k86l k86ls k86m_root k86s k88c k26s k86a k86a_root k86m k86mx2 k86sm`
            ;;

        s2)
            sz_project_name=`echo k86s k86sm k86s_root k88c k88c_21 k88c_root k88s k88s_root`
            ;;

        s1)
            sz_project_name=`echo k26 k26s k27 k86a k86l k86ls k86m k86s k86sm k88c`
            ;;

        *)
            _echo "it not project name"
            ;;
    esac

    for p in ${sz_project_name}
    do
        customs_path=${sz_base_path}/${p}/yunovo_customs

        if [[ -d ${customs_path} ]];then
            rm -rf ${customs_path}

            if [[ $? -eq 0 ]];then
                echo "--> customs path = $customs_path, rm successful ..."
            fi

        else
            echo "$customs_path is not exsit ..."
        fi
    done
}
