---
title: "Changing Schema | Datomic"
source: "https://docs.datomic.com/schema/schema-change.html"
author:
published:
created: 2025-05-03
description: "Learn how to manage and modify Datomic schemas. Follow our guide for making schema changes safely."
tags:
  - "clippings"
---
## Changing Schema

Changing an existing schema attribute is similar to defining a new schema attribute: you submit a transaction with the new facts, including the `:db/id` and the new value(s) of the attribute(s).

All changes happen synchronously.

Because Datomic maintains a single set of physical indexes, and supports query across time, a database value utilizes the single schema associated with its *current* basis. Thus traveling back in time does not take the working schema back in time, as the infrastructure to support the past schema may no longer exist.

Attempting a schema change that violates an invariant will cause the transaction to abort with an exception. To enable such change, first change your data so the invariant you want becomes true. For example: if you want to mark an attribute unique, you will need to find and retract any non-unique values for that attribute first.

## Changing a:db/ident

This example changes the `:db/ident` of `:person/name` to be`:person/full-name`.

Idents provide names for things - specifically schema attributes and enumerated values. Both types of names can be changed by changing the schema.

To rename a `:db/ident`, submit a transaction with the `:db/id` and the value of the new `:db/ident`. This change will take place synchronously and will be immediately visible in the database returned by the transaction.

Both the new *ident* and the old *ident* will refer to the entity. Entid will return the same *entity id* for both the new and the old *ident*. Ident will return the new *ident*, so there is asymmetry between what the *entity id* returns and what *ident* returns for the old *ident*.`:db/ident` in the entity map, returned from entity, will be the new *ident*.

We don't recommend re-purposing an old `:db/ident`, but if you find you need to re-use the name for a different purpose, you can define the name again as described in attribute-definition. This re-purposed `:db/ident` will cease to point to the entity it was previously pointing to and ident will return the newly installed entity instead.

## Changing a:db/cardinality Attribute

The example below changes the cardinality of `:person/favorite-food` to many and the cardinality of `:person/email` to single.

When changing from a multi-valued attribute to a single-valued attribute, there must be at most a single value for every entity in the set of current assertions; otherwise, the change will not be accepted and the transaction will fail.

After changing the cardinality of an attribute, entity lookups will return values specified by the new cardinality - either a single value in the case of `:db.cardinality/one` or a set of values in the case of`:db.cardinality/many`. This includes queries against historical databases. An entity from a [`d/as-of`](https://docs.datomic.com/clojure/index.html#datomic.api/as-of),[`d/since`](https://docs.datomic.com/clojure/index.html#datomic.api/since), or [`d/history`](https://docs.datomic.com/clojure/index.html#datomic.api/history) database that has an attribute with multiple values will return a single one of those values if the schema attribute has been changed to be single-valued.

## Changing a:db/isComponent Attribute

The example below changes `:order/line-items` to be a component, and`:customer/orders` to not be a component:

Changing an *isComponent* attribute will cause Datomic to start enforcing the semantics for the new [component](http://blog.datomic.com/2013/06/component-entities.html) value of the attribute. For example, when you set `:db/isComponent` to true, values of that attribute will automatically be retracted by the`:db/retractEntity` transaction function.

## Changing a:db/noHistory Attribute

The example below changes `:person/encrypted-password` to stop retaining history going forward, and changes `:person/address` to start retaining history going forward:

Changing an attribute's `:db/noHistory` to false or retracting it will cause Datomic to start retaining history on that attribute. Setting`:db/noHistory` to true will cause Datomic to stop retaining history. Note that `:db/noHistory` controls the operation of future indexing jobs, and does nothing to current historical values.

## Adding an AVET index to an attribute

If `:db/index` is `true` or `:db/unique` is set, Datomic will maintain values for the attribute in the [AVET index](https://docs.datomic.com/indexes/index-model.html#avet). When you alter an existing attribute to be maintained in the AVET index, the AVET index may not be available immediately. To find out when the AVET index is available, call [sync-schema](https://docs.datomic.com/clojure/index.html#datomic.api/sync-schema).

In Datomic Cloud, all attributes are maintained in the AVET index.

The example below indicates that values for `:person/external-id` need to be maintained in the AVET index.

## Removing an AVET index from an attribute

If `:db/index` is false or unset and `:db/unique` is unset, Datomic will not keep an AVET index.

The example below will retract the unique identity constraint and drop the AVET index for `:person/external-id`.

## Changing a:db/unique Attribute

This example changes the attribute `:person/external-id` to be a unique identity:

To add a uniqueness constraint to an attribute, the following must be true:

- The attribute must have a cardinality of `:db.cardinality/one`.
- If there are values present for that attribute, they must be unique in the set of *current* database assertions.
- In Datomic Pro, Datomic must already be maintaining an AVET index on the attribute.

Adding a unique constraint does not change history, therefore historical databases may contain non-unique values. Code that expects to find a unique value may find multiple values when querying against history.

This example retracts the unique identity constraint on`:person/external-id` going forward:

If `:db/unique` is retracted, Datomic will stop enforcing the uniqueness constraint starting on the next transaction.

> You can never alter *:db/valueType*, *:db/tupleAttrs*, *:db/tupleTypes*, or *:db/tupleType*.