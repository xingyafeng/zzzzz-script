

Android --- 代码编译环服务器境搭建　ubuntu16.04

代理服务器：

    export http_proxy=http://10.129.93.241:3128
    export https_proxy=https:// 10.129.93.241:3128

代码编译环境服务器
-----------------------------------------------------

系统配置记录如下:

1/　系统版本信息

    root@build20:/etc/apt# lsb_release -a
    No LSB modules are available.
    Distributor ID:	Ubuntu
    Description:	Ubuntu 16.04.7 LTS
    Release:	16.04
    Codename:	xenial

2/ 配置源

    # See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
    # newer versions of the distribution.
    deb http://archive.ubuntu.com/ubuntu/ xenial main restricted
    # deb-src http://archive.ubuntu.com/ubuntu/ xenial main restricted
    
    ## Major bug fix updates produced after the final release of the
    ## distribution.
    deb http://archive.ubuntu.com/ubuntu/ xenial-updates main restricted
    # deb-src http://archive.ubuntu.com/ubuntu/ xenial-updates main restricted
    
    ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
    ## team. Also, please note that software in universe WILL NOT receive any
    ## review or updates from the Ubuntu security team.
    deb http://archive.ubuntu.com/ubuntu/ xenial universe
    # deb-src http://archive.ubuntu.com/ubuntu/ xenial universe
    deb http://archive.ubuntu.com/ubuntu/ xenial-updates universe
    # deb-src http://archive.ubuntu.com/ubuntu/ xenial-updates universe
    
    ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
    ## team, and may not be under a free licence. Please satisfy yourself as to
    ## your rights to use the software. Also, please note that software in
    ## multiverse WILL NOT receive any review or updates from the Ubuntu
    ## security team.
    deb http://archive.ubuntu.com/ubuntu/ xenial multiverse
    # deb-src http://archive.ubuntu.com/ubuntu/ xenial multiverse
    deb http://archive.ubuntu.com/ubuntu/ xenial-updates multiverse
    # deb-src http://archive.ubuntu.com/ubuntu/ xenial-updates multiverse
    
    ## N.B. software from this repository may not have been tested as
    ## extensively as that contained in the main release, although it includes
    ## newer versions of some applications which may provide useful features.
    ## Also, please note that software in backports WILL NOT receive any review
    ## or updates from the Ubuntu security team.
    deb http://archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse
    # deb-src http://archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse
    
    ## Uncomment the following two lines to add software from Canonical's
    ## 'partner' repository.
    ## This software is not part of Ubuntu, but is offered by Canonical and the
    ## respective vendors as a service to Ubuntu users.
    # deb http://archive.canonical.com/ubuntu xenial partner
    # deb-src http://archive.canonical.com/ubuntu xenial partner
    
    deb http://security.ubuntu.com/ubuntu/ xenial-security main restricted
    # deb-src http://security.ubuntu.com/ubuntu/ xenial-security main restricted
    deb http://security.ubuntu.com/ubuntu/ xenial-security universe
    # deb-src http://security.ubuntu.com/ubuntu/ xenial-security universe
    deb http://security.ubuntu.com/ubuntu/ xenial-security multiverse
    # deb-src http://security.ubuntu.com/ubuntu/ xenial-security multiverse
    deb http://172.26.41.69/ubuntu/ trusty main restricted

3/ 安装依赖

    # git
    add-apt-repository ppa:git-core/ppa
    
    # php
    add-apt-repository ppa:ondrej/php
    
    apt-get install php7.0 php-common php7.0-cli  php7.0-curl php7.0-fpm  php7.0-opcache php7.0-xml
    apt-get install git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip libssl-dev  libssl-dev  libswitch-perl 

    # openjdk
    sudo add-apt-repository ppa:openjdk-r/ppa  
    
    sudo apt-get install openjdk-8-jdk
    sudo update-alternatives --config java  
    sudo update-alternatives --config javac
    
    sudo apt-get build-dep python-imaging
    sudo apt-get install libjpeg8 libjpeg62-dev libfreetype6 libfreetype6-dev
    pip install --upgrade pip 
    sudo pip install Pillow

    # 官方依赖
    sudo apt-get install git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-mul tilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip

    # 新版本依赖
    apt-get install libssl-dev  libswitch-perl
    
    sudo apt-get install -y git gcc-mul tilib libncurses5-dev:i386 
    sudo apt-get install libx11-dev:i386 libreadline6-dev:i386 
    sudo apt-get install tofrodos python-markdown zlib1g-dev:i386 
    sudo apt-get install dpkg-dev libsdl1.2-dev libesd0-dev
    sudo apt-get install git-core gnupg flex bison gperf build-essential  
    sudo apt-get install zip curl zlib1g-dev gcc-multilib g++-multilib 
    sudo apt-get install libc6-dev-i386 
    sudo apt-get install lib32ncurses5-dev x11proto-core-dev libx11-dev 
    sudo apt-get install lib32z-dev ccache
    sudo apt-get install libgl1-mesa-dev libxml2-utils xsltproc unzip m4    

4/ 安装open JDK8

    sudo add-apt-repository ppa:openjdk-r/ppa 
    sudo apt-get update
    sudo apt-get install openjdk-8-jdk 
    
    sudo gedit /etc/profile
         
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    export JRE_HOME=${JAVA_HOME}/jre 
    export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib 
    export PATH=${JAVA_HOME}/bin:$PATH


编译遇到的问题点，记录方便后续　制作dockerfile：
----------------------------------------------------------------------------------------------------
1/ 

