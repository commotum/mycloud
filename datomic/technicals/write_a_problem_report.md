---
title: "Writing a Problem Report | Datomic"
source: "https://docs.datomic.com/tech-notes/writing-a-problem-report.html"
author:
published:
created: 2025-05-03
description: "Learn how to write an effective problem report for Datomic. Follow our guidelines to create helpful troubleshooting."
tags:
  - "clippings"
---
## Writing a Problem Report

Datomic is a database, so problem reports about Datomic tend to be about putting data in, getting data out, or both. This guide will help you turn unexpected Datomic behavior into a reproducible problem report.

## Anatomy of a Report

A reproducible problem report (hereafter just "report") contains the following elements:

- **Environment**: the context in which the problem occurred. This needs to include everything necessary for a third party to reconstruct the environment.
- **History**: the steps to go from a starting environment to the moment a problem occurs.
- **Expectation**: what you expected to happen.
- **Actual**: what actually happened.
- **Evidence**: how do you know what happened.
- **Impact**: what are the effects and severity of the problem?

A report is also noticeable for what it does **not** contain:

- Analysis
- Attempts to assign causes and effects
- Recommended courses of action
- Judgment, This is the correct pre-analytic posture, and it will also improve the mood of your colleagues.

Analysis is important too, but when you are reporting try to stay in "just the facts" mode. As Sherlock Holmes says, *"It is a capital mistake to theorize before one has data. Insensibly one begins to twist facts to suit theories, instead of theories to suit facts".*

> Note that we are carefully avoiding the use of the word "bug". We save "bug" for problems where we have a hypothesis, a reproducing test, and a fix.

## Writing a Good Report

When you first encounter a problem, you are typically in the middle of something bigger. To write a good report, you must winnow that bigger thing down to something that is both concise and precise. Concision here is about the number of steps: if your problem history contains N>1 steps, search for a problem history with fewer steps until you have the smallest number of steps that still reproduce.

Precision is how completely you specify each step. Ideally, you will provide the exact data for each step. If you attempt to describe the data (instead of just enumerating it) it is very easy to introduce presumptions that generalize the problem in ways not (yet) supported by the evidence.

Resist this.

## Clojure and Datomic Make Reporting Easy

Clojure and Datomic are particularly well suited to problem reporting, for three reasons:

- **Everything** is immutable data: including queries, transactions, and database values. So program state has a direct data representation, without the need for complex and error-prone recipes for getting the system into the state where the problem occurs.
- Clojure programs are made of **generic** data. Domain entities are represented as plain maps, lists, strings, etc. This eliminates the need for complex and error-prone "domain object" or "model" code. In other words, it is easy to simplify Datomic problem reports to a small number of operations with generic, immutable data because that is what Datomic programs already look like.
- Clojure programs are [dynamic and programmable](https://clojure.org/about/dynamic). When you are homing in a problem, you can sit inside your program at a REPL, quickly [carving out the parts of the program](https://youtu.be/Qx0-pViyIDU?t=1718s) that are irrelevant to the problem at hand.

## Getting Concise

Reports should include only the steps necessary to trigger the problem. In particular, they typically will **not** include:

- Test frameworks
- (In)convenience wrapper libraries
- Build automation
- Dev tools

The "reduce the problem steps idea" should be applied not just to steps, but also to dependencies. If you don't think a library is part of the problem, [it should not be in the report](https://www.youtube.com/watch?v=FihU5JxmnBg&t=1792s). (Taking this from the opposite direction, most Datomic problem reports should, after iteration, include an environment that depends only on Datomic.)

Below are some specific tips for how to make a Clojure or Datomic repro more concise and precise.

## Clojure Tips

- Functions should depend on their arguments, not on data in top-level defs.
- Try to reduce or eliminate control flow. If the repro branches, can you eliminate some branches entirely.
- Try to minimize the number of namespaces your repro depends on.

## Datomic Tips

- The state preceding a problem should generally be represented as a single database value; or the transaction data to build a value.
- Try to call `d/db` only once in the steps of a problem report.
- Give every function in a problem report a doc string that explains the function's purpose, inputs, and outputs.
- Naming the nouns is just as important as naming the verbs. Put query and transaction data in vars, and give them good names.
- Every Datomic API call in a repro should either contribute to the problem or be removed from the repro. (If this sounds like I am just restating the earlier point I made about reducing the number of steps in a repro, you are damn right I am! This mechanical exercise alone would probably redirect or eliminate half of all problem reports).
- Datomic is a distributed system, with many potential processes: transactors, peers, clients, storage services, and cluster nodes. When you describe the environment and steps for a problem, be specific about which process(es) you are describing.
- If your repro involves more than one process, try to shrink it repro down to a single process, with either [dev-local](https://docs.datomic.com/cloud/dev-local.html) (for client applications) or an [in-memory database](https://docs.datomic.com/operation/peer-getting-started.html#connecting) (for peer applications).