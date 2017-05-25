#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }
function error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

info "Generate keystores"

function setup_clean(){
    info "clean keystores"

    rm -f *.key *.csr *.crt *.pem *.p12 *.jks *.bks *.log
    [ $? == 0 ] || (error "failed to clean"; exit 1)
}

function setup_server(){
    info "setup keystore servers"

    ./1st_server.sh
    [ $? == 0 ] || (error "failed to generate server's ca and ia"; exit 1)
}

function setup_client(){
    info "setup keystore clients"

    for dev in ${devices}; do
        ./2nd_client.sh ${dev}
        [ $? == 0 ] || (error "failed to generate ${device} client certificate"; exit 1)
    done
}

function setup(){
    case "$1" in
        clean)
            setup_clean
            ;;
        server)
            setup_server
            ;;
        client)
            setup_client
            ;;
        all)
            setup_clean
            setup_server
            setup_client
            ;;
        *)
            echo "Usage $0 clean|server|client|all"
            exit
    esac
}

if [ $# == 0 ]; then setup help; fi
for opt in $*; do setup $opt; done
