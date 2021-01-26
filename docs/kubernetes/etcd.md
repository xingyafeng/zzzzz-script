https://github.com/etcd-io/etcd/releases
https://cloud.tencent.com/developer/article/1577995

etcd集群
----------------------------------------------------------------------------------------------------

# 创建文件夹
sudo mkdir -p /var/lib/etcd
sudo mkdir -p /opt/config
sudo mkdir -p /opt/bin

# 创建文件
sudo touch /opt/config/etcd.conf

#[Member]
ETCD_NAME="kub-node-0"
ETCD_DATA_DIR=/var/lib/etcd
ETCD_LISTEN_PEER_URLS=http://10.129.93.164:2380
ETCD_LISTEN_CLIENT_URLS=http://10.129.93.164:2379,http://127.0.0.1:2379

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS=http://10.129.93.164:2380
ETCD_ADVERTISE_CLIENT_URLS=http://10.129.93.164:2379
ETCD_INITIAL_CLUSTER="kub-node-0=http://10.129.93.164:2380,kub-node-1=http://10.129.93.165:2380,kub-node-2=http://10.129.93.166:2380"
ETCD_INITIAL_CLUSTER_STATE=new
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ENABLE_V2="true"

#[Security]
ETCD_CERT_FILE="/opt/ssl/etcd.pem"
ETCD_KEY_FILE="/opt/ssl/etcd-key.pem"
ETCD_TRUSTED_CA_FILE="/opt/ssl/ca.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_PEER_CERT_FILE="/opt/ssl/etcd.pem"
ETCD_PEER_KEY_FILE="/opt/ssl/etcd-key.pem"
ETCD_PEER_TRUSTED_CA_FILE="/opt/ssl/ca.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"

etcd 证书
# https://www.cnblogs.com/linuxws/p/11194403.html # 名词解释
# https://www.cnblogs.com/stonecode/p/12502399.html ## 证书字段的说明
# https://blog.csdn.net/liangweihua123/article/details/89240884 　cfssl下载
# https://www.cnblogs.com/stonecode/p/12502399.html 

# 1. 下载
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

# 2. 赋予执行
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64

# 3. 重命名
mv cfssl_linux-amd64 /usr/bin/cfssl
mv cfssljson_linux-amd64 /usr/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo

# 通过ca-csr.json生成
sudo cfssl gencert -initca ca-csr.json | sudo cfssljson -bare ca -

# 通过etcd-csr.json生成
sudo cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=etcd etcd-csr.json | sudo cfssljson -bare etcd

# 通过kubernetes-csr.json生成
sudo cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | sudo cfssljson -bare kubernetes

<注意　warning 忽略>

ca.csr ca.pem　---- (ca公钥 两个文件) 
ca-key.pem　　 ---- (ca私钥,妥善保管)

注意配置权限．
sudo chown etcd:etcd /opt/ssl

# 解压 etcd版本
tar zxvf kubernetes/etcd/etcd-v3.4.14-linux-amd64.tar.gz -C /tmp/
sudo cp /tmp/etcd-v3.4.14-linux-amd64/. /opt/bin/ -r

# 配置开机启动
$ sudo vim /etc/systemd/system/etcd.service 
[Unit]
Description=etcd - highly-available key value store
Documentation=https://github.com/etcd-io/etcd
Documentation=man:etcd
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
User=etcd
Type=notify
EnvironmentFile=-/opt/config/etcd.conf
ExecStart=/opt/bin/etcd
Restart=on-failure
LimitNOFILE=65536
RestartSec=10s

[Install]
WantedBy=multi-user.target
Alias=etcdxx.service

$ sudo systemctl daemon-reload
$ sudo systemctl stop etcd.service
$ sudo systemctl restart etcd.service

$ sudo cat /var/log/syslog |grep etcd
$ sudo journalctl -xe -u etcd
$ sudo systemctl status etc.service -u etcd

