# Generating a recursive-descent parser from an LL(1) ixml grammar

2022-08-22

## Requirement

Given an ixml grammar, return a recursive descent parser for the
language described: set of XQuery functions to parse input against the
grammar and return an XML representation of a parse tree, if any
exist.


## Framing assumptions

Each production rule in the grammar will be translated into a function
rd:*N*(), where *N* is the nonterminal on the left-hand side of the
rule.  (This is a slight oversimplification; there may be one function
to handle *N* as an element, another to handle it as an attribute, and
a third to handle it if *N* is hidden.)

The function accepts a single argument of type ENV (environment --
details below) and returns a sequence beginning with a new environment
and continuing with the parse-tree results if any.

The body of the function is created by replacing each construct *C* in
the right-hand side of the rule for *N* with the 'program equivalent'
of *C*, written *Pr(C, $E)* for some appropriate environment $E.  

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

  * rd:sym($E as ENV) as xs:string

    Returns the current symbol from the argument environment.  Shorter
    than `$E/sym/string()`.

  * rd:next($E as ENV) as ENV

    Returns an environment with the position moved one step forward.

  * rd:advance($E as ENV, $n as xs:integer) as ENV

    Returns an environment with the position moved $n characters
    forward.

  * rd:regex-from-cs($e as element()) as xs:string

    Accepts an inclusion or exclusion element; returns an equivalent
    regular expression in the notation used by XPath.

  * rd:first-as-regex(*expression*) as xs:string

    Accepts an expression from the grammar being processed.  Returns a
    regular expression (in XPath notation) which matches a character
    in the input if and only if that character can begin a string
    derived from *expression*.

    This is written as a function call and could be written that way
    in a parser, but since it can be computed at parser-generation
    time, what appears in the parser will normally be not the function
    call but its result.
    
  * rd:re1-matches($s as xs:string, $re as xs:string) as xs:boolean

    Checks to see whether the regular expression $re accepts the
    single-character string $s.

  * rd:prefix-matches($s as xs:string, $re as xs:string) as xs:string?

    Checks to see whether the regular expression $re matches any
    prefix of string $s.

    If it does, the prefix is returned as a result; its length is not
    guaranteed greater than zero. If the regular expression does not
    match any prefix, nothing (the empty sequence) is returned.

  * rd:regex-from-re($re as ??) as xs:string

    Accepts a representation of an ixml regular expression; returns an
    equivalent regular expression in the notation used by XPath.

  * rd:hex-to-char($s as xs:string) as xs:string

    Accepts a single hexadecimal number denoting a legitimate UCS code
    point and returns the corresponding UCS character.

## Function skeletons

