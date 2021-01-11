<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="relabel"
    version="3.0">

  <!--* relabel.xsl
      * Read ixml.xml grammar, write it out again, adding a
      * comment at the beginning.
      *-->

  <!--* Revisions:
      * 2020-12-14 : CMSMcQ : made stylesheet, for simplifying regular
      *                       grammars and their FSAs
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="relabel" on-no-match="shallow-copy"/>

  <xsl:param name="desc" as="xs:string"
	     select=" 'Grammar touched by relabel.xsl' "/>
  
  <xsl:param name="fTracing" as="xs:boolean"
	     select=" false() "/>

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="ixml">
    <xsl:param name="desc" as="xs:string?" tunnel="yes"
	       select="$desc"/>
    <xsl:copy>
      <xsl:sequence select="@*"/>
      <xsl:attribute name="gt:date" select="current-dateTime()"/>
      <xsl:element name="comment">
	<xsl:value-of select="current-dateTime()"/>
	<xsl:text>: </xsl:text>
	<xsl:value-of select="$desc"/>
	<xsl:text>.</xsl:text>
      </xsl:element>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ixml/comment"/>
  
</xsl:stylesheet>
