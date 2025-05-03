---
title: "Database Filters | Datomic"
source: "https://docs.datomic.com/reference/filters.html"
author:
published:
created: 2025-05-03
description: "Learn about Datomic query filters, how to implement them, and their impact on querying efficiency. Optimize your data retrieval with this guide."
tags:
  - "clippings"
---
Hide All Examples

## Database Filters

Filters take a database value and return a new database value that exposes only datoms that satisfy a predicate. This makes it possible to have a single set of queries and index traversals that can be used without change against different filtered views of your data.

Datomic databases can be filtered with the time-based predicates `as-of` and `since`. In addition, you can get an unfiltered view of all history via `history`.

Each of these APIs is described below.

## Example Database

All the examples below use an [example inventory database](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/master/tutorial/filters.repl), looking specifically at an entity that tracks the quantity of dilithium crystals on hand at a given point in time. The subset of the data relevant to the examples are:

| e | a | v | tx | added |
| --- | --- | --- | --- | --- |
| 0x00000c00000003e9 | :db/txInstant | Mon Dec 31 19:00:00 | 0xc00000003e9 | true |
| 0x00001000000003ea | :item/id | DLC-042 | 0xc00000003e9 | true |
| 0x00001000000003ea | :item/description | Dilitihium Crystals | 0xc00000003e9 | true |
| 0x00001000000003ea | :item/count | 100 | 0xc00000003e9 | true |
| 0x00000c00000003eb | :db/txInstant | Thu Jan 31 19:00:00 | 0xc00000003eb | true |
| 0x00001000000003ea | :item/count | 100 | 0xc00000003eb | false |
| 0x00001000000003ea | :item/count | 250 | 0xc00000003eb | true |
| 0x00000c00000003ec | :db/txInstant | Thu Feb 27 19:00:00 | 0xc00000003ec | true |
| 0x00001000000003ea | :item/count | 250 | 0xc00000003ec | false |
| 0x00001000000003ea | :item/count | 50 | 0xc00000003ec | true |
| 0x00000c00000003ed | :db/txInstant | Mon Mar 31 20:00:00 | 0xc00000003ed | true |
| 0x00000c00000003ed | :tx/error | true | 0xc00000003ed | true |
| 0x00001000000003ea | :item/count | 50 | 0xc00000003ed | false |
| 0x00001000000003ea | :item/count | 9999 | 0xc00000003ed | true |
| 0x00000c00000003ee | :db/txInstant | Wed May 14 20:00:00 | 0xc00000003ee | true |
| 0x00001000000003ea | :item/count | 9999 | 0xc00000003ee | false |
| 0x00001000000003ea | :item/count | 100 | 0xc00000003ee | true |

## as-of

[Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/as-of) | [Client API](https://docs.datomic.com/client-api/datomic.client.api.html#var-as-of)

An `as-of` filter returns a database "as of" at a particular point in time, ignoring any transactions after that point. The time specification can be any time point, i.e.

- A Datomic transaction id. Use a transaction id when you want a database as of a specific transaction.
- A Datomic point in time. Use with, e.g., the basis-t value of the `:db-after` returned by `transact`
- An instant in time (a `java.util.Date`). Use an instant when you have a wall clock time for the database you want, but do not have a transaction id or basis-t value, as an instant is not as precise as Datomic's t or tx values.

Because the `item/count` of dilithium crystals is changing over time, different `as-of` views will show different counts:

## since

[Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/since) | [Client API](https://docs.datomic.com/client-api/datomic.client.api.html#var-since)

A `since` filter is the opposite of `as-of`. Taking the same point-in-time arguments as `as-of`, `since` returns a value of the database that includes only datoms added by transactions after that point in time.

There is an important subtlety to consider when using `since`. Typically, the identifying information used to lookup an entity is established in the first transaction about that entity, so a `since` filter may not be able to see the information needed for lookup. Our example has exactly this problem trying to find the entity in question by its`:item/id`:

Most callers of `since` will refer to the database twice: one reference to the default "now" db to find entities, and a second reference to the `since` db to shave off the past. With entities, this looks like

Notice that the "now" `db` is used to resolve the lookup ref, and the `since-2014` db is then used to pull the associated attributes.

In the query, this can take the form of passing two different filters of the same db as separate inputs:

Here, the `db` argument is named `$` inside the query and used to resolve the `:item/id`. Then the `since-2014` is named `$since` inside the query, and used to find the `:item/count`.

## history

[Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/history) | [Client API](https://docs.datomic.com/client-api/datomic.client.api.html#var-history)

The history view of the database includes the present and the unfiltered past, including retractions. This makes the history view ideal for querying the complete history of an entity, or group of entities.

Below is a query for all assertions about dilithium crystals:

Note that the query joins through `:db/txInstant` to return wall clock time, and joins through `:db/ident` to return human-readable attribute names.

Simplified views of data that do not account for time are incompatible with `history`, since a history database can see multiple different values for the "same" fact at different times. In particular, an entity is a point-in-time view and cannot be created from a `history` database.

## filter

[Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/filter)

### Filtering For Security

Imagine that you want to exclude all values of an attribute entirely from consideration. The following code creates a filter that rejects all datoms about the attribute:user/passwordHash.

### Joining Different Filters of the Same Database

It is idiomatic to join different filters of the same database. One motivating case is performance: Since filtering is not free, it makes sense to filter only the parts of the query that need filtering. For example, the query below uses an unfiltered database to find entities, and then a filtered version of the same database to limit the attributes visible through the d/entity call:

#### Filtering on Transaction Attributes

Filters can do more than look at single datoms. They can also consider datoms in the context of the entire database. For example, imagine that you mark the transactions in your system with a*:source/confidence* field that indicates your confidence in the source, on a scale from 0 to 100. You could then filter the database as follows:

Queries using this filter can focus on finding data of interest, without worrying about the cross-cutting concern of how trusted the data is. The query below finds only the stories whose titles were added by sources with a trust score higher than 90:

## Usage Considerations

### as-of Is Not a Branch

Filters are applied to an unfiltered database value obtained from `db` or `with`. In particular, the combination of `with` and `as-of` means " `with` followed by `as-of` ", regardless of which API call you make first. `with` plus `as-of` lets you see a speculative db with recent datoms filtered out, but it does **not** let you branch the past.

### The Present Pays No Penalty

The original database value returned from connection does no filtering. It sees only the present, without having to filter the past. So queries about "now" are as efficient as possible–they do not consider history and pay no penalty for history, no matter how much history is stored in the system.

### Filter or Log?

Filters are applied to database indexes, filtering out data that does not match a predicate. Filters cannot do anything that could not be done directly with indexes, but they do allow you to separate some aspect of a query, reusing query logic across different filtered views.

Consider the following two queries:

- "What happened between 8:00 and 9:00 this morning?"
- "What did entity 42 look like at 8:00 this morning?"

The first query is limited **only** by time. Such a query can be answered directly from the log, which is a time index. Answering the same question via `as-of` and `since` would require a filtering scan of the entire database.

The second query is limited by both entity and by time. Thus it makes sense to augment indexes with a filter, calling a query on an `as-of` view of the database. The query will use the EAVT index to jump straight to the requested datoms, which are then filtered to exclude the most recent datoms. Because all the time-related work is done by `as-of`, the query can be time-agnostic and can work with any point-in-time. You can use the same approach in your own queries, writing queries that are agnostic about time (or about some domain value), and using filters to allow reuse of those queries across different domain values.