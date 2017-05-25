#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

###############################################################################
info "Generate the server-site SSL certificate (version 3)"

# generate a RSA private key
openssl genrsa -out server.key ${numbits}
[ $? == 0 ] || exit $?

# generate a certificate request
openssl req -new \
    -key server.key \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName} \
    -out server.csr
[ $? == 0 ] || exit $?

# generate the certificate by siging the CSR with CA private key
openssl x509 -req \
    -days ${days} \
    -CA ca_cert.pem -CAkey ca.pem -set_serial ${server_serial} \
    -in server.csr \
    -out server.crt
[ $? == 0 ] || exit $?

###############################################################################
info "Export the SSL, CA, and RA files as PKCS12 files with an alias"

# export CRT & KEY as PKCS#12
openssl pkcs12 -export \
    -inkey server.key -in server.crt -CAfile ca_cert.pem \
    -name ${server_alias} -password pass:${password} \
    -out server.p12
[ $? == 0 ] || exit $?

###############################################################################
info "Update the JKS files for java server"

cp -f default/wso2carbon.jks .

keytool -importkeystore \
    -noprompt \
    -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass ${password} \
    -destkeystore wso2carbon.jks -deststorepass ${password}
[ $? == 0 ] || exit $?

###############################################################################
info "Optionally, view the list of certificates in the BKS form using the following command"

# prints to stdout the contents of the keystore entry
keytool -list -v \
    -alias ${server_alias} \
    -keystore wso2carbon.jks -storetype JKS -storepass ${password}
