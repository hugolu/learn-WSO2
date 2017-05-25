#!/bin/bash

source config.ini

ROOT="/usr/local"

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }
function error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

function install_jdk(){
    info "Install JDK"

    rm -rf ${ROOT}/jdk ${ROOT}/${JDK_DIR}

    tar -C ${ROOT} -zxf ${JDK_TGZ}
    [ $? == 0 ] || error "failed to install JDK"
    ln -s ${ROOT}/${JDK_DIR} ${ROOT}/jdk

    echo 'export JAVA_HOME=/usr/local/jdk' >> ~/.bashrc
    echo 'export PATH=${JAVA_HOME}/bin:${PATH}' >> ~/.bashrc

    source ~/.bashrc
    java -version
}

function install_maven(){
    info "Install Maven"

    rm -rf ${ROOT}/maven ${ROOT}/${MAVEN_DIR}

    tar -C ${ROOT} -zxf ${MAVEN_TGZ}
    [ $? == 0 ] || error "failed to install MAVEN"
    ln -s ${ROOT}/${MAVEN_DIR} ${ROOT}/maven

    echo 'export MAVEN_HOME=/usr/local/maven' >> ~/.bashrc
    echo 'export PATH=${MAVEN_HOME}/bin:${PATH}' >> ~/.bashrc

    source ~/.bashrc
    mvn -version
}

function install_ant(){
    info "Install Ant"

    rm -rf ${ROOT}/ant ${ROOT}/${ANT_TGZ}

    tar -C ${ROOT} -zxf ${ANT_TGZ}
    [ $? == 0 ] || error "failed to install ANT"
    ln -s ${ROOT}/${ANT_DIR} ${ROOT}/ant

    echo 'export ANT_HOME=/usr/local/ant' >> ~/.bashrc
    echo 'export PATH=${ANT_HOME}/bin:${PATH}' >> ~/.bashrc

    source ~/.bashrc
    ant -version
}

function setup(){
    case $1 in
        jdk)
            install_jdk
            ;;
        maven)
            install_maven
            ;;
        ant)
            install_ant
            ;;
        all)
            install_jdk
            install_maven
            install_ant
            ;;
        *)
            echo "Usage $0 jdk|maven|ant|all"
            exit 1
    esac
}

if [ $# == 0 ]; then setup help; fi
for opt in $*; do setup $opt; done

echo "end"
