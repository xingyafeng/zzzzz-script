https://www.cnblogs.com/zhi-leaf/p/6282301.html
https://www.howtoing.com/how-to-set-up-time-synchronization-on-ubuntu-16-04

ubuntu16.04时间同步

# 查看时间
$ timedatectrl
      Local time: Tue 2021-01-26 09:56:43 CST  --> 本地时钟
  Universal time: Tue 2021-01-26 01:56:43 UTC　--> 世界时钟
        RTC time: Tue 2021-01-26 01:56:43　　　--> 实时时钟
       Time zone: Asia/Shanghai (CST, +0800)   --> 时区
Network time on: yes    -->　timesyncd 已启用
NTP synchronized: yes   -->　ntp时间　 已同步
RTC in local TZ: no     -->　网络时间同步

# 设置时区
sudo timedatectl set-timezone Asia/Shanghai

# 安装ntp服务
apt-get update;apt install ntp

# 开启ntp时间同步
sudo service ntp stop
sudo timedatectl set-ntp false
sudo service ntp start
sudo timedatectl set-ntp true
sudo timedatectl status