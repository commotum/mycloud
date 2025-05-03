---
title: "Retract | Datomic"
source: "https://docs.datomic.com/client-tutorial/retract.html"
author:
published:
created: 2025-05-03
description: "Discover how to retract data in Datomic with this tutorial."
tags:
  - "clippings"
---
## Retract

## Explicit Retract

We would like to keep a count of items in inventory, so let's add a bit more schema:

Now we can assert that we have seven of SKU-21 and a thousand of SKU-42:

Curse my clumsy fingers, we just put some bad data into the system. We aren't supposed to have any *SKU-22*, but we just added seven. We can fix this with a retraction, which cancels the effect of an assertion:

The `:db/retract` above removes the incorrect value, but note that we are also adding an assertion about the special tempid "datomic.tx". Every transaction in Datomic is its own entity, making it easy to add fact s about why a transaction was added (or who added it, or from where the data came, etc).

## Implicit Retract

We also miskeyed the entry for SKU-42, asserting 100 instead of 1000. We can fix this by asserting the correct value. We do **not** need also to retract the old value; since `:inv/count` is`:cardinality/one`, Datomic knows that there can only be one value at a time and will automatically retract the previous value:

When we look only at the most recent database value, all we can see is the net effect after our corrections:

Knowing the present truth is a starting point, but Datomic's model of time will let us [do a lot more](https://docs.datomic.com/client-tutorial/history.html).

The set of possible attributes that can be associated with entities. Any entity can have any attribute.A complete Datomic installation, consisting of storage resources, a primary compute stack, and optional query groups.An atomic fact in the database, dissociating an [entity](https://docs.datomic.com/glossary.html#entity) from a particular [value](https://docs.datomic.com/glossary.html#value) of an [attribute](https://docs.datomic.com/glossary.html#attribute). Opposite of an [assertion](https://docs.datomic.com/glossary.html#assertion).An atomic fact in the database, associating an [entity](https://docs.datomic.com/glossary.html#entity), [attribute](https://docs.datomic.com/glossary.html#attribute), [value](https://docs.datomic.com/glossary.html#value), and a [tx](https://docs.datomic.com/glossary.html#tx). Opposite of a [retraction](https://docs.datomic.com/glossary.html#retraction).An atomic fact in the database, associating an [entity](https://docs.datomic.com/glossary.html#entity), [attribute](https://docs.datomic.com/glossary.html#attribute), [value](https://docs.datomic.com/glossary.html#value), and a [tx](https://docs.datomic.com/glossary.html#tx). Opposite of a [retraction](https://docs.datomic.com/glossary.html#retraction).An atomic unit of work in a database. All Datomic writes are transactional, fully serialized, and ACID (Atomic, Consistent, Isolated, and Durable).The first component of a [datom](https://docs.datomic.com/glossary.html#datom), specifying who or what the datom is about. Also the collection of datoms associated with a single entity, as in the Java type, Entity.See [datom](https://docs.datomic.com/glossary.html#datom).An atomic unit of work in a database. All Datomic writes are transactional, fully serialized, and ACID (Atomic, Consistent, Isolated, and Durable).