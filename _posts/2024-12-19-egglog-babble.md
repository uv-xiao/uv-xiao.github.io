---
layout: post
title: use babble for egglog
date: 2024-12-19 00:00:00
description:
tags:
categories:
tabs: true
thumbnail:
mermaid:
  enabled: true
  zoomable: true
toc:
  beginning: true
  # sidebar: left
pretty_table: true
tikzjax: true
pseudocode: true
---

# egg-babble

## egg v.s. egglog

egglog = egg + datalog, it's a logic programming language plus a Rust library. egg is just a Rust library. egglog has more features than egg. See [egglog paper](https://dl.acm.org/doi/10.1145/3591239) for details.

## babble

babble = e-graph-based anti unification. Generally, it finds common patterns (as libraries, or named *abstractions*) in an e-graph, and then conducts *extraction* to apply the library to get compressed corpus.

Read [babble paper](https://dl.acm.org/doi/10.1145/3571207) for details. Here is a more accessible [lecture](https://inst.eecs.berkeley.edu/~cs294-260/sp24/2024-03-06-babble).

## bridge egglog and babble

Babble is based on egg rather than egglog. However, we want to enjoy the features of egglog. So, we need to bridge egglog and babble.

First, we have a look at how babble uses egg.

The core struct of babble is [LearnedLibrary](https://github.com/dcao/babble/blob/115f920db52f124fd7247d1f80e811f3784e6896/src/learn.rs#L92), defined as:


```rust
/// A `LearnedLibrary<Op>` is a collection of functions learned from an
/// [`EGraph<AstNode<Op>, _>`] by antiunifying pairs of enodes to find their
/// common structure.
///
/// You can create a `LearnedLibrary` using [`LearnedLibrary::from(&your_egraph)`].
#[derive(Debug, Clone)]
pub struct LearnedLibrary<Op, T> {
    /// A map from DFTA states (i.e. pairs of enodes) to their antiunifications.
    aus_by_state: BTreeMap<T, BTreeSet<PartialExpr<Op, T>>>,
    /// A set of all the nontrivial antiunifications discovered.
    nontrivial_aus: BTreeSet<PartialExpr<Op, Var>>,
    /// Whether to also learn "library functions" which take no arguments.
    learn_constants: bool,
    /// Maximum arity of functions to learn.
    max_arity: Option<usize>,
    /// Data about which e-classes can co-occur.
    co_occurrences: CoOccurrences,
}
```

Briefly, babble "cross_over" DFTA (not important, just consider it as enumerating pairs of enodes; but you can also look at [this discussion](https://github.com/egraphs-good/egg/discussions/104) to understand its relation with e-graph), and find aus (anti-unifications) of enode pairs (`T=(Id, Id)`), stored in `aus_by_state`. Every aus is a `PartialExpr<Op, Var>`, representing AST with holes (variables):
```rust

/// A partial expression. This is a generalization of an abstract syntax tree
/// where subexpressions can be replaced by "holes", i.e., values of type `T`.
/// The type [`Expr<Op>`] is isomorphic to `PartialExpr<Op, !>`.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum PartialExpr<Op, T> {
    /// A node in the abstract syntax tree.
    Node(AstNode<Op, Self>),
    /// A hole containing a value of type `T`.
    Hole(T),
}
/// An abstract syntax tree node representing an operation of type `Op` applied
/// to arguments of type `T`.
///
/// This type implements [`Language`] for arguments of type [`Id`].
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub struct AstNode<Op, T = Id> {
    operation: Op,
    args: Vec<T>,
}
```

Babble uses egg only in two places: to construct a DFTA, and to do [deduplication](https://github.com/dcao/babble/blob/115f920db52f124fd7247d1f80e811f3784e6896/src/learn.rs#L200). So their relation is not tight. 

Whenever we want to use babble for a new "language", we need to define a new `Op` with the `babble::Teachable` trait impelemented. For example (from [flexible-isa](https://github.com/sgpthomas/flexible-isa/blob/5a5fedab8242bbdb9ed880e32df73b589227c36e/src/instruction_select/lang.rs#L27)), `HalideExprOp` has `Teachable` [implemented](https://github.com/sgpthomas/flexible-isa/blob/5a5fedab8242bbdb9ed880e32df73b589227c36e/src/instruction_select/lang.rs#L442). Then, `babble::AstNode<HalideExprOp>` is just the language babble takes.

> Back to the question, how to bridge egglog and babble?
{: .block-tip}

First, egglog's internal data structure [Egraph](https://github.com/egraphs-good/egglog/blob/c61dfaa0f5fcd27bec83c3c3ee81b249d8ffe3b0/src/lib.rs#L428) is not easy for manipulation. Fortunately, egglog provides [egglog::serialize](https://github.com/egraphs-good/egglog/blob/22643065b9fb912322424cfa1e414ac7a977d988/src/serialize.rs#L84) to produce [egraph-serialize](https://github.com/egraphs-good/egraph-serialize) format, which is easy for manipulation. Now, we have [egraph_serialize::Egraph](https://github.com/egraphs-good/egraph-serialize/blob/f303fe1fd26719d4f0042f241581a84213ef5a64/src/lib.rs#L64), and have two ways to go on:

1. design a very simple "language", maybe: `type OurLang=babble::AstNode<OurOp>`, and construct an `Egraph<OurLang, A>` from `egraph_serialize::Egraph`. `OurOp` must include features of [`babble::SimpleOp`](https://github.com/dcao/babble/blob/115f920db52f124fd7247d1f80e811f3784e6896/src/simple_lang.rs#L19). The `A:Analysis<OurLang>` is just a dummy struct, not used by babble. Then, babble returns all aus, which correpond back to `egraph_serialize::Egraph` and thereby to egglog.
2. get rid of egg, and directly use `egraph_serialize::Egraph` to construct a DFTA. I don't think many modifications are needed.

Another question is, how to build correspondence between egglog and egraph-serialize?  The eggcc provides a good example, the [`Extractor`](https://github.com/egraphs-good/eggcc/blob/fe8160c6bc0a4f2e5272d3394a9e2fd30cc0a416/dag_in_context/src/greedy_dag_extractor.rs#L40) is a struct that stores mapping between egglog `Term` and egraph_serialize `NodeId`, 

After finding all aus that correspond to egglog, how to conduct further rewrites and extraction in egglog? We need to implement utilities like [`LearnedLibrary::rewrites`](https://github.com/dcao/babble/blob/115f920db52f124fd7247d1f80e811f3784e6896/src/learn.rs#L161) in egglog by ourselves.

