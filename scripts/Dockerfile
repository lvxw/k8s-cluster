FROM centos:7

RUN yum clean all
RUN yum install -y epel-release
RUN yum install -y passwd
RUN yum install -y yum-axelget wget; \
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup; \
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo; \
    yum clean all; \
    yum makecache; \
    yum install -y which sshpass net-tools openssh* rsync conntrack ntpdate ntp ipvsadm ipset jq iptables curl sysstat libseccomp  vim  net-tools git firewalld iptables-services grub2 rsyslog yum-utils device-mapper-persistent-data lvm2

RUN yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo; \
    yum update -y; \
    yum install -y docker-ce; \
    mkdir -p /etc/docker /etc/systemd/system/docker.service.d

RUN echo '{' > /etc/docker/daemon.json
    echo '    "exec-opts": ["native.cgroupdriver=systemd"],' >> /etc/docker/daemon.json
    echo '    "log-driver": "json-file",' >> /etc/docker/daemon.json
    echo '    "log-opts": {' >> /etc/docker/daemon.json
    echo '    "max-size": "100m"' >> /etc/docker/daemon.json
    echo '    }' >> /etc/docker/daemon.json
    echo '}' >> /etc/docker/daemon.json

RUN systemctl daemon-reload; \
    systemctl restart docker; \
    systemctl enable docker

RUN rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm; \
    yum --enablerepo=elrepo-kernel install -y kernel-lt; \
    grub2-set-default 'CentOS Linux (4.4.189-1.el7.elrepo.x86_64) 7 (Core)'


RUN echo "k8s-cluster" | passwd --stdin root
COPY node-common-config.sh /usr/local/bin

CMD /bin/bash
