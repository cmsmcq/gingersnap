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

These appear to have come out all right.

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

<p style="font-size: smaller;">
(Post-hoc edit 16 January: Notation is a bit of an issue here.
Chomsky's notation is not well suited to typing in Markdown, and since
my goal is to explain the argument to myself I am inclined to use
notation more similar to what existing parts of Gingersnap already
produce. As I've been working on these notes, I've wavered a bit, but
now I'm going to go through and try to write things more consistently.
However, the notes are likely to be inconsistent in use of italics.
Nicer to read, but tedious to type in Markdown. Note also that Chomsky
uses symbols transcribed here as -> and => to denote the immediate
rewrites-as relation and its reflexive transitive closure, where I am
used to => and =>*. I'll try to follow Chomsky here, because the
asterisk often confuses Markdown.)
</p>

We are given a non-self-embedding grammar *G* in what we now call
Chomsky Normal Form and are going to construct an equivalent grammar
*G'*.

Since *G* is CNF, rules are all of one of the forms

    A: t.
    A: B, C. { B ne C }

There is also a restriction that appears to amount to saying that for
any pair of nonterminals *P*, *C* in a parent/child relation, *C* can
appear in at most one RHS of *P*.

Since *G* is not self-embedding, there is (by def. 7, p. 148) no
nonterminal N such that N => phi N psi for nonempty phi and psi. So
for every recursive nonterminal N in *G*, the recursion is either N =>
phi N (right embedding) or N => N psi (left embedding). This comes up
later.

Chomsky defines K as the set of sequences (N1, N2, ... Nm) of length
one or more, such that:

1. Any two adjacent symbols *N*<sub>*i*</sub>, *N*<sub>*i*+1</sub>
are in a parent/child relation, that is, there is in *G* a rule of the form

    > *N*<sub>*i*<sub>: phi, *N*<sub>*i*+1</sub>, psi

2. And no two symbols in the sequence are the same. 

Given the first restriction, N1 et al. must be nonterminals in *G*, so
what we have in K are sequences of paths in the stack language of *G*,
or equivalently sequences of symbols that can appear adjacent on a
parser stack when parsing *G*, and which contain no instance of
recursion.

I note in passing that there will be a finite number of such
sequences.

Chomsky specifies that the nonterminals in *G'* have the form (B1 ...
Bn)[i], for *i* in {1, 2}, where the Bs are nonterminals in *G*, and
"suppose[s]" (?!) that (B1 ... Bn) is in K.  

### Digression on notation

(Notation changed and prose revised 16 January.) To simplify things
and to relate this construction to Gingersnap, I'm going to re-cast
this and say that the nonterminals of *G'* all correspond to sequences
are nonterminals in *V(G)* and are formed by concatenating the
sequence with a separator. I predict that many if not all nonterminals
will be the nonterminals generated by ixml-to-rk-subset, so I'm going
to adopt a notation here that's closer to what that tool uses. So what
Chomsky writes (B1 ... Bn) when talking about it in some contexts and
[B1, ..., Bn] when writing it as part of a nonterminal in *V(G')*, I
am going to write as a base name plus an affix (which describes the
stack).

* Chomsky writes the sequence in root-to-leaf, ancestor-to-descendant
order. I'm going to reverse that and write in descendant-to-ancestor
order, so the item at the top of the stack is at the left. It is Bn
that determines the shape of the rules, so I interpret the compound
name as the base name Bn plus an affix describing the rest of the
stack.

* I'll put a separator between the identifiers from *V(G)*. The choice
of separator is irrelevant to the content, but it matters for reading
and typing. The tool ixml-to-rk-subset uses middle dot by default (16
Jan: the cnf-to-rg tool I wrote yesterday uses U+01C0 Latin letter
dental click, to work around a problem in nxml mode); here for
simplicity in typing I am just going to use a full stop.

* I'm going to put the subscripts at the end (earlier doesn't seem to
help), and to avoid interference from Markdown I'm going to use the
normal separator and not an underscore. (cnf-to-rg currently uses 'i'
and 'f', not 1 and 2, and puts the index at the start. The index is a
pain no matter where it goes, and while i and f are semantically
clearer, 'i' sorts after 'f' by default, which makes sorting produce
unhappy results.  Let's see if we can make peace with 1 and 2.)

So what Chomsky writes as

> [*B*<sub>1</sub> ··· *B*<sub>*n*</sub>]<sub>1</sub>, [*B*<sub>1</sub> ··· *B*<sub>*n*</sub>]<sub>2</sub>

I am going to write as:

> Bn.....B1.1, Bn.....B1.2.


### Back to the paper

Chomsky doesn't say so, but for the moment I think it's safe to imagine that  
the sequences used as nonterminals always start with the start symbol.
This won't be the smallest possible grammar (in practice, some stack
affixes are going to be equivalent), but I don't think it will cause
any errors. (Note from the future: yes. It takes him a couple pages to
get to it, but he does say on p. 154 that B1 ... Bn includes Bn and
all the nodes dominating Bn. Why he didn't lead with that, I do not
know.) (But another note: there are proof steps that work with partial
affixes, which appear to make no sense if B1 ... Bn includes the full
path from the start symbol to Bn.)

Chomsky then specifies patterns to be followed in the production rules
of *G'*. When I write grammar rules inline, I'm going to write rules
in parentheses, without final stops, but otherwise in ixml notation.

If *G* has  (Bn = a), then *G'* has

    Bn.....B1.1 = a, Bn.....B1.2.

This makes the subscripts 1 and 2 look a lot like 'before' and 'after.
Or, more precisely, like states N\_0 and N\_f in the RTN generated by
ixml-to-saprg. OK. Tentatively. (I'm going to refer to these as left-
and right-states; they can be thought of as roughly analogous to the
pre- and post-states on a node in a tree traversal.)

If *G* has (Bn: C, D) where neither C nor D occur in (B1 ... Bn), then
*G'* has

    Bn.....B1.1 = C.Bn.....B1.1.
    C.Bn.....B1.2 = D.Bn.....B1.1.
    D.Bn.....B1.2 = Bn.....B1.2.	

If we replace Bn.....B1 by N and ignore the stack affixes, this is
structurally the same as a call/return linkage in the recursive
transition network created by ixml-to-saprg.

    N_0: C_0.
    C_f: D_0.
	D_f: N_f.

That is: epsilon transitions from pre-state of parent to pre-state of
first child, from post-state of first child to pre-state of second
child, and from post-state of last child to post-state of parent.

Back to the construction. If *G* has (Bn: C, D) where D = Bi for some Bi
in (B1 ... Bn), -- that is to say, *G* has (Bn: C, Bi) -- then *G'* has

    Bn.....B1.1 = C.Bn.....B1.1. { Same as before. }
    C.Bn.....B1.2 = Bi.....B1.1.  { Trim the affix. }

