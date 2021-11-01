# Overview of Gingersnap

Gingersnap is a collection of tools for working with invisible-XML grammars.

'Invisible XML' is the name given to an idea put forward by Steven Pemberton:  we can make non-XML resources accessible to XML-based tools by writing a grammar describing them and using an invisible-XML parser to use the grammar to parse the resource and produce an XML representation of the resource.

Gingersnap is not an invisible-XML parser.  (There are a few in development.)  It's a tool to do things with ixml grammars.

2021-01-23, rev. 2021-01-24

# What's here

This is currently just a list of the stylesheets and modules in the Gingersnap library, with brief descriptions of what they do.

It does not explain how to do anything useful, or provide examples.  That will have to wait.

In its current state, Gingersnap is messy.  Its primary job so far has been to enable the author to get some specific tasks done. The stylesheets work, at least on the data processed so far, and it's possible to string them together to do useful things.  But the library has been written piece by piece as things were needed, and the kind of consistency that follows from a clear central plan is mostly missing.  Naming conventions are inconsistent, and putting sequences of transforms together into work flows requires an awareness of a great deal of detail irrelevant to the ultimate goal.  (The library thus qualifies as 'low-level' by Perlis's criterion.  I comfort myself by reflecting that he also said "Everything should be built top-down, except the first time," and also "Simplicity does not precede complexity, but follows it.")

