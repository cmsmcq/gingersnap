<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="remove-unreachables"
    version="3.0">

  <!--* remove-unreachables.xsl
      * Read ixml.xml grammar, write it out again, suppressing 
      * rules for unreachable nonterminals.
      *
      * Relies on ixml-annotate-pc gt:unreachable annotation.
      *
      * This is used as part of simplification in the removal
      * of unsatisfiable expression.
      *-->

  <!--* Revisions:
      * 2020-12-20 : CMSMcQ : made stylesheet, for the process of
      *                       working with R_0 grammars.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->

  <xsl:output method="xml"
	      indent="yes"/>

  <xsl:mode name="remove-unreachables" on-no-match="shallow-copy"/>


  <!--****************************************************************
      * Templates
      ****************************************************************
      *-->
  <xsl:template match="rule[@gt:reachable=('false', 'no', 0)]"/>

  
  
</xsl:stylesheet>
