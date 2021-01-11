<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="inline-nonterminal"
    version="3.0">

  <!--* rule-substitution.xsl
      * Read ixml.xml grammar, write it out again, replacing references
      * to a specified nonterminal with its right hand side.
      *-->

  <!--* Revisions:
      * 2020-12-12 : CMSMcQ : made stylesheet, for simplifying regular
      *                       grammars and their FSAs
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="inline-nonterminal" on-no-match="shallow-copy"/>

  <xsl:param name="testing-nt" as="xs:string"
	     select=" 'block_7' "/>
  <xsl:param name="testing-keep" as="xs:boolean"
	     select=" false() "/>
  <xsl:param name="fTracing" as="xs:boolean"
	     select=" false() "/>

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="nonterminal">
    <xsl:param name="nt" as="xs:string" tunnel="yes"/>
  
    <xsl:variable name="name" select="@name"/>

    <xsl:choose>
      <xsl:when test="$name = $nt">
	<!--* we have been asked to inline this nonterminal.
	    * First get the rule.
	    *-->
	<xsl:variable name="rule"
		      as="element(rule)"
		      select="/ixml/rule[@name=$name]"/>
	<!--* Sanity check:  a RHS is a sequence of alt elements,
	    * right? *-->
	<xsl:if test="$rule/child::*
		      [not(self::alt) and not(self::comment)]">
	  <xsl:message>Rule has unexpected structure. I do not know what to do.</xsl:message>
	  <xsl:message><xsl:copy-of select="$rule"/></xsl:message>
	</xsl:if>

	<!--* Replace the nonterminal with the RHS *-->
	<xsl:choose>
	  <xsl:when test="parent::alt and count($rule/alt) eq 1">
	    <!--* Common case; no need to complicate the target location,
		* just slip it in. *-->
	    <xsl:if test="$fTracing">
	      <xsl:comment>* <xsl:value-of select="$nt"/> *</xsl:comment>
	    </xsl:if>
	    <xsl:sequence select="$rule/alt/node()"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <!--* Default and fallback case:  wrap the RHS
		* in an alts element. *-->
	    <xsl:element name="alts">
	      <xsl:sequence select="$rule/alt"/>
	    </xsl:element>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>
	    
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="rule">
    <xsl:param name="nt" as="xs:string" tunnel="yes"/>
    <xsl:param name="fKeep" as="xs:boolean" tunnel="yes"/>

    <xsl:variable name="name" select="@name"/>

    <xsl:choose>
      <xsl:when test="($name = $nt) and (not($fKeep))">
	<!--* we have been asked to lose this rule.
	    *-->
	<xsl:if test="$fTracing">
	  <xsl:element name="comment">
	    <xsl:value-of select="$nt"/>
	    <xsl:text> has been inlined. </xsl:text>
	  </xsl:element>
	</xsl:if>
      </xsl:when>
      <xsl:when test="($name = $nt) and ($fKeep)">
	<!--* We have been asked to keep this rule.
	    * We do NOT want to find self-references in the RHS;
	    * we'll handle that in a different step, using
	    * Arden's lemma.
	    *-->
	<xsl:copy-of select="."/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy>
	  <xsl:sequence select="@*"/>
	  <xsl:apply-templates/>
	</xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
