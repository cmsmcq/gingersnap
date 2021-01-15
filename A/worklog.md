# Work log (not necessarily complete)

This document contains notes on things I don't want to forget, when I remember to write them down.

## 2020-12-30

The pipeline now runs from start to finish on the Program grammar r0 subset.

Now to try it on several other grammars to smoke out errors and learn things.

  * tiny CFGs:  a, ab, abab in ./ab
  
  * numbers (a regular language) - both direct test-case generation and
    generation of r_k, R_k approximations
    
  * gj55 (a regular language) - ditto, both direct and via approximations
  
  * arithmetic expressions with three kinds of brackets
  
  * gj23 an inherently ambiguous grammar
  
  * Program

### ab.ixml, etc

17:14 ixml to xml translation. Remember that the recursive descent
parser reads a dummy xml document (how old school).

    for g in *.ixml;
    do echo;
       echo $g ...;
       ~/bin/saxon-he-wrapper.sh \
            dummy.xml \
	    ~/2020/recursive-descent-parsing/ixml-to-xml.manual.xsl \
	    ${g}.xml \
	    input=file \
	    inputfile=`pwd`/$g ;
       done

a.ixml (just 'a' wrapped in parens). Let's build an r<sub>5</sub>
subset and an R<sub>2</sub> superset. (Note 12 Jan 2021: Or, to use
the terminology introduced later, a U(5) subset and an O(2) superset.)

So we need an R0 superset, an r2 subset, and an r5 subset.

To make the R0 superset, make a sup.R0.pipeline.xml pipeline
document, run it.

    $SAXON a.ixml.xml \
        ../src/grammar-pipeline-handler.xsl \
        a.sup.R0.rtn.xml \
        stepsfile=`pwd`/sup.R0.pipeline.xml

To simplify it, separate the generic R0 generation pipeline from the
grammar-specific simplification pipeline:

     ~/bin/saxon-he-wrapper.sh \
           a.sup.R0.rtn.xml \
	       ../src/grammar-pipeline-handler.xsl \
	       a.sup.R0.simplified.xml \
	       stepsfile=`pwd`/sup.R0.simplify.pipeline.xml 

To make the r2 and r5 subsets, just run the pipelines
grammar-to-sub.r2.xml or grammar-to-sub.r5.xml. The k value cannot be
passed as a parameter. We should fix that.

    ~/bin/saxon-he-wrapper.sh \
        a.ixml.xml \
	    ../src/grammar-pipeline-handler.xsl \
		a.sub.r2.xml \
		stepsfile=`pwd`/grammar-to-sub.r2.xml

You should be able to just run the stylesheet, but it requires pc
annotation, so the pipeline is simpler.

To clean the r5 subset (which is not intended for knitting), a
separate pipeline is needed. The pipeline rk-simplifier.pipeline.xml
appears to be generic.

State of play at COB 30 December: working on a.ixml (the simplest
possible example), I have found plenty of rough edges to sand down a
bit. The exercise seems to be worth while.

To do next:

  * Knit r2 subset with R0 superset to make R2 superset.
  * Make FSA for r5 subset and R2 superset, determinize.
  * Generate tests for r5 subset and R2 superset.
  * ¿ Also make clean r2 subset and R5 superset?
  
## 2020-12-31, am.

Made simplified r2 subset. Hand knit R2 and R5 supersets.

It would be nice if you could run make-rtn on the subsets and
supersets directly, but at the moment that appears not to be true. We
need a way to say "expand everything" instead of "expand just
recursive nonterminals". I.e. no pseudo-terminals!

For the development work, what I did was manually reduce the grammar
to a single production, whose regex could become an FSA.

It would be nice if that were not necessary.

## 2021-01-12

### Miscellaneous changes

Various changes. Moved from 2020 directory to 2021; made separate git
repo for the 2021/gingersnap directory, set it up to to push to
github.

Spent a lot of time trying to work out how many different things I
wanted ixml-to-saprg (aka make-rtn) to be able to do.

* generate a 'mixed' grammar (part conventional ixml, part regular
grammar / FSA describing a recursive transition network for at least
the recursive nonterminals) which accepts the same language as the
original grammar (assuming a stack-aware processor for the FSA parts).

* generate 'pure' stack-augmented regular grammar with no 
'conventional' part, whose FSA accepts the same language as the 
original language, if the stack is managed properly.

* generate 'pure' stack-augmented regular grammar with no 
'conventional' part, whose FSA accepts the same language as the 
original language even if the stack is ignored.

The result is that the transform now accepts five parameters, not just
one, but it appears to work.

