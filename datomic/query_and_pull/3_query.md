---
title: "Query Reference | Datomic"
source: "https://docs.datomic.com/query/query-data-reference.html"
author:
published:
created: 2025-05-03
description: "Learn about the data format for Datomic datalog queries and rules."
tags:
  - "clippings"
---
Hide All Examples

## Query Reference

This topic documents the data format for Datomic datalog queries and rules. If you want to follow along at a REPL, most of the examples on this page work use the [mbrainz-subset](https://github.com/Datomic/mbrainz-importer#readme) database and are in the [Day of Datomic Cloud](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/master/tutorial/query.clj) repository.

## Query Grammar

### Syntax Used In Grammar

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

### Query Arg Grammar

```
query             = [find-spec return-map-spec? with-clause? inputs? where-clauses?]
find-spec         = ':find' (find-rel | find-coll | find-tuple | find-scalar)
find-rel          = find-elem+
find-coll         = [find-elem '...']
find-scalar       = find-elem '.'
find-tuple        = [find-elem+]
find-elem         = (variable | pull-expr | aggregate)
variable          = symbol starting with "?"
pull-expr         = ['pull' variable pattern]
pattern           = (pattern-name | pattern-data-literal)
pattern-name      = plain-symbol
plain-symbol      = symbol that does not begin with "$", "?", or "%"
aggregate         = [aggregate-fn-name fn-arg+]
fn-arg            = (variable | constant | src-var)
constant          = any non-variable data literal
src-var           = symbol starting with "$"
return-map-spec   = (return-keys | return-syms | return-strs)
return-keys       = ':keys' plain-symbol+
return-syms       = ':syms' plain-symbol+
return-strs       = ':strs' plain-symbol+
with-clause       = ':with' variable+
inputs            = ':in' (src-var | binding | pattern-name | rules-var)+
binding           = (bind-scalar | bind-tuple | bind-coll | bind-rel)
bind-scalar       = variable
bind-tuple        = [ (variable | '_')+]
bind-coll         = [variable '...']
bind-rel          = = [ [(variable | '_')+] ]
rules-var         = '%'
where-clauses     = ':where' clause+
clause            = (not-clause | not-join-clause | or-clause | or-join-clause | expression-clause)
not-clause        = [ src-var? 'not' clause+ ]
not-join-clause   = [ src-var? 'not-join' [variable+] clause+ ]
or-clause         = [ src-var? 'or' (clause | and-clause)+]
or-join-clause    = [ src-var? 'or-join' [variable+] (clause | and-clause)+ ]
and-clause        = [ 'and' clause+ ]
expression-clause = (data-pattern | pred-expr | fn-expr | rule-expr)
data-pattern      = [ src-var? (variable | constant | '_')+ ]
pred-expr         = [ [pred fn-arg+] ]
fn-expr           = [ [fn fn-arg+] binding]
rule-expr         = [ src-var? rule-name (variable | constant | '_')+]
rule-name         = plain-symbol
```

See [the pull pattern grammar](https://docs.datomic.com/query/query-pull.html#pull-grammar) for the description of the pattern-data-literal rule.

### Query Rule Grammar

## Queries

```
query                      = [find-spec with-clause? inputs? where-clauses?]
```

A query consists of:

- a *find-spec* that specifies variables and aggregates to return
- an optional *with-clause* to control how duplicate find values are handled
- an optional *inputs* clause that names the databases, data, and rules available to the query engine
- optional *where-clauses* that constrain and transform data

At least one of *inputs* or *where-clauses* must be specified.

Datomic offers multiple ways to query:

- `q` [Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/q) | [Client API](https://docs.datomic.com/client-api/datomic.client.api.html#var-q)
- `query` [Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/query) | [Client API arity-1](https://docs.datomic.com/client-api/datomic.client.api.html#var-q)
- `qseq` [Peer API](https://docs.datomic.com/clojure/index.html#datomic.api/qseq) | [Client API](https://docs.datomic.com/client-api/datomic.client.api.html#var-qseq)

### Query Example

This query limits datoms to `:artist/name` "The Beatles", and returns the entity ids for such results:

Note as well the quoted vector `[:find ...]`. `q` requires a quoted sequence passed to it for the query. Failure to quote the query will result in a `Unable to resolve symbol:` error.

## Find Specs

```
find-spec                  = ':find' (find-rel | find-coll | find-tuple | find-scalar)
find-rel                   = find-elem+
find-coll                  = [find-elem '...']
find-scalar                = find-elem '.'
find-tuple                 = [find-elem+]
find-elem                  = (variable | pull-expr | aggregate)
```

| Find Spec | Returns | Supported API |
| --- | --- | --- |
| :find?a?b | relation | Peer & Client |
| :find \[?a …\] | collection | Peer |
| :find \[?a?b\] | single tuple | Peer |
| :find?a. | single scalar | Peer |

A *find-spec* is the literal `:find` followed by one or more *find-elems*, which can be

- a [*variable*](https://docs.datomic.com/query/#variables) that returns variables directly
- a [*pull-expr*](https://docs.datomic.com/query/#pull-expressions) that hierarchically selects data about an entity variable
- an [*aggregate*](https://docs.datomic.com/query/#aggregates) that summarizes all values of a variable

The order of *find-elems* determines the order variables appear in a result tuple.

## Variables

```
variable                   = symbol starting with "?"
```

A *variable* is a symbol that begins with `?`. In a *find-spec*, variables control which variables are returned, and what order those variables appear in the result tuple.

Like the rest of Clojure, variables are case-sensitive e.g. `?track` and`?Track` are different variables.

### Find Variables Example

The query below specifies that the result tuples should contain the track name and duration. Note that the `?track` and `?e` variables are used in the query, but are not returned.

In this example, the variable `?track` [unifies](https://docs.datomic.com/query/query-executing.html#unification). The clauses for`:track/artists`, `:track/name` and `:track/duration` all must have `?track` in the entity slot to unify around the same entity.

## Pull Expressions

```
pull-expr                  = ['pull' variable pattern]
pattern                    = (pattern-name | pattern-data-literal)
```

A pull expression returns information about a variable as specified by a pattern. Each variable can appear in at most one pull expression. Pull expressions are fully described in the [Pull reference](https://docs.datomic.com/query/query-pull.html).

### Finding Pull Expression Example

Rather than returning just a variable, this query uses a pull expression to specify which attributes to return values for about the entity whose `:artist/name` is "The Beatles":

### Separation of Concerns

The Pull API provides a declarative interface where you specify *what* information you want for an entity without specifying *how* to find it. Pull expressions can be used in queries to find entities and return an explicit map with the specified information about each entity.

This example uses `songs-by-artist` to find all tracks for an artist, then uses different pull patterns to pull different information about the resulting entities.

```
Copy;; Use a different pull pattern to get the track name, the release name, and the artists on the release.
(d/q songs-by-artist db track-releases-and-artists "Bob Dylan")
```
```
([{:track/name "California",
   :medium/_tracks
   #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
 [{:track/name "Grasshoppers in My Pillow",
   :medium/_tracks
   #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
 [{:track/name "Baby Please Don't Go",
   :medium/_tracks
   #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
 [{:track/name "Man of Constant Sorrow",
   :medium/_tracks
   #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
 [{:track/name "Only a Hobo",
   :medium/_tracks
   #:release{:_media #:release{:artists [#:artist{:name "Bob Dylan"}], :name "A Rare Batch of Little White Wonder"}}]
 ...)
```

## Custom Query Functions

You can write your own custom functions for use as [aggregate](https://docs.datomic.com/query/#aggregates),[predicate](https://docs.datomic.com/query/#predicates), or [function](https://docs.datomic.com/query/#functions) clauses in query. To make these functions available in Datomic Pro, follow the instructions to [deploy transaction functions](https://docs.datomic.com/transactions/transaction-functions.html#deploying). To make these functions available in Datomic Cloud, follow the instructions to deploy as an [ion](https://docs.datomic.com/ions/ions-reference.html#ion-config).

You can [cancel](https://docs.datomic.com/transactions/transaction-functions.html#canceling) custom query functions.

## Return Maps

Supplying a return-map will cause the query to return maps instead of tuples. Each entry in the `:keys` / `:strs` / `:syms` clause will become a key mapped to the corresponding item in the `:find` clause.

| keyword | symbols become |
| --- | --- |
| :keys | keyword keys |
| :strs | string keys |
| :syms | symbol keys |

In the example below, the `:keys` `artist` and `release` are used to construct a map for reach row returned.

Return maps also preserve the order of the `:find` clause. In particular, return maps

- implement `clojure.lang.Indexed`
- support `nth`
- support vector style destructuring

For example, the first result from the previous query can be destructured in two ways:

## Aggregates

```
aggregate                  = [aggregate-fn-name fn-arg+]
fn-arg                     = (constant | src-var)
```

An aggregate function appears in the find clause and transforms a result. Aggregate functions can take variables, constants, or src-vars as arguments.

Aggregates appear as lists in a find-spec. Query variables not in aggregate expressions will group the results and appear intact in the result.

### Example Aggregate

This query binds `?a ?b ?c ?d`, then groups by `?a` and `?c`, and produces a result for each aggregate expression for each group, yielding 5-tuples.

### Built-In Aggregates

Each of these is described in more detail below.

| aggregate | \# returned | notes |
| --- | --- | --- |
| avg | 1 |  |
| count | 1 | counts duplicates |
| count-distinct | 1 | counts only unique values |
| distinct | n | set of distinct values |
| max | 1 | compares all types, not just numbers |
| max n | n | returns up to n largest |
| median | 1 |  |
| min | 1 | compares all types, not just numbers |
| min n | n | returns up to n smallest |
| rand n | n | random up to n with duplicates |
| sample n | n | sample up to n, no duplicates |
| stddev | 1 |  |
| sum | 1 |  |
| variance | 1 |  |

### Aggregates Returning a Single Value

The aggregation functions that return a single value are listed below, and all behave as their names suggest.

- *min* and *max*  
	The following query finds the smallest and largest track lengths:
	The *min* and *max* aggregation functions support all database types (via comparators), not just numbers.
- *sum*  
	The following query uses *sum* to find the total number of tracks on all media in the database.
- *count* and *count-distinct*  
	More than one artist can have the same name. The following query uses *count* to report the total number of artist names, and *count-distinct* to report the total number of unique artist names.
	Note the use of a [with-clause](https://docs.datomic.com/query/#with) so that equal names do not coalesce.
- Statistics: *median*, *avg*, *variance*, and *stddev*  
	Are musicians becoming more verbose when naming songs? The following query reports the *median*, *avg*, and *stddev* of song title lengths (in characters), and includes *year* in the find set to break out the results by year.

## Inputs

```
inputs                     = ':in' (src-var | binding | pattern-name | rules-var)+
```

The inputs clause names and orders the inputs to a query. Inputs can be

- a database name, i.e. a symbol starting with `$`
- a variable binding, e.g. a symbol starting with `?`
- a pattern name, i.e. a plain symbol
- the rules var, i.e. the symbol `%`

A query has as many inputs as it has `:args` values, and the inputs bind the`:args` values for use inside the query.

### Default Inputs

Most queries operate against a single database. So as a convenience, the inputs clause can be elided, and will default to a single database whose name is the dollar sign *$*.

For example, the following three queries are equivalent:

### Inputs Example

The query below takes the artist name as an input, so that this parameterized query can be re-used with different artist names.

Inside the query, `$` is bound to `db`, and `?name` is bound to "The Beatles".

### Pattern Inputs

An input can be a pattern var, specifying a pattern to be used in pull expressions in the find clause.

The query below binds `pattern` to the artist's start year and end year.

## Binding Forms

A *binding form* tells how to map data onto variables. A variable name like *?artist-name* is the simplest kind of *binding*, assigning its value directly to variable. Other forms support destructuring the data into a tuple, a collection, or a relation:

| Binding Form | Binds |
| --- | --- |
| ?a | scalar |
| \[?a?b\] | tuple |
| \[?a …\] | collection |
| \[ \[?a?b \] \] | relation |

### Tuple Binding

```
bind-tuple                 = [ (variable | '_')+]
```

A tuple binding binds a set of variables to a single value each, passed in as a collection. The query below binds both artist name and release name to find the entity ids for releases of John Lennon's *Mind Games*:

### Collection Binding

```
bind-coll                  = [variable '...']
```

A collection binding binds a single variable to multiple values passed in as a collection. This can be used to ask "or" questions involving the values of the collection binding.

This query shows how to ask "What releases are associated with either Paul McCartney *or* George Harrison?"

### Relation Binding

```
bind-rel                   = [ [(variable | '_')+] ]
```

A relation binding is fully general, binding multiple variables positionally to a relation (collection of tuples) passed in. This can be used to ask "or" questions involving variables in the relation binding. For example, what releases are associated with either John Lennon's *Mind Games* or Paul McCartney's *Ram*?

## Where Clauses

```
where-clauses              = ':where' clause+
clause                     = (not-clause | not-join-clause | or-clause | or-join-clause | expression-clause)
expression-clause          = (data-pattern | pred-expr | fn-expr | rule-expr)
```

A where clause limits the results returned. The most common kind of where clause is a data pattern that is matched against datoms in the database, but there are many other kinds of clauses to support negation, disjunction, predicates, and functions.

## Implicit Joins

`where` clauses implicitly join. If a variable appears in the same place in multiple clauses, those matches must [unify](https://docs.datomic.com/query/query-executing.html#unification).

To start we'll form two queries to find the years of releases of The Beatles and Janis Joplin separately. (Remember the database covers only from 1968 to 1973).

We can take advantage of implicit joins by combining these queries but utilizing the same `?year` variable in the `:release/year` clause while looking for the artists separately

Now the years when both The Beatles and Janis Joplin released an album can be found.

`?year` was matched for both `?release` and `release2`.

## Data Patterns

```
data-pattern               = [ src-var? (variable | constant | '_')+ ]
```

A data pattern is a tuple that begins with an optional src-var which binds to a relation. The src-var is followed one or more elements that match the tuples of that relation in order. The relation is almost always a Datomic database, so the components are E, A, V, Tx, and Op. The elements of data pattern can be

- variables, which unify and bind to values
- constants, which limit results to tuples that match the constant
- the blank `_` which matches anything

The example below, [utilizing the mbrainz database via the mbrainz importer](https://github.com/Datomic/mbrainz-importer), has a single data pattern which operates as follows:

- `$mbrainz` binds to the db argument
- the constant `:artist/name` limits results to datoms with that value in their Attribute (A) position
- the constant "The Beatles" limits results to datoms with that value in their Value (V) position
- the variables `?e`, `?tx`, and `?op` bind to those positions in the matching datoms, if any

## Blanks

Sometimes you don't care about certain elements of the tuples in a query, but you must put something in the clause in order to get to the positions that you **do** care about. The underscore symbol (`_`) is a blank placeholder, and matches anything without [binding](https://docs.datomic.com/query/#binding-forms) or [unifying](https://docs.datomic.com/query/query-executing.html#unification).

For example, if you wanted a random artist name, you would need a data pattern that talked about A and V, but you would not care about the E component which precedes them. The following query uses the blank in the E position:

*Do not use a dummy variable instead of the blank.* This will make the query engine do extra work by tracking binding and unification for a variable that you never intend to use. It will also make human readers do extra work, puzzling out that the dummy variable is intentionally not used.

Blanks do not cause [unification.](https://docs.datomic.com/query/query-executing.html#unification)Clauses with multiple blanks will not unify despite appearing to have the same symbol used.

### Implicit Blanks

In data patterns, you should elide any trailing components you don't care about, rather than explicitly padding with blanks. The previous examples already demonstrates this by omitting the Tx and Op components from the pattern

## Predicates

```
pred-expr                  = [ [pred fn-arg+] ]
```

A predicate is an arbitrary Java or Clojure function. Predicates must be pure functions, i.e. they must be free of side effects and always return the same thing given the same arguments.

Predicates are invoked against variables that are already bound to further constrain the result set. If the predicate returns `false` or `nil` for a set of variable bindings, that set is removed.

### Predicate Example

The query below uses the built-in predicates `<=` and `<` to limit the results to artists whose name sorts greater than or equal to "Q" and less than "R", i.e. the artists whose name begins with "Q":

You can use any pure function from the [clojure.core](https://clojure.github.io/clojure/clojure.core-api.html) namespace as a predicate.

### Range Predicates

The predicates `=`, `!=`, `<=`, `<`, `>`, and `>=` are special, in that they take direct advantage of Datomic's AVET index. This makes them **much** more efficient than equivalent formulations using ordinary predicates. For example, the "artists whose name starts with 'Q'" query shown above is much more efficient than an equivalent version using `starts-with?`

Unlike their Clojure equivalents, the Datomic range predicates require exactly two arguments.

The section [Built-in Predicates and Functions](https://docs.datomic.com/query/#built-in-functions) lists all built-in predicates.

## Functions

```
fn-expr                    = [ [fn fn-arg+] binding]
```

Queries can call arbitrary Java or Clojure functions. Such functions must be pure functions, i.e. they must be free of side effects and always return the same thing given the same arguments.

Functions are invoked against variables are that are already bound, and their results are interpreted via [binding forms](https://docs.datomic.com/query/#binding-forms) to bind additional variables.

### Function Example

The example below uses the division function `quot` call to convert track lengths from milliseconds to minutes:

An alternate example utilizing a [predicate](https://docs.datomic.com/query/#predicates) with a function binding to find artists with names under 7 characters and show the number of characters in their name.

The section [Built-in Predicates and Functions](https://docs.datomic.com/query/#built-in-functions) lists all built-in functions.

## Built-in Predicates and Functions

Datomic provides the following built-in expression functions and predicates:

- Two-argument comparison predicates: *!=*, *<*, *<=*, *\>*, and *\>=*.
- Two-argument mathematical operators: *+*, *\-*, *\**, and /.
- All of the functions from the [clojure.core](https://clojure.github.io/clojure/clojure.core-api.html) namespace of Clojure, except *eval*.
- A set of functions and predicates that are aware of Datomic data structures, documented below:
	- [get-else](https://docs.datomic.com/query/#get-else)
	- [get-some](https://docs.datomic.com/query/#get-some)
	- [ground](https://docs.datomic.com/query/#ground)
	- [missing](https://docs.datomic.com/query/#missing)
	- [q](https://docs.datomic.com/query/#q)
	- [tuple](https://docs.datomic.com/query/#tuple)
	- [untuple](https://docs.datomic.com/query/#untuple)
- \[Peer API\] A set of functions that are aware of Datomic's Log:
	- [tx-ids](https://docs.datomic.com/reference/log.html#log-in-query)
	- [tx-data](https://docs.datomic.com/reference/log.html#log-in-query)

Comparison and math operators work as in Clojure with the exception that `/` will work like [`quot`](https://clojuredocs.org/clojure.core/quot) when called with integer arguments to avoid introducing Clojure's ratio type to other language callers that cannot support it.

### get-else

The *get-else* function takes a database, [an entity identifier](https://docs.datomic.com/transactions/transaction-data-reference.html#entity-identifiers), a cardinality-one attribute, and a default value. It returns that entity's value for the attribute, or the default value if entity does not have a value.

The query below reports "N/A" whenever an artist's *startYear* is not in the database:

### get-some

The *get-some* function takes a database, [an entity identifier](https://docs.datomic.com/transactions/transaction-data-reference.html#entity-identifiers), and one or more cardinality-one attributes, returning a tuple of the entity id and value for the first attribute possessed by the entity.

The query below tries to find a *:country/name* for an entity, and then falls back to *:artist/name*:

### ground

The *ground* function takes a single argument, which must be a constant, and returns that same argument. Programs that know information at query time should prefer *ground* over e.g. *identity*, as the former can be used inside the query engine to enable optimizations.

### missing?

The *missing?* predicate takes a database,[an entity identifier](https://docs.datomic.com/transactions/transaction-data-reference.html#entity-identifiers), and an attribute and returns true if the entity has no value for attribute in the database.

The following query finds all artists whose start year is not recorded in the database.

### q

The *q* function allows you to perform nested queries, and takes the same arguments as the variable-arity [q api function](https://docs.datomic.com/client-api/datomic.client.api.html#var-q).

The example below shows using a nested query to bind the the `?duration` variable for use by an enclosing query that returns the entity id and name of the shortest tracks:

### tuple

Given one or more values, the *tuple* function returns a [tuple](https://docs.datomic.com/schema/schema-reference.html#tuples) containing each value. See also [untuple](https://docs.datomic.com/query/#untuple).

### untuple

Given a [tuple](https://docs.datomic.com/schema/schema-reference.html#tuples), the untuple function can be used to name each element of the tuple. See also [tuple](https://docs.datomic.com/query/#tuple).

## Calling Java Methods

Java methods can be used as query expression functions and predicates, and should be type hinted for performance. Java code used in this way must be on the Java process classpath.

Java methods should only be used when there is not an equivalent function in [clojure.core](https://clojure.github.io/clojure/clojure.core-api.html).

The sections below show how to call both static methods and instance methods.

### Calling Static Methods

Java static methods can be called with the *(ClassName/methodName …)* form. For example, the following code calls *System.getProperties*, binding property names to *?k* and property values to *?v*.

### Calling Instance Methods

Java instance methods can be called with the *(.methodName obj …)* form. For example, the following code finds artists whose name contains "woo"?

Note the `^String` type hint on `?name`. Type hints outside java.lang will need to be fully qualified, and complex method signatures may require more than one hint to be unambiguous.

## Calling Clojure Functions

Clojure functions can be used as query expression functions and predicates. The example below uses *subs* as an expression function to extract prefixes of words:

## Not Clauses

```
not-clause                 = [ src-var? 'not' clause+ ]
```

With *not* clauses, you can express that one or more logic variables inside a query must **not** satisfy all of a set of predicates. removes already-bound tuples that satisfy the *clauses*. Unless you specify an explicit *src-var*, *not* clauses will target a source named *$*.

### Not Example

The following query uses a *not* clause to find the count of all artists who are not Canadian:

### How Not Clauses Work

Not clauses are evaluated like a subquery and return a set of tuples that is used to remove tuples from the query's result set via set difference. Since the removal of tuples from the query's result set is performed using set logic, not clauses have the potential to be much more efficient than expression predicates which must be applied iteratively to each tuple in the result set instead of to the entire result set.

### Insufficient Binding for a Not Clause

All variables used in a *not* clause will unify with the surrounding query. This includes both the arguments to nested expression clauses as well as any bindings made by nested function expressions. Datomic will attempt to push the *not* clause down until all necessary variables are bound, and will throw an `::anom/incorrect` [anomaly](https://docs.datomic.com/api/error-handling.html) if that is not possible.

The query below demonstrates the problem. It attempts to remove eids that are not associated with an `:artist/country`, without ever finding a set of eids to begin with:

## Not-join Clauses

A *not-join* clause works exactly like a *not* clause, but also allows you to specify which variables should unify with the surrounding clause; only this list of variables needs binding before the clause can run.

*var* specifies which variables should unify.

### Not-join Example

In this next query, which returns the number of artists who didn't release an album in 1970, `?artist` is in the *var* clause and must unify with the surrounding query. `?release` is used only inside the *not-join* clause and will not unify.

### Multiple Clauses In not Or not-join

When more than one clause is supplied to not or not-join, they are evaluated as if connected by an [and clause](https://docs.datomic.com/query/#and-clause).

The following query counts the number of releases named "Live at Carnegie Hall" that were not by Bill Withers.

## Or Clauses

With *or* clauses, you can express that one or more logic variables inside a query satisfy at least one of a set of predicates. An *or* clause constrains the result to tuples that satisfy at least one of its *clause* or *and-clauses*

The following query uses an *or* clause to find the count of all vinyl media by listing the complete set of media that make up vinyl in the *or* clause:

### Or Clause Example

### Or Clause Variables

All clauses used in an *or* clause must use the same set of variables, which will unify with the surrounding query. This includes both the arguments to nested expression clauses as well as any bindings made by nested function expressions. Datomic will attempt to push the *or* clause down until all necessary variables are bound, and will throw an exception if that is not possible.

### How Or Clauses Work

One can imagine *or* clauses turn into an invocation of an anonymous rule whose predicates comprise the *or* clauses. As with rules,*src-vars* are not currently supported within the clauses of *or*, but are supported on the *or* clause as a whole at top level.

## And Clause

```
and-clause                 = [ 'and' clause+ ]
```

Inside an *or* clause, you may use an *and* clause to specify conjunction. The *and* clauses are not available (or needed) outside of an *or* clause, since conjunction is the default in other clauses.

### And Clause Example

The following query uses an *and* clause inside the *or* clause to find the number of artists who are either groups or females:

## Or-join Clause

An *or-join* clause is similar to an *or* clause, but it allows you to specify which variables should unify with the surrounding clause; only this list of variables needs binding before the clause can run. `[variable+]` specifies which logic variables should unify.

### Or-join Example

In this query, which returns the number of releases that are either by Canadian artists or released in 1970, `?artist` is only used inside the *or* clause and doesn't need to unify with the outer clause.*or-join* is used to specify that only `?release` needs unifying.

## With Clauses

A *with-clause* considers additional variables not named in the *find-spec* when forming the basis set for a query result. The with variables are then removed, leaving a bag (not a set!) of values to be consumed by the *find-spec*. This is particularly useful when finding aggregates.

### Example with-clause

Consider the following example, where our intention is to find out the years of every Bob Dylan release.

Bob Dylan was clearly a more prolific artist than this. The query returned *the years Bob Dylan released* records, rather than the release years of each of the records.

Set logic combines all of the releases that came out in the same year, and this is not what is wanted for the particular query.

A *with-clause* correct this query:

This result is more like what we wanted. This is a list of the year of *each release* between 1968 and 1973.

## Rules

Datomic datalog allows you to package up sets of `:where` clauses into named *rules*. These rules make query logic reusable, and also composable, meaning that you can bind portions of a query's logic at query time.

### Defining a Rule

```
rule                       = [ [rule-head clause+]+ ]
rule-head                  = [rule-name rule-vars]
rule-name                  = plain-symbol
rule-vars                  = [variable+ | ([variable+] variable*)]
```

As with transactions and queries, rules are described using data structures. A rule is a list of lists. The first list in the rule is the *rule-head*. It names the rule and specifies its *rule-vars*. The rest of the lists are clauses that make up the body of the rule.

In the example below, the rule-head is `track-info`, and the three clauses of the rule body join artists to name and duration information about tracks:

### Using a Rule

```
inputs                     = ':in' (src-var | binding | pattern-name | rules-var)+
rules-var                  = the symbol "%"
rule-expr                  = [ src-var? rule-name (variable | constant | '_')+]
```

You have to do two things to use a rule in a query. First, you have to pass a *rule set* (collection of rules) as an input source and reference it in the *:in* section of your query using the '%' symbol. Second, you have to invoke one or more rules with a *rule-expr* in the *:where* section of your query.

The example below puts the `track-info` rule into a collection and names the rules with `%`. It then invokes the rule `track-info` by name in the where clause:

### Multiple Rule Heads

Rules with multiple definitions will evaluate them as different logical paths to the same conclusion (i.e. logical OR). In the rule below, the rule name `benelux` is defined three times. As a result, the rule matches artists from any of the three Benelux countries:

### Required Bindings

Rules normally operate exactly like other items in a where clause. They must unify with the variables already bound, and must bind any variables not already bound.

But sometimes you know that a rule will only be correct, or only be efficient, if some variables are already bound. You can require that some variables be bound before a rule can fire by enclosing the required variables in a vector or list as the first argument to the rule. If the required variables are not bound, Datomic will report an incorrect [anomaly](https://docs.datomic.com/client/client-api.html#anomalies).

In the example below, the `track-info` rule has `?artist` as a required binding, and a query that does not bind `?artist` fails:

This can be fixed easily:

### Rule Database Scoping

By default, rules operate against the default database named by `$`. As with other *where* clauses, you may specify a database as a `src-var` before the rule-name to scope the rule to that database. Databases cannot be used as arguments in a rule.

The example below passes in two sources: the `$mbrainz` database, and an `$artists` relation. Every *where* clause must therefore begin with a `src-var` name:

### Rule Generality

In all the examples above, the body of each rule is made up solely of data clauses. However, rules can contain any type of clause that a where clause might contain: data, expressions, or even other rule invocations.

**Next:**[Pull](https://docs.datomic.com/query/query-pull.html)