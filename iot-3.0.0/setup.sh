#!/bin/bash 
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

wso2home=${root_dir}/wso2iot

function install(){

    info "Install the product"

    unziped_dir=${root_dir}/`basename ${zip_file} .zip`

    rm -rf ${wso2home} ${unziped_dir} > /dev/null 2>&1
    unzip ${zip_file} -d ${root_dir}
    ln -s ${unziped_dir} ${wso2home}
}

function config_ip(){

    info "Configuring WSO2 IoT Server with the IP"

    files="
    core/repository/conf/carbon.xml
    core/repository/conf/identity/sso-idp-config.xml
    core/repository/deployment/server/jaggeryapps/devicemgt/app/conf/app-conf.json
    core/repository/deployment/server/jaggeryapps/api-store/site/conf/site.json
    core/repository/conf/app-manager.xml
    "
    for file in ${files}; do
        echo "modify $file"
        sed "s/IOT_SERVER_IP/${iot_server_ip}/g" < template/${file} > ${wso2home}/${file}
        [ $? == 0 ] || exit $?
    done
}

function config_samlsso(){

    info "Modify the files about samlsso"

    files="
    core/repository/deployment/server/jaggeryapps/portal/configs/designer.json
    core/repository/deployment/server/jaggeryapps/social/configs/social.json
    core/repository/deployment/server/jaggeryapps/android-web-agent/app/conf/app-conf.json
    core/repository/deployment/server/jaggeryapps/publisher/config/publisher.json
    core/repository/deployment/server/jaggeryapps/store/config/publisher.json
    core/repository/deployment/server/jaggeryapps/store/config/store.json
    core/repository/deployment/server/jaggeryapps/devicemgt/app/conf/config.json
    "

    for file in ${files}; do
        echo "modify $file"
        sed "s/IOT_SERVER_IP/${iot_server_ip}/g" < template/${file} > ${wso2home}/${file}
        [ $? == 0 ] || exit $?
    done
}

function config_ssl_authentication(){

    info "Configure WSO2 IoT Server for mutual SSL authentication"

    unzip "${wso2home}/core/repository/deployment/server/webapps/api#device-mgt#android#v1.0.war" \
        -d "${wso2home}/core/repository/deployment/server/webapps/api#device-mgt#android#v1.0"

    files="
    core/repository/conf/tomcat/catalina-server.xml
    core/repository/deployment/server/webapps/api#device-mgt#android#v1.0/WEB-INF/web.xml
    "

    for file in ${files}; do
        cp -f template/${file} ${wso2home}/${file}
    done
}

function config_security(){

    info "Install WSO2 API Manager Features in WSO2 G-Reg"

    files="
    core/repository/conf/axis2/axis2.xml
    "

    for file in ${files}; do
        cp -f template/${file} ${wso2home}/${file}
    done
}

function config_keystore(){

    info "Copy jks to wso2iot"

    product_jks_pair="
    core:wso2certs.jks,client-truststore.jks,wso2carbon.jks
    broker:client-truststore.jks,wso2carbon.jks
    analytics:client-truststore.jks,wso2carbon.jks
    "
    for product_jks in ${product_jks_pair}; do
        product=$(echo ${product_jks} | cut -d : -f 1)
        jks=$(echo $(echo ${product_jks} | cut -d : -f 2) | sed "s/,/ /g")
        (cd ../keystore; cp ${jks} ${wso2home}/${product}/repository/resources/security)
        [ $? == 0 ] || exit $?
    done

}

function config_analytics(){

    info "Configure device analytics"

    files="
    core/repository/conf/data-bridge/data-agent-config.xml
    core/repository/conf/etc/device-analytics-config.xml
    "

    for file in ${files}; do
        echo "modify $file"
        sed "s/DAS_SERVER_IP/${das_server_ip}/g" < template/${file} > ${wso2home}/${file}
        [ $? == 0 ] || exit $?
    done
}

