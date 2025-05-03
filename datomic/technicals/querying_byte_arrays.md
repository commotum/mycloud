---
title: "Querying on Byte Array Attributes | Datomic"
source: "https://docs.datomic.com/tech-notes/querying-byte-array.html"
author:
published:
created: 2025-05-03
description: "Learn how to efficiently query byte array attributes on Datomic."
tags:
  - "clippings"
---
Hide All Examples

## Querying on Byte Array Attributes

The equality semantics of byte arrays in Java are those of identity, not value, equality. This can be confusing when using byte arrays in datalog queries since datalog queries match using value equality semantics. Consider the following example.

- First, we do some setup, creating a simple schema with just one-byte array attribute:
- Next, a few entities with two-byte arrays with different object identities but equivalent values:
- Clojure's clojure{(=)} function called with these two-byte arrays as arguments returns false:
- Therefore running the following query returns the empty set:
- Using java.util.Arrays/equals to test for equality, instead of datalog's built-in matching returns the expected result: