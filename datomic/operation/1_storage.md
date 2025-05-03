---
title: "Setting up Storage Services | Datomic"
source: "https://docs.datomic.com/operation/storage.html"
author:
published:
created: 2025-05-03
description: "Discover how to choose and configure storage options in Datomic."
tags:
  - "clippings"
---
## Setting up Storage Services

This document walks through the process of provisioning a storage service for use with Datomic Pro.

### Storage Services

Storage service options are listed here:

- [Dev mode (dev)](https://docs.datomic.com/operation/#dev-mode)
- [SQL database (SQL)](https://docs.datomic.com/operation/#sql-database)
- [DynamoDB (DDB)](https://docs.datomic.com/operation/#dynamo)
- [Cassandra (Cass3)](https://docs.datomic.com/operation/#cassandra)

The steps required to provision them and detailed instructions are included below (links provided here for convenience).

Note that you can move an application from one storage service to another simply by switching the connection string used by peers and the properties file used to start the transactor. All are fully API-compatible.

> All of the script commands described in this document must be executed from the root directory of the Datomic distribution.

### Storage Client Dependencies

Datomic depends on various storage client libraries. The recommended versions of all storage client libraries are in the `provided` scope of the Datomic pom.xml file:

These jars are included in the Datomic distribution `/lib`, and are used by the transactor to access the storage systems. Peers will need the jars corresponding to the storage system on their classpath as well.

## Dev Mode

The dev storage protocol is intended for development. It runs an embedded JDBC server inside the transactor, and uses local disk files for storage.

By default, the embedded storage runs with default passwords and is accessible only by other processes on the same machine. This configuration is intended for interactive development where application peers and the transactor are colocated.

### Securing Remote Access

To allow remote peers access to embedded storage you must do three things:

- Choose two passwords for the embedded storage
- Set the `storage-access` property
- Add a password to the connection URI used by peers

### Choose Passwords

Datomic's embedded JDBC storage has two passwords: an 'admin' password used by the transactor plus a 'datomic' password used by the peers. Once you set these passwords, you are responsible for remembering them. If you lose a password, you will not be able to access your data and will need to recover from a Datomic backup.

Set the passwords by setting the following transactor properties:

### Set storage-access Property

To enable remote access to Datomic's embedded storage, set the following transactor property:

New transactor properties will take effect on the next transactor start.

### Rotating Passwords

Once you have set the `storage-datomic-password`, you can rotate it as follows:

- Set `old-storage-datomic-password` to the current password
- Set `storage-datomic-password` to a new password
- Restart the transactor
- Change peer Connection URIs to use the new password

The `storage-admin-password` can be rotated similarly. Be careful not to lose track of passwords while performing a password rotation.

## SQL Database

The steps to provision a SQL database as your storage service are:

- Setup a SQL database, or use an existing one
- Create SQL table (datomic\_kvs)
- Create SQL user(s), or use an existing one
- Get JDBC connection string
- Add JDBC driver dependencies to your project

There are scripts for doing each of the first three steps with [PostgreSQL](https://www.postgresql.org/), [MySQL](https://www.mysql.com/), and [Oracle](https://www.oracle.com/database/) in the Datomic distribution's *bin/sql* directory. You can run them using their respective command line or GUI admin tools.

For example, for Postgres at the command line:

The last script creates a user named 'datomic' with the password 'datomic'. You can use an existing user instead, or modify the script to create a user with a different username or password, if desired.

If you want to use a different SQL server, mimic the table and schema from one of the included databases.

### JDBC Drivers

Only the Postgres driver is included with the transactor distribution. For other SQL distributions, follow the steps below:

- Make the driver available on the classpath of the transactor by placing it in <datomic-install>/lib.
- In your peer project, add a dependency for your specific JDBC driver in all SQL distributions. The example below shows how that looks for PostgreSQL.
- In a Maven-based build, add the following snippet to the dependencies section of your pom.xml:
- In a Leiningen project, add the following to the dependencies section of your *project.clj* in the collection under `:dependencies` key:

### Validation Query

Datomic uses a query to validate JDBC connections. By default, this query is:

For Oracle JDBC URIs, the query is:

> This validation query can be overridden via the [`datomic.sqlValidationQuery` system property](https://docs.datomic.com/operation/system-properties.html#transactor-properties).

### Heroku PostgreSQL Database

You can provision a Heroku-hosted PostgreSQL database for use as your storage service using the following steps:

- Sign up for Heroku PostgreSQL.
- Start a database and retrieve the host, port, dbname, username, and password from the web console.
- Use PGAdmin to install the Datomic table schema by:
	- Adding a server using the connection information retrieved in the previous step and specifying the dbname for the MaintenanceDB (in place of 'postgres') as well as the actual database.
	- Open a SQL window on that server and paste it into the bin/sql/postgres-table script.
	- Edit the owner and grant to be the user Heroku provides and remove the public grant.
	- Run the script to create the datomic\_kvs table.

