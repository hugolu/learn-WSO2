# WSO2 IoT Server

## Download scripts
```
# git clone http://gitlab.hollywant.com:8181/devops/wso2.git
# cd wso2/
# git checkout iot-das
```

## Setup environment (if necessary)
Prerequisites:
- jdk-8u112-linux-x64.tar.gz
- apache-maven-3.3.9-bin.tar.gz
- apache-ant-1.10.1-bin.tar.gz

Copy the above tarballs into env/, and then
```
# (cd env; ./setup.sh all)
# source ~/.bashrc
```

## Steps of Installation
Prerequisites:
- wso2iot-3.0.0.zip
- wso2das-3.1.0.zip

Copy the above zip files into iot-3.0.0/ and das-3.1.0/, and then
```
# ./setup.sh all
```

## Start/Stop servers
```
# ./wso2carbon start   # start servers
# ./wso2carbon stop    # stop servers
# ./wso2carbon restart # restart servers
```
