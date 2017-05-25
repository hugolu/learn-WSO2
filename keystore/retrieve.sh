#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

rm -f *.key *.csr *.crt *.pem *.p12 *.jks *.bks *.log

###############################################################################
info "Generate a self-signed Certificate Authority (CA) certificate (version 3)"

openssl genrsa -out ca_private.key 4096

openssl req -new -key ca_private.key -out ca.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName}

openssl x509 -req -days 365 -in ca.csr -signkey ca_private.key -out ca.crt -extensions v3_ca -extfile ./openssl.cnf

openssl rsa -in ca_private.key -text > ca_private.pem

openssl x509 -in ca.crt -out ca_cert.pem

###############################################################################
info "Copy the CA certificate details to JKS"

openssl pkcs12 -export -out ca.p12 -inkey ca_private.pem -in ca_cert.pem -name "cacert" \
    -password pass:"wso2carbon"

keytool -importkeystore -srckeystore ca.p12 -srcstoretype PKCS12 -destkeystore client-truststore.jks \
    -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"

###############################################################################
info "Convert alias in JKS into PKCS12"

keytool -importkeystore -noprompt \
    -srckeystore client-truststore.jks -srcstoretype JKS -srcstorepass wso2carbon \
    -destkeystore keystore.p12 -deststoretype PKCS12 -deststorepass wso2carbon \
    -srcalias cacert -destalias cacert \
    -srckeypass wso2carbon -destkeypass wso2carbon

###############################################################################
info "Extract the private key from PKCS12"

openssl pkcs12 -nocerts \
    -in keystore.p12 -passin pass:wso2carbon \
    -out encrypedkey.pem -passout pass:wso2carbon  

openssl rsa -in encrypedkey.pem -out retrieved.key -passin pass:wso2carbon

diff ca_private.key retrieved.key
if [ $? == 0 ]; then
    echo "retrieve the private key successfully"
else
    echo "failed to retrieve the private key"
fi
