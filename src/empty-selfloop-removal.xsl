<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="empty-selfloop-removal"
    version="3.0">

  <!--* empty-selfloop-removal.xsl
      * Read ixml.xml grammar, write it out again, suppressing 
      * right-hand sides of the form (q: {nil}, q), that is
      * empty transitions to the same state we started in.
      *
      * This pattern arises in work with the R_0 grammar.
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split stylesheet into main and module
      * 2020-12-13 : CMSMcQ : made stylesheet, for the process of 
      *                       working with R_0 grammars.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  <xsl:import href="ixml-grammar-tools.lib.xsl"/>
  <xsl:include href="empty-selfloop-removal.lib.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>
  
  
</xsl:stylesheet>
