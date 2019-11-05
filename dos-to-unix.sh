#!/bin/bash
baseDir=`cd $(dirname $0) && pwd`

dos2unix ${baseDir}/*
dos2unix ${baseDir}/hadoop/*
dos2unix ${baseDir}/scripts/*
dos2unix ${baseDir}/scripts/utils/*

chmod 755 ${baseDir}/*.sh
chmod 755 ${baseDir}/scripts/*.sh
chmod 755 ${baseDir}/scripts/utils/*.sh
