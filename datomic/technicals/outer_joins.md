---
title: "Outer Joins | Datomic"
source: "https://docs.datomic.com/tech-notes/outer-joins.html"
author:
published:
created: 2025-05-03
description: "Explore how to perform outer joins with different queries in Datomic."
tags:
  - "clippings"
---
## Outer Joins

In the relational database world, outer joins allow you to return relations even when data is missing from one side of a join. For example, you might want all of the [Mbrainz](https://github.com/Datomic/mbrainz-importer#readme) artists and their start years, including artists who do not even have a start year.

In Datomic, you can find the entities you want with [datalog](https://docs.datomic.com/query/query-data-reference.html), and then make an independent decision about which details you want to [pull](https://docs.datomic.com/query/query-pull.html). The following example uses a query to find the artists, and then plugs in a pull pattern to get both the artist name and start year:

The query/pull separation also makes it easy to reuse query and pull logic independently.

Datomic also includes the [get-else query function](https://docs.datomic.com/query/query-data-reference.html#get-else), which is closer to a literal outer join in that you can reference a possibly-missing attribute directly in the datalog, specifying an alternate value when the attribute is missing. The example below replaces a missing start year with "Unknown":

Check the [full code](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/master/doc-examples/outer_join.clj) for this example in the [Day of Datomic Cloud repo](https://github.com/cognitect-labs/day-of-datomic-cloud#readme).