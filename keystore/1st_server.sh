#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

###############################################################################
# Generating a BKS File for Android
# https://docs.wso2.com/display/IoTS300/Generating+a+BKS+File+for+Android

###############################################################################
info "In the location where you modified and saved the openssl.cnf file, run the following commands to generate a self-signed Certificate Authority (CA) certificate (version 3) and convert the certificate to the .pem format"

openssl genrsa -out ca_private.key ${numbits}
[ $? == 0 ] || exit $?

openssl req -new -key ca_private.key -out ca.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName}
[ $? == 0 ] || exit $?

openssl x509 -req -days ${days} -in ca.csr -signkey ca_private.key -out ca.crt -extensions v3_ca -extfile ./openssl.cnf
[ $? == 0 ] || exit $?

openssl rsa -in ca_private.key -text > ca_private.pem
[ $? == 0 ] || exit $?

openssl x509 -in ca.crt -out ca_cert.pem
[ $? == 0 ] || exit $?

###############################################################################
info "In the same location, run the following commands to generate a Registration Authority (RA) certificate (version 3), sign it with the CA, and convert the certificate to the .pem format."

openssl genrsa -out ra_private.key ${numbits}
[ $? == 0 ] || exit $?

openssl req -new -key ra_private.key -out ra.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName}
[ $? == 0 ] || exit $?

openssl x509 -req -days ${days} -in ra.csr -CA ca.crt -CAkey ca_private.key -set_serial 00001 -out ra.crt -extensions v3_req -extfile ./openssl.cnf
[ $? == 0 ] || exit $?

openssl rsa -in ra_private.key -text > ra_private.pem
[ $? == 0 ] || exit $?

openssl x509 -in ra.crt -out ra_cert.pem
[ $? == 0 ] || exit $?

###############################################################################
info "Generate the SSL certificate (version 3) based on your domain/IP address"

openssl genrsa -out ia.key ${numbits}
[ $? == 0 ] || exit $?

openssl req -new -key ia.key -out ia.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName}
[ $? == 0 ] || exit $?

openssl x509 -req -days ${days} -in ia.csr -CA ca_cert.pem -CAkey ca_private.pem -set_serial 00001 -out ia.crt
[ $? == 0 ] || exit $?

