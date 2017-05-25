#!/bin/bash 

function error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

function setup_keystore(){
    (cd keystore; ./setup.sh all)
    [ $? == 0 ] || (error "failed to setup keystore"; exit 1)
}

function setup_iot(){
    (cd iot-3.0.0; ./setup.sh all)
    [ $? == 0 ] || (error "failed to setup WSO2 IoT"; exit 1)
}

function setup_das(){
    (cd das-3.1.0; ./setup.sh all)
    [ $? == 0 ] || (error "failed to setup WSO2 DAS"; exit 1)
}

function setup(){
    case "$1" in
        keystore)
            setup_keystore
            ;;
        iot)
            setup_iot
            ;;
        das)
            setup_das
            ;;
        all)
            setup_keystore
            setup_iot
            setup_das
            ;;
        *)
            echo "Usage $0 keystore|iot|das|all"
            exit 1
    esac
}

if [ $# == 0 ]; then setup help; fi
for opt in $*; do setup $opt; done
