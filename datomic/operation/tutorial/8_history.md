---
title: "History | Datomic"
source: "https://docs.datomic.com/client-tutorial/history.html"
author:
published:
created: 2025-05-03
description: "Discover how to utilize the Datomic history feature. Learn to query historical data, track changes, and gain insights into your data's evolution."
tags:
  - "clippings"
---
## History

## Prerequisites

- Update your database to add some inventory:
- Make some corrections to the data:

## asOf Query

Imagine that SKU-22 requires cold storage. Pat notices the database entry showing that we have some SKU-22 in stock and turns the thermostat down to 56F. This turns out to be very unpopular with everybody who works in the building. By the time somebody else checks the database to verify Pat's finding, the data error has been fixed.

This example shows why systems of record *should never delete data, even if that data is mistaken*. Other parties may have acted on that data, and a key responsibility of data-of-record systems is to provide an audit trail in these situations.

With Datomic, you can make a database query asOf any previous point in time, where time can be specified either as an instant or as a transaction id. If you are following along in code, you probably don't remember the exact instant in time that you made the correction above–and you don't have to.

- You can query the system for the most recent transaction s:

The `max` in find limits the results to the three highest valued (most recent) transaction ids. Take the smallest of these, and use `as-of` to back up past the two "correction" transactions.

- Now you can see the data about SKU-22 that justifies Pat's unpopular decision:

## History Query

In addition to point-in-time auditing, you can also review the entire history of your data. When you query against a *history* database value, the query will return all assertion s and retraction s, regardless of when they were in effect. The following query shows the complete history of `:inv/count` data for items by SKU:

The `?op` is true for assertions and false for retractions. Note that:

- Transaction *…399* set the count for three SKUs
- Transaction *…400* retracted the count for SKU-22
- Transaction *…402* "changed" the count for SKU-42

## Deleting System (Optional)

You have finished the tutorial. If you are done with your Datomic System, you can follow the instructions for [deleting a system](https://docs.datomic.com/operation/deleting.html).

A database is a set of datoms.A database value as of a point in time. With asOf, you can reuse existing queries and rules to ask questions about points in time other than the present.Datomic's Datalog system. A query finds [values](https://docs.datomic.com/glossary.html#value) in a [database](https://docs.datomic.com/glossary.html#database) subject to the given constraints, and is specified as [edn](https://docs.datomic.com/glossary.html#edn).A complete Datomic installation, consisting of storage resources, a primary compute stack, and optional query groups.An atomic unit of work in a database. All Datomic writes are transactional, fully serialized, and ACID (Atomic, Consistent, Isolated, and Durable).Datomic's Datalog system. A query finds [values](https://docs.datomic.com/glossary.html#value) in a [database](https://docs.datomic.com/glossary.html#database) subject to the given constraints, and is specified as [edn](https://docs.datomic.com/glossary.html#edn).An atomic fact in the database, associating an [entity](https://docs.datomic.com/glossary.html#entity), [attribute](https://docs.datomic.com/glossary.html#attribute), [value](https://docs.datomic.com/glossary.html#value), and a [tx](https://docs.datomic.com/glossary.html#tx). Opposite of a [retraction](https://docs.datomic.com/glossary.html#retraction).An atomic fact in the database, dissociating an [entity](https://docs.datomic.com/glossary.html#entity) from a particular [value](https://docs.datomic.com/glossary.html#value) of an [attribute](https://docs.datomic.com/glossary.html#attribute). Opposite of an [assertion](https://docs.datomic.com/glossary.html#assertion).An atomic fact in a database, composed of entity/attribute/value/transaction/added. Pronounced like "datum", but pluralized as datoms.The set of possible attributes that can be associated with entities. Any entity can have any attribute.A declarative way to make hierarchical selections of information about entities.Datomic's Datalog system. A query finds [values](https://docs.datomic.com/glossary.html#value) in a [database](https://docs.datomic.com/glossary.html#database) subject to the given constraints, and is specified as [edn](https://docs.datomic.com/glossary.html#edn).A deductive query system, typically consisting of:  
- A database of facts
  
- A set of rules for deriving new facts from existing facts
  
- A query processor that, given some partial specification of a  
	fact or rule: finds all instances of that specification implied  
	by the database and rules, i.e. all the matching facts
  
Datomic's built-in [query](https://docs.datomic.com/glossary.html#query) is an implementation of Datalog.