---
title: "Transactor Reference | Datomic"
source: "https://docs.datomic.com/operation/transactor.html"
author:
published:
created: 2025-05-03
description: "Learn how to run and manage a Datomic transactor."
tags:
  - "clippings"
---
## Transactor Reference

## Running the Transactor

A Datomic transactor performs ACID transactions for a set of databases. You can launch a transactor for one or more databases with the bin/transactor script in the Datomic directory:

```
cd /home/user/datomic/datomic-pro-1.0.7277
```

Once your storage service is configured, you can start the transactor locally by running *bin/transactor*. It takes a properties file as input. The file varies depending on the storage service:

- For Dev and SQL, make a copy of the appropriate template properties file in *config/samples* and edit it as desired.
- If you are using a Heroku-hosted PostgreSQL instance, edit your *sql-transactor-template.properties* as follows:
	1. Add the Heroku-provided host and database name to the JDBC URL in the *sql-url* property.
	2. Put the username and password in the *sql-user* and *sql-password* properties.
	3. Uncomment the *sql-driver-params* property and set it to:
```
sql-driver-params=ssl=true&sslfactory=org.postgresql.ssl.NonValidatingFactory
```
- When you run the transactor locally against DynamoDB, specify AWS access keys using either environment variables (AWS\_SECRET\_KEY and AWS\_ACCESS\_KEY\_ID) or Java system properties (aws.secretKey and aws.accessKeyId). You can use your AWS account access keys or a set of IAM user access keys. If you use IAM user access keys, the user must be assigned the [necessary policies](https://docs.datomic.com/setup/storage.html#manual-setup). Running locally this way should only be considered for development and is not a supported means for handling permissions in production.

> For more information on configuring the transactor review the [transactor properties section](https://docs.datomic.com/operation/system-properties.html#transactor-properties) of the documentation.

- To start the transactor, run the following command, passing in your

properties file:

> Check [configuring high availability](https://docs.datomic.com/operation/ha.html) for information on launching a second transactor for high availability.

If you set a `pid-file` in the transactor properties file, Datomic will write the current process ID to that file on startup.

The transactor startup script accepts JVM arguments, but note that JVM args other than `-Xmx` and `-Xms` passed to `bin/transactor` (including Java system properties passed via `-D`) override Datomic's recommended Java options, including the GC settings.

| JVM Argument | Dev default setting | Prod default setting |
| --- | --- | --- |
| Max Heap | Xmx1g | Xmx4g |
| Initial Heap size | Xms1g | Xms4g |
| GC Settings | \-XX:+UseG1GC | \-XX:+UseG1GC |
|  | \-XX:MaxGCPauseMillis=50 | \-XX:MaxGCPauseMillis=50 |

> Check [storage services](https://docs.datomic.com/overview/storage.html) and [peers](https://docs.datomic.com/operation/peer-getting-started.html) for information on supported storages and how transactors interact with peers.

### Health Check Endpoint

A web endpoint for a health check is **not** needed for the Datomic transactor. The Datomic transactor is not a web application, and Datomic [high availability](https://docs.datomic.com/operation/ha.html) takes care of transactor health automatically.

- However, some tools have a checklist requirement that all processes

provide a health check endpoint. If you need one, Datomic Pro lets you set a health check host and port in the transactor properties file:

- Or on the command line:

When the health check is enabled, Datomic will respond with a 2xx status code to HTTP requests for {host}:{port}/health, e.g.

### TrustStore and KeyStore

If you are accessing Cassandra via SSL, you must provide a

- Java [TrustStore](https://docs.oracle.com/cd/E21454_01/html/821-2544/cnfg_ssl-overview_c.html) for the transactor to use when connecting to storage.
- The TrustStore must contain one or more certificates that can be used to verify the

identity of the storage node(s) the transactor is connecting to.

- Provide a Java KeyStore that the transactor will use to establish an SSL connection with peers.
- Use the standard Java system properties to specify the TrustStore and KeyStore:

> Check the [Troubleshooting](https://docs.datomic.com/operation/#trouble-ssl) section for more info if you get an exception when trying to start the transactor with SSL.

If you are not using SSL to access Cassandra, Datomic configures a KeyStore for the transactor and a TrustStore for peers automatically.

If the console output includes a line of the form shown below, it means that the transactor is working correctly:

```
System started {URI}
```

> The URI is used by peers to attach to the system. Check the JavaDoc for [Peer.connect()](https://docs.datomic.com/javadoc/datomic/Peer.html#connect-java.lang.Object-) for the full connection details.

The transactor requires a Java 1.6+ Server VM. By default, the transactor runs with 1GB memory pool. You can change the default by passing a *\-Xmx* flag, as you would when you launch a JVM application directly.

Note that transactors and peers that use DynamoDB will have the best performance running on EC2. You can test them locally to ensure the correct configuration, but should deploy them to EC2 for the best performance.

## Connecting to the Transactor

After the transactor is running, you can test the configuration using the Datomic shell. You need the storage-specific connection URI as described in the JavaDoc for [Peer.connect()](https://docs.datomic.com/javadoc/datomic/Peer.html#connect-java.lang.Object-).

After connecting to storage, peers will look up the transactor endpoint. The transactor writes the value of the *host* transactor property in storage, and this is the address peers will attempt to connect to. If the transactor cannot bind to its publicly reachable IP address (e.g. the transactor is on a VM that doesn't own or can't see its external address), you will need to provide a value for *alt-host* on the transactor with the publicly reachable IP address in addition to the *host* property. If the peers cannot reach the transactor using *host* they will use the *alt-host* address instead.

If you are accessing Cassandra via SSL, you must provide a Java [TrustStore](https://docs.oracle.com/cd/E21454_01/html/821-2544/cnfg_ssl-overview_c.html) for the peer to use. The TrustStore must contain one or more certificates that can be used to verify the identity of the storage node(s) the peer is connecting to. The TrustStore must also contain the certificate that can be used to verify the identity of the transactor. You specify a TrustStore using the standard Java system properties:

> Check the [Troubleshooting](https://docs.datomic.com/operation/#trouble-ssl) section for more info if you get an exception when trying to connect a peer when using SSL.

If you are not using SSL to access Cassandra, Datomic configures a KeyStore for the transactor and a TrustStore for peers automatically.

The code below shows how to create and connect to a database using the Datomic shell:

### Configuring Options

Once you have verified that your transactor is working with your storage configuration, you can configure and test additional options, such as [memcached](https://docs.datomic.com/reference/caching.html#memcached).

To enable the use of Memcached, uncomment the *memcached* entry in your transactor properties file. Then set its value to a comma-delimited list of host:port pairs naming your memcached endpoints:

```
memcached=m1.example.com:11211,m2.example.com:11211
```

When you restart the transactor, it will transparently use Memcached.

> Check the [Caching documentation](https://docs.datomic.com/reference/caching.html) for more information on configuring Memcached.

### Running on AWS

Once you know everything is working, you may want to run your transactor on AWS if you are planning on using other AWS services, specifically Dynamo DB. The document [running on AWS](https://docs.datomic.com/operation/aws.html) contains the instructions.

### Troubleshooting SSL Connections

The following error message indicates that the transactor or peer cannot communicate with the storage nodes. Verify that you can connect to the storage nodes using other tools; for instance a simple Cassandra cqlsh. Also, verify that the TrustStore contains the certificates necessary for connecting to the storage nodes.

Typical error message when unable to connect to Cassandra via SSL:

```
com.datastax.driver.core.exceptions.NoHostAvailableException: All host(s) tried for query failed
```

If you see the following error message, this indicates that the transactor and peer are not configured with the same SSL information. Verify the transactor KeyStore and peer TrustStore are properly configured.

```
HornetQNotConnectedException HQ119007: Cannot connect to server(s). Tried with all available servers.  org.hornetq.core.client.impl.ServerLocatorImpl.createSessionFactory
```