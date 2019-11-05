#!/bin/bash

function setEnv(){
    cd `cd $(dirname $0) && pwd`
    hostName=$1
    ipPrefix=$2
    nodeCount=$3
    source /etc/profile
}

function addHosts(){
    for x in `seq 1 ${nodeCount}`
    do
        if [[ ${x} -eq 1 ]]
        then
            tmpHostName=k8s-master01
            ip=${ipPrefix}.02
        else
            tmpHostName=k8s-node0$(($x-1))
            ip=${ipPrefix}.$(($x+1))
        fi
        echo "${ip} ${tmpHostName}" >> /etc/hosts;
    done
}

function commonConfigure(){
cat > /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
    "max-size": "100m"
    }
}
EOF

    systemctl daemon-reload
    systemctl restart docker
    systemctl enable docker

    hostnamectl  set-hostname  ${hostName}
    systemctl  stop firewalld  &&  systemctl  disable firewalld
    systemctl  start iptables  &&  systemctl  enable iptables  &&  iptables -F  &&  service iptables save
    swapoff -a && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0 # 禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
vm.overcommit_memory=1 # 不检查物理内存是否够用
vm.panic_on_oom=0 # 开启 OOM
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
    sysctl -p /etc/sysctl.d/kubernetes.conf


    timedatectl set-timezone Asia/Shanghai
    timedatectl set-local-rtc 0
    systemctl restart rsyslog
    systemctl restart crond


    mkdir /var/log/journal /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-prophet.conf <<EOF
[Journal]
# 持久化保存到磁盘
Storage=persistent
# 压缩历史日志
Compress=yes
SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000
# 最大占用空间 10G
SystemMaxUse=10G
 单日志文件最大 200M
SystemMaxFileSize=200M
# 日志保存时间 2 周
MaxRetentionSec=2week
# 不将日志转发到 syslog
ForwardToSyslog=no
EOF

    systemctl restart systemd-journald
}

function installK8sCluster(){
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

    yum -y  install  kubeadm-1.15.1 kubectl-1.15.1 kubelet-1.15.1
    systemctl enable kubelet.service


    cd /usr/local/soft

    if [[ ! -e /usr/local/soft/kubeadm-basic.images ]]
    then
        tar zxvf  /usr/local/soft/kubeadm-basic.images.tar.gz
    fi

    for x in `ls -l /usr/local/soft/kubeadm-basic.images`
    do
        docker load -i /usr/local/soft/kubeadm-basic.images/${x}
    done

#    kubeadm init --config=${baseDir}/scripts/kubeadm/kubeadm-config.yaml --experimental-upload-certs | tee kubeadm-init.log

}

setEnv $*
addHosts
commonConfigure
installK8sCluster
