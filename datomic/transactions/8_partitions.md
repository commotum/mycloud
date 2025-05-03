---
title: "Partitions | Datomic"
source: "https://docs.datomic.com/transactions/partitions.html"
author:
published:
created: 2025-05-03
description: "Learn about partition assingment, sharding and implicit and named partitions in Datomic."
tags:
  - "clippings"
---
## Partitions

## Partitions

Every Datomic entity is associated with a particular partition. These partitions act as a coarse-grained grouping mechanism for entities, much as file cabinets act as a coarse-grained grouping mechanism for paper files.

The partition is encoded via high bits in the entity ID. Therefore, entities in the same partition are sorted together in Datomic's two E-leading indexes, EAVT and AEVT. If the partitions align with usage patterns, this can improve performance. For example, consider a system with inventory, customers, and order partitions. A query for a particular item in inventory causes an "inventory" segment to be cached, and that segment contains a few thousand other inventory-related facts. If inventory queries tend to be followed by other inventory queries, this locality reduces the number of segments that a peer needs to cache. Conversely, if your application tends to access information about individual customers, it would be advantageous to put all of each particular customer's data in one partition and spread out your customers across thousands of [implicit partitions](https://docs.datomic.com/transactions/partitions.html#implicit-partitions).

Datomic supports two types of partitions: implicit partitions and named partitions. Both can be used in the same database.

Partitions enable two techniques that are handy in larger systems: partition sharding and new entity scans.

Partitions are strictly a locality optimization. You can ignore partitions completely; if you do, all your domain entities will be in the same (default) partition.

## Implicit Partitions

Implicit partitions are currently available only in Datomic Pro Edition.

To facilitate entity grouping when using a multitude of partitions, each Datomic database includes 524288 implicit partitions, which can be accessed by calling *implicit-part*. Unlike named partitions, implicit partitions require no transaction to create. Like named partitions, each implicit partition corresponds to an entity ID.

Applications can employ algorithmic schemes to group related entities to the same partition. For example, an order processing system could assign a customer to an implicit partition (e.g. via hashing), and then put all of a customer's order and line item entities in that partition. This would improve locality of reference when querying for a customer's orders.

## Named Partitions

Named partitions are useful when your domain has a modest number of named categories for which you would like to have locality. In addition, named partitions are used internally by Datomic. Every Datomic database comes with three named partitions:

| Partition | Purpose |
| --- | --- |
| :db.part/db | System partition, used for schema |
| :db.part/tx | Transaction partition |
| :db.part/user | User partition, for application entities |

Schema entities are automatically placed in the *:db.part/db* partition.

[Transaction entities](https://docs.datomic.com/transactions/transaction-data-reference.html#reified-txes) are automatically placed in the *:db.part/tx* partition.

### Default Partition

The *:db.part/user partition* is the default partition for entities whenever a partition is not otherwise specified. In Datomic Pro, you can override this default by setting *default-partition* in the transactor properties file:

### Installing Named Partitions

To install a new named partition, transact an entity with an ident and reference that new entity as a *db.install/partition* value of the system entity *db.part/db*.

For example, the transaction data specifies a partition named*:communities*:

## Partition Assignment

Partition assignment is currently available only in Datomic Pro Edition.

To control partition assignment for tempids, entity maps can include the *:db/force-partition* or *:db/match-partition* directives. These directives allow you to request partition assignment for any new entity id created by a transaction.

Because partition directives are separate maps, they encourage keeping partition policy separate from entity data, and make it easier to write supporting code that manages partitions across many transactions.

### :db/force-partition

The value of *:db/force-partition* is a map from tempids to desired partitions. Named partitions are specified by a keyword, such as *:orders* below:

Implicit partitions are specified by entity id, found by calling `db.part` or [implicit-part](https://docs.datomic.com/transactions/partitions.html#implicit-partitions). The example below transacts "customer" and "order" into implicit partition `343`:

### :db/match-partition

Sometimes it is more convenient to request a partition via an entity in the same partition, rather than the partition id. The value of:db/match-partition is a map from tempids to *entities* in desired partitions.

The following example transacts line items into the same partition (implicit part 500) as their containing order:

## Partition Sharding

Partition-based sharding is a technique for distributing entity-scoped read load to application servers. When dividing entities mechanically into N different groups at creation time, grouping together entities that are likely to be accessed together, it is possible to assign each group a different partition in Datomic. Then, at query time, direct entity-related queries to different application servers based on their partition. This causes the application servers to cache disjoint subsets of the total index, substantially increasing the fraction of the index that can fit into application server memory.

Partition-based sharding is an optimization only. Entities in any partition can still be reached by any peer.

## New Entity Scans

Because Datomic stores information about time, it is easy to ask questions that apply only to recently created entities. For example, it is trivial in Datomic to run a batch job over everything that changed today, by grabbing the *txRange* of the [log](https://docs.datomic.com/reference/log.html) starting at midnight.

Such a scan does, however, have to consider *all* of today's datoms, filtering out any that are irrelevant to the task at hand.

It is possible to use partitions as a filtering mechanism when designing a system that needs to know about specific new entities (something that wants to respond to new events of a certain type, for example, using the Peer API):

- Assign all the datoms for an event category to the same partition.
- Instead of using the log, use [entid-at](https://docs.datomic.com/clojure/index.html#datomic.api/entid-at) to fabricate an event id closest to the chosen start time t.
- Pass the fabricated entity id to [seek-datoms](https://docs.datomic.com/clojure/index.html#datomic.api/seek-datoms) to walk EAVT, walking entities ordered by time of creation and implicitly "filtered" by partition's impact on order.

## Partitions in Tempids (Obsolete)

Tempid partitions are obsolete but will continue to be supported. For new applications, use [db/force-partition and db/match-partition](https://docs.datomic.com/transactions/#partition-assignment) to assign partitions.

Datomic supports partition assignment inside tempids. Rather than tempid strings, you can create tempids as a special data structure, with a slot for specifying the desired partition.

To assign a partition to a tempid, create a structural tempid by calling [d/tempid](https://docs.datomic.com/clojure/index.html#datomic.api/tempid), passing the partition:

Each call to *tempid* produces a unique temporary id. If you want two call to *tempid* to produce the same id, pass a negative number in the range -1.. -100000 as a second argument. All calls to *tempid* with the same second argument will return the same id.

Datomic also supports a tempid [tagged literal](https://clojure.org/reference/reader#tagged_literals):