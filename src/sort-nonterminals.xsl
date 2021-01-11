<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:gt="http://blackmesatech.com/2020/grammartools"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		default-mode="sort-nonterminals"
		version="3.0">

  <!--* Read ixml.xml grammar, write it out again with the rules
      * after the first one sorted alphabetically.
      *-->

  <!--* 2020-12-20 : CMSMcQ : made file to simplify navigation in
      *                       derived grammars
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="sort-nonterminals" on-no-match="shallow-copy"/>

  
  <!--****************************************************************
      * Main / starting template
      ****************************************************************
      *-->
  <!--* With a default identity transform, we don't actually need a
      * main starting template.  But we do want one for ixml, to
      * inject a comment to identify the stylesheet.
      *-->
  <xsl:template match="ixml">   
    
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: sort-nonterminals.xsl.</xsl:text>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Input: </xsl:text>
	<xsl:value-of select="base-uri(/)"/>
      </xsl:element>
      <xsl:element name="comment">
	<xsl:text>    Nonterminals except the first have been sorted.</xsl:text>
      </xsl:element>
      
      <xsl:apply-templates select="comment"/>
      <xsl:apply-templates select="rule[1]"/>
      <xsl:apply-templates select="rule[position() gt 1]">
	<xsl:sort select="lower-case(string(@name))"/>
      </xsl:apply-templates>
      
    </xsl:copy>
  </xsl:template>

  
</xsl:stylesheet>
