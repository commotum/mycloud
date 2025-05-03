---
title: "Schema Data Reference | Datomic"
source: "https://docs.datomic.com/schema/schema-reference.html"
author:
published:
created: 2025-05-03
description: "Check this reference guide for Datomic schema elements to define and understand database structure."
tags:
  - "clippings"
---
## Schema Data Reference

This document defines the grammar for schema data.

## Schema Grammar

### Syntax Used in Grammar

```
'' literal
"" string
[] = list or vector
{} = map {k1 v1 ...}
() grouping
| choice
? zero or one
+ one or more
```

### Schema Map Grammar

```
attr-def    = {':db/ident' keyword
               ':db/cardinality' cardinality
               ':db/valueType' type
               (':db/doc' string)?
               (':db/unique' unique)?
               (':db/isComponent' boolean)?
               (':db/id' tx-entid)?
               (':db/noHistory' boolean)?
               (':db.attr/preds' attr-pred+)?
               (':db.entity/attrs' ident+)?
               (':db.entity/preds' ent-pred+)?}
tx-entid    = (identifier | tempid)
tempid      = string
identifier  = (eid | lookup-ref | ident)
eid         = nat-int
lookup-ref  = [identifier value]
ident       = keyword
attr-pred   = qualified symbol naming a /predicate/ of a value
ent-pred    = qualified symbol naming a /predicate/ of db-after and an eid
cardinality = (':db.cardinality/one' | ':db.cardinality/many')
type        = (':db.type/bigdec'  | ':db.type/bigint'  | ':db.type/boolean' |
               ':db.type/bytes'   | ':db.type/double'  | ':db.type/float'   |
               ':db.type/instant' | ':db.type/keyword' | ':db.type/long'    |
               ':db.type/ref'     | ':db.type/string'  | ':db.type/symbol'  |
               ':db.type/tuple'   | ':db.type/uuid'    | ':db.type/uri')
unique      = (':db.unique/identity' | ':db.unique/value')
boolean     = ('true' | 'false')
```

### Grammar Notes

The grammar above shows only the attributes that are built-in to Datomic schema. Just like all other entities in Datomic, schema entities are open and can have any attributes you define added to them.

