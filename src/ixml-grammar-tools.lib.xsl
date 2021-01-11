<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		version="3.0">

  <!--* Functions for working with ixml grammars.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : rename as ixml-grammar-tools.lib.xsl
      *                       as part of restructuring and naming
      *                       changes.
      * 2020-12-23 : CMSMcQ : make this not a package.  What I learned
      *                       about packages is that Saxon HE does not
      *                       support searching for them from the
      *                       command line.
      * 2020-12-23 : CMSMcQ : make this a package, as a way to learn 
      *                       about packages (and make Saxon's warning
      *                       message go away)
      * 2020-11-28 : CMSMcQ : pull functions out to library
      * 2020-11-28 : CMSMcQ : made stylesheet, as alternative to 
      *                       ixml-to-nonterminalslist.xsl
      *-->

  <!--****************************************************************
      * Interface 
      ****************************************************************
      *-->
  
  <!--* lnChildrenXGN:  given a grammar G and a nonterminal N,
      * return a list of non-terminal children (i.e. nonterminals
      * appearing on some RHS of N). *-->
  <!--* <xsl:expose component="function"
	      names="gt:lnChildrenXGN"
	      visibility="final"/> *-->
  
  <!--* lnDescXGN:  given a grammar G and a nonterminal N,
      * return a list of non-terminal descendants of N (i.e. the 
      * transitive closure of lnChildrenXGN for the same G). *-->
  <!--* <xsl:expose component="function"
	      names="gt:lnDescXGN"
	      visibility="final"/> *-->
  
  <!--* fIstoken($n):  is node $n a symbol (i.e. a terminal or
      * non-terminal in the ixml grammar)? *-->
  <!--* <xsl:expose component="function"
	      names="gt:fIstoken"
	      visibility="final"/> *-->
  
  <!--* fIsexpression($n):  is node $n an expression? (a symbol,
      * or an operator like repeat0, option, ...).
      * (Pragmatically:  can it be interpreted as a regular expression
      * over the symbols of G?  Can it have a Gluschkov automaton?
      * Does it require gl:* attributes?  Those are all the same
      * question.) *-->
  <!--* <xsl:expose component="function"
	      names="gt:fIsexpression"
	      visibility="final"/> *-->
 

  
  <!--****************************************************************
      * Implementation (Functions)
      ****************************************************************
      *-->

  <!--* lnChildrenXGN:
      * list of nonterminal children
      * from grammar G, nonterminal N
      *-->
  <xsl:function name="gt:lnChildrenXGN"
		as="xs:string*">
    <xsl:param name="G" as="element(ixml)"/>
    <xsl:param name="n" as="xs:string"/>

    <xsl:sequence select="distinct-values(
			  $G/rule[@name=$n]/descendant::nonterminal
			  /@name/string())"/>
  </xsl:function>

  
  <!--* gt:lnDescXGN:
      * list of nonterminal descendants
      * from grammar G, nonterminal N
      *-->
  <xsl:function name="gt:lnDescXGN"
		as="xs:string*">
    <xsl:param name="G" as="element(ixml)"/>
    <xsl:param name="n" as="xs:string"/>

    <xsl:sequence select="gt:lnDescXGNAQ($G, $n, (), $n)"/>
  </xsl:function>
  
  
  <!--* gt:lnDescXGNAQ: list of nonterminal descendants from
      * grammar G, nonterminal N, given accumulator A, queue Q.
      *
      * An auxiliary function, declared private to avoid cluttering
      * things up.
      *-->
  <!--* <xsl:expose component="function"
	      names="gt:lnDescXGNAQ"
	      visibility="private"/> *-->  
  <xsl:function name="gt:lnDescXGNAQ"
		as="xs:string*">
    <xsl:param name="G" as="element(ixml)"/>
    <xsl:param name="n" as="xs:string"/>
    <xsl:param name="acc" as="xs:string*"/>
    <xsl:param name="queue" as="xs:string*"/>

    <xsl:variable name="lnCandidates"
		  as="xs:string*"
		  select="distinct-values(
			  $G/rule[@name=$queue]/descendant::nonterminal
			  /@name/string())"/>

    <xsl:variable name="lnNew"
		  as="xs:string*"
		  select="$lnCandidates
			  [ not( . = $acc) ]"/>

    <xsl:sequence select="if (empty($lnNew))
      then $acc
      else gt:lnDescXGNAQ($G, $n, ($acc, $lnNew), $lnNew)"/>
  </xsl:function>
  

  <!--****************************************************************
      * Predicates 
      *-->

  <!--* gt:fIstoken($e): is $e a symbol (terminal or non)? *-->
  <!--* (not one of alt, option, etc.) *-->
  <xsl:function name="gt:fIstoken"
		as="xs:boolean">
    <xsl:param name="e" as="node()"/>
    <xsl:sequence select="exists($e
			  [self::nonterminal
			  or self::inclusion
			  or self::exclusion
			  or self::literal
			  ])"/>
  </xsl:function>

  <!--* gt:fIsexpression($e): is $e an expression? *-->
  <!--* (not a comment ...) *-->
  <xsl:function name="gt:fIsexpression"
		as="xs:boolean">
    <xsl:param name="e" as="node()"/>
    <xsl:sequence select="gt:fIstoken($e)
			  or
			  exists($e
			  [self::sep
			  or self::option
			  or self::repeat0 
			  or self::repeat1 
			  or self::alt 
			  or self::alts 
			  ])"/>
  </xsl:function>  
  
</xsl:stylesheet>
