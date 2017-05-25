#!/bin/bash 
source config.ini

cp -f *.jks /home/wso2iot/core/repository/resources/security/
(cd ../deployment; ./wso2iot restart)
