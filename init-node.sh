#!/bin/bash

function setEnv(){
    baseDir=`cd $(dirname $0) && pwd`
    cd ${baseDir}

    source /etc/profile
}


function init(){
    hostnamectl  set-hostname  k8s-master01

    yum install -y wget;
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
    yum clean all && yum makecache &&yum update y
    yum install -y conntrack ntpdate ntp ipvsadm ipset jq iptables curl sysstat libseccomp vim  net-tools git sshpass
    systemctl  stop firewalld  &&  systemctl  disable firewalld
    yum -y install iptables-services  &&  systemctl  start iptables  &&  systemctl  enable iptables &&  iptables -F  &&  service iptables save

    swapoff -a && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

    timedatectl set-timezone Asia/Shanghai
    timedatectl set-local-rtc 0
    systemctl restart rsyslog
    systemctl restart crond

    systemctl stop postfix && systemctl disable postfix
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''

cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.66.10   k8s-master01
192.168.66.20   k8s-node01
192.168.66.21   k8s-node02
EOF
}


function setKernelParams(){
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
}


function setLog(){
    mkdir -p /var/log/journal /etc/systemd/journald.conf.d

cat > /etc/systemd/journald.conf.d/99-prophet.conf <<EOF
[Journal]
Storage=persistent
Compress=yes
SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000
SystemMaxUse=10G
SystemMaxFileSize=200M
MaxRetentionSec=2week
ForwardToSyslog=no
EOF
    systemctl restart systemd-journald
}


function installDocker(){
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum update -y && yum install -y docker-ce
    mkdir -p /etc/docker /etc/systemd/system/docker.service.d

cat > /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    }
}
EOF

    systemctl daemon-reload && systemctl restart docker && systemctl enable docker
}


function installKubeadm(){
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
    yum -y  install  kubeadm-1.15.1 kubectl-1.15.1 kubelet-1.15.1
    systemctl enable kubelet.service

    cd /tmp/k8s-cluster/files/
    tar zxvf kubeadm-basic.images.tar.gz
    for x in `ls -l kubeadm-basic.images`
    do
        docker load -i kubeadm-basic.images/${x}
    done

#    kubeadm init --config=kubeadm-config.yaml --experimental-upload-certs | tee kubeadm-init.log
#    kebuctl create -f kube-flannel.yml
#    sshpass -p k8s-cluster ssh-copy-id -i ~/.ssh/id_rsa.pub root@k8s-master01 -o StrictHostKeyChecking=no
#    sshpass -p k8s-cluster ssh-copy-id -i ~/.ssh/id_rsa.pub root@k8s-node01 -o StrictHostKeyChecking=no
#    sshpass -p k8s-cluster ssh-copy-id -i ~/.ssh/id_rsa.pub root@k8s-node02 -o StrictHostKeyChecking=no

}


function updateKernel(){
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
    yum --enablerepo=elrepo-kernel install -y kernel-lt
    grub2-set-default 'CentOS Linux (4.4.189-1.el7.elrepo.x86_64) 7 (Core)'
    reboot
}


setEnv
init
setKernelParams
setLog
installDocker
installKubeadm
updateKernel
