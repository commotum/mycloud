---
title: "Transactions | Datomic"
source: "https://docs.datomic.com/transactions/transactions.html"
author:
published:
created: 2025-05-03
description: "Access guides and best practices for managing transactions in Datomic."
tags:
  - "clippings"
---
## Transactions

This section documents Datomic transactions. Start with the [transaction model](https://docs.datomic.com/transactions/model.html) document, which explains the semantics of Datomic transactions. After that, you can move to specific detail topics as needed:

- [Transaction model](https://docs.datomic.com/transactions/model.html): semantics of Datomic transactions
- [Transaction data](https://docs.datomic.com/transactions/transaction-data-reference.html): the transaction data format
- [Processing transactions](https://docs.datomic.com/transactions/transaction-processing.html): what happens when you call [d/transact](https://docs.datomic.com/clojure/index.html#datomic.api/transact)
- [Transaction functions](https://docs.datomic.com/transactions/transaction-functions.html): extending Datomic transactions with your code
- [ACID](https://docs.datomic.com/transactions/acid.html): how Datomic transactions deliver the ACID properties
- [Client synchronization](https://docs.datomic.com/transactions/client-synchronization.html): coordinating access to a particular point in time from multiple processes