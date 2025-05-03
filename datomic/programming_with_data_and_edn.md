---
title: "Programming with Data and EDN | Datomic"
source: "https://docs.datomic.com/reference/edn.html"
author:
published:
created: 2025-05-03
description: "Understand EDN (Extensible Data Notation) in Datomic. Learn its syntax and usage for efficient data representation and interchange."
tags:
  - "clippings"
---
## Programming with Data and EDN

Datomic is designed to be directly programmable using data. That means your application's code can use ordinary data structures to communicate with Datomic. [Extensible Data Notation](https://github.com/edn-format/edn) (EDN) is a way of representing these data structures as text. Example transaction s, queries, query results, and sample data throughout this Developer Guide are presented in EDN. You can also construct the necessary data structures programmatically using any of the languages supported by Datomic.

This section explains how to read EDN notation and how to use data structures to program with Datomic. Even if you don't use EDN in your application's code, you'll want to be able to read EDN so that you can understand the examples in this Developer Guide.

## Quickstart Video

A 70 second overview of EDN can be found at the [EDN Live Tutorial](https://docs.datomic.com/livetutorial/edntutorial.html).

A video is available [on Youtube](https://youtu.be/5eKgRcvEJxU) as well.

## Datomic Data Types

The sections below summarize the data types used by Datomic, and explain the EDN notation used to represent each type.

Following EDN convention, the examples in this Developer Guide use whitespace instead of commas to separate elements in collections. You may use commas to separate elements in collections if you wish; however, they will be ignored by the reader. EDN treats commas as whitespace unless they appear inside a string.

For more detailed information, refer to the [EDN specification](https://github.com/edn-format/edn).

### Scalar Data Types for Numbers

Datomic uses the following data types to store numbers:

- **long** - A fixed, signed integer in [Two's complement](https://en.wikipedia.org/wiki/Two%2527s_complement) binary representation. Has the same semantics as a Java `long`.
- **bigint** - An arbitrary precision signed integer. Same as [`java.math.BigInteger`](https://docs.oracle.com/javase/7/docs/api/java/math/BigInteger.html) on Java platforms.
- **double** - A double-precision 64-bit IEEE 754 floating point number. Corresponds to a Java `double`.
- **float** - A single-precision 32-bit IEEE 754 floating point number. Corresponds to a Java `float`.
- **bigdec** - A floating point number with arbitrary and exact precision. Corresponds to [`java.math.BigDecimal`](https://docs.oracle.com/javase/7/docs/api/java/math/BigDecimal.html).

| Data Type | Precision | EDN Notation | Example |
| --- | --- | --- | --- |
| long | 64-bit (signed integer) | the digits 0-9, optional plus sign (+) or a minus sign (-) prefix | `42`, `+42`, `-42`, `0` |
| bigint | arbitrary (signed integer) | same as *long* with a mandatory *N* suffix | `42N`, `+42N`, `-42N`, `0N` |
| double | 64-bit, double | the digits 0-9 with a decimal point (.), optional plus sign (+) or a minus sign (-) prefix | `3.14`, `-3.14` |
| float | 32-bit, single | same as *double* | `3.13`, `-3.14` |
| bigdec | arbitrary and exact | same as double with a mandatory *M* suffix | `3.14M`, `-3.14M` |

### Other Scalar Data Types

Datomic uses the following non-numeric scalar data types (syntax indicated in table below):

- **string** - a string.
- **character** - a single character.
- **boolean** - a boolean.
- **instant** - An instant in time (not a date).
- **uuid** - A universally unique identifier. Corresponds to `java.util.UUID`.
- **symbol** - Symbols are used to represent identifiers, similar to programming language keyword s and variable names. Symbols may include an optional namespace in the form `namespace/name`.
- **keyword** - Keywords are identifiers that typically designate themselves, similar to programming language enumerations. Keywords follow the rules of symbols, except they must begin with a colon (:). May include an optional namespace in the form`:namespace/name`.

Having dedicated non-string types for symbols and keywords makes EDN especially suitable for DSLs while retaining its all-data nature, and that is leveraged by Datomic for query and transaction syntax.

| Data Type | EDN Notation | Example |
| --- | --- | --- |
| string | enclosed in double quotes ("") | `"this is a string"` |
| character | preceded by a backslash (\\) | `\f`, `\tab`, `\return`, `\u001B` |
| boolean | true, false | `true`, `false` |
| instant | *#inst* followed by a string in RFC-3339 format | `#inst "1985-04-12T23:20:50.52Z"` |
| UUID | *#uuid* followed by a string in canonical UUID format | `#uuid "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"` |
| symbol | Begins with a non-numeric character other than a colon (:) or a hash sign (#). Check [EDN specification](https://github.com/edn-format/edn) for symbol chars | `?c`, `my-query-rules` |
| keyword | Begins with a colon (:). Check [EDN specification](https://github.com/edn-format/edn) for keyword chars. | `:find`, `:where`, `:db/id`, `:db/doc`, `:namespace/foo` |

### Collection Data Types

Datomic uses the following data types for multi-valued collections:

- **list** - A list is a sequence of values. Lists are represented by zero or more elements enclosed in parentheses (). Lists may contain heterogeneous elements and scalar or nested values. The use of lists instead of vectors in Datomic syntax is optional, and is often done just to distinguish different constructs.
- **vector** - A vector is a sequence of values. Vectors are represented by zero or more elements enclosed in square brackets \[\]. Vectors may contain heterogeneous elements, and simple or nested values.
- **map** - A map is a collection of associations between keys and values. Maps are represented by a set of zero or more key/value pairs, entirely enclosed in curly braces {}. Keys and values can be elements of any type. Maps may contain heterogeneous elements, and simple or nested values.

| Datomic Data Type | EDN Notation | Example in EDN |
| --- | --- | --- |
| list | enclosed in parentheses () | `(1 2 3)`, `(a b 42)` |
| vector | enclosed in square brackets \[\] | `[1 2 3]`, `[a b 42]` |
| map | enclosed in curly braces {} | `{:a 100 :b 90}`, `{:a 1, "foo" :bar, [1 2 3] four}` |

## Query EDN Example

Below is an example of a query shown in EDN. This query finds the IDs of all entities with a `:community/name` attribute whose value is "belltown".

In the example above:

- `:find` and `:where` are keyword s denoting programmatic clauses in the query.
- `?c` is a symbol denoting a logic variable.
- `:community/name` is a namespace d keyword, used as a constant in the query, and denoting the ident <att-ref-ident> of a particular schema attribute.
- "belltown" is a string, used as a constant in the query, and denoting the desired value of the `:community/name` attribute.
- the entire query is a vector containing a nested vector.

See [the query reference](https://docs.datomic.com/query/query-data-reference.html) for more information about query syntax.

## Transaction EDN Example

Below is an example of a transaction written in EDN notation. This transaction creates a new entity with two attributes: `:person/name` and`:person/email`.

In the transaction above:

- `:person/name` and `:person/email` are namespace d keyword s denoting the ident s <att-ref-ident> of attributes the new entity will possess.
- "Anna" is a string denoting the the value of the `:person/name` attribute.
- "anna@example.com" is string denoting the value of the `:person/email` attribute.
- the entire transaction is a vector containing a nested map.

Check [transaction structure](https://docs.datomic.com/transactions/transaction-data-reference.html) for more information about how transactions are structured.

An atomic unit of work in a database. All Datomic writes are transactional, fully serialized, and ACID (Atomic, Consistent, Isolated, and Durable).Data type representing a name, e.g.:email or (with namespace):customer/email.Prefix portion of a [keyword](https://docs.datomic.com/glossary.html#keyword) used to make the keyword globally unique. Namespaces serve a similar function to table names in a relational store, without imposing any obligations or limitations, e.g. an entity can have attributes from more than one namespace.Datomic's Datalog system. A query finds [values](https://docs.datomic.com/glossary.html#value) in a [database](https://docs.datomic.com/glossary.html#database) subject to the given constraints, and is specified as [edn](https://docs.datomic.com/glossary.html#edn).An atomic unit of work in a database. All Datomic writes are transactional, fully serialized, and ACID (Atomic, Consistent, Isolated, and Durable).Datomic's Datalog system. A query finds [values](https://docs.datomic.com/glossary.html#value) in a [database](https://docs.datomic.com/glossary.html#database) subject to the given constraints, and is specified as [edn](https://docs.datomic.com/glossary.html#edn).Something that can be said about an [entity](https://docs.datomic.com/glossary.html#entity). An attribute has a name, e.g.:person/first-name, and a value type, e.g.:db.type/long, and a cardinality.Something that does not change, e.g. 42, John, or [inst "2012-02-29". A](https://docs.datomic.com/glossary.html#inst) [datom](https://docs.datomic.com/glossary.html#datom) relates an [entity](https://docs.datomic.com/glossary.html#entity) to a value through an [attribute](https://docs.datomic.com/glossary.html#attribute).Data type representing a name, e.g.:email or (with namespace):customer/email.Prefix portion of a [keyword](https://docs.datomic.com/glossary.html#keyword) used to make the keyword globally unique. Namespaces serve a similar function to table names in a relational store, without imposing any obligations or limitations, e.g. an entity can have attributes from more than one namespace.Data type representing a name, e.g.:email or (with namespace):customer/email.A value of type:db/ident that uniquely identifies an [entity](https://docs.datomic.com/glossary.html#entity).An atomic unit of work in a database. All Datomic writes are transactional, fully serialized, and ACID (Atomic, Consistent, Isolated, and Durable).The first component of a [datom](https://docs.datomic.com/glossary.html#datom), specifying who or what the datom is about. Also the collection of datoms associated with a single entity, as in the Java type, Entity.Prefix portion of a [keyword](https://docs.datomic.com/glossary.html#keyword) used to make the keyword globally unique. Namespaces serve a similar function to table names in a relational store, without imposing any obligations or limitations, e.g. an entity can have attributes from more than one namespace.Data type representing a name, e.g.:email or (with namespace):customer/email.A value of type:db/ident that uniquely identifies an [entity](https://docs.datomic.com/glossary.html#entity).