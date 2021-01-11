<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="linkage-removal"
    version="3.0">

  <!--* rtn-linkage-removal.xsl
      * Read ixml.xml grammar, write it out again, suppressing the
      * 'linkage' rules added by ixml-to-saprg.xsl.
      *
      * We do this to simplify the creation of R_0 versions of
      * selected recursive nonterminals.
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

  <xsl:mode name="linkage-removal" on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="rule[@rtn:ruletype='linkage-stub']"/>

  <xsl:template match="alt[@rtn:ruletype='linkage-return']"/>

  
  
</xsl:stylesheet>
