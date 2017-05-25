#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

###############################################################################
info "Generate a self-signed Certificate Authority (CA) certificate"

# generate a RSA private key
openssl genrsa -out ca.key ${numbits}
[ $? == 0 ] || exit $?

# generate a certificate request
openssl req -new \
    -key ca.key \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName} \
    -out ca.csr
[ $? == 0 ] || exit $?

# generate the certificate by siging the CSR with CA private key (self-signed)
openssl x509 -req \
    -days ${days} \
    -in ca.csr -signkey ca.key \
    -out ca.crt -extensions v3_ca -extfile openssl.cnf
[ $? == 0 ] || exit $?

# convert the RSA private key to the .pem format
openssl rsa -in ca.key -text > ca.pem
[ $? == 0 ] || exit $?

# convert the certificate to the .pem format
openssl x509 -in ca.crt -out ca_cert.pem
[ $? == 0 ] || exit $?

###############################################################################
info "Export the SSL, CA, and RA files as PKCS12 files with an alias"

openssl pkcs12 -export \
    -inkey ca.pem -in ca_cert.pem \
    -name ${ca_alias} -password pass:${password} \
    -out ca.p12
[ $? == 0 ] || exit $?

###############################################################################
info "Update the JKS files for java server"

cp -f default/wso2certs.jks .
cp -f default/client-truststore.jks .

keytool -importkeystore \
    -noprompt \
    -srckeystore ca.p12 -srcstoretype PKCS12 -srcstorepass ${password} \
    -destkeystore wso2certs.jks -deststorepass ${password}
[ $? == 0 ] || exit $?

keytool -importkeystore \
    -noprompt \
    -srckeystore ca.p12 -srcstoretype PKCS12 -srcstorepass ${password} \
    -destkeystore client-truststore.jks -deststorepass ${password}
[ $? == 0 ] || exit $?

###############################################################################
info "Optionally, view the list of certificates in the BKS form using the following command"

# prints to stdout the contents of the keystore entry
keytool -list -v \
    -alias ${ca_alias} \
    -keystore wso2certs.jks -storetype JKS -storepass ${password}

keytool -list -v \
    -alias ${ca_alias} \
    -keystore client-truststore.jks -storetype JKS -storepass ${password}