So:  anyone is welcome to look around and play with the library. but potentially interested users should be warned that in its current state, the library may be unnecessarily and frustratingly difficult for other people to use.  You have been warned.  (And it's no good telling me I should write some introductory documentation.  I agree; it's on the to-do list.  But better documentation is currently less urgent than the things above it on that list.

## Subclasses of grammar

Unless otherwise indicated, all stylesheets read an ixml grammar and produce an ixml grammar.  Within that broad category, several subtypes of grammars may be distinguished:

* *right regular grammars* (sometimes abbreviated RG) have rules in which each right hand side has one of the forms

     * *n1*: *t* ,*n2*
     * *n1*: *n2*  (often written *n1*: `{nil}`*n2*  to make clear that the absence of the terminal is not an error)
	 * *n1*: `{nil}`.

    Because at the moment nothing in Gingersnap expects or produces a left-regular grammar, the documentation will often use the term *regular grammar* to mean *right regular grammar*.

    Right regular grammars correspond very directly to finite state automata; the first two rule forms describe transitions from state *n1* to state *n2* on terminal *t* or on the empty string (epsilon transitions), and the third rule form identifies state *n1* as a final state.

* *FSA* (finite state automaton) is used here sometimes to denote a regular grammar.

* *pseudo-regular grammars* (sometimes PRG) treat some nonterminals as if they were terminals; normally those nonterminals generate a regular language and might be treated as terminal symbols in a parser with a lexer.  I often call such nonterminals *pseudo-terminals*.

* *stack-augmented pseudo-regular grammars* (sometimes SAPRG) are pseudo-regular grammars in which some rules and some nonterminals are augmented with instructions for managing a push-down stack.  When interpreted by suitable software, SAPRGs thus effectively define a push-down automaton.  The *ixml-to-saprg* module generates a push-down automaton which can effectively interprets the input grammar as a recursive transition network in the sense of Wood 1970.  Ignoring the stack in such a push-down automaton reduces -- in particular ignoring the stack-related constraints on transitions -- reduces the push-down automaton to a finite state automaton recognizing the O<sub>0</sub> superset of the language of the push-down automaton.

* *mixed grammar* is a grammar in which some production rules have been translated into a stack-augmented pseudo-regular grammar and others have been left alone.  (The recursive transition network is simpler and smaller if non-recursive symbols in the grammar are left alone when building the RTN.)

* *Chomsky normal form* are grammars in which every rule has the form `n: t.` or `n1: n2, n3.`  The form was defined by Chomsky 1959 and there given the unfortunate name *regular grammar*.  I believe I have read that what is now normally called CNF differs in some details from the definition in Chomsky 1959, but I have not tracked that down.


## The stylesheets in the library

Note that for technical reasons (avoiding double import of utility modules), some stylesheets are split into a top-level executable and an included module that does all the work.  The name *foo.lib.xsl* indicates that the module is not directly executable.

### Annotation of the grammar

* `ixml-annotate-pc.xsl` adds attributes `gt:recursive`, `gt:referenced`, `gt:reachable`, and optionally `gt:descendants` to `rule` elements; adds `gt:defined` attribute to `nonterminal`.  

* `ixml-annotate-gluschkov.xsl` calculates first set, last set, and nullabiity for each subexpression of a rule, as well as follow sets for each symbol in the subexpression.  This follows Anne Brüggemann-Klein's exposition of the algorithm for construction of the Gluschkov automaton from a regular expression.  (Gingersnap does not currently have a module for translating regular expressions into star normal form, so the algorithm is cubic instead of quadratic, but so far this has not been a problem.) 

### Reporting on the grammar, visualizing the grammar

* `ixml-to-nonterminalslist.xsl` produces an XML document listing nonterminals in the grammar and their relations.  Of limited practical interest; `ixml-annotate-gluschkov` produces the same information in a usually more useful form.

* `nonterminalslist-to-dot.xsl` translates the nonterminals list into a dot file depicting the parent-child relations of nonterminals in the grammar.  

* `ixml-to-pcdot.xsl` translates a grammar into a dot file depicting the parent-child relations of nonterminals in the grammar.

* `ixmlgl-to-rtndot.xsl` translates a grammar annotated by `ixml-annotate-gluschkov` into a dot file depicting the recursive transition network.

* `rg-to-dot.xsl` translates a regular grammar into a dot file depicting the transition network (i.e. the FSA).


### Algebraic manipulation of grammars (esp. regular grammars / FSAs)

Some of these may be applicable to grammars in general, but most were developed specifically to perform specific tasks in simplifying an FSA and in reducing an FSA to a single rule with a regular right hand side.

* `rule-substitution.xsl` replaces references to a specified nonterminal with its right-hand side(s).  Optionally keeps or deletes the now unreachable production rule for the nonterminal so treated.

* `eliminate-unit-rules.xsl`eliminates unit rules by replacing the RHS consisting of a single nonterminal with that nonterminal's RHS (repeating the operation as necessary until the RHS no longer consists of a single nonterminal).

* `right-factor.xsl` in the right-hand sides of a specified nonterminal *n1*, pull together those which end with a reference to a specified nonterminal *n2* and pull them into a single right-hand side.  So `n1: t1, n2; t2, n2; t3, n3.` becomes `n1: (t1; t2), n2; t3, n3.`  This is sometimes helpful in reducing FSAs to regular expressions.

* `distribute-seq-over-disj.xsl` rewrites `alt` elements of the form (alpha, (beta; gamma)) with two `alt` elements of the form (alpha, beta); (alpha, gamma).  If the outer sequence has more than one nested choice, this stylesheet only touches the first.  This was developed for simplifying FSAs.  Cf.  `dnf-from-andor`.

* `ardens-lemma.xsl` applies Arden's Lemma to a specified rule in a regular grammar, to eliminate recursion.  Arden's Lemma is that if _P_ is not nullable, then _L = B; P, L_ if and only if _L = P* B_.  This is essential in reducing FSAs to regular expressions.

* `simplify-epsilon.xsl` eliminates pointless occurrences of the comment `{nil}` in a regular grammar.  When FSAs are manipulated in the course of simplifying them or turning them into regular expressions, such comments sometimes accumulate; this is a helpful cosmetic change.

* `simplify-expressions.xsl` simplifies expressions involving unsatisfiable terms.  The patterns simplified arise in the creation of regular approximations, and simplifying them helps reduce clutter.

* `simplify-nested-sequences.xsl` promote nested sequences:  (a, (b, c), d) becomes (a, b, c, d).

* `normalize-terminals.xsl` performs several operations on terminals in order to make construction of a deterministic FSA easier.  Multi-character literals are split into single-character literals.  For all terminals, a `gt:ranges` attribute indicating which characters match the terminal is calculated and put into normal form (with overlaps eliminated and ranges in ascending order).

* `eliminate-arc-overlap.xsl` in a regular grammar, rewrite the arcs leaving each state to ensure that no two of them overlap partially:  any two arcs either have the same ranges or disjoint ranges.  So `q1:  ['a' - 'z'], q2; 't', q3.` becomes `q1:  ['a' - 's'; 'u' - 'z'], q2; 't', q2; 't', q3.`

* `determinize-ixml-fsa.xsl` reads an FSA and produces an equivalent deterministic FSA.  Presupposes that terminals have been normalized. 

* `dnf-from-andor.xsl` expands choices nested within sequences to turn a grammar with no `repeat0`, `repeat1`, or `option` elements into disjunctive normal form.  (If repeats and options are present, behavior is undefined and probably not helpful; safely used after repeats and options have been unrolled.)

### Changes to the grammar

* `add-final-state-flag.xsl` marks one state in an FSA as a final, by adding an empty RHS to it.  Of limited interest; I think the FSA generating tools now make this less likely to be needed.

### Deletion of things from the grammar

* `rtn-linkage-removal.xsl` removes rules inserted by `ixml-to-saprg` to link the unchanged part of a grammar to the recursive transition network.  Of limited interest; I think `ixml-to-saprg` now refrains from emitting such linkage rules when appropriately invoked.

* `rule-removal.xsl` deletes production rules for specified nonterminals from a grammar.  Can be used to eliminate rules for pseudoterminals in a mixed grammar.

* `remove-unreachables.xsl` removes rules for unreachable nonterminals.

* `empty-selfloop-removal.xsl` removes epsilon transitions from an FSA when their source and target states are the same.  Such transitions may arise when a cycle of epsilon transitions is contracted.

* `strip-rtn-attributes.xsl` removes various namespaced attributes from a grammar (not just `rtn:*`, despite the name). Useful when they are no longer accurate and are in the way.


### Creation of subset and superset approximations

* `rk-subset.xsl` takes a grammar *G* and a parameter *k* and generates a grammar for the *u*<sub>*k*</sub> subset of *L(G)*.  (The name reflects an earlier convention for naming subset approximations that used *r* instead of *u*.)  The stylesheet contains a pipeline which bundles together the sequence of smaller steps needed and calls the pipeline handler to handle the pipeline.

* `R0-superset.xsl`  takes a grammar *G* and generates a grammar for the *O*<sub>0</sub> superset of *L(G)*.  (The name reflects an earlier convention for naming superset approximations that used *R* instead of *O*.)  The stylesheet contains a pipeline which bundles together the sequence of smaller steps needed and calls the pipeline handler to handle the pipeline.

* `ixml-to-rk-subset.xsl` takes an annotated grammar *G* and a parameter *k* and generates a grammar for the *u*<sub>*k*</sub> subset of *L(G)*.  (The name reflects an earlier convention for naming subset approximations that used *r* instead of *u*.)  This is the module that does the key work in the generation of subsets.

* `ixml-to-saprg.xsl` takes an annotated grammar *G* and generates a push-down automaton for its recursive transition network.

* `cnf-to-rg.xsl` takes a non-center-embedding grammar in Chomsky Normal Form and creates a regular grammar for the same language, using the algorithm in Chomsky 1959.  Nothing in the algorithm checks to see whether the grammar is in fact center embedding, and I don't know for certain what will happen in such cases.  (The resulting grammar is so thick with empty transitions that it is very difficult to see what is going on.)  I believe that in such cases the resulting regular grammar recognizes the O<sub>0</sub> subset of the original grammar.

### Creation of test cases

Some of these relate specifically to the creation of positive or negative test cases from a deterministic FSA. 

* `fsa-to-tclego.xsl` reads an FSA and generates 'test-case lego pieces' for each state and arc:  these are sequences of terminals specific to that state or arc, which can be combined in various ways to create positive and (if the FSA is deterministic) negative test cases.  The modules `fsa-to-tclego-alpha.xsl`  and `fsa-to-tclego-omega.xsl` do the work.

* `tclego-to-tcrecipes.xsl` reads the output of the preceding and produces 'test case recipes', which are sequences of terminals which, when instantiated, will constitute positive or negative test cases for the FSA in question.  Parameters control the style of coverage (arc, state, arc-final, state-final) and whether positive or negative test recipes, or both, are produced.

* `tcrecipes-to-testcases.xsl` reads a file of test-case recipes and produces an XML document containing test cases.  

The following relate specifically to the creation of positive test cases from a context-free grammar.

* `unroll-occurrences.xsl` replaces E? with ({nil} | E), E*F with ({nil} | E | EFEFE... ), and E+F with (E | EFEFE... ).  Note that this is a lossy transformation.  A parameter controls the number of repetitions in the last disjunct for repeats; the default is 3, because higher numbers easily produce very voluminous, repetitive results.  The resulting grammar is effectively restricted to terminal symbols, nonterminal symbols, sequences (`alt` elements) and choices (`alts` elements) and can usefully be interpreted as a set of and/or trees.  The output from this stylesheet should normally be fed to `dnf-from-andor` to create a grammar in disjunctive normal form.  

* `parsetrees-from-dnf.xsl` reads a grammar in disjunctive normal form (normally produced from the grammar for which we want positive test cases by running it through `unroll-occurrences` and `dnf-from-andor`) and produces a set of parsetrees.  The algorithm is simple:  it picks a RHS from the grammar and extends it upward until it starts with the start symbol and downward until all nonterminals have been expanded.  Whenever a RHS is needed, preference is given to right-hand sides not already used.  If the tree exceeds a user-specified height before being completed, it is abandoned but included in the output as a failed tree.  Processing ends when all right-hand sides in the input have been used, or when a user-specified limit on the number of failed trees is exceeded.

In practice, for 'real' grammars the majority of trees produced by `parsetrees-from-dnf` may be incomplete, because of interactions among the way repeats are handled in `unroll-occurrences` and the way right-hand sides are re-used in building trees.  The next two stylesheets are written to fix up this situation.

* `ln-from-parsetrees.xsl` examines a set of complete or partial parse trees and tries to locate complete subtrees for each nonterminal in the grammar.  For each nonterminal, it writes out the smallest complete subtree it finds.  That is, for each nonterminal *N* it seeks to find in the input one example of a complete parse tree for a sentence in *L(N)*.  (Hence the 'ln' in the name.)

* `parsetree-pointing.xsl` reads a set of parse trees as produced by `parsetrees-from-dnf` and a file of complete parse trees for various nonterminals as produced by `ln-from-parsetrees` and uses the complete subtrees from the latter to expand the unexpanded nonterminals in the former.  The name refers to the practice of injecting new mortar into brickwork.

In principle, there is no guarantee that the output from `parsetrees-from-dnf` will contain complete parse trees for all nonterminals, though so far it always has.  If it doesn't, several rounds of the two fixup stylesheets may solve the problem, or manual intervention may be needed.  Supplying complete parse trees for missing nonterminals may be tedious, but it's doable.

### Pipelining

Because by and large the stylesheets are small and tightly focused, workflows may involve invoking several stylesheets in sequence.  To make such workflows easier to write and manage, a trivial pipelining system has been implemented (inspired by work described at Balisage by Ari Nordström) which simply invokes one library stylesheet after another, governed by an XML document listing the sequence of steps.

* `grammar-pipeline-handler.xsl` accepts an ixml grammar and a pipeline specification document as input, and runs the input through the steps specified in the pipeline.  At the moment, only linear dataflows are supported:  no branches or other complications.  The pipeline can request that the result of a given step be saved under a given filename.

* `grammar-pipeline.rnc` is a Relax NG compact-syntax schema defining the set of pipeline documents for which the grammar pipeline handler should be prepared.

As this first description is written, the pipeline schema and handler are a little behind:  there are some newer stylesheet modules that have not been added to the pipeline infrastructure yet.

### Miscellaneous

* `relabel.xsl` suppresses the comments at the beginning of a grammar and inserts a new one.

* `sort-nonterminals.xsl` sorts all rules except the first alphabetically.  (The first indicates the start symbol of the grammar, so it should not be moved.)

* `ixml-html.xsl` displays a grammar as HTML; can be useful when working out a pipeline to simplify an FSA.

* `serialize-as-ixml.xsl` reads grammar in XML form, serializes as ixml.


### Utility modules

* `dot-tools.xsl` contains some useful functions for writing dot files.
* `ixml-grammar-tools.lib.xsl` contains some functions used by multiple modules.
* `range-operations.lib.xsl` contains functions for operations on lists of character ranges.

