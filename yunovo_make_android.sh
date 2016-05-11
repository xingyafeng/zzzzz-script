#!/bin/bash

#set java env
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$CLASSPATH:$JAVA_HOME/lib:$JRE_HOME/lib
export PATH=${JAVA_HOME}/bin:$JRE_HOME/bin:$PATH

function make_android()
{
	source  build//envsetup.sh
	lunch full_magc6580_we_l-user
	make -j24 2>&1 | tee build.log
}

make_android
