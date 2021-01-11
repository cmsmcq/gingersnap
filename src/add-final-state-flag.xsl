<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="add-final-flag"
    version="3.0">

  <!--* add-final-state-flag.xsl
      * Read ixml.xml grammar, write it out again, adding a rule of
      * the form (q: {nil}}.) to some specified state q.
      *
      * This is used to make the recursive part of the R_0 recognize
      * one specific nonterminal (when there is a visible difference).
      *
      * (As may be seen, it is thought when this is written that there
      * is sometimes a difference.
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

  <xsl:mode name="add-final-flag" on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="rule">
    <xsl:param name="final"
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
      <xsl:when test="@name = $final">
	<xsl:copy>
	  <xsl:sequence select="@*"/>
	  <xsl:element name="alt">
	    <xsl:attribute name="rtn:ruletype"
			   select=" 'r0-linkage-return' "/>
	    <xsl:element name="comment">
	      <xsl:text>nil</xsl:text>
	    </xsl:element>
	  </xsl:element>
	  <xsl:sequence select="*"/>
	</xsl:copy>
      </xsl:when>

      <!--* if the name does not match, leave the rule alone. *-->
      <xsl:otherwise>
	<xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  
</xsl:stylesheet>
