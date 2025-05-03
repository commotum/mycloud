---
title: "Comparison with Updating Transactions | Datomic"
source: "https://docs.datomic.com/tech-notes/comparison-with-updating-transactions.html"
author:
published:
created: 2025-05-03
description: "Compare Datomic's update transactions with traditional systems."
tags:
  - "clippings"
---
## Comparison with Updating Transactions

Some database systems compose transactions from a series of updates, where each update changes the state of the database. Depending on the degree of isolation provided, transactions might also see interleaved updates from other transactions, e.g. *a'* might not even equal *b* in:

Datomic transaction execution is not defined as a series of updates. This section highlights the differences, which may be helpful to people accustomed to working with updating transactions.

A Datomic transaction [is defined as the addition of a set of datoms](https://docs.datomic.com/transactions/transactions.html#transaction-execution) to the previous (db-before) value of a database. In particular, a Datomic transaction is not defined as a batch of smaller updates. Assertions and retractions are not read/modify/write operations, nor are they functions of `db->db`, they are just information, and the transaction's operation is to append them, as a set, to `db-before`. No information residing in db-before is displaced or modified by transaction application. No rules about the order of read/modify/write updates within a `tx` can be violated by Datomic as no such updates are provided.

Datomic transaction functions are functions of `db-before * args -> tx-data`. They do not update anything. In particular, Datomic does not use the data returned from transaction functions to produce interim database values.

Compared to systems that compose transactions from updates, Datomic's transactions enable a set of powerful guarantees that facilitate reasoning about programs:

- Database values are always composed only of complete transactions
- Every fact (datom) in a database is associated with a complete transaction
- Every datom is part of a complete transaction order, queryable via `t`

Database systems that offer incremental updates of a database cannot offer any of these guarantees.

Check [composing transactions](https://docs.datomic.com/tech-notes/composing-transactions-by-example.html) for examples of how to compose transactions that enforce domain invariants.