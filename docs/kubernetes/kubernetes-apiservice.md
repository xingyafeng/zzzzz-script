

k8s下载：https://github.com/kubernetes/kubernetes

apiservice 搭建

# 证书详解
https://www.cnblogs.com/deny/p/12259778.html

# 创建证书 client
sudo cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-crs.json | cfssljson -bare client

<!!! 注意-profile 参数  >

vi client-crs.json
{
    "CN": "k8s-node",
    "hosts": [
	],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "GuangDong",
            "O": "TCT",
            "ST": "ShenZhen",
            "OU": "INT"
        }
    ]
}

# 创建证书 apiserver
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server apiserver-csr.json | cfssljson -bare apiserver

<!!! 注意-profile 参数  >

cat apiserver-csr.json
{
    "CN": "k8s-apiserver",
    "hosts": [
	"127.0.0.1",
	"10.129.93.164",
	"10.129.93.165",
	"10.129.93.166",
	"10.129.93.167",
	"m10",
	"m11",
	"m12",
	"m13",
	"kubernetes",
	"kubernetes.default",
	"kubernetes.default.svc",
	"kubernetes.default.svc.cluster",
	"kubernetes.default.svc.cluster.local"
	],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "GuangDong",
            "O": "TCT",
            "ST": "ShenZhen",
            "OU": "INT"
        }
    ]
}


配置文件：

1\ audit.yml # 日志审计清单
2\

配置开机启动
/etc/systemd/system/kub-apiserver.service

[Unit]
Description=Kubernetes API Service
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/tmp/kubernetes/server/bin/conf/kub-apiserver.conf
ExecStart=/usr/bin/kube-apiserver \
            $KUBE_LOGTOSTDERR \
            $KUBE_LOG_LEVEL \
            $KUBE_ETCD_SERVERS \
            $KUBE_API_ADDRESS \
            $KUBE_API_PORT \
            $KUBELET_PORT \
            $KUBE_ALLOW_PRIV \
            $KUBE_SERVICE_ADDRESSES \
            $KUBE_ADMISSION_CONTROL \
            $KUBE_API_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

/etc/kubernetes/config

该配置文件同时被kube-apiserver、kube-controller-manager、kube-scheduler、kubelet、kube-proxy使用。

###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
#日志默认存储方式，默认存储在系统的journal服务中,设置为true后日志不输出到文件
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
#日志等级
KUBE_LOG_LEVEL="--v=0"
KUBE_LOG_LEVEL="--v=0"                                 

# Should this cluster be allowed to run privileged docker containers
#如果设置为true，则k8s将允许在pod中运行拥有系统特权的容器应用，与docker run --privileged的功效相同
KUBE_ALLOW_PRIV="--allow-privileged=false"    

# How the controller-manager, scheduler, and proxy find the apiserver
#KUBE_MASTER="--master=http://sz-pg-oam-docker-test-001.tendcloud.com:8080"
#KUBE_MASTER="--master=http://m10:8080"
#kubernetes Master的apiserver地址和端口
KUBE_MASTER="--master=http://10.129.93.164:8080"

----- /etc/kubernetes/config end


# 关键的配置文件
/etc/kubernetes/token.csv 

/tmp/kubernetes/server/bin/conf/kub-apiserver.conf

###
## kubernetes system config
##
## The following values are used to configure the kube-apiserver
##
#
## The address on the local server to listen to.
#KUBE_API_ADDRESS="--insecure-bind-address=sz-pg-oam-docker-test-001.tendcloud.com"
#aipServer的监听地址，默认为127.0.0.1，若要配置集群，则要设置为0.0.0.0才能被其他主机找到
KUBE_API_ADDRESS="--advertise-address=10.129.93.164 --bind-address=10.129.93.164 --insecure-bind-address=10.129.93.164"
#
## The port on the local server to listen on.
#apiserver的监听端口，默认8080是用于接收http请求，6443用于接收https请求。可以不用写
#KUBE_API_PORT="--port=8080"
#
## Port minions listen on
# kubelet的监听端口，若只作为Master节点则可以不配置
#KUBELET_PORT="--kubelet-port=10250"
#
## Comma separated list of nodes in the etcd cluster
# etcd地址
KUBE_ETCD_SERVERS="--etcd-servers=https://10.129.93.164:2379,10.129.93.165:2379,10.129.93.166:2379"
#
## Address range to use for services
# service的地址范围，用于创建service的时候自动生成或指定serviceIP使用
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.129.0.0/16"
#
## default admission control policies
#为了避免做用户认证，取消掉了ServiceAccount参数f
KUBE_ADMISSION_CONTROL="--admission-control=ServiceAccount,NamespaceLifecycle,NamespaceExists,LimitRanger,ResourceQuota"
#
## Add your own!
#此处可以添加其他配置
KUBE_API_ARGS="--authorization-mode=RBAC --runtime-config=rbac.authorization.k8s.io/v1beta1 --kubelet-https=true --experimental-bootstrap-token-auth --token-auth-file=/etc/kubernetes/token.csv --service-node-port-range=30000-32767 --tls-cert-file=/tmp/kubernetes/server/bin/cert/apiserver.pem --tls-private-key-file=/tmp/kubernetes/server/bin/cert/apiserver-key.pem --client-ca-file=/tmp/kubernetes/server/bin/cert/ca.pem --service-account-key-file=/tmp/kubernetes/server/bin/cert/ca-key.pem --etcd-cafile=/etc/kubernetes/ssl/ca.pem --etcd-certfile=/tmp/kubernetes/server/bin/cert/kubernetes.pem --etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem --enable-swagger-ui=true --apiserver-count=3 --audit-log-maxage=30 --audit-log-maxbackup=3 --audit-log-maxsize=100 --audit-log-path=/var/lib/audit.log --event-ttl=1h"
