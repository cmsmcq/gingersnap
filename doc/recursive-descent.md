# Generating a recursive-descent parser from an LL(1) ixml grammar

2022-08-22

## Requirement

Given an ixml grammar, return a recursive descent parser for the
language described: set of XQuery functions to parse input against the
grammar and return an XML representation of a parse tree, if any
exist.

The grammar may be assumed suitable for parsing by recursive descent.
Ambiguous grammars and non-deterministic grammars are not suitable.
(But if the non-determinism only affects terminal symbols, as in the
expression `('x'?)*` or the expression `('A'; #41)`, the
non-determinism may not be fatal.)

## Framing assumptions

Each production rule in the grammar will be translated into a function
g:*N*(), where *g* is a namespace prefix chosen for the grammar (or
for the parser constructed for that grammar) and *N* is the
nonterminal on the left-hand side of the rule.  (This is a slight
oversimplification; as shown below there may be one function to handle
*N* as an element, another to handle it as an attribute, and a third
to handle it if *N* is hidden.)

The function accepts a single argument of type ENV (environment --
details below) and returns a sequence beginning with a new environment
and continuing with the parse-tree results if any.

The body of the function is created by replacing each construct *C* in
the right-hand side of the rule for *N* with the 'program equivalent'
of *C*, written *gc:Pr(C, $E)* for some appropriate environment $E.

The environment is a bundle of information containing:

  * the input string (this need not change)
  * the current position in the input string
  * the character at that position
  * possibly error diagnostics

One simple representation of environments is as elements; maps can
also be used.

## Auxiliary functions

To simplify the exposition above, some auxiliary functions have been
assumed.  They are listed here with descriptions.

Some functions are specific to a particular recursive-descent parser;
others can be used in any recursive-descent parser and can be defined
as part of a standard library; still others are part of the grammar
compiler which reads the grammar and produces the parser.  They are
distinguished by namespace prefix:

  * *g*:  functions specific to a particular grammar
  * *rd*:  library functions for use in any recursive-descent parser
  * *gc*:  functions evaluated by the grammar compiler during generation of the parser 

### Functions in the library *rd*

  * rd:sym($E as ENV) as xs:string

    Returns the current symbol from the argument $E.  Shorter than
    `$E/sym/string()`.

  * rd:remaining($E as ENV) as xs:string

    Returns the unparsed substring from the argument $E.  Shorter than
    `substring($E/input/string(), $E/pos/number())`.

  * rd:next($E as ENV) as ENV

    Returns an environment with the position moved one step forward.

  * rd:advance($E as ENV, $n as xs:integer) as ENV

    Returns an environment with the position moved $n characters
    forward.

  * rd:re1-matches($s as xs:string, $re as xs:string) as xs:boolean

    Checks to see whether the regular expression $re accepts the
    single-character string $s.

  * rd:prefix-matches($s as xs:string, $re as xs:string) as xs:string?

    Checks to see whether the regular expression $re matches any
    prefix of string $s.

    If it does, the prefix is returned as a result; its length is not
    guaranteed greater than zero. If the regular expression does not
    match any prefix, nothing (the empty sequence) is returned.

    N.B. rd:re1-matches and rd:prefix-matches are both equivalent, for
    any arguments, to the built-in XPath function fn:matches.  They
    are given different names to stress the difference in expectations
    about the arguments.


### Functions in the library *gc*

These functions are all evaluated at compile time; their names are
written in all caps to make them visually more distinct from the
functions evaluated at parse time. (In at least some cases they
*could* be delayed until parse time, but there is no point in doing
so, since their arguments are all available at grammar compilation
time.)

  * gc:PROGRAM(*expression*)

    Accepts an expression from the grammar being processed, returns an
    XQuery expression which assumes an environment (e.g. $E0) and looks
    at the current position in the input for a string which matches
    the *expression*.

    If it finds a match, the XQuery expresion returns (a) a new
    environment with the position at the end of the matching string,
    and (b) a parse tree for the string.

    If the current input does not match the *expression*, then the
    XQuery expression returns a new environment marked with an error.

  * gc:REGEX-FROM-CS($e as element()) as xs:string

    Accepts an inclusion or exclusion element; returns an equivalent
    regular expression in the notation used by XPath.

  * gc:FIRST-AS-REGEX(*expression*) as xs:string

    Accepts an expression from the grammar being processed.  Returns a
    regular expression (in XPath notation) which matches a character
    in the input if and only if that character can begin a string
    derived from *expression*.

  * gc:FOLLOW-AS-REGEX(*expression*) as xs:string

    Accepts an expression from the grammar being processed.  Returns a
    regular expression (in XPath notation) which matches a character
    in the follow-set of the *expression*.  Or, to put it another way,
    it matches a character in the input if and only if that character
    can *follow* a string derived from *expression*.

    The follow-set is used when expressions include nullable
    sub-expressions (sub-expressions which can match the empty
    string).

    For simplicity, the discussion here ignores the problem of
    recognizing the end of the input; the reader may assume that a
    special END-OF-INPUT character is appended to the input, which is
    guaranteed not to occur in the input proper.

  * gc:REGEX-FROM-RE($re as xs:string) as xs:string

    Accepts a representation of an ixml regular expression (for the
    moment let's assume it's a string); returns an equivalent regular
    expression in the notation used by XPath.

  * gc:HEX-TO-CHAR($s as xs:string) as xs:string

    Accepts a single hexadecimal number denoting a legitimate UCS code
    point and returns the corresponding UCS character.  

