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

