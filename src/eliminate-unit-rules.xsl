<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="eliminate-unit-rules"
    version="3.0">

  <!--* eliminate-unit-rules.xsl
      * Read ixml.xml grammar G, write out same grammar without unit
      * rules.  When applied to a regular or pseudo-regular grammar,
      * this step eliminates epsilon transitions from the FSA.
      * 
      * To do:  allow user to restrict action by parent rule name?
      * (Not stricty essential:  user can always take manual control
      * by using rule-substitution.xsl.)
      *-->

  <!--* Revisions:
      * 2022-02-19 : CMSMcQ : If the input has rtn:stack attributes
      *                       on epsilon transitions, carry them
      *                       forward.
      * 2021-01-12 : CMSMcQ : change value-of to sequence to make
      *                       Saxon stop complaining
      * 2021-01-01 : CMSMcQ : make file, for dealing with FSAs made 
      *                       directly from regular approximations,
      *                       without manual simplification.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:mode name="eliminate-unit-rules" on-no-match="shallow-copy"/>

  <!--* fissile and non-fissile copied in from ixml-to-saprg.lib.xsl.
      * They are not actually used in this stylesheet. *-->
  
  <!--* fissile: which nonterminals should be broken out?
      * Either '#all' (meaning everything not marked non-fissile)
      * or a list of names.
      * Default is:  #all.
      *-->
  <xsl:param name="fissile" as="xs:string*"
	     select=" '#all' "/>

  <!--* non-fissile: which nonterminals should be treated as
      * pseudo-terminals and NOT be broken out?
      * Either '#non-recursive' (relying on @gt:recursive marking)
      * or '#none' (meaning all nonterminals are fissile)
      * or a list of names (for hand-selected pseudo-terminals)
      * Default is:  #non-recursive.
      *-->
  <xsl:param name="non-fissile" as="xs:string*"
	     select=" '#non-recursive' "/>
  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">
    <xsl:param name="fissile" as="xs:string*" tunnel="yes"
	       select="$fissile"/>
    <xsl:param name="non-fissile" as="xs:string*" tunnel="yes"
	       select="$non-fissile"/>
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: eliminate-unit-rules.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Output:  same grammar with unit rules eliminated. </xsl:text>
      </xsl:element>
      
      <xsl:text>&#xA;</xsl:text>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!--* N.B. we are taking steps to protect against cycles
      * in expanding any particular RHS, but we are not
      * taking any steps to ensure that we don't end up
      * injecting the same RHS twice.  That is, this code
      * will in its current state produce sub-optimal results
      * given a grammar like
      *
      * a: b; c.  b: d; e. c: d; e. d: 'd'. e: 'e'.
      *
      * We would like to get
      *
      * a: 'd'; 'e'.
      *
      * instead of
      *
      * a: 'd'; 'e'; 'd'; 'e'.
      *
      * But for the moment, I'm going to ignore that problem.
      *-->

  <xsl:template match="rule/alt">
    <xsl:param name="lnSeen" as="xs:string*"/>
    <xsl:param name="stack-operations" as="attribute(rtn:stack)*"/>

    <xsl:choose>
      <xsl:when test="gt:is-unit-rule(.)">
	<!--* This unit rule needs to be replaced by the
	    * RHS of the nonterminal it points to.  Unless,
	    * of course, we have already seen that nonterminal.
	    *-->
	<xsl:variable name="nRHS" as="xs:string"
		      select="nonterminal/@name/string()"/>
	<xsl:variable name="stack-op" as="attribute(rtn:stack)?"
		      select="nonterminal/@rtn:stack"/>
	<xsl:choose>
	  <xsl:when test="$nRHS = $lnSeen"/>
	  <xsl:otherwise>
	    <xsl:variable name="rRHS" as="element(rule)"
			  select="../../rule[@name = $nRHS]"/>
	    <xsl:for-each select="$rRHS/alt">
	      <xsl:apply-templates select=".">
		<xsl:with-param name="lnSeen"
				select="$nRHS, $lnSeen"/>
		<xsl:with-param name="stack-operations"
				select="$stack-operations, $stack-op"/>
	      </xsl:apply-templates>
	    </xsl:for-each>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
      <xsl:when test="exists($stack-operations)">
	<!--* if we have any stack operations, then we can assume the
	    * input is a stack automaton and we want to inject the
	    * stack operations into the child non-terminal.  If the
	    * input is not a stack automaton, then the rtn:stack 
	    * attributes are meaningless.
	    *-->
	<xsl:copy>
	  <xsl:apply-templates select="@*"/>
	  <xsl:for-each select="child::node()">
	    <xsl:choose>
	      <xsl:when test="self::nonterminal">
		<xsl:copy>
		  <xsl:apply-templates select="@* except @rtn:stack"/>
		  <xsl:attribute name="rtn:stack">
		    <xsl:sequence
			select="string-join(
				  ($stack-operations/string(), 
                                   @rtn:stack/string(.)),
				  ', '
				)"/>
		  </xsl:attribute>
		  <xsl:apply-templates select="child::node()"/>
		</xsl:copy>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:sequence select="."/>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
	</xsl:copy>	
      </xsl:when>
      <xsl:otherwise>
	<!--* if we don't have any stack operations, then just
	    * continue with a shallow copy. 
	    *-->
	<xsl:copy>
	  <xsl:apply-templates select="@*, child::node()"/>
	</xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>




  <!--****************************************************************
      * Functions
      ****************************************************************
      *-->
  
  <!--* ft:is-unit-rule($RHS):  true iff this alt element contains
      * a single nonterminal and nothing else bar comments.
      *-->
  <xsl:function name="gt:is-unit-rule" as="xs:boolean">
    <xsl:param name="e" as="element(alt)"/>
    <xsl:sequence select="exists($e/nonterminal)
			  and (count($e/* except $e/comment) eq 1)"/>
  </xsl:function>
  
  <!--****************************************************************
      * Predicates 
      *-->
  
</xsl:stylesheet>
