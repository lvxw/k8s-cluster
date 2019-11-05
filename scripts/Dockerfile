FROM centos:7

RUN yum clean all
RUN yum install -y epel-release
RUN yum install -y passwd
RUN yum install -y yum-axelget wget; \
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup; \
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo; \
    yum clean all; \
    yum makecache; \
    yum update -y; \
    yum install -y which sshpass net-tools openssh* rsync conntrack ntpdate ntp ipvsadm ipset jq iptables curl sysstat libseccomp  vim  net-tools git firewalld iptables-services grub2 rsyslog yum-utils device-mapper-persistent-data lvm2 docker-ce; \
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm; \
    yum --enablerepo=elrepo-kernel install -y kernel-lt; \
    grub2-set-default 'CentOS Linux (4.4.189-1.el7.elrepo.x86_64) 7 (Core)'

CMD /bin/bash
