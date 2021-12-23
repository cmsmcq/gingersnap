# Using Gingersnap to make test cases from a grammar

2021-11-19, copy edits 2021-12-22

Much of Gingersnap was first developed as a set of tools for the
automatic generation of test cases from grammars, with the goal of
making it easier to create a set of tests with good coverage.

## Coverage measures

At various times I have tried to define various levels of coverage for
grammar-based testing, for both positive test cases (the input is a
sentence in the language defined by the grammar) and negative (not a
sentence).

### Coverage for regular grammars

For regular grammars, one of the simplest ways to visualize and define
coverage is in terms of the corresponding finite state automaton. We
can distinguish several coverage measures:

* state completeness: each state is visited at least once in the test 
suite. 

* arc completeness: each arc is traversed at least once in the test 
suite. Note that this entails state completeness. 

* state-final completeness: each state is the last state visited in at
least one test case in the test suite. Note that this entails state
completeness.

* arc-final completeness: each state is the last state visited in at
least one test case in the test suite. Note that this entails
state-final completeness and arc completeness.

* state positive completeness: each state (except error states) is
visited at least once in a positive test case. State negative
completeness is analogous: each state is visited by at least one
negative test case.

* arc positive / negative completeness: each arc is traversed at least
once in some positive / negative test case. Note that this entails
state positive or state negative completeness.

Note that the simplest way to generate a test suite with
state-positive and state-negative completeness is to work through each
state *q*, finding a path from the start state to *q* , a path
from *q* to some final state, and a path from *q* to some non-final
state. That is what the initial approach in Gingersnap does. The
result is, however, extremely repetitive.

Note that in the case of cycles in the FSA, arc completeness will
ensure that we traverse the cycle at least once in at least one test
case.

More stringent coverage measures may be imagined which check that for
each ordered pair of states or arcs, there is at least one test case
in which we visit or traverse first one, then the other. And so on.
Under normal circumstances, such path-oriented approaches seem likely
to produce huge numbers of tests and yield relatively few new bugs.


### Coverage for context-free grammars

For context-free grammars, three levels of coverage seem most likely
to be useful.

* nonterminal completeness: every nonterminal occurs in at least one
parse tree. This produces a light-weight set of tests which may be
helpful for a small test case to be run very frequently but will be
inadequate for serious work.

* choice completeness: for each choice in the grammar, every branch is
exercised at least once.  Expressions of the form *E?*, *E**, and *E+*
are treated as the choices (ε | *E*), (*E* | *E<sup>k</sup>*), and (ε
| *E* | *E<sup>k</sup>*), respectively, for any *k* > 1 (not
necessarily the same *k* in all cases).

* Cartesian produce of choices: for each right-hand side in the
grammar, every combination of branches is exercised at least once.

The *choice* and *Cartesian product of choices* measures are very
roughly analogous to the *condition coverage* and *decision/condition
coverage* criteria of Myers 1979: one treats different possibilities
independently, and the other attempts to deal with combinations of
them.

For a right-hand side of the form *a?, b+*, the choice completeness
measure wil require at least two tests (e.g. `b` and `abbb`, or `ab`
and `bbb`), while the Cartesian product completeness measure will
require four: `ab`, `b`, `abbb`, `bbb`. It may be observed that the
Cartesian product measure is a simple form of path-based coverage (and
it does indeed produce large numbers of tests which seem unlikely to
find new bugs).

More demanding coverage measures are also possible. For example, the
sequence of nonterminals from the root of a parse tree to a leaf of
that parse tree is a member of a regular language; we can apply the
various FSA-based measures to that regular language. That would
effectively check that every possible parent/child combination in the
set of possible parse trees is instantiated at least once in the test
suite.

I do not currently have any direct measure of coverage for negative
test cases for a context-free grammar. The only way I know to get
systematic generation of negative test cases is to generate an O*k*
regular superset of the language and generate negative test cases for
that superset, measuring coverage with respect to the FSA for the
negated regular superset.


## Making test cases 

### Making test cases from a regular grammar 

Given a regular approximation of a grammar, we can generate test cases
from the regular approximation.  The main steps of the work flow are:

* Make a deterministic FSA for the regular approximation.
* From the DFSA make *lego pieces* for test-case construction.
* Assemble the lego pieces into test cases.

The `tclego-from-rg` transform handles the first two steps. It takes
any regular grammar as input; from that regular grammar it prepares a
deterministic FSA and from that deterministic FSA it prepares a
collection of 'test case lego pieces' intended to simplify the
creation of actual test cases.

It works on small grammars but fails to handle the ixml grammar for
ixml: the deterministic FSA is too large.  The intermediate stages
may, however, be useful resources for semi-manual test construction.

```
    <grammar-pipeline>
      <desc>
        <p>Generic pipeline for converting a regular approximation
        (whether an r_k subset or an R_k superset) to a
        deterministic FSA from which test cases can be generated.</p>
        <p>At least, it's mostly generic.</p>
        <p>The make-rtn/@fissile attribute is grammar-specific.</p>
        <p>The expand-references/@nonterminals attribute is currently
        grammar-specific. If we add a way to tell make-rtn not to add
        linkage rules, this could be dispensed with.</p>
      </desc>

      <normalize-terminals>
        <desc>
          <p>Normalization of terminals is required for
          the determinization step to work, even when
          the grammar appears not to need it: the
          annotations are used in checking determinism.
          </p>
        </desc>
      </normalize-terminals>

      <eliminate-unit-rules>
        <desc>
          <p>The FSAs I'm working with have epsilon transitions,
          which of course take the form of unit rules.
          We need to lose them before determinizing.
          </p>
        </desc>
      </eliminate-unit-rules>

      <annotate-pc>
        <desc>
          <p>Epsilon elimination does make some states unreachable,
          so let's clear them out.  First re-annotate.  Then
          do the deed.</p>
        </desc>
		</annotate-pc>
		
      <remove-unreachables>
        <desc>
          <p>I said, then do the deed.  Get moving!</p>
        </desc>
      </remove-unreachables>
      
      <simplify-epsilon-expressions save="temp.nfsa.xml">
        <desc><p>Not always needed, but not harmful.</p></desc>
      </simplify-epsilon-expressions>  

      <determinize>
        <desc>
          <p>Now make the FSA deterministic.</p>
        </desc>
      </determinize>      
      
      <simplify-epsilon-expressions save="temp.dfsa.xml"/>

      <fsa-to-tclego save="temp.tclego.xml"/>
  
    </grammar-pipeline>
````

From the test-case lego pieces, the obvious pipeline to complete the
process of making test cases would be:

* tclego-to-tcrecipes
* tcrecipes-to-testcases

### Making test cases from a context-free grammar

I don't know a good way to make negative test cases direct from a
context-free grammar. To make them indirectly, generate a regular
superset approximation (for small grammars, O3 seems to work all
right), make an FSA for it, determinize the FSA, negate it, and
generate the test cases.

Positive test cases can be generated in a similar way: generate a
regular subset approximation and generate test cases from it.

For *direct* generation of positive test cases from a context-free
grammar, I believe the best current pipeline is something like the
following. After any step, manual intervention is possible and may be
desirable.

#### Cartesian-product coverage

The fullest existing pipeline aims at Cartesian-product coverage:

* Use `unroll-occurrences` to eliminate options and repetitions. The
  result can be interpreted as a set of and/or trees.

* Use `dnf-from-andor` to rewrite the grammar in disjunctive normal
  form. Since the output from this step is logically equivalent to its
  input, it effectively produces coverage at the Cartesian-produce
  level.

* Use `parsetrees-from-dnf` to write out a set of parse-tree
  skeletons, rooted in the grammar's start-symbol, in which leaves are
  terminals and pseudo-terminals.  At least, that's the idea; in
  practice, many of the resulting trees are incomplete.

* Use `ln-from-parsetrees` and `parsetree-pointing` (or manual
  intervention) to patch up gaps.

* Use `testcases-from-parsetrees` to write out test cases.

In some cases, the first two steps in this pipeline can produce
unfortunate results. In the grammar for ixml, for example, comments
are defined thus:

````
comment:  (cchar; comment)*. 
````

Unrolling the Kleene closure yields

````
comment:  {nothing}; 
        (cchar; comment);
        (cchar; comment), (cchar; comment), (cchar; comment).
````

The disjunctive-normal-form equivalent ends up with eleven right-hand
sides for *comment*, of which eight require a nested comment. If we
construct trees by selecting randomly or systematically from all the
possible realizations of a nonterminal, the result is a profusion of
deeply nested comments that astonished me when I first saw it.

To avoid this problem it may be better to bypass the second step of
the pipeline. Unfortunately, at the moment, the later steps in the
pipeline assume their input is in disjunctive normal form, so
bypassing it means working manually, or re-implementing the rest of
the pipeline.

In the meantime, the best workaround may be to edit the DNF form of
the grammar manually to trim unneeded alternatives. If a little care
is taken, choice coverage can be maintained.


