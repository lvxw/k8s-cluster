#!/bin/bash

hostCount=3

for x in `seq 1 ${hostCount}`
do
    if [[ ${x} -eq 1 ]]
    then
        hostName=k8s-master01
    else
        hostName=k8s-node0$(($x-1))
    fi
    echo "----------------------------${hostName}------------------------------------"
    ssh -o StrictHostKeyChecking=no ${hostName} "source /etc/profile;$*"
    echo ""
done
