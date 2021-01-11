<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:gt="http://blackmesatech.com/2020/grammartools"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:gl="http://blackmesatech.com/2019/iXML/Gluschkov"
    xmlns:rtn="http://blackmesatech.com/2020/iXML/recursive-transition-networks"
    xmlns:follow="http://blackmesatech.com/2016/nss/ixml-gluschkov-automata-followset"
    default-mode="tclego-to-tcrecipes"
    version="3.0">

  <!--* tclego-to-tcrecipes.xsl:  Read test-case lego grammar (as
      * produced by fsa-to-tclego.xsl), write out test case recipes
      * with metadata, with user control of coverage criterion.
      *
      * CURRENT STATE OF THIS STYLESHEET:  incomplete and currently 
      * in a state of incomplete refactoring. 
      *
      *
      *-->

  <!--* Revisions:
      * 2020-12-28 : CMSMcQ : split into main and module 
      * 2020-12-26 : CMSMcQ : begin writing this, with long comment
      *                       to clear my mind.
      *-->

  <!--****************************************************************
      * Setup
      ****************************************************************
      *-->
  
  <xsl:import href="range-operations.lib.xsl"/>
  <xsl:include href="tclego-to-tcrecipes.lib.xsl"/>

  <xsl:output method="xml"
	      indent="yes"/>
 
</xsl:stylesheet>
