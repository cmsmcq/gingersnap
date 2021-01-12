# General notes on test-case generation

2021-01-11

This document is intended as a sort of high-level guide to some issues
relating to generating test cases for a language *L* defined by a
grammar *G*.

Wherever possible, details are suppressed and pushed into other
documents focused on specific questions.


## Requirements / desiderata

The goal in creating tests is to find as many errors as possible with
the least effort possible. Effort has two forms: the effort needed to
create the test cases, and the time and other costs of running them.

(Some authors seem to want to find as many errors as possible with *as
few tests* as possible, but at least in the short run I think what
needs minimization is effort, not number of tests.)

When we generate tests from a grammar (I am thinking at the moment
mostly of test cases for testing parsers, but I think the principles
are the same when generating test cases for any program whose input is
defined completely or partially by a grammar), the requirements and
desiderata include:

* We want the generation of test cases to be as automatic as
possible, to reduce the required effort.   Ideally, I'd hand a grammar
to a program and get test cases back, but I'll settle for less if I have to.

* We want the test cases to be thorough and to provide good coverage
of the grammar. One reason to generate test cases automatically is
that automated processes don't suffer from boredom (or if they do,
they don't show it) and so can be more thorough than hand-generated
test cases are likely to be.

* We want both positive and negative tests: test cases which should be
accepted as sentences in *L* and test cases which should be rejected
as non-sentences.

* In tests for ixml parsers, positive test cases should ideally have
either raw parse trees or abstract syntax trees or both. (By 'abstract
syntax trees' in the ixml context I mean the XML described by the ixml
annotations which specify when nonterminals should become elements or
attributes or be invisible, and when character data should be
preserved and when it should be suppressed.)

* We would like to avoid redundant test cases where possible. That is,
we would like to avoid having multiple tests testing 'the same thing'.

"Thoroughness", "good coverage", and "redundancy" are all perhaps
intuitively plausible terms, but they don't have good formal
definitions.


## Regular languages 

If *L* is a regular language, then it can be defined by a regular
expression, a regular grammar, or a finite-state automaton. The
regular grammar and the FSA are isomorphic; the grammar can be viewed
as a way of writing down the FSA and the FSA can be viewed as a way of
visualizing the regular grammar.

From a regular expression, positive test cases can be generated and
various coverage measures can be defined (separate discussion needed).
But I do not know a reliable way to generate negative test cases
directly from a regular expression.

From an FSA, positive test cases can be generated and various coverage
measures can be defined (separate discussion needed). To generate
negative test cases, the FSA can be made deterministic and error
transitions supplied so that transitions are defined out of every
state on every symbol. The FSA can then be made to generate the
complement of *L*; every sentence in the complement of *L* is of
course a negative test case for *L* itself.

Note that negative test case generation from a nondeterministic FSA is
not reliable, because the input may also describe another path which
leads to an accept state.

Separate documents needed on:

* test-case generation from regular expressions
* test-case generation from FSAs and regular grammars

## Non-regular context-free languages

If *L* is a non-regular context-free language, then positive cases can
be generated directly from the grammar by rewriting sentential forms
until they contain only terminal symbols. Various methods for doing
this and various coverage measures can be defined. (Separate
discussion needed.)

For negative cases, the difficulty is that the complement of a
context-free language *L* is not guaranteeed context-free, and there
is no algorithm for creating a grammar that generates the complement
of *L*.

One approach to this problem is as follows:

From the target language *L* we generate a regular superset
approximation *R*. *R* is an approximation of *L* in that many
sentences will be members either of both *L* and *R* or of neither.

There are several published algorithms for generating regular
approximations of context-free languages (separate discussion needed).
Gingersnap includes tools for generating an infinite series of subset
regular approximations and a matching series of superset
approximations, such that each approximation in the series is at least
as good (in the usual case: better) than its predecessor. (Separate
discussion needed.)

Since *R* is a regular language, its complement is also a regular
language and can be described by a finite state automaton.

Since *R* is a superset of *L*, the complement of *R* is a subset of
the complement of *L*. That is, every sentence of *L* is a sentence
of *R* and every sequence of symbols which is not a sentence in *R* is
also not a sentence in *L*.

It follows that by generating negative test cases for *R*, we generate
negative test cases for *L*. If *R* is a sufficiently close
approximation of *L*, negative test cases for *R* will be useful
negative test cases for *L*.

Separate documents needed on:

* positive test-case generation from context-free grammars
* regular approximations as implemented in Gingersnap
* other algorithms for regular approximations (to be implemented in Gingersnap)