The grammar shows only the transaction [map form](https://docs.datomic.com/transactions/transaction-data-reference.html#map-forms). It is also possible to define schema with the more verbose transaction [list form](https://docs.datomic.com/transactions/transaction-data-reference.html#list-forms), as these forms are semantically equivalent.

Because schema is composed of ordinary Datomic data, the schema grammar is a specialization of the [transaction grammar](https://docs.datomic.com/transactions/transaction-data-reference.html#grammar). The shared grammar elements `tx-entid`, `identifier`, `eid`,`lookup-ref`, and `ident` are documented there.

## Defining Schema

Attributes are defined using the same data model used for application data. That is, attributes are themselves defined by entities with associated attributes and are added to the database using [`d/transact`](https://docs.datomic.com/clojure/index.html#datomic.api/transact).

| Name | Purpose | Required? |
| --- | --- | --- |
| `:db/ident` | specifies a unique programmatic name for an entity (normally a schema entity) | [Required](https://docs.datomic.com/schema/schema-reference.html#db-ident) for schema entities |
| `:db/cardinality` | specifies whether an attribute associates a single value or a set of values | [Required](https://docs.datomic.com/schema/schema-reference.html#db-cardinality) |
| `:db/valueType` | specifies the type of value that can be associated with an attribute | [Required](https://docs.datomic.com/schema/schema-reference.html#db-valuetype) |
| `:db/unique` | specifies a uniqueness constraint for the values of an attribute | [Optional](https://docs.datomic.com/schema/schema-reference.html#db-unique) |
| `:db/index` | specifies a boolean value indicating that an index should be generated for this attribute. Defaults to false. | Optional |
| `:db/isComponent` | specifies whether an attribute is a ref to a component entity | [Optional](https://docs.datomic.com/schema/schema-reference.html#db-iscomponent) |
| `:db/noHistory` | specifies whether historical values should be forgotten for an attribute | [Optional](https://docs.datomic.com/schema/schema-reference.html#db-nohistory) |
| `:db/doc` | specifies a documentation string for an attribute | [Optional](https://docs.datomic.com/schema/schema-reference.html#db-doc) |
| `:db.attr/preds` | specifies one or more predicates that constrain an attribute's value by more than just its value type | [Optional](https://docs.datomic.com/schema/schema-reference.html#attribute-predicates) |

The example [map form](https://docs.datomic.com/transactions/transaction-data-reference.html#map-forms) below shows an attribute that represents a person's name:

## :db/cardinality

```
{':db/cardinality' cardinality}
cardinality = (':db.cardinality/one' | ':db.cardinality/many')
```

The required `:db/cardinality` attribute specifies whether an attribute associates a single value or a set of values with an entity. It has no default value.

The values allowed for `:db/cardinality` are:

- `:db.cardinality/one` – the attribute is single-valued, it associates a single value with an entity.
- `:db.cardinality/many` – the attribute is multi-valued, it associates a set of values with an entity.

## :db/doc

```
':db/doc' = string
```

The optional `:db/doc` specifies a documentation string, and can be any string value.

## :db/id

```
{':db/id' tx-entid}
tx-entid       = (identifier | tempid)
identifier     = (eid | lookup-ref | ident)
eid            = nat-int
lookup-ref     = [identifier value]
ident          = keyword
```

`:db/id` is not an attribute; rather, it is syntactic sugar for specifying the [entity identifier](https://docs.datomic.com/transactions/transaction-data-reference.html#entity-identifiers) in a map form. For example, the following two forms are equivalent:

## :db/ident

```
{':db/ident' keyword}
```

The `:db/ident` attribute specifies a unique programmatic name for an entity. Idents are required for schema entities and are optional for all other entities.

Idents should be used for two purposes: to name schema entities and to represent enumerated values. To support these usages, idents are designed to be extremely fast and always available. All idents associated with a database are stored in memory in every Datomic compute node.

When an entity has an ident, you can use that ident in place of the eid, e.g.

These characteristics also imply situations where idents should *not* be used:

- Idents should not be used as unique names or ids on ordinary domain entities. Such entity names should be implemented with a domain-specific attribute that is a unique identity.
- Idents should not be used as names for test data. Your real data will not have such names, and you don't want test data to behave differently than the real data it simulates.

Idents can be used instead of entity ids in the following API calls:

- As the sole argument to [`d/entity`](https://docs.datomic.com/clojure/index.html#datomic.api/entity)
- In the E, A, and V positions of assertions and retractions passed to [`d/transact`](https://docs.datomic.com/clojure/index.html#datomic.api/transact) and [`d/with`](https://docs.datomic.com/clojure/index.html#datomic.api/with)
- In the E, A, and V positions of a [where clause](https://docs.datomic.com/query/query-data-reference.html#where-clauses) in a query

### Allowable Values

The allowable value of `:db/ident` is a [Clojure keyword](https://clojure.org/reference/data_structures#Keywords). It is idiomatic to namespace-qualify all idents you define. Namespaces can be hierarchical, with segments separated by ".", as in `:<namespace>.<nested-namespace>/<name>`.

The `:db` namespace, and all `:db.*` namespaces, are reserved for use by Datomic. With the exception of `:db/doc` and `:db/ident`, you should not use the built-in Datomic attributes on your own domain entities.

If using underscores in `:db/ident` values, do not use as the first character in the name portion of the keyword as this will prevent you from using [reverse lookups](https://docs.datomic.com/query/query-pull.html#reverse-lookup).

## :db/isComponent

```
{':db/isComponent' boolean}
```

A component entity is one that exists only as part of a larger parent entity.

The optional `:db/isComponent` attribute specifies that an attribute whose [:db/valueType](https://docs.datomic.com/schema/#db-valuetype) is [`:db.type/ref`](https://docs.datomic.com/schema/#db-valuetype) refers to a sub-component of the entity to which the attribute is applied. When you retract an entity with [`:db.fn/retractEntity`](https://docs.datomic.com/transactions/transaction-functions.html#db-retractentity), all sub-components are also retracted.

Omitting `:db/isComponent` for an entity is semantically equivalent to setting it to `false`.

## :db/noHistory

```
{':db/noHistory' boolean}
```

### Description and Use Cases

By default, Datomic maintains all historical values of an attribute. To disable this, set `:db/noHistory` to true. The purpose of`:db/noHistory` is to conserve storage, not to make semantic guarantees about removing information.

`:db/noHistory` is often used for [high churn attributes](https://docs.datomic.com/reference/best.html#nohistory-for-high-churn) along with attributes that you do not require a history of.

## :db/unique

```
{':db/unique' unique}
unique         = (':db.unique/identity' | ':db.unique/value')
```

The `:db/unique` attribute specifies a uniqueness constraint for the values of an attribute. Datomic will reject a transaction if the resulting database would contain multiple entities with the same value for a unique attribute (of either type). You can submit transaction data with a unique attribute without specifying an existing entity id. When you do, one of two things could happen if that unique AV already exists in the database: unify or reject.

To add a uniqueness constraint to an attribute:

- The attribute must have a `:db/cardinality` of `:db.cardinality/one`
- If there are values present for that attribute, they must be unique in the set of *current* database assertions

Adding a unique constraint does not change history, therefore historical databases may contain non-unique values. Code that expects to find a unique value may find multiple values when querying against history.

### :db.unique/identity

Unique identity is specified through an attribute with `:db/unique` set to `:db.unique/identity`. Unique identity is appropriate whenever you want to assert a database-wide unique identifier for an entity. Common use cases include email addresses, account names, product codes/skus, and UUIDs. If transaction data includes a tempid + unique identity, and an entity with that identity already exists in the database, Datomic will unify the new transaction data with the existing entity id. This enables ["upsert"](https://docs.datomic.com/glossary.html#upsert), e.g.

An entity can have multiple different unique attributes, however, this creates the possibility of encountering a [conflict anomaly](https://docs.datomic.com/api/error-handling.html). If a transaction tries to [upsert](https://docs.datomic.com/glossary.html#upsert) a tempid into two *different* existing entities. For example, if entity 42 has the unique email `johndoe@example.com`, and entity 43 has the unique account number `1007`, then a transaction cannot claim that a new entity has both an email of `johndoe@example.com` and an account number of `1007`.

### :db.unique/value

Unique value is specified through an attribute with `:db/unique` set to`:db.unique/value`. If transaction data includes a tempid + unique value, and an entity with that value already exists, Datomic will reject the transaction.

## :db/valueType

```
{':db/valueType' type}
type           = (':db.type/bigdec'  | ':db.type/bigint'  | ':db.type/boolean' |
                  ':db.type/bytes'   | ':db.type/double'  | ':db.type/float'   |
                  ':db.type/instant' | ':db.type/keyword' | ':db.type/long'    |
                  ':db.type/ref'     | ':db.type/string'  | ':db.type/symbol'  |
                  ':db.type/tuple'   | ':db.type/uuid'    | ':db.type/uri')
```

The `:db/valueType` attribute specifies the type of value that can be associated with an attribute. The type is one of the keywords in the table below.

`:db/valueType` cannot be updated after an attribute is created.

| Value type | Description | Java equivalent | Example |
| --- | --- | --- | --- |
| :db.type/bigdec | Arbitrary precision decimal | [`java.math.BigDecimal`](https://docs.oracle.com/javase/8/docs/api/java/math/BigDecimal.html) | 1.0M |
| :db.type/bigint | Arbitrary precision integer | [`java.math.BigInteger`](https://docs.oracle.com/javase/8/docs/api/java/math/BigInteger.html) | 7N |
| :db.type/boolean | Boolean | [`boolean`](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html) | True |
| :db.type/bytes | Value type for small binary data | [`byte[]`](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html) | (byte-array (map byte \[1 2 3\])) |
| :db.type/double | 64-bit IEEE 754 floating point number | [`double`](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html) | 1.0 |
| :db.type/float | 32-bit IEEE 754 floating point number | [`float`](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html) | 1.0 |
| :db.type/instant | Instant in time | [`java.util.Date`](https://docs.oracle.com/javase/8/docs/api/java/util/Date.html) | #inst "2017-09-16T11:43:32.450-00:00" |
| :db.type/keyword | Namespace + name | N/A | :yellow |
| :db.type/long | 64 bit two's complement integer | [`long`](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html) | 42 |
| :db.type/ref | Reference to another entity | N/A | 42 |
| :db.type/string | Unicode string | [`java.lang.String`](https://docs.oracle.com/javase/8/docs/api/java/lang/String.html) | "Foo" |
| :db.type/symbol | Symbol | N/A | Foo |
| :db.type/tuple | [tuples](https://docs.datomic.com/schema/#tuples) of scalar values | N/A | \[42 12 "foo"\] |
| :db.type/uuid | 128-bit universally unique identifier | [`java.util.UUID`](https://docs.oracle.com/javase/8/docs/api/java/util/UUID.html) | #uuid "f40e770e-9ad5-11e7-abc4-cec278b6b50a" |
| :db.type/uri | Uniform Resource Identifier (URI) | [`java.net.URI`](https://docs.oracle.com/javase/8/docs/api/java/net/URI.html) | [https://www.datomic.com/details.html](https://www.datomic.com/details.html) |

### Notes on Value Types

- Keywords are interned for efficiency.
- Instances are stored as the number of milliseconds since the epoch.
- Strings are limited to 4096 characters in Cloud and Datomic Local. Datomic does not enforce this limit in Pro, but users are strongly encouraged to enforce it.
- BigDecimals are limited to 1024 digit precision.
- BigIntegers are limited to a bit length of 8192.
- Symbols map to the symbol type in languages that support them, e.g. clojure.lang.Symbol in Clojure.
- Consistent results in query depend on the scale matching for all BigDecimal comparisons. You are strongly encouraged to use a consistent scale per attribute.

### Tuples

Tuples can be used to create multi-attribute unique keys on domain entities. Tuples can be used to optimize queries that otherwise would have to join two or more high-population attributes.

A tuple is a collection of 2-8 scalar values, represented in memory as a Clojure vector. There are three kinds of tuples:

- [Composite tuples](https://docs.datomic.com/schema/#composite-tuples) are derived from other attributes of the same entity. Composite tuple types have a `:db/tupleAttrs` attribute, whose value is 2-8 keywords naming other attributes.
- [Heterogeneous fixed length tuples](https://docs.datomic.com/schema/#heterogeneous-tuples) have a `:db/tupleTypes` attribute, whose value is a vector of 2-8 scalar value types.
- [Homogeneous variable length tuples](https://docs.datomic.com/schema/#homogeneous-tuples) have a `:db/tupleType` attribute, whose value is a keyword naming a scalar value type.

The following types are considered scalar types suitable for use in a tuple:

String values within a tuple are limited to 256 characters.

`nil` is a legal value for any slot in a tuple. This facilitates using tuples in range searches, where `nil` sorts lowest.

Datomic includes the query helpers [tuple](https://docs.datomic.com/query/query-data-reference.html#tuple) and [untuple](https://docs.datomic.com/query/query-data-reference.html#untuple) for working with tuples in queries.

### Composite Tuples

Composite tuples are applicable in the following situations:

- When a domain entity has a multi-attribute key
- To optimize a query that joins more than one high-population attribute on the same entity

For example, consider the domain of course registrations, modeled with the following entity types:

- Courses represent a course, e.g. Algebra II
- Semesters represent a period in time when a course is run, e.g. "fall 2019"
- Students can take courses in particular semesters

A *registration* entity is a unique combination of a student, semester, and course. In Datomic schema:

A given course/semester/student combination is unique in the database. To model this, you can create a composite tuple whose`:db/tupleAttrs` are:

With this composite installed, Datomic's unique identity will ensure that all assertions about a semester/course/student combination resolve to the same entity.

Composite attributes are entirely managed by Datomic–you never assert or retract them yourself. Whenever you assert or retract any attribute that is part of a composite, Datomic will automatically populate the composite value.

Given a database with the courses and semesters schema, add some seed data:

Now if you register John for Bio 101 in the fall of 2018 by transacting:

Datomic will also add the composite tuple datom:

Note that your entity IDs will differ from those in the example above.

If the current value of an entity does not include all attributes of a composite, the missing attributes will be nil. For example, given a composite 4-tuple:reg/course+semester+student+grade that also includes a student’s grade, the assertions above would cause Datomic to populate:

Note that nil sorts lower than all other values, so tuples with trailing nils can be useful for range queries.

If you retract all constituents of a composite, Datomic will retract the composite. For example, transacting:

will cause Datomic to retract the composite:

Again, note that you will need to substitute the entity IDs from your initial transaction to replicate this example in your system.

### Adding Composites to Existing Entities

Adding a composite tuple to a database that contains existing data using those attributes will **not** immediately generate values for the new tuple. The composite tuple will be populated the next time any of the composite member attributes are transacted. This includes "no-op" transactions of the same attribute value. This design allows you to add composite tuples in a systematic and paced manner, so as not to overwhelm a running system.

An example helper function can be found in the [Day of Datomic Cloud examples](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/40a5220fd5e9b0ec0064680e87774ba26109ca57/src/datomic/dodc/composites.clj). The function will cycle through all values for a given attribute, reasserting them, with the specified batch size, and pausing between batches. You can use this, or something like it, to systematically add composite tuples once you've created the necessary schema attribute(s).

### Heterogeneous Tuples

Heterogeneous tuples have a `:db/tupleTypes` attribute, with a value specified as a vector of 2-8 scalar types.

For example, you could model a location in a 2D game with the following tuple attribute:

You can then explicitly assert a player's location with a vector of the appropriate tuple types:

### Homogeneous Tuples

Homogeneous tuples provide variable-length composites of a single attribute type. The type of a homogeneous tuple is specified by the keyword attribute `:db/tupleType`.

Datomic itself includes a good example of homogeneous tuples in the definitions of the other tuple types. Both `:db/tupleTypes` and`:db/tupleAttrs` are declared as homogeneous tuples of `:db/tupleType``:db.type/keyword`:

## Attribute Predicates

You may want to constrain an attribute value by more than just its value type. For example, an email address is not just a string, but a string with a particular format. In Datomic, you can assert *attribute predicates* about an attribute. Attribute predicates are asserted via the `:db.attr/preds` attribute, and are fully-qualified symbols that name a *predicate* of a value. Predicates return *true* (and only *true*) to indicate success. All other values indicate failure and are reported back as transaction errors.

Inside transactions, Datomic will call all attribute predicates for all attribute values, and abort a transaction if any predicate fails.

For example, the following function validates that a `user-name` has a particular length:

To install the `user-name?` predicate, add a `db.attr/preds` value to an attribute, e.g.

A transaction that includes an invalid `user-name` will result in an [incorrect anomaly](https://docs.datomic.com/api/error-handling.html) that includes:

- The entity id
- The attribute name
- The attribute value
- The name of the failed predicate
- The predicate return in `:db.error/pred-return`

For example, the string "This-name-is-too-long" is not a valid `user-name?` and will cause an anomaly like:

Attribute predicates must be on the classpath of a process that is performing a transaction.

Attribute predicates can be asserted or retracted at any time, and will be enforced starting on the transaction after they are asserted. Asserting or retracting an attribute predicate does not affect attribute values that already exist in the database.

Attribute predicates can [`cancel`](https://docs.datomic.com/transactions/transaction-functions.html#canceling) the transaction directly.

## Entity Specs

You may want to ensure properties of an entity being asserted, for example:

- Required keys
- The creation of related tuples
- Satisfaction of properties that cut across attributes and the DB

An *entity spec* is a Datomic entity having one or more of:

- (usually) a `:db/ident`
- `:db.entity/attrs` naming [required attributes](https://docs.datomic.com/schema/#required-attributes)
- `:db.entity/preds` naming [entity predicates](https://docs.datomic.com/schema/#entity-predicates)

You can then ensure an entity spec by asserting the `:db/ensure` attribute for an entity. For example, the following transaction data ensures entity "new-account-1" with entity spec`:new-account`:

`:db/ensure` is a virtual attribute. It is not added in the database; instead, it triggers checks based on the named entity.

Entity predicates must be on the classpath of a process that is performing a transaction.

Entity specs can be asserted or retracted at any time and will be enforced starting on the transaction after they are asserted. Asserting or retracting an entity spec has no effect on entities that already exist in the database since `:db/ensure` only triggers checks without creating extra transaction data.

Entity specs and `:db/ensure` are *not* analogous to traditional SQL constraints:

- Specs are more flexible, enforcing arbitrary shapes on particular entities without imposing an overall structure on the database
- Specs can do more, allowing arbitrary functions of an entity and the database value as of the start of the transaction (db-before)
- Spec enforcement for an entity must be requested explicitly at transaction time via `:db/ensure`; enforcement is never automatic or retroactive

### Required Attributes

The `:db.entity/attrs` attribute is a multi-valued attribute of keywords, where each keyword names a required attribute.

For example, the following transaction data creates a spec that requires a `:user/name` and `:user/email`:

The `:user/validate` entity can then be used in later transaction to ensure that all required attributes are present. For example, the following transaction would fail:

When a required attribute is missing, Datomic will throw an anomaly whose `ex-data` includes the failing entity and the name of the spec, e.g.:

### Entity Predicates

The `:db.entity/preds` attribute is a multi-valued attribute of symbols, where each symbol names a predicate of database value and entity id. Inside a transaction, Datomic will call all predicates, and abort the transaction if any predicate returns a value that is not `true`.

For example, given the following predicate that has been [deployed](https://docs.datomic.com/transactions/transaction-functions.html#deploying):

You could install the predicate on a guard entity along with [required attributes](https://docs.datomic.com/schema/#required-attributes):

Given an invalid entity that requests `:score/guard`:

Datomic will throw an anomaly whose `ex-data` names the failing predicate:

Datomic will report the value returned by the failing predicate under the `:db.error/pred-return` key. This can be used to report more information about what went wrong.

A full example can be found [in Day of Datomic Cloud](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/master/tutorial/entity_specs.clj)

[`d/cancel`](https://docs.datomic.com/transactions/transaction-functions.html#canceling) can be used directly from entity predicates to cancel the transaction.

### Number of Schema Elements

Datomic enforces the total number of schema elements to be fewer than 2 <sup>20</sup>, which includes schema attributes and value types. Attempts to create more than 2 <sup>20</sup> schema elements will fail.

### Schema Element Restrictions

Excluding `:db/doc` and `:db/ident`, names in the `:db` namespace and all `:db.*` namespaces are reserved for use in Datomic schema. Domain entities cannot use these names.

### Limitations of NaN

The comparison semantics of NaN (Java's [Float](https://docs.oracle.com/javase%2F8%2Fdocs%2Fapi%2F%2F/java/lang/Float.html#NaN) and [Double](https://docs.oracle.com/javase%2F7%2Fdocs%2Fapi%2F/java/lang/Double.html#NaN) constant holding Not-A-Number) make it unavailable for upsert. Upsert in Datomic requires the ability to compare the desired new value to any existing value, which cannot be done when the existing value is NaN. As such, to assert a new value for an attribute whose current value is NaN, a retraction must first be transacted for that NaN value, then a new value can be asserted.

## Legacy

This section contains information about features that have been deprecated. These features will not be removed from the product, but you are discouraged from using them for new development.

### Limitations of Bytes

The `:db.type/bytes` value type has been deprecated because it maps directly to Java byte arrays, which do not have value semantics (semantically equal byte arrays do not compare or hash as equal). As a result, a bytes attribute can function only as a container of data that is semantically opaque, i.e. given an entity id you can look up a bytes attribute value

Bytes attributes **cannot** be used in situations that require value semantics:

- Cannot be unique and therefore cannot be used to lookup an entity
- Cannot be used in [Datomic Cloud](https://docs.datomic.com/datomic-overview.html#datomic-editions)
- Cannot be used with [analytics](https://docs.datomic.com/analytics/analytics-concepts.html)