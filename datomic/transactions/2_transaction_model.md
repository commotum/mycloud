---
title: "Transaction Model | Datomic"
source: "https://docs.datomic.com/transactions/model.html"
author:
published:
created: 2025-05-03
description: "Discover the Datomic transaction model. Understand its structure, concepts, and how to manage data changes effectively."
tags:
  - "clippings"
---
## Transaction Model

This page explains Datomic’s transaction model and the motivations behind its design. It also attempts to preempt common misconceptions.

There are a number of potential causes for confusion when learning the model. First, its declarative semantics are less common and thus unfamiliar. Second, Datomic some constructs superficially resemble constructs of e.g. SQL databases, which are very different in that they rely on imperative manipulation of a mutable database. Third, Datomic often names data and functions with verbs which may suggest operations where there are none.

## It’s All About Information

A Datomic database is *information*, specifically a set of atomic immutable facts. Because “fact” has many casual meanings, we call facts in Datomic *datoms*. There are two kinds of datoms, *additions* and *retractions*, named via `:db/add` and `:db/retract` in transaction data. Each datom associates an entity (E) with a value (V) via an attribute (A), similar to the [subject/predicate/object of RDF](https://en.wikipedia.org/wiki/Semantic_triple). In the example below, the entity Stu is related to the value `“pizza”` by the attribute `:likes`.

A transaction is *information*, specifically a set of datoms written as above. A Datomic transaction is [declarative](https://en.wikipedia.org/wiki/Declarative_programming). The [d/transact](https://docs.datomic.com/clojure/index.html#datomic.api/transact) API atomically accrues a transaction to a database. On their own, the datoms of a transaction ‘do’ nothing. They could instead be considered mere clauses named:

A *database value* is the set of all datoms ever added to the database. It only accrues new information (like a log or ledger), and only via transactions. *A database is not a set of places that get updated*. The word value emphasizes that databases, like datoms, are immutable. For brevity, database value is often shorthanded as *db value* or even *db*.

## d/with and d/transact

Datomic is a *functional* database: databases are immutable values and API operations other than (create/delete?) and d/transact are *pure functions without side effects*. Even d/transact is built upon the pure function [d/with](https://docs.datomic.com/clojure/index.html#datomic.api/with), which takes a database value and a set of information (held to be true at a point in time), and returns a new database value that includes, via accretion, that new information. d/with enforces all of Datomic's semantic guarantees, e.g. it checks the information set for internal consistency, validates the information set against data already in the database, unifies entity ids, and assigns time t.

The declarative, set-oriented nature of d/with radically simplifies reasoning about data. The only states of the world are complete and domain-valid database values. You never have to worry about the order things happened inside a transaction, because there is *and can be* no order. E.g. d/with validates each datom against the entire information set. This can only be done with the full set in hand and no presumption of order.

A transaction, as a noun, is the information set accrued to a database by d/with. Transact, as a verb, is the logical operation of atomically accruing an information set to a database. In Datomic, d/transact is nothing more then the composition of d/with with a durable swap operation, where the Datomic connection is the [reference type](https://clojure.org/about/state#_clojure_programming). A Datomic database connection is like a turbocharged [atom](https://clojure.org/reference/atoms) that is durable, fully [ACID](https://docs.datomic.com/transactions/acid.html), holds values larger than main memory, automatically distributes to an arbitrary number of peer processes, and provides a declarative, logic-based query language.

At the application level, a transaction is a way to record in the database something that happened in your organization – a purchase, registration, event etc. – by recording the ‘facts’ of the event. Datomic is like a ledger. There are no updates, only appends, and no read/writeable ‘places’.

Any particular value of a database is the product of the immediate predecessor value and the application (in toto) of a single transaction. The only 'effect' supported by a Datomic db is the acceptance of a complete set of transaction data at the end of [d/transact](https://docs.datomic.com/clojure/index.html#datomic.api/transact). There are no smaller effects or operations.

## Application Correctness

Programs may wish to enforce business-rules validations at transaction boundaries. Datomic supports such validations with [entity specs](https://docs.datomic.com/schema/schema-reference.html#entity-specs) which have access to db-after, the (proposed) end-of-transaction database value.

Programs may wish to generate, transform or validate input data with reference to data already in the database. Datomic supports such transformations and validations via [transaction functions](https://docs.datomic.com/transactions/transaction-functions.html), which are pure functions in the 'functional programming with values’ sense. A transaction function is passed the value of the db-before (this transaction), and its result is transaction data that is added to the other data in the transaction (but not *incorporated* in the db until tx completion). Thus transaction functions always produce the same result regardless of the order in which they appear, and preserve the declarative nature of Datomic transactions. They are not stored procedures.

One way to think about transaction functions is that they are like the helper functions one might run on the peer/client when creating the initial transaction data. Like those helpers, they only create data, they are not operations affecting a db. Unlike helpers run on the peer, transaction functions are run on the transactor and are supplied with the db-before, the value of the database immediately preceding the transaction in which they are invoked. This allows you to (functionally) increment values, confirm prerequisites etc. that you couldn’t do on the peer, since you can’t know beforehand which db-value your tx will create the successor of.

Thus a Datomic transaction function, however named (`compare-and-swap`,`create-customer` etc), is not an 'operation' modifying a database, nor a grouping of such operations, and does not ‘do’ anything. The verb-like names indicate the purpose of the data, but, like pure functions named by verbs (e.g. Clojure's `drop` and `take`), don’t imply any effects.

## Integrity and Composition

Transactions are atomic and take effect at a monotonic point in time; therefore, they have integrity, in the sense of "being complete or undivided." The information set of a transaction can be neither split nor combined. Splitting a transaction would incorrectly assert two different time points where there is only one, while combining two transactions would have the opposite problem. Such splits and combinations might violate any number of other domain constraints as well.

The indivisibility of transactions is a powerful guarantee, directly analogous to real-world contracts. When parties agree to a contract, they agree to all provisions of the contract at once, and would not in general be willing to agree to only an arbitrary sub- or superset of the provisions. (The fact that I am willing to *sell* you my house does not mean that I am willing to *give* you my house.) Like Datomic transactions, real-world contract provisions must be written in some order but that order is incidental: Contracts take effect all at once.

SQL DML is a time-extensive ordered batch of read-write operations, and the "composition" of such batches is their concatenation: DOabc + DOdef = DOabcdef. Datomic transactions are sets of assertions at a point and time and cannot be composed like that: info-true-at-Tj + info-true-at-Tk = info-true-at-T??? Nor can they be decomposed into sub time - there is no time within a Datomic transaction, it represents a point. Such re-use is too brittle to deserve the name "composition" as DML does not, and could not, guarantee that the resulting database states will be domain-correct.

Transaction data can be large and complex. You cannot split transactions into smaller transactions without risk of violating their semantics. And you cannot decompose them operationally because there are no operations; Datomic eschews the loss of integrity inherent in an operational approach. So what answer does Datomic provide for managing complex transaction data? Declarative and functional programming.

Datomic transaction functions and entity specs bring the power of declarative and functional programming to the challenge of assembling and validating transaction data. Rather than a limited, special purpose DML, you have the functional power of Clojure. Further, you have declarative datalog on database values that are always in a known valid state. In Datomic, composition is of functions and declarative queries *inside* a transaction function or entity spec. Composition *across* transaction functions and entity specs is unnecessary and in fact impossible; their return values do not and could not support composing them.

## Why Do Things This Way?

Datomic is designed to facilitate creating correct applications and reasoning about the information they produce. [d/transact](https://docs.datomic.com/clojure/index.html#datomic.api/transact) and [d/with](https://docs.datomic.com/clojure/index.html#datomic.api/with) are the only operations/functions that produce db values. Given a datomic database value you know that:

- It is the set of all datoms ever added to the database, all of which are accessible.
- Each datom is associated with a transaction and its monotonic timestamp 't'.
- Any particular value of a database is the product of the immediate predecessor value and the atomic addition of a single transaction (in toto) representing a set of facts true at a single (indivisible!) point in time.
- Transactions (and the log of their assertions) are reified, and can have assertions made about them (provenance etc), and you can get from every datom in Datomic to the tx that asserted it and vice-versa.

All Datomic APIs (including helpers like transaction functions and entity specs) pass and support only database values with the full semantics above. There is only the full API, there is no smaller/restricted imperative [Data Manipulation Language](https://en.wikipedia.org/wiki/Data_manipulation_language) (DML) supporting smaller than tx ‘operations’, stored ‘procedures’ which group ‘operations’, mid-tx db ‘states’, mid-tx concurrency semantics, sub-tx time etc., and *there could not be without compromising the properties above.*

On the flip side, neither are you constrained by the limited semantics, operations and fragility of an imperative DML - you can always leverage the full power of Clojure or Java while developing functions that operate on a Datomic db since a) it is immutable and b) your code cannot have effects but can only construct data, thus the engine need not understand the semantics of your code in order to enforce R/W invariants etc. You need not be concerned with constructing an ordered script when composing the data in a transaction.

Since Datomic programmers will only ever see database values incorporating complete transactions, they will thereby enjoy working with data that always has application-level correctness and consistency, a much stronger notion than the ‘correctness’ notions of read/write consistency modes of imperative, place-oriented read/write transactions and the literature thereof. This makes it substantially more straightforward working with and reasoning about Datomic vs composing mutating operations, db isolation levels etc.

The tradeoffs and benefits of Datomic’s approach largely co-align with those of declarative/functional vs procedural programming.[Like Clojure](https://clojure.org/about/state), Datomic prioritizes building simple, robust systems about which you can reason more readily.