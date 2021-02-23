
# 制作启动盘　UltraISO

# ubuntu iso 下载:
OS镜像: https://developer.aliyun.com/mirror/?spm=a2c6h.12883283.1362934.3.3396201ceDROld

# 进入BIOS

hp      F8
lenovo  F2

# 修改root密码
sudo passwd root

# 修改hostname
cat /etc/hosts
cat /etc/hostname

# 配置源

    1> default
    2> 163网易
    3> 163阿里云

    apt命令：
    sudo apt-get update  更新源
    sudo apt-get install package 安装包
    sudo apt-get remove package 删除包
    sudo apt-cache search package 搜索软件包
    sudo apt-cache show package  获取包的相关信息，如说明、大小、版本等
    sudo apt-get install package --reinstall  重新安装包
    sudo apt-get -f install  修复安装
    sudo apt-get remove package --purge 删除包，包括配置文件等
    sudo apt-get build-dep package 安装相关的编译环境
    sudo apt-get upgrade 更新已安装的包
    sudo apt-get dist-upgrade 升级系统
    sudo apt-cache depends package 了解使用该包依赖那些包
    sudo apt-cache rdepends package 查看该包被哪些包依赖
    sudo apt-get source package  下载该包的源代码
    sudo apt-get clean && sudo apt-get autoclean 清理无用的包
    sudo apt-get check 检查是否有损坏的依赖

# 下载软件

    export http_proxy=http://10.129.93.241:3128 && export http_proxys=http://10.129.93.241:3128 && apt-get update;apt install lsof xmlstarlet openjdk-8-jdk zip nfs-kernel-server nfs-common -y
    
    配置代理，并更新
    export http_proxy=http://10.129.93.241:3128 
    export http_proxys=http://10.129.93.241:3128 
    apt-get update;

    1> lsof 
    2> xmlstarlet 
    3> openjdk-8-jdk 
    4> zip 
    5> nfs-kernel-server nfs-common  # nfs服务器和客户端

# 配置ssh


# 配置vim插件　https://github.com/hominlinx/vim
sudo apt-get install zlib1g-dev libbz2-dev libssl-dev libncurses5-dev libsqlite3-dev libreadline-dev tk-dev libgdbm-dev libdb-dev libpcap-dev xz-utils libexpat1-dev liblzma-dev libffi-dev libc6-dev

遇到的问题： 
~/.vim/bundle/YouCompleteMe $ ./install.sh --clang-completer
WARNING: this script is deprecated. Use the install.py script instead.
Searching Python 3.7 libraries...
ERROR: found static Python library (/usr/bin/python3.7/lib/python3.7/config-3.7m-x86_64-linux-gnu/libpython3.7m.a) but a dynamic one is required. You must use a Python compiled with the --enable-shared flag. If using pyenv, you need to run the command:
  export PYTHON_CONFIGURE_OPTS="--enable-shared"
before installing a Python version.

上述错误，是由于编译python3.7版本未生成动态库导致，编译install 不能执行完成．需要重新编译python3.7生产动态库解决
在配置的时候，增加参数　--enable-shared,如下：

./configure --prefix=/usr/local --enable-optimizations --enable-shared
make -j8 
sudo make install

2.

sudo vi /etc/ld.so.conf.d/python3.7.5.conf

增空　python的源码路径中的so

GCC 8 on Ubuntu 16.04

sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install gcc-8 g++-8
gcc-8 --version

