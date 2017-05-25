#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

###############################################################################
info "Generate the client-side SSL certificate (version 3)"

# generate a RSA private key
openssl genrsa -out client.key ${numbits}
[ $? == 0 ] || exit $?

# generate a certificate request
openssl req -new \
    -key client.key \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName} \
    -out client.csr
[ $? == 0 ] || exit $?

# generate the certificate by siging the CSR with CA private key
openssl x509 -req \
    -days ${days} \
    -CA ca_cert.pem -CAkey ca.pem -set_serial ${client_serial} \
    -in client.csr \
    -out client.crt
[ $? == 0 ] || exit $?

# convert the certificate to the .pem format
openssl x509 -in client.crt -out client.pem
[ $? == 0 ] || exit $?

###############################################################################
info "Export the SSL, CA, and RA files as PKCS12 files with an alias"

# export CRT & KEY of client as PKCS#12
openssl pkcs12 -export \
    -inkey client.key -in client.crt -CAfile ca_cert.pem \
    -name ${client_alias} -password pass:${password} \
    -out client.p12
[ $? == 0 ] || exit $?

###############################################################################
info "Update the BKS file"

# deletes from the keystore the entry identified by alias
keytool -delete \
    -alias ${ca_alias} \
    -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider \
    -providerpath bcprov-jdk16-1.46.jar \
    -keystore truststore.bks -storetype BKS -storepass ${password} > /dev/null 2>&1

# reads the certificate and stores it in the keystore entry identified by alias
keytool -importcert -v \
    -noprompt -trustcacerts \
    -alias ${ca_alias} \
    -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider \
    -providerpath bcprov-jdk16-1.46.jar \
    -file ca_cert.pem \
    -keystore truststore.bks -storetype BKS -storepass ${password}
[ $? == 0 ] || exit $?

# deletes from the keystore the entry identified by alias
keytool -delete \
    -alias ${client_alias} \
    -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider \
    -providerpath bcprov-jdk16-1.46.jar \
    -keystore keystore.bks -storetype BKS -storepass ${password} > /dev/null 2>&1

# reads the certificate and stores it in the keystore entry identified by alias
keytool -importkeystore -v \
    -noprompt \
    -alias ${client_alias} \
    -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider \
    -providerpath bcprov-jdk16-1.46.jar \
    -srckeystore client.p12 -srcstoretype pkcs12 -srcstorepass ${password} \
    -keystore keystore.bks -storetype BKS -storepass ${password}
[ $? == 0 ] || exit $?

###############################################################################
info "Optionally, view the list of certificates in the BKS form using the following command"

keytool -list -v \
    -alias ${ca_alias} \
    -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider \
    -providerpath bcprov-jdk16-1.46.jar \
    -keystore truststore.bks -storetype BKS -storepass ${password}

keytool -list -v \
    -alias ${client_alias} \
    -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider \
    -providerpath bcprov-jdk16-1.46.jar \
    -keystore keystore.bks -storetype BKS -storepass ${password}
