<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    exclude-result-prefixes="xs gl rtn follow"
    default-mode="sigma"
    version="3.0">

  <!--* fsa-to-tclego-sigma.xsl:  Read ixml.grammar G, write out a set
      * of sigma rules in ixml form.  For details see fsa-to-tclego.xsl
      *
      *-->

  <!--* Revisions: 
      * 2020-12-30 : CMSMcQ : make stylesheet as addition to
      *                       fsa-to-tclego.
      *-->

  <!--* In order to simplify the final stage of test case construction,
      * we make a list of characters which are known to be significant
      * in the input grammar; the code below may refer to these as
      * 'magic' characters.
      *
      * This stylesheet produces ixml rules which list magic and other
      * characters.  We distinguish three classes:
      *
      * . characters occurring in literals (e.g. semicolon and comma
      *   in many programming languages); if literals have been split
      *   into single-character sequences in the input, e.g. by
      *   normalize-terminals.xsl, then the individual characters of
      *   string literals will also occur here (e.g. "i" and "f" in
      *   programming languages, from the "if" keyword).
      *
      * . characters occurring in char-set terminals (e.g. 'a'-'z')
      *
      * . characters not occurring in either of the above (the class
      *   of 'surprised to see me?' characters)
      *
      * If characters are chosen randomly, then in many grammars the
      * third class (and to a lesser extent the second) will
      * predominate.  We don't want to exclude all Unicode characters
      * outside the ASCII range from the test cases, but we also don't
      * want software to pass most negative tests by simply scanning
      * for characters with code points greater than 127, and we
      * don't want to generate 26 tests every time we see the range
      * ['a'-'z'].
      * 
      * The purpose of gathering the classes is to allow test-case
      * generation to be biased towards the first and second classes.
      *
      * For ease of later manipulation, we generate rules with various
      * kinds of lists:
      *
      * sigma-literals:  literals in the input grammar 
      * sigma-inclusions:  inclusions in the input grammar 
      * sigma-exclusions:  exclusions in the input grammar
      * sigma-ranges:  atomic inclusive ranges in the input grammar
      * sigma-union:  union of all inclusive ranges in the input grammar 
      * sigma-complement:  complement of union of all inclusive ranges 
      * sigma-neg-ranges:  atomic exclusive ranges
      *
      * None of these have any duplicates, although the ranges in
      * sigma-ranges may overlap each other.
      *
      * Suppressing duplicate elimination might be an interesting way
      * of biasing selection.  Maybe later.
      *-->
  
  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="sigma" on-no-match="shallow-skip"/>


  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <xsl:template match="/">
    <xsl:apply-templates mode="stand-alone-sigma"/>
  </xsl:template>
  
  <xsl:template match="ixml" mode="stand-alone-sigma">
    <xsl:copy>
      <xsl:apply-templates select=".">
	<xsl:with-param name="G" tunnel="yes" select="."/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="ixml">
    <!--* sigma-literals:  literals in the input grammar *-->
    <xsl:element name="rule">
      <xsl:attribute name="name" select="'sigma-literals'"/>
      <xsl:element name="alt">
	<xsl:element name="literal">
	  <!--* gather all the literals as code points *-->
	  <xsl:variable
	      name="literals" as="xs:integer*"
	      select="for $L in descendant::literal
		      [not(ancestor::inclusion or ancestor::exclusion)]
		      return
		      for $numeral in tokenize($L/@gt:ranges,'\s+')[1]
		      return xs:integer($numeral)
		      "/>
	  <!--* dedup *-->
	  <xsl:variable name="lcp" as="xs:integer*"
			select="distinct-values($literals)"/>
	  <!--* write them out as a string *-->
	  <xsl:attribute name="dstring"
			 select="codepoints-to-string($lcp)"/>
	</xsl:element>
      </xsl:element>
    </xsl:element>
    
    <!--* sigma-inclusions:  inclusions in the input grammar *-->
    <xsl:element name="rule">
      <xsl:attribute name="name" select="'sigma-inclusions'"/>
      <xsl:element name="alt">
	<xsl:for-each-group select="descendant::inclusion"
			    group-by="@gt:ranges">
	  <xsl:sequence select="current-group()[1]"/>
	</xsl:for-each-group>
      </xsl:element>
    </xsl:element>
    
    <!--* sigma-exclusions:  exclusions in the input grammar*-->
    <xsl:element name="rule">
      <xsl:attribute name="name" select="'sigma-exclusions'"/>
      <xsl:element name="alt">	
	<xsl:for-each-group select="descendant::exclusion"
			    group-by="@gt:ranges">
	  <xsl:sequence select="current-group()[1]"/>
	</xsl:for-each-group>
      </xsl:element>
    </xsl:element>
    
    <!--* sigma-ranges:  atomic inclusive ranges in the input grammar*-->
    <xsl:variable name="leRanges" as="element()*">
      <xsl:for-each-group select="descendant::inclusion/*[@gt:ranges]"
			  group-by="@gt:ranges">
	<xsl:sort select="@gt:ranges"/>
	<xsl:sequence select="current-group()[1]"/>
      </xsl:for-each-group>
    </xsl:variable>
    
    <xsl:element name="rule">
      <xsl:attribute name="name" select="'sigma-ranges'"/>
      <xsl:element name="alt">
	<xsl:element name="inclusion">
	  <xsl:sequence select="$leRanges"/>
	</xsl:element>
      </xsl:element>
    </xsl:element>
    
    <xsl:element name="rule">
      <xsl:attribute name="name" select="'sigma-range-characters'"/>
      <xsl:element name="alt">
	<!--* for each range, give me the min, max, and mid *-->
	<xsl:variable name="li0" as="xs:integer*">
	  <xsl:for-each select="$leRanges">
	    <xsl:variable name="liPair" as="xs:integer*"
			  select="for $t
				  in tokenize(@gt:ranges, '\s+')
				  return xs:integer($t)
				  "/>
	    <xsl:variable name="iMid" as="xs:integer?"
			  select="if (exists($liPair))
				  then (sum($liPair) idiv 2)
				  else ()"/>
	    <xsl:sequence select="distinct-values(($liPair, $iMid))"/>
	  </xsl:for-each>
	</xsl:variable>
	<!--* Dedup *-->
	<xsl:variable name="li1" as="xs:integer*"
		      select="distinct-values($li0)"/>

	<!--* Write it out as a literal *-->	
	<xsl:element name="literal">
	  <xsl:attribute name="dstring"
			 select="codepoints-to-string($li1)"/>
	</xsl:element>
      </xsl:element>
    </xsl:element>
    
    <!--* sigma-union:  union of all inclusive ranges in the input grammar *-->
    <xsl:element name="rule">
      <xsl:attribute name="name" select="'sigma-union'"/>
      <xsl:element name="alt">	
	<xsl:element name="comment">
	  <xsl:text> Watch this space. </xsl:text>
	</xsl:element>
      </xsl:element>
    </xsl:element>
    
    <!--* sigma-complement:  complement of union of all inclusive ranges *-->
    <xsl:element name="rule">
      <xsl:attribute name="name" select="'sigma-complement'"/>
      <xsl:element name="alt">	
	<xsl:element name="comment">
	  <xsl:text> Watch this space. </xsl:text>
	</xsl:element>
      </xsl:element>
    </xsl:element>
    
    <!--* sigma-neg-ranges:  atomic exclusive ranges*-->	
    <xsl:element name="rule">
      <xsl:attribute name="name" select="'sigma-neg-ranges'"/>
      <xsl:element name="alt">	
	<xsl:element name="comment">
	  <xsl:text> Watch this space. </xsl:text>
	</xsl:element>
      </xsl:element>
    </xsl:element>
    
  </xsl:template>

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->  
  

  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  

  <!--****************************************************************
      * Predicates 
      *-->    


  
      
</xsl:stylesheet>
