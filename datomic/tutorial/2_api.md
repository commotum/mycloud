---
title: "Client API Tutorial | Datomic"
source: "https://docs.datomic.com/client-tutorial/client.html"
author:
published:
created: 2025-05-03
description: "Explore the Datomic Client API tutorial. Learn how to connect, query, and transact with Datomic using step-by-step examples and practical guidance."
tags:
  - "clippings"
---
## Client API Tutorial

This tutorial introduces the Datomic Client API. You will:

- [Create a database](https://docs.datomic.com/client-tutorial/#create-database)
- [Transact schema](https://docs.datomic.com/client-tutorial/#transact-schema)
- [Transact data](https://docs.datomic.com/client-tutorial/#transact-data)
- [Query the database](https://docs.datomic.com/client-tutorial/#query)
- Optionally [delete the database](https://docs.datomic.com/client-tutorial/#delete-database) when you are done

## Prerequisites

This tutorial assumes that you have [setup Datomic Local](https://docs.datomic.com/datomic-local.html) and started a REPL with Datomic Local on your classpath, or you have [launched](https://docs.datomic.com/setup-cloud/cloud-setup.html) a Datomic Cloud system and know how to start a Clojure REPL with the [Datomic client API installed](https://docs.datomic.com/accessing/integrating-client-lib.html#installing).

## Create a Client

### Using Datomic Local

To interact with Datomic, you must first create a [datomic.client.api/client](https://docs.datomic.com/client-api/datomic.client.api.html#var-client).

In your REPL, execute:

### Using Datomic Cloud

To [connect](https://docs.datomic.com/client-api/datomic.client.api.html#var-connect) to Datomic Cloud, you will need the following information:

- `:region` is the AWS region in which you've started Datomic Cloud.
- `:system` is your Datomic system's name.
- `:endpoint` is your system's client endpoint. Check your [CloudFormation outputs](https://docs.datomic.com/operation/howto.html#template-outputs) for `ClientApiGatewayEndpoint`.

Use this information to create a client with [datomic.client.api/client](https://docs.datomic.com/client-api/datomic.client.api.html#var-client).

Even though the endpoint is public, client access is securely managed by [IAM permissions](https://docs.datomic.com/operation/access-control.html#how-datomic-access-control-works).

Warnings may occur. Do not be alarmed as they will not affect functionality during this tutorial.

## Create a Database

- Create a new database with [datomic.client.api/create-database](https://docs.datomic.com/client-api/datomic.client.api.html#var-create-database):
- Now you're ready to connect to your newly created database using [datomic.client.api/connect](https://docs.datomic.com/client-api/datomic.client.api.html#var-connect):

The next step will be to define some schema for your new database.

Schema defines the set of possible attributes that can be associated with an entity. We'll need to provide 3 attributes: [db/ident](https://docs.datomic.com/schema/schema-reference.html#db-ident), [db/valueType](https://docs.datomic.com/schema/schema-reference.html#db-valuetype) and [db/cardinality](https://docs.datomic.com/schema/schema-reference.html#db-cardinality).[db/doc](https://docs.datomic.com/schema/schema-reference.html#db-doc) will also be provided for documentation.

## Transact Schema

Now we need to create a [schema](https://docs.datomic.com/schema/schema.html).

- Define the following small schema for a database about movies:
- Now transact the schema using [datomic.client.api/transact](https://docs.datomic.com/client-api/datomic.client.api.html#var-transact).

You should get back [a response](https://docs.datomic.com/transactions/transaction-processing.html#results) as shown above.

## Transact Data

- Now you can define some movies to add to the database utilizing the [schema](https://docs.datomic.com/schema/schema-reference.html#defining-schema) we defined earlier:
- [Transact](https://docs.datomic.com/transactions/transaction-processing.html) the movies into the database:

You should see a response similar to the above with different data.

## Query

- Get a current value for the database with [datomic.client.api/db](https://docs.datomic.com/client-api/datomic.client.api.html#var-db):
- Now create a [query](https://docs.datomic.com/query/query-executing.html) for all movie titles:
- And execute the query with the value of the database using [datomic.client.api/q](https://docs.datomic.com/client-api/datomic.client.api.html#var-q):

If your database has a large number of movies, it may be prudent to use [qseq](https://docs.datomic.com/query/query-executing.html#qseq) to return a lazy sequence quickly rather than waiting for the full results to build and return.

## Delete a Database (Optional)

When you are done with this tutorial, you can use [datomic.client.api/delete-database](https://docs.datomic.com/client-api/datomic.client.api.html#var-delete-database) to delete the *movies* database:

The set of possible attributes that can be associated with entities. Any entity can have any attribute.