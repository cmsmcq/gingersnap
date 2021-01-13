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


