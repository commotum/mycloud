---
title: "Best Practices | Datomic"
source: "https://docs.datomic.com/reference/best.html"
author:
published:
created: 2025-05-03
description: "Explore Datomic's best practices. Follow this guide to enhance your application's efficiency and reliability."
tags:
  - "clippings"
---
## Best Practices

## Plan for Accretion

Programs should not assume that an entity will be limited to the set of attributes that it has at a given point in time. The [schema growth](https://docs.datomic.com/reference/#grow-schema) principle provides a means for entities to develop over time, and ties programmatic usage to a fixed set of attributes can lead to *breakage* in the face of *growth*.

For example, usage should be structured to handle a given set of attributes for an entity, not applying arbitrary usage to all possible attributes:

## Model Relationships in One Direction Only

When you create a reference type, Datomic automatically indexes the reference in both directions: from entity to value and from value to entity. The indices are equally efficient, so it is entirely redundant to manage relationships in both directions.

For example, the Mbrainz sample schema connects artists and releases via the `:release/artists` attribute. There is no need for a separate`:artist/releases` attribute. The data clause below can find`?artist` from `?release` and/or `?release` from `?artist`:

## Use Idents for Enumerated Types

Enumerated types should be represented by a reference pointing to an entity that has an ident. This is very efficient in memory and storage, as Datomic stores the ident name only once and allows any number of datoms to reference it.

The Mbrainz sample schema demonstrates this with `:artist/country`. Note that transactions can use an ident directly as a reference value, eliding the indirection. The transaction data below creates a reference between `artist-id` and the entity whose ident is`:country/GB`:

## Use Unique Identities for External Keys

If an attribute is used as an external key, set that attribute to be `:db/unique``:db.unique/identity`. Unique identities can be domain-specific identifiers, such as an account number or an email address.

For example, you could represent an ISO 3166-1 compliant country code external key with the following attribute definition:

## Use NoHistory for High-Churn Attributes

For high churn attributes, such as a counter or version incrementer, the cost of storing history is frequently not worth the impact on database size or indexing performance. If you have a high-churn attribute that you don't expect to use in historical queries, you should set `:db/noHistory` to `true`.

## Grow Schema and Never Break It

In a production system, one or more codebases depend on your data. In schema terms,*growth* is providing more schema while *breakage* is removing schema or changing the meaning of existing schema.

Growth migrations are suitable for production, and breakage migrations are, at best, a dev-only convenience.

Further details on *growth* vs. *breakage* can be found in Rich Hickey's 2016 Clojure/conj Keynote, [Spec-ulation](https://www.youtube.com/watch?v=oyLBGkS5ICk).

Datomic provides lightweight, flexible schema that can be *grown* as necessary to support new information about your system or domain. *Growth* is always additive, i.e. adding new attributes, adding new 'types', adding relationships between 'types':

Although this recommendation may seem difficult, the following three sections provide approaches to facilitate *growth* without *breakage*.

## Never Remove or Reuse Names

The meaning of a name is established when the name is first introduced. Removing a named schema component at any level is a breaking change for programs that depend on that name. Never remove a name. Reusing that name to mean something substantially different breaks programs that depend on that meaning. This can be even worse than removing the name, as the breakage may not be as immediately obvious.

## Use Aliases

Instead of removing or reusing names, use aliases to allow multiple names to refer to a single schema element. Datomic allows multiple [`:db/idents`](https://docs.datomic.com/schema/schema-reference.html#db-ident) to refer to a single entity ID.

For example, to create an alias, `:user/primary-email` that refers to the same schema element as an existing ident (`:user/id`), transact the following assertion:

This new alias allows new programs to use the new `:user/primary-email` name, while adhering to the [the prior section](https://docs.datomic.com/reference/#never-remove-or-reuse) ensures that old programs that require `:user/id` will continue to function.

## Annotate Schema

Because Datomic schema is stored as data, you can and should annotate your schema elements with useful information that can:

- Help users/readers understand the system
- Document how the schema has grown over time

For example, in the case of a [preferred newer schema option](https://docs.datomic.com/reference/#grow-schema), you could add a `:schema/see-instead` flag and a `:db/doc` on the older schema element to point users at the new convention:

## Add Facts About the Transaction Entity

Most entities in a system model the "what" of your domain. Transactions provide a place to model "when", "who", "where", and "why".

As a part of every transaction, Datomic creates an entity to represent the transaction itself. This *reified transaction* automatically includes a "when" datom, `:db/txInstant`, which records the wall clock time that the transaction was recorded.

Transactions are ordinary entities: you can create attributes that are about transactions and query them just like any other datoms in Datomic.

For example, the following datoms use a `:data/src` attribute to link the transaction to a source URL from an external system.

## Use Lookup Refs to Specify Existing Entities

Database updates often have a two-step structure:

- Query for database ids using an externally unique identifier
- Use those database ids as part of a transaction

Lookup refs flatten this into a single step. With a lookup ref, you can specify an entity directly via an external identifier.

So instead of:

You can simply:

## Use CAS for Optimistic Concurrency

Transactional systems can use optimistic or pessimistic concurrency controls to deal with read-for-update scenarios. Datomic's built-in compare-and-swap enables generic optimistic approaches.

The following example illustrates the use of `db/cas` for adding a deposit to an account. In only the case that `db/cas` fails (note that we catch `:cognitect.anomalies/conflict` for this specific case), we retry the deposit:

## Use DbAfter to see the Result of a Transaction

The *transact* function returns a map whose `:db-after` key holds value of the database immediately after the transaction is applied. Using `:db-after` ensures that you will see only the impact of your transaction and not other changes to the database that may have been made later.

Because `:db-after` can also be retrieved from [with](https://docs.datomic.com/client-api/datomic.client.api.html#var-with), you can examine the results of a prospective or real transaction identically by using`:db-after`.

The following example uses `:db/cas` and `:db-after` in conjunction to verify that a deposit only increases the account by the correct amount:

## Set txInstant on Imports

When importing values (e.g. from another datastore), note that you can override Datomic's default timestamping behavior by setting `:db/txInstant` explicitly. In the typical case, you will override this by using the original transaction time logged by the database from which you're importing.

Note that Datomic's `:db/txInstant` values must increase monotonically. So when you are performing an import:

- You must choose a `:db/txInstant` value that is not older than any existing transaction
- You should choose `:db/txInstant` newer than the transactor's clock time; otherwise the transactor will be unable to add data until the wall clock catches up

To set `:db/txInstant`, add a map to the transaction with the special`:db/id` value "datomic.tx" and a supplied value for the`:db/txInstant` attribute.

## Pipeline Transactions for Higher Throughput

Data imports run significantly faster if you pipeline transactions using the async API, and maintain several transactions in-flight at the same time.

This can be accomplished using [pipeline](https://clojure.github.io/core.async/#clojure.core.async/pipeline) in *core.async*:

```
Copy(ns your.namespace
  (:require [clojure.core.async :as a :refer (>!! <! >! go-loop)]
            [datomic.client.api :as d]))

(defn tx-pipeline
  "Transacts data from from-ch. Returns a map with:
     :result, a return channel getting {:error t} or {:completed n}
     :stop, a fn you can use to terminate early."
  [conn conc from-ch]
  (let [to-ch (a/chan 100)
        done-ch (a/chan)
        transact-data (fn [data]
                       (try
                          (d/transact conn {:tx-data data})
                        ; if exception in a transaction
                        ; will close channels and put error
                        ; on done channel.
                        (catch Throwable t
                          (.printStackTrace t)
                          (a/close! from-ch)
                          (a/close! to-ch)
                          (>!! done-ch {:error t}))))]

   ; go block prints a '.' after every 1000 transactions, puts completed
   ; report on done channel when no value left to be taken.
   (go-loop [total 0]
     (when (zero? (mod total 1000))
       (print ".") (flush))
     (if-let [c (<! to-ch)]
       (recur (inc total))
       (>! done-ch {:completed total})))

   ; pipeline that uses transducer form of map to transact data taken from
   ; from-ch and puts results on to-ch
   (a/pipeline-blocking conc to-ch (map transact-data) from-ch)

   ; returns done channel and a function that you can use
   ; for early termination.
   {:result done-ch
    :stop (fn [] (a/close! to-ch))}))
```

## Put the Most Selective Clause First in Query

The `:where` clauses of Datomic queries are executed in order. To minimize the work performed by the query engine, the [most restrictive](https://docs.datomic.com/query/query-executing.html#clause-order) clauses should come before the less restrictive clauses, i.e.:

## Prefer Query Over Raw Index Access

Datomic's datalog query is simple and declarative. Queries written in datalog are evident, readily optimized (in ways that may improve over time), and logic-based. As such, Datomic query decouples logical specification from lookup implementation.

Leveraging datalog's simple and declarative nature allows for the easy decomposition of queries. With little system knowledge you can troubleshoot query performance. For more details check the [decomposing a query](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/master/tutorial/decomposing_a_query.clj) example in our Day-of-datomic-cloud tutorial examples.

Conversely, raw index access (e.g. the [datoms API](https://docs.datomic.com/query/raw-index-access.html)) is preferable when all you want is a raw index with no logic or joins. The most common scenarios for this are data import/export and integration with external query systems.

## Use Pull to Retrieve Attribute Values

`pull` is usually the simplest way to retrieve a value for a specified attribute for a given entity. Using an [entity identifier](https://docs.datomic.com/transactions/transaction-data-reference.html#entity-identifiers), calling `pull` is straightforward – check the example below that retrieves the documentation for `:db/ident`:

`Pull` returns a map:

You should use the `:where` clauses to *identify* entities of interest, combined with a `pull` expression to *navigate* to attribute values for those entities. An example:

Finds all artists from Japan then uses pull to list their names. Note that the results are now self-documenting:

`Pull` does not unify on attributes. While a `:where` clause omits an entity that lacks a specified attribute, `pull` simply omits requested attributes that are missing.

Returns maps for artists that have no gender listed:

## Put Blanks in Data Patterns

[Blanks](https://docs.datomic.com/query/query-data-reference.html#blanks) can be used as placeholders that match anything but do not bind or unify. This Mbrainz example finds all countries that have an artist in the Mbrainz database, using a blank to match any artist:

Using a variable rather than the blank when you do not care about the value is an anti-pattern because:

- Blanks allow the query engine to avoid extra work tracking binding and unification for a dummy variable.
- The `_` makes clear your (lack of) intent for these values.

## Use Query Inputs to Parameterize Queries and Leverage Caching

Datomic [caches](https://docs.datomic.com/query/query-executing.html#query-cacheing) queries, so long as the query argument data structures are evaluated as equal. As a result, reusing parameterized queries is much more efficient than building different query data structures. If you need to build data structures at run time for a query, do so using a standard process so that equivalent queries will be evaluated as equal.

The following query finds the names of all bands starting with `"B"`, of type *group*, with a start year of `1970`:

A common anti-pattern is to make repeated adjustments to the query's data structure to change what facts it will match, e.g.:

Instead, you should parameterize the query so that you can call it multiple times with different inputs:

## Work with Data Structures, Not Strings

Two features of Datalog queries make them immune to many of the SQL-injection style attacks to which many other DBMSs are vulnerable:

- Datalog queries are composed of data structures, rather than strings, which obviates the need to do string interpolation, sanitization, escaping, etc.
- The query API is parameterized with data sources. In many cases, this feature obviates the need to include user-provided data in the query itself. Instead, you can pass user data to a parameterized query as its own data source.

You should avoid building queries by reading in a string that has been built up by concatenation or interpolation. Doing so gives up the security and simplicity of working with native data structures.

The example below shows the contrast between good and bad practice.

## Use a Consistent Db Value for a Unit of Work

A database value is immutable and multiple calls to `query` or `pull` on the same database value will return consistent results. The result of calling the *db* function on a connection will progress over time, and therefore calling the function repeatedly in sequence can retrieve facts that do not share a common time basis.

You should use a single database v value for a unit of work in order to maintain consistency and reap the resulting benefits for testing, predictability, and composability.

## Specify t Instead of txInstant for Precise asOf Locations

Datomic's own `t` time value exactly orders transactions in monotonically ascending order, with each transaction receiving its own `t` value. By contrast, wall clock times specified by `db:txInstant` are imprecise as more than one transaction can be recorded in the same millisecond.

For filtering databases by time, establishing the relative order of events in a historical database, or any other time-based operation requiring exact precision, you should always use the `t` (or related `tx`) value.

For example, if you are interested in the wall clock time in which The Rolling Stones were added to the Mbrainz database, you might use a query like this:

But if you want to use the log API to inspect the other data transacted along with this fact, you should get the transaction ID itself:

This transaction id can be converted to a t value with exact precision, or itself used as an argument to e.g. `txRange` where it can be used to retrieve the datoms in the transaction.

## Use the History Filter for Audit Trail Queries

With the history filter, your database will have a view that spans time and sees all historical datoms, including facts that have been since retracted. Use the [history filter](https://docs.datomic.com/reference/filters.html#history) to answer audit trail questions such as:

- "What did we know about this customer when we confirmed this purchase?"
- "In which of these four-time ranges was this customer active?"

The following example uses a history database to retrieve all purchases ever entered for a user as well as the time the purchase was logged by the system. Since it uses a history database, it includes facts that were once asserted but have been later retracted:

This will bind `?added` to `true` if the datom is an assertion and `false` if the datom is a retraction, returning results like:

You can see a canceled (retracted) order and explain why you sent a loaf of bread to shipping at 3:41:43 even though there was no longer a bread order in the shipping queue when the loaf arrived at 3:43:15.

## Pass Multiple Points-in-time to a Single Query

When using filters, you will often need to use multiple points in time for a database. A common mistake encountered with using the `since` filter, for example, is to omit the unfiltered (or differently filtered) database that is the basis for the facts about the identity of the entity for which the query is being made.

An example of using two points in time is provided in the [Day-of-datomic-cloud](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/master/tutorial/filters.clj#L91-L95) sample repository:

This query requires two databases as input. The item's id was transacted before the time range was defined by the `since` filter, so you look up the entity id from its domain id using the unfiltered `$` database. We then join that to the `:item/count` from the filtered `$since` database.

## Use the Log API If Time Is Your Most Selective Criterion

If you are most interested in retrieving values by or at specific times, the [log API](https://docs.datomic.com/api/log.html) is the appropriate (and most efficient) way to do so. The log is ordered by transaction time and provides fast lookup by T.

Transactions can be retrieved directly by `tx-range` [API](https://docs-gateway-dev2-952644531.us-east-1.elb.amazonaws.com:8185/clojure/clojure-client-protocols/0.8.36/datomic.client.api.alpha.html#var-tx-range)

The Log API provides access to the transaction id and data for each transaction. These can be retrieved from the map returned by `tx-range` as `:data` and `:t`.

An example using the `tx-range` API is provided in the [Day of Datomic Cloud](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/master/tutorial/log.clj#L44) sample repository. The example below retrieves all datoms from a specific transaction with the transaction ID *tx-id*: