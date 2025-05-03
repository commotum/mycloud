---
title: "Executing Queries | Datomic"
source: "https://docs.datomic.com/query/query-executing.html"
author:
published:
created: 2025-05-03
description: "Learn how to execute queries in Datomic."
tags:
  - "clippings"
---
Hide All Examples

## Executing Queries

[Day of Datomic Cloud](https://www.youtube.com/watch?v=qplsC2Q2xBA&t=8s) goes over query concepts, with [examples on Github](https://github.com/cognitect-labs/day-of-datomic-cloud).

## Querying a Database

In order to query, you must acquire a [database value](https://docs.datomic.com/whatis/data-model.html#database). To get a database value, you can call `db`, passing in a [connection](https://docs.datomic.com/clojure/index.html#datomic.api/connect).

The arguments to `q` are documented in the [Query Data Reference](https://docs.datomic.com/query/query-data-reference.html).

## q

`q` is the primary entry point for Datomic query.

[Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/q) | [Client API](https://docs.datomic.com/client-api/datomic.client.api.html#var-q)

`q` Performs the query described by query and args, and returns a collection of tuples.

- The query to perform: a map, list, or [string](https://docs.datomic.com/query/#work-with-data-structures). [Complete description.](https://docs.datomic.com/query/query-data-reference.html)
	- [`:find`](https://docs.datomic.com/query/query-data-reference.html#find-specs) - specifies the tuples to be returned.
	- [`:with`](https://docs.datomic.com/query/query-data-reference.html#with) - is optional, and names vars to be kept in the aggregation set but not returned
	- [`:in`](https://docs.datomic.com/query/query-data-reference.html#inputs) - is optional. Omitting ':in …' is the same as specifying ':in $'
	- [`:where`](https://docs.datomic.com/query/query-data-reference.html#where-clauses) - limits the result returned
- Data sources for the query, e.g. database values retrieved from a [call to db](https://docs.datomic.com/query/#querying-a-database), and/or [rules](https://docs.datomic.com/query/query-data-reference.html#rules).

## qseq

`qseq` is a variant of `q` that [pulls](https://docs.datomic.com/query/query-data-reference.html#pull-expressions) and [xforms](https://docs.datomic.com/query/query-pull.html#xform-option) lazily as you consume query results.

[Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/qseq) | [Client API](https://docs.datomic.com/client-api/datomic.client.api.html#var-qseq)

`qseq` utilizes the same [arguments and grammar as q](https://docs.datomic.com/query/query-data-reference.html#arg-grammar).

`qseq` is primarily useful when you know in advance that you do not need/want a realized collection. i.e. you are only going to make a single pass (or partial pass) over the result data.

Item transformations such as `pull` are deferred until the seq is consumed. For queries with pull(s), this results in:

- Reduced memory use and the ability to execute larger queries.
- Lower latency before the first results are returned.

The returned seq object efficiently supports [`count`](https://clojure.github.io/clojure/clojure.core-api.html#clojure.core/bounded-count).

## Unification

Unification occurs when a variable appears in more than one data pattern. In the following query, *?e* appears twice:

Matches for the variable *?e* must *unify*, i.e. represent the same value in every clause in order to satisfy the set of clauses. So a matching *?e* must have both *:age* 42 and *:likes* for some *?x*:

## List Form vs. Map Form

Queries written by humans typically are a list, and the various keyword arguments are inferred by position. For example, this query has one `:find:` argument, three `:in` arguments, and two `:where` arguments:

While most people find the positional syntax easy to read, it makes extra work for programmatic readers and writers, which have to keep track of what keyword is currently "active" and interpret tokens accordingly. For such cases, queries can be specified more simply as maps. The query above becomes:

## Timeout

Users can protect against long-running queries via Datomic's query timeout functionality. Datomic will abort a query shortly after its elapsed duration has exceeded the provided `:timeout` threshold.

`:timeout` can be provided to [query](https://docs.datomic.com/clojure/index.html#datomic.api/query) in the Peer API and the 1-arity version of [q](https://docs.datomic.com/client-api/datomic.client.api.html#var-q) in the Client API.

The example below lists all movies in the database by genre, but will likely fail due to the 1msec timeout.

You will likely see something like `ExceptionInfo Datomic Client Timeout  clojure.core/ex-info (core.clj:4739)`.

## Clause Order

To minimize the amount work the query engine must do, query authors should put the most selective or narrowing `:where` clauses first, and then proceed on to less selective clauses.

[query-stats](https://docs.datomic.com/reference/query-stats.html) provides information about clause selectivity that can be used to properly order the `:where` clauses of a query.

As an example, consider the following two queries looking for Paul McCartney's releases. The first `:where` clause begins with a [data pattern](https://docs.datomic.com/query/query-data-reference.html#data-patterns) (`[?release :release/name ?name]`) that has very low selectivity since `?release` nor `?name` have values bound to them, forcing the query engine to consider any release with some value for `:release/name` in the database:

The following equivalent query reorders the `:where` clauses, leading with a much more selective pattern (`[?release :release/artists ?artist]`) that is limited in this context to the single `?artist` passed in.

The second query runs 50 times faster on the [mbrainz](https://github.com/Datomic/mbrainz-importer) dataset.

## Query Caching

Datomic processes maintain an in-memory cache of parsed query representations. Caching is based on equality of the query argument to `q`. To take advantage of caching, programs should

- Use parameterized queries (that is, queries with multiple inputs) instead of building dynamic queries.
- When building dynamic queries, use a canonical approach to naming and ordering such that equivalent queries will be structurally equal.

In the example below, the parameterized query for artists will be cached on first use and can be reused any number of times:

A semantically equivalent query with different variable names will be separately compiled and cached: