# Generating infinite series of regular subset and superset approximations for context-free languages

2020-01-11

This document describes a method for generating an infinite series of
pairs of regular approximations for a given context free language *L*
defined by a context free grammar *G*.  It is currently rather terse,
because I'm in a hurry.

## The pumping lemma for regular languages

An important result in formal language theory is that for any regular
language *L* there exists a number *m* such that any sentence *s*
in *L* can be partitioned into subsets *u*, *v*, and *w* such that

* *s* = *u* *v* *w*
* for all integers *n* >= 0, the string *u* *v*^*n* *w* is in *L*

(I am using blank as a concatenation operator here.)


For any
non-negative integer k, we can generate a subset *U(k)* and a superset
*O(k)*, with the property that *U(k)* contains all the sentences
of *L* such that no matching brackets nest more than *k* levels deep
and *O(k)* contains both *U(k)* and also sentences in which brackets
may occur more than *k* levels deep but are not guaranteed to match at
those deeper levels. So*U(0)* contains the sentences of *L* with no
brackets, *U(1)* the sentences of *L* with brackets occurring at most
one level deep (no nesting), *U(2)* sentences with at most two levels
of brackets. And analogously, *O(0)* contains all the sentences
of *L*, and in addition sentences with missing or extra
brackets, *O(1)* removes from *O(0)* all sentences in which outermost
brackets fail to match,*O(2)* removes all sentences in which brackets
at levels 1 or 2 fail to match, and so on.