FAILED: out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared/res/values/isdm_Jrdshared_defaults.xml 
/bin/bash -c "(if [ \"Jrdshared\" = \"Jrdshared\" ]; then echo \"copy isdm_telecom_Jrdshared.plf to isdm_Jrdshared.plf......\"; cp -f out/target/common/jrdResAssetsCust/wimdata/wprocedures/plf/isdm_telecom_Jrdshared.plf out/target/common/jrdResAssetsCust/wimdata/wprocedures/plf/isdm_Jrdshared.plf;touch out/target/common/jrdResAssetsCust/wimdata/wprocedures/plf/isdm_telecom_Jrdshared.plf; fi ) && (mkdir -p out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values ) && (if [ -f out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml ]; then rm -rf out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml;fi ) && (LD_LIBRARY_PATH=makeperso/build/jrdtools/prd2xml makeperso/build/jrdtools/prd2xml/prd2h --def makeperso/build/jrdtools/prd2xml/prd2h_def.xml --dest out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values out/target/common/jrdResAssetsCust/wimdata/wprocedures/plf/isdm_Jrdshared.plf ) && (rm -f out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_struct.h ) && (rm -f out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_value.h ) && (rm -f out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_*.log ) && (mv out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_android.xml out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml ) && (if [ \"Jrdshared\" = \"Jrdshared\" ]; then echo \"generating symbols.xml......\"; python vendor/jrdcom/build/common/xml-process.py out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/jrd_symbols.xml; sed -i 's/aaaatype/type/g' out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/jrd_symbols.xml; fi ) && (mkdir -p out/target/product/a3a84g/obj/APPS/Jrdshared_intermediates/flat-res/vendor/jrdcom/proprietary/Jrdshared//res/ ) && (out/host/linux-x86/bin/aapt2 compile -o out/target/product/a3a84g/obj/APPS/Jrdshared_intermediates/flat-res/vendor/jrdcom/proprietary/Jrdshared//res/  --legacy out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml ) && (echo -n \$(find out/target/product/a3a84g/obj/APPS/Jrdshared_intermediates/flat-res -name 'values_isdm_*_defaults.arsc.flat' -and -type f) > out/target/product/a3a84g/obj/APPS/Jrdshared_intermediates/aapt2-flat-isdm-list )"
copy isdm_telecom_Jrdshared.plf to isdm_Jrdshared.plf......
makeperso/build/jrdtools/prd2xml/prd2h: error while loading shared libraries: libXext.so.6: cannot open shared object file: No such file or directory
[  0% 10/2988] TEE build: out/target/product/a3a84g/trustzone/trustlet/fpc_ta/Debug/04010000000000000000000000000000.tlbin
******************************************
Trusted Application Build
******************************************
- GP_ENTRYPOINTS is not set, default is : N
- TA_INTERFACE_VERSION  is  not  set,  default  is : 0.0

解决方法：
sudo apt-get install libxtst6:i386

2/

FAILED: out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared/res/values/isdm_Jrdshared_defaults.xml 
/bin/bash -c "(if [ \"Jrdshared\" = \"Jrdshared\" ]; then echo \"copy isdm_telecom_Jrdshared.plf to isdm_Jrdshared.plf......\"; cp -f out/target/common/jrdResAssetsCust/wimdata/wprocedures/plf/isdm_telecom_Jrdshared.plf out/target/common/jrdResAssetsCust/wimdata/wprocedures/plf/isdm_Jrdshared.plf;touch out/target/common/jrdResAssetsCust/wimdata/wprocedures/plf/isdm_telecom_Jrdshared.plf; fi ) && (mkdir -p out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values ) && (if [ -f out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml ]; then rm -rf out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml;fi ) && (LD_LIBRARY_PATH=makeperso/build/jrdtools/prd2xml makeperso/build/jrdtools/prd2xml/prd2h --def makeperso/build/jrdtools/prd2xml/prd2h_def.xml --dest out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values out/target/common/jrdResAssetsCust/wimdata/wprocedures/plf/isdm_Jrdshared.plf ) && (rm -f out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_struct.h ) && (rm -f out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_value.h ) && (rm -f out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_*.log ) && (mv out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_android.xml out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml ) && (if [ \"Jrdshared\" = \"Jrdshared\" ]; then echo \"generating symbols.xml......\"; python vendor/jrdcom/build/common/xml-process.py out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/jrd_symbols.xml; sed -i 's/aaaatype/type/g' out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/jrd_symbols.xml; fi ) && (mkdir -p out/target/product/a3a84g/obj/APPS/Jrdshared_intermediates/flat-res/vendor/jrdcom/proprietary/Jrdshared//res/ ) && (out/host/linux-x86/bin/aapt2 compile -o out/target/product/a3a84g/obj/APPS/Jrdshared_intermediates/flat-res/vendor/jrdcom/proprietary/Jrdshared//res/  --legacy out/target/common/jrdResAssetsCust/vendor/jrdcom/proprietary/Jrdshared//res/values/isdm_Jrdshared_defaults.xml ) && (echo -n \$(find out/target/product/a3a84g/obj/APPS/Jrdshared_intermediates/flat-res -name 'values_isdm_*_defaults.arsc.flat' -and -type f) > out/target/product/a3a84g/obj/APPS/Jrdshared_intermediates/aapt2-flat-isdm-list )"
copy isdm_telecom_Jrdshared.plf to isdm_Jrdshared.plf......
makeperso/build/jrdtools/prd2xml/prd2h: error while loading shared libraries: libXrender.so.1: cannot open shared object file: No such file or directory
[  0% 14/2979] Ensuring Jack server is installed and started

解决方法：
32位库文件
apt-get install libxrender1:i386

64位库文件
apt-get install libxrender1


3/

/bin/sh: 1: bc: not found

解决方法：
apt install bc
