#!/bin/bash

function echoError(){
    echo -e "\e[31m\e[1mError: ${*}\e[0m"
}
function echoWarn(){
    echo -e "\e[33m\e[1mWarning: ${*}\e[0m"
}
function echoInfo(){
    echo -e "\e[32m\e[1mInfo: ${*}\e[0m"
}
function echoDebug(){
    echo -e "\e[34m\e[1mDebug${*}\e[0m"
}
