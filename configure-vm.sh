#!/bin/bash

function setEnv(){
    baseDir=`cd $(dirname $0) && pwd`
    cd ${baseDir}

    source /etc/profile
    source scripts/utils/echo-utils.sh
}

function init(){
    if [[ ! -e /root/.configured-vm ]]
    then
        yum install -y wget
        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.bak
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
        yum clean all && yum makecache && yum update -y

        hostnamectl set-hostname vm01
        systemctl stop firewalld && systemctl disable firewalld
        sed  -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config && setenforce 0

        if [[ ! -f /root/.ssh/id_rsa/id_rsa ]]
        then
            ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''
        fi

        touch /root/.configured-vm
    fi
}

function installBasicSoftware(){
    yum install -y net-tools ntpdate vim gcc gcc-c++ nc unzip zip lzop zlib* dos2unix sshpass rsync
    ntpdate pool.ntp.org && hwclock --systohc
}

function installDocker(){
    source /etc/profile
    if [[ `which docker` != '/usr/bin/docker'  ]]
    then
        yum install -y docker
        mkdir -p /data/docker/lib /etc/docker
        sed -i 's/ExecStart=\/usr\/bin\/dockerd-current/ExecStart=\/usr\/bin\/dockerd-current --graph=\/data\/docker\/lib/' /lib/systemd/system/docker.service
        tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://ltaa1zpv.mirror.aliyuncs.com"]
}
EOF
        systemctl daemon-reload && systemctl restart docker && systemctl enable docker
    fi
}

function installMysql(){
    if [[ `which mysql` != '/usr/bin/mysql' ]]
    then
        wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
        rpm -ivh mysql-community-release-el7-5.noarch.rpm && yum -y install mysql-server
        rm -rf mysql-community-release-el7-5.noarch.rpm

        systemctl stop mysqld
        chown -R root:root /var/lib/mysql
        systemctl start mysqld
        mysql -u root -e " use mysql; update user set password=password('base') where user='root';"
        mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'service' WITH GRANT OPTION;"
        systemctl restart mysqld
    fi
}

function installRedis(){
    if [[ `which redis-server` != '/usr/bin/redis-server' ]]
    then
        yum install -y  epel-release
        yum install -y redis redis
        systemctl start redis && systemctl enable redis
        sed -i 's/bind 127.0.0.1/\#bind 127.0.0.1/' /etc/redis.conf
        sed -i 's/protected-mode yes/protected-mode no/' /etc/redis.conf
        sed -i 's/daemonize no/daemonize yes/' /etc/redis.conf
        systemctl restart redis
    fi
}

setEnv
init
installBasicSoftware
installDocker
#installMysql
installRedis
