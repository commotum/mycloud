---
title: "Read Revisited: More Query | Datomic"
source: "https://docs.datomic.com/client-tutorial/read-revisited.html"
author:
published:
created: 2025-05-03
description: "Learn how to run Datomic queries with parameters."
tags:
  - "clippings"
---
## Read Revisited: More Query

First, don't forget to acquire the latest value of the database,**after** the transaction that added the order.

## Parameterized Query

Now let's try a more complex query. We would like to be able to suggest additional items to shoppers. We need a query that, given any inventory item, finds all the other items that have ever appeared in the same order.

The "related items" query will have two parameters:

- A database value
- An inventory entity id

Parameters enter query via additional arguments to `q`, and they are named by a corresponding `:in` clause. The special `$` name is a placeholder for the database value.

The query below finds the SKUs for all items that have appeared in an order with SKU-25:

Notice how variables are used to join:

- `?inv` is bound on input to the entity id for *SKU-25*, which
- joins to every order `?item` mentioning `?inv`, which
- joins to every `?order` of that `?item`, which
- joins to every `?other-item` in those orders, which
- joins to every `?other-inv` inventory entity, which
- joins to all the skus `?sku`

## Rules

The "related items" feature is so nice that we would like to use it in a bunch of different queries. You can name query logic as a *rule* and reuse it in multiple queries.

- Create a rule named `ordered-together` that binds two variables `?inv`

and `?other-inv` if they have ever appeared in the same order:

- Now you can pass these *rules* to a query, using the special `:in` name `%`,

and then refer to the rules by name:

So far we have created and accumulated data. Now let's look at what happens when things [change over time](https://docs.datomic.com/client-tutorial/retract.html).

Something that does not change, e.g. 42, John, or [inst "2012-02-29". A](https://docs.datomic.com/glossary.html#inst) [datom](https://docs.datomic.com/glossary.html#datom) relates an [entity](https://docs.datomic.com/glossary.html#entity) to a value through an [attribute](https://docs.datomic.com/glossary.html#attribute).A database is a set of datoms.An atomic unit of work in a database. All Datomic writes are transactional, fully serialized, and ACID (Atomic, Consistent, Isolated, and Durable).Datomic's Datalog system. A query finds [values](https://docs.datomic.com/glossary.html#value) in a [database](https://docs.datomic.com/glossary.html#database) subject to the given constraints, and is specified as [edn](https://docs.datomic.com/glossary.html#edn).Named slots for application configuration data.An opaque identifier assigned by Datomic that uniquely identifies an entity. Entity ids are integers for efficiency, but application programs should treat them as opaque ids.