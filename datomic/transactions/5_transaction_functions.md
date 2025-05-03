---
title: "Transaction Functions | Datomic"
source: "https://docs.datomic.com/transactions/transaction-functions.html"
author:
published:
created: 2025-05-03
description: "Discover Datomic's transaction functions and how to operate them."
tags:
  - "clippings"
---
Hide All Examples

## Transaction Functions

This page describes transaction functions, which allow arbitrary validations and transformation of transaction data.

Sections covered in this page are:

- [Transaction function semantics](https://docs.datomic.com/transactions/transaction-functions.html#semantics)
- [When to use transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#when-to-use)
- [Performance and security](https://docs.datomic.com/transactions/transaction-functions.html#performance-and-security)
- [Types of transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#types)
- [Invoking transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#invoking)
- [Built-in transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#built-in)
- [Writing transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#writing)
- [Canceling a transaction](https://docs.datomic.com/transactions/transaction-functions.html#canceling)
- [Testing transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#testing)
- [Deploying transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#deploying)

## Transaction Function Semantics

A transaction function lets you build transactions that are flexible based on the value of the database at the start of the transaction (db-before). Rather than determining all the values a transaction needs prior to submitting the transaction, you can use transaction functions to calculate values based on the current state of the database (db-before).

A transaction function is a pure function `[db-before, args] -> tx-data`, i.e. a transaction function takes db-before plus args you provide and produces tx-data for inclusion in the transaction.

Transaction functions support the operation of [d/with](https://docs.datomic.com/transactions/model.html#with-and-transact), which is also a pure function `[db-before, tx-data] -> tx-data`. d/with calls transaction functions to augment tx-data, producing more tx-data:

Transaction functions are tightly focused: they do not see the entire tx-data, only the args passed to them. They also do not see each other's return value. This tight focus is semantically critical, e.g. if d/with piped the return value from one transaction function into the next, then Datomic transactions would have order semantics and no longer be declarative!

## When to use transaction functions

[Consistency](https://docs.datomic.com/transactions/acid.html#consistency) refers to the property that a database transaction takes the database from one valid state to another. Datomic has a number of built-in consistency checks that you can augment by writing custom [*entity predicates*](https://docs.datomic.com/schema/schema-reference.html#entity-predicates) and *transaction functions*. Datomic’s features are well-tested and optimized, and you should prefer them over writing custom code where they fit your use case. Generally speaking, you should work your way down the table below, preferring the approaches listed earlier if they are sufficient for your needs.

| Desired Consistency | Datomic Feature |
| --- | --- |
| value type | attribute [value type](https://docs.datomic.com/schema/schema-reference.html#db-valuetype) |
| uniqueness | attribute [uniqueness constraint](https://docs.datomic.com/schema/schema-reference.html#db-unique) |
| single / multi value attribute | attribute [cardinality](https://docs.datomic.com/schema/schema-reference.html#cardinality) |
| optimistic concurrency (at the level of a single datom) | [db/cas](https://docs.datomic.com/transactions/transaction-functions.html#dbfn-cas) |
| attribute predicate | attribute spec ([`:db.attr/preds`](https://docs.datomic.com/schema/schema-reference.html#attribute-predicates)) |
| entity required attributes | entity spec required attributes ([`:db.entity/attrs`](https://docs.datomic.com/schema/schema-reference.html#required-attributes)) |
| entity predicate against db-after | entity spec predicates ([`:db.entity/preds`](https://docs.datomic.com/schema/schema-reference.html#entity-predicates)) |
| predicates and transformations of transaction data, given db-before | [custom transaction function](https://docs.datomic.com/transactions/transaction-functions.html#types) |
| sagas | [sync](https://docs.datomic.com/transactions/client-synchronization.html#sync) and [as-of](https://docs.datomic.com/transactions/client-synchronization.html#comparison) |

## Performance and Security

By their nature, transaction functions and entity predicates run inside the serialized pipeline of transactions for a database. A slow transaction function and/or entity predicate will impact not only the current transaction, but any transaction requests queued behind the current transaction in the pipeline. Transaction functions and entity predicates should do the minimal amount of work possible, and should do only work that requires access to the in-transaction value of the database.

Transaction functions and entity predicates are arbitrary code, and should be safeguarded in the same ways you would safeguard any other mechanism for deploying code into production. In particular, database functions are deployed via transactions, so you should prevent arbitrary transactions from untrusted users.

## Types of transaction functions

Datomic supports two types of transaction function: database functions and classpath functions. They have essentially the same capabilities and differ primarily in how they are deployed.

1. You can transactionally store a **database function** in a Datomic database. After you do, this function is available on the transactor and in any peer. Database functions can accept up to 10 arguments.
2. **Classpath functions** use Java’s classpath.

You can use either or both approaches, which differ as follows:

|  | Database Function | Classpath Function |
| --- | --- | --- |
| invoke | transaction data has a list whose first element is a **keyword** naming the function, with args as subsequent elements | transaction data has a list whose first element is a **symbol** naming the function, with args as subsequent elements |
| develop | create a function object with e.g. a db/fn literal (Clojure) or a call to Peer.function (Java) | write ordinary Clojure/Java code |
| test | call the function object | test ordinary Clojure/Java code |
| deploy | transact an entity with code in db/fn attribute | you must ensure that the function is on the classpath of the transactor, e.g. by adding a lib to the script you use to launch it |
| resolve | Datomic looks up an entity in the database whose db/ident is the keyword, and then finds the code under that entity's db/fn | Datomic looks up the fully qualified symbol on the classpath |
| version control | versions of the code live in the Database | external to the database in e.g. traditional source control |
| semantics | up to 10 arguments | ordinary Clojure/Java semantics |

## Invoking Transaction Functions

Datomic calls transaction functions automatically when encountering anything other than `:db/add` or `:db/retract` as the first element in a list form. For example, the transaction data below includes a call to the built-in transaction function `:db/retractEntity`

Transaction functions can abort a transaction for any reason whatsoever by calling [`cancel`](https://docs.datomic.com/clojure/index.html#datomic.api/cancel), or they can [expand](https://docs.datomic.com/transactions/transaction-data-reference.html#tx-data) to (possibly empty) data that will be included in the transaction.

The following example installs and invokes a trivial database function:

The example below installs and invokes an equivalent classpath transaction function:

## Built-In Transaction Functions

The following transaction functions are automatically included in Datomic for you to use.

### :db/retractEntity

The `:db/retractEntity` function takes an entity id as an argument. It retracts all the attribute values where the given entity id is either the entity or value, effectively retracting the entity's own data and any references to the entity as well. Entities that are [components](https://docs.datomic.com/schema/schema-reference.html#db-iscomponent) of the given entity are also recursively retracted.

The following example transaction data retracts two entities, specifying one of the entities by entity id, and the other by a [lookup ref](https://docs.datomic.com/transactions/transaction-data-reference.html#lookup-ref).

### :db/cas

The `:db/cas` (compare-and-swap) function takes four arguments: an entity id, an attribute, an expected current value, and a new value. The attribute must be `:db.cardinality/one`. If the entity has the expected value for the given attribute in db-before, then db/cas will expand to a list form asserting the new value. Otherwise, the transaction will abort and throw an exception.

You can use nil for the old value to specify that the new value should be asserted only if no value currently exists.

The following example transaction data asserts entity 42's`:account/balance` to be 110, if and only if `:account/balance` is 100 at the time the transaction executes (in db-before):

### :db/force-partition

The [`:db/force-partition`](https://docs.datomic.com/transactions/partitions.html#force-partition) function takes a map of tempids to desired partitions.

### :db/match-partition

The [`:db/match-partition`](https://docs.datomic.com/transactions/partitions.html#match-partition) function takes a map of tempids to entities that are in desired partitions.

## Writing Transaction Functions

If you have a consistency requirement that is not covered by a built-in feature of Datomic, you can write a custom transaction function, adhering to the following rules:

1. Must be pure functions, free of side effects.
2. Must take the current value of the database (db-before) as a first argument, followed by data arguments that match the arguments in the transaction data.
3. On success, must return valid transaction data (which can include more transaction functions!)
4. To abort a transaction, call [`cancel`](https://docs.datomic.com/clojure/index.html#datomic.api/cancel).
5. Transaction data is serialized with Fressian. Transaction functions should not rely on, or presume, Clojure collection capabilities since collections deserialized by Fressian are guaranteed only Java interfaces.

## Canceling a transaction

[`cancel`](https://docs.datomic.com/clojure/index.html#datomic.api/cancel) cancels the current Datomic query or transaction, and throws an ex-info with an [anomaly](https://github.com/cognitect-labs/anomalies) to the original caller.

`cancel` requires a map with the key `:cognitect.anomalies/category`, which has valid values of:

- `:cognitect.anomalies/incorrect`
- `:cognitect.anomalies/conflict`

When `:cognitect.anomalies/message` is provided, the message will be used as the Exception's detail message.

All other keys should be namespace-qualified and all data passed to cancel must be either [transit](https://github.com/cognitect/transit-format) -serializable in the Client API, or [fressian](https://github.com/Datomic/fressian/wiki) -serializable in the Peer API.

The example below uses a transaction function to ensure that users always have a `name` and `email`. The first transaction succeeds, but the second is canceled since `:address` is passed instead of `:email`.

## Testing Transaction Functions

Transaction functions are ordinary code, and can be developed and tested in whatever environment/IDE you use for writing JVM code. In particular, they are suited for REPL-based testing in Clojure.

## Deploying Transaction Functions

Database functions and classpath functions are deployed differently.

### Deploying Database Functions

You deploy a database function by adding it as an attribute of an entity. There is already an attribute of the correct (`:db.type/fn`) type - `:db/fn`. Normally you will also add a:db/ident attribute on the function entity to serve as its name, as well as a:db/doc string. When a function is added to the database, its language and code are stored.

The function object that you get from calling `d/function` (or `Peer.function()`) is the same thing that you will get when retrieving the `:db/fn` attribute. It is an object that will implement `datomic.functions.Fn`, as well as the one of `datomic.functions.FnN` matching its arity. In addition, for Clojure users, it will implement `clojure.lang.IFn`. This object will dynamically compile itself the first time it is invoked. Subsequent calls will be as fast as any compiled Java code - the calls are *neither interpreted nor reflective*. To invoke a function, simply call `d/invoke` (or `invoke()` on it). You can call database functions written in either language from any JVM language with interop support.

### Deploying Classpath Functions

`d/transact` always executes on the transactor, so functions must be added to the transactor classpath. `d/with` can execute anywhere you call it, on either transactors or peers.

To add a classpath function for use by peers, use your ordinary classpath-building tools, e.g. tools.deps, leiningen, or maven.

To add a classpath function for use by transactors, set the `DATOMIC_EXT_CLASSPATH` environment variable before launching the transactor, e.g. if you added your code in mylibs/mylib.jar: