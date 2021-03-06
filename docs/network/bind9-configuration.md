# 日志配置　logging
http://www.jquerycn.cn/a_7595
https://www.jianshu.com/p/b5302409e9ed
https://blog.csdn.net/yockie/article/details/8350229

# bind9配置
https://blog.csdn.net/zmnbehappy/article/details/85157911

如何在Ubuntu16.04上将BIND配置为专用网络DNS服务器

NS1 主DNS服务器

# 1. install
在DNS服务器上安装BIND

$ sudo apt-get update
$ sudo apt-get install bind9 bind9utils bind9-doc


# 2 config

named.conf.options
------------------------- 内容

## 说明：ACL块　这是我们将定义客户端列表的地方，我们将允许递归DNS查询（即与ns1在同一数据中心的服务器）。
acl "trusted" {
        10.129.46.47;   # ns1 - can be set to localhost
        10.129.93.104;  # host4
        10.129.93.105;  # host5
        10.129.93.106;  # host6
};

options {
        directory "/var/cache/bind";

        // If there is a firewall between you and nameservers you want
        // to talk to, you may need to fix the firewall to allow multiple
        // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

        // If your ISP provided one or more IP addresses for stable
        // nameservers, you probably want to use them as forwarders.
        // Uncomment the following block, and insert the addresses replacing
        // the all-0's placeholder.

        forwarders {
                10.129.72.132;
        };

        //========================================================================
        // If BIND logs error messages about the root key being expired,
        // you will need to update your keys.  See https://www.isc.org/bind-keys
        //========================================================================
        dnssec-enable no;　　　//dns安全扩展　启用
        dnssec-validation no;　//dns安全扩展　验证

        auth-nxdomain no;    # conform to RFC1035 //符合RFC1035
        listen-on port 53 { any; }; # 让任意ip监听

        recursion yes;                 # enables resursive queries 递归查询
        allow-recursion { any; };  　　# allows recursive queries from "trusted" clients 配置白名单
        listen-on port 53 { 127.0.0.1; 10.129.46.47; };   # ns1 private IP address - listen on private network only
        allow-transfer { none; };      # disable zone transfers by default # 转发是否允许
};


# zone　配置说明
zone "你要配置的域名" {
        type master;
        file "正向解析文件的所在位置";
};
zone "反向输入你的ip地址.in-addr.arpa"{
        type master;
        file "反向解析文件的所在的位置";
};

named.conf.local
------------------------- 内容
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "tct.com" IN {
    type master;
    file "/etc/bind/zones/db.tct.com"; # zone file path
    allow-transfer { 10.129.46.47; };  # ns2 private IP address - secondary
    allow-update { none; };
};

zone "129.10.in-addr.arpa" IN {
    type master;
    file "/etc/bind/zones/db.10.129";  # 10.129.0.0/16 subnet
    allow-transfer { 10.129.46.47; };           # ns2 private IP address - secondary
    allow-update { none; };
};


mkdir /etc/bind/zones
touch db.tct.com db.10.129

db.tct.com <- db.local

;
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	ns1.tct.com. admin.tct.com. (
			      3		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
; name servers - NS records
     IN      NS      ns1.tct.com.

; name servers - A records
ns1          IN      A       10.129.46.47

; 短域名
; 10.128.0.0/16 - A records
host4        IN      A       10.129.93.104
host5        IN      A       10.129.93.105
host6        IN      A       10.129.93.106
host7        IN      A       10.129.93.107
host8        IN      A       10.129.93.108
host9        IN      A       10.129.93.109


db.10.129　<- db.127 　
# 特别注意　配置PRT ip也要反过来
;
; BIND reverse data file for local loopback interface
;
$TTL	604800
@	IN	SOA	tct.com. admin.tct.com. (
			      3		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL

; name servers
        IN      NS      ns1.tct.com.

; PTR Records
; 注意 IP要倒着写 10.129.46.47 <--> 47.46.129.10 # 129.10 已经倒了，不用再次写入
47.46   IN      PTR     ns1.tct.com.
104.93  IN      PTR     host4

sudo named-checkzone tct.com /etc/bind/zones/db.tct.com
sudo named-checkzone 128.10.in-addr.arpa /etc/bind/zones/db.10.128

# 重启BIND：
sudo systemctl restart bind9
sudo /etc/init.d/bind9 restart  

# 如果已配置UFW防火墙，请键入以下命令以打开对BIND的访问权限：
sudo ufw allow Bind9

#查看启动日志文件
tail /var/log/syslog

# 配置bind　日志
/var/cache/bind/query.log

|---------------------------------------------------------------------------------------------------

Ubuntu客户端

vi /etc/network/interfaces
dns-nameservers 10.129.46.47
dns-search tct.com

cat /etc/resolv.conf
cat /etc/resolvconf/resolv.conf.d/base

# 配置客户端

# /etc/resolvconf/resolv.conf.d/tail 

# /etc/resolvconf/resolv.conf.d/head
nameserver 10.128.180.22

# /etc/resolvconf/resolv.conf.d/base
nameserver 10.129.72.132
search hq.ta-mp.com tct.com

sudo resolvconf -u
sudo /etc/init.d/networking restart

Output
# Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)
#     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
search tct.com
nameserver 10.129.46.47


测试客户端

sudo yum install bind-utils

#正向查找
nslookup host1
dig -t A s4.tct.com +short <==> dig s4.tct.com +short

#反向查找
nslookup 10.129.46.53
dig -x 10.128.180.22 +short
dig -x 10.129.93.104 +short


# 参考资料
https://cloud.tencent.com/developer/article/1346240
https://www.dazhuanlan.com/2019/10/11/5d9f79926ebe1/
https://www.jianshu.com/p/8efb3bbc180a