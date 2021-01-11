<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"		
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		default-mode="arc-overlap"
		version="3.0">

  <!--* eliminate-arc-overlap.xsl:  module for inclusion into
      * determinzie.xsl.  Templates to process rules so as to
      * eliminate partial overlap between arcs in an FSA.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split into main and module to quiet Saxon 
      * 2020-12-28 : CMSMcQ : propagate gt:ranges further up the tree: 
      *                       onto alt, and then onto rule.  The value
      *                       on rule is easy to complement to get
      *                       error transitions when they are needed.
      *                       Also factor sanity checks into template.
      * 2020-12-26 : CMSMcQ : make sanity checks fire correctly
      * 2020-12-25 : CMSMcQ : correct some errors; passes Andrews test.
      * 2020-12-24 : CMSMcQ : draft completed, ready to test.
      * 2020-12-23 : CMSMcQ : begin making first version. 
      *-->

  <!--****************************************************************
      * Plan / overview 
      ****************************************************************
      *
      * We assume the input is a regular grammar.  We should probably
      * check.
      *
      * We check the arcs leaving each state (the RHS of each rule) to
      * ensure that no two of them have a partial overlap.  Any two
      * rules have the same non-terminal, or disjoint non-terminals.
      * (This doesn't come up in automata theory because there arcs are
      * assumed to be labeled with single symbols - not much fun in
      * a Unicode world.)
      *
      * For each arc, we split the label whenever we find overlap
      * with another arc.  We then check each split again.
      *
      * More formally:
      * if for any arc $a there is sibling $s such that ($a \ $s) and
      * ($a intersect $s) are both non-empty (which means each will
      * be different from $a), then we create a new arc for each of
      * these, and call the routine recursively.  If there is no such
      * sibling, then the arc goes into the output without change.
      *
      * To say it explicitly, this approach is based on two premises:
      * (1) We can work on rules individually: we do NOT have to work
      * pairwise.
      * (2) We can split rules by considering just the original 
      * grammar:  it is not necessary to consult the modified rules.
      *
      *-->

  
  <!--****************************************************************
      * Setup, parameters 
      ****************************************************************
      *-->

  <xsl:mode name="arc-overlap" on-no-match="shallow-copy"/>
  
  <xsl:template match="text()[not(parent::comment)]"/>

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <!--* Sanity check: does this rule have the structure we expect?
      * at most one terminal? at most one nonterminal? in that
      * order? *-->
  <xsl:template match="rule">

    <xsl:if test="false()">
      <xsl:message>
	<xsl:text>handling rule </xsl:text>
	<xsl:value-of select="@name"/>
	<xsl:text> in mode arc-overlap. &#xA;</xsl:text>
	<!-- <xsl:sequence select="."/> *-->
      </xsl:message>
    </xsl:if>    

    <!--* We create the new children but save them in a
	* variable so we can look at them and extract a
	* merged range for the rule. *-->
    <xsl:variable name="leAlts" as="element()+">
      <xsl:apply-templates/>
    </xsl:variable>
    
    <xsl:variable name="lrRule" as="xs:integer*">
      <xsl:sequence select="gt:merge-element-ranges($leAlts)"/>
    </xsl:variable>

    <!--* The merged range in turn lets us get a
	* complementary range (the theta range).
	*-->
    <xsl:variable name="lrComplement" as="xs:integer*">
      <xsl:sequence select="gt:lrDiff($lrXMLchar, $lrRule)"/>
    </xsl:variable>    
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:ranges" select="$lrRule"/>
      <xsl:attribute name="gt:theta" select="$lrComplement"/>

      <xsl:sequence select="$leAlts"/>
    </xsl:copy>
  </xsl:template>
  
  <!--* The main template we need is one for arcs, because we can
      * work on arcs in isolation.
      * We do need the siblings, which we can pass around as a
      * parameter.
      *-->
  <xsl:template match="rule/alt" name="handle-RHS">
    <xsl:param name="rhsThis" as="element(alt)"
	       select="."/>
    <xsl:param name="leSib" as="element()*"
	       select="../*[not(self::comment)]"/>

    <xsl:call-template name="sanity-checks-on-alt"/>    

    <xsl:message use-when="false()">
      <xsl:text>handle-RHS:  </xsl:text>
      <xsl:value-of select="count($leSib)"/>
      <xsl:text> siblings.</xsl:text>
    </xsl:message> 

    <xsl:variable name="terminalThis" as="element()?"
		  select="$rhsThis/*
			  [not(self::nonterminal)
			  and not(self::comment)]"/>
    <xsl:variable name="lrA" as="xs:string"
		  select="($terminalThis/@gt:ranges/string(), '')[1]"/>

    <xsl:message use-when="false()">
      <xsl:text>    lrA:  </xsl:text>
      <xsl:value-of select="$lrA"/>
      <xsl:text>.</xsl:text>
    </xsl:message>
    
    <!--* (1) Find the set of siblings which this one partially overlaps.
	* That is, if the sibling's range is lrB, we have:
	* (a) lrA intersect lrB is non-empty, and 
	* (b) lrA minus lrB is non-empty. 
	*-->
    <xsl:variable
	name="leOverlapping" as="element()*"
	select="$leSib[*[@gt:ranges]
		[
		exists(gt:lrIntersectionSS(string(@gt:ranges), $lrA))
		and 
		exists(gt:lrDiffSS($lrA, string(@gt:ranges)))
		]]"/>
   
    <!--* (2) If there are no such siblings (the set is empty), then
	* return a copy of the current element.
        * (3) Otherwise, split this arc into two and recur.
	*-->
    <xsl:choose>
      <xsl:when test="empty($leOverlapping)">
	<!--* (2) No partially overlapping siblings, nothing to do.
	    * Return a copy of this arc, with a new @gt:ranges copied
	    * from the terminal symbol.
	    *-->
	
	<!--* <xsl:sequence select="$rhsThis"/> *-->
	<xsl:element name="alt">
	  <xsl:sequence select="$rhsThis/@*"/>
	  <xsl:sequence select="$rhsThis/*/@gt:ranges"/>
	  <xsl:sequence select="$rhsThis/*"/>
	</xsl:element>

	<xsl:for-each select="$leSib" use-when="false()">
	  <xsl:message>    lrB (no overlap):  <xsl:value-of select="*/@gt:ranges"/></xsl:message>
	</xsl:for-each>
	<xsl:message use-when="false()">handleRHS returning, bye.</xsl:message>

      </xsl:when>
      <xsl:otherwise>
	<!--* (3) This arc's label partially overlaps the label of
	    * at least one other arc.  We need to break out
	    * the part that overlaps (the intersection of the ranges)
	    * and the part that doesn't.
	    *-->
	<xsl:if test="false()">
	  <xsl:message>
	    <xsl:text>Overlap found in </xsl:text>
	    <xsl:value-of select="count($leOverlapping)"/>
	    <xsl:text> siblings.</xsl:text>
	    <xsl:text>&#xA;    lrA = </xsl:text>
	    <xsl:value-of select="if (string-length($lrA) gt 50)
				  then concat(substring($lrA, 1, 40), '...')
				  else $lrA"/>
	  </xsl:message>
	</xsl:if>
	
	<!--* (3a) Pick an overlapping element, any overlapping element. *-->
	<xsl:variable name="rhsThat" as="element()"
		      select="$leOverlapping[1]"/>

	<xsl:message use-when="false()">
	  <xsl:text>rhsThat = </xsl:text>
	  <xsl:sequence select="$rhsThat"/>
	</xsl:message>
	
	<xsl:variable name="terminalThat" as="element()"
		      select="$rhsThat/*[@gt:ranges]"/>

	<xsl:message use-when="false()">
	  <xsl:text>terminalThat = </xsl:text>
	  <xsl:sequence select="$terminalThat"/>
	</xsl:message>

	<xsl:variable name="lrB" as="xs:string"
		      select="$terminalThat/@gt:ranges/string()"/>

	<xsl:if test="false()">
	<xsl:message>
	  <xsl:text>    lrB = </xsl:text>
	  <xsl:value-of select="if (string-length($lrB) gt 50)
				then concat(substring($lrB, 1, 40), '...')
				else $lrB"/>
	</xsl:message>
	</xsl:if>

	<!--* (3b) Get the intersection and difference. *-->
	<xsl:variable name="lrIntersection" as="xs:integer+"
		      select="gt:lrIntersectionSS(
			      string($lrA), 
			      string($lrB)
			      )"/>
	<xsl:variable name="lrDifference" as="xs:integer+"
		      select="gt:lrDiffSS(
			      string($lrA), 
			      string($lrB)
			      )"/>

	<xsl:message use-when="false()">
	  <xsl:text>    intersection = </xsl:text>
	  <xsl:value-of select="$lrIntersection[position() lt 21]"/>
	  <xsl:if test="count($lrIntersection) gt 20">...</xsl:if>
	</xsl:message>
	<xsl:message use-when="false()">
	  <xsl:text>    difference = </xsl:text>
	  <xsl:value-of select="$lrDifference[position() lt 21]"/>
	  <xsl:if test="count($lrDifference) gt 20">...</xsl:if>
	</xsl:message>

	<!--* (3c) Make new arcs. *-->
	<xsl:variable name="follow-state" as="element(nonterminal)?"
		      select="$rhsThis/nonterminal"/>
	
	<xsl:variable name="rhsSame" as="element(alt)">
	  <xsl:element name="alt">
	    <xsl:sequence
		select="gt:serialize-range-list($lrIntersection),
			$follow-state"/>
	  </xsl:element>
	</xsl:variable>
	<xsl:variable name="rhsDiff" as="element(alt)">
	  <xsl:element name="alt">
	    <xsl:sequence
		select="gt:serialize-range-list($lrDifference),
			$follow-state"/>
	  </xsl:element>
	</xsl:variable>

	<!--* (3d) Recursively split these new RHS if need be.
	    * Fortunately, we have code to do that.
	    * We need to pass along the 'leSib' elements, because
	    * the new arcs don't yet have siblings.  But the only
	    * siblings we need to pass along are the ones that
	    * overlapped the original arc.  (We probably don't need
	    * all of them, either, to be frank. But there are limits
	    * to my willingness to chase that penny under the table.)
	    *-->
	
	<xsl:message use-when="false()">Recurring ...</xsl:message>
	
	<xsl:call-template name="handle-RHS">
	  <xsl:with-param name="rhsThis" select="$rhsSame"/>
	  <xsl:with-param name="leSib" select="$leOverlapping"/>
	</xsl:call-template>
	
	<xsl:call-template name="handle-RHS">
	  <xsl:with-param name="rhsThis" select="$rhsDiff"/>
	  <xsl:with-param name="leSib" select="$leOverlapping"/>
	</xsl:call-template>
	
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--* Some quickly written sanity checks, to ease my mind
      * about the input.
      *-->
  <xsl:template name="sanity-checks-on-alt">

    <xsl:if test="count(*
		  [name() = ('literal', 'inclusion', 'exclusion')]
		  ) gt 1">
      <xsl:message terminate="no">
	<xsl:text>! multiple terminals? </xsl:text>
	<xsl:sequence select="."/>
      </xsl:message>
    </xsl:if>
    
    <xsl:if test="count(*/@gt:ranges) gt 1">
      <xsl:message terminate="no">
	<xsl:text>! multiple elements with @gt:ranges? </xsl:text>
	<xsl:sequence select="."/>
      </xsl:message>
    </xsl:if>
    
    <xsl:if test="count(nonterminal) gt 1">
      <xsl:message terminate="no">
	<xsl:text>! multiple nonterminals?? </xsl:text>
	<xsl:sequence select="."/>
      </xsl:message>
    </xsl:if>
    
    <xsl:if test="exists(nonterminal
		  [following-sibling::*
		  [not(self::comment)]])">
      <xsl:message terminate="no">
	<xsl:text>! non-final nonterminal?? </xsl:text>
	<xsl:sequence select="."/>
      </xsl:message>
    </xsl:if>
    
    <xsl:if test="exists(nonterminal)
		  and not(exists(literal) or exists(inclusion) or exists(exclusion))
		  and not(@rtn:ruletype = 'linkage')">
      <xsl:message terminate="no">
	<xsl:text>! empty transitions?  what are you thinking?? </xsl:text>
	<xsl:sequence select="."/>
      </xsl:message>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