The changes were slowed down by the need to set up some regression
tests so that I would be more likely to notice when I broke things.
The 'tests' directory now contains a rather thin collection of
regression tests in XSpec, for a few pipeline stages. The idea is to
make at least one regression test for each stage, before I touch it,
showing its existing behavior on an existing example, and in principle
to write test cases for the new functionality as well. (I confess,
though, that for ixml-to-saprg it was simpler to generate the expected
output with the program than by hand, so I just ran the modified code
on a relevant example, examined the output, and iterated until the
output was correct, then put that file into the reference-output
directory.)

Somewhere along the way I also encapsulated the generic
grammar-to-rk-subset pipeline into a stylesheet, which accepts the
parameter k, and I have started but not yet tested a generic
stylesheet for the R0 superset.  (Or:  U(k) subset, O(0) superset.)

### Resuming work on a.ixml

The interruption has made me lose focus on a.ixml.  Where was I?

It doesn't matter. Let's re-do the work. We start with a.ixml and
a.ixml.xml.  We want to make

* a.u2.ixml.raw.xml for the U(2) subset 
* a.u5.ixml.raw.xml for the U(5) subset
* a.u5.ixml.clean.xml for the U(5) subset cleaned and simplified (we
don't need an analogous clean U(2) grammar, because the only purpose
of U(2) is to be knit together with a.S.O0 to make a.O2.ixml.xml)
* a.S.O0.ixml.xml for the O(0) version of the nonterminal S in grammar a.ixml 
* a.S.O0.simplified.ixml.xml for a hand-simplified version of the above
* a.O2.ixml.xml (hand-knit)
* a.u5.fsa.xml 
* a.O2.fsa.xml
* positive test cases for a.u5 
* negative test cases for a.O2

### Raw and clean subsets

Use `rk-subset.xsl` with `k=*$k*` to produce the a.u*${k}*.raw.ixml.xml grammars:

     for k in 2 5;
     do echo $k;
	    ~/bin/saxon-he-wrapper.sh a.ixml.xml ../src/rk-subset.xsl a.u${k}.ixml.xml k=${k};
	 done

Use the generic `sub.rk.simplifier.pipeline.xml` pipeline to produce
the a.u5.clean.ixml.xml grammar:

     ~/bin/saxon-he-wrapper.sh \
          a.u5.raw.ixml.xml \
          ../src/grammar-pipeline-handler.xsl \
          a.u5.clean.ixml.xml \
          stepsfile=`pwd`/sub.rk.simplifier.pipeline.xml

### O(0) form of S and a.O2 grammar

To make `a.S.O0.ixml.xml`, we run `R0-superset.xsl` on `a.ixm.xml` with `start='S'`.

To make `a.S.O0.simplified.ixml.xml` we develop and run the pipeline `a.S.O0.simplification.pipeline.xml`.

Revised ixml-to-rk-subset  as proposed in to-do list.

Made `a.O2.ixml.xml` by hand-knitting the O0 version of S into the u2 grammar.

### FSAs

Made the FSAs by running R0-superset with `start='#inherit'`.

    ~/bin/saxon-he-wrapper.sh a.O2.ixml.xml ../src/R0-superset.xsl a.O2.fsa.xml start='#inherit'
    ~/bin/saxon-he-wrapper.sh a.u5.clean.ixml.xml ../src/R0-superset.xsl a.u5.fsa.xml start='#inherit'

These appear to have come out all righ.

### Test cases

After two weeks, I no longer remember how the pipeline for test cases
was supposed to work. (That is, of course, part of the point of going
through the process several times with simple grammars: to streamline
the process and learn it better.)

#### Where were we?

The relevant pipeline in last month's work appears to be
sub.r0.cleanup.pipeline; the name is not quite an accurate description
of the current content. It appears to begin with the original Program
grammar and then perform a rather long pipeline, which I think can be
broke up as follows.  First make the U(0) grammar:

     annotate-pc
     | rk-subset k=0

Then simplify it (I think this is just to clean up the undefined nonterminals):

	 | annotate-pc
	 | simplify-expressions (x 4)
	 | annotate-pc
	 | remove-unreachables

Now reduce it to a single regular expression. I do not see why
annotate-gl is needed here, and maybe it's not.

	 | annotate-pc
	 | annotate-gl
	 | expand-references nonterminals= pretty much everything 
	 | expand-references nonterminals= everything else

Now prepare for the big step. Normalizing terminals is not necessary
for a.ixml; it only applies when there are multi-character strings and
character-set terminals.

	 | strip-rtn-attributes
	 | annotate-pc
	 | normalize-terminals
	 | annotate-gl
	 | make-rtn fissile="program"

The next step was necessary to get rid of the linkage rules introuced
by make-rtn; the revisions to rtn mean that that step won't be
necessary now.

     | expand-references nonterminals="program_0 program_f"

The FSA needs to be determinized, and then apparently the expressions
need smoothing out. And then the test-case Lego pieces can be made and
translated into recipes.

	 | determinize
	 | simplify-epsilon-expressions
     | fsa-to-tclego
	 | tclego-to-tcrecipes

