<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="simplify-epsilon-expressions"
    version="3.0">

  <!--* simplify-epsilon.xsl
      * Read ixml.xml grammar, write it out again, selectively
      * deleting comments containing just the token 'nil'.
      *
      * These patterns arise in simplifying the R_0 FSA and
      * we simplify them in order to reduce clutter.
      *
      *-->

  <!--* Revisions:
      * 2020-12-13 : CMSMcQ : made stylesheet, for simplifying regular
      *                       grammars and their FSAs
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="simplify-epsilon-expressions"
	    on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="comment[. = 'nil']">
    <xsl:choose>
      <!--* special cases:  nil is the only content of an empty rule,
	  * or there are only two children, one of which is nil
	  * and the other of which is the next state.
	  *-->
      <xsl:when test="count(../*) = 1">
	<xsl:copy-of select="."/>
      </xsl:when>
      <xsl:when test="(count(../*) = 2) and exists(../nonterminal)">
	<xsl:copy-of select="."/>
      </xsl:when>

      <!--* Otherwise, retain nil only if the following
	  * sibling is a nonterminal and there are no
	  * non-comments to the left.
	  *-->
      <xsl:when test="exists(following-sibling::*[1]/self::nonterminal)
		      and empty(preceding-sibling::*[not(self::comment)])">
	<xsl:copy-of select="."/>
	<!--* suppress *-->
      </xsl:when>
      <xsl:when test="exists(preceding-sibling::*)">
	<!--* suppress *-->
      </xsl:when>
      <xsl:otherwise>
	<!--* <xsl:copy-of select="."/>  *-->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
</xsl:stylesheet>
