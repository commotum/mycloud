---
title: "Accumulate | Datomic"
source: "https://docs.datomic.com/client-tutorial/accumulate.html"
author:
published:
created: 2025-05-03
description: "Learn how to use Datomic's accumulate function in this Client tutorial."
tags:
  - "clippings"
---
## Accumulate

## More Schema

Our stakeholders have a new request. Now it isn't just an inventory database, it also needs to track orders:

- An order is a collection of line items
- Each line item has a count and references an item in the inventory

We can model this directly in Datomic schema without translation:

Note that:

- `:db.cardinality/many` allows a single order to have multiple `:order/items`
- `:db/isComponent` `true` tells Datomic that order items belong to an order

## More Data

Now let's add a sample order:

In this example a **nested** entity map is displayed. The top level is the order, which has multiple `:order/items` nested within.

With this data in hand, let's explore some [more features of query](https://docs.datomic.com/client-tutorial/read-revisited.html).

The set of possible attributes that can be associated with entities. Any entity can have any attribute.The first component of a [datom](https://docs.datomic.com/glossary.html#datom), specifying who or what the datom is about. Also the collection of datoms associated with a single entity, as in the Java type, Entity.