The actual creation of test cases is not shown; it involves repeated
invocation of tcrecipes-to-testcases.xsl.

(Addendum, next day: actually, it's tclego-to-recipes that has to be
invoked multiple times. It was parameterized to produce only recipes
of a particular style and polarity when I was working on the program
grammar, because otherwise the output was excessive. I don't remember
whether it ran out of memory too or not.)

#### Making the test cases

Need:
* positive test cases for a.u5 
* negative test cases for a.O2 

For grammar a.ixml we already have the FSAs, so the first several
blocks of steps listed above can be skipped. I think the only steps
needed are those in the final block.

* Eliminate epsilon transitions is not in the final block, because
that pipeline first reduced the U(0) grammar to a single regular
expression and then built its Gluschkov automaton, and there are no
epsilon transitions in the Gluschkov automaton. But we are working
from FSAs built from RTNs; they do have empty transitions.

* determinizing

* possibly simplifying

* fsa-to-tclego

* tclego-to-tcrecipes

Let's put this into a pipeline, trying to stay generic.  Working file is
`a.regular-approx-to-dfsa.pipeline.xml`

Close of work 12 January: determinization step is failing: it produces
an empty rule with no RHS. And no error messages. Conjecture: its
assumptions are not being met, but they are also not being checked, so
the problem is not being flagged.

## 2021-01-13

The problem with determinizer was that it relies on gt:ranges
annotation and was not checking its input to make sure it had been
supplied. The problem with the pipeline was that it was not running
the normalize-term step. Since that step provides the gt:ranges
annotation, it is not optional, even for grammars like a.ixml in which
there are no multi-character strings and no overlapping ranges to be
normalized.

It might be nicer if when applied to such input the determinizer were
the identity transform, but at the moment it's renaming all the
states, unnecessarily.

Produced a.u5.tclego.xml and a.O2.tclego.xml by running the pipeline
a.regular-approx-to-dfsa.pipeline.xml on a.u5.fsa.xml and
a.O2.fsa.xml.

     ~/bin/saxon-he-wrapper.sh \
          a.O2.fsa.xml \
          ../src/grammar-pipeline-handler.xsl \
          a.O2.tclego.xml \
          stepsfile=`pwd`/a.regular-approx-to-dfsa.pipeline.xml 

The pipeline appears generic and suitable for packaging in a single
stand-alone stylesheet.

From the tclego, it's possible to generate all the test cases in a
single output, but the current state of the test-case generator makes
that unsatisfactory. It's better to generate separate files of recipes
for the different coverage rules (and polarity). From those recipe
files, test cases can be generated.

I used this bash command:

     for cov in state arc state-final arc-final;
          do echo "${cov} recipes";
          ~/bin/saxon-he-wrapper.sh a.O2.tclego.xml \
               ../src/tclego-to-tcrecipes.xsl \
               a.O2.tcrecipes.${cov}.neg.xml \
               coverage=${cov} polarity='negative';
          echo "${cov} cases";
          ~/bin/saxon-he-wrapper.sh \
               a.O2.tcrecipes.${cov}.neg.xml \
               ../src/tcrecipes-to-testcases.xsl
               a.O2.testcases.${cov}.neg.xml ;
     done

And analogously for positive tests for u5.

The results are a little surprising and suggest that perhaps I do need
to take more steps to remove duplicates, at least from positive test
cases.  Some summary information can be generated quickly with

     for g in u5 O2;
          do for p in pos neg;
               do for cov in state arc state-final arc-final;
                    do echo -n "$cov $g tests: " ;
                    grep '<input-string' a.${g}.testcases.${cov}.${p}.xml | wc -l;
                    echo -n "     unique: " ;
                    grep '<input-string' a.${g}.testcases.${cov}.${p}.xml | sort | uniq | wc -l;
                    grep '<input-string' a.${g}.testcases.${cov}.${p}.xml | sort | uniq;
                    echo;
               done;
          done;
     done

The positive test cases for arc- and state-final coverage were, as
expected, all unique, but I had to think for a bit to see why they
produced so few cases.

The state-final coverage produced just two tests:

* <input-string>(a)</input-string>
* <input-string>a</input-string>

The arc-final coverage also produced just two tests:

* <input-string>((a))</input-string>
* <input-string>(a)</input-string>

These are fine tests, but from a u5 subset grammar I was expecting at
least one test with more than two levels of parenthesis. But
examination of [the deterministic FSA](../ab/a.u5.dfsa.xml) clears it
up a bit. The FSA has two final states (m-S\_1 and m-S\_4), so a
state-final coverage approach produces two tests.

There are three arcs that lead to these states, though, so the
arc-final coverage should be producing three tests (the test for `a`
is missing). There appears to be a bug in tclego-to-tcrecipes. Aha.
Good.

