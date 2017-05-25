/**
 * Copyright (c) 2009, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 * <p/>
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * <p/>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p/>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.wso2.android.agent.stream;

import org.apache.log4j.PropertyConfigurator;
import org.wso2.carbon.databridge.agent.AgentHolder;
import org.wso2.carbon.databridge.agent.DataPublisher;
import org.wso2.carbon.databridge.agent.exception.DataEndpointAgentConfigurationException;
import org.wso2.carbon.databridge.agent.exception.DataEndpointAuthenticationException;
import org.wso2.carbon.databridge.agent.exception.DataEndpointConfigurationException;
import org.wso2.carbon.databridge.agent.exception.DataEndpointException;
import org.wso2.carbon.databridge.commons.Event;
import org.wso2.carbon.databridge.commons.exception.TransportException;
import org.wso2.carbon.databridge.commons.utils.DataBridgeCommonsUtils;

import java.io.File;
import java.io.FileNotFoundException;
import java.net.*;
import java.util.Enumeration;
import java.util.Random;


public class Publisher{
    private static final String ANDROID_AGENT_STREAM = "org.wso2.android.agent.Stream";
    private static final String VERSION = "1.0.0";
    private static final int defaultThriftPort = 7613;
    private static final int defaultBinaryPort = 9613;
    private static final Random RAND = new Random();
    private static int count;

    public static void main(String[] args) throws DataEndpointAuthenticationException,
            DataEndpointAgentConfigurationException,
            TransportException,
            DataEndpointException,
            DataEndpointConfigurationException,
            FileNotFoundException,
            SocketException,
            UnknownHostException {

        String log4jConfPath = "./src/main/resources/log4j.properties";
        PropertyConfigurator.configure(log4jConfPath);

        System.out.println("Starting Android Agent");
        String currentDir = System.getProperty("user.dir");
        System.setProperty("javax.net.ssl.trustStore", currentDir + "/src/main/resources/client-truststore.jks");
        System.setProperty("javax.net.ssl.trustStorePassword", "wso2carbon");

        AgentHolder.setConfigPath(getDataAgentConfigPath());
        String host = getLocalAddress().getHostAddress();

        String type = getProperty("type", "Thrift");
        int receiverPort = defaultThriftPort;
        if (type.equals("Binary")) {
            receiverPort = defaultBinaryPort;
        }
        int securePort = receiverPort + 100;

        String url = getProperty("url", "tcp://" + host + ":" + receiverPort);
        String authURL = getProperty("authURL", "ssl://" + host + ":" + securePort);
        String username = getProperty("username", "admin");
        String password = getProperty("password", "admin");

        if (args[0] == null || args[0].isEmpty() || args[0].equals("count")) {
            count = 60*60*24;
        } else {
            count = Integer.parseInt(args[0]);
        }

        DataPublisher dataPublisher = new DataPublisher(type, url, authURL, username, password);

        String streamId = DataBridgeCommonsUtils.generateStreamId(ANDROID_AGENT_STREAM, VERSION);
        for (int i = 0; i < count; i++) {
            publishEvent(dataPublisher, streamId);
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                // do nothing
            }
        }
        dataPublisher.shutdown();
    }

    public static String getDataAgentConfigPath() {
        File filePath = new File("src" + File.separator + "main" + File.separator + "resources");
        if (!filePath.exists()) {
            filePath = new File("test" + File.separator + "resources");
        }
        if (!filePath.exists()) {
            filePath = new File("resources");
        }
        if (!filePath.exists()) {
            filePath = new File("test" + File.separator + "resources");
        }
        return filePath.getAbsolutePath() + File.separator + "data-agent-conf.xml";
    }

    private static void publishEvent(DataPublisher dataPublisher, String streamId) throws FileNotFoundException, SocketException, UnknownHostException {
        for (int did = 0; did < 10; did++) {
            int availMem = RAND.nextInt(522956800);
            String content = String.format("{\"isDoorOpened\":%s,\"isLackOf50Cent\":%s,\"isLackOf100Cent\":%s,\"isSoldOut\":%s,\"isVMCDisconnected\":%s,\"User\":%d,\"System\":%d,\"IOW\":%d,\"IRQ\":%d,\"availMem\":%d,\"totalMem\":522956800,\"lowMemory\":%s,\"threshold\":62667776}",
                    RAND.nextInt(100) > 98 ? "true" : "false",
                    RAND.nextInt(100) > 98 ? "true" : "false",
                    RAND.nextInt(100) > 98 ? "true" : "false",
                    RAND.nextInt(100) > 98 ? "true" : "false",
                    RAND.nextInt(100) > 98 ? "true" : "false",
                    RAND.nextInt(30), RAND.nextInt(30), RAND.nextInt(20), RAND.nextInt(20), availMem,
                    availMem < 62667776 ? "true" : "false");

            Object[] payload = new Object[]{
                    String.valueOf(did),
                    content,
                    "SVM_STATE"};
            Event event = new Event(streamId, System.currentTimeMillis(), null, null, payload);
            dataPublisher.publish(event);
            System.out.println(did + " publishs " + content);
        }
    }

    public static InetAddress getLocalAddress() throws SocketException, UnknownHostException {
        Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
        while (interfaces.hasMoreElements()) {
            NetworkInterface iface = interfaces.nextElement();
            Enumeration<InetAddress> addresses = iface.getInetAddresses();

            while (addresses.hasMoreElements()) {
                InetAddress addr = addresses.nextElement();
                if (addr instanceof Inet4Address && !addr.isLoopbackAddress()) {
                    return addr;
                }
            }
        }
        return InetAddress.getLocalHost();
    }


    private static String getProperty(String name, String def) {
        String result = System.getProperty(name);
        if (result == null || result.length() == 0 || result.equals("")) {
            result = def;
        }
        return result;
    }

}
