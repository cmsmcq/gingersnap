# To-do list for Gingersnap

2020-11-27, rev. 2020-12-26, last rev. 2021-01-11

## Short-term needs

* Quick things to fix

  * make ixml-to-rk not inject stylesheet PI if one is already there.
  
  * make ixml-to-rk do comments first before inject its own navigation
    markers.

  * (not so quick) make ixml-to-saprg take two parameters:
    $fissile = '#all' (default)
      | list of names
    $non-fissile = '#non-recursive' (default)
      | '#none'
      | list of names
    When $fissile has names, $non-fissile is ignored.
    $fissile='#all' means all nonterminals except those recognized
      as pseudo-terminals (by default, non-recursive ones).

    [2020-01-02 I believe this is done as specified, but the results
    are not what was hoped.  Three scenarios must be supported; see
    making-rtns.asc document of today.  (1) exhibition of mixed
    grammar, (2) FSA for regular language, (3) R_0 RTN for a specific
    named nonterminal in a CFL.]

  * add pipeline stage for collapsing epsilon transitions (defined
    as unit rules), optionally with restriction on where.
    Recursive checking needed to get epsilon-closure.  Cycles
    may exist and must be protected against.

    [2020-01-02 I believe this is done as specified, but has not been
    well tested.]
    
  * Extend rule-substitution code to support the scenario of inlining
    all nonterminals.  Think what to do if there are recursive
    nonterminals present: produce bad output? die? leave them alone?
    [2020-01-02]

*  User conveniences, release engineering

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

  * Make tool to generate dot file from regular or pseudo-regular
    grammar.

  * When stubbing out non-terminals, instead of defining them with a
    reference to empty set, define them with a reference to
    max-{$basename}, and define that with a reference to empty-set.
    This will make it easier to knit the subset and superset grammars
    together, because there will be just the one point of contact.

## Things to make better

*  Small functional improvements

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
    QT-FOTS-3 schemas and let yourself be inspired by them. 

  * Make simplify-expressions (which deals with empty-set)
    iterate to a fixed-point or a maximum number of iterations.

*  Resilience

  * Functions for checking various properties of RHS (rule/alt) and
    rules and grammars.  Regular? free of epsilon transitions?
    eq-or-disjoint?  ...

  * Look carefully at each pipeline stage and identify its
    precondition and its postcondition.  Note as far as possible cases
    where it destroys the pre- or postconditions of other stages.

  * Make each pipeline stage check as fully as possible for its
    preconditions.  In case of worry about speed, remember the story
    about array bounds checking in the Elliot Brothers compiler.

*  Rationalization, consistency

  * Better message-level control in all stylesheets.  Use use-when!
    (If I'm going to pay for using HE by compilation on each run, I
    might as well use what that buys me.)

  * Bettter control of when to eliminate attributes as no longer
    relevant.

  * Single import of function libraries (involves splitting the
    calling modules into runnable and non-runnable modules).


*  Software engineering, good practice

  * Make shallow tests (XSpec) for each pipeline stage. 

  * Make systematic tests (XSpec) for each pipeline stage. 


## Longer-term things

*  Exploration and learning (and exploitation)

  * Redo the examples you worked out by hand, record them as simple
    illustrations.  (They were chosen in part to help you understand;
    they can help a reader understand.  Also, it would be nice to see
    if the answers agree.)

  * Comparison of RTN as I construct it with LALR (?) automaton
    described by G/J.

  * Make systematic test cases for ATMO horizontal-tier (see
    file:///Users/cmsmcq/2019/misc/test-case-generation/notes.xml and
    uyghur.ittc.ku.edu/2018/05/testdata/)

  * Make tools to tell whether ignoring the stack in an RTN changes
    L(G) or not.  If it doesn't, it's not really recursive in any
    important sense; it's just an FSA.

*  Additional functionality / new pipeline stages

  * Alternative methods of test-case generation described in
    2019/misc/test-case-generation/notes.xml -- this is particularly
    important for positive test cases, since those methods can
    generate raw parse trees along the way (from which we can generate
    ASTs later).

  * Pipeline step to eliminate epsilon transitions. 

  * FSA minimization. 

  * FSA intersection, union, difference. 

  * Implement testing for ambiguity (from that paper you saw once) 

  * LL(1), LL(k) testing. 

  * Regular approximation algorithms of Pereira/X, N__, and the guys
    from the farm

  * LALR(1) testing.

  * recursive-descent generation

  * Coverage measurement (and run coverage measurement on XSTS and/or
    QT test suites)

Misc


Done

  * What are the empty comments in ixml-to-rk output about? (a sub r2) 
  (fixed) 
