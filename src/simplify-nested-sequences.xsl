<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="simplify-nested-sequences"
    version="3.0">

  <!--* simplify-nested-sequences.xsl
      * Read ixml.xml grammar, write it out again, flattening
      * nested sequences.
      *
      * These patterns arise in simplifying the R_0 FSA and
      * we simplify them in order to reduce clutter.
      *
      *-->

  <!--* Revisions:
      * 2020-12-19 : CMSMcQ : made stylesheet, for simplifying regular
      *                       grammars and their FSAs
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="simplify-nested-sequences"
	    on-no-match="shallow-copy"/>

  <xsl:param name="rules"
	     as="xs:string*"
	     select="'#all'"/>

  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <!--* A sequence containing only a choice of sequences.  Lost the
      * wrapper.
      *-->
  <xsl:template match="alt[alts][count(*) eq 1]">
    <xsl:apply-templates select="./alts/alt"/>
  </xsl:template>
  
  
</xsl:stylesheet>
