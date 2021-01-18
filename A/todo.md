# To-do list for Gingersnap

2020-11-27, rev. 2020-12-26, last rev. 2021-01-11

## Short-term needs

### Quick things to fix

* Extend rule-substitution code to support the scenario of inlining
    all nonterminals.  Think what to do if there are recursive
    nonterminals present: produce bad output? die? leave them alone?
    [2020-01-02]

* Absolutize the reference to ixml-html.xsl, based on stylesheet
  location (?).

### User conveniences, release engineering

* Make stylesheet to read original grammar and produce draft
    configuration file:
    * recursive nonterminals and default stack identifiers
    * pseudo-terminals with regexes and sample values
    * pool of literal strings
    * pool of characters in literal strings
    * pool of characters from ranges
    * pool of characters from theta ranges (?)

* Make high-level single stylesheets to wrap up standard pipelines
    for ixml-to-subset-rk (k parameterized), ixml-to-superset-R0, and
    regular-grammar-to-testcases.  This leaves simplification of R0
    superset and knitting of R_k supersets as manual labor.

* When stubbing out non-terminals in ixml-to-rk-subset,
    instead of defining them with a
    reference to empty set, define them with a reference to
    *max-`{$basename}`*, and define that with a reference to empty-set.
    This will make it easier to knit the subset and superset grammars
    together, because there will be just the one point of contact.

## Things to make better

###  Small functional improvements

* Retention of information about which items in the original grammar
    a given state corresponds to.  (Can we carry the original items
    from the original states?)

    Make ixml-annotate-pc record the input URI in an attribute,
    since it has one.  Others should update it if they have one,
    else leave it alone.

    Extend function in ixml-to-saprg to accept a state name or
    element or something and insert a location pointer after it.
    Then we can associate items with each state.

* Also retention of information about the original source grammar
    and important derivation steps (gt:* attributes on the ixml
    document, maybe?) to allow test case collections to have a
    coherent automatically generated description of what they are.

