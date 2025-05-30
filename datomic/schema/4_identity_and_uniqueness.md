---
title: "Identity and Uniqueness | Datomic"
source: "https://docs.datomic.com/schema/identity.html"
author:
published:
created: 2025-05-03
description: "Understand Datomic identity schemas. Learn how to define and manage unique identities and ensure data consistency in your applications."
tags:
  - "clippings"
---
## Identity and Uniqueness

Datomic provides a number of ways to model identity and uniqueness:

- All entities have database-unique *entity ids*.
- *Idents* can be used for programmatic names.
- *Unique identities* allow transactions to work with domain keys instead of entity ids.
- *Unique values* enforce a single holder of an identifying key.
- *Squuids* provide efficient, globally unique identifiers.
- *Lookup Refs* represent a lookup on a unique attribute as an attribute, value pair.

Each of these is described below.

## Entity Identifiers

An *entity identifier* is any one of the three ways that Datomic can uniquely identitfy an entity: an entity id, ident, or lookup ref. Most Datomic APIs that refer to entities take entity identifiers as arguments.

## Entities

Every datom in Datomic includes a database-unique entity id, often abbreviated as simply *e* in documentation and API names. Entity ids are assigned by the transactor, and never change.

You can request new entity ids by specifying a temporary id (tempid) in transaction data. The [Peer.tempid](https://docs.datomic.com/javadoc/datomic/Peer.html#tempid-java.lang.Object-long-) method creates a new tempid, and the [Peer.resolveTempid](https://docs.datomic.com/javadoc/datomic/Peer.html#resolveTempid-datomic.Database-java.lang.Object-java.lang.Object-) method can be used to interrogate a transaction return value for the actual id assigned.

Internally, entity ids encode the partition an entity belongs to. An entity's partition may be useful in some cases, and can be discovered by calling [Peer.part](https://docs.datomic.com/javadoc/datomic/Peer.html#squuidTimeMillis-java.util.UUID-).

Transactions and partitions are discussed fully in [transactions](https://docs.datomic.com/transactions/transactions.html).

## Idents

Idents associate a programmatic name (a keyword) with an entity id, by setting a value for the *:db/ident* attribute:

When an entity has an ident, you can use that ident in place of the numeric identifier, e.g.

instead of:

Idents should be used for two purposes: to name schema entities and to implement enumerated tags. To support these usages, idents have two special characteristics:

- Idents are designed to be extremely fast and always available. All idents associated with a database are stored in memory in every Datomic transactor and peer.
- When you navigate the entity API to a reference that has an ident, the lookup will return the ident, not another entity.

These characteristics also imply situations where idents should *not* be used:

- Idents should not be used as unique names or ids on ordinary domain entities. Such entity names should be implemented with a domain-specific attribute that is a unique identity.
- Idents should not be used as names for test data. (Your real data will not have such names, and you don't want test data to behave differently than the real data it simulates.)

Idents can be used instead of entity ids in the following API calls:

- As the sole argument to [entity](https://docs.datomic.com/javadoc/datomic/Database.html#entity-java.lang.Object-).
- In the e, a, and v positions of assertions and retractions passed to [transact](https://docs.datomic.com/javadoc/datomic/Connection.html#transact-java.util.List-) and [with](https://docs.datomic.com/javadoc/datomic/Database.html#with-java.util.List-).
- In the e, a, and v positions of a [query](https://docs.datomic.com/query/query.html).

There are some situations where Datomic cannot know that a keyword is an ident. For example, Datomic does not know the semantics of database functions written by you. If you need to convert between idents and entity ids in your own code, you can use the [ident](https://docs.datomic.com/javadoc/datomic/Database.html#ident-java.lang.Object-) and [entid](https://docs.datomic.com/javadoc/datomic/Database.html#entid-java.lang.Object-) methods on the *Database* class.

## Unique Identities

Unique identity is specified through an attribute with *:db/unique* set to *:db.unique/identity*. For example, this schema asserts that a *:inv/sku* is unique:

Unique identity is appropriate whenever you want to assert a database-wide unique identifier for an entity. Common examples include email, account name, product code (and UUIDs, but see Squuids, below). Unique identities have the following properties:

- A unique identity attribute is always indexed by value, in order to support uniqueness checks. Specifying *:db/index true* is redundant and not recommended.
- Uniqueness checks are per-attribute, and do not prevent you from using the same value with a different attribute elsewhere.
- If a transaction specifies a unique identity for a temporary id, and that unique identity already exists in the database, then that temporary id will resolve to the *existing* entity in the system. This *upsert* behavior makes it possible for transactions to work with domain identities, without ever having to specify Datomic entity ids.

It is legal for a single entity to have multiple different unique attributes, e.g. you might decide that people have both unique emails and unique government identifiers. However, note that this creates the possibility of conflict, which will result in a transaction throwing an *IllegalStateException*. (Conflict will occur if a transaction tries to upsert a tempid into two *different* existing entities. As an example. if entity 42 has the unique email "johndoe@example.com", and entity 43 has the unique account number 1007, then a transaction cannot claim that a new tempid is both John Doe and account 1007.)

Uniqueness can be declared on attributes of any value type, including references (*:db.type/ref*). Only (*:db.cardinality/one*) attributes can be unique.

Datomic does provide a mechanism to declare composite uniqueness constraints via [composite tuples](https://docs.datomic.com/schema/schema.html#composite-tuples).

## Unique Values

Unique value is specified through an attribute with *:db/unique* set to *:db.unique/value*. A unique value represents a database-wide value that can be asserted only once.

Unique values have the same semantics as unique identities, with one critical difference: Attempts to assert a new tempid with a unique value already in the database will cause an *IllegalStateException*.

## Squuids

It is often important to have a globally unique identifier for an entity. Where such identifiers do not already exist in the domain, you can use a unique identity attribute with a value type of*:db.type/uuid*.

In all systems that maintain a value-sorted index, checking for the existence or uniqueness of random (v4) UUIDs has poor locality, as reads will scatter across all the UUIDs. To address this, Datomic includes a semi-sequential UUID generator, [squuid](https://docs.datomic.com/clojure/index.html#datomic.api/squuid). Squuids are valid UUIDs, but unlike purely random UUIDs, they include a leading time component, which helps align read patterns with recency. Applications may also choose to use v7 UUIDs for the same rationale.

You can retrieve the time component of a squuid with [squuid-time-millis](https://docs.datomic.com/clojure/index.html#datomic.api/squuid-time-millis).

If the ability to discover the time that a squuid was created leaks sensitive information, then squuids may not be appropriate. However, you should still prefer Squuids (or v7 UUIDs) if your ids may ever be indexed in other, non-Datomic systems.

## Lookup Refs

In many databases, entities have unique identifiers from the problem domain like an email address or an order number. Applications often need to find entities based on these external keys. You can do this with query, but it's easier to use a *lookup ref*. A lookup ref is a *java.util.List* containing an attribute and a value. It identifies the entity with the given unique attribute value. For example, this lookup ref:

identifies the entity with the *:person/email* value "joe@example.com".

You can use lookup refs to retrieve entities using the *entity* and datoms using the *datoms* and *seek-datoms* APIs. You cannot use them in the body of a query, use datalog clauses instead.

You can also use lookup refs to refer to existing entities in transactions, avoiding extra lookup code:

This transaction asserts that the entity with the value "joe@example.com" for the *:person/email* attribute also loves pizza.

Lookup refs have the following restrictions:

- The specified attribute must be defined as either*:db.unique/value* or *:db.unique/identity*.
- When used in a transaction, the lookup ref is evaluated against the specified attribute's index as it exists before the transaction is processed, so you cannot use a lookup ref to lookup an entity being defined in the same transaction.
- Lookup refs cannot be used in the body of a query though they can be used as [inputs in a parameterized query](https://docs.datomic.com/query/query.html#multiple-inputs).

Lookup refs used in a transaction will be resolved by the transactor. Lookup refs used with *datoms* or *seek-datoms* will resolve on the peer using the database value provided.

## Joins Should Use Entity IDs

Entity ids are native to Datomic, have a compact numeric representation, and are stored as part of every datom.

Queries against a single database can lookup entity ids via other kinds of identifiers, but for efficiency should join by entity id.

## Limitations

Attributes of type *:db.type/bytes* cannot be unique and cannot be used as lookup refs. Check [bytes limitations](https://docs.datomic.com/schema/schema.html#bytes-limitations).