Note two differences from the earlier case:

* Post-state of first child goes to pre-state of Bi.....B1 (the Bi
    ancestor), not Bi.Bn.....Bi.....B1 (the Bi child). We cut off the
    prefix Bi.Bn..... and just start from the second Bi.

    So informally: When we hit a recursive nonterminal, we trim the
    stack affix by eliminating the cycle. By trimming
    the stack we are ensuring that *G'* does not and cannot keep track 
    of how deeply Bi is nested. If *G* were self-embedding, that would 
    make *G'* broader. (D'oh.) 

* No transition from post state of last child Bi to post state of
  parent Bn.

Similarly, if *G* has (Bn: C, D) where C = Bi for some Bi in (B1 ... Bn)
-- i.e. *G* has (Bn: Bi, D) -- , then *G'* has

    Bi.....B1.2 = D.Bn.....B1.1. { Trim the affix. }
    D.Bn.....B1.2 = Bn.....B1.2. { As before. }

The changes are the mirror of those for the right-recursive case: The
transition to the pre-state of the second child comes from the
post-state of the ancestor Bi, not from the post-state of the child
Bi. (That may be misleading. There is no nonterminal in *G'*
distinctively representing the child Bi. The child Bi and the ancestor
Bi in the imaginary parse tree for *G* both map to the same nonterminal
in *G'*.) And there is no epsilon transition from the pre-state of Bn to
the pre-state of first-child Bi.

### What about the other cases?

Chomsky does not consider the situation where both C and D occur in
the stack-tracking affix. Either he thinks it's impossible because *G*
is not center-embedding (maybe so), or he thinks it's covered by the
third and fourth cases, or there is another explanation. If the idea
is that it's covered by what's said above, then perhaps I can work it
out. If *G* has (Bn = Bi, Bj) and we followed the first rule, and
didn't trim the affixes, then *G'* would have:

    Bn.....B1.1 = Bi.Bn.....Bi.....B1.1.
    Bi.Bn.....Bi.....B1.2 = Bj.Bn.....Bj.....B1.1.
    Bj.Bn.....Bj.....B1.2 = Bn.....B1.2.	

Trimming the affixes would give us:

    Bn.....B1.1 = Bi.....B1.1.
    Bi.....B1.2 = Bj.....B1.1.
    Bj.....B1.2 = Bn.....B1.2.

However, if we follow the pattern established above (no epsilon
transitions from pre-state of parent to pre-state of recursive first
child, or from post-state of recursive last child to post-state of
parent), then the rule would reduce to:

    Bi.....B1.2 = Bj.....B1.1.

I do not currently understand the absence of those transitions. Poor
me.

### Digression onto left- and right-embedding

I am also puzzled by the fact that when Chomsky illustrates the four
different situations he says we can be in (p. 153), the (Bn = Bi, D)
case shows the descendant Bi (left child of its parent) as deriving
from the left child of the ancestor Bi, and conversely for the
right-child case. I think this must follow from the fact that *G* is
not self-embedding, but I have to think about it for a moment.

We have either (Bi => phi Bi) or (Bi => Bi psi).

In the first case, we have (Bi => phi Bi), so the rule used for Bn
must be (Bn = C, Bi). Otherwise we'd have (Bi => chi Bi D) which
contradicts the premise. And if the derivation step for the ancestor
Bi was (Bi = X, Y), then the descendant must derive from Y, not X.
Otherwise we'd have (Bi => mu Bi Y), and another contradiction.

And similarly for the second case.

So stop being puzzled by the left- or right-handedness. If Bi is
right-embedding (first case), then it must always be the right-hand
child of a right-hand child, all the way up to the ancestor Bi. The
ancestor Bi does not need to be a right-hand child, though: if its
parent is non-recursive, that would be fine.

### Back to the exposition

When we have (Bi => phi Bi), then in the terminal strings of *L(G)* we
can have arbitrary many repetitions of phi -- i.e. phi<sup>*k*</sup>.
And similarly for psi if (Bi => Bi psi). Chomsky says "(iii) and (iv)
accommodate these possibilities by permitting the appropriate cycles
in *G'*."

Chomsky announces that he is going to prove that *L(G')* = *L(G)*, which
takes a long time, and then the main result of the paper, namely that
self-embedding is what makes context-free grammars more powerful than
finite-state automata.

I'm going to start by just paraphrasing the lemmas.

**Lemma 3.** For any sequence (A<sub>1</sub>, ... , A<sub>*m*</sub>) in set K,
then for all 1 <= *j* <= *k* <= *m* we have

> A<sub>*j*</sub> => A<sub>*k*</sub>.

**Lemma 4.** If (Bn.....B1.i = x, Bm.....B1.j) and C is not in those affixes,
and (C = alpha, B1, beta) -- note in passing that either alpha or beta
will be empty, don't panic -- then (Bn.....B1.C.i = x, Bm.....B1.C.j).

That is, in the absence of recursion, the stack affix of the
nonterminal Bn makes no difference: if for any affix aaa we have N.A =
x, M.N.A, then we have the same if A is aaab instead.

Here, Chomsky relies on the fact that he described the patterns
without explaining that the affix always described the complete stack.

I'm going to have to pause here. Even understanding the lemmas well
enough to paraphrase them is taking time, and I have to go now.

But before I go, this thought: perhaps the construction should be
recast more explicitly as the writing of a regular grammar?

### Later:  It *is* a regular grammar, yes, keep going

Let's see. The grammar rules all have one of the following forms
(using P for the parent, including whatever affix it may have, and A,
B for left and right child):

    P.1: 'a', P.2.
    P.1: {nil}, A.P.1.
	A.P.2: B.P.1.
	B.P.2: P.2.

So it is clearly a regular grammar in the post-Chomsky sense. The
construction as described so far has no final state; that may be what
Chomsky means when he says *G'* is equivalent to *G* "(when slightly
modified)".

(Addendum 16 Jan.  Note also that it's a *right*-regular grammar.)

### Back to paraphrase.

**Lemma 5.** (Paraphrasing very loosely.) Bn is either right-recursive,
and the right-hand child of a right-hand child, or left-recursive and
the left-hand child of a left-hand child. Proof is roughly as
described above; it follows from the premise that *G* is not
self-embedding.

## 2021-01-15:  something that feels like insight into my problem

Working with pen and paper this morning I concluded that one reason
things are so hard to understand at this point in the paper is that
the 18 lines of prose labeled "Construction" do not tell me how to
construct grammar *G'*. By modern conventions, a context-free grammar is
a tuple (*V*<sub>*N*</sub>, *V*<sub>*T*</sub>, *P*, *S*), where
*V*<sub>*N*</sub> is a finite vocabulary of nonterminals,
*V*<sub>*T*</sub> is a finite vocabulary of terminals,
*P* is a finite set of productions, and
*S* in *V*<sub>*N*</sub> is a start symbol.

The construction described by Chomsky specifies that the nonterminals
in *G'* consist of a sequence of nonterminals from *G* plus a suffix (1 or
2 in Chomsky's notation; I am now leaning towards pre and post, or 0
and f). He specifies that for a given nonterminal in *G'*, if rules of a
certain form occur in *G*, then certain rules of a specified form will
exist among the productions of *G'*. Unless I am missing something,
that's it.  So the construction of *G'*

* constrains the set of nonterminals to be sequences of nonterminals
in *G*, plus an index, but does not say what the set of nonterminals is,

* does not say what the set of terminals is,

* constrains the set of productions to include some rules, given the
presence of certain nonterminals in *V*<sub>*N*</sub> of *G'* and the
presence of certain rules in *P* of *G*, but does not say what the set
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

Perhaps he is defining not a single grammar *G'* but a class of grammars
-- any grammars that satisfy the constraints explicit or implicit in
the description of the construction.

### Later: how to move forward?  Initial conjectures

I've spent time trying to formulate my problem concisely, by drafting
a letter to a friend who might be able to help me understand the
paper. Drafting the letter helped, even though I do not expect to send
it. (Not their problem -- my problem.)

My current plan is reasonably simple. I will continue trying to
explain the paper to myself -- the record will be in this work log --
and my working approach will be (1) that the construction described in
Chomsky 1959 identifies a class of grammars, an infinite number of
which will have sets of nonterminals and sets of productions and start
symbols that let the proofs go through, and that (2) among that
infinite set there will be some, possibly just one, with the smallest
suitable set of nonterminals and the smallest suitable set of
production rules.

* My initial guess is that the smallest set of nonterminals needed for
the grammar *G'* is the Cartesian product of the indices 0 and f
(Chomsky's 1 and 2) with the set of pc chains (members of Chomsky's
set K) which begin with the start symbol of *G* and contain no repeating
nonterminals.

    I should define 'pc chains'. They are sequences of nonterminals (in
    the nonterminal vocabular of *G*) such that each one after the first
    appears on a right-hand side of a rule for the one on its left. So:
    members of Chomsky's set K. The name 'pc' is from parent / child,
    because this left-hand side / right-hand side relation is what leads
    to parent / child relations in the nodes of parse trees. I would like
    to call them daisy chains, and the individual members daisies, but I
    don't think I can pull it off.

    I have the impression, though, that some of the lemmas and proofs talk
    as if the nonterminals included all non-repeating pc chains of *G*,
    whether they start with S or not. So perhaps we will need to include
    all of them.

    And I am fairly confident that if *G* is self-embedding, a grammar made
    in the style of *G'* to recognize the subset of *L(G)* with at most *n*
    degrees of self embedding will need to include pc chains with up
    to *n*+1 occurrences of any nonterminal. So perhaps we will need to
    include even more nonterminals. Or perhaps the idea is simply to
    unfold the grammar, *n* times, in which case we get pc chains from
    the unfolding of *G* which have no repetitions but map 1:1 with chains
    for *G* which do have repetitions.

* My initial guess is that the terminal vocabulary of *G'* is that of *G*. 

* My initial guess is that the smallest set of production rules needed
for the proofs to go through is the set which includes all those
required by the construction (given a particular set of nonterminals)
and no others. (That is, I am guessing that Chomsky wrote that
rule *p* is in the set *P* if some condition holds, and did not bother
to say "and no other *p* is in set *P*". This may violate the rule of
charity in interpretation: it amounts to saying that he wrote "if"
though he meant "iff". But the alternatives currently appear even
worse.)

* My initial guess is that the only start symbol that is going to let
the proofs go through is S.0 (Chomsky's [S]<sub>1</sub>). Or perhaps
what I mean is that if I were trying to specify a construction of *G'*
to do what I think *G'* is supposed to do, I would choose S.0.

### Evening:  cnf-to-rg

I have now written a stylesheet, cnf-to-rg, to translate grammars in
Chomsky normal form into regular grammars, using my guess at the
meaning of the Chomsky's description of the construction, supplemented
heavily by guesses about "what would make sense" in cases where there
is nothing to guess at because the description just doesn't say anything.

As expected, providing all and only the production rules described by
Chomsky produces a grammar with no definition for the post-state of S
(S.f, in the notation I've been using here, fǀE in the notation
produced by the XSLT -- I'm not sure I'm happy with the index first,
but I remember quite clearly that I was unhappy with it coming last),
which means the grammar is not clean and *L(G')* is going to be the
empty set.

Not expected, but probably not surprising, is the growth of the
grammar. The toy grammar from which I started, in conventional ixml,
has seven nonterminals, with ten right-hand sides:

     expr: term+add.
     term: factor+mul.
     factor: num; var.
     var: ['a'-'z']+.
     num: ['0'-'9']+.
     add: '+'; '-'.
     mul: '*'; '/'.

The BNF version also has seven nonterminals with fourteen RHS.

The Chomsky Normal Form version has 12 nonterminals, with 33 RHS.

And the regular grammar (finite state grammar, I guess Chomsky would
call it) produced by cnf-to-rg has 199 nonterminals and 275 RHS.

At one point, Chomsky sounds a bit apologetic about the profusion of
empty transitions in the finite-state grammar constructed by his
rules. I was inclined to think there was no occasion for apology, but
... maybe there is.

It remains to be seen whether having implemented cnf-to-rg will help
me understand the paper.

## 2021-01-16:  Continuing through the lemmas

Spent a few minutes just now retweaking the notation in the notes from
14 and 15 January. I had been using middle dot as a separator and
wavering between 1, 2 and 0,f as indices. It's complicated enough
following these notes; those notational hesitations don't seem worth
preserving. So I'm going to try to be consistent in using full stop
and 1,2.

Now back to work. We had:

**Lemma 3:** If N1 precedes N2 in a rewrite chain (pc chain), then N1
=> phi N2 psi for some phi, psi.

**Lemma 4:** If (1) we have

    Bn.....B1.i: x, Bm....B1.j .

and (2) B0 does not appear in the affixed nonterminal Bn.....B1,
and (3) we have

    B0: alpha, B1, beta.

then we also have

    Bn.....B1.B0.i: x, Bm....B1.B0.j

Note in passing that this is inconsistent with my conjecture that the
nonterminals of *G'* will include all and only the symbols Bn.....B1
in which the base name Bn is a nonterminal in *G* and the sequence B1,
..., Bn is a repetition-free rewrite chain of *G* and B1 is the start
symbol of *G*. Because by the lemma, if the conditions are met then we
have two nonterminals with affixes ending in B1 and two ending in B0.
But B1 and B0 cannot both be the start symbol.

So cnf-to-rg does not generate all the production rules of G' as
specified.  It only generates the ones that are reachable.

**Lemma 5.** If *G* is not center-embedding, then any cycle in the
parent/child language on the nonterminals of *G* involves either only
left children or only right children.

It follows that if Bn.....B1 is in V(G') and (Bn: C, D) is in P(G),
then at most one of C and D can appear in the sequence B1, ..., Bn.

**Convention 2.** Given a derivation (phi<sub>1</sub>, ...,
phi<sub>*r*</sub>) for G', step phi<sub>*i*</sub> will take the form

> *a*<sub>1</sub> ··· *a*<sub>*i*</sub> *Q*<sub>*i*</sub>

Note: it follows from Lemma 5 that there will always be only one
nonterminal (here *Q*<sub>*i*</sub>) in any step, and each step in the
sequence produces at most one terminal (here *a*<sub>*j*</sub>). So
the form shown follows from the setup. Note also that many of the
terminals will be the empty string (the identity *I*); *a*<sub>*j*</sub>
will only be a non-empty terminal symbol if the relevant step followed
rule (i).

## 2021-01-17 test cases for test case generation

### Error in FSA generation

The other day I noticed that a test was missing in the arc-final
coverage for a.ixml. As I've mulled that over in the back of my mind,
I have come to suspect a problem not (only) in the generation of
tcrecipes but (instead, or also) in the generation of alpha and omega
paths.  

As a way to smoke out mistakes, I thought I would start with the
simplest FSAs I could imagine: FSAs with a single state and no arcs,
one state and one arc, etc. Seven simple test cases with 1 or two
states and zero to two non-empty arcs are now in toys as g010.ixml
etc.

They are already FSAs, but to avoid problems if they lack the expected
annotations, I ran them through R0-subset, which runs a pipeline of
annotate-pc, annotate-gl, and make-rtn. The first one I looked at has
an error in its output. I wasn't looking for problems in R0-subset,
but let's take it as an opportunity.  First, survey them all:

* g010: S0 has no arcs and is not final; Sf is marked final but is
unreachable.

* g011: S0 not marked final, nor is S1. S2 and Sf are linked as
expected but unreachable.

* g012: Again problems; looks like the empty arc on S is mishandled. S0
is not marked final, S3 is unreachable. I also see that the initial
ixml grammar has a typo and is not what was intended. After repair,
problems similar to those already noted: S0 is not marked final, and
Sf is final but unreachable.

* g022: (At this point I paused to write rg-to-dot, because I was
begininng to be bored with drawing the FSAs by hand to look at them.)
Again S0 not final, Sf unreachable.

* g101: 'a' is not repeatable.  Sf again unreachable, and this time
it's correct that S0 is not final.

* g102: Result is analogous to g101.  I.e. not correct.

* g112:  This is not getting any better.

OK, all seven of these are borked.

I had not yet looked at three of these when I began to suspect that
the Gluschkov annotation step is not prepared for epsilon transitions
or final-state marking. How happy I should be that I found this now
instead of later; how embarrassed I am that I found it now insted of
earlier! (But the psychology is clear, even if deplorable: I wanted to
pass the Andrews test on input that was not an edge case of the kind
illustrated by these grammars. And as my to-do list shows, it was
having something that works well enough that I wanted to use it and
worried about breaking it that provided the motivation to put tasks
involving better testing and formalization on the task list. The
reason I did not see this before is that I was trying to get the
pipeline to work for the Program grammar and the ixml grammar, which
do not give any visible sign of exercising these edge cases. So I'll
try to look on the bright side.)

What to do now?

* Back up and fix the pc | gl | make-rtn pipeline to produce correct
FSAs? Then finish the task of making test cases from them for the
test-case production steps. Then re-run a.ixml and see if the results
look better.

* Flow around this problem: Determinize the originals, annotate them
further by hand if need be, and proceed with my work on test-case
generation.  Then go back and fix the pc, gl, make-rtn pipeline.

I'll think about this as I do something else for a while.

√
### Working on Gluschkov automaton annotation and FSA generation

Well, that decision didn't take long; I hadn't gotten up before I
started sketching what the RTN automaton should look like.

Found that the Gluschkov annotation was correctly reporting both
the list of last positions and nullability of the expression as a
whole, but that ixml-to-saprg was acting as if only the last positions
were final.  Added code to detect nullability on the rule and
add an epsilon transition from N<sub>0</sub> to N<sub>f</sub>
in that case.

The grammars now being produced all look correct.  But given
that there are so few terminal-labeled transitions, the machinery
for stack management and finality takes a disproportionate
share of the FSA.  The R0 FSA generated from g112 has two
arcs labeled 'a', and eight labeled epsilon.  And eight states
instead of two.  I should stop being appalled by the number of
epsilon transitions in Chomsky's finite-state construction.

(Hey, nice side effect: writing rg-to-dot this morning means I will be
able to look at the generated grammar a bit more conveniently.)

The RTNs being generated may be good test cases for tclego
and friends, but they are not the test cases I was trying to make,
so in fact I do want to determinize the original grammars (and
change g012 into a regular grammar if I can) for the work on
tclego.

But now I really do need to do something else for a bit.

### Attempting to reduce duplication in tcrecipes

Added a filter function to the step that reads lego data and produces
test-case recipes, but it does not seem to be reducing the number of
recipes at all, and the results are as repetitious as before.  There may
be a bug in the filtering code, or I may have invoked things wrong.
I notice that empty arcs cause some traces to be different but produce
the same recipe.

On the plus side, I appear not to have broken anything.

I'm going to give up on this for now, and plan to filter on the actual
test cases, if need be.

Actually, the repetitions can usefully be ignored at the moment. It
was the positive tests that proved very repetitious; the negative
tests are all distinctive. And while it's puzzling and I would like to
fix it, in the immediate future I want to produce parse trees for the
positive test cases, which means using the original grammar, not a
subset approximation.

I will need to review the work I did on generating positive cases a
couple of years ago.

## 2021-01-18 Planning work on positive test case generation

Some notes from 2019 identify three ways to generate test cases for a
regular language. And since the RHS in an EBNF grammar notation like
ixml are regular languages over the vocabulary of G (i.e. V(G) union
T(G)), they all come up in connection with test cases for context-free
languages as well.  They are:

* **arc-based coverage**: From an FSA, generate arc-internal and
arc-final coverage (or state-internal and state-final, but my notes
only mention arcs).

* **expression-based choice coverage**: From a regular expression, 
generate an and/or tree, and from that generate test case recipes that 
guarantee that every child of an OR is included at least once. 

* **Cartesian product of choices**: From a regular expression, 
generate an and/or tree, and from that generate test case recipes that 
include the Cartesian product of all choices.

The difference between expression-based choice coverage and the
Cartesian product is visible for an expression like ((a|b), (c|d)).
The expression-based approach will (as implemented in 2019) generate
tests for ac and bd. The Cartesian product will generate ac, ad, bc,
and bd.

In 2019, I ended up concluding that expression-based choice coverage
might be a good first approach, though it was less thorough than
arc-based coverage. Cartesian product produced a lot more tests and
its yield (errors detected per test) seemed likely to be lower. But
Cartesian product was the simplest to implement.

In August of 2020 I wrote notes that say

> It's easy to control how many positive-example schemas are produced
> by the Cartesian-product method by using finer or coarser
> pseudo-terminals. Given that, Cartesian product's yield need not be
> all that low. And since it's easier to implement correctly, it's
> probably preferable.

After looking again at the notes from 2019 and 2020, that still seems
plausible. So I will look to see if I have already implemented the
construction of and/or trees and the Cartesian product approach (I do
seem to remember implementing expression-based choice coverage and
finding the bookkeeping tedious, unintuitive, and error-prone), and
then decide whether to adapt that code or rewrite it from a blank
page. (It seems obvious to me now that I don't need to improvise a
vocabulary with elements named *and* and *or* when I have ixml
with *alt* and *alts*.)

In the earlier notes, my plan was to translate E* and E+ to E{0,2} and
E{1,2}; this morning I am inclined to make that (E{0,2} | E{15}) and
(E{1,2} | E{15}), or some similarly arbitrary 'high' number. Perhaps a
parameter.

### Pipeline for lego pieces

We can get to what my earlier notes called 'lego pieces' for test-case
construction (analogous to the 'tclego' in the FSA-to-testcases
workflow, but not identical) with a deceptively simple workflow:

* Unroll repeat0, repeat1, and option.  This is a lossy rewrite:

	* `E*S` rewrites as (empty | E | ESE | E(SE)<sup>*n*</sup>),
	where *n* + 1 is the user-specified 'high number'.

    * `E+S` rewrites as (E | ESE | E(SE)<sup>*n*</sup>).

    * `E?` rewrites as (empty | E)

This is structurally the same as the unsimplified and/or tree of 2019.

I think that by default we do not want to unroll the RHS of
pseudo-terminals, but I may be wrong.

* Reduce to disjunctive normal form. This is a non-lossy rewrite that
simplies the and/or tree expressed by `alt` and `alts` to a single
top-level disjunction over flat sequences of terminals and
nonterminals. Specifically, we move any expression that match the
patterns below into the form on the right. 

    * (E, (F, G)) = ((E, F), G) = (E, F, G) 
    * (E; (F; G)) = ((E; F); G) = (E; F; G) 
    * ('', E) = (E, '') = E
    * (E, (F; G)) = (E, F); (E, G) 
    * ((E; F), G)) = (E, G); (F, G) 
    * (E; E) = E

Since in ixml both comma and semicolon are n-ary operators not binary,
the actual forms used will vary.

At this point we have a grammar that generates a subset of the target
language, but we do not yet have what we need.

What we need, as testcase recipes, is a set of parse-tree fragments
whose root is the start symbol of G and whose leaves are all terminals
or pseudo-terminals. And ideally, we would like this set to provide
good 'coverage' of the grammar.

### Coverage measures

The coverage measures I have thought of are:

* **lego piece coverage**: Each top-level sequence in the disjunctive
normal form of the grammar is used at least once.

* **parent/child completeness**: Each parent/child pair in G appears
in at least one tree. (This should follow from lego coverage, since
the DNF will involve very complete coverage of each RHS for each
nonterminal.)

* **ancestor/descendant completeness**: Every ancestor/descendant pair
in G appears in some tree.

* **stack-path completeness**: The set of root-to-leaf paths in the
test case forest provides arc-internal coverage of the FSA for the
stack-path language of G (the FSA built on the parent/child relation).

For now, I think lego-piece coverage is all we want. Stack-path
completeness seems likely to produce tests with low average yield.


### Building parse-trees to serve as test-case recipes: alpha, omega 

How to achieve lego-piece coverage? The 2019 notes suggest a method
similar in its way to the alpha/omega path approach used for FSAs:

* For each nonterminal N, find the smallest tree(s) rooted in S with N
as a leaf. (This is analogous to finding the shortest alpha-path from
S to N in the stack-path language.)

* For each nonterminal N, find the smallest tree(s) rooted in N with
no nonterminal leaves. (Analogous to finding the omega paths for
FSAs.)

But note that putting these together is going to have the same
tendency to repetitiveness as the positive stack and arc coverage in
FSAs does.

### Building parse-trees randomly / depth first

Here is another approach. We imagine that we are building things with
Lego pieces, which we keep in piles and select and combine according
to rules. It will probably be helpful if we construct the stack-path
FSA for G, or at least build up a list of parent/child pairs we can
consult, indexed by child (the lego pieces themselves will be indexed
by parent).

**Preparation**

* Start with all the lego pieces in a pile labeled 'New'. (Using a map
with RHS keyed by their LHS ought to work.)

* Also start with an empty pile labeled 'Used'.

* Set some limit to the depth of any tree (say, 4 * |V|?). 

* Set some limit to the number of failed attempts. (I have no idea,
but I want a guarantee that this process will terminate.)

**General rules**

* As a general rule, when selecting a lego piece, if there are a
suitable pieces in the New pile, use one of them. Otherwise take one
from the Used pile.

* Whenever a piece is used, remove it from its earlier location and
place it at the bottom of the Used pile.

* When there are multiple suitable pieces in the New pile, pick one at
random. When picking a piece from the Used pile, take the first one
found. (Do either of these rules matter? Hmm.)

**Build trees**

* If the New pile is empty, we are done.  Stop.

* If we have reached the failed-attempts limit, we have failed.
Something has gone very wrong and a more intelligent algorithm will be
needed. Stop.

**Build one tree**

* Otherwise, take a piece from the New pile.

    As long as there are pieces for the start symbol S in the New
    pile, start with one of those.

    Build a (partial) tree T consisting of the pieces left-hand side
    as parent and its RHS elements as children. (Does starting with S
    where possible actually matter? Hmm.)

* Let N be the root of T. If N is not S, then first build 'up' by
finding a lego piece with a leaf labeled N, rooted in some nonterminal
N2.

* Continue building up until T is rooted in S or until T exceeds the
depth limit.

* If T exceeds the depth limit, then increment the failed-attempt
count and skip to *Build trees*.

* Now build down: For each nonterminal leaf N in T, select a lego
piece rooted in N and plug it in.

* Continue building down until T has no nonterminal leaves or until T
exceeds the depth limit.

* If T has no nonterminal leaves, the tree is done. Put it in the
results and go back to *Build trees*.

* If T is unfinished after the cycle limit is hit, then something may
have gone wrong. Increment the failed-attempt count and go back
to *Build trees*.

This approach of building trees essentially at random seems unlikely
to produce an optimal result (however one might define 'optimal'), but
it has the advantage that we are only ever dealing with one tree at a
time. It's like a depth-first search in a search space.

### Breadth-first?

We could try a breadth-first search -- Grune and Jacobs decribe it in
their chapter 2 -- but I expect that in general the DNF form of the
grammar will have several RHS for each N, and we'll end up very
quickly with a very large number of trees if we replace each N with
each of its RHS.

### Manual construction?

For converting FSAs into regular expressions, I found it helpful to
produce tools to let me specify the steps manually. What would the
analogous steps be here? The only primitive operations are selecting a
lego piece, attaching a lego piece at a location, and testing for
completeness. I could imagine an interactive interface that worked
something like this: Tool displays a partial tree T, with nodes styled
to indicate whether they are pseudo-terminal, terminal, or
nonterminal. (Frege-style tree or directory-style tree would work.)
User clicks on a nonterminal leaf to open a menu of options, chooses
one. The menu keeps a count of how many times each option has been
selected, so user can manage coverage manually. When the tree is done,
it's saved and we continue.

This could work from the raw grammar, as well. Click on the
nonterminal, get its RHS. Now the tree will contain not just
nonterminals, pseudo-terminals, and terminals, but also the other
elements of the ixml grammar. Click on E? and get a choice of E or
epsilon. Click on E+ or E* and get a choice of occurrence count. The
counts would be kept for each `alt`, `repeat1`, `repeat0`, and
`option` in the grammar. (If we wanted to go down into the terminals,
then also on the members of a charset. But I don't think I do want to
at the moment.)

### Evening:  unroll-occurrences and dnf-from-andor

I've written a module to unroll option, repeat0, and repeat1, with a
user parameter for how many occurrences to use for the repeats in
addition to 0 and 1. And a module to reduce the result into
disjunctive normal form. When there are nested occurrence indicators,
or an occurrence indicator on a choice, the numbers grow very fast:
(a; b)* expands, given a 'high number' parameter of 10, into 1027
choices (one empty, one a, one b, and 1024 combinations of a and b.
Similar but not exponential growth will occur when there's more than
one Kleene operator in a rule.

In the ixml grammar for ixml, this hits both the definition of S and
that of comment, but nothing else. The user appears to have a choice:
* keep *n* low (say, 3 or 4 -- even 5 is rather tedious when it lists
all 32 combinations of choice a and choice b), or
* use a higher *n* and hand-edit the disjunctive-normal form grammar
to delete most of the disjuncts in cases like these.

For now, I'm going with keeping *n* low: 3, or even 2. A single test
in Knuth's style may be rhetorically effective, but it probably
doesn't provide as much help as one might wish in finding the problem
if one fails. A series of simpler tests is more informative. The
testing of the unrolling and disjunctive normal form modules is a case
in point. When the initial results were puzzling, I wished I had
started with simpler test cases.

Next step: generation of partial parse trees with terminal and
pseudo-terminal leaves, but not actual characters. Trees without
characters?  Musil trees?  It must be late.

## 2021-01-19 Implementing parsetrees-from-dnf

For the algorithm as I worked it out yesterday, I need to be able to
find RHS for production rules based on their LHS, based on the
nonterminals they contain, and based on whether they are new or old.

Trying to work out how to structure a map to keep track of that took a
while. When I was done, I realized I don't think I need a map at all.
The RHS are all alt elements, and they are all present in the grammar.
All I need to do is keep track of which have been used and which not.
And if I am worried about speed (why?  it's not running slow at the moment,
because it's not running at all, because I'm writing this and not
writing the program!), I can just use keys.  Set operations are a
wonderful thing.

## 2021-01-20 Continuing implementation of parsetrees-from-dnf

### How to grow the tree

Growing the tree downward seems to be possible in several ways.
Which should be used?

* **normal**. A normal call to apply-templates will grow the tree fine but won't 
be able to track usage of the RHS in the disjunctive normal form 
grammar.  So, no. 

* **right-sibling**. A manual depth-first tree traversal with explicit
right-sibling call would work. I am not sure why it isn't more
attractive but perhaps it just feels a bit like work. It would require
a template for each node we traverse, not just one template for
nonterminal.

* **apply-templates plus inspection**. We could initialize a variable
with a normal call to apply-templates and then inspect the result tree
to see which new RHS are used. To simplify the inspection, each
nonterminal would carry the identity of the RHS used to initialize it.
(Adding a key on RHS with the generate-id() result for that RHS as the
key value would simplify that lookup.) This would not prevent
duplicate uses of a RHS in the same generation, but with luck that
won't happen often. This idiom is well represented in Gingersnap
already; it's the way the transitive closure of references is managed
in the CNF-to-RG transform and others.

* **multivalued return**. All templates in the grow-the-tree mode
could return multiple values: an element and a sequence of RHS used to
grow that subtree. This resembles the multivalued returns used in the
recursive-descent parser for ixml I wrote last fall. This would
require explicit templates for all nodes, no defaulting allowed.

I think I'm looking at a right-sibling traversal here.

### Form of partial parse trees

The form of the parse trees should also be recorded. The other day I
sketched out three possible forms. As an example, I'll use an example
from the ixml spec.

          <expr open="(" sign="+" close=")">
            <left name="a"/>
            <right>b</right>
          </expr>

* A literal parse tree -- like the one ixml should return, but with
terminal elements instead of character data at the leaves, and with
@mark (or @gt:mark) attributes.

          <expr mark="^">
            <open mark="@">
              <literal dstring="("/>
            </open>
            <arith mark="-">
              <left mark="^">
                <name mark="@">
                  <literal dstring="a"/>
                </name>
              </left>
              <op mark="-">
                <sign mark="@">
                  <literal dstring="+"/>
                </sign>
              </op>
              <right>
                <name mark="-">
                  <literal dstring="b"/>
                </name>
              </right>
              <close mark="@">
                <literal dstring=")"/>
              </close>
            </arith>      
          </expr>

* An expanded form of ixml

          <nonterminal name="expr" mark="^">
            <nonterminal name="open" mark="@">
              <literal dstring="("/>
            </nonterminal>
            <nonterminal name="arith" mark="-">
              <nonterminal name="left" mark="^">
                <nonterminal name="name" mark="@">
                  <literal dstring="a"/>
                </nonterminal>
              </nonterminal>
              <nonterminal name="op" mark="-">
                <nonterminal name="sign" mark="@">
                  <literal dstring="+"/>
                </nonterminal>
              </nonterminal>
              <nonterminal name="right" mark="^">
                <nonterminal name="name" mark="-">
                  <literal dstring="b"/>
                </nonterminal>
              </nonterminal>
              <nonterminal name="close" mark="@">
                <literal dstring=")"/>
              </nonterminal>
            </nonterminal>
          </nonterminal>

* A parse-forest grammar:

          <ixml>
            <rule name="expr-1-5" mark="^">
              <alt>
                <nonterminal mark="@" name="open-1-1"/>
                <nonterminal mark="-" name="arith-2-4"/>
                <nonterminal mark="@" name="close-5-5"/>
              </alt> 
            </rule>
            <rule name="open-1-1" mark="@">
              <alt>
                <literal dstring="("/>
              </alt> 
            </rule>
            <rule name="close-5-5">
              <alt>
                <literal dstring=")"/>
              </alt> 
            </rule>
            <rule name="arith-2-4">
              <alt>
                <nonterminal name="left-2-2"/>
                <nonterminal name="op-3-3"/>
                <nonterminal name="right-4-4"/>
              </alt> 
            </rule>
            <rule name="left-2-2">
              <alt>
                <nonterminal mark="@" name="name-2-2"/>
              </alt> 
            </rule>
            <rule name="right">
              <alt>
                <nonterminal mark="-" name="name-4-4"/>
              </alt> 
            </rule>
            <rule name="name-2-2" mark="@">
              <alt>
                <literal dstring="a"/>
              </alt> 
            </rule>
            <rule name="name-4-4" mark="@">
              <alt>
                <literal dstring="b"/>
              </alt> 
            </rule>
            <rule name="op-3-3" mark="-">
              <alt>
                <nonterminal name="sign-3-3"/>
              </alt> 
            </rule>
            <rule name="sign-3-3" mark="@">
              <alt>
                <literal dstring="+"/>
              </alt>
            </rule>
			</ixml>

Literal results and extended ixml don't work well for test cases for
ixml itself. The parse forest grammar does not work when we are trying
to build the parse tree.

So a fourth style is needed: every node in the (partial) raw parse
trees we build is one of the following.

* a `nonterminal` element to be replaced by a RHS as part of testcase
recipe generation

* a terminal element (`literal`, `inclusion`, or `exclusion`) to be
replaced by characters as part of testcase generation.

* a `gt:element` element to be turned into an appropriate element or
attribute node, or deleted, as part of testcase generation.


### Back to growing the tree

There have been distractions and interruptions today, but eventually I
got back to this and set out to right the pre- and post-order
traversal needed to get a single round of template application with
replacement of nonterminal leaves with RHS. There is a wrinkle I had
overlooked -- I guess my unusual traversals have all just been
traversing a flat sequence, rather than a tree.

In the first visit to some gt:element E, I need to copy E itself as E'
and move to the first child of E. That child calls its siblings. All
as normal. But everything called by the first child of E ends up as a
child of E' -- including, unless I find a way around it, the nodes
produced from the right siblings of E, which should be siblings of E',
not children.

So I'm back to the drawing board. Perhaps I should go back
to *apply-templates plus inspection*, but that feels too much like
defeat.

So my next plan is a sort of merge of right-sibling traversal and
multivalued returns.

The parent element E needs to capture the results of its call to
apply-templates in a variable. Those results need to include the nodes
produced by the children of E, and some information about their effect
on $new and $used. (Because the template for E knows what $new and
$used were when it passed them to the first child, all we need is a
list of what was freshly used in processing E's children.)

So the last child of E should return not only its normal result, but
also a separator and then the list of freshly used alt elements.

## 2021-01-21 Parse-tree generation

The module parsetrees-from-dnf is now completely drafted, and after
a bit of a argument Saxon accepts it as type-correct, and it runs.
But trees are growing to the limit more often than I had expected,
and the toy test g.roundrobin.ixml makes me suspect that the way
right-hand sides are queued for re-use (i.e. the management of the
`$used` parameter) is not correctly implemented.

But I'm going to check in the current version, just to have a check point.

(Later.)  One problem was inconsistency on whether the parameters passed
in the right-sibling traversal were to be tunnel parameters or not.  If
you receive them as tunnel parameters but pass without tunnel="yes",
the results will not be as expected.

Running the module on ixml now produces just two tests, but only one
of them is actually a complete tree; the second fails with 29,000 elements
and a height of 21.  There are 1951 unexpanded nonterminal elements in
the failed attempt, 1894 of them 'comment' or 'cchar'.  The flaw here appears
to be that the way things get expanded, there is a higher likelihood than
desirable that comments will nest.

That falls, I supposed, into the class of 'unlucky expansions' that led me to
want to be able to leave pseudo-terminals unexpanded.  I wonder:  if I
specify just comment as a pseudo-terminal, would the module succeed in
building a full test case?

Modifying the module to accept a list of pseudo-terminals provides the
answer: with maxdepth set to 20, 30, 40, 50, and 60,
parsetrees-from-dnf produces five trees each time, of which 4, 3, 3,
3, and 2 are failed attempts. Increasing the maximum depth by tens
makes the failed trees larger and larger, and slows down the
execution, but does not reduce the number of failed trees to 0.

It's clear that I have both a practical problem (I need completed
trees) and possibly a design issue (I want an algorithm to produce a
set -- preferably the smallest set -- of complete trees that cover the
disjuncts, and what I've got is something else).

Would it help to grow in the other direction? Perhaps some or all of
the following might help?

* Extend or adapt gt:make-trees() or it caller to accept a nonterminal
N and produce trees for N. Note that in this case we must always start
with N, not with an arbitrary RHS, because we cannot assume that from
an arbitrary N we can find a path ascending to the root.

    This could be used to produce a grammar for the pseudo-terminals.

* Write a separate stylesheet to accept a partial tree and grow it,
either with respect to the original DNF or using an alternative
grammar. For the cases I have in mind, there is no need to track which
disjuncts are used.

    This could be used to complete the failed test cases being
produced now.

* Manually edit the DNF to produce terminal alternatives for selected
nonterminals.  (This could be just selection from automatically generated
cases.)

Perhaps the minimal-cost approach right now is:  for any grammar

1. Unroll, make disjunctive normal form, generate some trees, possibly
with a judicious selection of pseudo-terminals.

    In the case of the ixml grammar, running parsetrees-from-dnf with
	maxdepth=20 and pseudo-terminals=comment produces one complete and
	four partial trees.

2. Make a list of the unexpanded nonterminals that need to be replaced
by suitable subtrees.

    In the case of ixml, There are 35 distinct names among the
	unexpanded nonterminals in those trees (of 45 nonterminals in the
	grammar).

3. For each item in the list, choose one or more replacement strings.
For pseudo-terminals, several strings are probably desirable. For
other nonterminals, one suffices. The partial trees already have
complete coverage of the DNF for those nonterminals; the manually
selected sentences for them don't need to exhibit any variety to help
with coverage.

4. Replace the nonterminals remaining in the partial parse trees with
the replacement strings.

## 2021-01-22 Trying to re-plan positive test generation from CFG

Everything remains a bit hazy. I'm not happy with the behavior of
parsetrees-from-dnf but I have not managed any statement of the goal
crisp enough to guide an implementation. And perhaps for that reason I
don't see a clear path to improvement. A few paths seem to
invite exploration.

* From G create a regular grammar describing the stack path automaton.
(Name generation will need to be re-done in Gluschkov annotator to
preserve the nonterminal as the state name.)

* From the stack path FSA alpha and omega paths can be generated and
combined to form spines for test cases.

* Spines can be filled in - at each step in the spine, we have a
parent/child link so we choose a RHS of that parent containing that
child (thus giving the child siblings). This will leave a lot of leaf
nonterminals. Expand these using a collection of sentences in L(N) for
all N in G. Deduplication will likely be necessary.

* From G generate a small collection of sentences in L(N) for all N in
G. This can be used in several ways, no doubt; it's mentioned in the
previous item, but it would also allow me to generate partial tests
with parsetrees-from-dnf and then complete them.

    Here the central idea is the lego piece, to reduce complexity and
    variation in the task of expanding a nonterminal in a partial
    parse tree.

* Given a collection of sentences from L(N), whether constructed
manually or automatically, expand leaf nonterminals in a partial parse
tree to make a full parse tree (modulo the fact that the terminals
will sometimes be inclusions or exclusions, not literals, so like all
the parse trees I have been worrying about this week they are parse
tree schemata or parse tree skeletons or parse tree patterns or parse
tree recipes.

(Evening) It occurs (or re-occurs) to me at this point, while
re-formulating the list just given, that (a) what I need is not (just)
sentences from L(N) but parse trees, since they have to be plugged
into the sockets provided by the leaf nonterminals, and (b) that the
collection of trees produced by parsetrees-from-dnf may well already
have such trees.

Some quick exploration with BaseX shows that this is in fact the case
-- the set of trees in which I had created while specifying `comment`
as a pseudo-terminal even had complete trees for comment, which
frankly I don't understand. (Or rather, don't wish to, because it's
pretty evidently a bug.)

So now I have two quick stylesheets to write, or maybe only one:

* read a set of parse trees and extract one or more complete trees for
each nonterminal specified by the user (default: all of them); choose
the smallest such trees, since we are only interested in filling gaps.

* read a set of incomplete parse trees and a set of complete trees,
and replace each leaf nonterminal with a complete subtree.

These could be done in a single stylesheet, but they will be simpler
separate.

(Later.)  Done.  They seem to work.

Running the unroll / dnf / parsetree pipeline on a.ixml produced two
test trees (or sentences): 'a' and '(a)'.  That covers the set of RHS,
but it somehow feels more satisfying if there is a test like
'((((((((a))))))))'.  Perhaps a stylesheet to find an ancestor/descendant
pair for a specified nonterminal and modify the test case by
replacing the descendant with a copy of the ancestor, repeatedly
(d times, d to be supplied by user, default to 8 or 5 or ...).  But not today.

Current state of play: I have modules to go from an ixml grammar *G*
to an O<sub>*n*</sub> superset of *G* to a deterministic FSA for the
superset to a set of negative test cases for *G* based on the
superset, with minimal human intervention. I have other modules to go
from ixml to a set of positive test case recipes, with parse trees,
with human intervention possible if required. Currently the biggest
problem is that the process is kind of cumbersome wherever the work
flow is not a linear data flow.  (Well, that's optimistic.  Currently the
biggest problem is that when I run these on new grammars they
occasionally roll over or behave badly.  But the business of remembering
how to invoke all the necessary steps is predictably tedious, not
unpredictably exciting.)

Either a bunch of scripts or a make file seem like a plausible investment.
And of course recent work must be integrated into pipelines.

* Check that the parse trees generated by parsetrees-from-dnf and
parsetree-pointing can be turned into test cases by the existing tools
(adapting and extending as need be).

* Integrate the new modules into the grammar pipeline handler; write
pipelines.

* Write a make file to create the different work products (and write
out reminders about what has to be done manually).

* Recapitulate the work flows on a.ixml.

* Resume the tour of the toy and sample grammars.

* Review QT and XSD test suite schemas; design ixml test suite schema.

* Make test case generator produce test suite catalog with inline or
external test cases.


## 2021-01-24 Progress on testcase generation

Have written stylesheets to turn the parse trees into test cases; have
concluded that I need to distinguish the raw parse tree we expect a
parser to produce (represented as an XML element structure, roughly
what an ixml parser would produce if all the marks were '^'), the
cooked parse tree or AST produced by attending to the marks, and the
parse tree matrix (or skeleton, or pattern, but for the moment I like
matrix).

Am checking everything in now as a sort of checkpoint, but am aware of
two or three issues in testcases-from-parsetrees-cooked.xsl: terminals
are not being suppressed properly (they are not attending to the
@tmark attribute), terminals are being output twice (once in default
mode and once in attributes mode, I suppose), and attributes are not
being created properly.  The second and third are surely related.

(Later.) That was confusing enough to take a little time, but
attributes are now being emitted without error in the ixml test cases
in the toys directory, and I believe they are correct.

## 2021-01-26 More progress 

Have spent the last two days running the flows from the ixml document
to positive test cases and through the O3 superset to negative test cases.

The ixml-tests project now has positive and negative test cases for
the gxxx grammars, and positive test cases for the arithmetic expression
grammar.  The O3 superset flow is running into difficulties, because
ixml-to-saprg is not dealing well with pseudo-terminals in the case
that a start symbol is specified.  Apparently the revision did not
handle all cases:  either I didn't implement it right, or I overlooked
something.

Or possibly when revising the transform I expected pseudoterminals
to have been expanded in place.

## 2021-01-26 Asymptotic progress

Taking the O0 versions of expr, term, and factor in the arith.ixml grammar
and simplifying them to a single rule was a very painful experience.  Found
bugs in ixml-to-saprg, and the make file and R0-subset transform were not
much help.  Eventually got the simplifications by a much more manual process
than I would have liked, involving factoring some disjunctions into ad hoc
nonterminals by hand, halfway through the development.  (I don't have a
tool for doing such factoring, because specifying what to factor seems
tricky.  Perhaps I just need to bite the bullet and allow tumbler references
to the subexpression I have in mind.)

Eventually got it done, and generated the negative tests.  Put them into the
ixml-tests project.

If I can, this afternoon I'll do tests for ixml itself.  That may be a challenge.

