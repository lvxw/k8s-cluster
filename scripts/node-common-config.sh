#!/bin/bash

function setEnv(){
    cd `cd $(dirname $0) && pwd`
    base_dir=`pwd`
    nodeCount=$1
    ipPrefix=$2
    source /etc/profile
}

function addHosts(){
    for x in `seq 1 ${nodeCount}`
    do
        if [[ ${x} -eq 1 ]]
        then
            hostName=k8s-master01
            ip=${ipPrefix}.02
        else
            hostName=k8s-node0$(($x-1))
            ip=${ipPrefix}.$(($x+1))
        fi
        echo "${ip} ${hostName}" >> /etc/hosts;
    done
}

function commonConfigure(){
    hostnamectl  set-hostname  k8s-master01
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

setEnv $*
addHosts
commonConfigure