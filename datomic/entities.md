---
title: "Entities | Datomic"
source: "https://docs.datomic.com/reference/entities.html"
author:
published:
created: 2025-05-03
description: "Understand the concepts of entities in Datomic."
tags:
  - "clippings"
---
## Entities

A Datomic entity provides a lazy, associative view of all the information that can be reached from a Datomic entity id.

The [entity](https://docs.datomic.com/javadoc/datomic/Entity.html) interface provides associative access to:

- All the attribute/value pairs associated with an entity id E
- All other entities reachable as values V from E
- All other entities that can reach E through their values V

Navigation to other entities is recursive, so with thoroughly connected data such as a social network graph, it may be possible to navigate an entire dataset starting with a single entity.

The entity interface is completely generic and can navigate any and all Datomic data.

## Basics

The examples below refer to the following example datoms concerning entity 42, a.k.a. Jane Doe:

![entities-basics.png](https://docs.datomic.com/images/entities-basics.png)

The *entity* function returns an *entity*, given a db value and entity id or lookup ref:

Given an entity, you can then navigate to any of that entity's attributes:

The special attribute *:db/id* provides access to the entity's own id:

If an attribute points to another entity through a cardinality-one attribute, *get* returns another *entity* instance:

If an attribute points to another entity through a cardinality-many attribute, *get* returns a *set* of entity instances. The following example returns all the entities that Jane likes:

If you precede an attribute's local name with an underscore (\_), *get* will navigate backward, returning the *set* of entities that point to the current entity. The following example returns all the entities who like Jane:

Entities do not *exist* in any particular place; they are merely an associative view of all the datoms about some *E* at a point in time. If there are no facts currently available about an entity, Database.entity returns an empty entity, with only a *:db/id*.

## Laziness and Caching

Entity attributes are accessed lazily as you request them. Once you access a particular attribute, the attribute will be cached for the lifetime of that entity instance.

*clojure.core/keys* returns the keys available for an entity, without caching their values.

The [d/touch](https://docs.datomic.com/clojure/index.html#datomic.api/touch) method is a convenience that accesses and caches all the attributes of an entity. In addition, touch also accesses and caches the attributes of any other entities reachable through an attribute whose schema definition includes *:db/isComponent true*.

As an example, consider a database of orders, line items, and products. A line item is a component of an order. A product is related to an order but is not a component of the order. In such a database, touching an order will access the order's attributes, and recursively access all the order's line items. Touching an order will not access the line items' products.

d/touch is a convenience, suitable for interactive exploration, or for when you know that you need all of an entity's information. When this is not the case, it can be more efficient to be explicit and ask for precisely what you need.

Note that none of the entity APIs mandate any communication with a server. Entities are lazy values, backed by a lazy database value in an application process. In particular, entities are not subject to the N+1 select problem, which is an artifact of client/server query architectures.

## Entities and Time

Entities know the point in time on which they are based. Given an entity, you can access the database on which the entity is based:

From the database you can then find the database's basisT, the transactions that contributed to the entity, etc.

Entities represent only a point in time, not the database across time. Notice that the *across time* aspect of the database vanishes when making entities.

![entities-time.png](https://docs.datomic.com/images/entities-time.png)

The point-in-time nature of entities means that entities can be derived from any point-in-time view of a database, i.e. the return values of [d/db](https://docs.datomic.com/clojure/index.html#datomic.api/db), [d/as-of](https://docs.datomic.com/clojure/index.html#datomic.api/as-of), [d/since](https://docs.datomic.com/clojure/index.html#datomic.api/since), and [d/with](https://docs.datomic.com/clojure/index.html#datomic.api/with).

Entities cannot be derived from any time-spanning view of a database, i.e. the return value of [d/history](https://docs.datomic.com/clojure/index.html#datomic.api/history).

## Usage Considerations

Entities are always consistent.

Entities are lazy, immutable values. They are thread-safe and do not require coordination with any other concurrent uses of the same information.

Entities are based on a point in time of the database. Navigation from an entity will always and only reach other entities with that same time basis, allowing extended calculations to be performed without coordination.

Entities are not a mapping layer between databases and application code. Entities are a direct, mechanical translation from database information to associative application access.

Entities are not suitable for existence tests, which should typically be performed via lookup of a [unique identity](https://docs.datomic.com/schema/identity.html).