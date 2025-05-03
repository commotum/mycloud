---
title: "Indexes | Datomic"
source: "https://docs.datomic.com/indexes/indexes.html"
author:
published:
created: 2025-05-03
description: "Understand Datomic indexes: discover their types and functions."
tags:
  - "clippings"
---
## Indexes

Any system that accumulates data and offers the ability to ask questions about that data will need an efficient way to retrieve specific information. In databases, that takes the form of indexes. Indexes afford the database access to the underlying data in a format that is optimized for read-time access. A covering index is one that contains actual data values, not just pointers to where those values can be found.

Datomic maintains four covering indexes that contain ordered sets of datoms. Each of these indexes is named based on the sort order used. E, A, and V are always sorted in ascending order, while T is always in descending order:

Datomic indexes are used behind the scenes in [Query](https://docs.datomic.com/query/query-data-reference.html), [Entity API](https://docs.datomic.com/entities.html), and [Pull API](https://docs.datomic.com/query/query-pull.html). For access patterns that aren't well suited for query, Datomic also provides [Index APIs](https://docs.datomic.com/indexes/index-apis.html) that offer the ability to retrieve data directly from indexes.

This section documents what Datomic's indexes are, how they are maintained, and how to access them.

- [Index Model](https://docs.datomic.com/indexes/index-model.html)
- [Background Indexing](https://docs.datomic.com/indexes/background-indexing.html)