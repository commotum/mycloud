---
title: "Read | Datomic"
source: "https://docs.datomic.com/client-tutorial/read.html"
author:
published:
created: 2025-05-03
description: "Learn how to read data using Datomic Client API."
tags:
  - "clippings"
---
## Read

## Database Values

Datomic maintains the entire history of your data. From this, you can query against a database value as of a particular point in time.

The *db* API returns the latest database value from a connection.

An analogy with source control is helpful here. A Datomic connection references the entire history of your data, analogous to a source code repository. A database value from *db* is analogous to a checkout.

## Pull

If you know an entity id, you can use the [pull API](https://docs.datomic.com/query/query-pull.html) to return information about that entity and related entities. Better still, if the entity has a unique attribute, you do not even need to know its entity id. A [lookup ref](https://docs.datomic.com/whatis/data-model.html#lookup-refs) is a two-element list of unique attribute + value that uniquely identifies an entity, e.g.

The following call pull s the color, type, and size for *SKU-42*:

Note that the arguments and return value of pull are both just ordinary data structures, i.e. lists and maps.

### Database as a Value

[Previously when data was transacted](https://docs.datomic.com/client-tutorial/assertion.html#sample-data) the result was stored in `sample-data-transaction`.

`(:db-before sample-data-transaction)` gets the database value before the transaction.

Attempting to pull against the database *before* the transaction shows that the data does not exist in the `db`.

Pulling against the db value in `(:db-after sample-data-transaction)` will pull against a `db` with the data transacted [previously in the tutorial](https://docs.datomic.com/client-tutorial/assertion.html#sample-data).

## Query

Storing and retrieving data by unique id is useful, but a database needs also to provide declarative, logic-based query. Datomic uses [datalog](https://docs.datomic.com/whatis/data-model.html#datalog) with negation, which has expressive power similar to SQL + recursion.

The following query finds the skus of all products that share a color with *SKU-42*:

Note that the arguments and return value of `q` are both just ordinary data structures, i.e. lists and maps.

In the `:where` clauses, each list further constrains the results. For each list:

- The first element matches the entity id
- The second element matches an attribute
- The third element matches an attribute 's value

Symbols beginning with a question mark are Datalog *variables*. When the same symbol occurs more than once, it causes a join. In the query above

- `?e` joins *SKU-42* to its color
- `?e2` joins to all entities sharing the color
- `?sku` retrieves the SKU for every `?e2`

Now we are confident that we can get basic inventory in and out. Just in time, too, because our stakeholders are back with [more feature requests](https://docs.datomic.com/client-tutorial/accumulate.html).

Datomic's Datalog system. A query finds [values](https://docs.datomic.com/glossary.html#value) in a [database](https://docs.datomic.com/glossary.html#database) subject to the given constraints, and is specified as [edn](https://docs.datomic.com/glossary.html#edn).A database is a set of datoms.Something that does not change, e.g. 42, John, or [inst "2012-02-29". A](https://docs.datomic.com/glossary.html#inst) [datom](https://docs.datomic.com/glossary.html#datom) relates an [entity](https://docs.datomic.com/glossary.html#entity) to a value through an [attribute](https://docs.datomic.com/glossary.html#attribute).Client object that provides access to a database. Programs can use a connection to submit transactions.An opaque identifier assigned by Datomic that uniquely identifies an entity. Entity ids are integers for efficiency, but application programs should treat them as opaque ids.The first component of a [datom](https://docs.datomic.com/glossary.html#datom), specifying who or what the datom is about. Also the collection of datoms associated with a single entity, as in the Java type, Entity.Something that can be said about an [entity](https://docs.datomic.com/glossary.html#entity). An attribute has a name, e.g.:person/first-name, and a value type, e.g.:db.type/long, and a cardinality.A declarative way to make hierarchical selections of information about entities.An opaque identifier assigned by Datomic that uniquely identifies an entity. Entity ids are integers for efficiency, but application programs should treat them as opaque ids.Something that can be said about an [entity](https://docs.datomic.com/glossary.html#entity). An attribute has a name, e.g.:person/first-name, and a value type, e.g.:db.type/long, and a cardinality.Something that can be said about an [entity](https://docs.datomic.com/glossary.html#entity). An attribute has a name, e.g.:person/first-name, and a value type, e.g.:db.type/long, and a cardinality.Something that does not change, e.g. 42, John, or [inst "2012-02-29". A](https://docs.datomic.com/glossary.html#inst) [datom](https://docs.datomic.com/glossary.html#datom) relates an [entity](https://docs.datomic.com/glossary.html#entity) to a value through an [attribute](https://docs.datomic.com/glossary.html#attribute).A deductive query system, typically consisting of:  
- A database of facts
  
- A set of rules for deriving new facts from existing facts
  
- A query processor that, given some partial specification of a  
	fact or rule: finds all instances of that specification implied  
	by the database and rules, i.e. all the matching facts
  
Datomic's built-in [query](https://docs.datomic.com/glossary.html#query) is an implementation of Datalog.Datomic's Datalog system. A query finds [values](https://docs.datomic.com/glossary.html#value) in a [database](https://docs.datomic.com/glossary.html#database) subject to the given constraints, and is specified as [edn](https://docs.datomic.com/glossary.html#edn).