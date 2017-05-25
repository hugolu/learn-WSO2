#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

###############################################################################
# Auto Enrolling an Android Device
# https://docs.wso2.com/display/IoTS300/Auto+Enrolling+an+Android+Device

rm -f *.key *.csr *.crt *.pem *.p12 *.jks *.bks *.log

###############################################################################
info "Generate a self-signed Certificate Authority (CA) certificate (version 3)"

# Generate the private key
openssl genrsa -out ca_private.key 4096

# Generate a certificate signing request (CSR)
openssl req -new -key ca_private.key -out ca.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName}

# Self-sign the CSR by signing it with the private key
openssl x509 -req -days 365 -in ca.csr -signkey ca_private.key -out ca.crt -extensions v3_ca -extfile ./openssl.cnf

# Convert the private key to the .pem format
openssl rsa -in ca_private.key -text > ca_private.pem

# Convert the CA certificate to the .pem format
openssl x509 -in ca.crt -out ca_cert.pem

###############################################################################
info "Generate the SSL certificate (version 3) based on your domain/IP address"

# Generate a private key
openssl genrsa -out ia.key 4096

# Generate a certificate signing request (CSR)
openssl req -new -key ia.key -out ia.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${commonName}

# Sign the CSR with the CA private key to generate the SSL certificate
openssl x509 -req -days 730 -in ia.csr -CA ca_cert.pem -CAkey ca_private.pem -set_serial 044324343 -out ia.crt

###############################################################################
info "Generate the client-side SSL certificate (version 3)"

# Generate a private key
openssl genrsa -out client.key 4096

# Generate a certificate signing request (CSR)
openssl req -new -key client.key -out client.csr \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=12438035315552875930

# Sign the CSR file with the CA private key to generate the client certificate
openssl x509 -req -days 730 -in client.csr -CA ca_cert.pem -CAkey ca_private.pem -set_serial 12438035315552875930 -out client.crt

# Convert the client certificate to the .pem format for future use
openssl x509 -in client.crt -out client.pem

###############################################################################
info "Copy server side SSL certificate to the wso2carbon.jks file"

cp -f default/wso2carbon.jks .

openssl pkcs12 -export -out KEYSTORE.p12 -inkey ia.key -in ia.crt -CAfile ca_cert.pem -name "wso2carbon" \
    -password pass:"wso2carbon"
[ $? == 0 ] || exit $?

keytool -importkeystore -srckeystore KEYSTORE.p12 -srcstoretype PKCS12 -destkeystore wso2carbon.jks \
     -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

###############################################################################
info "Copy the CA certificate details to the client-truststore.jks"

cp -f default/client-truststore.jks .

openssl pkcs12 -export -out ca.p12 -inkey ca_private.pem -in ca_cert.pem -name "cacert" \
    -password pass:"wso2carbon"
[ $? == 0 ] || exit $?

keytool -importkeystore -srckeystore ca.p12 -srcstoretype PKCS12 -destkeystore client-truststore.jks \
    -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

###############################################################################
info "Create a new BKS file having the name truststore and add the CA certificate"

keytool -noprompt -import -v -trustcacerts -alias `openssl x509 -inform PEM -subject_hash -noout -in ca_cert.pem` -file ca_cert.pem -keystore truststore.bks -storetype BKS -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath bcprov-jdk16-1.46.jar -storepass 'wso2carbon'

###############################################################################
info "Create a new BKS file with the name keystore and add the client certificate generated bellow"

openssl pkcs12 -export -out client.p12 -inkey client.key -in client.crt -CAfile ca_cert.pem -name "wso2carbon" \
    -password pass:"wso2carbon"
[ $? == 0 ] || exit $?

info "End of generation"
