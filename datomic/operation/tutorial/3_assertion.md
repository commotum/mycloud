---
title: "Assertion | Datomic"
source: "https://docs.datomic.com/client-tutorial/assertion.html"
author:
published:
created: 2025-05-03
description: "Learn how to create assertions in Datomic using the Client API. Follow this tutorial for step-by-step guidance on adding facts to your database."
tags:
  - "clippings"
---
## Assertion

## Create and Connect

An assertion requires a database to exist and a connection.

- Utilize a configuration map as described [in the client API tutorial](https://docs.datomic.com/client-tutorial/client.html#create-client):
- Create a new database with [`create-database`](https://docs.datomic.com/client-api/datomic.client.api.html#var-create-database):
- Acquire a connection to the database with [`connect`](https://docs.datomic.com/client-api/datomic.client.api.html#var-connect):

## List and Map Forms

An assertion adds a single atomic fact to Datomic. Assertions are represented by ordinary data structures (lists or maps). Our inventory database will need to have enumerated types for various product attributes such as color.

- Let's start with an [edn](https://github.com/edn-format/edn) list that asserts the color green:
- `:db/add` specifies that this is an assertion
- "Foo" is a temporary entity id for the new entity
- `:db/ident` is an *attribute* used for programmatic identifiers
- `:green` is the datom's *value*
- The same datom can be represented by a map:

Maps imply (and are equivalent to) a set of assertion s, all about the same entity.

## Transactions

Datomic databases are updated via [ACID](https://docs.datomic.com/transactions/acid.html) transactions, which add a set of datom s to the database. Execute the code below at a [Clojure REPL](https://clojure.org/guides/repl/introduction) to add colors to the inventory database in a single transaction.

The transaction below adds four colors to the database:

A successful transaction returns a map with information about the transaction and the state of the database. It will be explored later.

## Programming with Data

In addition to colors, our inventory database will also track sizes and types of items. Since we are programming with data, it is easy to write a helper function to make these transactions more concise.

- The `make-idents` function shown below will take a collection of keywords, and return transaction-ready maps:
- You can quickly notice that this works by trying it out at the REPL:

Note that because `make-idents` function takes and returns pure data, no database is necessary to develop and test this function.

The `#:db` before the map indicates a [namespaced map](https://clojure.org/guides/weird_characters#_and_namespace_map_syntax).

- Let's put types, colors, and sizes into the database and define a collection of colors we already added:

## Schema

So far we have used only built-in schema such as `:db/ident`. Now we want to add some inventory-specific attribute s:

- *sku*, a unique string identifier for a particular product
- *color*, a reference to a color entity
- *size*, a reference to a size entity
- *type*, a reference to a type entity

In Datomic, schema are entities just like program data. A schema entity must include:

- [:db/ident](https://docs.datomic.com/schema/schema-reference.html#db-ident), a programmatic name
- [:db/valueType](https://docs.datomic.com/schema/schema-reference.html#db-valuetype), a reference to an entity that specifies what type the attribute allows
- [:db/cardinality](https://docs.datomic.com/schema/schema-reference.html#db-cardinality), a reference to an entity that specifies whether a particular entity can possess more than one value for the attribute at a given time.

So we can add our schema like this:

Notice that the `:inv/sku` attribute also has a `:db/unique` value. This specifies that every `:inv/sku` must be unique within the database.

## Sample Data

Now let's make some sample data. Again, no special API is necessary, we can just use ordinary Clojure collections. The following expression creates one example inventory entry for each combination of color, size, and type:

Now that we have asserted some data, let's look at some different ways we can [retrieve it](https://docs.datomic.com/client-tutorial/read.html).

An atomic fact in the database, associating an [entity](https://docs.datomic.com/glossary.html#entity), [attribute](https://docs.datomic.com/glossary.html#attribute), [value](https://docs.datomic.com/glossary.html#value), and a [tx](https://docs.datomic.com/glossary.html#tx). Opposite of a [retraction](https://docs.datomic.com/glossary.html#retraction).A database is a set of datoms.Client object that provides access to a database. Programs can use a connection to submit transactions.Client object that provides access to a database. Programs can use a connection to submit transactions.A database is a set of datoms.An atomic fact in the database, associating an [entity](https://docs.datomic.com/glossary.html#entity), [attribute](https://docs.datomic.com/glossary.html#attribute), [value](https://docs.datomic.com/glossary.html#value), and a [tx](https://docs.datomic.com/glossary.html#tx). Opposite of a [retraction](https://docs.datomic.com/glossary.html#retraction).See [datom](https://docs.datomic.com/glossary.html#datom).An opaque identifier assigned by Datomic that uniquely identifies an entity. Entity ids are integers for efficiency, but application programs should treat them as opaque ids.The first component of a [datom](https://docs.datomic.com/glossary.html#datom), specifying who or what the datom is about. Also the collection of datoms associated with a single entity, as in the Java type, Entity.An atomic fact in the database, associating an [entity](https://docs.datomic.com/glossary.html#entity), [attribute](https://docs.datomic.com/glossary.html#attribute), [value](https://docs.datomic.com/glossary.html#value), and a [tx](https://docs.datomic.com/glossary.html#tx). Opposite of a [retraction](https://docs.datomic.com/glossary.html#retraction).The first component of a [datom](https://docs.datomic.com/glossary.html#datom), specifying who or what the datom is about. Also the collection of datoms associated with a single entity, as in the Java type, Entity.An atomic fact in a database, composed of entity/attribute/value/transaction/added. Pronounced like "datum", but pluralized as datoms.The set of possible attributes that can be associated with entities. Any entity can have any attribute.Something that can be said about an [entity](https://docs.datomic.com/glossary.html#entity). An attribute has a name, e.g.:person/first-name, and a value type, e.g.:db.type/long, and a cardinality.