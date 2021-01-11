<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="right-factor"
    version="3.0">

  <!--* right-factor.xsl
      * Read ixml.xml grammar, write it out again, right-factoring
      * the top-level alt elements in the specified rule to
      * group RHS that end in the specified follow states.
      *
      * This is sometimes helpful to reduce the overall size of
      * rules.
      *
      * This is used in simplifying FSAs.
      *-->

  <!--* Revisions:
      * 2020-12-13 : CMSMcQ : made stylesheet, for the process of
      *                       working with R_0 grammars.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="right-factor" on-no-match="shallow-copy"/>
  <xsl:mode name="match-cleaning" on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="rule">
    <xsl:param name="nonterminal"
	       as="xs:string*"
	       tunnel="yes"
	       required="yes"/>

    <!--* follow-state:  this is what we want to factor out on the
	* right.  For the moment, we handle only one; if you want
	* two things factored, run this stylesheet twice.
	*-->
    <xsl:param name="follow-state"
	       as="xs:string"
	       tunnel="yes"
	       required="yes"/>

    <!--* where:  top of result or bottom?
	*-->
    <xsl:param name="where"
	       as="xs:string"
	       tunnel="yes"
	       select=" 'top' "/>
    
    <xsl:choose>
      <!--* if the rule's name matches anything in the
	  * list of rules to be factored, then factor it.
	  *-->
      <xsl:when test="@name = $nonterminal">

	<xsl:variable name="rulename"
		      as="xs:string"
		      select="string(@name)"/>

	<!--* Prefix RHS are those of the form (L: P L) *-->
	<xsl:variable name="matching-RHS"
		      as="element(alt)+"
		      select="alt[
			      *[last()]/self::nonterminal[@name = $follow-state]
			      ]"/>

	<!--* Base RHS are everything else *-->
	<xsl:variable name="non-matching-RHS"
		      as="element(alt)+"
		      select="alt except $matching-RHS"/>

	<!--* copy the rule *-->
	<xsl:copy>
	  <xsl:sequence select="@*"/>

	  <xsl:element name="comment">
	    <xsl:text> Right-factored for </xsl:text>
	    <xsl:value-of select="$follow-state"/>
	    <xsl:text>.</xsl:text>
	  </xsl:element>

	  <xsl:if test="$where = 'top'">
	    <xsl:element name="alt">
	      <xsl:attribute name="rtn:ruletype"
			     select=" 'right-factor-result' "/>
	      <xsl:element name="alts">
		<xsl:apply-templates select="$matching-RHS"
				     mode="match-cleaning"/>
	      </xsl:element>
	      <xsl:element name="nonterminal">
		<xsl:attribute name="name"
			       select="$follow-state"/>
	      </xsl:element>
	    </xsl:element>
	  </xsl:if>

	  <xsl:sequence select="$non-matching-RHS"/>

	  <xsl:if test="$where = 'bottom'">
	    <xsl:element name="alt">
	      <xsl:attribute name="rtn:ruletype"
			     select=" 'right-factor-result' "/>
	      <xsl:element name="alts">
		<xsl:apply-templates select="$matching-RHS"
				     mode="match-cleaning"/>
	      </xsl:element>
	      <xsl:element name="nonterminal">
		<xsl:attribute name="name"
			       select="$follow-state"/>
	      </xsl:element>
	    </xsl:element>
	  </xsl:if>
	  
	</xsl:copy>
      </xsl:when>

      <!--* if the name does not match, leave the rule alone. *-->
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="nonterminal"
		mode="match-cleaning">
    <xsl:param name="follow-state"
	       tunnel="yes"
	       as="xs:string"/>
    <xsl:choose>
      <xsl:when test="@name = $follow-state"/>
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>      
    </xsl:choose>
  </xsl:template>

  
  
</xsl:stylesheet>
