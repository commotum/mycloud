---
title: "Processing Transactions | Datomic"
source: "https://docs.datomic.com/transactions/transaction-processing.html"
author:
published:
created: 2025-05-03
description: "Learn how to process, monitor and operate Datomic transactions."
tags:
  - "clippings"
---
## Processing Transactions

## Processing Transactions

After a transaction data structure is built, you must submit it to the transactor for processing. The transactor queues transactions and processes them serially.

### Submitting Transactions

Once a transaction data structure is built, you submit it to the transactor by calling `transact` or `transact-async`.

In the Peer API, both functions return a Clojure future that will eventually contain the transaction's result.

In the Client API, `datomic.client.api/transact` will block until a transaction result is returned, while `datomic.client.api.async/transact` will return a core.async channel that will eventually contain the transaction's result.

### Transaction Timeouts

When a transaction times out, the peer does not know whether the transaction succeeded, and will need to query a recent value of the database to discover what happened.

### Monitoring Transactions

Peers can monitor all transactions being processed by the system's transactor. In the Peer API, [tx-report-queue](https://docs.datomic.com/clojure/index.html#datomic.api/tx-report-queue) returns a queue of transaction notifications.

The queue delivers a report for every transaction submitted while a peer is connected to the database, even those submitted by other peers.

Reports are records with the following keys:

| key | usage |
| --- | --- |
| :db-before | database value before the transaction |
| :db-after | database value after the transaction |
| :tx-data | datoms produced by the transaction |
| :tempids | argument to [resolve-tempid](https://docs.datomic.com/clojure/index.html#datomic.api/resolve-tempid) |

It is the responsibility of your application to empty the queue. When you are done monitoring the queue, remove it by calling [remove-tx-report-queue](https://docs.datomic.com/clojure/index.html#datomic.api/remove-tx-report-queue) otherwise it will continue to accumulate transaction reports and consume memory.

This example shows how to connect to the notification queue, and retrieve a transaction report from it:

The `tx-data` of a transaction report contains the set of datoms created by a transaction (both assertions and retractions). The `tx-data` can be used as an input source for a query. The query below uses the `tx-data` and the database value after the transaction was applied to show each datom of the transaction.

The query expects the `db-after` and `tx-data` values of a transaction report as its two input sources, in that order.

Check [Query](https://docs.datomic.com/query/query-data-reference.html#relation-binding) for more information on using sets of tuples as input sources in queries.