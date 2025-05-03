---
title: "ACID | Datomic"
source: "https://docs.datomic.com/transactions/acid.html"
author:
published:
created: 2025-05-03
description: "Learn about ACID transactions in Datomic. Explore how Datomic ensures Atomicity, Consistency, Isolation, and Durability in your data management."
tags:
  - "clippings"
---
## ACID

Datomic transactions are ACID: Atomic, Consistent, Isolated, and Durable. This document defines the four components of ACID, explains how Datomic works, and explores the implications of Datomic's approach.

## Atomicity

Atomicity requires that each transaction is "all or nothing". If one part of a transaction fails, the entire transaction fails, and the database is left unchanged.

A Datomic transaction is written to durable storage in a single atomic write, so there is no possibility of partial work. Inside peer processes, the in-memory representation of a database is a pointer to a persistent data structure, and is also updated via a single atomic operation.

## Consistency

[Consistency](https://en.wikipedia.org/wiki/ACID) ensures that any transaction will take the database from one valid state to another. Datomic makes the following consistency guarantees:

- Every peer sees completed transactions as of a particular point in time, called a *time basis*.
- The time basis of transactions is a global ordering of transactions for a particular system. Peers always see all transactions up to their time basis, in order, with no gaps.

Datomic also provides first class support for accessing the time basis of information:

- Every fact in the database knows its time basis via the transaction component of a datom.
- A database value knows its time basis via [Database.basisT](https://docs.datomic.com/javadoc/datomic/Database.html#basisT--).
- Peers can synchronize on a time basis via [Connection.sync](https://docs.datomic.com/javadoc/datomic/Connection.html#sync-long-).

To correctly implement domain models, transactions need to be able to derive new facts based on existing facts (e.g. adding to a bank balance), and to enforce domain-specific functional constraints (e.g. a valid account must include name, email, and password hash). Datomic's [transaction functions](https://docs.datomic.com/transactions/transaction-functions.html) provide transformations and validations of transaction data based on the database value at start-of-transaction (db-before), and [entity predicates](https://docs.datomic.com/schema/schema-reference.html#entity-predicates) provide arbitrary predicates of the database value at end-of-transaction (db-after).

## Isolation

The Isolation property ensures that concurrent transactions result in the same system state that would result if the transactions were executed serially.

For purposes of understanding isolation, Datomic operations come in two flavors: reads and writes. A read is an operation which obtains the current value of the database: e.g., a call to [`d/db`](https://docs.datomic.com/clojure/index.html#datomic.api/db). A write is an operation which alters the state of the database, e.g. [`d/transact`](https://docs.datomic.com/clojure/index.html#datomic.api/transact).

Datomic guarantees serializability: all operations, across all nodes, appear to execute in a total order.

- Writes are *strong* serializable because they are fully serialized. Every successful transaction performs a storage CAS ensuring that its basis is the previous transaction.
- All operations on a single peer are monotonic. If operation Op1 completes before operation Op2 begins, a peer will always observe that Op1 executed before Op2. This holds for any combination of writes and reads.
- Reads across multiple peers are merely serializable. For instance, if peer P1 sees a write complete before peer P2 begins a read, P2 may not observe P1’s write. Operations that interact with multiple peers can explicitly ensure operation orders using [`sync`](https://docs.datomic.com/clojure/index.html#datomic.api/sync).

## Durability

Durability means that once a transaction has been committed, it has been recorded in durable storage. Datomic is fully durable–it always awaits acknowledgment from storage before reporting that a transaction is complete.

## How It Works

Datomic uses storage engines to store blocks (not individual datoms). Datomic keeps two trees of datoms in block storage:

- The *index* is updated periodically in the background and contains datoms sorted in various orders.
- The *log* is updated as part of every transaction and contains datoms grouped by transaction and sorted by time.

Both these trees are stored as sets of immutable values, and are compatible with eventually-consistent storage.

Pointers to the roots of trees are stored in durable references (refs). These refs are *not* compatible with eventual consistency. Therefore, refs are always updated by *conditional put* operations, which can ensure consistency of updates.

Conditional put is implemented in different ways, depending on the storage being used:

- DynamoDB uses conditional put.
- Cassandra uses lightweight transactions.
- SQL uses transactions.

Note that Datomic is tuned for efficient writes, so the details are more complex than this overview of the basic concepts. In particular, a Datomic system under load uses a combination of batching, transient data structures, and persistent data structures so that the average number of writes per transaction can be one, or even less than one.

## Implications

Datomic provides strong consistency of the entire database, while requiring only eventual consistency for the majority of actual writes.

Most Datomic writes are of tree nodes. These writes are compatible with eventually consistent storage, because the semantics of immutable values are beautifully simple: In an immutable system with no updates, there are only two possibilities:

- a value is present
- a value is not present yet

A few writes require the stronger semantics of conditional put:

- Conditional put of the log root pointer guarantees consistency at the transaction level.
- Conditional put of the index root pointer guarantees atomic adoption of a new index.

Another way to understand this is to consider the failure mode introduced by an eventually consistent *storage* node that is not up-to-date yet. Datomic will always see a correct log pointer, which was placed via conditional put. If some of the tree nodes are not yet visible underneath that pointer, Datomic is *consistent* but partially *unavailable*, and will become fully *available* when *eventually* happens.