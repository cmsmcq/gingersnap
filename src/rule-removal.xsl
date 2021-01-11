<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="rule-removal"
    version="3.0">

  <!--* rule-removal.xsl
      * Read ixml.xml grammar, write it out again, suppressing 
      * selected rules.
      *
      * This is used to remove pseudo-terminals from the R_0
      * grammar as part of, or in preparation for, knitting
      * the R_0 grammar into an appropriate r_k grammar.
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

  <xsl:mode name="rule-removal" on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="rule">
    <xsl:param name="delenda"
	       as="xs:string*"
	       tunnel="yes"
	       required="yes"/>
    
    <xsl:choose>
      <!--* if the rule's name matches anything in the
	  * list of things to be deleted, do nothing with
	  * this rule.  (But do check to see whether there
	  * are references we are about to strand by deleting
	  * this rule.)
	  *-->
      <xsl:when test="@name = $delenda">
	<!--* Check suppressed:  in the expected use of this
	    * stylesheet there will be lots of dangling references.
	    * They are pseudo-terminals, and we don't need a
	    * message about them. *-->
	<!--*
	<xsl:if test="/descendant::nonterminal/@name = @name">
	  <xsl:message>! Deleting rule for <xsl:value-of
	  select="@name"/>, but there are dangling references.</xsl:message>
	  </xsl:if>
	  *-->
      </xsl:when>

      <!--* if the name does not match, leave the rule alone. *-->
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  
</xsl:stylesheet>