### Terminal symbols

  * `"x"`, `^"x"` ⇒

    ````
    if (rd:sym($E0) eq "x") 
    then (rd:next($E0), rd:sym($E0))
    else rd:error()
    ````

  * `-"x"` ⇒

    ````
    if (rd:sym($E0) eq "x") 
    then rd:next($E0)
    else rd:error()
    ````
    
    The same pattern applies for all terminals: if the symbol is
    marked "`-`", it is omitted from the sequence being returned.

  * `#XY` ⇒

    ````
    if (rd:sym($E0) eq rd:hex-to-char("XY")) 
    then (rd:next($E0), rd:sym($E0))
    else rd:error()
    ````

  * `[` *charset* `]` ⇒

    ````
    if (rd:re1-matches(rd:sym($E0), rd:regex-from-cs("[charset]")) 
    then (rd:next($E0), rd:sym($E0))
    else rd:error()
    ````

  * `~[` *charset* `]` ⇒
    ````
    if (rd:re1-matches(rd:sym($E0), rd:regex-from-cs("~[charset]")) 
    then (rd:next($E0), rd:sym($E0))
    else rd:error()
    ````

  * *token(re)* ⇒
    ````
    let $match := rd:prefix-matches(substring($E0/input, $E0/pos), rd:regex-from-re(*re*))
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
      element *N* { Pr(rhs) }
    };
    ````
    where *rhs* is the right-hand side of the production rule for *N*.
    
  * `@`*N* ⇒ rd:a.*N*($E0)`

    Returns an attribute named *N*.
    ````
    declare function rd:a.*N*(
      $E0 as ENV
    ) as attribute(*N*) {
      attribute *N* { Pr(rhs) }
    };
    ````
    where *rhs* is the right-hand side of the production rule for *N*.

  * `-`*N* ⇒ rd:h.*N*($E0)`

    Returns a sequence of nodes with no wrapper.
    ````
    declare function rd:a.*N*(
      $E0 as ENV
    ) as item()+ {
      Pr(rhs)
    };
    ````


### Expressions

  * *factor* `?` ⇒
    ````
    if (rd:sym($E0) = rd:first(*factor*))
    then Pr(*factor*, $E0)
    else $E0
    ````

  * *factor* `*` ⇒ rd:seq_*factor*($E0)

    where rd:seq_*factor*() is
    ````
    declare function rd:seq_*factor*($E0 as ENV) as item()+ {
        if (rd:sym($E0) = rd:first(*factor*))
	then let $E1 := Pr(*factor*, $E0),
	         $E2 := rd:seq_*factor*($E1[1])
	     return ($E2[1], tail($E1), tail($E2))
	else $E0
    }
    ````

  * *factor* `+` ⇒
    ````
    if (rd:sym($E0) = rd:first(*factor*))
    then rd:seq_*factor*($E0)
    else error
    ````

    where rd:seq_*factor*() is as above.
  
  * *factor* `**` *sep* ⇒ rd:seqsep_*factor*_*sep*($E0)

    where rd:seqseq_*factor*_*sep*() is
    ````
    declare function rd:seq_*factor*_*sep*($E0 as ENV) as item()+ {
        if (rd:sym($E0) = rd:first(*factor*))
	then let $E1 := Pr(*factor*, $E0),
	         $E2 := if (rd:sym($E1[1]) = rd:first(*sep*))
		        then let $E3 := Pr(*sep*, $E1[1]), 
                                 $E4 := rd:seq_*factor*($E3[1])
		             return ($E4[1], tail($E3), tail($E4))
			else $E1[1]
	     return ($E2[1], tail($E1), tail($E2))
	else $E0
    }
    ````

  * *factor* `++` *sep* ⇒
    ````
    if (rd:sym($E0) = rd:first(*factor*))
    then rd:seq_*factor*_*sep*($E0)
    else error
    ````

    where rd:seqseq_*factor*_*sep*() is as above.
    
  * *term<sub>0</sub>* `,`  *term<sub>1</sub>* ⇒
    ````
    let $E1 := Pr(*term<sub>0</sub>*, $E0),
        $E2 := PR(*term<sub>1</sub>*, head($E1))
    return ($E2[1], tail($E1), tail($E2))
    ````

    This can be extended to a sequence of arbitrary length:
    *term<sub>0</sub>* `,`  *term<sub>1</sub>* `,` ... `,` *term<sub>n</sub>* ⇒
    ````
    let $E1 := Pr(*term<sub>0</sub>*, $E0),
        $E2 := Pr(*term<sub>1</sub>*, head($E1))
	...
	$E*N+1* := Pr(*term<sub>n</sub>*, head($E*N*))
    return ($E2[1], tail($E1), tail($E2), ..., tail($E*N*), tail($E*N+1*))
    ````


  * *alt<sub>0</sub>* `;`  *alt<sub>1</sub>* ⇒
    ````
    if (rd:sym($E0) = rd:first(*term<sub>0</sub>*)
    then := Pr(*term<sub>0</sub>*, $E0)
    else if (rd:sym($E0) = rd:first(*term<sub>1</sub>*)
    then := Pr(*term<sub>1</sub>*, $E0)
    else error
    ````

    This too can be extended to arbitrarily many alternatives.
    
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

