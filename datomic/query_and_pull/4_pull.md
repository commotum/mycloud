---
title: "Pull | Datomic"
source: "https://docs.datomic.com/query/query-pull.html"
author:
published:
created: 2025-05-03
description: "Learn how pull collect information about entities in Datomic."
tags:
  - "clippings"
---
Hide All Examples

## Pull

Pull is a declarative way to make hierarchical (and possibly nested) selections of information about entities. Pull applies a *pattern* to a collection of entities, building a map for each entity. Pull is available

- via the standalone `pull` API [Peer](https://docs.datomic.com/clojure/index.html#datomic.api/pull) | [Client](https://docs.datomic.com/client-api/datomic.client.api.html#var-pull)
- via the [standalone `pull-many` API in Peer](https://docs.datomic.com/clojure/index.html#datomic.api/pull-many)
- as a [find specification](https://docs.datomic.com/query/query-data-reference.html#pull-expressions) in query

Patterns support [forward](https://docs.datomic.com/query/#attribute-names) and [reverse](https://docs.datomic.com/query/#reverse-lookup) attribute navigation,[wildcarding](https://docs.datomic.com/query/#wildcard-specifications), [nesting](https://docs.datomic.com/query/#nesting),[recursion](https://docs.datomic.com/query/#recursive-specifications),[naming control](https://docs.datomic.com/query/#as-option),[transformation](https://docs.datomic.com/query/#xform-option), [defaults](https://docs.datomic.com/query/#default-option), and [limits](https://docs.datomic.com/query/#limit-option) on the results returned. Entities can be passed to pull as any kind of [entity identifier](https://docs.datomic.com/transactions/transaction-data-reference.html#entity-identifiers): [entity ids](https://docs.datomic.com/transactions/transaction-data-reference.html#eid), [idents](https://docs.datomic.com/transactions/transaction-data-reference.html#ident), or [lookup refs](https://docs.datomic.com/transactions/transaction-data-reference.html#lookup-ref).

Pull patterns are written in the [Extensible Data Notation](https://github.com/edn-format/edn) (edn), which is programming language neutral. In programs, you can create patterns programmatically out of your basic language data types, e.g. Java Strings, Lists, and Maps. Alternatively, you can pass the pattern argument as a serialized edn string.

The results below are also written with edn, and they use an ellipsis`...` where large results have been elided for brevity.

If you want to follow along at a REPL, most of the examples on this page use the [mbrainz-subset](https://github.com/Datomic/mbrainz-importer#readme) database and can be found in the [Day of Datomic Cloud](https://github.com/cognitect-labs/day-of-datomic-cloud/blob/master/tutorial/pull.repl) repository and are covered in the [Day of Datomic Cloud](https://youtu.be/qplsC2Q2xBA?t=775) video sessions.

## Example Notes

The examples will use the following:

```
Copy(def dylan-harrison-sessions (ffirst (d/q '[:find ?release
                                           :where [?zimbo :artist/name "Bob Dylan"]
                                                  [?magpie :artist/name "George Harrison"]
                                                  [?release :release/artists ?zimbo]
                                                  [?release :release/artists ?magpie]]
                                         db)))

(def ghost-riders (ffirst (d/q '[:find ?track
                                 :in $ ?release ?trackno
                                 :where [?release :release/media ?medium]
                                        [?medium :medium/tracks ?track]
                                        [?track :track/position ?trackno]]
                               db
                               dylan-harrison-sessions
                               11)))

(def led-zeppelin (ffirst (d/q '[:find ?artist
                                 :where [?artist :artist/name "Led Zeppelin"]]
                               db)))

(def mccartney (ffirst (d/q '[:find ?artist
                              :where [?artist :artist/name "Paul McCartney"]]
                               db)))

(def concert-for-bangla-desh (ffirst (d/q '[:find ?release-name
                                            :where [?release-name :release/name "The Concert for Bangla Desh"]]
                                          db)))

(def dark-side-of-the-moon (ffirst (d/q '[:find ?release-name
                                            :where [?release-name :release/name "The Dark Side of the Moon"]]
                                          db)))
```

## Pull Grammar

### Grammar Syntax

```
'' literal
"" string
[] = list or vector
{} = map {k1 v1 ...}
() grouping
| choice
+ one or more
```

### Pull Pattern Grammar

```
pattern             = [attr-spec+]
attr-spec           = attr-name | wildcard | map-spec | attr-expr
attr-name           = an edn keyword that names an attr
map-spec            = { ((attr-name | attr-expr) (pattern | recursion-limit))+ }
attr-expr           = [attr-name attr-option+] | legacy-attr-expr
as-expr             = [attr-name ":as" any-value]
limit-expr          = [attr-name ":limit" (positive-number | nil)] 
default-expr        = [attr-name ":default" any-value]
xform-expr          = [attr-name ":xform" symbol]
attr-option         = as-expr | limit-expr | default-expr | xform-expr
wildcard            = "*" or '*'
recursion-limit     = positive-number | '...'
legacy-attr-expr    = legacy-limit-expr | legacy-default-expr
legacy-limit-expr   = [("limit" | 'limit') attr-name (positive-number | nil)]
legacy-default-expr = [("default" | 'default') attr-name any-value]
```

Terminals such as "limit" can be strings, but where languages have a symbol type you should prefer the idiomatic symbolic type, e.g. `(limit :friends 100)` in Clojure instead of `("limit" "friends" 100)`.

## Patterns

A pattern is a list of Attribute Specifications.

```
pattern            = [attr-spec+]
```

## Attribute Specifications

```
attr-spec           = attr-name | wildcard | map-spec | attr-expr
attr-expr           = [attr-name attr-option+] | legacy-attr-expr
attr-option         = as-expr | limit-expr | default-expr | xform-expr
wildcard            = "*" or '*'
recursion-limit     = positive-number | '...'
legacy-attr-expr    = legacy-limit-expr | legacy-default-expr
legacy-limit-expr   = [("limit" | 'limit') attr-name (positive-number | nil)]
legacy-default-expr = [("default" | 'default') attr-name any-value]
```

An attribute spec specifies an attribute to be returned, and (optionally) what additional transformations to perform on the value before it is returned. Attribute specs can be attribute names, wildcards, map specs, or attribute expressions.

## Attribute Names

```
attr-name          = an edn keyword that names an attr
```

An attribute spec names an attribute, with an optional leading underscore on the name part of the keyword to reverse the direction of navigation.

### Attribute Name Example

The following pattern uses two attribute names to return an `:artist/name` and `:artist/startYear`, pulling on `led-zeppelin`:

### Reverse Lookup

An underscore prefix (`_`) on the name part of an attribute ident causes the attribute to be navigated in reverse. If you name your attributes with an underscore leading the name portion of the keyword, those attributes cannot be used with reverse lookup.

Normally, `pull` returns a map of attributes and values (which may be nested entities) selected from the entity supplied as the last argument to the `pull` call. For example, `(d/pull db [:release/artists] led-zeppelin)` would attempt to pull the `:release/artists` attribute from the `led-zeppelin` entity.

The underscore prefix reverses the direction of a `pull`, so `(d/pull db [:release/_artists] led-zeppelin)` will pull all of the entities that have a `:release/artists` attribute with the value of `led-zeppelin`.

### Attribute Name Reverse Lookup Example

As an exploratory measure `led-zeppelin` is pulled with a [wildcard](https://docs.datomic.com/query/#wildcard-specifications). `:release/artists` is not part of the result.

You can navigate 'backwards' from `:release/artists` to find the releases with a reference to `led-zeppelin` by pulling`:release/_artists`

Attributes like `:artist/startYear` or `:artist/name` would not work with reverse lookup as there is no reference value.

```
Copy(d/pull db '[* :release/_artists] led-zeppelin)
```
```
{:artist/sortName "Led Zeppelin",
 :artist/name "Led Zeppelin",
 :artist/type #:db{:id 70746976177619070, :ident :artist.type/group},
 :artist/country #:db{:id 47850746040811801, :ident :country/GB},
 :artist/gid #uuid "678d88b2-87b0-403b-b63d-5da7465aecc3",
 :artist/endDay 25,
 :artist/startYear 1968,
 :artist/endMonth 9,
 :release/_artists
 [#:db{:id 12591607161327185}   ;; ----.
  #:db{:id 13611953951903311}   ;;     | 
  #:db{:id 14614708556444205}   ;;     | 
  #:db{:id 20349761206917151}   ;;     | 
  #:db{:id 27505382880490028}   ;;     | 
  #:db{:id 30606005670815267}   ;;     | 
  #:db{:id 36437815344539172}   ;;     | 
  #:db{:id 38834750693087262}   ;;     | 
  #:db{:id 43703388180886059}   ;;     |-- Releases
  #:db{:id 43910096366902013}   ;;     | 
  #:db{:id 45994770413170389}   ;;     | 
  #:db{:id 49236130691853680}   ;;     | 
  #:db{:id 51514318784597586}   ;;     | 
  #:db{:id 54157544737773785}   ;;     | 
  #:db{:id 58683134597703205}   ;;     | 
  #:db{:id 66718365573484112}   ;;     | 
  #:db{:id 71402285107818196}], ;; ----' 
 :artist/endYear 1980,
 :db/id 2458507999719892}
```

## Map Specification

```
map-spec           = { ((attr-name | limit-expr) (pattern | recursion-limit))+ }
limit-expr         = [("limit" | 'limit') attr-name (positive-number | nil)]
recursion-limit    = positive-number | '...'
```

You can explicitly specify the handling of referenced entities by using a map instead of just an attribute name. The simplest map specification is a map specifying a specific `pattern` for a particular `attr-name`.

### Map Specification Example

The `:track/artists` attribute appears in a map spec, causing the`:db/id` and `:artist/name` to be sub-pulled for each artist on the track `ghost-riders`.

### Map Specification Nesting Example

Map specs can nest arbitrarily. The pattern below pulls `concert-for-bangla-desh` 's media's tracks' titles and artists' names:

## Attribute Spec

```
attr-spec           = attr-name | wildcard | map-spec | attr-expr | xform-expr
attr-expr           = [attr-name attr-option+] | legacy-attr-expr
attr-option         = as-expr | limit-expr | default-expr
```

You can use an attribute spec to declare various aspects of the corresponding values returned by Pull.

Note that the pattern appears in a seq. This necessitates that the whole clause be quoted or that the pattern is in a vector.

## :as Option

```
[attr-name ":as" any-value]
```

The `:as` option can be used to declare what an attribute should be renamed to in the result map.

### :as Option Example

The following pattern uses an:as option to pull an `:artist/name`, replacing the key in the result map with the string "Band Name", pulling on `led-zeppelin`.

## :limit Option

```
[attr-name ":limit" (positive-number | nil)]
```

By default, Pull will return the first 1000 values for a cardinality-many attribute, but you can control that by providing either a positive number or `nil for` the:limit option. All values for a cardinality-many attribute will be returned if you explicitly provide a `nil` limit.

### :limit Option Example

To return only 10 of `led-zeppelin` 's tracks:

### :limit Inside a Map Specification Example

Pulling from `led-zeppelin`, you can get a limited set of nested track names with:

### Nil:limit Example

The pattern below returns all of Led Zeppelin's tracks, without limit:

## :default Option

```
[attr-name ":default" any-value]
```

The:default option specifies a value to return if an entity has no value for that attribute.

### :default Option Example

The following select reports a zero:artist/endYear for Paul McCartney (`mccartney`), who is still active:

The default need not be of the same type as the attribute's values:

## :xform Option

The `:xform` option provides the ability to transform the value returned by pull for an attribute.

The `fn` is either a fully qualified function allowed under the `:xforms` key the appropriate edition-specific configuration file, or one of the following built-ins:

- [str](https://clojure.github.io/clojure/clojure.core-api.html#clojure.core/str)
- [keyword](https://clojure.github.io/clojure/clojure.core-api.html#clojure.core/keyword)
- [symbol](https://clojure.github.io/clojure/clojure.core-api.html#clojure.core/symbol)
- [name](https://clojure.github.io/clojure/clojure.core-api.html#clojure.core/name)
- [namespace](https://clojure.github.io/clojure/clojure.core-api.html#clojure.core/namespace)
- [clojure.edn/read-string](https://clojure.github.io/clojure/clojure.edn-api.html#clojure.edn/read-string)

To use additional xform functions in Cloud follow the instructions for adding `:xforms` to [ion-config.edn](https://docs.datomic.com/ions/ions-reference.html#configure). To use additional xform functions in Pro, add the fully qualified function under the `:xforms` key in `resources/datomic/extensions.edn`:

The `fn` takes the value returned from the pull expression, which might be `nil`, and returns a value that will be included in the result instead. The return value needs to be supported by [transit](https://github.com/cognitect/transit-format) (Client API) or [fressian](https://github.com/Datomic/fressian/wiki) (Peer API) without any extension handlers.

[`:default`](https://docs.datomic.com/query/#default-option) values are not transformed by `:xform`, and the `:xform` result takes precedence.

[`cancel`](https://docs.datomic.com/transactions/transaction-processing.html#cancel) can be used to cancel xform functions and throw `ex-info` to the caller.

### :xform Option Example

The following example uses the unqualified symbol `str` (from the default functions) to transform the result of pulling the `:artist/endYear` for led-zeppelin from an integer to a string:

## Wildcards

```
wildcard           = '*'
```

The wildcard specification `*` pulls all attributes of an entity, and recursively pulls any [component attributes](https://docs.datomic.com/query/query-pull.html#component-defaults).

### Wildcard Example

The wildcard pulls all the direct attributes of the release. It also recursively pulls `:release/media` because it is a component attribute. It does not recursively pull `:release/artists` or`:release/country`, because those are *not* component attributes.

### Combining Wildcards and Map Specifications

A map specification can be used in conjunction with the wildcard to provide subpatterns for specific attributes.

#### Combining Wildcards and Map Specifications Example

The wildcard pulls all attributes of the `ghost-riders` track, and an explicit map uses the value of `:track/artists` to pull`:artist/name`.

## Recursion Limits

```
recursion-limit    = positive-number | '...'
map-spec           = { ((attr-name | limit-expr) (pattern | recursion-limit))+ }
```

You can provide a positive number in a map specification to limit how deeply Pull should recur when encountering recursive references. You can optionally provide an ellipsis (…) instead of a number allow recursion to arbitrary depth.

If a recursive subselect encounters an entity that it has already seen, it will not apply the pattern, instead returning only the `:db/id` of the entity. Thus recursive select is safe in the presence of cycles.

### Limited Recursion Example

The following (non-mbrainz) specification will pull the first and last names of friends-of-friends up to six degrees of separation from the original entity.

### Unlimited Recursion Example

The following specification will find all reachable friends, which might be most of the friends in the entire database.

### Empty Results

If there is no match between a pattern and an entity, then `pull` will return an empty map:

Non-matching results will be removed entirely from the return map. Even though `ghost-riders` has artists, none of those artists have`:penguins`:

## Pull Results

### Component Defaults

If a pull `attr-name` names a reference attribute, `pull` will return a map for the referenced value. If the attribute is a [component attribute](https://docs.datomic.com/query/query-pull.html#component-defaults), the return map will contain all attributes of the related entity as well.

#### Component Defaults Example

`:medium/tracks` is a component attribute, so pulling `:release/media` will also pull related tracks. The example below pulls from `dark-side-of-the-moon`.

### Non-Component Defaults

If a reference is to a non-component attribute, the default is to pull only the `:db/id`.

#### Non-Component Defaults Example

Pulling `:artist/_{country}` of `:country/GB` returns only the entity ids for the artists from Great Britain:

### Multiple Results

If navigating an attribute might lead to more than one value, the pull result will be a list of the values found. These cases include:

- All forward cardinality-many references
- Reverse references for non-component attributes.

#### Multiple Results Example

Pulling `[:release/media]` of `dark-side-of-the-moon` pulls the values associated with `[:release/media]` and from inside of those results.

### Missing Attributes

In the absence of a default, attribute specifications that do not match an entity are omitted from that entity's result map, rather than e.g. appearing with a `nil` value.

#### Missing Attributes Example

Paul McCartney has an `:artist/name` but not a `died-in-1966`, so only the former appears in a pull result:

## Legacy Attribute Expressions

> NOTE: [Attributes Specifications](https://docs.datomic.com/query/#attribute-with-options) provides a superset of the functionality of Attribute Expressions and is preferred, however `limit` and `default` Attribute Expressions will continue to be supported.

```
attr-expr           = [attr-name attr-option+] | legacy-attr-expr
legacy-attr-expr    = legacy-limit-expr | legacy-default-expr
legacy-limit-expr   = [("limit" | 'limit') attr-name (positive-number | nil)]
legacy-default-expr = [("default" | 'default') attr-name any-value]
```

Attribute specifications can be wrapped in expressions to control the attribute's default or limit. Each is shown below.

## Legacy Limit Expression

```
legacy-limit-expr   = [("limit" | 'limit') attr-name (positive-number | nil)]
```

The legacy limit expression is an alternate syntax for [Limit Option](https://docs.datomic.com/query/#limit-option). Limit Option is preferred.

## Legacy Default Expressions

```
legacy-default-expr = [("default" | 'default') attr-name any-value]
```

The legacy default expression is an alternate syntax for [Default Option](https://docs.datomic.com/query/#default-option). Default Option is preferred.