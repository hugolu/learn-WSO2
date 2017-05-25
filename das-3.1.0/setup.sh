#!/bin/bash 
source config.ini

function info() { echo -e "\e[34m[INFO]\e[0m $1"; }

wso2home=${root_dir}/wso2das

function install(){

    info "Install the product"

    unziped_dir=${root_dir}/`basename ${zip_file} .zip`

    rm -rf ${wso2home} ${unziped_dir} > /dev/null 2>&1
    unzip ${zip_file} -d ${root_dir}
    ln -s ${unziped_dir} ${wso2home}
}

function config_port(){

    info "Configure WSO2 DAS Server port offset"

    files="
    repository/conf/carbon.xml
    "
    for file in ${files}; do
        cp -f template/${file} ${wso2home}/${file}
    done
}

function config_dashboard(){

    info "Config WSO2 Dashboard Server IP"

    files="
    repository/deployment/server/jaggeryapps/portal/configs/designer.json
    "

    for file in ${files}; do
        echo "modify $file"
        sed "s/DAS_SERVER_IP/${das_server_ip}/g" < template/${file} > ${wso2home}/${file}
        [ $? == 0 ] || exit $?
    done
}

function config_keystore(){

    info "Copy jks to WSO2 DAS"

    client_truststore_files="
    samples/httpd-logs/src/main/resources/client-truststore.jks
    samples/apim-stats/src/main/resources/client-truststore.jks
    samples/smart-home/src/main/resources/client-truststore.jks
    samples/wikipedia/src/main/resources/client-truststore.jks
    samples/cep/producers/soap/src/main/resources/client-truststore.jks
    repository/resources/security/client-truststore.jks
    "
    for file in ${client_truststore_files}; do
        cp -f ../keystore/client-truststore.jks ${wso2home}/${file}
        [ $? == 0 ] || exit $?
    done

    wso2carbon_files="
    samples/cep/producers/soap/src/main/resources/wso2carbon.jks
    repository/resources/security/wso2carbon.jks
    "
    for file in ${wso2carbon_files}; do
        cp -f ../keystore/wso2carbon.jks ${wso2home}/${file}
        [ $? == 0 ] || exit $?
    done
}

function copy_sample(){

    info "Copy SVM samples"
    
    files="
    repository/deployment/server/eventpublishers/cpu2ui.xml
    repository/deployment/server/eventpublishers/mem2ui.xml
    repository/deployment/server/eventpublishers/warning2log.xml
    repository/deployment/server/eventreceivers/android_event_receiver.xml
    repository/deployment/server/eventstreams/org.wso2.android.agent.cpu_1.0.0.json
    repository/deployment/server/eventstreams/org.wso2.android.agent.mem_1.0.0.json
    repository/deployment/server/eventstreams/org.wso2.android.agent.Stream_1.0.0.json
    repository/deployment/server/eventstreams/org.wso2.android.agent.svm_1.0.0.json
    repository/deployment/server/eventstreams/org.wso2.android.agent.waning_1.0.0.json
    repository/deployment/server/executionplans/StreamExecutionPlan.siddhiql
    repository/deployment/server/executionplans/SvmExecutionPlan.siddhiql
    "
    for file in ${files}; do
        cp -f template/${file} ${wso2home}/${file}
        [ $? == 0 ] || exit $?
    done

    dirs="
    repository/deployment/server/jaggeryapps/portal/store/carbon.super/fs/gadget/cpu/
    repository/deployment/server/jaggeryapps/portal/store/carbon.super/fs/gadget/mem/
    "
    for dir in ${dirs}; do
        rm -rf ${wso2hoem}/${dir}
        cp -a template/${dir} ${wso2home}/${dir}
        [ $? == 0 ] || exit $?
    done
}

case "$1" in
    install)
        install
        ;;
    port)
        config_port
        ;;
    dashboard)
        config_dashboard
        ;;
    keystore)
        config_keystore
        ;;
    sample)
        copy_sample
        ;;
    all)
        install
        config_port
        config_dashboard
        config_keystore
        ;;
    *)
        echo "Usage $0 install|port|dashboard|keystore|all"
        echo "  install     Install the product"
        echo "  port        Configure WSO2 DAS Server port offset"
        echo "  dashboard   Configure WSO2 Dashboard Server IP"
        echo "  keystore    Copy jks to WSO2 DAS"
        echo "  all         Execute all above"
        exit 1
esac

info "End of Installation"