## Function skeletons for gc:PROGRAM()

### Terminal symbols

  * `"x"`, `^"x"` ⇒

    ````
    if (starts-with(rd:remaining($E0), "x") 
    then (rd:advance($E0, string-length("x")), "x")
    else rd:error()
    ````

  * `-"x"` ⇒

    ````
    if (starts-with(rd:remaining($E0), "x") 
    then (rd:advance($E0, string-length("x")))
    else rd:error()
    ````
    
    The same pattern applies for all terminals and won't be repeated
    below: if the symbol is marked "`-`", it is omitted from the
    sequence being returned.

  * `#XY` ⇒

    ````
    if (rd:sym($E0) eq gc:HEX-TO-CHAR("XY")) 
    then (rd:next($E0), rd:sym($E0))
    else rd:error()
    ````

  * `[` *charset* `]` ⇒

    ````
    if (rd:re1-matches(rd:sym($E0), gc:REGEX-FROM-CS("[charset]")) 
    then (rd:next($E0), rd:sym($E0))
    else rd:error()
    ````

  * `~[` *charset* `]` ⇒
    ````
    if (rd:re1-matches(rd:sym($E0), gc:REGEX-FROM-CS("~[charset]")) 
    then (rd:next($E0), rd:sym($E0))
    else rd:error()
    ````

  * *token(re)* ⇒
    ````
    let $match := rd:prefix-matches(substring($E0/input, $E0/pos), gc:REGEX-FROM-RE(*re*))
    return if (exists($match))
    then (rd:advance($E0, string-length($match), $match)
    else rd:error()
    ````

    N.B. ixml doesn't have a separate level of token definitions; this
    is an extension for hand-translation, to capture the fact that a
    given nonterminal or expression can be captured with a single
    greedy regular-expression match.


### Insertions

  * `+"x"` ⇒
    ````
    ($E0, "x")

  * `+#XY` ⇒
    ````
    ($E0, hex-to-char("XY"))
    ````

Since insertions match a zero-length substring, they consume no
input. If the insertion is optional or repeatable, if any expression
consisting only of insertions is optional or repeatable, or if any
choice involves two or more alternatives consisting only of
insertions, then the grammar is non-deterministic.


### Nonterminals

When references to nonterminals are encountered, the function for that
nonterminal is called -- or rather, one of the functions for that
nonterminal; there may be more than one, for nonterminals which occur
in the grammar with different marks.

  * *N* ⇒ `rd:*N*($E0)`

    Depending on the default mark for nonterminal *N*, the function
    `rd:`*N*`($E0)` is defined as one of `rd:e.N($E0)`, `rd:a.N($E0)`,
    or `rd:h.N($E0)`.
    
  * `^`*N* ⇒ rd:e.*N*($E0)`

    Returns an element named *N*:
    ````
    declare function rd:e.*N*(
      $E0 as ENV
    ) as element(*N*) {
      element *N* { gc:PROGRAM(rhs) }
    };
    ````
    where *rhs* is the right-hand side of the production rule for *N*.
    
  * `@`*N* ⇒ rd:a.*N*($E0)`

    Returns an attribute named *N*.
    ````
    declare function rd:a.*N*(
      $E0 as ENV
    ) as attribute(*N*) {
      attribute *N* { gc:PROGRAM(rhs) }
    };
    ````
    where *rhs* is the right-hand side of the production rule for *N*.

  * `-`*N* ⇒ rd:h.*N*($E0)`

    Returns a sequence of nodes with no wrapper.
    ````
    declare function rd:a.*N*(
      $E0 as ENV
    ) as item()+ {
      gc:PROGRAM(rhs)
    };
    ````


### Expressions

For expressions, the form of the rule may vary depending on whether
the sub-expressions are nullable (= generate the empty string) or not.

  * *factor* `?` ⇒    

    If *factor* is non-nullable, then:
    ````
    if (rd:re1-matches(rd:sym($E0), gc:FIRST-AS-REGEX(*factor*)))
    then gc:PROGRAM(*factor*, $E0)
    else $E0
    ````

    If *factor* is nullable, then:
    ````
    if (rd:re1-matches(rd:sym($E0), gc:FIRST-AS-REGEX(*factor*))
       or rd:re1-matches(rd:sym($E0), gc:FOLLOW-AS-REGEX(*factor*)))
    then gc:PROGRAM(*factor*, $E0)
    else $E0
    ````

    If the *factor* generates any non-empty sequence of nonterminal
    symbols, then the grammar is ambiguous and not suitable for
    recursive-descent parsing.  (If, for example, we have the rule `N
    = ().`, then the rule `S = N?.` has two parse trees for the empty
    string: `<S><N/></S>` and `<S/>`.)

  * *factor* `*` ⇒ rd:seq_*factor*($E0)

    where rd:seq_*factor*() is
    ````
    declare function rd:seq_*factor*($E0 as ENV) as item()+ {
        if ((rd:re1-matches(rd:sym($E0), gc:FIRST-AS-REGEX(*factor*))))
	then let $E1 := gc:PROGRAM(*factor*, $E0),
	         $E2 := rd:seq_*factor*($E1[1])
	     return ($E2[1], tail($E1), tail($E2))
	else $E0
    }
    ````

    If *factor* is nullable, then the grammar is nondeterministic (and
    if *factor* generates any nonterminals, the grammar is also
    ambiguous).

  * *factor* `+` ⇒
    ````
    if ((rd:re1-matches(rd:sym($E0), gc:FIRST-AS-REGEX(*factor*))))
    then rd:seq_*factor*($E0)
    else error
    ````
    
    where rd:seq_*factor*() is as above.

    If *factor* is nullable, then the grammar is nondeterministic.  If
    it is nullable and generates nonterminals, the grammar is
    ambiguous.
    
  * *factor* `**` *sep* ⇒ rd:seqsep_*factor*_*sep*($E0)

    where rd:seqsep_*factor*_*sep*() is
    ````
    declare function rd:seqsep_*factor*_*sep*($E0 as ENV) as item()+ {
        if ((rd:re1-matches(rd:sym($E0), gc:FIRST-AS-REGEX(*factor*))))
	then let $E1 := gc:PROGRAM(*factor*, $E0),
	         $E2 := if (rd:re1-matches(rd:sym($E1[1]), gc:FIRST-AS-REGEX(*sep*)))
		        then let $E3 := gc:PROGRAM(*sep*, $E1[1]), 
                                 $E4 := rd:seq_*factor*_*sep*($E3[1])
		             return ($E4[1], tail($E3), tail($E4))
			else $E1[1]
	     return ($E2[1], tail($E1), tail($E2))
	else $E0
    }
    ````

    If *factor* is nullable,

    If *sep* is nullable, then 

  * *factor* `++` *sep* ⇒
    ````
    if ((rd:re1-matches(rd:sym($E0), gc:FIRST-AS-REGEX(*factor*))))
    then rd:seq_*factor*_*sep*($E0)
    else error
    ````

    where rd:seqsep_*factor*_*sep*() is as above.
    
  * *term<sub>0</sub>* `,`  *term<sub>1</sub>* ⇒
    ````
    let $E1 := gc:PROGRAM(*term<sub>0</sub>*, $E0),
        $E2 := gc:PROGRAM(*term<sub>1</sub>*, head($E1))
    return ($E2[1], tail($E1), tail($E2))
    ````

    This can be extended to a sequence of arbitrary length:
    *term<sub>0</sub>* `,`  *term<sub>1</sub>* `,` ... `,` *term<sub>n</sub>* ⇒
    ````
    let $E1 := gc:PROGRAM(*term<sub>0</sub>*, $E0),
        $E2 := gc:PROGRAM(*term<sub>1</sub>*, head($E1))
	...
	$E*N+1* := gc:PROGRAM(*term<sub>n</sub>*, head($E*N*))
    return ($E2[1], tail($E1), tail($E2), ..., tail($E*N*), tail($E*N+1*))
    ````


  * *alt<sub>0</sub>* `;`  *alt<sub>1</sub>* ⇒
    ````
    if (rd:re1-matches(rd:sym($E0), gc:FIRST-AS-REGEX(*term<sub>0</sub>*)))
    then := gc:PROGRAM(*term<sub>0</sub>*, $E0)
    else if (rd:re1-matches(rd:sym($E0), gc:FIRST-AS-REGEX(*term<sub>1</sub>*)))
    then := gc:PROGRAM(*term<sub>1</sub>*, $E0)
    else error
    ````

    This too can be extended to arbitrarily many alternatives.

    *Unfortunately, this is not quite right: if one of the
    alternatives generates the empty string, testing the current
    symbol for membership in the first set of each term does not do
    quite the right thing.  Probably every one of these skeletons
    needs to be looked at with a cold eye with respect to generation
    of the empty string.  This rule and the others should have a clear
    relation to the rules for Gluschkov automata and for Brzozowski
    derivatives.*
    
    
## Additional notes

See also [my notes from ten years ago on recursive-descent parsing in
XQuery](http://cmsmcq.com/mib/?p=1260).  Like the parser skeleton
described there, a parser produced using the patterns shown above
requires that the grammar be LL(1).  In particular,

  * For any set of alternatives (A; B; ...), first(A), first(B)
    etc. must be pairwise disjoint.

  * For options (A?) and repetitions (A*, A**B, A+, A++B), first(A)
    and first(B) must be disjoint from the follow-set of the
    expression.

The treatment of compound expressions (sequences, choices,
repetitions, options) resembles, in some ways, both the rules for
calculating Brzozowski derivatives and those for calculating the
Gluschkov automaton from a given regular expression. 