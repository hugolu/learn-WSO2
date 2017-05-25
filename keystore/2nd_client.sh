#!/bin/bash
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

device=$1
CommonName=${common_name[$1]}
serial=$CommonName
dir=${iot_server_ip}.${device}

###############################################################################
info "Generate the client-side SSL certificate (version 3)"

# generate a RSA private key
openssl genrsa -out client_${device}.key ${numbits}
[ $? == 0 ] || exit $?

# generate a certificate request
openssl req -new \
    -key client_${device}.key \
    -subj /C=${country}/ST=${state}/L=${Loc}/O=${org}/OU=${OrgUnit}/CN=${CommonName} \
    -out client_${device}.csr
[ $? == 0 ] || exit $?

# generate the certificate by siging the CSR with CA private key
openssl x509 -req \
    -days ${days} \
    -CA ca_cert.pem -CAkey ca_private.pem -set_serial ${serial} \
    -in client_${device}.csr \
    -out client_${device}.crt
[ $? == 0 ] || exit $?

# convert the certificate to the .pem format
openssl x509 -in client_${device}.crt -out client_${device}.pem
[ $? == 0 ] || exit $?

###############################################################################
# Generating a BKS File for Android
# https://docs.wso2.com/display/IoTS300/Generating+a+BKS+File+for+Android
###############################################################################
info "Export the SSL, CA, and RA files as PKCS12 files with an alias."

openssl pkcs12 -export -out KEYSTORE_${device}.p12 -inkey ia.key -in ia.crt -CAfile ca_cert.pem -name "wso2carbon" \
    -password pass:"wso2carbon"
[ $? == 0 ] || exit $?

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

keytool -importkeystore -srckeystore KEYSTORE_${device}.p12 -srcstoretype PKCS12 -destkeystore wso2carbon.jks \
    -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

keytool -importkeystore -srckeystore KEYSTORE_${device}.p12 -srcstoretype PKCS12 -destkeystore client-truststore.jks \
    -noprompt -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?


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

keytool -noprompt -import -v -trustcacerts -alias 'openssl x509 -inform PEM -subject_hash -noout -in ca_cert.pem' -file ca_cert.pem -keystore truststore_${device}.bks -storetype BKS -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath bcprov-jdk16-1.46.jar -storepass 'wso2carbon'
[ $? == 0 ] || exit $?

keytool -list -v -keystore "truststore_${device}.bks" -provider org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath "bcprov-jdk16-1.46.jar" -storetype BKS -storepass "wso2carbon"
[ $? == 0 ] || exit $?

################################################################################
info "Generate client.p12 file and import it to BKS file"

openssl pkcs12 -export -out client_${device}.p12 -inkey client_${device}.key -in client_${device}.crt -CAfile ca_cert.pem -name "wso2carbon" -password pass:"wso2carbon"
[ $? == 0 ] || exit $?

keytool -noprompt -importkeystore -v -srckeystore client_${device}.p12 -srcstoretype pkcs12 -alias wso2carbon -keystore keystore_${device}.bks -storetype BKS -providerclass org.bouncycastle.jce.provider.BouncyCastleProvider -providerpath bcprov-jdk16-1.46.jar -srcstorepass "wso2carbon" -deststorepass "wso2carbon"
[ $? == 0 ] || exit $?

################################################################################
info "Pack up client key, crt, and bks into ${dir}.zip"

rm -rf ${dir}
mkdir ${dir}

cp -f client_${device}.key ${dir}/client.key
cp -f client_${device}.crt ${dir}/client.crt
cp -f truststore_${device}.bks ${dir}/truststore.bks
cp -f keystore_${device}.bks ${dir}/keystore.bks

rm -f ${dir}.zip
zip -r ${dir}.zip ${dir}
