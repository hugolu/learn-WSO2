#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

###############################################################################
# Generating a BKS File for Android
# https://docs.wso2.com/display/IoTS300/Generating+a+BKS+File+for+Android

rm -f *.key *.csr *.crt *.pem *.p12 *.jks *.bks *.log

###############################################################################
info "In the location where you modified and saved the openssl.cnf file, run the following commands to generate a self-signed Certificate Authority (CA) certificate (version 3) and convert the certificate to the .pem format"

openssl genrsa -out ca_private.key ${numbits}
[ $? == 0 ] || exit $?

openssl req -new -key ca_private.key -out ca.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName}
[ $? == 0 ] || exit $?

openssl x509 -req -days 365 -in ca.csr -signkey ca_private.key -out ca.crt -extensions v3_ca -extfile ./openssl.cnf
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

openssl x509 -req -days 365 -in ra.csr -CA ca.crt -CAkey ca_private.key -set_serial 02 -out ra.crt -extensions v3_req -extfile ./openssl.cnf
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

openssl x509 -req -days 730 -in ia.csr -CA ca_cert.pem -CAkey ca_private.pem -set_serial 044324343 -out ia.crt
[ $? == 0 ] || exit $?

###############################################################################
#info "Generate the SSL certificate (version 3) based on localhost"

#openssl genrsa -out ia_localhost.key ${numbits}
#[ $? == 0 ] || exit $?

#openssl req -new -key ia_localhost.key -out ia_localhost.csr \
#    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN="localhost"
#[ $? == 0 ] || exit $?

#openssl x509 -req -days 730 -in ia_localhost.csr -CA ca_cert.pem -CAkey ca_private.pem -set_serial 044324343 -out ia_localhost.crt
#[ $? == 0 ] || exit $?
###############################################################################
info "Generate the client-side SSL certificate (version 3)"

# Generate a private key
openssl genrsa -out client.key ${numbits}

# Generate a certificate signing request (CSR)
openssl req -new -key client.key -out client.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=100011000110001

# Sign the CSR file with the CA private key to generate the client certificate
openssl x509 -req -days ${days} -in client.csr -CA ca_cert.pem -CAkey ca_private.pem -set_serial 100011000110001 -out client.crt

# Convert the client certificate to the .pem format for future use
openssl x509 -in client.crt -out client.pem
###############################################################################
info "Export the SSL, CA, and RA files as PKCS12 files with an alias."

openssl pkcs12 -export -out KEYSTORE.p12 -inkey ia.key -in ia.crt -CAfile ca_cert.pem -name "wso2carbon" \
    -password pass:"wso2carbon"
[ $? == 0 ] || exit $?

#openssl pkcs12 -export -out KEYSTORE_localhost.p12 -inkey ia_localhost.key -in ia_localhost.crt -CAfile ca_cert.pem -name "wso2carbon" \
#    -password pass:"wso2carbon"
#[ $? == 0 ] || exit $?

openssl pkcs12 -export -out ca.p12 -inkey ca_private.pem -in ca_cert.pem -name "cacert" \
    -password pass:"cacert"
[ $? == 0 ] || exit $?

openssl pkcs12 -export -out ra.p12 -inkey ra_private.pem -in ra_cert.pem -chain -CAfile ca_cert.pem -name "racert" \
    -password pass:"racert"
[ $? == 0 ] || exit $?

###############################################################################
info "Copy the three P12 files to the <IoT_HOME>/core/repository/resources/security directory."

# 来自李仕的经验：
#   在你自己的目录下import，会生成一个新的jks，然后拷贝到security目录
#   wso2carbon.jks和wso2certs.jks都是这样处理
#   client-truststore.jks是把p12文件拷贝到security目录再import
cp -f default/client-truststore.jks .

###############################################################################
info "Import the generated P12 files as follows:"

keytool -importkeystore -srckeystore KEYSTORE.p12 -srcstoretype PKCS12 -destkeystore wso2carbon.jks \
    -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

keytool -importkeystore -srckeystore KEYSTORE.p12 -srcstoretype PKCS12 -destkeystore client-truststore.jks \
    -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

#keytool -importkeystore -srckeystore KEYSTORE_localhost.p12 -srcstoretype PKCS12 -destkeystore wso2carbon.jks \
#    -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
#[ $? == 0 ] || exit $?

#keytool -importkeystore -srckeystore KEYSTORE_localhost.p12 -srcstoretype PKCS12 -destkeystore client-truststore.jks \
#    -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
#[ $? == 0 ] || exit $?

keytool -importkeystore -srckeystore ca.p12 -srcstoretype PKCS12 -destkeystore wso2certs.jks \
    -noprompt -srcstorepass "cacert" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

keytool -importkeystore -srckeystore ra.p12 -srcstoretype PKCS12 -destkeystore wso2certs.jks \
    -noprompt -srcstorepass "racert" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

keytool -importkeystore -srckeystore ca.p12 -srcstoretype PKCS12 -destkeystore client-truststore.jks \
    -noprompt -srcstorepass "cacert" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

keytool -importkeystore -srckeystore ra.p12 -srcstoretype PKCS12 -destkeystore client-truststore.jks \
    -noprompt -srcstorepass "racert" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

###############################################################################
info "Generate the BKS file:"

keytool -noprompt -import -v -trustcacerts -alias 'openssl x509 -inform PEM -subject_hash -noout -in ca_cert.pem' -file ca_cert.pem -keystore truststore.bks -storetype BKS -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath bcprov-jdk16-1.46.jar -storepass 'wso2carbon'
[ $? == 0 ] || exit $?

keytool -list -v -keystore "truststore.bks" -provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath "bcprov-jdk16-1.46.jar" -storetype BKS -storepass "wso2carbon"
[ $? == 0 ] || exit $?
