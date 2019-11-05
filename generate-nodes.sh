#!/bin/bash

function setEnv(){
    baseDir=`cd $(dirname $0) && pwd`
    cd ${baseDir}

    cp scripts/xcall.sh scripts/xsync.sh /usr/local/bin
    source /etc/profile
    source scripts/utils/echo-utils.sh
}

function init(){
    nodesExist='true'
    nodeCount=3
    ipPrefix=172.23.16

    if [[ $# -eq 0 ]]
    then
       echoWarn "You can enter the number of nodes, but you don't, so we'll use the default value of 3."
    else
       if [[ $1 -lt 3 ]]
       then
            echoWarn 'The number of nodes you enter is less than 3, so we will use the minimum value of 3.'
       else
            nodeCount=$1
       fi
    fi
}

function check(){
    if [[ ! -e /root/.configured-vm ]]
    then
        echoWarn "The docker container host is not configured. We will configure the host first"
        ./configure-vm.sh
    fi

    if [[ `docker ps -a | grep k8s-master01 | grep k8s-base:v1 | wc -l` -le 3 ]]
    then
        nodesExist='false'
    else
        echoInfo "The cluster exists. The current number of cluster nodes is `docker ps -a | grep k8s-master01 | grep k8s-base:v1 | wc -l`."
    fi
}

function createNodes(){
    if [[ ${nodesExist} == 'false' ]]
    then
        docker build -t k8s-base:v1 scripts
        docker network create -d bridge --subnet ${ipPrefix}.0/24 --gateway ${ipPrefix}.1 k8s-cluster

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
            docker create --privileged --network=k8s-cluster --ip=${ip} --name ${hostName} -it  k8s-base:v1 /usr/sbin/init
            echo "${ip}    ${hostName}" >> /etc/hosts
        done
    fi
}

function configNodes(){
    if [[ ${nodesExist} == 'false' ]]
    then
        rm -rf /root/.ssh/known_hosts
        for x in `seq 1 ${nodeCount}`
        do
            if [[ ${x} -eq 1 ]]
            then
                hostName=k8s-master01
            else
                hostName=k8s-node0$(($x-1))
            fi
            docker start ${hostName}
            docker exec -it ${hostName} systemctl start sshd
            sleep 10s
            sshpass -p cluster ssh-copy-id -i ~/.ssh/id_rsa.pub root@${hostName} -o StrictHostKeyChecking=no
        done

        for x in `seq 1 ${nodeCount}`
        do
            if [[ ${x} -eq 1 ]]
            then
                hostName=k8s-master01
            else
                hostName=k8s-node0$(($x-1))
            fi
            sleep 10s
            docker exec -it ${hostName} scripts/node-common-config.sh ${nodeCount}
        done

        for x in `seq 1 ${nodeCount}`
        do
            if [[ ${x} -eq 1 ]]
            then
                hostName=k8s-master01
            else
                hostName=k8s-node0$(($x-1))
            fi
            docker stop ${hostName}
        done
    fi
}

setEnv
init $*
check
createNodes
configNodes