# 查看集群的健康状态
/opt/bin/etcdctl --cacert=/opt/ssl/ca.pem --cert=/opt/ssl/etcd.pem --key=/opt/ssl/etcd-key.pem --endpoints=http://10.129.93.164:2379,http://10.129.93.165:2379,http://10.129.93.166:2379 endpoint health
/opt/bin/etcdctl --cacert=/opt/ssl/ca.pem --cert=/opt/ssl/etcd.pem --key=/opt/ssl/etcd-key.pem --endpoints=http://10.129.93.164:2379,http://10.129.93.165:2379,http://10.129.93.166:2379 endpoint status --write-out=table

# 分析故障
----------------------------------------------------------------------------------------------------
# 查看启动失败的原因
sudo journalctl -xe -u etcd
sudo systemctl status etc.service -u etcd

# 网络
sudo netstat -apn | grep 2379
etcdctl member list
/opt/bin/etcdctl --endpoints="http://10.129.93.164:2379,http://10.129.93.165:2379,http://10.129.93.166:2379" endpoint status --write-out=table 


# 遇到的问题

一, 相应失败
6月 08 03:46:26 vmnode1 etcd[46641]: publish error: etcdserver: request timed out

二， 
6月 08 11:09:36 vmnode0 etcd[11820]: rejected connection from "192.168.200.81:48552" (error "remote error: tls: bad certificate", ServerName "")
6月 08 11:09:36 vmnode0 etcd[11820]: rejected connection from "192.168.200.81:48554" (error "remote error: tls: bad certificate", ServerName "")
6月 08 11:09:36 vmnode0 etcd[11820]: request sent was ignored (cluster ID mismatch: peer[39a8adcf41828c16]=bf653702878aa654, local=aff16232db8b0940)
6月 08 11:09:36 vmnode0 etcd[11820]: request sent was ignored (cluster ID mismatch: peer[39a8adcf41828c16]=bf653702878aa654, local=aff16232db8b0940)

三，
6月 08 04:01:46 vmnode1 etcd[46706]: request cluster ID mismatch (got aff16232db8b0940 want bf653702878aa654)
6月 08 04:01:46 vmnode1 etcd[46706]: request cluster ID mismatch (got aff16232db8b0940 want bf653702878aa654)
6月 08 04:01:46 vmnode1 etcd[46706]: request cluster ID mismatch (got aff16232db8b0940 want bf653702878aa654)

先查看防火墙是否开启，firewalld
在查看 data-dir=/var/lib/etcd 的缓存情况，清除一下
注意端口不能ip不能重复，　sudo journalctl -xe -u etcd　log 可以查出来
注意etcd集群要一起启动，当个启动也会出现连接失败的问题

# -------------------------------------------------------------------------------------------------- 参考内容
1. 备份原先的etcd配置文件。
cp /etc/etcd/etcd.conf /etc/etcd/etcd.conf.bak
ETCD_NAME="node235"
ETCD_DATA_DIR="/var/lib/etcd/node235.etcd"
ETCD_LISTEN_PEER_URLS="http://10.40.239.235:2380"
ETCD_LISTEN_CLIENT_URLS="http://10.40.239.235:2379,http://localhost:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.40.239.235:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://10.40.239.235:2379"
ETCD_INITIAL_CLUSTER="node234=http://10.40.239.234:2380,node235=http://10.40.239.235:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

