---
title: "Background Indexing | Datomic"
source: "https://docs.datomic.com/indexes/background-indexing.html"
author:
published:
created: 2025-05-03
description: "Understand background indexing in Datomic with our guide. Learn how it works, its benefits, and how to optimize indexing performance."
tags:
  - "clippings"
---
## Background Indexing

## Rationale

Datomic maintains multiple sorted indexes of datoms. For the most part, users do not have to request, specify, or otherwise think about these indexes. Rather, the indexes are automatically available at all times and are used implicitly to enforce transactional invariants and to perform Datalog queries and pulls. The job of background indexing in Datomic is to build and maintain these indexes.

## The Job

Naively, one could sort the entire database on every transaction. To avoid this, Datomic maintains multiple sort tiers and merges them to produce a sorted view of the entire database. The smallest tier is called the memory index. The memory index must be very fast for two reasons: First, it incorporates every new datom on every transaction. Second, the memory index must be rebuilt from scratch from the log every time a process loads a database.

The memory index is maintained in every process and cannot grow forever. Every so often, Datomic will perform a background indexing job. This job will empty the memory index, merging those datoms into durable index tiers – trees of segments with a wide (~1000) branching factor and with leaf segments typically containing a few thousand datoms each. Datomic adapts each index job to the data to reduce the number of segments that must be rewritten, so that index job times are sublinear in total database size. If background indexing cannot keep up with the growth of the memory index, Datomic will radically slow transaction processing until indexing can catch up, becoming effectively unavailable for writes.

Background indexing jobs are both CPU and I/O intensive. CPU is used to merge tiers of datoms and to serialize and deserialize segments. I/O is needed to both read the current index segments and to write the new ones. The CPU and I/O activities of indexing can be (and are) parallelized. Indexing could also be distributed across machines, but as of this writing (July 2024) this is not the case. In Datomic Pro, indexing is performed by the transactor. The situation in Datomic Cloud is better, in that indexing is performed by a cluster node that is *not* the same as the transacting node for a database.

## Implications

When deploying Datomic, you normally want to allocate sufficient CPU and I/O resources so that indexing can keep up with transaction load. In Datomic Pro, there are many knobs for fine-tuning this. In Datomic Cloud, there is basically a single knob: EC2 instance size.

While there is no one-size-fits-all advice, here are a couple of anecdotes:

1. One of our earliest tests of Datomic was an import of the full mbrainz dataset. This import adds about 100 million (10 <sup>8</sup>) datoms. A vanilla developer laptop has plenty of CPU and I/O to import this dataset, using Datomic Pro’s default settings.
2. Amazon’s DynamoDB has a free tier that offers 25 write capacity units, i.e. about 25 kilobytes/second. This is *thousands of times* less write capacity than a single laptop hard drive. There is no way that such a tier can keep up with, well, much of anything. Many a developer has been burned by moving a prototype into production without increasing this setting. In Datomic this usually manifests as indexing falling behind as it is unable to write segments to DynamoDB fast enough.

## When Sublinear Isn't

There are three situations where Datomic indexing times can fail to be sublinear in database size. All of these situations impact Datomic Pro only. (This is not a coincidence, and partially explains why we left these features out of Datomic Cloud!)

1. Excision targets datoms matching some predicate, and indexing must then remove such datoms *regardless of which tier or segment they live in*. This defeats Datomic’s indexing optimizations and is (almost by definition) potentially linear in the size of the database.
2. Adding an AVET index requires sorting all the extant values for that attribute.
3. When using fulltext search, Lucene’s indexing is not sublinear in database size, as it must [occasionally perform large merges](https://blog.mikemccandless.com/2011/02/visualizing-lucenes-segment-merges.html).

## Footnotes:

<sup><a href="https://docs.datomic.com/indexes/#fnr.1" role="doc-backlink">1</a></sup>

But hey, it is free!