function config_postgresql(){

    info "Setup Postgresql datasource configuration files"

    files="
    core/repository/conf/datasources/android-datasources.xml
    core/repository/conf/datasources/cdm-datasources.xml
    core/repository/conf/datasources/master-datasources.xml
    core/repository/conf/datasources/metrics-datasources.xml
    core/repository/conf/datasources/windows-datasources.xml
    "

    for file in ${files}; do
        echo "modify $file"
        sed "s/DB_SERVER_IP/${db_server_ip}/g; s/DB_PREFIX/${db_prefix}/g; s/DB_USERNAME/${db_username}/g; s/DB_PASSWORD/${db_password}/g" < template/${file} > ${wso2home}/${file}
        [ $? == 0 ] || exit $?
    done

    info "Copy Postgresql driver"
    cp -f lib/postgresql-42.0.0.jar ${wso2home}/core/repository/components/lib

    info "Reset Postgresql database"

    databases="wso2carbon_db wso2appm_db wso2am_db wso2mb_db es_storage wso2_social_db wso2metrics_db wso2dm_db android_db windows_db"
    for database in ${databases}; do
        PGPASSWORD=${db_password} dropdb ${db_prefix}_${database} -h ${db_server_ip} -U ${db_username}
        PGPASSWORD=${db_password} createdb ${db_prefix}_${database} -h ${db_server_ip} -U ${db_username}
        [ $? == 0 ] || exit $?
    done

    info "Create database tables"

    db_sqls="
    wso2carbon_db:core/dbscripts/postgresql.sql
    wso2appm_db:core/dbscripts/appmgt/postgresql.sql
    wso2am_db:core/dbscripts/apimgt/postgresql.sql
    wso2mb_db:broker/dbscripts/postgresql.sql
    wso2metrics_db:core/dbscripts/metrics/postgresql.sql
    wso2dm_db:core/dbscripts/cdm/postgresql.sql
    wso2dm_db:core/dbscripts/certMgt/postgresql.sql
    android_db:core/dbscripts/cdm/plugins/android/postgresql.sql
    windows_db:core/dbscripts/cdm/plugins/windows/postgresql.sql
    es_storage:core/dbscripts/storage/postgre-new/storage-resource.sql
    wso2_social_db:core/dbscripts/social/postgres-new/social-resource.sql
    "
    for db_sql in ${db_sqls}; do
        db=$(echo ${db_sql} | cut -d : -f 1)
        sql=$(echo ${db_sql} | cut -d : -f 2)
        PGPASSWORD=${db_password} psql -h ${db_server_ip} -U ${db_username} -d ${db_prefix}_${db} < template/${sql}
        [ $? == 0 ] || exit $?
    done

}

function config_db(){

    info "Start server with -Dsetup"

    ${wso2home}/core/bin/wso2server.sh -Dsetup > /dev/null 2>&1 &
}

case "$1" in
    install)
        install
        ;;
    ip)
        config_ip
        ;;
    samlsso)
        config_samlsso
        ;;
    ssl)
        config_ssl_authentication
        ;;
    security)
        config_security
        ;;
    keystore)
        config_keystore
        ;;
    analytics)
        config_analytics
        ;;
    postgresql)
        config_postgresql
        ;;
    db)
        config_db
        ;;
    all)
        install
        config_ip
        config_samlsso
        config_ssl_authentication
        config_security
        config_keystore
        #config_postgresql
        config_db
        config_analytics
        ;;
    *)
        echo "Usage $0 install|ip|samlsso|ssl|security|keystore|analytics|postgresql|db|all"
        echo "  install     Install the product"
        echo "  ip          Configuring WSO2 IoT Server with the IP"
        echo "  samlsso     Modify the files about samlsso"
        echo "  ssl         Configure WSO2 IoT Server for mutual SSL authentication"
        echo "  security    Install WSO2 API Manager Features in WSO2 G-Reg"
        echo "  keystore    Generate keystore and update JKS"
        echo "  analytics   Configure device analytics"
        echo "  postgresql  Setup Postgresql"
        echo "  db          Create database tables"
        echo "  all         Execute all above"
        exit 1
esac

info "End of Installation"