The state and arc test cases were more productive: each of them
produced tests for all five levels of nesting.

* <input-string>(((((a)))))</input-string>
* <input-string>((((a))))</input-string>
* <input-string>(((a)))</input-string>
* <input-string>((a))</input-string>
* <input-string>(a)</input-string>

In both cases, `a` is again missing.  Same bug, or a different one.

But the state and arc coverage generators produced 14 and 16 tests,
respectively, so they produced each of these useful tests about three
times, on average. And actually they should have done more. There are
17 states and 22 arcs in the DFSA, so we appear to be missing tests
for three states and six arcs. Unless somehow we have a state or arc
for which there is no successful suffix?

Filtering for uniqueness seems likely to be a good idea; seeing the
same test three times is going to make a bad impression.

The negative tests are also interesting. They are all unique; no
duplicates here within any given style of coverage.

O2 tests with state coverage (22 of them):

* <input-string>((((X)))</input-string>
* <input-string>((((Xa)))</input-string>
* <input-string>(((a))$)</input-string>
* <input-string>(((a))$</input-string>
* <input-string>(((a)))$)</input-string>
* <input-string>(((a)))$</input-string>
* <input-string>(((a)*))</input-string>
* <input-string>(((a)*)</input-string>
* <input-string>(((a񫛜)))</input-string>
* <input-string>(((a񫛜))</input-string>
* <input-string>(((今)))</input-string>
* <input-string>(((今a)))</input-string>
* <input-string>((a#))</input-string>
* <input-string>((a#)</input-string>
* <input-string>((a))</input-string>
* <input-string>((a)</input-string>
* <input-string>((�))</input-string>
* <input-string>((�a))</input-string>
* <input-string>(a#)</input-string>
* <input-string>(a#</input-string>
* <input-string>(㷽)</input-string>
* <input-string>(㷽a)</input-string>

In the first two cases, I have replaced U+5350 from the CJK Unified
Ideographs block with X, since 5350 resembles a political symbol now
in disrepute.

Arc coverage for (26 tests)

* <input-string>((")))</input-string>
* <input-string>(("a)))</input-string>
* <input-string>((((#)))</input-string>
* <input-string>((((#a)))</input-string>
* <input-string>((((퟿)))</input-string>
* <input-string>((((퟿))</input-string>
* <input-string>(((a#))</input-string>
* <input-string>(((a#)</input-string>
* <input-string>(((a)))#)</input-string>
* <input-string>(((a)))#</input-string>
* <input-string>(((a))𐀁)</input-string>
* <input-string>(((a))𐀁</input-string>
* <input-string>(((a)񪖦)</input-string>
* <input-string>(((a)񪖦</input-string>
* <input-string>((()))</input-string>
* <input-string>(((𐀁)))</input-string>
* <input-string>((())</input-string>
* <input-string>(((𐀁a)))</input-string>
* <input-string>((a)</input-string>
* <input-string>((a</input-string>
* <input-string>((퟿))</input-string>
* <input-string>((퟿)</input-string>
* <input-string>())</input-string>
* <input-string>(񙉊)</input-string>
* <input-string>(񙉊</input-string>
* <input-string>(a))</input-string>

State-final coverage for O2 (10 tests):

* <input-string>((((</input-string>
* <input-string>(((</input-string>
* <input-string>(((a))</input-string>
* <input-string>(((a)</input-string>
* <input-string>(((a</input-string>
* <input-string>((</input-string>
* <input-string>((a)</input-string>
* <input-string>((a</input-string>
* <input-string>(</input-string>
* <input-string>(a</input-string>

Arc-final O2 tests (11):

* <input-string>(((((</input-string>
* <input-string>((((</input-string>
* <input-string>((((a</input-string>
* <input-string>(((</input-string>
* <input-string>(((a))</input-string>
* <input-string>(((a)</input-string>
* <input-string>(((a</input-string>
* <input-string>((</input-string>
* <input-string>((a)</input-string>
* <input-string>((a</input-string>
* <input-string>(a</input-string>

Note that the unexpected characters are all in the arc and state
coverage: the *-final coverages, of course, use strings that lead to
the arc or state in question, which means they never have unexpected
characters. In fact, they are (of course) always prefixes of sentences
which are themselves not sentences.

## 2021-01-13, later

Thinking about the missing tests in the state and arc coverage test
sets: they may be due either to problems in the FSA (it looked OK, but
I have not verified it carefully) or to problems in the test
generation pipeline. My money is on the latter, and specifically on
the generation of alpha and omega paths (paths leading from the start
state to a given state or arc, and paths leading from that state or
arc to a final state); the numbers reported by tclego have always been
off by a little, which suggests to me now that the path generation is
not dealing correctly with empty paths.

Some test cases look to be worth writing. An FSA must have at least
one state (otherwise it has no start state), so the smallest FSAs are
those with a single state. They are simple enough to specify formally
here.  I'll use U to mean 'any Unicode character'. 

* ({q0}, U, {}, q0, {q0} ): one state, no transitions, state is final

        q0 = {nil}.

        <rule name="q0"><alt/></rule>

* ({q0}, U, {}, q0, {} ): one state, no transitions, state is not final 

        <rule name="q0"/> (this is probably not actually valid ixml) 

* ({q0}, U, {(q0,'a',q0}, q0, {q0} ): one state, one transition (a), state is final 

        q0 = 'a'. 

        <rule name="q0"><alt><literal dstring="a"/></alt></rule>

* ({q0}, U, {(q0,U,q0)}, q0, {q0} ): one state, one transition (U), state is final 

* ({q0}, U, {(q0,'a',q0}, q0, {} ): one state, one transition (a), state is not final 

* ({q0}, U, {(q0,U,q0)}, q0, {} ): one state, one transition (U), state is not final 

In the last two FSAs, the existence of the transition doesn't affect
the language recognized: since there is no final state, no strings are
accepted and the language is {}.

More tests are needed, but these definitely look to be worth doing.


## 2021-01-13, still later

Reading Braband / Møller/ Schwartzbach 2008 on XSugar.  Nifty paper.

They focus explicitly on two-way translation, though as far as I can
tell after reading part of the paper they are in roughly the same
situation w.r.t. round-trippability as ixml is — it’s possible to
throw away information on the way into or out of XML, so what can be
round tripped is, roughly, what the particular syntax description
implicitly declares as important.

In many ways, XSugar and ixml are similar.

  * Both can use both elements and attributes on the RHS.

  * Both prescribe Earley parsing (though XSugar requires extensions
    for priorities and unordered RHS).

XSugar has constructs and facilities that ixml does not have:

  * an ‘&’ operator that declares a RHS unordered
  
  * the ability to change the order of siblings in translation into or
    from XML (each symbol has a type and an optional unique local
    name; the local names in the non-XML and XML parts of the
    production must match, but need not be in the same sequence)

  * the ability to inject character data into the XML (the mirror image
    of dropping literals from the non-XML)

  * the ability to mark a RHS as having lower priority than other RHS
    for the same nonterminal

  * magic symbols _ and __ meaning 'optional whitespace' and 'required
    whitespace'

  * ability to declare that elements (and attributes) are in a
    particular namespace

And conversely XSugar lacks some things present in ixml:

  * it’s BNF based, not EBNF based
  
Their static analysis to determine whether an XSugar syntax spec is
lossless in both directions may possibly be applicable (mutatis
mutandis) to ixml.  And their definition of round-trip information
preservation ('reversibility') can definitely serve as a model in any
discussions of round-tripping in ixml.

The bad news is that the problem of detecting reversibility turns out
to involve checking that both the non-XML grammar and the XML grammar
are unambiguous, which is undecidable in general.  It took me a few
minutes to see how to apply the ambiguity check to the XML side of
their grammar rules, but I think I get it now.  It will take some more
thinking to see whether and how an ixml grammar can be rewritten as a
grammar for tagged documents, but I think it may be doable.

Consider the XSugar example

     S: [A z] = <S> [A z] </>
      : [B z] = <S> [B z] </>
     A: ["a"] "x" = "x"
     B: ["b"] "x" = "x"

This corresponds, I think, to the ixml

    S: A; B.
    -A: -"a", "x". 
    -B: -"b", "x". 

From the XSugar it's straightforward to extract the grammar for the
non-XML data format, which in iXML I would write [pause] exactly like
the grammar just given, except for the various marks:

    S: A; B.
    A: "a", "x". 
    B: "b", "x". 

It's equally possible to extract a grammar for the 'normalized XML'
they define, which is a sort of abstracted tagged-document syntax.

    S: "<S>", A, "</>"; "<S>", B, "</>".
    A: "x".
	B: "x".

It's easy to see that this is ambiguous, because there is only one
sentence (`<S>x</>`) and it can be derived in two different ways, via A
and B.

It may be a little trickier to read a grammar for tagged documents out
of the ixml syntax -- at the very least it is likely to be error prone
for me. The tentative rules for rewriting an ixml grammar as a schema
get us part (most?) of the way there, but if I recall correctly, that
sketch ran into trouble precisely when it started to try to deal with
terminal symbols. On the plus side: the grammar for tagged documents
does not need to be a legal schema in any existing schema language. So
I can improvise as needed when it comes to PCDATA and attribute
values.

On a practical level, B/M/S divide translation into four steps:

* parsing maps from data to parse tree
* abstraction maps from parse tree to unifying syntax tree
* concretization maps from UST to parse tree
* unparsing maps from parse tree to data

The distinction between parsing and abstraction corresponds perfectly,
I think, to the distinction in the current version of Aparecium
between parsing into the raw parse tree and modifying that parse tree
in accordance with the marks in the grammar. I have been embarrassed
by the difficulty I had trying to fold the abstraction step into the
parsing step; maybe I should stop worrying about it. The
implementation is simpler with separate steps. I assume it's slower,
but until I measure and see that the abstraction is a meaningful part
of the cost, it's probably not the best place to worry about speed.
(Ah, but I notice that on p. 20 they report that their Earley parser
goes directly into the UST without first producing the parse tree.)

The distinction between UST (or AST) and parse tree looks as if it
would be useful when trying to think about reading ixml grammars as
ways to parse XML documents. But I have to keep in mind that as I have
understood ixml, the XML is a pretty direct representation of the AST,
whereas for B/M/S it's just another concrete syntax for their AST. It
looks like the kind of problem that will require thinking about some
concrete examples to start with. When the time come.

## 2021-01-14

There are other things I should be doing, but I'm spending the morning
reading Chomsky, "On certain formal properties of grammars." Terry
Langendoen says in 1975 that "Chomsky (1959a), moreover, provides an
algorithm for constructing FAs for sentences generated by arbitrary
Chomsky-normal-form (CNF) grammars with up to any fixed finite
degree *n* of center embedding (CE)."

His construction uses some mechanisms that are unfamiliar to me, and
his expository style does not involve any hints that I can see about
where he is going. I'm going to try to understand what he writes by
explaining it to myself.

We are given a non-self-embedding grammar G in what we now call
Chomsky Normal Form and are going to construct an equivalent grammar
G'.

Since G is CNF, rules are all of one of the forms

* A: t.
* A: B, C. { B ne C }

There is also a restriction that appears to amount to saying that for
any pair of nonterminals P, C in a parent/child relation, C can appear
in at most one RHS of P.

Since G is not self-embedding, there is (by def. 7, p. 148) no
nonterminal N such that N =>* phi N psi for nonempty phi and psi. So
for every recursive nonterminal N in G, the recursion is either N =>*
phi N (right embedding) or N =>* N psi (left embedding). This comes up
later.

Chomsky defines K as the set of sequences (N1, N2, ... Nm) of length
one or more, such that:

1. Any two adjacent symbols *N*<sub>*i*</sub>, *N*<sub>*i*+1</sub>
are in a parent/child relation, that is, there is in G a rule of the form

        *N*<sub>*i*<sub>: phi, *N*<sub>*i*+1</sub>, psi

2. And no two symbols in the sequence are the same. 

Given the first restriction, N1 et al. must be nonterminals in G, so
what we have in K are sequences of paths in the stack language of G,
or equivalently sequences of symbols that can appear adjacent on a
parser stack when parsing G, and which contain no instance of
recursion.

I note in passing that there will be a finite number of such
sequences.

Chomsky specifies that the nonterminals in G' have the form (B1 ...
Bn)[i], for *i* in {1, 2}, where the Bs are nonterminals in G, and
"suppose[s]" (?!) that (B1 ... Bn) is in K.

To simplify things and to relate this construction to Gingersnap, I'm
going to re-cast this and say that the nonterminals of G' are all
formed by concatenating sequences of nonterminals in G, with middle
dot. I predict that many if not all nonterminals will be the
nonterminals generated by ixml-to-rk-subset. So what Chomsky writes
(B1 ... Bn) I am going to write Bn·...·B1. I'm going to put the
subscripts at the end (earlier doesn't seem to help), and to avoid
interference from Markdown I'm going to use a middle dot and not an
underscore: Bn·...·B1·1, Bn·...·B1·2.

Chomsky doesn't say so, but for the moment I think it's safe to imagine that  
the sequences used as nonterminals always start with the start symbol.
This won't be the smallest possible grammar (in practice, some stack
affixes are going to be equivalent), but I don't think it will cause
any errors. (Note from the future: yes. It takes him a couple pages to
get to it, but he does say on p. 154 that B1 ... Bn includes Bn and
all the nodes dominating Bn. Why he didn't lead with that, I do not
know.) (And another note: there are proof steps that work with partial
affixes, so he didn't want to suggest that the affixes were always
full up to the start symbol.)

Chomsky then specifies patterns to be followed in the production rules
of G'. When I write grammar rules inline, I'm going to write rules in
parentheses, without final stops, but otherwise in ixml notation.

If G has  (Bn = t), then G' has

    Bn·...·B1·1 = t, Bn·...·B1·2.

This makes the subscripts 1 and 2 look a lot like 'before' and 'after.
Or, more precisely, like states N\_0 and N\_f in the RTN generated by
ixml-to-saprg. OK. Tentatively. (I'm going to refer to these as left-
and right-states; they can be thought of as roughly analogous to the
pre- and post-states on a node in a tree traversal.)

If G has (Bn: C, D) where neither C nor D occur in (B1 ... Bn), then
G' has

    Bn·...·B1·1 = C·Bn·...·B1·1.
    C·Bn·...·B1·2 = D·Bn·...·B1·1.
    D·Bn·...·B1·2 = Bn·...·B1·2.	

If we replace Bn·...·B1 by N and ignore the stack affixes, this is
structurally the same as a call/return linkage in the RTN:

    N\_0: C\_0.
    C\_f: D\_0.
	D\_f: N\_f.

That is: epsilon transitions from pre-state of parent to pre-state of
first child, from post-state of first child to pre-state of second
child, and from post-state of last child to post-state of parent.

Back to the construction. If G has (Bn: C, D) where D = Bi for some Bi
in (B1 ... Bn), -- that is to say, G has (Bn: C, Bi) -- then G' has

    Bn·...·B1·1 = C·Bn·...·B1·1. { Same as before. }
    C·Bn·...·B1·2 = Bi·...·B1·1.  { Trim the affix. }

Note two differences from the earlier case:

* Post-state of first child goes to pre-state of Bi·...·B1 (the Bi
    ancestor), not Bi·Bn·...·Bi·...·B1 (the Bi child). We cut off the
    prefix Bi·Bn·...· and just start from the second Bi.

    So informally: When we hit a recursive nonterminal, we trim the
    stack affix by eliminating the cycle. By trimming
    the stack we are ensuring that G' does not and cannot keep track 
    of how deeply Bi is nested. If G were self-embedding, that would 
    make G' broader. (D'oh.) 

* No transition from post state of last child Bi to post state of
  parent Bn.

Similarly, if G has (Bn: C, D) where C = Bi for some Bi in (B1 ... Bn)
-- i.e. G has (Bn: Bi, D) -- , then G' has

    Bi·...·B1·2 = D·Bn·...·B1·1. { Trim the affix. }
    D·Bn·...·B1·2 = Bn·...·B1·2. { As before. }

The changes are the mirror of those for the right-recursive case: The
transition to the pre-state of the second child comes from the
post-state of the ancestor Bi, not from the post-state of the child
Bi. (That may be misleading. There is no nonterminal in G'
distinctively representing the child Bi. The child Bi and the ancestor
Bi in the imaginary parse tree for G both map to the same nonterminal
in G'.) And there is no epsilon transition from the pre-state of Bn to
the pre-state of first-child Bi.

Chomsky does not consider the situation where both C and D occur in
the stack-tracking affix. Either he thinks it's impossible because G
is not center-embedding (maybe so), or he thinks it's covered by the
third and fourth cases, or there is another explanation. If the idea
is that it's covered by what's said above, then perhaps I can work it
out. If G has (Bn = Bi, Bj) and we followed the first rule, and didn't
trim the affixes, then G' would have:

    Bn·...·B1·1 = Bi·Bn·...·Bi·...·B1·1.
    Bi·Bn·...·Bi·...·B1·2 = Bj·Bn·...·Bj·...·B1·1.
    Bj·Bn·...·Bj·...·B1·2 = Bn·...·B1·2.	

Trimming the affixes would give us:

    Bn·...·B1·1 = Bi·...·B1·1.
    Bi·...·B1·2 = Bj·...·B1·1.
    Bj·...·B1·2 = Bn·...·B1·2.

However, if we follow the pattern established above (no epsilon
transitions from pre-state of parent to pre-state of recursive first
child, or from post-state of recursive last child to post-state of
parent), then the rule would reduce to:

    Bi·...·B1·2 = Bj·...·B1·1.

I do not currently understand the absence of those transitions. Poor
me.

I am also puzzled by the fact that when Chomsky illustrates the four
different situations he says we can be in (p. 153), the (Bn = Bi, D)
case shows the descendant Bi (left child of its parent) as deriving
from the left child of the ancestor Bi, and conversely for the
right-child case. I think this must follow from the fact that G is not
self-embedding, but I have to think about it for a moment.

We have either (Bi =>* phi Bi) or (Bi => Bi psi).

In the first case, we have (Bi =>* phi Bi), so the rule used for Bn
must be (Bn = C, Bi). Otherwise we'd have (Bi => chi Bi D) which
contradicts the premise. And if the derivation step for the ancestor
Bi was (Bi = X, Y), then the descendant must derive from Y, not X.
Otherwise we'd have (Bi =>* mu Bi Y), and another contradiction.

And similarly for the second case.

So stop being puzzled by the left- or right-handedness. If Bi is
right-embedding (first case), then it must always be the right-hand
child of a right-hand child, all the way up to the ancestor Bi. The
ancestor Bi does not need to be a right-hand child, though: if its
parent is non-recursive, that would be fine.

When we have (Bi =>* phi Bi), then in the terminal strings of L(G) we
can have arbitrary many repetitions of phi -- i.e. phi<sup>*k*</sup>.
And similarly for psi if (Bi =>* Bi psi). Chomsky says "(iii) and (iv)
accommodate these possibilities by permitting the appropriate cycles
in G'."

Chomsky announces that he is going to prove that L(G') = L(G), which
takes a long time, and then the main result of the paper, namely that
self-embedding is what makes context-free grammars more powerful than
finite-state automata.

I'm going to start by just paraphrasing the lemmas.

L3. For any sequence (A<sub>1</sub>, ... , A<sub>*m*</sub>) in set K,
then for all 1 <= *j* <= *k* <= *m* we have

    A<sub>*j*</sub> =>\* A<sub>*k*</sub>.

L4. If (Bn·...·B1·i = x, Bm·...·B1·j) and C is not in those affixes,
and (C = alpha, B1, beta) -- note in passing that either alpha or beta
will be empty, don't panic -- then (Bn·...·B1·C·i = x, Bm·...·B1·C·j).

That is, in the absence of recursion, the stack affix of the
nonterminal Bn makes no difference: if for any affix aaa we have N·A =
x, M·N‚A, then we have the same if A is aaab instead.

Here, Chomsky relies on the fact that he described the patterns
without explaining that the affix always described the complete stack.

I'm going to have to pause here. Even understanding the lemmas well
enough to paraphrase them is taking time, and I have to go now.

But before I go, this thought: perhaps the construction should be
recast more explicitly as the writing of a regular grammar?

(Later.)

Let's see. The grammar rules all have one of the following forms
(using P for the parent, including whatever affix it may have, and A,
B for left and right child):

    P.0: 'a', P.f.
    P.0: {nil}, A.P.0.
	A.P.f: B.P.0.
	B.P.f: P.f.

So it is clearly a regular grammar in the post-Chomsky sense. The
construction as described so far has no final state; that may be what
Chomsky means when he says G' is equivalent to G "(when slightly
modified)".

Back to paraphrase.

Lemma 5. (Paraphrasing very loosely.) Bn is either right-recursive,
and the right-hand child of a right-hand child, or left-recursive and
the left-hand child of a left-hand child. Proof is roughly as
described above; it follows from the premise that G is not
self-embedding.

## 2021-01-15

Working with pen and paper this morning I concluded that one reason
things are so hard to understand at this point in the paper is that
the 18 lines of prose labeled "Construction" do not tell me how to
construct grammar G'. By modern conventions, a context-free grammar is
a tuple (*V*<sub>*N*</sub>, *V*<sub>*T*</sub>, *P*, *S*), where
*V*<sub>*N*</sub> is a finite vocabulary of nonterminals,
*V*<sub>*T*</sub> is a finite vocabulary of terminals,
*P* is a finite set of productions, and
*S* in *V*<sub>*N*</sub> is a start symbol.

The construction described by Chomsky specifies that the nonterminals
in G' consist of a sequence of nonterminals from G plus a suffix (1 or
2 in Chomsky's notation; I am now leaning towards pre and post, or 0
and f). He specifies that for a given nonterminal in G', if rules of a
certain form occur in G, then certain rules of a specified form will
exist among the productions of G'. Unless I am missing something,
that's it.  So the construction of G'

* constrains the set of nonterminals to be sequences of nonterminals
in G, plus an index, but does not say what the set of nonterminals is,

* does not say what the set of terminals is,

* constrains the set of productions to include some rules, given the
presence of certain nonterminals in *V*<sub>*N*</sub> of G' and the
presence of certain rules in *P* of G, but does not say what the set
of productions is, and

* does not say what the start symbol is.

To be fair, we should bear in mind that Chomsky was inventing the
field, and the conventional description of a grammar as that 4-tuple
only came later. But Chomsky's description of grammars in section 2
(p. 141) does say quite clearly what the moving parts of the grammar
are:

> a system *G* of the following form: *G* is a semi-group under concatenation with strings in a finite set *V* of symbos as its elements, and *I* as the identity element.  *V* is called the "vocabulary" of *G*.  *V* = *V*<sub>*T*</sub> ∪ *V*<sub>*N*</sub> (*V*<sub>*T*</sub>, *V*<sub>*N*</sub> disjoint), where *V*<sub>*T*</sub> is the "terminal vocabulary" and *V*<sub>*N*</sub> is the "nonterminal vocabulary."  *V*<sub>*T*</sub> contains *I* .... *V*<sub>*N*</sub> contains an element *S* (sentences).  A two-place relation → is defined on elements of *G, read "can be rewritten as."  ...

So it's not as though he didn't realize that the four items in the
tuple are salient.

Perhaps he thought it was all obvious. In that case, I hate to be the
one to break the spell, but no it's not obvious.

Perhaps he is defining not a single grammar G' but a class of grammars
-- any grammars that satisfy the constraints explicit or implicit in
the description of the construction.