这里解释一下这些参数的含义：
ETCD_NAME：此成员的名字。ETCD的节点名，在集群中应该保持唯一，可以使用 hostname。
ETCD_DATA_DIR：数据存储目录。由etcd自动创建。服务运行数据保存的路径，默认为 ${name}.etcd。
ETCD_LISTEN_PEER_URLS：监听在对等节点流量上的URL列表，该参数告诉etcd在指定的 “协议://IP:端口”组合上接收来自其对等方的传入请求。协议可以是http或者https。或者，使用unix://<file-path>或者unixs://<file-path>到unix sockets。如果将0.0.0.0作为IP，etcd将监听在所有的接口上的给定端口。如果给定了IP和端口，etcd将监听指定的接口和端口。可以使用多个URL指定要监听的地址和端口的数量。 etcd将响应来自任何列出的地址和端口的请求。
ETCD_LISTEN_CLIENT_URLS：监听在客户端流量上的URL列表，该参数告诉etcd在指定的“协议://IP:端口”组合上接受来自客户端的传入请求。协议可以是http或者https。或者，使用unix://<file-path>或者unixs://<file-path>到unix sockets。如果将0.0.0.0作为IP，etcd将监听在所有的接口上的给定端口。如果给定了Ip和端口，etcd将监听指定的接口和端口。可以使用多个URL指定要监听的地址和端口的数量。 etcd将响应来自任何列出的地址和端口的请求。
ETCD_INITIAL_ADVERTISE_PEER_URLS：此成员对等URL的列表，用来通知到集群的其余部分。 这些地址用于在集群周围传送etcd数据。 所有集群成员必须至少有一个路由。 这些URL可以包含域名。
ETCD_ADVERTISE_CLIENT_URLS：此成员的客户端URL的列表，这些URL广播给集群的其余部分。 这些URL可以包含域名。
ETCD_INITIAL_CLUSTER：启动集群的初始化配置。配置集群的成员。
ETCD_INITIAL_CLUSTER_TOKEN：引导期间etcd群集的初始集群令牌。
ETCD_INITIAL_CLUSTER_STATE：初始群集状态（“新”或“现有”）。 对于在初始静态或DNS引导过程中存在的所有成员，将其设置为new。 如果此选项设置为existing，则etcd将尝试加入现存集群。 如果设置了错误的值，etcd将尝试启动，但会安全地失败。

ETCD_SNAPSHOT_COUNTER：多少次的事务提交将触发一次快照，指定有多少事务（transaction）被提交时，触发截取快照保存到磁盘。
ETCD_HEARTBEAT_INTERVAL：ETCD节点之间心跳传输的间隔，单位毫秒，leader 多久发送一次心跳到 followers。默认值是 100ms。
ETCD_ELECTION_TIMEOUT：该节点参与选举的最大超时时间，单位毫秒，重新投票的超时时间，如果 follow 在该时间间隔没有收到心跳包，会触发重新投票，默认为 1000 ms。
ETCD_LISTEN_PEER_URLS：该节点与其他节点通信时所监听的地址列表，多个地址使用逗号隔开，其格式可以划分为scheme://IP:PORT，这里的scheme可以是http、https。和同伴通信的地址，比如 http://ip:2380 ，如果有多个，使用逗号分隔。需要所有节点都能够访问，所以不要使用 localhost。ETCD_LISTEN_CLIENT_URLS：该节点与客户端通信时监听的地址列表，对外提供服务的地址：比如 http://ip:2379 ,http://127.0.0.1:2379 ，客户端会连接到这里和 etcd 交互ETCD_INITIAL_ADVERTISE_PEER_URLS：该成员节点在整个集群中的通信地址列表，这个地址用来传输集群数据的地址。因此这个地址必须是可以连接集群中所有的成员的。该节点同伴监听地址，这个值会告诉集群中其他节点。
ETCD_INITIAL_CLUSTER：配置集群内部所有成员地址，其格式为：ETCD_NAME=ETCD_INITIAL_ADVERTISE_PEER_URLS，如果有多个使用逗号隔开，集群中所有节点的信息，格式为 node1=http://ip1:2380 ,node2=http://ip2:2380 ,…。注意：这里的 node1 是节点的 –name 指定的名字；后面的 ip1:2380 是 –initial-advertise-peer-urls 指定的值ETCD_ADVERTISE_CLIENT_URLS：广播给集群中其他成员自己的客户端地址列表
ETCD_INITIAL_CLUSTER_STATE：新建集群的时候，这个值为new；假如已经存在的集群，这个值为 existing。
ETCD_INITIAL_CLUSTER_TOKEN:初始化集群token，创建集群的token，这个值每个集群保持唯一。这样的话，如果你要重新创建集群，即使配置和之前一样，也会再次生成新的集群和节点 uuid；否则会导致多个集群之间的冲突，造成未知的错误。