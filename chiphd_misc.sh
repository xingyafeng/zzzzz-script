#!/usr/bin/env bash

#### define PS1 env color
export pwd_black='\[\e[30m\]'
export pwd_red='\[\e[31m\]'
export pwd_green='\[\e[32m\]'
export pwd_yellow='\[\e[33m\]'
export pwd_blue='\[\e[34m\]'
export pwd_purple='\[\e[35m\]'
export pwd_cyan='\[\e[36m\]'
export pwd_white='\[\e[37m\]'
export pwd_default='\[\e[0m\]'
export pwd_bold='\[\e[1m\]'

unset PS1
export PS1="$pwd_green$pwd_bold\u@\h$pwd_purple$pwd_bold $pwd_purple$pwd_bold\w $ $pwd_default"

function mkdir_data_folder()
{
    local da=$workspace/date
    local time_date=`date +%m%d`
    local td=$da/$time_date

    if [ ! -e "$da/$time_date"  ];then
        mkdir -p $da/$time_date
    fi
}

function auto_running_jenkins()
{
    local jenkins_war_path=/home/work5/jenkins/jenkins.war
    local jenkins_war=jenkins.war

    if [ -f $jenkins_war_path ];then

        if [ "`ps aux | grep jenkins.war | grep -v "color=auto" | awk '{print $13}'`" != "$jenkins_war" ];then
            java -jar $jenkins_war_path --httpPort=8089 --daemon
        fi
    else
        echo " $jenkins_war_path is no found ..."
    fi

}

function set_alias()
{
    ### grep
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    # some more ls aliases
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
}

### 是否为编译服务器
function is_yunovo_server
{
    local yunovo_server=`echo s1 s2 s3 s4 f1 happysongs`
    local hostN=`hostname`

    for n in $yunovo_server
    do
        if [ $n == $hostN ];then
            echo true
        fi
    done
}

### 是否为云智易联项目
function is_yunovo_project
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    case $thisP in

        $k26P | $k26PR)
            echo true

            ;;
        $k26sP | $k26sPR)
            echo true

            ;;
        $k27P | $k27PR)
            echo true

            ;;
        $k86aP | $k86aPR)
            echo true

            ;;
        $k86mP | $k86mPR)
            echo true

            ;;
        $k86mx2P | $k86m2xPR)
            echo true

            ;;
        $k86sP | $k86sPR)
            echo true

            ;;
        $k86smP | $k86smPR)
            echo true

            ;;
        $k86lP | $k86lPR)
            echo true

            ;;
        $k86lsP | $k86lsPR)
            echo true

            ;;
        $k86ldP | $k86ldPR)
            echo true

            ;;
        $k86lsdP | $k86lsdPR)
            echo true

            ;;
        $k88cP | $k88cPR)
            echo true

            ;;
        $k88sP | $k88sPR)
            echo true

            ;;

        *)
            echo false

            ;;
    esac
}

### 获取当前编译项目名称
function get_project_real_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}

    if [ "$thisP" ];then
        echo $thisP
    else
        echo "it do not get project name !"
        return 1
    fi
}

function get_project_name()
{
    local thisP=$(pwd) && thisP=${thisP%/*} && thisP=${thisP##*/}
    local project_name=($k26P $k86aP $k86mP $k86sP $k86smP $k86lP $k86lsP $k86ldP $k88cP)
    local isroot=false

    if [ "$thisP" ];then

        for p in ${project_name[@]}
        do
            if [ "$thisP" == "${p}_root" ];then
                isroot=true
                echo $p
            fi
        done

        if [ "$isroot" == "false" ];then
            echo $thisP
        fi
    else
        echo "it do not get project name !"
        return 1
    fi
}

function get_system_app_type()
{
    local zzz_path=~/workspace/script/zzzzz-script
    local app_path=$zzz_path/yunovo_app.txt
    local apk_path=$zzz_path/yunovo_apk.txt
    local allapps_path=$zzz_path/fs/allapp.txt
    local findfs=out/target/product/aeon6735_65c_s_l1/system/

    find $findfs -name "*.apk" | grep app | sed 's/.*app\/\([^\/]*\).*/\1/g' | sort > $allapps_path

    echo
    show_vir "-----------------------------------apk"
    while read p;do
        while read apk;do
            if [ $p == $apk ];then
                show_vip "-- $apk"
            fi
        done < $apk_path
    done < $allapps_path

    echo
    show_vir "----------------------------------app"

    while read p;do
        while read app;do
            if [ $p == $app ];then
                show_vip "---- $app"
            fi
        done < $app_path
    done < $allapps_path
}

function remove_space_for_vairable()
{
    ## 去掉空格后的变量
    local new_v=
    local old_v=$1
    local tmp_file=~/workspace/script/zzzzz-script/tmp.txt

    new_v=`cat $tmp_file | sed 's/[ ]\+//g'`

    if [ "$new_v" != "$old_v"  ];then
        echo $new_v
    else
        echo $old_v
    fi

    if [ -f $tmp_file ];then
        rm $tmp_file -r
    fi
}