* add pipeline stage to rename trace attributes (e.g. to protect pc
    annotations made on original grammar from loss when pc is run
    again on derived grammars.

* develop convention for comments to carry step-by-step
    information by enveloping earlier step information:  most recent
    step is outer comment, its input is its child.  Sanity check:
    there must never be more than one metadata comment in a
    gt-well-formed tgrammar.

* Make a coherent plan for a test catalog; review the XSTS and 
    QT-FOTS-3 schemas and take inspiration from them. 

* Make simplify-expressions (which deals with empty-set)
    iterate to a fixed-point or a maximum number of iterations.

### Resilience

* Functions for checking various properties of RHS (rule/alt) and
    rules and grammars.  Regular? free of epsilon transitions?
    eq-or-disjoint?  ...

* Look carefully at each pipeline stage and identify its
    precondition and its postcondition.  Note as far as possible cases
    where it destroys the pre- or postconditions of other stages.

* Make each pipeline stage check as fully as possible for its
    preconditions.  In case of worry about speed, remember the story
    about array bounds checking in the Elliot Brothers compiler.

### Rationalization, consistency

* Better message-level control in all stylesheets.  Use use-when!
    (If I'm going to pay for using HE by compilation on each run, I
    might as well use what that buys me.)

* Bettter control of when to eliminate attributes as no longer
    relevant.

* Make RNG, RNC schemas for current ixml. 

* Make RNG, RNC schemas, and ixml grammars for variant forms of ixml:

    * ixml extended with notations for empty string, empty set,
      universal set of characters
    * ixml extended with wildcards
    * ixml with Gingersnap-specific extensions 
    * ixml restricted to regular grammars and pseudo-regular grammars
	  (if you want to allow pseudo-terminals, you will need a way to
	  recognize them)
    * regular grammars extended with stack management


### Software engineering, good practice

* Make shallow tests (XSpec) for each pipeline stage. 

* Make systematic tests (XSpec) for each pipeline stage. 


### Other things to make better

* The recursive descent parser ixml-to-xml-manual.xsl fails if in g012
there is a blank before the closing parenthesis.  I've worked around
it for now (17 January 2021) but it should be fixed.

## Longer-term things

###  Exploration and learning (and exploitation)

* Redo the examples worked out by hand during the early exploratory
  work and record them as simple illustrations.  (They were chosen in
  part to help gain understanding; they can maybe help a reader
  understand.  Also, it would be nice to see if the answers agree.)

* Comparison of RTN as constructed by Gingersnap (ixml-annotate-gl and
  ixml-to-saprg) with the LALR (?) automaton as described by Grune and
  Jacobs.

* Make systematic test cases for ATMO horizontal-tier (see
    <!--- file:///Users/cmsmcq/2019/misc/test-case-generation/notes.xml and -->
    uyghur.ittc.ku.edu/2018/05/testdata/)

* Make tools to tell whether ignoring the stack in an RTN changes L(G)
  or not.  If it doesn't, it's not really recursive in any important
  sense; it's just an FSA.

###  Additional functionality / new pipeline stages

* Alternative methods of test-case generation described in
    2019/misc/test-case-generation/notes.xml -- this is particularly
    important for positive test cases, since those methods can
    generate raw parse trees along the way (from which we can generate
    ASTs later).

* FSA minimization. 

* FSA intersection, union, difference. 

* Implement testing for ambiguity (from that paper you saw once
[I think that means Braband / Giegerich / Møller 2010]) 

* LL(1), LL(k) testing. 

* Review, summarize, and implement the regular approximation
  algorithms of
  * Reread Langendoen 1975; if it defines an algorithm, implement it. 
  * Track down DTL's reference to Chomsky 1959a; implement that. 
  * Pereira/Wright (ACL '91)
  * Grimley Evans (EACL 1997) 
  * Nederhof (IWFSMNLP 1998?) 
  * Mohri and Nederhof 2000 
  * Nederhof 2000 
  * the guys from the farm (Parameswaran and Taly 2007)
  * Yli-Jyrä (FG Vienna 2008) 
    
* LALR(1) testing.

* generation of recursive-descent parser (if feasible)

* Coverage measurement (and run coverage measurement on XSTS and/or QT
test suites)

* Translate native ixml into BNF. 

* Translate BNF grammar into Chomsky Normal Form. 




### Further extension

* Specify ixml grammar and schemas for ixml extended with annotations
  in the style of xsd:annotation and/or XQuery annotations.

* Specify ixml grammar and schemas for ixml extended with inherited 
  and synthetic attributes. Assignment syntax is an extension point, 
  but perhaps start with XPath 3.1? 

* Try to apply the reversibility analysis of Braband / Møller /
Schwartzbach 2010 to ixml.  I think that will involve

    * Reading ixml grammars backwards / rewriting them as grammars of
      tagged documents (not quite the same as schemas), so they can be
      tested for ambiguity

    * Writing an ixml unparser (re-serializes the output of an ixml
      parser in the non-XML syntax)

## Misc

* From grammar, build XForm to allow manual creation of partial parse
  trees.  Form displays a partial parse tree, beginning with S.  User
  clicks on a nonterminal P to expand it by inserting its RHS (which
  makes the parent P unclickable, although maybe I might want to undo
  the expansion to back out of a bad decision).  Click on * or + or ?
  to supply that many copies of the base term (with separators).
  Click on one choice in a set of choices to choose that one.  Form
  keeps track of various coverage measures (number of times each
  alternative is chosen, possibly also number of times each
  nonterminal has been used, parent/child counts, ancestor/descendant
  counts, ...); counts are stored as attributes in a copy of the
  grammar, which can be saved and re-loaded, so the form can be used
  to generate testcase recipes to fill in coverage gaps in a test set.

  This would be kind of fun to use, but it's not on the short path to
  a test suite.

  See also work long entry for 18 January 2021.


## Done

* What are the empty comments in ixml-to-rk output about? (a sub r2)
(fixed)

* Single import of function libraries (involves splitting the 
calling modules into runnable and non-runnable modules). 
[Done 28 Dec 2020.]

* add pipeline stage for collapsing epsilon transitions (defined as
  unit rules), optionally with restriction on where.  Recursive
  checking needed to get epsilon-closure.  Cycles may exist and must
  be protected against.

  [2020-01-02 I believe this is done as specified, in
  eliminate-unit-rules.xsl, but it has not been well tested.]

* Pipeline step to eliminate epsilon transitions.  (Duplicate.)

* (not so quick) make ixml-to-saprg take two parameters:

    * `$fissile` = '`#all`' (default)
      | list of names
    * `$non-fissile` = '`#non-recursive`' (default)
      | '`#none`'
      | list of names
		  
    When `$fissile` has names, `$non-fissile` is ignored.
    `$fissile`='`#all`' means all nonterminals except those recognized
     as pseudo-terminals (by default, non-recursive ones).

    [2020-01-02 I believe this is done as specified, but the results
    are not what was hoped.  Three scenarios must be supported; see
    making-rtns.asc document of today.  (1) exhibition of mixed
    grammar, (2) FSA for regular language, (3) R_0 RTN for a specific
    named nonterminal in a CFL.]

    [2020-01-12 Reworked again.  It seems to work.]

* make ixml-to-rk not inject stylesheet PI if one is already
  there. [Done 2021-01-12.]
  
* make ixml-to-rk do comments first before injecting its own
  navigation markers. [Done 2021-01-12.]

* Make tool to generate dot file from regular or pseudo-regular
  grammar, to visualize the FSA.  (Done 2021-01-17, but only for
  regular grammar, pseudo-regular will have to wait.)

