---
title: "Reducing Latency with Transaction Hints | Datomic"
source: "https://docs.datomic.com/reference/hints.html"
author:
published:
created: 2025-05-03
description: "Learn how to reduce transaction latency with hints."
tags:
  - "clippings"
---
## Reducing Latency with Transaction Hints

Datomic creates a new database value by [accreting a database with a set of new information](https://docs.datomic.com/transactions/model.html). In order to accomplish this goal, Datomic reads the db-before to resolve identities in datoms, maintain composite tuple attributes, uphold invariants (e.g. unique values, cardinality-1 retractions, redundancy elimination), as well as to expand information sets or assert application invariants expressed through transaction functions and entity predicates.

Such reads against a db-before bound the minimum transaction latency, and thus it is important for data to be locally available before it is necessary. Datomic strives to prefetch reads as soon as it knows necessity. However, certain data dependencies limit the amount of prefetching possible: checking datom invariants cannot commence until entity IDs are resolved, and transaction functions are opaque and can do arbitrary things.

With Transaction Hints, Peers can analyze a transaction to convey hints that enable the transactor to prefetch data earlier and exhaustively. This can significantly increase transaction performance and is observable through [io-stats](https://docs.datomic.com/reference/io-stats.html) and [tx-stats](https://docs.datomic.com/reference/tx-stats.html). Though this requires speculatively running the transaction on the Peer prior to the transactor, Peers can independently and concurrently generate hints that reduce queueing and service time in the transactor.

## Using Transaction Hints

To calculate transaction hints in a Peer, use the [d/with](https://docs.datomic.com/clojure/index.html#datomic.api/with) API passing `:return-hints` true.

This augments the return with a `:hints` key, which can be passed to [d/transact](https://docs.datomic.com/clojure/index.html#datomic.api/transact) or [d/transact-async](https://docs.datomic.com/clojure/index.html#datomic.api/transact-async). Transaction semantics are unchanged when using hints, even though the db used to create hints and the db the transaction is durably incorporated into are different.

- If you use [classpath transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#types), those functions must be available on the Peer's classpath also.
- The transactor must have at least two CPU cores. The number of concurrent prefetch reads is configurable via [datomic.prefetchConcurrency](https://docs.datomic.com/operation/system-properties.html#transactor-properties).